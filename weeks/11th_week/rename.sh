#!/usr/bin/env bash
mkdir -p all

for file in ncbi_dataset/data/GC*/GC*_genomic.fna; do
    acc=$(basename "$file" | cut -d'_' -f1,2)
    ln -s "$(pwd)/$file" "all/$acc"
done
