#!/usr/bin/env python3
import subprocess

# ---- edit these ----
seqwin_markers = "seqwin-out/signatures.fasta"
fur_markers = "markers.fasta"
output_csv = "seqwin_in_fur.csv"
min_identity = 95   # percent identity needed to count as "found"
min_coverage = 90   # percent of the marker length needed to count as "found"
# ---------------------

# get the length of each seqwin marker
lengths = {}
name = None
length = 0
for line in open(seqwin_markers):
    if line.startswith(">"):
        if name is not None:
            lengths[name] = length
        name = line[1:].split()[0]
        length = 0
    else:
        length += len(line.strip())
if name is not None:
    lengths[name] = length

# blast all seqwin markers against fur markers in one go
cmd = [
    "blastn",
    "-query", seqwin_markers,
    "-subject", fur_markers,
    "-outfmt", "6 qseqid pident length",
]
result = subprocess.run(cmd, capture_output=True, text=True)
lines = result.stdout.strip().split("\n")

# keep the best (longest) hit per seqwin marker
best_identity = {}
best_length = {}
for line in lines:
    if line == "":
        continue
    qseqid, pident, hit_length = line.split("\t")
    pident = float(pident)
    hit_length = int(hit_length)
    if qseqid not in best_length or hit_length > best_length[qseqid]:
        best_length[qseqid] = hit_length
        best_identity[qseqid] = pident

# write results
out = open(output_csv, "w")
out.write("marker,length,identity,coverage,found\n")

n_found = 0
for marker in lengths:
    marker_length = lengths[marker]
    if marker in best_length:
        identity = best_identity[marker]
        coverage = 100 * best_length[marker] / marker_length
        found = identity >= min_identity and coverage >= min_coverage
    else:
        identity = 0
        coverage = 0
        found = False
    if found:
        n_found += 1
    out.write(f"{marker},{marker_length},{identity:.1f},{coverage:.1f},{int(found)}\n")
out.close()

print(len(lengths), "seqwin markers total")
print(n_found, "found in fur markers")
print("wrote", output_csv)
