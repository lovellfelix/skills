#!/usr/bin/env bash
set -euo pipefail

# gen-changelog.sh
# Generate a changelog since the previous tag. Prefer git-cliff if available,
# otherwise produce a minimal conventional-style changelog.
# Usage: gen-changelog.sh [--tag <tag>] [--out CHANGELOG.md]

OUT=${OUT:-CHANGELOG.md}
OUT_FILE="handoff/release-notes.md"
TAG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag) TAG="$2"; shift 2 ;;
    --out) OUT_FILE="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

mkdir -p "handoff"

if command -v git-cliff >/dev/null 2>&1; then
  echo "Using git-cliff to generate changelog"
  if [[ -n "$TAG" ]]; then
    git-cliff --tag "$TAG" -o "$OUT_FILE"
  else
    git-cliff -o "$OUT_FILE"
  fi
  echo "Created: $OUT_FILE"
  exit 0
fi

# Fallback: minimal changelog from git log since last tag
if [[ -z "$TAG" ]]; then
  if git describe --tags --abbrev=0 >/dev/null 2>&1; then
    TAG=$(git describe --tags --abbrev=0)
  fi
fi

if [[ -n "$TAG" ]]; then
  RANGE="$TAG..HEAD"
else
  RANGE="HEAD"
fi

echo "Generating minimal changelog for range: $RANGE"
cat > "$OUT_FILE" <<EOF
# Release notes

Generated: $(date -u +%Y-%m-%d)

Changes since ${TAG:-start}:

$(git log --pretty=format:"- %s (%an)" $RANGE)
EOF

echo "Wrote: $OUT_FILE"
exit 0
