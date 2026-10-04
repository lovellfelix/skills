#!/usr/bin/env bash
set -euo pipefail

# publish-pypi.sh
# Usage: publish-pypi.sh [--dry-run] [--repository pypi|testpypi] [--dist-dir dist]

DRY_RUN=false
REPOSITORY="pypi"
DIST_DIR="dist"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --repository) REPOSITORY="$2"; shift 2 ;;
    --dist-dir) DIST_DIR="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

if [[ ! -d "$DIST_DIR" ]]; then
  echo "dist directory $DIST_DIR does not exist" >&2
  exit 2
fi

# Prefer API token in TWINE_PASSWORD env (recommended by PyPI)
if [[ -z "${TWINE_USERNAME:-}" || -z "${TWINE_PASSWORD:-}" ]]; then
  echo "Using token-based auth is recommended. Provide TWINE_USERNAME and TWINE_PASSWORD or configure ~/.pypirc" >&2
fi

if [[ "$DRY_RUN" == "true" ]]; then
  echo "DRY RUN: twine upload --repository $REPOSITORY $DIST_DIR/*"
  ls -1 "$DIST_DIR"
  exit 0
fi

# Optionally sign distributions using gpg
# twine will pick up .asc files next to artifacts if present
if command -v twine >/dev/null 2>&1; then
  twine upload --repository "$REPOSITORY" "$DIST_DIR"/*
else
  echo "twine is required. Install with 'pip install twine'" >&2
  exit 2
fi
