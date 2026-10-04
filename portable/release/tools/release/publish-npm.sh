#!/usr/bin/env bash
set -euo pipefail

# publish-npm.sh
# Usage: publish-npm.sh [--dry-run] [--tag <tag>] [--access <public|restricted>] [--dist-dir <dir>]

DRY_RUN=false
TAG=latest
ACCESS=public
DIST_DIR=.

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --tag) TAG="$2"; shift 2 ;;
    --access) ACCESS="$2"; shift 2 ;;
    --dist-dir) DIST_DIR="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

if [[ -z "${NPM_TOKEN:-}" ]]; then
  echo "NPM_TOKEN is required in env" >&2
  exit 2
fi

export NPM_CONFIG_REGISTRY=${NPM_CONFIG_REGISTRY:-https://registry.npmjs.org/}

pushd "$DIST_DIR" >/dev/null
PACKAGE_JSON="package.json"
if [[ ! -f "$PACKAGE_JSON" ]]; then
  echo "package.json not found in $DIST_DIR" >&2
  exit 2
fi

# Optional: generate checksums and sign artifacts if any
# Resolve checksum-sign script robustly from the repository root so this works
# regardless of current working directory when the script is invoked.
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$REPO_ROOT" ]]; then
  # fallback to script-relative resolution
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  REPO_ROOT="$SCRIPT_DIR"
fi
CHECKSUM_SCRIPT="$REPO_ROOT/tools/release/checksum-sign.sh"
if [[ -x "$CHECKSUM_SCRIPT" ]]; then
  # iterate over found tgz files and sign each
  while IFS= read -r -d '' f; do
    bash "$CHECKSUM_SCRIPT" "$f" || true
  done < <(find . -maxdepth 1 -type f -name "*.tgz" -print0)
fi

# Write npm auth token to npmrc for CI
echo "//${NPM_CONFIG_REGISTRY#https://}:_authToken=${NPM_TOKEN}" > .npmrc

if [[ "$DRY_RUN" == "true" ]]; then
  echo "DRY RUN: npm publish --tag $TAG --access $ACCESS"
  npm pack
  echo "done"
  popd >/dev/null
  exit 0
fi

# Publish
if npm publish --tag "$TAG" --access "$ACCESS"; then
  echo "npm publish succeeded"
  popd >/dev/null
  exit 0
else
  echo "npm publish failed" >&2
  popd >/dev/null
  exit 1
fi
