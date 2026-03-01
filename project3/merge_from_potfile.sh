#!/bin/bash
# Merge any new cracks from Hashcat potfile into cracked.txt and update remaining.
set -e
cd "$(dirname "$0")"
hashcat -m 500 --show input/hashes_remaining.txt 2>/dev/null > input/pot_cracked.txt || true
if [[ -s input/pot_cracked.txt ]]; then
  ./merge_hashcat.sh input/pot_cracked.txt >> cracked.txt
  ./update_remaining.sh
  awk -F: 'NR==FNR{seen[$1]=1;next} ($1 in seen){next} 1' cracked.txt input/xing.kai@northeastern.edu.shadow > input/shadow_remaining.txt
  echo "Merged $(wc -l < input/pot_cracked.txt) new cracks."
else
  echo "No new cracks in potfile."
fi
