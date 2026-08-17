#!/usr/bin/env bash
# venn_prep.sh
#
# For every dataset/pool:
#   - runs blast_markers.py (fur vs seqwin) if not already done
#   - runs blast_markers_reverse.py (seqwin vs fur)
#   - extracts fur-only and seqwin-only marker sequences into fasta files
#   - writes one combined venn_summary.csv with the counts for a Venn diagram

set -uo pipefail
DATASETS=(a b1 b2 d e f)

SUMMARY="venn_summary.csv"
echo "dataset,n_fur,n_seqwin,n_fur_only,n_seqwin_only,n_intersection" > "$SUMMARY"

for d in "${DATASETS[@]}"; do
    outdir="$d"
    fur_fa="$outdir/markers.fasta"
    sw_fa="$outdir/seqwin-out/signatures.fasta"

    if [[ ! -f "$fur_fa" || ! -f "$sw_fa" ]]; then
        echo "$outdir: skipping - missing markers.fasta or signatures.fasta"
        continue
    fi

    echo "$outdir"

    cp blast_markers.py "$outdir/blast_markers.py"
    cp blast_markers_reverse.py "$outdir/blast_markers_reverse.py"
    (cd "$outdir" && python3 blast_markers.py)
    (cd "$outdir" && python3 blast_markers_reverse.py)

    python3 extract_unique.py "$fur_fa" "$outdir/fur_in_seqwin.csv" "$outdir/fur_unique.fasta"
    python3 extract_unique.py "$sw_fa" "$outdir/seqwin_in_fur.csv" "$outdir/seqwin_unique.fasta"

    n_fur=$(tail -n +2 "$outdir/fur_in_seqwin.csv" | wc -l)
    n_fur_found=$(awk -F, 'NR>1 && $5==1' "$outdir/fur_in_seqwin.csv" | wc -l)
    n_seqwin=$(tail -n +2 "$outdir/seqwin_in_fur.csv" | wc -l)
    n_seqwin_found=$(awk -F, 'NR>1 && $5==1' "$outdir/seqwin_in_fur.csv" | wc -l)

    n_fur_only=$((n_fur - n_fur_found))
    n_seqwin_only=$((n_seqwin - n_seqwin_found))
    n_intersection=$(( (n_fur_found + n_seqwin_found) / 2 ))

    echo "$d,$n_fur,$n_seqwin,$n_fur_only,$n_seqwin_only,$n_intersection" >> "$SUMMARY"
done

echo
echo "wrote $SUMMARY"
cat "$SUMMARY"
