#!/usr/bin/env bash
# pass-store.sh — let an agent WRITE a secret into the agent/ subtree.
#
# Unlike reading (pass-run.sh), writing a pass entry is an encryption-only
# operation — it needs only the agent/ subtree's public key, never the
# passphrase-protected private key. So this needs no pinentry approval:
# storing a value the agent already has (or generating one it never sees)
# doesn't weaken the read-side guarantee pass-run.sh enforces, since the
# value still can't come back out without a human approving a decrypt.
#
# Usage:
#   pass-store.sh --secret agent/<name> [--full]          # value on stdin
#   pass-store.sh --secret agent/<name> --generate [LEN]   # random value, never shown
#
#   --full       Store stdin verbatim (multi-line) instead of trimming to
#                the first line.
#   --generate   Generate a random secret via `pass generate` instead of
#                reading stdin. LEN defaults to 32. The value is never
#                printed or returned — use this when the agent doesn't
#                need to know the value itself (e.g. a fresh internal
#                service password).
#
# Examples:
#   echo "$NEW_API_KEY" | pass-store.sh --secret agent/openai-api-key
#   pass-store.sh --secret agent/internal-db-password --generate 40

set -euo pipefail

die() { echo "pass-store: $*" >&2; exit 1; }

cmd_help() { sed -n '2,/^set -euo/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; }

command -v pass >/dev/null 2>&1 || die "pass(1) not found on PATH"

name=""
want_full=false
want_generate=false
gen_len=32

while [[ $# -gt 0 ]]; do
  case "$1" in
    --secret)
      [[ $# -ge 2 ]] || die "--secret requires a value"
      name="$2"
      shift 2
      ;;
    --full)
      want_full=true
      shift
      ;;
    --generate)
      want_generate=true
      shift
      if [[ $# -ge 1 && "$1" =~ ^[0-9]+$ ]]; then
        gen_len="$1"
        shift
      fi
      ;;
    -h|--help)
      cmd_help
      exit 0
      ;;
    *)
      die "unknown option: $1 (see --help)"
      ;;
  esac
done

[[ -n "$name" ]] || die "--secret is required"
[[ "$name" == agent/* ]] || die "refusing '$name': only secrets under agent/ may be written with this wrapper"
$want_full && $want_generate && die "--full and --generate are mutually exclusive"

store_dir="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
gnupg_home="${GNUPGHOME:-$HOME/.gnupg-agent}"

if $want_generate; then
  PASSWORD_STORE_DIR="$store_dir" GNUPGHOME="$gnupg_home" pass generate --force "$name" "$gen_len" >/dev/null
  echo "pass-store: generated $name ($gen_len chars) — value not shown"
else
  value=$(cat)
  [[ -n "$value" ]] || die "empty value on stdin — refusing to store a blank credential"
  if ! $want_full; then
    value=$(printf '%s\n' "$value" | head -n1)
  fi
  printf '%s\n' "$value" | PASSWORD_STORE_DIR="$store_dir" GNUPGHOME="$gnupg_home" pass insert --force --multiline "$name" >/dev/null
  echo "pass-store: stored $name"
fi
