#!/usr/bin/env bash
#
# Compare frontmatter metadata between a portable skill in this repo and a
# git-tracked (non-symlinked) fork of that skill elsewhere on disk.
#
# Only `metadata.version` and `metadata.tags` are compared. A `metadata.version`
# difference is a hard failure (exit 1); a tags-only difference is reported as a
# warning (exit 0) because forks legitimately add runtime-specific tags.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
PORTABLE_ROOT="${PORTABLE_ROOT:-$REPO_ROOT/portable}"

FIELDS=("metadata.version" "metadata.tags")

usage() {
  cat <<'EOF'
Check frontmatter drift between a portable skill and a git-tracked fork.

Usage:
  check-fork-drift.sh <skill-name> <fork-path>
  check-fork-drift.sh --help

Arguments:
  skill-name    Portable skill name under portable/ (e.g. "lean-ctx")
  fork-path     Path to a non-symlinked fork directory (or its SKILL.md)

Compared fields:
  metadata.version, metadata.tags

Environment:
  PORTABLE_ROOT   Override the portable skills root (default: <repo>/portable)
  FORK_DRIFT_DEBUG  Set to 1 to print resolved paths

Exit codes:
  0   Versions match (tag differences are warnings only)
  1   metadata.version differs
  2   Usage or input error
EOF
}

die() {
  printf 'Error: %s\n' "$1" >&2
  exit 2
}

# Prints the value of a frontmatter key path (e.g. "metadata.version").
# Exits non-zero when the key is absent so callers can distinguish
# "missing" from "empty".
extract_frontmatter_value() {
  local file="$1"
  local key="$2"

  python3 - "$file" "$key" <<'PY'
import re
import sys

path, key = sys.argv[1], sys.argv[2]
try:
    with open(path, encoding="utf-8") as f:
        text = f.read()
except OSError as exc:
    print(f"cannot read {path}: {exc}", file=sys.stderr)
    raise SystemExit(3)

m = re.match(r"^---\r?\n(.*?)\r?\n---", text, re.DOTALL)
if not m:
    print(f"no frontmatter block in {path}", file=sys.stderr)
    raise SystemExit(3)
block = m.group(1)

# Collapse multi-line flow sequences (`tags:` then a wrapped `[...]` list)
# onto a single line so the line-based pass below sees a complete value.
block = re.sub(r":\s*\n\s*\[", ": [", block)
collapsed, depth = [], 0
for ch in block:
    if ch == "[":
        depth += 1
    elif ch == "]":
        depth -= 1
    if ch == "\n" and depth > 0:
        continue
    collapsed.append(ch)
block = "".join(collapsed)

top, meta = {}, {}
in_meta = False
for line in block.splitlines():
    if not line.strip():
        in_meta = False
        continue
    if line[:1] in (" ", "\t"):
        if in_meta and ":" in line:
            k, v = line.strip().split(":", 1)
            meta[k.strip()] = v.strip()
        continue
    if ":" not in line:
        in_meta = False
        continue
    k, v = line.split(":", 1)
    k, v = k.strip(), v.strip()
    if k == "metadata" and v == "":
        in_meta = True
        continue
    in_meta = False
    top[k] = v

if "." in key:
    prefix, rest = key.split(".", 1)
    val = meta.get(rest) if prefix == "metadata" else None
else:
    val = top.get(key, meta.get(key))

if val is None:
    print(f"missing frontmatter key '{key}' in {path}", file=sys.stderr)
    raise SystemExit(4)

val = val.strip().strip("\"'")
print(val)
PY
}

# Normalise a flow/block tag list into a sorted comma-joined string so that
# ordering and quoting differences are not reported as drift.
normalize_tags() {
  python3 - "$1" <<'PY'
import sys

raw = sys.argv[1].strip()
if raw.startswith("[") and raw.endswith("]"):
    raw = raw[1:-1]
tags = [t.strip().strip("\"'") for t in raw.split(",")]
tags = [t for t in tags if t]
print(",".join(sorted(tags)))
PY
}

main() {
  if [[ $# -eq 0 ]]; then
    usage >&2
    exit 2
  fi
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    usage
    exit 0
  fi
  if [[ $# -ne 2 ]]; then
    die "expected 2 arguments: <skill-name> <fork-path>"
  fi

  local skill_name="$1"
  local fork_path="$2"

  if [[ ! "$skill_name" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
    die "skill name must match [a-z0-9][a-z0-9-]*: $skill_name"
  fi

  local portable_skill_md="$PORTABLE_ROOT/$skill_name/SKILL.md"
  if [[ ! -f "$portable_skill_md" ]]; then
    die "portable skill not found: $portable_skill_md"
  fi

  local fork_skill_md="$fork_path"
  if [[ -d "$fork_path" ]]; then
    fork_skill_md="$fork_path/SKILL.md"
  fi

  if [[ -L "$fork_path" ]]; then
    die "fork path is a symlink, expected a real directory: $fork_path"
  fi
  if [[ ! -e "$fork_skill_md" ]]; then
    die "fork SKILL.md not found: $fork_skill_md"
  fi
  if [[ -L "$fork_skill_md" ]]; then
    die "fork SKILL.md is a symlink, expected a real file: $fork_skill_md"
  fi

  if [[ "${FORK_DRIFT_DEBUG:-0}" == "1" ]]; then
    printf 'portable: %s\nfork:     %s\n' "$portable_skill_md" "$fork_skill_md" >&2
  fi

  local differing=() version_differs=0
  local field portable_value fork_value

  for field in "${FIELDS[@]}"; do
    if ! portable_value="$(extract_frontmatter_value "$portable_skill_md" "$field")"; then
      die "failed to read '$field' from $portable_skill_md"
    fi
    if ! fork_value="$(extract_frontmatter_value "$fork_skill_md" "$field")"; then
      die "failed to read '$field' from $fork_skill_md"
    fi

    if [[ "$field" == "metadata.tags" ]]; then
      portable_value="$(normalize_tags "$portable_value")"
      fork_value="$(normalize_tags "$fork_value")"
    fi

    if [[ "$portable_value" != "$fork_value" ]]; then
      differing+=("$field")
      printf 'DRIFT: %s\n  portable: %s\n  fork:     %s\n' \
        "$field" "$portable_value" "$fork_value"
      if [[ "$field" == "metadata.version" ]]; then
        version_differs=1
      fi
    fi
  done

  if [[ ${#differing[@]} -eq 0 ]]; then
    printf 'PASS: no frontmatter drift for skill "%s"\n' "$skill_name"
    exit 0
  fi

  printf '\n%sg: %d field(s) differ (%s)\n' \
    "$([[ $version_differs -eq 1 ]] && printf 'FAIL' || printf 'WARN')" \
    "${#differing[@]}" \
    "$(IFS=', '; printf '%s' "${differing[*]}")"

  if [[ $version_differs -eq 1 ]]; then
    exit 1
  fi
  exit 0
}

main "$@"