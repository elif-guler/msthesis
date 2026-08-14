#!/usr/bin/env bash
# run_tools.sh
#
# Runs makeFurDb + fur, and seqwin, on the targets/neighbors folders built
# by check_separation.sh, for every dataset/pool combination.
#
# Usage: ./run_tools.sh [pool ...]   (default: 100 1000)
#        ./run_tools.sh [dataset ...] [pool ...] is NOT supported -
#        edit DATASETS below directly if you need a subset of datasets.

set -uo pipefail   # not -e: one failed run shouldn't stop the rest

DATASETS=(a b1 b2 d e f)

SUMMARY=()

for d in "${DATASETS[@]}"; do
    outdir="$d"
    echo "$outdir"

    if [[ ! -d "$outdir/targets" || ! -d "$outdir/neighbors" ]]; then
        echo "skipping - no targets/neighbors in $outdir"
        SUMMARY+=("$outdir: SKIPPED (missing targets/neighbors)")
        continue
    fi

    if makeFurDb -t "$outdir/targets" -n "$outdir/neighbors" -o -d "$outdir/target.db" \
		 > "$outdir/makeFurDb.log" 2>&1
    then
        echo "makeFurDb ok"
    else
        echo "makeFurDb failed - see $outdir/makeFurDb.log"
        SUMMARY+=("$outdir: makeFurDb FAILED")
        continue
    fi

    if fur -d "$outdir/target.db" > "$outdir/markers.fasta" 2>"$outdir/fur.log"
    then
        n=$(grep -c '^>' "$outdir/markers.fasta" 2>/dev/null)
        [[ -z "$n" ]] && n=0
        echo "fur ok, $n markers"
    else
        echo "fur failed - see $outdir/fur.log"
        SUMMARY+=("$outdir: fur FAILED")
        continue
    fi

    if seqwin --tar-dir "$outdir/targets" --neg-dir "$outdir/neighbors" \
              -o "$outdir/seqwin-out" --overwrite \
              > "$outdir/seqwin.log" 2>&1
    then
        ns=$(grep -c '^>' "$outdir/seqwin-out/signatures.fasta" 2>/dev/null)
        [[ -z "$ns" ]] && ns=0
        echo "seqwin ok, $ns markers"
        SUMMARY+=("$outdir: OK - $n fur markers, $ns seqwin markers")
    else
        echo "seqwin failed - see $outdir/seqwin.log"
        SUMMARY+=("$outdir: seqwin FAILED")
    fi
    echo
done

echo "summary"
for line in "${SUMMARY[@]}"; do
    echo "  $line"
done
