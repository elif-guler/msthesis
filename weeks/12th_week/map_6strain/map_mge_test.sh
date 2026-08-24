#!/usr/bin/env bash
# map_mge_test.sh
#
# Runs the MGE permutation test for both fur and seqwin marker sets,
# for each of the 6 strains (a, b1, b2, d, e, f), using MAP's own
# mobilome.gff.gz as the MGE reference (instead of the old NCBI
# keyword-matched GFF from the gin_mge pipeline).
#
# REQUIRES CONFIRMATION BEFORE RUNNING:
#   1. MOBILOME_GFF path pattern below - run this first and check the
#      actual output structure:
#        find /home/elif/msthesis/weeks/12th_week/map_6strain/results -iname "*mobilome*"
#      then fix the MOBILOME_GFF= line if the real path differs.
#   2. Confirm the seqwin marker filename per strain - this script
#      assumes "seqwin_unique.fasta", matching your fur_unique.fasta
#      naming convention. Adjust the case statement below if seqwin's
#      output file is actually named something else (e.g. signatures.fasta).
#
# Requires: make_intervals.py, annotate_mge.py (same directory or on
# PATH), and the "shuffle" binary used by your original gin_mge pipeline.

set -uo pipefail

MAP_RESULTS="/home/elif/msthesis/weeks/12th_week/map_6strain/results"
STRAINS_DIR="/home/elif/msthesis/weeks/12th_week/map_6strain"
N=10000

echo "strain,marker_type,observed,permutations,ge_observed,pvalue" > map_mge_summary.csv

for strain in a b1 b2 d e f; do
    REF_FASTA=$(ls "$STRAINS_DIR/$strain/reference/"*.fasta 2>/dev/null | head -n 1)
    TEMPLATE_GFF=$(ls "$STRAINS_DIR/$strain/reference/"*.gff 2>/dev/null | head -n 1)   # for shuffle - defines valid positions
    MOBILOME_GFF="$MAP_RESULTS/$strain/gff/${strain}_mobilome.gff.gz"                                 # for annotate_mge.py - the MGE calls; CONFIRM THIS PATH

    if [[ -z "$REF_FASTA" || -z "$TEMPLATE_GFF" ]]; then
        echo "$strain: skipping - missing reference/*.fasta or reference/*.gff"
        continue
    fi

    if [[ ! -f "$MOBILOME_GFF" ]]; then
        echo "$strain: skipping - no mobilome.gff.gz found at $MOBILOME_GFF"
        continue
    fi

    for marker_type in fur seqwin; do
        case "$marker_type" in
            fur)    MARKERS="$STRAINS_DIR/$strain/fur_unique.fasta" ;;
            seqwin) MARKERS="$STRAINS_DIR/$strain/seqwin_unique.fasta" ;;  # confirm this filename
        esac

        if [[ ! -f "$MARKERS" ]]; then
            echo "$strain/$marker_type: skipping - marker file not found ($MARKERS)"
            continue
        fi

        outdir="$strain/mge_test_$marker_type"
        mkdir -p "$outdir"
        INTERVALS="$outdir/intervals.txt"

        echo "$strain / $marker_type"

        # 1. Turn markers into chr/start/end intervals on the reference
        python3 make_intervals.py "$MARKERS" "$REF_FASTA" "$INTERVALS"

        # 2. Count observed MGE overlaps against MAP's mobilome calls
        OBSERVED=$(python3 annotate_mge.py --gff "$MOBILOME_GFF" --intervals "$INTERVALS")
        echo "  Observed MGE overlaps: $OBSERVED"

        # 3. Shuffle intervals among valid template positions, count overlaps for each
        shuffle -n "$N" "$TEMPLATE_GFF" "$INTERVALS" | \
            python3 annotate_mge.py --gff "$MOBILOME_GFF" --stream > "$outdir/shuffle_counts.txt"

        # 4. Empirical p-value
        GE=$(awk -v obs="$OBSERVED" '$1>=obs{n++} END{print n+0}' "$outdir/shuffle_counts.txt")
        TOTAL=$(wc -l < "$outdir/shuffle_counts.txt")
        PVALUE=$(awk -v ge="$GE" -v total="$TOTAL" 'BEGIN{print (ge+1)/(total+1)}')

        echo "  Permutations      : $TOTAL"
        echo "  >= observed       : $GE"
        echo "  Empirical p-value : $PVALUE"

        echo "$strain,$marker_type,$OBSERVED,$TOTAL,$GE,$PVALUE" >> map_mge_summary.csv
    done
done

echo
echo "wrote map_mge_summary.csv"
cat map_mge_summary.csv
