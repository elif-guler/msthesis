#!/usr/bin/env bash
set -uo pipefail

BASE_DIR="$(pwd)"
NWK_FILE="${BASE_DIR}/eco33.nwk"
SUMMARY_CSV="gin_mge_summary_ecoli.csv"

echo "dataset,pool,observed,permutations,ge_observed,pvalue" > "${SUMMARY_CSV}"

# 1. Download references into BASE_DIR/reference/<clade>/
python3 resolve_and_download_ecoli.py "${NWK_FILE}"

CLADES=("a" "b1" "b2" "d" "e" "f")

for clade in "${CLADES[@]}"; do
    echo "=================================================="
    echo "==> Running MGE Test for E. coli Clade '${clade}'"
    echo "=================================================="
    
    DOWNLOAD_REF_DIR="${BASE_DIR}/reference/${clade}"
    ACC_FILE="${DOWNLOAD_REF_DIR}/used_accession.txt"
    CLADE_DIR="${BASE_DIR}/${clade}"
    
    if [ ! -f "${ACC_FILE}" ]; then
        echo "[SKIP] Reference accession missing for clade ${clade} at ${ACC_FILE}"
        continue
    fi
    
    ACC=$(cat "${ACC_FILE}")
    FASTA_REF="${DOWNLOAD_REF_DIR}/${ACC}.fasta"
    GFF_REF="${DOWNLOAD_REF_DIR}/${ACC}.gff"
    
    # Locate marker fasta in clade directory
    FUR_MARKERS=""
    if [ -f "${CLADE_DIR}/${clade}.fasta" ]; then
        FUR_MARKERS="${CLADE_DIR}/${clade}.fasta"
    elif [ -f "${CLADE_DIR}/markers.fasta" ]; then
        FUR_MARKERS="${CLADE_DIR}/markers.fasta"
    fi

    if [ -z "${FUR_MARKERS}" ]; then
        echo "[SKIP] Marker FASTA missing in ${CLADE_DIR}"
        continue
    fi

    # 2. Stage reference and script dependencies inside the clade directory
    mkdir -p "${CLADE_DIR}/reference"
    cp "${FASTA_REF}" "${CLADE_DIR}/reference/${ACC}.fasta"
    cp "${GFF_REF}" "${CLADE_DIR}/reference/${ACC}.gff"
    cp "${ACC_FILE}" "${CLADE_DIR}/reference/used_accession.txt"
    cp "${FUR_MARKERS}" "${CLADE_DIR}/fur_unique.fasta"
    
    cp "${BASE_DIR}/annotate_mge.py" "${CLADE_DIR}/"
    cp "${BASE_DIR}/make_intervals.py" "${CLADE_DIR}/"

    # 3. Enter clade folder and run the test script
    cd "${CLADE_DIR}"
    
    if [ -f "${BASE_DIR}/gin_mge_test.sh" ]; then
        bash "${BASE_DIR}/gin_mge_test.sh" "${clade}" "fur_markers"
        
        if [ -f "gin_mge_summary.csv" ]; then
            tail -n +2 gin_mge_summary.csv >> "${BASE_DIR}/${SUMMARY_CSV}"
        fi
    else
        echo "[ERROR] Cannot find gin_mge_test.sh in ${BASE_DIR}"
    fi
    
    cd "${BASE_DIR}"
done

echo "=================================================="
echo "Completed! Summary saved to: ${SUMMARY_CSV}"
echo "=================================================="
