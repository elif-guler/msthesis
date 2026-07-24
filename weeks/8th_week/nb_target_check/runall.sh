#!/usr/bin/env bash
# run_all.sh
#
# Runs runpipeline.sh then check_separation.sh for each dataset directory
# (clo, mtb, sen by default), and prints a short summary at the end.
#
# Usage: ./run_all.sh [sample_column] [dataset1 dataset2 ...]
#
# Assumes, for each dataset dir <d>:
#   ./runpipeline.sh      <d>/acc.txt <d> "<sample_column>"
#   ./check_separation.sh <d>/acc.txt <d> "<sample_column>"
# (same argument order as runpipeline.sh/check_separation.sh take now -
#  edit the two calls below if your scripts' signature differs)

set -uo pipefail   # not -e: one dataset failing shouldn't stop the others

SAMPLE_COL=${1:-100}
shift || true
DATASETS=("$@")
[[ ${#DATASETS[@]} -eq 0 ]] && DATASETS=(clo mtb sen)

SUMMARY=()

for d in "${DATASETS[@]}"; do
    echo "=================================================================="
    echo "Dataset: $d  (pool: $SAMPLE_COL)"
    echo "=================================================================="

    if [[ ! -f "$d/acc.txt" ]]; then
        echo "  Skipping - no $d/acc.txt found."
        SUMMARY+=("$d/$SAMPLE_COL: SKIPPED (no acc.txt)")
        continue
    fi

    OUT="$d/pool_$SAMPLE_COL"
    mkdir -p "$OUT"

    echo "--- runpipeline.sh ---"
    if ./runpipeline.sh "$d/acc.txt" "$OUT" "$SAMPLE_COL" > "$OUT/pipeline.log" 2>&1; then
        echo "  OK (log: $OUT/pipeline.log)"
    else
        echo "  FAILED - see $OUT/pipeline.log"
        SUMMARY+=("$d/$SAMPLE_COL: runpipeline.sh FAILED")
        continue
    fi

    echo "--- check_separation.sh ---"
    if ./check_separation.sh "$d/acc.txt" "$OUT" "$SAMPLE_COL" > "$OUT/verify.log" 2>&1; then
        echo "  OK (log: $OUT/verify.log)"
        t2n=$(wc -l < "$OUT/target_to_neighbor.txt" 2>/dev/null || echo "?")
        n2t=$(wc -l < "$OUT/neighbor_to_target.txt" 2>/dev/null || echo "?")
        SUMMARY+=("$d/$SAMPLE_COL: OK - target_to_neighbor=$t2n  neighbor_to_target=$n2t")
    else
        echo "  FAILED - see $OUT/verify.log"
        SUMMARY+=("$d/$SAMPLE_COL: check_separation.sh FAILED")
    fi
    echo
done

echo "=================================================================="
echo "Summary"
echo "=================================================================="
for line in "${SUMMARY[@]}"; do
    echo "  $line"
done
