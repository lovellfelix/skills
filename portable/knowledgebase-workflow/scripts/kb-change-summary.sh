#!/usr/bin/env bash
set -euo pipefail
ROOT=$(pwd)
SCRIPTS_DIR="${ROOT}/scripts"
NODE=$(command -v node || true)

echo "Running KB validation scripts..."
if [ -z "$NODE" ]; then
  echo "node not found in PATH. Please install Node.js to run KB checks." >&2
  exit 2
fi

node "$SCRIPTS_DIR/find-duplicates.js"
node "$SCRIPTS_DIR/generate-backlinks.js"

echo "KB checks passed. Backlinks generated in ./backlinks/"
exit 0
