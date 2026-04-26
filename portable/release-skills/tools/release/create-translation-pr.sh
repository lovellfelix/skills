#!/usr/bin/env bash
set -euo pipefail

# create-translation-pr.sh
# Create a translation PR stub for release notes so native speakers can review.
# Usage: create-translation-pr.sh --source handoff/release-notes.md --lang es-ES [--confirm]

SOURCE="handoff/release-notes.md"
LANG=""
BRANCH="translation/auto"
CONFIRM=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source) SOURCE="$2"; shift 2 ;;
    --lang) LANG="$2"; shift 2 ;;
    --branch) BRANCH="$2"; shift 2 ;;
    --confirm) CONFIRM=true; shift ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

if [[ ! -f "$SOURCE" ]]; then
  echo "Source file not found: $SOURCE" >&2
  exit 2
fi

if [[ -z "$LANG" ]]; then
  echo "--lang is required, e.g. es-ES" >&2
  exit 2
fi

TMP_DIR=$(mktemp -d)
cp "$SOURCE" "$TMP_DIR/release-notes.md"

pushd "$TMP_DIR" >/dev/null
# Create a draft translation entry file
mkdir -p translations
cp release-notes.md "translations/release-notes.$LANG.md"
echo "(Translation stub auto-generated. Please translate the entry and keep contributor attributions.)" >> "translations/release-notes.$LANG.md"

# Create branch and push
git init >/dev/null
REMOTE_URL=$(git remote get-url origin 2>/dev/null || true) || true
if [[ -n "$REMOTE_URL" ]]; then
  git remote add origin "$REMOTE_URL" || true
fi
# Create commit with a clear message
git checkout -b "$BRANCH"
cp -r translations .
git add .

if git commit -m "chore: add translation stub for $LANG (auto-generated)" >/dev/null 2>&1; then
  echo "Created local commit for translation stub"
else
  echo "Warning: git commit failed (possibly no changes). Continuing..."
fi

if [[ "$CONFIRM" == "true" ]]; then
  if [[ -z "$REMOTE_URL" ]]; then
    echo "No git origin configured. Cannot push. Connect a remote named 'origin' and re-run with --confirm." >&2
    popd >/dev/null
    rm -rf "$TMP_DIR"
    exit 2
  fi

  set -x
  git push --set-upstream origin "$BRANCH"
  set +x

  if command -v gh >/dev/null 2>&1; then
    gh pr create --title "Translation: release notes ($LANG)" --body "Auto-generated translation stub. Please translate and preserve attributions." --base main --head "$BRANCH" || true
    echo "Created PR for translation ($LANG)"
  else
    echo "gh CLI not available; branch pushed: $BRANCH"
  fi
else
  echo "Dry-run: translation stub prepared in temporary dir: $TMP_DIR"
  echo "To push and create a PR, re-run this script with --confirm. Example:" 
  echo "  create-translation-pr.sh --source $SOURCE --lang $LANG --confirm"
fi
popd >/dev/null

# Cleanup (only when not in dry-run)
if [[ "$CONFIRM" != "true" ]]; then
  # leave TMP_DIR for inspection and print path
  echo "Left temporary dir for inspection: $TMP_DIR"
else
  rm -rf "$TMP_DIR"
fi

exit 0
