#!/usr/bin/env bash
set -euo pipefail

# checksum-sign.sh
# Generate SHA256 checksum and GPG signature for a file.
# Usage: checksum-sign.sh <file> [--gpg-key <key-id>] [--no-sign]

if [[ $# -lt 1 ]]; then
  echo "Usage: checksum-sign.sh <file> [--gpg-key <key-id>] [--no-sign]" >&2
  exit 2
fi

FILE="$1"
shift || true
GPG_KEY=""
NO_SIGN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --gpg-key) GPG_KEY="$2"; shift 2 ;;
    --no-sign) NO_SIGN=true; shift ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

if [[ ! -f "$FILE" ]]; then
  echo "File not found: $FILE" >&2
  exit 2
fi

SHA_FILE="$FILE.sha256"
echo "Generating sha256 for $FILE -> $SHA_FILE"

# Detect available checksum tool: prefer sha256sum, then shasum, then openssl
if command -v sha256sum >/dev/null 2>&1; then
  sha256sum "$FILE" | awk '{print $1}' > "$SHA_FILE"
  CHECKSUM_TOOL=sha256sum
elif command -v shasum >/dev/null 2>&1; then
  shasum -a 256 "$FILE" | awk '{print $1}' > "$SHA_FILE"
  CHECKSUM_TOOL=shasum
elif command -v openssl >/dev/null 2>&1; then
  openssl dgst -sha256 -binary "$FILE" | openssl base64 -A >/tmp/.sha256.base64 || true
  # fallback to hex output
  openssl dgst -sha256 "$FILE" | awk '{print $2}' > "$SHA_FILE"
  CHECKSUM_TOOL=openssl
else
  echo "Warning: No sha256 checksum tool (sha256sum|shasum|openssl) found. Skipping checksum generation." >&2
  echo "Created: <none> (checksum missing)"
  # Soft-fail: do not return non-zero to allow CI to proceed in limited environments
  exit 0
fi

echo "Used checksum tool: $CHECKSUM_TOOL"

if [[ "$NO_SIGN" == "true" ]]; then
  echo "Skipping GPG signing (--no-sign)"
  exit 0
fi

if ! command -v gpg >/dev/null 2>&1; then
  echo "gpg not found: skipping signature generation. To sign artifacts, install gpg and provide a key or run with --no-sign" >&2
  # Soft-fail: leave checksum but no signature
  exit 0
fi

if [[ -n "$GPG_KEY" ]]; then
  echo "Signing $FILE with key $GPG_KEY"
  gpg --batch --yes --local-user "$GPG_KEY" --detach-sign --armor "$FILE"
else
  echo "Signing $FILE with default gpg key"
  gpg --batch --yes --detach-sign --armor "$FILE"
fi

echo "Created: $SHA_FILE and $FILE.asc"
