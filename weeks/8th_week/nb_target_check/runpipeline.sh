#!/usr/bin/env bash
# Usage: ./runpipeline.sh <accessions_table.tsv> <outdir> [100|1000]
set -euo pipefail

TABLE=$1
OUTDIR=$2
POOL=${3:-100}   # which neighbor sample column to use: 100 or 1000

mkdir -p "$OUTDIR"/genomes "$OUTDIR"/fastas "$OUTDIR"/Rejected

# table columns are fixed: 1=accession 2=Is target 3=sampled100 4=sampled1000
[[ "$POOL" == "1000" ]] && COL=4 || COL=3

# strip \r in case the file has Windows line endings
CLEAN="$OUTDIR/table.tsv"
tr -d '\r' < "$TABLE" > "$CLEAN"

# 1. accession lists - both filtered to the chosen sample pool
awk -F'\t' -v c="$COL" 'NR>1 && $2=="TRUE"  && $c=="TRUE" {print $1}' "$CLEAN" > "$OUTDIR/targets.txt"
awk -F'\t' -v c="$COL" 'NR>1 && $2=="FALSE" && $c=="TRUE" {print $1}' "$CLEAN" > "$OUTDIR/neighbors.txt"
cat "$OUTDIR/targets.txt" "$OUTDIR/neighbors.txt" > "$OUTDIR/all_accessions.txt"
echo "Targets: $(wc -l < "$OUTDIR/targets.txt")  Neighbors: $(wc -l < "$OUTDIR/neighbors.txt")"

# 2. download
datasets download genome accession \
  --inputfile "$OUTDIR/all_accessions.txt" \
  --include genome --dehydrated --no-progressbar \
  --filename "$OUTDIR/genomes.zip"
unzip -o "$OUTDIR/genomes.zip" -d "$OUTDIR/genomes"
datasets rehydrate --directory "$OUTDIR/genomes"

# 3. one FASTA per accession
for d in "$OUTDIR"/genomes/ncbi_dataset/data/*/; do
  acc=$(basename "$d")
  cat "$d"*.fna > "$OUTDIR/fastas/${acc}.fasta"
done
echo "$(ls "$OUTDIR"/fastas | wc -l) FASTA files ready"

# 4. phylonium, dropping any genome phylonium can't reliably compare
phylonium "$OUTDIR"/fastas/*.fasta > "$OUTDIR/distances.phy" 2>"$OUTDIR/phylonium.log" || true
while grep -qw nan "$OUTDIR/distances.phy" 2>/dev/null; do
  bad=$(awk '{c=0; for(i=2;i<=NF;i++) if ($i=="nan") c++; print $1, c}' "$OUTDIR/distances.phy" \
        | sort -k2,2 -nr | head -1 | cut -d' ' -f1)
  [[ -z "$bad" ]] && break
  echo "Dropping $bad (nan distances)"
  mv "$OUTDIR/fastas/$bad.fasta" "$OUTDIR/Rejected/"
  phylonium "$OUTDIR"/fastas/*.fasta > "$OUTDIR/distances.phy" 2>>"$OUTDIR/phylonium.log" || true
done

echo "Distance matrix: $OUTDIR/distances.phy"
