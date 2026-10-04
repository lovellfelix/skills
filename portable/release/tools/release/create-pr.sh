#!/usr/bin/env bash
set -euo pipefail

# create-pr.sh
# Create a release PR using gh CLI.
# Usage: create-pr.sh --branch <branch> --title <title> --body-file <file> [--base main]

BRANCH=""
TITLE=""
BODY_FILE=""
BASE=main

while [[ $# -gt 0 ]]; do
  case "$1" in
    --branch) BRANCH="$2"; shift 2 ;;
    --title) TITLE="$2"; shift 2 ;;
    --body-file) BODY_FILE="$2"; shift 2 ;;
    --base) BASE="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

if [[ -z "$BRANCH" || -z "$TITLE" || -z "$BODY_FILE" ]]; then
  echo "Usage: create-pr.sh --branch <branch> --title <title> --body-file <file>" >&2
  exit 2
fi

if [[ ! -f "$BODY_FILE" ]]; then
  echo "Body file not found: $BODY_FILE" >&2
  exit 2
fi

# Create branch
git checkout -b "$BRANCH"

git add -A
if git diff --cached --quiet; then
  echo "No staged changes to commit. Proceeding without commit." >&2
else
  git commit -m "$TITLE"
fi

git push --set-upstream origin "$BRANCH"

# Create PR
if command -v gh >/dev/null 2>&1; then
  gh pr create --base "$BASE" --head "$BRANCH" --title "$TITLE" --body-file "$BODY_FILE"
else
  echo "gh CLI required to create PR." >&2
  exit 2
fi
