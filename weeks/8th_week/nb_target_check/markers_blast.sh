#!/usr/bin/env bash
# markers_blast.sh
#
# For every dataset/pool, checks whether fur's markers.fasta are a subset
# of seqwin's signatures.fasta, using blast_markers.py (which has no
# arguments - it always reads markers.fasta / seqwin-out/signatures.fasta
# from the current directory). So this script cd's into each pool folder
# before running it, instead of passing paths in.

set -uo pipefail
SCRIPT="$(pwd)/blast_markers.py"
DATASETS=(clo mtb sen)
POOLS=(100 1000)
SUMMARY="fur_subset_summary.csv"
echo "dataset,pool,n_fur_markers,n_found_in_seqwin,fraction_found" > "$SUMMARY"

for d in "${DATASETS[@]}"; do
  for p in "${POOLS[@]}"; do
    outdir="$d/pool_$p"
    fur_fa="$outdir/markers.fasta"
    sw_fa="$outdir/seqwin-out/signatures.fasta"
    if [[ ! -f "$fur_fa" || ! -f "$sw_fa" ]]; then
        echo "$outdir: skipping - missing markers.fasta or signatures.fasta"
        continue
    fi
    echo "$outdir"
    if (cd "$outdir" && python3 "$SCRIPT" > fur_in_seqwin.log 2>&1)
    then
        line=$(tail -2 "$outdir/fur_in_seqwin.log" | head -1)
        echo "  $line"
        n=$(awk -F, 'NR>1{c++} END{print c+0}' "$outdir/fur_in_seqwin.csv")
        found=$(awk -F, 'NR>1 && $5==1{c++} END{print c+0}' "$outdir/fur_in_seqwin.csv")
        frac=$(awk -v n="$n" -v f="$found" 'BEGIN{ if(n>0) printf "%.3f", f/n; else print "0.000" }')
        echo "$d,$p,$n,$found,$frac" >> "$SUMMARY"
    else
        echo "  FAILED - see $outdir/fur_in_seqwin.log"
    fi
  done
done

echo
echo "wrote $SUMMARY"
cat "$SUMMARY"
