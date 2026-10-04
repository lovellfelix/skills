#!/usr/bin/env bash
set -euo pipefail

# generate-sbom.sh
# Produce SPDX JSON and CycloneDX SBOMs into sbom/ directory.
# Usage: generate-sbom.sh [--output-dir sbom]

OUT_DIR="sbom"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output-dir) OUT_DIR="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

mkdir -p "$OUT_DIR"

if command -v syft >/dev/null 2>&1; then
  echo "Using syft to generate SBOMs"
  if ! syft . -o spdx-json > "$OUT_DIR/spdx.json"; then
    echo "syft failed to generate spdx-json" >&2
    exit 1
  fi
  if ! syft . -o cyclonedx-json > "$OUT_DIR/cyclonedx.json"; then
    echo "syft failed to generate cyclonedx-json" >&2
    exit 1
  fi
  echo "Generated: $OUT_DIR/spdx.json, $OUT_DIR/cyclonedx.json"
  exit 0
fi

if command -v cyclonedx >/dev/null 2>&1; then
  echo "Using cyclonedx-cli to generate CycloneDX SBOM"
  if ! cyclonedx -o "$OUT_DIR/cyclonedx.json" -f json .; then
    echo "cyclonedx-cli failed to generate cyclonedx" >&2
    exit 1
  fi
  echo "Generated: $OUT_DIR/cyclonedx.json"
  # create an empty spdx to keep artifacts consistent
  echo '{}' > "$OUT_DIR/spdx.json"
  exit 0
fi

# If we reach here, no real SBOM generator is available. Fail hard - CI should have tooling installed.
cat > "$OUT_DIR/spdx.json" <<'EOF'
{}
EOF
cat > "$OUT_DIR/cyclonedx.json" <<'EOF'
{}
EOF

echo "ERROR: No SBOM tool (syft or cyclonedx-cli) found. CI requires an SBOM generator to produce real SBOMs. Install syft: https://github.com/anchore/syft" >&2
exit 2
