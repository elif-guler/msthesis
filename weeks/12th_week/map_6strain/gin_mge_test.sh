#!/usr/bin/env bash
set -uo pipefail

d=$1
p=$2
outdir="$d/pool_$p"
N=10000

acc=$(cat "$d/reference/used_accession.txt" 2>/dev/null)
if [[ -z "$acc" ]]; then
    echo "$d: skipping - no reference/used_accession.txt"
    exit 1
fi

GFF="$d/reference/$acc.gff"
REF_FASTA="$d/reference/$acc.fasta"
FUR_UNIQUE="$outdir/fur_unique.fasta"
INTERVALS="$outdir/fur_only_intervals.txt"

if [[ ! -f "$GFF" || ! -f "$REF_FASTA" ]]; then
    echo "$outdir: skipping - no reference genome"
    exit 1
fi
if [[ ! -f "$FUR_UNIQUE" ]]; then
    echo "$outdir: skipping - no fur_unique.fasta"
    exit 1
fi

echo "Running test for: $outdir"

# 1. Map markers to reference coordinates
python3 make_intervals.py "$FUR_UNIQUE" "$REF_FASTA" "$INTERVALS"

# 2. Count observed MGE overlaps
OBSERVED=$(python3 annotate_mge.py --gff "$GFF" --intervals "$INTERVALS")
echo "  Observed MGE overlaps: $OBSERVED"

# 3. Shuffle intervals and stream through MGE annotator
shuffle -n "$N" "$GFF" "$INTERVALS" | \
    python3 annotate_mge.py --gff "$GFF" --stream > "$outdir/shuffle_counts.txt"

# 4. Empirical p-value
GE=$(awk -v obs="$OBSERVED" '$1>=obs{n++} END{print n+0}' "$outdir/shuffle_counts.txt")
TOTAL=$(wc -l < "$outdir/shuffle_counts.txt")
PVALUE=$(awk -v ge="$GE" -v total="$TOTAL" 'BEGIN{print (ge+1)/(total+1)}')

echo "  Permutations      : $TOTAL"
echo "  >= observed       : $GE"
echo "  Empirical p-value : $PVALUE"

echo "$d,$p,$OBSERVED,$TOTAL,$GE,$PVALUE" >> gin_mge_summary.csv
