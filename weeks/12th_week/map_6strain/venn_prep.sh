#!/usr/bin/env bash
set -uo pipefail

DATASETS=(a b1 b2 d e f)
SUMMARY="venn_summary.csv"
echo "dataset,n_fur,n_seqwin,n_fur_only,n_seqwin_only,n_intersection" > "$SUMMARY"

for d in "${DATASETS[@]}"; do
    fur_fa="$d/markers.fasta"
    sw_fa="$d/seqwin-out/signatures.fasta"

    if [[ ! -f "$fur_fa" || ! -f "$sw_fa" ]]; then
        echo "$d: skipping - missing markers.fasta or signatures.fasta"
        continue
    fi

    echo "=== Processing $d ==="

    cp blast_markers.py "$d/blast_markers.py"
    cp blast_markers_reverse.py "$d/blast_markers_reverse.py"
    (cd "$d" && python3 blast_markers.py)
    (cd "$d" && python3 blast_markers_reverse.py)

    python3 extract_unique.py "$fur_fa" "$d/fur_in_seqwin.csv" "$d/fur_unique.fasta"
    python3 extract_unique.py "$sw_fa" "$d/seqwin_in_fur.csv" "$d/seqwin_unique.fasta"

    n_fur=$(tail -n +2 "$d/fur_in_seqwin.csv" | wc -l)
    n_fur_found=$(awk -F, 'NR>1 && $5==1' "$d/fur_in_seqwin.csv" | wc -l)
    n_seqwin=$(tail -n +2 "$d/seqwin_in_fur.csv" | wc -l)
    n_seqwin_found=$(awk -F, 'NR>1 && $5==1' "$d/seqwin_in_fur.csv" | wc -l)

    n_fur_only=$((n_fur - n_fur_found))
    n_seqwin_only=$((n_seqwin - n_seqwin_found))
    n_intersection=$(( (n_fur_found + n_seqwin_found) / 2 ))

    echo "$d,$n_fur,$n_seqwin,$n_fur_only,$n_seqwin_only,$n_intersection" >> "$SUMMARY"
done

echo "Wrote $SUMMARY"
cat "$SUMMARY"
