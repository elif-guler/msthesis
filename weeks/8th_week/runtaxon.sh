#!/bin/bash
# Usage: ./run_taxon.sh <taxon_dir> 
set -e

TAXON_DIR="$1"
if [ -z "$TAXON_DIR" ]; then
    echo "Usage: $0 <taxon_dir>" >&2
    exit 1
fi

cd "$TAXON_DIR"

#1. Build separate accession lists per sample size
# acc.txt has a comment line + a header line before data starts, so NR>2.
awk -F '\t' 'NR>2 && $3=="TRUE" {print $1}' acc.txt > accessions_100.txt
awk -F '\t' 'NR>2 && $4=="TRUE" {print $1}' acc.txt > accessions_1000.txt

mkdir -p all

# Seed 'all/' from whatever is already sitting in targets/ and neighbors/
# (these currently hold real fasta files from the 1000-genome run).
for f in targets/*.fasta neighbors/*.fasta; do
    [ -e "$f" ] || continue
    acc=$(basename "$f" .fasta)
    # Only symlink if not already present as a real file/link
    [ -e "all/${acc}.fasta" ] || ln -sf "$(realpath "$f")" "all/${acc}.fasta"
done

# Figure out which accessions (from either size's list) are still missing
# from all/. We still dedupe against a combined set so nothing downloads twice.
missing=0
: > missing_accessions.txt
cat accessions_100.txt accessions_1000.txt | sort -u | while read -r acc; do
    if [ ! -e "all/${acc}.fasta" ]; then
        echo "$acc" >> missing_accessions.txt
        missing=1
    fi
done
# note: the 'missing' var set inside the pipe subshell won't propagate;
# check the file instead
if [ -s missing_accessions.txt ]; then
    missing=1
else
    missing=0
fi

if [ "$missing" -eq 1 ]; then
    echo "[$TAXON_DIR] Downloading $(wc -l < missing_accessions.txt) missing genomes..."
    datasets download genome accession \
        --inputfile missing_accessions.txt \
        --dehydrated --filename missing_ncbi_dataset.zip
    unzip -o missing_ncbi_dataset.zip -d missing_ncbi_dataset
    datasets rehydrate --directory missing_ncbi_dataset

    find missing_ncbi_dataset/ncbi_dataset/data -name "*_genomic.fna" | while read -r f; do
        acc=$(basename "$(dirname "$f")")
        ln -sf "$(realpath "$f")" "all/${acc}.fasta"
    done
else
    echo "[$TAXON_DIR] All required genomes already present, no download needed."
fi

#2. Build target/neighbor sets + run tools, per sample size
for entry in "3:100" "4:1000"; do
    col="${entry%%:*}"
    size="${entry##*:}"
    outdir="results/${size}"

    mkdir -p "$outdir/targets" "$outdir/neighbors"
    rm -f "$outdir"/targets/*.fasta "$outdir"/neighbors/*.fasta

    awk -F '\t' -v col="$col" 'NR>2 && $col=="TRUE" {print $1"\t"$2}' acc.txt |
    while IFS=$'\t' read -r acc target; do
        if [ ! -e "all/${acc}.fasta" ]; then
            echo "WARNING: all/${acc}.fasta missing, skipping" >&2
            continue
        fi
        if [ "$target" = "TRUE" ]; then
            ln -sf "$(realpath "all/${acc}.fasta")" "$outdir/targets/${acc}.fasta"
        else
            ln -sf "$(realpath "all/${acc}.fasta")" "$outdir/neighbors/${acc}.fasta"
        fi
    done

    n_targets=$(ls "$outdir/targets" | wc -l)
    n_neighbors=$(ls "$outdir/neighbors" | wc -l)
    echo "[$TAXON_DIR/$size] targets=$n_targets neighbors=$n_neighbors"

    # fur 
    /usr/bin/time -v -o "$outdir/makeFurDb.res" \
        makeFurDb -T 1 -t "$outdir/targets" -n "$outdir/neighbors" -o -d "$outdir/target.db"

    /usr/bin/time -v -o "$outdir/fur.res" \
        fur -m -d "$outdir/target.db" > "$outdir/target.fasta"

    # seqwin 
    /usr/bin/time -v -o "$outdir/seqwin.res" \
        seqwin --tar-dir "$outdir/targets" --neg-dir "$outdir/neighbors" \
               -o "$outdir/seqwin-out" --overwrite
done

echo "[$TAXON_DIR] Done."
