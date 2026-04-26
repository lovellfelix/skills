#!/usr/bin/env bash
set -euo pipefail

# publish-claude.sh
# Helper to validate or produce marketplace.json for Claude marketplace and
# provide an approval flow for interactive/manual approval.
# Usage: publish-claude.sh [--marketplace marketplace.json] [--dry-run] [--approve]

MARKETPLACE_JSON="marketplace.json"
DRY_RUN=true
APPROVE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --marketplace) MARKETPLACE_JSON="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --approve) APPROVE=true; DRY_RUN=false; shift ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

if [[ ! -f "$MARKETPLACE_JSON" ]]; then
  echo "marketplace.json not found: $MARKETPLACE_JSON"
  # try to generate a basic stub from manifest.json if present
  if [[ -f "manifest.json" ]]; then
    echo "Generating marketplace.json stub from manifest.json"
    jq '{name: .name, version: .version, description: .description}' manifest.json > "$MARKETPLACE_JSON" 2>/dev/null || true
    if [[ -f "$MARKETPLACE_JSON" ]]; then
      echo "Generated stub: $MARKETPLACE_JSON"
    else
      echo "Failed to generate marketplace.json from manifest.json; please create $MARKETPLACE_JSON manually." >&2
      exit 2
    fi
  else
    echo "No manifest.json available to generate marketplace.json; create $MARKETPLACE_JSON and re-run." >&2
    exit 2
  fi
fi

# Basic validation: ensure required fields exist
if ! jq -e '.name and .version' "$MARKETPLACE_JSON" >/dev/null 2>&1; then
  echo "marketplace.json is missing required fields (name, version). Please update and re-run." >&2
  jq . "$MARKETPLACE_JSON" || true
  exit 2
fi

if [[ "$DRY_RUN" == "true" ]]; then
  echo "Dry-run: marketplace.json validated. Contents:"
  jq . "$MARKETPLACE_JSON" || true
  echo "To publish or submit, re-run with --approve (interactive) or integrate into your marketplace upload process."
  exit 0
fi

# Non-dry-run: require explicit approve flag
if [[ "$APPROVE" != "true" ]]; then
  echo "Approval required to proceed. Re-run with --approve to continue." >&2
  exit 2
fi

# At this point we have approval and a validated marketplace.json
echo "Approved: submitting marketplace.json"
# In CI, the actual submission step is intentionally manual or needs credentials.
# Print next steps for human operator; optionally implement upload with token env.
if [[ -n "${CLAUDE_MARKETPLACE_TOKEN:-}" ]]; then
  echo "CLAUDE_MARKETPLACE_TOKEN present; attempting upload..."
  # Placeholder for real upload endpoint
  echo "Uploading $MARKETPLACE_JSON to Claude marketplace (stub)..."
  # TODO: implement real API call when available
  echo "Upload not implemented. Please use the marketplace console or implement API client."
  exit 0
else
  echo "CLAUDE_MARKETPLACE_TOKEN not found. Upload must be performed manually."
  echo "Suggested steps:"
  echo "  1. Review marketplace.json: jq . $MARKETPLACE_JSON"
  echo "  2. Upload via marketplace console or CLI provided by the marketplace provider."
  echo "  3. If automating, set CLAUDE_MARKETPLACE_TOKEN and implement upload in this script."
  exit 2
fi
