#!/bin/bash
# Run Hashcat (GPU only) on remaining uncracked hashes.
# Uses your GPU (Metal on Apple Silicon, CUDA/OpenCL elsewhere).
# Usage: ./run_gpu_remaining.sh
set -e
cd "$(dirname "$0")"
PROJECT="$PWD"
WORDLIST="input/rockyou_top1m.txt"
REMAINING="input/hashes_remaining.txt"

# Prefer GPU device (1 = first GPU; Hashcat -I shows Metal GPU as #01 on Mac)
DEVICE="${HASHCAT_DEVICE:-1}"
# Workload 4 = high GPU utilization
WORKLOAD=4

# Resolve Hashcat rules (Homebrew path may vary by version)
for RULES in /opt/homebrew/Cellar/hashcat/*/share/doc/hashcat/rules /usr/local/Cellar/hashcat/*/share/doc/hashcat/rules; do
  [[ -d "$RULES" ]] && break
done
RULES="${RULES:-/opt/homebrew/Cellar/hashcat/7.1.2/share/doc/hashcat/rules}"

OUT="input/hc_gpu.txt"
merge_and_update() {
  if [[ -f "$OUT" ]]; then
    ./merge_hashcat.sh "$OUT" >> cracked.txt 2>/dev/null || true
    ./update_remaining.sh
  fi
}

if [[ ! -f "$REMAINING" ]]; then
  echo "No remaining hashes. Run: ./update_remaining.sh (and ensure cracked.txt is up to date)."
  exit 1
fi
n=$(wc -l < "$REMAINING")
echo "=== Hashcat (GPU) on $n remaining hashes (device $DEVICE, -w $WORKLOAD) ==="

# Run GPU attacks in sequence; each run may crack more, so we keep same $REMAINING path
rm -f "$OUT"

echo "[1/6] Wordlist (straight)"
hashcat -m 500 -a 0 -w $WORKLOAD -d "$DEVICE" -O "$REMAINING" "$WORDLIST" -o "$OUT" --quiet 2>/dev/null || true
merge_and_update

echo "[2/6] Wordlist + 2 digits"
hashcat -m 500 -a 6 -w $WORKLOAD -d "$DEVICE" -O "$REMAINING" "$WORDLIST" "?d?d" -o "$OUT" --quiet 2>/dev/null || true
merge_and_update

echo "[3/6] Wordlist + 3 digits"
hashcat -m 500 -a 6 -w $WORKLOAD -d "$DEVICE" -O "$REMAINING" "$WORDLIST" "?d?d?d" -o "$OUT" --quiet 2>/dev/null || true
merge_and_update

echo "[4/6] 2 digits + wordlist"
hashcat -m 500 -a 7 -w $WORKLOAD -d "$DEVICE" -O "$REMAINING" "?d?d" "$WORDLIST" -o "$OUT" --quiet 2>/dev/null || true
merge_and_update

echo "[5/6] Wordlist + best66 rules"
[[ -d "$RULES" ]] && hashcat -m 500 -a 0 -w $WORKLOAD -d "$DEVICE" -O "$REMAINING" "$WORDLIST" -r "$RULES/best66.rule" -o "$OUT" --quiet 2>/dev/null || true
merge_and_update

echo "[6/6] Wordlist + dive rules"
[[ -d "$RULES" ]] && hashcat -m 500 -a 0 -w $WORKLOAD -d "$DEVICE" -O "$REMAINING" "$WORDLIST" -r "$RULES/dive.rule" -o "$OUT" --quiet 2>/dev/null || true
merge_and_update

./update_remaining.sh
echo "GPU run done. Remaining: $(wc -l < "$REMAINING")"
