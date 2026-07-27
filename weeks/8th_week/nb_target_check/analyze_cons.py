#!/usr/bin/env python3
"""
Usage: analyze_cons_div.py <signatures.fasta> <targets_dir> <neighbors_dir> <output.csv> [genome_ext]

Same logic as the original script - BLASTs a set of signature/marker
sequences against every target and neighbor genome, and reports, per
signature: conservation (how identical it is across targets), divergence
(how different it is from neighbors), and the fraction of neighbors it
still hits at all.
"""
import sys
import glob
import subprocess
from collections import defaultdict


def read_fasta_lengths(path):
    lengths = {}
    name = None
    length = 0
    for line in open(path):
        if line.startswith(">"):
            if name is not None:
                lengths[name] = length
            name = line[1:].split()[0]
            length = 0
        else:
            length += len(line.strip())
    if name is not None:
        lengths[name] = length
    return lengths


def best_hits(query_fasta, genome_fasta):
    cmd = [
        "blastn", "-task", "blastn",
        "-query", query_fasta, "-subject", genome_fasta,
        "-evalue", "1e-5",
        "-max_hsps", "1000", "-max_target_seqs", "50000",
        "-outfmt", "6 qseqid nident mismatch gaps bitscore",
    ]
    output = subprocess.run(cmd, capture_output=True, text=True, check=True).stdout
    best = {}
    for line in output.strip().split("\n"):
        if line == "":
            continue
        qseqid, nident, mismatch, gaps, bitscore = line.split("\t")
        nident, mismatch, gaps, bitscore = int(nident), int(mismatch), int(gaps), float(bitscore)
        if qseqid not in best or bitscore > best[qseqid][3]:
            best[qseqid] = (nident, mismatch, gaps, bitscore)
    return best


def main():
    if len(sys.argv) < 5:
        sys.exit(__doc__)

    signatures_fasta = sys.argv[1]
    targets_dir = sys.argv[2]
    nontargets_dir = sys.argv[3]
    output_csv = sys.argv[4]
    genome_ext = sys.argv[5] if len(sys.argv) > 5 else "fasta"

    sig_lengths = read_fasta_lengths(signatures_fasta)
    sig_ids = list(sig_lengths.keys())

    target_files = sorted(glob.glob(targets_dir + "/*." + genome_ext))
    nontarget_files = sorted(glob.glob(nontargets_dir + "/*." + genome_ext))
    n_target = len(target_files)
    n_nontarget = len(nontarget_files)
    print(n_target, "target genomes,", n_nontarget, "non-target genomes,", len(sig_ids), "signatures")

    if n_target == 0 or n_nontarget == 0 or len(sig_ids) == 0:
        print("Nothing to do (empty signatures/targets/neighbors) - writing header-only CSV.")
        with open(output_csv, "w") as out:
            out.write("signature_id,length,conservation,divergence,fraction_nontarget_hit,score\n")
        return

    identical_bases = defaultdict(int)
    diff_bases = defaultdict(int)
    nontarget_hits = defaultdict(int)

    for genome_file in target_files:
        print("target:", genome_file)
        hits = best_hits(signatures_fasta, genome_file)
        for sig in sig_ids:
            if sig in hits:
                nident, mismatch, gaps, bitscore = hits[sig]
                identical_bases[sig] += nident

    for genome_file in nontarget_files:
        print("nontarget:", genome_file)
        hits = best_hits(signatures_fasta, genome_file)
        for sig in sig_ids:
            if sig in hits:
                nident, mismatch, gaps, bitscore = hits[sig]
                diff_bases[sig] += mismatch + gaps
                nontarget_hits[sig] += 1

    with open(output_csv, "w") as out:
        out.write("signature_id,length,conservation,divergence,fraction_nontarget_hit,score\n")
        for sig in sig_ids:
            L = sig_lengths[sig]
            conservation = identical_bases[sig] / (L * n_target)
            divergence = diff_bases[sig] / (L * n_nontarget)
            frac_hit = nontarget_hits[sig] / n_nontarget
            score = conservation + divergence
            out.write(f"{sig},{L},{conservation:.4f},{divergence:.4f},{frac_hit:.4f},{score:.4f}\n")

    print("wrote", output_csv)


if __name__ == "__main__":
    main()
