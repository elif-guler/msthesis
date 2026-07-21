#!/bin/bash
set -e

# Choose which dataset to use:
# SAMPLE_COL=3  -> "Is sampled (100 genomes)"
# SAMPLE_COL=4  -> "Is sampled (1000 genomes)"
SAMPLE_COL=4

# Build accession list for download
awk -F '\t' -v col="$SAMPLE_COL" '
NR>1 && $col=="TRUE" {print $1}
' acc.txt > accessions.txt

# Download genomes
datasets download genome accession \
    --inputfile accessions.txt \
    --dehydrated

# Extract and rehydrate
unzip -o ncbi_dataset.zip
datasets rehydrate --directory .

# Collect genomes
mkdir -p all

find ncbi_dataset/data -name "*_genomic.fna" | while read -r f
do
    acc=$(basename "$(dirname "$f")")
    ln -sf "$(realpath "$f")" "all/${acc}.fasta"
done

# Build phylogeny
phylonium all/* \
    | nj \
    | midRoot \
    | land > tree.nwk

# Plot tree
plotTree tree.nwk

# Create target and neighbor directories
mkdir -p targets neighbors

awk -F '\t' -v col="$SAMPLE_COL" '
NR>1 && $col=="TRUE" {
    print $1 "\t" $2
}
' acc.txt | while IFS=$'\t' read -r acc target
do
    if [ "$target" = "TRUE" ]; then
        ln -sf "$(pwd)/all/${acc}.fasta" "targets/${acc}.fasta"
    else
        ln -sf "$(pwd)/all/${acc}.fasta" "neighbors/${acc}.fasta"
    fi
done

# Build Fur database
/usr/bin/time -v -o makeFurDb.res \
makeFurDb \
    -T 1 \
    -t targets \
    -n neighbors \
    -o \
    -d target.db

# Run Fur
/usr/bin/time -v -o fur.res \
fur -m -d target.db > target.fasta
