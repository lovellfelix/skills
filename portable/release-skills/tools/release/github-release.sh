#!/usr/bin/env bash
set -euo pipefail

# github-release.sh
# Create a GitHub release and upload assets via gh CLI.
# Usage: github-release.sh --tag v1.2.3 --notes-file release-notes.md [--draft] [--prerelease] [--assets "file1 file2"]

TAG=""
NOTES_FILE=""
DRAFT=false
PRERELEASE=false
ASSETS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag) TAG="$2"; shift 2 ;;
    --notes-file) NOTES_FILE="$2"; shift 2 ;;
    --draft) DRAFT=true; shift ;;
    --prerelease) PRERELEASE=true; shift ;;
    --assets) ASSETS="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

if [[ -z "$TAG" || -z "$NOTES_FILE" ]]; then
  echo "Usage: github-release.sh --tag <tag> --notes-file <file> [--draft] [--prerelease] [--assets \"file1 file2\"]" >&2
  exit 2
fi

if [[ ! -f "$NOTES_FILE" ]]; then
  echo "Notes file not found: $NOTES_FILE" >&2
  exit 2
fi

CMD=(gh release create "$TAG" --notes-file "$NOTES_FILE")

if [[ "$DRAFT" == "true" ]]; then
  CMD+=(--draft)
fi
if [[ "$PRERELEASE" == "true" ]]; then
  CMD+=(--prerelease)
fi

# Attach assets if provided
if [[ -n "$ASSETS" ]]; then
  for a in $ASSETS; do
    if [[ -f "$a" ]]; then
      CMD+=("$a")
    else
      echo "Warning: asset not found: $a" >&2
    fi
  done
fi

# Execute
"${CMD[@]}"

echo "GitHub release created for $TAG"
