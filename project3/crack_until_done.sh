#!/bin/bash
# Run Hashcat attacks in sequence; merge into cracked.txt and update remaining after each run.
# Stops when 50 cracked or no new cracks from a full round.
set -e
cd "$(dirname "$0")"
WORDLIST="input/rockyou_top1m.txt"
REMAINING="input/hashes_remaining.txt"
SHADOW="input/xing.kai@northeastern.edu.shadow"
RULES="/opt/homebrew/Cellar/hashcat/7.1.2/share/doc/hashcat/rules"
OUT="input/hc_batch.txt"

merge_one() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    if [[ "$line" =~ ^([^:]+):(.+)$ ]]; then
      hash="${BASH_REMATCH[1]}"
      pass="${BASH_REMATCH[2]}"
      user=$(awk -F: -v h="$hash" '$2 == h {print $1; exit}' "$SHADOW")
      [[ -n "$user" ]] && echo "$user:$pass"
    fi
  done < "$f"
}

update_shadow_remaining() {
  awk -F: 'NR==FNR{seen[$1]=1;next} ($1 in seen){next} 1' cracked.txt "$SHADOW" > input/shadow_remaining.txt
}

round=0
while true; do
  round=$((round+1))
  ./update_remaining.sh
  n=$(wc -l < "$REMAINING" 2>/dev/null || echo 0)
  [[ "$n" -eq 0 ]] && echo "All 50 cracked." && exit 0
  echo "=== Round $round: $n hashes remaining ==="

  # Clear pot so we don't skip; use fresh output file
  rm -f "$OUT"

  # 1) Straight wordlist
  hashcat -m 500 -a 0 -w 4 -O "$REMAINING" "$WORDLIST" -o "$OUT" --quiet 2>/dev/null || true
  merged=$(merge_one "$OUT")
  if [[ -n "$merged" ]]; then echo "$merged" >> cracked.txt; echo "Merged $(echo "$merged" | wc -l) from wordlist"; ./update_remaining.sh; update_shadow_remaining; fi

  ./update_remaining.sh
  n=$(wc -l < "$REMAINING" 2>/dev/null || echo 0)
  [[ "$n" -eq 0 ]] && echo "All 50 cracked." && exit 0

  # 2) Wordlist + 2 digits
  hashcat -m 500 -a 6 -w 4 -O "$REMAINING" "$WORDLIST" "?d?d" -o "$OUT" --quiet 2>/dev/null || true
  merged=$(merge_one "$OUT")
  if [[ -n "$merged" ]]; then echo "$merged" >> cracked.txt; echo "Merged $(echo "$merged" | wc -l) from +2d"; ./update_remaining.sh; update_shadow_remaining; fi

  ./update_remaining.sh
  n=$(wc -l < "$REMAINING" 2>/dev/null || echo 0)
  [[ "$n" -eq 0 ]] && echo "All 50 cracked." && exit 0

  # 3) Wordlist + 3 digits
  hashcat -m 500 -a 6 -w 4 -O "$REMAINING" "$WORDLIST" "?d?d?d" -o "$OUT" --quiet 2>/dev/null || true
  merged=$(merge_one "$OUT")
  if [[ -n "$merged" ]]; then echo "$merged" >> cracked.txt; echo "Merged $(echo "$merged" | wc -l) from +3d"; ./update_remaining.sh; update_shadow_remaining; fi

  ./update_remaining.sh
  n=$(wc -l < "$REMAINING" 2>/dev/null || echo 0)
  [[ "$n" -eq 0 ]] && echo "All 50 cracked." && exit 0

  # 4) best66 rules
  hashcat -m 500 -a 0 -w 4 -O "$REMAINING" "$WORDLIST" -r "$RULES/best66.rule" -o "$OUT" --quiet 2>/dev/null || true
  merged=$(merge_one "$OUT")
  if [[ -n "$merged" ]]; then echo "$merged" >> cracked.txt; echo "Merged $(echo "$merged" | wc -l) from best66"; ./update_remaining.sh; update_shadow_remaining; fi

  ./update_remaining.sh
  n=$(wc -l < "$REMAINING" 2>/dev/null || echo 0)
  [[ "$n" -eq 0 ]] && echo "All 50 cracked." && exit 0

  # 5) dive rules
  hashcat -m 500 -a 0 -w 4 -O "$REMAINING" "$WORDLIST" -r "$RULES/dive.rule" -o "$OUT" --quiet 2>/dev/null || true
  merged=$(merge_one "$OUT")
  if [[ -n "$merged" ]]; then echo "$merged" >> cracked.txt; echo "Merged $(echo "$merged" | wc -l) from dive"; ./update_remaining.sh; update_shadow_remaining; fi

  ./update_remaining.sh
  n=$(wc -l < "$REMAINING" 2>/dev/null || echo 0)
  [[ "$n" -eq 0 ]] && echo "All 50 cracked." && exit 0

  echo "Round $round complete. Still $n remaining. Running another round..."
done
