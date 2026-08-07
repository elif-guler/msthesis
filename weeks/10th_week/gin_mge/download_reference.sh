#!/usr/bin/env bash
# download_reference.sh
#
# Downloads the FASTA + GFF for the reference genome named in a dataset's
# acc.txt header comment. If that specific accession has no GFF on NCBI,
# falls back to NCBI's officially designated reference genome for the
# same species (datasets ... taxon "<species>" --reference), so we stay
# on the same organism rather than switching to a related one.
#
# Usage: ./download_reference.sh <dataset_dir>
# Example: ./download_reference.sh clo

set -uo pipefail
d=$1

case "$d" in
    clo) species="Clostridioides difficile" ;;
    mtb) species="Mycobacterium tuberculosis" ;;
    sen) species="Salmonella enterica" ;;
    *) echo "$d: unknown dataset, add its species name to this script"; exit 1 ;;
esac

acc=$(grep -oE 'GCA_[0-9]+\.[0-9]+' "$d/acc.txt" | head -n 1)
if [[ -z "$acc" ]]; then
    echo "$d: couldn't find a reference accession in acc.txt's header comment"
    exit 1
fi

mkdir -p "$d/reference"
cd "$d/reference"

fetch_and_check () {
    local zipname=$1
    shift
    rm -rf ref "$zipname"
    datasets download genome "$@" --include genome,gff3 --dehydrated --filename "$zipname"
    rm -rf ref
    unzip -o "$zipname" -d ref > /dev/null
    datasets rehydrate --directory ref > /dev/null
    fna=$(find ref -name '*.fna' | head -n 1)
    gff=$(find ref -name genomic.gff | head -n 1)
}

echo "$d: trying dataset's own reference accession, $acc"
fetch_and_check ref.zip accession "$acc"

if [[ -z "$gff" ]]; then
    echo "$d: $acc has no GFF on NCBI - falling back to NCBI's reference genome for $species"
    fetch_and_check ref_fallback.zip taxon "$species" --reference
    if [[ -z "$gff" ]]; then
        echo "$d: ERROR - still no GFF found via the species-level reference either"
        exit 1
    fi
    acc=$(basename "$(dirname "$gff")")
    echo "$d: using $acc (NCBI reference genome for $species) instead"
fi

if [[ -z "$fna" ]]; then
    echo "$d: ERROR - no genome FASTA found"
    exit 1
fi

cp "$fna" "$acc.fasta"
cp "$gff" "$acc.gff"
echo "$acc" > used_accession.txt

echo "$d: reference/$acc.fasta and reference/$acc.gff ready"
