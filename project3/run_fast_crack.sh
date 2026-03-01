#!/bin/bash
# Speed up remaining: run John (CPU) + Hashcat (GPU) in parallel with fast attacks.
# Usage: ./run_fast_crack.sh
set -e
cd "$(dirname "$0")"
PROJECT="$PWD"
WORDLIST="input/rockyou_top1m.txt"
REMAINING="input/hashes_remaining.txt"
SHADOW_REM="input/shadow_remaining.txt"
HASHCAT_RULES="/opt/homebrew/Cellar/hashcat/7.1.2/share/doc/hashcat/rules"

echo "=== 1. Hashcat (GPU) hybrid: wordlist + 2 digits ==="
hashcat -m 500 -a 6 -w 4 -O "$REMAINING" "$WORDLIST" "?d?d" -o input/hc_hybrid.txt --quiet 2>/dev/null || true
echo "=== 2. Hashcat (GPU) hybrid: wordlist + 3 digits ==="
hashcat -m 500 -a 6 -w 4 -O "$REMAINING" "$WORDLIST" "?d?d?d" -o input/hc_hybrid.txt --quiet 2>/dev/null || true
echo "=== 3. Hashcat (GPU) hybrid: 2 digits + wordlist ==="
hashcat -m 500 -a 7 -w 4 -O "$REMAINING" "?d?d" "$WORDLIST" -o input/hc_hybrid.txt --quiet 2>/dev/null || true
echo "=== 4. Hashcat (GPU) rockyou + best66 rules ==="
hashcat -m 500 -a 0 -w 4 -O "$REMAINING" "$WORDLIST" -r "$HASHCAT_RULES/best66.rule" -o input/hc_hybrid.txt --quiet 2>/dev/null || true

echo "Hashcat batch done. Merge with: ./merge_hashcat.sh input/hc_hybrid.txt >> cracked.txt && ./update_remaining.sh"
