#!/usr/bin/env bash
# run_cons.sh
#
# Runs analyze_cons.py for both fur and seqwin marker sets, across
# every dataset/pool combination. Writes:
#   <dataset>/pool_<n>/cons_div_fur.csv
#   <dataset>/pool_<n>/cons_div_seqwin.csv

set -uo pipefail

DATASETS=(clo mtb sen)
POOLS=(100 1000)

for d in "${DATASETS[@]}"; do
  for p in "${POOLS[@]}"; do
    outdir="$d/pool_$p"
    echo "$outdir"

    if [[ ! -f "$outdir/markers.fasta" ]]; then
        echo "  skipping fur - no $outdir/markers.fasta"
    else
        if python3 analyze_cons.py \
            "$outdir/markers.fasta" "$outdir/targets" "$outdir/neighbors" \
            "$outdir/cons_div_fur.csv" \
            > "$outdir/cons_div_fur.log" 2>&1
        then
            echo "  fur -> $outdir/cons_div_fur.csv"
        else
            echo "  fur FAILED - see $outdir/cons_div_fur.log"
        fi
    fi

    if [[ ! -f "$outdir/seqwin-out/signatures.fasta" ]]; then
        echo "  skipping seqwin - no $outdir/seqwin-out/signatures.fasta"
    else
        if python3 analyze_cons.py \
            "$outdir/seqwin-out/signatures.fasta" "$outdir/targets" "$outdir/neighbors" \
            "$outdir/cons_div_seqwin.csv" \
            > "$outdir/cons_div_seqwin.log" 2>&1
        then
            echo "  seqwin -> $outdir/cons_div_seqwin.csv"
        else
            echo "  seqwin FAILED - see $outdir/cons_div_seqwin.log"
        fi
    fi
  done
done
