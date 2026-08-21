#!/usr/bin/env bash
# pass-run.sh — let an agent USE a pass(1) secret without ever SEEING it.
#
# Only decrypts entries under the `agent/` subtree, which is expected to use
# a dedicated zero-cache GPG key (see this skill's SKILL.md), so every call
# prompts pinentry on the physical desktop instead of silently reusing the
# main keyring's cache. Values are injected into the child process's
# environment only (never argv, which `ps` can read); output is buffered and
# every secret value is censored before being released.
#
# Usage:
#   pass-run.sh --secret agent/<name> [--as ENV_VAR] [--secret ... ] [--full] -- <command...>
#
#   --secret NAME   Entry under agent/ to resolve. Repeatable.
#   --as VAR        Env var name for the preceding --secret (default: last
#                    path component, uppercased, - -> _).
#   --full          Use the entire entry instead of just the first line.
#                    pass entries commonly carry username:/url: metadata on
#                    later lines that would corrupt a single-value credential.
#
# Example:
#   pass-run.sh --secret agent/openai-api-key -- curl -H "Authorization: Bearer $OPENAI_API_KEY" ...
#
# No output streaming: stdout/stderr are buffered until the command exits,
# then censored and released. This is a deliberate tradeoff for censoring
# correctness over live feedback on long-running commands.

set -euo pipefail

die() { echo "pass-run: $*" >&2; exit 1; }

cmd_help() { sed -n '2,/^set -euo/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; }

command -v pass >/dev/null 2>&1 || die "pass(1) not found on PATH"
command -v perl >/dev/null 2>&1 || die "perl not found on PATH (needed for literal-string censoring)"

secret_names=()
env_names=()
want_full=false
cmd=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --secret)
      [[ $# -ge 2 ]] || die "--secret requires a value"
      secret_names+=("$2")
      env_names+=("")
      shift 2
      ;;
    --as)
      [[ $# -ge 2 ]] || die "--as requires a value"
      [[ ${#secret_names[@]} -gt 0 ]] || die "--as must follow a --secret"
      env_names[${#env_names[@]}-1]="$2"
      shift 2
      ;;
    --full)
      want_full=true
      shift
      ;;
    --)
      shift
      cmd=("$@")
      break
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

[[ ${#secret_names[@]} -gt 0 ]] || die "at least one --secret is required"
[[ ${#cmd[@]} -gt 0 ]] || die "no command given after --"

default_env_name() {
  local base="${1##*/}"
  base="${base//-/_}"
  echo "${base^^}"
}

store_dir="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
gnupg_home="${GNUPGHOME:-$HOME/.gnupg-agent}"

env_kv=()
secret_values=()

for i in "${!secret_names[@]}"; do
  name="${secret_names[$i]}"
  [[ "$name" == agent/* ]] || die "refusing '$name': only secrets under agent/ may be used with this wrapper"

  if ! full_output=$(PASSWORD_STORE_DIR="$store_dir" GNUPGHOME="$gnupg_home" pass show "$name"); then
    die "pass show failed for '$name' (entry missing or gpg approval was denied/cancelled)"
  fi

  if $want_full; then
    value="$full_output"
  else
    value=$(printf '%s\n' "$full_output" | head -n1)
  fi
  [[ -n "$value" ]] || die "empty value for '$name' — refusing to run with a blank credential"

  env_name="${env_names[$i]:-$(default_env_name "$name")}"
  env_kv+=("$env_name=$value")
  secret_values+=("$value")
done

tmp_out=$(mktemp) || die "mktemp failed"
tmp_err=$(mktemp) || die "mktemp failed"
chmod 600 "$tmp_out" "$tmp_err"
trap 'rm -f "$tmp_out" "$tmp_err"' EXIT

set +e
env "${env_kv[@]}" "${cmd[@]}" >"$tmp_out" 2>"$tmp_err"
exit_code=$?
set -e

for secret in "${secret_values[@]}"; do
  S="$secret" perl -pi -e 's/\Q$ENV{S}\E/[REDACTED]/g' "$tmp_out" "$tmp_err"
done

cat "$tmp_out"
cat "$tmp_err" >&2

exit "$exit_code"
