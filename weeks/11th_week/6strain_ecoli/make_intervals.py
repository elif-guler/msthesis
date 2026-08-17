#!/usr/bin/env python3
"""
Usage: make_intervals.py <markers.fasta> <reference.fasta> <output_intervals.txt>

BLASTs each marker against the reference genome, keeps the best hit per
marker, and writes its coordinates as a 3-column "chr start end" file -
the format gin's annotate/shuffle expect. Markers with no hit on the
reference are skipped (silently - printed count at the end).
"""
import sys
import subprocess


def best_hits(query_fasta, subject_fasta):
    cmd = [
        "blastn",
        "-query", query_fasta, "-subject", subject_fasta,
        "-outfmt", "6 qseqid sseqid sstart send bitscore",
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    best = {}
    for line in result.stdout.strip().split("\n"):
        if line == "":
            continue
        qseqid, sseqid, sstart, send, bitscore = line.split("\t")
        sstart, send, bitscore = int(sstart), int(send), float(bitscore)
        start, end = min(sstart, send), max(sstart, send)
        if qseqid not in best or bitscore > best[qseqid][3]:
            best[qseqid] = (sseqid, start, end, bitscore)
    return best


def count_markers(fasta_path):
    n = 0
    for line in open(fasta_path):
        if line.startswith(">"):
            n += 1
    return n


def main():
    if len(sys.argv) < 4:
        sys.exit(__doc__)

    markers_fasta = sys.argv[1]
    reference_fasta = sys.argv[2]
    output_path = sys.argv[3]

    n_total = count_markers(markers_fasta)
    hits = best_hits(markers_fasta, reference_fasta)

    with open(output_path, "w") as out:
        for marker, (chrom, start, end, bitscore) in hits.items():
            out.write(f"{chrom}\t{start}\t{end}\n")

    print(f"{len(hits)}/{n_total} markers placed on the reference")
    print("wrote", output_path)


if __name__ == "__main__":
    main()
