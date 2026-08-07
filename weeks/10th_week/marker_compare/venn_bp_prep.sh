#!/usr/bin/env bash
# venn_bp_prep.sh
#
# Same idea as venn_prep.sh, but sums total basepairs (N's excluded)
# instead of counting markers. Requires fur_in_seqwin.csv and
# seqwin_in_fur.csv to already exist (from venn_prep.sh).
#
# Writes venn_bp_summary.csv: dataset,pool,bp_fur_only,bp_seqwin_only,bp_intersection

set -uo pipefail
DATASETS=(clo mtb sen)
POOLS=(100 1000)

SUMMARY="venn_bp_summary.csv"
echo "dataset,pool,bp_fur_only,bp_seqwin_only,bp_intersection" > "$SUMMARY"

for d in "${DATASETS[@]}"; do
  for p in "${POOLS[@]}"; do
    outdir="$d/pool_$p"
    fur_fa="$outdir/markers.fasta"
    sw_fa="$outdir/seqwin-out/signatures.fasta"
    fur_csv="$outdir/fur_in_seqwin.csv"
    sw_csv="$outdir/seqwin_in_fur.csv"

    if [[ ! -f "$fur_csv" || ! -f "$sw_csv" ]]; then
        echo "$outdir: skipping - run venn_prep.sh first"
        continue
    fi

    echo "$outdir"

    bp_fur_only=$(python3 sum_bp.py "$fur_fa" "$fur_csv" 0)
    bp_fur_intersect=$(python3 sum_bp.py "$fur_fa" "$fur_csv" 1)
    bp_seqwin_only=$(python3 sum_bp.py "$sw_fa" "$sw_csv" 0)
    bp_seqwin_intersect=$(python3 sum_bp.py "$sw_fa" "$sw_csv" 1)

    # same asymmetry as the marker-count version: average both directions
    bp_intersection=$(( (bp_fur_intersect + bp_seqwin_intersect) / 2 ))

    echo "  fur-only: $bp_fur_only bp   seqwin-only: $bp_seqwin_only bp   intersection: $bp_intersection bp"
    echo "$d,$p,$bp_fur_only,$bp_seqwin_only,$bp_intersection" >> "$SUMMARY"
  done
done

echo
echo "wrote $SUMMARY"
cat "$SUMMARY"
