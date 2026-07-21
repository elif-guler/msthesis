#!/usr/bin/env python3

import glob
import subprocess
from collections import defaultdict

# ---- edit these ----
signatures_fasta = "markers.fasta"
targets_dir = "targets"
nontargets_dir = "neighbors"
genome_ext = "fasta"
output_csv = "cons_div_results.csv"
# ---------------------


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
    # BLAST the signatures against one genome, keep best hit per signature
    cmd = [
        "blastn", "-task", "blastn",
        "-query", query_fasta, "-subject", genome_fasta,
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


sig_lengths = read_fasta_lengths(signatures_fasta)
sig_ids = list(sig_lengths.keys())

target_files = sorted(glob.glob(targets_dir + "/*." + genome_ext))
nontarget_files = sorted(glob.glob(nontargets_dir + "/*." + genome_ext))
n_target = len(target_files)
n_nontarget = len(nontarget_files)
print(n_target, "target genomes,", n_nontarget, "non-target genomes,", len(sig_ids), "signatures")

identical_bases = defaultdict(int)   # numerator for conservation
diff_bases = defaultdict(int)        # numerator for divergence
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

out = open(output_csv, "w")
out.write("signature_id,length,conservation,divergence,fraction_nontarget_hit,score\n")
for sig in sig_ids:
    L = sig_lengths[sig]
    conservation = identical_bases[sig] / (L * n_target)
    divergence = diff_bases[sig] / (L * n_nontarget)
    frac_hit = nontarget_hits[sig] / n_nontarget
    score = conservation + divergence
    out.write(f"{sig},{L},{conservation:.4f},{divergence:.4f},{frac_hit:.4f},{score:.4f}\n")
out.close()

print("wrote", output_csv)
