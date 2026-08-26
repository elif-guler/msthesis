#!/usr/bin/env bash
# download_reference.sh
#
# Download the EXACT reference assemblies required for the replication run.
#
# Usage:
#   bash download_reference.sh clo
#   bash download_reference.sh mtb
#   bash download_reference.sh sen

set -euo pipefail

d=$1

case "$d" in
    clo)
        acc="GCA_018885085.1"
        ;;
    mtb)
        acc="GCA_000195955.2"
        ;;
    sen)
        acc="GCA_000006945.2"
        ;;
    *)
        echo "$d: unknown dataset"
        exit 1
        ;;
esac

mkdir -p "$d/reference"
cd "$d/reference"

echo "$d: downloading exact reference assembly $acc"

rm -rf ref ref.zip
rm -f *.fasta *.gff used_accession.txt

datasets download genome accession "$acc" \
    --include genome,gff3 \
    --dehydrated \
    --filename ref.zip

unzip -q -o ref.zip -d ref

datasets rehydrate --directory ref

fna=$(find ref -type f -name '*.fna' | head -n 1)
gff=$(find ref -type f -name '*.gff' | head -n 1)

if [[ -z "$fna" ]]; then
    echo "$d: ERROR - no FASTA found for $acc"
    exit 1
fi

if [[ -z "$gff" ]]; then
    echo "$d: ERROR - no GFF found for $acc"
    exit 1
fi

cp "$fna" "$acc.fasta"
cp "$gff" "$acc.gff"

echo "$acc" > used_accession.txt

echo "$d: reference ready"
echo "  accession: $acc"
echo "  FASTA:     $acc.fasta"
echo "  GFF:       $acc.gff"
