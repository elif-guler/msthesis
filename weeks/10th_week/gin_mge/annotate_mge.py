#!/usr/bin/env python3
"""
Usage:
  1. Observed mode:
     python3 annotate_mge.py --gff <ref.gff> --intervals <intervals.txt>

  2. Shuffle mode (stdin stream):
     shuffle -n 10000 <gff> <intervals> | python3 annotate_mge.py --gff <ref.gff> --stream
"""

import sys
import re
import argparse


def parse_mge_features(gff_path):
    mge_pattern = re.compile(
        r'transposase|integrase|recombinase|phage|prophage|conjugation|plasmid|relaxase|insertion sequence|IS[0-9]',
        re.IGNORECASE
    )
    features = []

    with open(gff_path, 'r') as f:
        for line in f:
            if line.startswith('#') or not line.strip():
                continue
            parts = line.strip().split('\t')
            if len(parts) < 9:
                continue

            chrom = parts[0]
            start = int(parts[3])
            end = int(parts[4])
            attributes = parts[8]

            if mge_pattern.search(attributes):
                features.append((chrom, start, end))

    return features


def count_overlaps(intervals, mge_features):
    mge_by_chrom = {}
    for chrom, s, e in mge_features:
        mge_by_chrom.setdefault(chrom, []).append((s, e))

    count = 0
    for chrom, s, e in intervals:
        if chrom not in mge_by_chrom:
            continue
        for ms, me in mge_by_chrom[chrom]:
            if max(s, ms) <= min(e, me):  # 1-bp overlap check
                count += 1
                break
    return count


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--gff', required=True, help="Path to reference GFF")
    parser.add_argument('--intervals', help="Intervals file for observed mode")
    parser.add_argument('--stream', action='store_true', help="Read shuffle blocks from stdin")
    args = parser.parse_args()

    mge_features = parse_mge_features(args.gff)

    if args.intervals:
        intervals = []
        with open(args.intervals) as f:
            for line in f:
                if not line.strip():
                    continue
                chrom, start, end = line.strip().split('\t')[:3]
                intervals.append((chrom, int(start), int(end)))
        print(count_overlaps(intervals, mge_features))

    elif args.stream:
        current_intervals = []
        for line in sys.stdin:
            line = line.strip()
            if not line:
                if current_intervals:
                    print(count_overlaps(current_intervals, mge_features))
                    current_intervals = []
            else:
                parts = line.split('\t')
                if len(parts) >= 3 and parts[0] != "#Chr":
                    current_intervals.append((parts[0], int(parts[1]), int(parts[2])))

        if current_intervals:
            print(count_overlaps(current_intervals, mge_features))


if __name__ == "__main__":
    main()
