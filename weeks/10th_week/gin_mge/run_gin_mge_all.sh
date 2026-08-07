#!/usr/bin/env bash
# run_gin_mge_all.sh
#
# Downloads each dataset's reference genome once, then runs the gin
# permutation test for every dataset/pool combination.

set -uo pipefail

echo "dataset,pool,observed,permutations,ge_observed,pvalue" > gin_mge_summary.csv

for d in clo mtb sen; do
    bash download_reference.sh "$d"
done

for d in clo mtb sen; do
    for p in 100 1000; do
        bash gin_mge_test.sh "$d" "$p"
    done
done

echo
echo "wrote gin_mge_summary.csv"
cat gin_mge_summary.csv
