#!/usr/bin/env bash
set -euo pipefail

# run-scans.sh
# Run Trivy (or equivalent) against repository filesystem and SBOM artifacts.
# Exits non-zero if any CRITICAL or HIGH vulnerabilities are found.
# Usage: run-scans.sh [--output trivy-report.json] [--severity CRITICAL,HIGH] [--path .]

OUT_FILE="trivy-report.json"
SEVERITIES=${TRIVY_SEVERITIES:-"CRITICAL,HIGH"}
SCAN_PATH="."

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output) OUT_FILE="$2"; shift 2 ;;
    --severity) SEVERITIES="$2"; shift 2 ;;
    --path) SCAN_PATH="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

if ! command -v trivy >/dev/null 2>&1; then
  echo "trivy is required for scanning. Install from https://github.com/aquasecurity/trivy" >&2
  exit 2
fi

# Run filesystem scan and output JSON
echo "Running trivy fs scan on $SCAN_PATH (severities=$SEVERITIES)"
# trivy exit code handling: --exit-code 1 will cause exit 1 when any issues at requested severities found
trivy fs --quiet --format json --output "$OUT_FILE" --severity "$SEVERITIES" --exit-code 1 "$SCAN_PATH" || SCAN_EXIT=$?

# If trivy returned non-zero, we've already failed per policy; surface results
if [[ "${SCAN_EXIT:-0}" -ne 0 ]]; then
  echo "Scan detected vulnerabilities with severity in $SEVERITIES. See $OUT_FILE for details." >&2
  # Fail intentionally
  exit 1
fi

# No critical/high issues found
echo "No $SEVERITIES vulnerabilities found. Report: $OUT_FILE"
exit 0
