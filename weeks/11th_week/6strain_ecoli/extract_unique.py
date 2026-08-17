#!/usr/bin/env python3
import sys

# usage: extract_unique.py <input_fasta> <csv_with_found_column> <output_fasta>
input_fasta = sys.argv[1]
csv_path = sys.argv[2]
output_fasta = sys.argv[3]

# read the csv, collect ids where found == 0 (not found in the other tool's markers)
unique_ids = set()
first_line = True
for line in open(csv_path):
    if first_line:
        first_line = False
        continue
    parts = line.strip().split(",")
    marker_id = parts[0]
    found = parts[4]
    if found == "0":
        unique_ids.add(marker_id)

# copy over just those sequences
out = open(output_fasta, "w")
keep = False
n_written = 0
for line in open(input_fasta):
    if line.startswith(">"):
        name = line[1:].split()[0]
        keep = name in unique_ids
        if keep:
            n_written += 1
    if keep:
        out.write(line)
out.close()

print(n_written, "unique sequences written to", output_fasta)
