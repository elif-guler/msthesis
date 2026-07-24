#!/usr/bin/env bash
# Usage: ./check_separation.sh <table.tsv> <outdir> [100|1000]
#
# Expects <outdir>/fastas/<accession>.fasta to already exist (from runpipeline.sh).
# Requires: phylonium, nj, midRoot, land, fintac, pickle on PATH.

set -euo pipefail

TABLE=$1
OUTDIR=$2
POOL=${3:-100}

[[ "$POOL" == "1000" ]] && COL=4 || COL=3

FASTAS="$OUTDIR/fastas"
ALL="$OUTDIR/all"
mkdir -p "$ALL"
rm -f "$ALL"/*

# strip \r in case of Windows line endings
CLEAN="$OUTDIR/table.tsv"
tr -d '\r' < "$TABLE" > "$CLEAN"

# --- 1. First separation: read straight from the table, both filtered to
#        the chosen sample pool ---------------------------------------------
awk -F'\t' -v c="$COL" 'NR>1 && $2=="TRUE"  && $c=="TRUE" {print $1}' "$CLEAN" | sort -u > "$OUTDIR/first_targets.txt"
awk -F'\t' -v c="$COL" 'NR>1 && $2=="FALSE" && $c=="TRUE" {print $1}' "$CLEAN" | sort -u > "$OUTDIR/first_neighbors.txt"

echo "First-separation targets:   $(wc -l < "$OUTDIR/first_targets.txt")"
echo "First-separation neighbors: $(wc -l < "$OUTDIR/first_neighbors.txt")"

# --- 2. Build the "all" dir with t/n-prefixed filenames --------------------
missing=0
while read -r acc; do
    if [[ -f "$FASTAS/$acc.fasta" ]]; then
        cp "$FASTAS/$acc.fasta" "$ALL/t${acc}.fasta"
    else
        missing=$((missing+1))
    fi
done < "$OUTDIR/first_targets.txt"
while read -r acc; do
    if [[ -f "$FASTAS/$acc.fasta" ]]; then
        cp "$FASTAS/$acc.fasta" "$ALL/n${acc}.fasta"
    else
        missing=$((missing+1))
    fi
done < "$OUTDIR/first_neighbors.txt"
[[ $missing -gt 0 ]] && echo "Warning: $missing accessions had no FASTA in $FASTAS and were skipped."

n=$(ls "$ALL" | wc -l)
echo "Genomes going into the tree: $n"
if [[ $n -lt 3 ]]; then
    echo "Need at least 3 genomes for nj; aborting."
    exit 1
fi

# --- 3. phylonium distance matrix, dropping nan-producing genomes ---------
phylonium "$ALL"/* > "$OUTDIR/all.phyl" 2>"$OUTDIR/phylonium.log" || true
mkdir -p "$OUTDIR/Rejected"
while grep -qw nan "$OUTDIR/all.phyl" 2>/dev/null; do
    name=$(awk '{c=0; for(i=2;i<=NF;i++) if ($i=="nan") c++; print $1, c}' "$OUTDIR/all.phyl" \
          | sort -k2,2 -nr | head -1 | cut -d' ' -f1)
    [[ -z "$name" ]] && break
    echo "Rejecting $name (nan distances)"
    mv "$ALL/$name" "$OUTDIR/Rejected/" 2>/dev/null || true
    phylonium "$ALL"/* > "$OUTDIR/all.phyl" 2>>"$OUTDIR/phylonium.log" || true
done

# --- 4. Tree: nj -> midRoot -> land ----------------------------------------
nj "$OUTDIR/all.phyl" | midRoot | land > "$OUTDIR/all.nwk"

# --- 5. Find the best-supported target clade -------------------------------
tc=$(fintac "$OUTDIR/all.nwk" | tail -n +2 | sort -k6 -n -r | head -n 1 | awk '{print $1}')
echo "fintac-selected clade/leaf identifier: $tc"

if [[ $tc =~ ^[0-9]+$ ]]; then
    pickle "$tc" "$OUTDIR/all.nwk" | grep -v '^#' > "$OUTDIR/second_targets_raw.txt"
else
    pickle "$tc" "$OUTDIR/all.nwk" | awk 'NR==2{print $2}' > "$OUTDIR/second_targets_raw.txt"
fi
pickle -c "$tc" "$OUTDIR/all.nwk" | grep -v '^#' > "$OUTDIR/second_neighbors_raw.txt"

sed -E 's/^[tn]//; s/\.fasta$//' "$OUTDIR/second_targets_raw.txt"   | sort -u > "$OUTDIR/second_targets.txt"
sed -E 's/^[tn]//; s/\.fasta$//' "$OUTDIR/second_neighbors_raw.txt" | sort -u > "$OUTDIR/second_neighbors.txt"

# --- 6. Diff: first separation vs second separation ------------------------
echo
echo "=== First vs second separation ==="
echo "First targets:  $(wc -l < "$OUTDIR/first_targets.txt")"
echo "Second targets: $(wc -l < "$OUTDIR/second_targets.txt")"
echo

echo "Labeled TARGET in the table, but phylogeny groups them with NEIGHBORS:"
comm -23 "$OUTDIR/first_targets.txt" "$OUTDIR/second_targets.txt" | tee "$OUTDIR/target_to_neighbor.txt"
[[ -s "$OUTDIR/target_to_neighbor.txt" ]] || echo "  none"

echo
echo "Labeled NEIGHBOR in the table, but phylogeny groups them with TARGETS:"
comm -23 "$OUTDIR/first_neighbors.txt" "$OUTDIR/second_targets.txt" | tee "$OUTDIR/neighbor_to_target.txt"
[[ -s "$OUTDIR/neighbor_to_target.txt" ]] || echo "  none"

echo
echo "Full results in: $OUTDIR/{first,second}_{targets,neighbors}.txt"
