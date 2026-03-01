#!/bin/bash
# Build hashes_remaining.txt (one hash per line) for users not in cracked.txt
set -e
cd "$(dirname "$0")"
SHADOW="input/xing.kai@northeastern.edu.shadow"
CRACKED="cracked.txt"
REMAINING="input/hashes_remaining.txt"
awk -F: 'NR==FNR { seen[$1]=1; next } !($1 in seen) { sub(/^[^:]+:/,""); print }' "$CRACKED" "$SHADOW" > "$REMAINING.tmp"
mv "$REMAINING.tmp" "$REMAINING"
echo "Remaining hashes: $(wc -l < "$REMAINING")"
