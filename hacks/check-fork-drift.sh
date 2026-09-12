#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Portable skills root
PORTABLE_ROOT="$REPO_ROOT/portable"

# Fields to compare (frontmatter paths)
FIELDS=("metadata.version" "metadata.tags")

usage() {
  cat <<'EOF'
Check frontmatter drift between a portable skill and its fork.

Usage:
  check-fork-drift.sh <skill-name> <fork-path>
  check-fork-drift.sh --help

Arguments:
  skill-name    Name of the portable skill (e.g., "summarize")
  fork-path     Path to a non-symlinked fork of the skill on disk

Exit codes:
  0   All compared fields match
  1   At least one field differs (specific fields named in output)
  2   Usage or input error

Examples:
  check-fork-drift.sh summarize ~/my-fork/summarize
  check-fork-drift.sh release-skills /path/to/opencode-fork/release-skills
EOF
}

die() {
  printf 'Error: %s\n' "$1" >&2
  exit 2
}

extract_frontmatter_value() {
  local file="$1"
  local key="$2"

  python3 - "$file" "$key" <<'PY'
import re, sys
path, key = sys.argv[1], sys.argv[2]
with open(path, encoding="utf-8") as f:
    text = f.read()
m = re.match(r"^---\n(.*?)\n---", text, re.DOTALL)
if not m:
    sys.exit(0)
block = m.group(1)

# Collapse multi-line flow sequences onto one line
block = re.sub(r":\s*\n\s*\[", ": [", block)
collapsed = []
depth = 0
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
val = top.get(key, meta.get(key, ""))
if val.startswith('"') and val.endswith('"'):
    val = val[1:-1]
print(val)
PY
}

# Parse arguments
if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  usage
  exit 0
fi

if [[ $# -lt 2 ]]; then
  die "Expected 2 arguments: <skill-name> <fork-path>"
fi

SKILL_NAME="$1"
FORK_PATH="$2"

# Validate skill name format
if [[ ! "$SKILL_NAME" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
  die "Skill name must match: [a-z0-9][a-z0-9-]*"
fi

# Check that the fork path exists and is not a symlink
if [[ ! -e "$FORK_PATH" ]]; then
  die "Fork path does not exist: $FORK_PATH"
fi

if [[ -L "$FORK_PATH" ]]; then
  die "Fork path is a symlink: $FORK_PATH (expected a non-symlinked fork)"
fi

# Find the portable source SKILL.md
PORTABLE_SKILL_MD="$PORTABLE_ROOT/$SKILL_NAME/SKILL.md"

if [[ ! -f "$PORTABLE_SKILL_MD" ]]; then
  die "Portable skill not found: $PORTABLE_SKILL_MD"
fi

# Find the fork's SKILL.md
FORK_SKILL_MD="$FORK_PATH/SKILL.md"

if [[ ! -f "$FORK_SKILL_MD" ]]; then
  die "Fork SKILL.md not found: $FORK_SKILL_MD"
fi

# Check that fork is not a symlink itself
if [[ -L "$FORK_SKILL_MD" ]]; then
  die "Fork SKILL.md is a symlink: $FORK_SKILL_MD (expected a non-symlinked fork)"
fi

# Compare fields
ERRORS=0
DIFFS_FOUND=0

for field in "${FIELDS[@]}"; do
  portable_value="$(extract_frontmatter_value "$PORTABLE_SKILL_MD" "$field" 2>/dev/null || true)"
  fork_value="$(extract_frontmatter_value "$FORK_SKILL_MD" "$field" 2>/dev/null || true)"

  if [[ "$portable_value" != "$fork_value" ]]; then
    DIFFS_FOUND=$((DIFFS_FOUND + 1))
    if [[ "$field" == "metadata.version" ]]; then
      # Version difference is a hard error
      ERRORS=$((ERRORS + 1))
      printf 'DRIFT: %s\n  portable: %s\n  fork:     %s\n' "$field" "$portable_value" "$fork_value"
    else
      # Other field differences are informational
      printf 'DRIFT: %s\n  portable: %s\n  fork:     %s\n' "$field" "$portable_value" "$fork_value"
    fi
  fi
done

if [[ $DIFFS_FOUND -eq 0 ]]; then
  printf 'PASS: No frontmatter drift detected for skill "%s"\n' "$SKILL_NAME"
  exit 0
else
  printf '\n%d field(s) differ between portable source and fork.\n' "$DIFFS_FOUND"
  if [[ $ERRORS -gt 0 ]]; then
    printf 'FAIL: metadata.version differs — fork is out of sync with portable source.\n'
    exit 1
  else
    printf 'WARN: Some fields differ (non-version).\n'
    exit 0
  fi
fi