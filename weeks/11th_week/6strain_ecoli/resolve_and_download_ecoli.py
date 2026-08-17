#!/usr/bin/env python3
import sys
import os
import subprocess
import json
import re

CLADE_NODES = {
    "a": "15",
    "b1": "20",
    "b2": "3",
    "d": "7",
    "e": "11",
    "f": "7"
}

def get_target_accessions(node, nwk_file="eco33.nwk"):
    try:
        cmd = f"pickle {node} {nwk_file}"
        output = subprocess.check_output(cmd, shell=True, text=True)
        accessions = [line.strip() for line in output.splitlines() if line.strip() and not line.startswith("#")]
        return accessions
    except subprocess.CalledProcessError as e:
        sys.stderr.write(f"[ERROR] Failed to run pickle for node {node}: {e}\n")
        return []

def clean_accession(acc_str):
    match = re.search(r'(GC[AF]_\d+\.\d+)', acc_str)
    if match:
        return match.group(1)
    return acc_str.split('.')[0] + '.' + acc_str.split('.')[1] if '.' in acc_str else acc_str

def download_reference_and_gff(clade, accession, out_dir="reference"):
    print(f"\n==> Processing Clade '{clade}': Primary Target Accession = {accession}")
    clade_ref_dir = os.path.join(out_dir, clade)
    os.makedirs(clade_ref_dir, exist_ok=True)
    
    zip_file = os.path.join(clade_ref_dir, f"{accession}.zip")
    
    ds_cmd = (
        f"datasets download genome accession {accession} "
        f"--include genome,gff3 --filename {zip_file}"
    )
    print(f"Downloading NCBI dataset for {accession}...")
    res = subprocess.run(ds_cmd, shell=True)
    
    if res.returncode != 0 or not os.path.exists(zip_file):
        sys.stderr.write(f"[ERROR] NCBI datasets download failed for accession {accession}\n")
        return False

    unzip_cmd = f"unzip -o -q {zip_file} -d {clade_ref_dir}"
    subprocess.run(unzip_cmd, shell=True)
    
    data_path = os.path.join(clade_ref_dir, "ncbi_dataset", "data", accession)
    fna_file, gff_file = None, None
    
    if os.path.exists(data_path):
        for f in os.listdir(data_path):
            if f.endswith(".fna") or f.endswith(".fa") or f.endswith(".fasta"):
                fna_file = os.path.join(data_path, f)
            elif f.endswith(".gff") or f.endswith(".gff3"):
                gff_file = os.path.join(data_path, f)

    if not fna_file or not gff_file:
        sys.stderr.write(f"[WARNING] Missing FNA or GFF for {accession}.\n")
        return False

    target_fna = os.path.join(clade_ref_dir, f"{accession}.fasta")
    target_gff = os.path.join(clade_ref_dir, f"{accession}.gff")
    
    os.system(f"cp '{fna_file}' '{target_fna}'")
    os.system(f"cp '{gff_file}' '{target_gff}'")

    with open(os.path.join(clade_ref_dir, "used_accession.txt"), "w") as f:
        f.write(f"{accession}\n")

    print(f"[SUCCESS] Prepared reference for clade '{clade}' ({accession})")
    return True

def main():
    nwk_file = sys.argv[1] if len(sys.argv) > 1 else "eco33.nwk"
    
    if not os.path.exists(nwk_file):
        sys.stderr.write(f"[ERROR] Tree file '{nwk_file}' not found.\n")
        sys.exit(1)

    mapping_summary = {}
    for clade, node in CLADE_NODES.items():
        targets = get_target_accessions(node, nwk_file)
        if not targets:
            continue
        
        primary_acc = clean_accession(targets[0])
        mapping_summary[clade] = {
            "node": node,
            "primary_accession": primary_acc,
            "total_targets_in_clade": len(targets)
        }
        download_reference_and_gff(clade, primary_acc)

    with open("ecoli_clade_references.json", "w") as f:
        json.dump(mapping_summary, f, indent=2)

if __name__ == "__main__":
    main()
