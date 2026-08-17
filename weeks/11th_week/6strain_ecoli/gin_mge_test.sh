#!/usr/bin/env bash
set -uo pipefail
d=$1
p=$2
outdir="$d/pool_$p"
N=10000

acc=$(cat "$d/reference/used_accession.txt" 2>/dev/null)
if [[ -z "$acc" ]]; then
    echo "$d: skipping - no reference/used_accession.txt (run download_reference.sh $d first)"
    exit 1
fi
GFF="$d/reference/$acc.gff"
REF_FASTA="$d/reference/$acc.fasta"
FUR_UNIQUE="$outdir/fur_unique.fasta"
INTERVALS="$outdir/fur_only_intervals.txt"

if [[ ! -f "$GFF" || ! -f "$REF_FASTA" ]]; then
    echo "$outdir: skipping - no reference genome (run download_reference.sh $d first)"
    exit 1
fi
if [[ ! -f "$FUR_UNIQUE" ]]; then
    echo "$outdir: skipping - no fur_unique.fasta (run venn_prep.sh first)"
    exit 1
fi

echo "$outdir"

# 1. Turn fur-only markers into chr/start/end intervals on the reference
python3 make_intervals.py "$FUR_UNIQUE" "$REF_FASTA" "$INTERVALS"

# 2. Count observed MGE overlaps using full attribute text
OBSERVED=$(python3 annotate_mge.py --gff "$GFF" --intervals "$INTERVALS")
echo "  Observed MGE overlaps: $OBSERVED"

# 3. Shuffle intervals and pipe through streaming MGE annotator
shuffle -n "$N" "$GFF" "$INTERVALS" | \
    python3 annotate_mge.py --gff "$GFF" --stream > "$outdir/shuffle_counts.txt"

# 4. Calculate empirical p-value
GE=$(awk -v obs="$OBSERVED" '$1>=obs{n++} END{print n+0}' "$outdir/shuffle_counts.txt")
TOTAL=$(wc -l < "$outdir/shuffle_counts.txt")
PVALUE=$(awk -v ge="$GE" -v total="$TOTAL" 'BEGIN{print (ge+1)/(total+1)}')

echo "  Permutations      : $TOTAL"
echo "  >= observed       : $GE"
echo "  Empirical p-value : $PVALUE"

echo "$d,$p,$OBSERVED,$TOTAL,$GE,$PVALUE" >> gin_mge_summary.csv
