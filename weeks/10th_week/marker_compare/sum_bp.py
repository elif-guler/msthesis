#!/usr/bin/env python3
"""
Usage: sum_bp.py <markers.fasta> <csv_with_found_column> <found_value>

Sums the total basepairs (N's excluded) of every marker in <markers.fasta>
whose "found" value in <csv_with_found_column> matches <found_value> (0 or 1).
Prints just the total, so it's easy to use from a wrapper script.
"""
import sys

markers_fasta = sys.argv[1]
csv_path = sys.argv[2]
found_value = sys.argv[3]

# collect marker ids that match the wanted found value
wanted_ids = set()
first_line = True
for line in open(csv_path):
    if first_line:
        first_line = False
        continue
    parts = line.strip().split(",")
    marker_id = parts[0]
    found = parts[4]
    if found == found_value:
        wanted_ids.add(marker_id)

# sum non-N bases for those markers
total_bp = 0
keep = False
for line in open(markers_fasta):
    if line.startswith(">"):
        name = line[1:].split()[0]
        keep = name in wanted_ids
    elif keep:
        seq = line.strip().upper()
        total_bp += len(seq) - seq.count("N")

print(total_bp)
