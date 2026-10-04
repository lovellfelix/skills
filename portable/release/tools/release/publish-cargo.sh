#!/usr/bin/env bash
set -euo pipefail

# publish-cargo.sh
# Usage: publish-cargo.sh [--dry-run] [--manifest-path <path>] [--allow-dirty]

DRY_RUN=false
MANIFEST_PATH=""
ALLOW_DIRTY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --manifest-path) MANIFEST_PATH="$2"; shift 2 ;;
    --allow-dirty) ALLOW_DIRTY=true; shift ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

if [[ -z "${CARGO_REGISTRY_TOKEN:-}" ]]; then
  echo "CARGO_REGISTRY_TOKEN is recommended for publishing" >&2
fi

CMD=(cargo publish)
if [[ -n "$MANIFEST_PATH" ]]; then
  CMD+=(--manifest-path "$MANIFEST_PATH")
fi
if [[ "$DRY_RUN" == "true" ]]; then
  CMD+=(--dry-run)
fi
if [[ "$ALLOW_DIRTY" == "true" ]]; then
  CMD+=(--allow-dirty)
fi

echo "Running: ${CMD[*]}"
"${CMD[@]}"
