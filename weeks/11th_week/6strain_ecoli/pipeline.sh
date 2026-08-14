#!/usr/bin/env bash
set -euo pipefail

# Find where the 'all' directory actually lives
BASE_DIR="$(pwd)"

if [ -d "${BASE_DIR}/all" ]; then
    ALL_DIR="${BASE_DIR}/all"
elif [ -d "${BASE_DIR}/../all" ]; then
    ALL_DIR="$(cd "${BASE_DIR}/../all" && pwd)"
else
    echo "Error: Could not find 'all' directory in ${BASE_DIR} or ${BASE_DIR}/.."
    exit 1
fi

echo "Using genome directory: ${ALL_DIR}"

# Clade and Node mapping ("clade:node")
CLADE_NODES=(
    "a:15"
    "b1:20"
    "b2:3"
    "d:7"
    "e:11"
    "f:7"
)

process_clade() {
    local clade="$1"
    local node="$2"

    echo "--------------------------------------------------"
    echo "==> Processing Clade '${clade}' (Node ${node})..."
    echo "--------------------------------------------------"

    # Navigate into clade directory
    cd "${BASE_DIR}/${clade}"

    mkdir -p targets neighbors

    # Helper function to find real target file regardless of extension
    find_genome_file() {
        local acc="$1"
        # Try exact match first, then wildcard matches (*.fasta, *.fna, etc.)
        for f in "${ALL_DIR}/${acc}" "${ALL_DIR}/${acc}.fasta" "${ALL_DIR}/${acc}.fna" "${ALL_DIR}/${acc}"*; do
            if [ -e "$f" ]; then
                # Resolve broken relative symlinks to absolute physical paths
                readlink -f "$f"
                return 0
            fi
        done
        return 1
    }

    # Populate targets symlinks
    pickle "$node" eco33.nwk |
        grep -v '^#' |
        while read -r a; do
            if real_path=$(find_genome_file "$a"); then
                ln -sf "$real_path" "targets/${a}.fasta"
            else
                echo "Warning: No matching genome file found for '$a' in ${ALL_DIR}"
            fi
        done

    # Populate neighbors symlinks (complement)
    pickle -c "$node" eco33.nwk |
        grep -v '^#' |
        while read -r a; do
            if real_path=$(find_genome_file "$a"); then
                ln -sf "$real_path" "neighbors/${a}.fasta"
            else
                echo "Warning: No matching genome file found for '$a' in ${ALL_DIR}"
            fi
        done

    # Run Fur DB creation
    echo "Creating Fur database for ${clade}..."
    /usr/bin/time -v -o makeFurDb.res \
        makeFurDb -T 1 -t targets -n neighbors -o -d "${clade}.db"

    # Run Fur analysis
    echo "Running Fur analysis for ${clade}..."
    /usr/bin/time -v -o fur.res \
        fur -m -d "${clade}.db" > "${clade}.fasta"

    # Return to top directory
    cd "$BASE_DIR"

    echo "==> Completed Clade ${clade}."
}

# Execute loop across all defined clades
for pair in "${CLADE_NODES[@]}"; do
    clade="${pair%%:*}"
    node="${pair##*:}"
    process_clade "$clade" "$node"
done

echo "=========================================="
echo "All clade subdirectories processed!"
echo "=========================================="
