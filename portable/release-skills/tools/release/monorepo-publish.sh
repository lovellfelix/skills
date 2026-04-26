#!/usr/bin/env bash
set -euo pipefail

# monorepo-publish.sh
# Simple change-detection + per-package publish sample for Node (packages/*) and Cargo (crates/*)
# Usage: monorepo-publish.sh [--tag <tag>] [--dry-run] [--confirm]

TAG=""
DRY_RUN=true
CONFIRM=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag) TAG="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --confirm) CONFIRM=true; DRY_RUN=false; shift ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

if [[ "$CONFIRM" != "true" ]]; then
  echo "Running in dry-run mode. Pass --confirm to perform publishes."
fi

# Determine changed files since last tag (or origin/main)
if [[ -n "$TAG" ]]; then
  RANGE="$TAG..HEAD"
else
  if git rev-parse --verify origin/main >/dev/null 2>&1; then
    RANGE="origin/main..HEAD"
  else
    # origin/main not present. This commonly happens in shallow CI checkouts.
    if git rev-parse --is-shallow-repository >/dev/null 2>&1 && [[ "$(git rev-parse --is-shallow-repository 2>/dev/null)" == "true" ]]; then
      echo "Error: origin/main not available; repository appears to be a shallow checkout.\nIn GitHub Actions set actions/checkout@v4 with 'fetch-depth: 0' so origin/main is available for change detection.\nAlternatively, fetch the target branch before running this script: 'git fetch origin main --unshallow'" >&2
      exit 2
    fi
    echo "Warning: origin/main not found; falling back to HEAD for change detection" >&2
    RANGE="HEAD"
  fi
fi

echo "Detecting changed packages in range: $RANGE"
CHANGED_FILES=$(git diff --name-only "$RANGE" || true)

if [[ -z "$CHANGED_FILES" ]]; then
  echo "No changes detected in range: $RANGE"
fi

# Node packages under packages/*
for pkg in $(ls -d packages/* 2>/dev/null || true); do
  # normalize pkg path
  pkg=${pkg%/}
  if echo "$CHANGED_FILES" | grep -q "^${pkg#/}/" || echo "$CHANGED_FILES" | grep -q "^${pkg}/"; then
    echo "Package changed: $pkg"
    if [[ -f "$pkg/package.json" ]]; then
      pushd "$pkg" >/dev/null
      if [[ "$DRY_RUN" == "true" ]]; then
        echo "DRY RUN: would publish npm package in $pkg"
      else
        echo "Publishing npm package in $pkg"
        if ! bash ../../tools/release/publish-npm.sh --dist-dir .; then
          echo "Error: publish-npm.sh failed for $pkg" >&2
          exit 1
        fi
      fi
      popd >/dev/null
    else
      echo "Skipping $pkg: no package.json found" >&2
    fi
  fi
done

# Cargo crates under crates/*
for crate in $(ls -d crates/* 2>/dev/null || true); do
  crate=${crate%/}
  if echo "$CHANGED_FILES" | grep -q "^${crate#/}/" || echo "$CHANGED_FILES" | grep -q "^${crate}/"; then
    echo "Crate changed: $crate"
    if [[ -f "$crate/Cargo.toml" ]]; then
      pushd "$crate" >/dev/null
      if [[ "$DRY_RUN" == "true" ]]; then
        echo "DRY RUN: would publish cargo crate in $crate"
      else
        echo "Publishing crate: $crate"
        if ! bash ../../tools/release/publish-cargo.sh --manifest-path Cargo.toml; then
          echo "Error: publish-cargo.sh failed for $crate" >&2
          exit 1
        fi
      fi
      popd >/dev/null
    else
      echo "Skipping $crate: no Cargo.toml found" >&2
    fi
  fi
done

# Fallback: root-level package
if echo "$CHANGED_FILES" | grep -q "^package.json"; then
  echo "Root package.json changed"
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "DRY RUN: would publish root npm package"
  else
    if ! bash tools/release/publish-npm.sh --dist-dir .; then
      echo "Error: publish-npm.sh failed for root package" >&2
      exit 1
    fi
  fi
fi

echo "monorepo-publish.sh: done"
exit 0
