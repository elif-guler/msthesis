#!/usr/bin/env bash
# calc_marker_bp.sh
#
# For every dataset/pool, sums the total basepairs (and counts markers) in
# fur's markers.fasta and seqwin's signatures.fasta. Writes one combined
# summary CSV: marker_bp_summary.csv

set -uo pipefail

OUT="marker_bp_summary.csv"
echo "dataset,pool,tool,n_markers,total_bp" > "$OUT"

DATASETS=(clo mtb sen)
POOLS=(100 1000)

total_bp() {
    # sums the length of every non-header line in a fasta file
    awk '/^>/{next}{c+=length($0)} END{print c+0}' "$1"
}
n_markers() {
    local n
    n=$(grep -c '^>' "$1" 2>/dev/null)
    [[ -z "$n" ]] && n=0
    echo "$n"
}

for d in "${DATASETS[@]}"; do
  for p in "${POOLS[@]}"; do
    outdir="$d/pool_$p"

    fur_fa="$outdir/markers.fasta"
    if [[ -f "$fur_fa" ]]; then
        n=$(n_markers "$fur_fa"); [[ -z "$n" ]] && n=0
        bp=$(total_bp "$fur_fa")
        echo "$d,$p,fur,$n,$bp" >> "$OUT"
    fi

    sw_fa="$outdir/seqwin-out/signatures.fasta"
    if [[ -f "$sw_fa" ]]; then
        n=$(n_markers "$sw_fa"); [[ -z "$n" ]] && n=0
        bp=$(total_bp "$sw_fa")
        echo "$d,$p,seqwin,$n,$bp" >> "$OUT"
    fi
  done
done

echo "wrote $OUT"
cat "$OUT"
