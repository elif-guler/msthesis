#!/bin/bash
set -e
cd "$(dirname "$0")"

for taxon in clo mtb sen; do
    ./runtaxon.sh "$taxon"
done
