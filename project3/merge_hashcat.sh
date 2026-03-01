#!/bin/bash
# Merge Hashcat output (hash:password) into cracked.txt using shadow for username lookup.
set -e
SHADOW="input/xing.kai@northeastern.edu.shadow"
CRACKED="cracked.txt"
HASHFILE="$1"
if [[ ! -f "$HASHFILE" ]]; then echo "Usage: $0 <hashcat_output_file>"; exit 1; fi
declare -A hash_to_user
while IFS= read -r line; do
  if [[ "$line" =~ ^([^:]+):(.+)$ ]]; then
    user="${BASH_REMATCH[1]}"
    hash="${BASH_REMATCH[2]}"
    hash_to_user["$hash"]="$user"
  fi
done < "$SHADOW"
while IFS= read -r line; do
  if [[ "$line" =~ ^([^:]+):(.+)$ ]]; then
    hash="${BASH_REMATCH[1]}"
    pass="${BASH_REMATCH[2]}"
    user="${hash_to_user["$hash"]}"
    if [[ -n "$user" ]]; then
      echo "$user:$pass"
    fi
  fi
done < "$HASHFILE"
exit 0
