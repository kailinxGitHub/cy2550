# Project 3: Password Cracking

## Deliverables (submit these)

- **cracked.txt** – One line per cracked user: `username:crackedpassword`
- **email.txt** – Your Northeastern email in plaintext (already set to `xing.kai@northeastern.edu`)

## Your shadow file

- **Path:** `project3/input/xing.kai@northeastern.edu.shadow`
- **Format:** 50 lines, `username:$1$...` (MD5 crypt)

## Cracking on Mac (native, no VM)

### Option A: John the Ripper

```bash
cd "/Users/kailinx/Desktop/CY 2550/cy2550/project3"
john --format=md5crypt input/xing.kai@northeastern.edu.shadow
```

With a wordlist and rules (recommended for easy/medium):

```bash
john --wordlist=/usr/share/wordlists/rockyou.txt --rules input/xing.kai@northeastern.edu.shadow
```

Show cracked passwords:

```bash
john --show --format=md5crypt input/xing.kai@northeastern.edu.shadow
```

### Option B: Hashcat

Hashes must be in `hash only` form. Your `input/hashes_only.txt` may already be prepared; if not, strip the `username:` part. Hashcat mode for MD5 crypt is **500**.

```bash
hashcat -m 500 -a 0 input/hashes_only.txt /path/to/wordlist.txt
```

## Building cracked.txt

After each crack, add lines to **project3/cracked.txt** in this format, one per line:

```
username:crackedpassword
```

Example:

```
jdoe:password123
award:summer2024
```

No spaces around the colon. One entry per line. Create this file in `project3/` and keep it updated as you crack more passwords.

## Speed up the remaining

- **GPU only (recommended for remaining):** Run Hashcat on the GPU for all remaining hashes (Metal on Apple Silicon, CUDA/OpenCL elsewhere). Auto-merges cracks and updates the remaining list after each attack:
  ```bash
  ./run_gpu_remaining.sh
  ```
- **CPU + GPU in parallel:** Run John (CPU) on `input/shadow_remaining.txt` and Hashcat (GPU) on `input/hashes_remaining.txt` at the same time. To rebuild the “remaining” files after new cracks: `./update_remaining.sh` then `awk -F: 'NR==FNR{seen[$1]=1;next} ($1 in seen){next} 1' cracked.txt input/xing.kai@northeastern.edu.shadow > input/shadow_remaining.txt`
- **Faster Hashcat attacks:** Try hybrid attacks so the GPU has lots of work and finishes sooner per run:
  - Wordlist + 2 digits: `hashcat -m 500 -a 6 -w 4 input/hashes_remaining.txt input/rockyou_top1m.txt "?d?d" -o input/hc_hybrid.txt`
  - Wordlist + 3 digits: same but `"?d?d?d"`
  - 2 digits + wordlist: `hashcat -m 500 -a 7 -w 4 input/hashes_remaining.txt "?d?d" input/rockyou_top1m.txt -o input/hc_hybrid.txt`
- After any Hashcat run, merge into cracked: `./merge_hashcat.sh input/hc_hybrid.txt >> cracked.txt` then `./update_remaining.sh`.

## Tips (from assignment)

1. **Start early** – Hard and “elite” passwords can take days.
2. **Easy (~⅓):** Wordlist + simple rules, often minutes.
3. **Medium (~⅓):** Wordlist + built-in permutation rules, up to ~24 hours.
4. **Hard (~⅓):** Custom rules / masks, several days.
5. **Elites (~3):** Brute-force only; run for many days.
6. If nothing new cracks in ~24 hours, try a different strategy (other wordlist, rules, or attack mode).
7. Wordlists: e.g. [Probable-Wordlists](https://github.com/berzerk0/Probable-Wordlists).

## Submission

1. Ensure `cracked.txt` and `email.txt` are in `~/cy2550/project3` (or your repo’s `project3/`).
2. Push to GitHub.
3. Submit the repository to Gradescope.
4. Check the auto-grader output (43 passwords = full credit; 44–50 = extra credit).
