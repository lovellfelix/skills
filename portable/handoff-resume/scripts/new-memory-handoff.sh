#!/usr/bin/env bash
set -euo pipefail

dry_run=false
agents_home="${AGENTS_HOME:-$HOME/.agents}"
project=""
topic=""

usage() {
  cat <<'EOF'
new-memory-handoff.sh - create timestamped handoff in ~/.agents/memory/handoffs

Usage:
  scripts/new-memory-handoff.sh [--project <project-slug>] [--topic <topic>] [--agents-home <path>] [--dry-run]

Examples:
  scripts/new-memory-handoff.sh --project dotfiles --topic memory-conventions
  scripts/new-memory-handoff.sh --topic ad-hoc-debug
EOF
}

log() {
  printf '%s\n' "$*"
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

slugify() {
  local input=$1
  local lowered
  lowered=$(printf '%s' "$input" | tr '[:upper:]' '[:lower:]')
  lowered=${lowered// /-}
  lowered=${lowered//[^a-z0-9_.-]/-}
  lowered=${lowered#-}
  lowered=${lowered%-}

  if [[ -z "$lowered" ]]; then
    lowered="general"
  fi

  printf '%s' "$lowered"
}

ensure_dir() {
  local dir=$1
  if [[ -e "$dir" && ! -d "$dir" ]]; then
    die "Path exists but is not a directory: $dir"
  fi

  if [[ -d "$dir" ]]; then
    return 0
  fi

  if [[ "$dry_run" == "true" ]]; then
    log "DRY RUN: mkdir -p \"$dir\""
    return 0
  fi

  mkdir -p "$dir"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      [[ $# -ge 2 ]] || die "Missing value for --project"
      project="$2"
      shift 2
      ;;
    --topic)
      [[ $# -ge 2 ]] || die "Missing value for --topic"
      topic="$2"
      shift 2
      ;;
    --agents-home)
      [[ $# -ge 2 ]] || die "Missing value for --agents-home"
      agents_home="$2"
      shift 2
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
done

project_slug=$(slugify "${project:-general}")
topic_slug=$(slugify "${topic:-status}")

ts=$(date +%Y%m%d%H%M%S)
year=$(date +%Y)
month=$(date +%m)

handoff_dir="$agents_home/memory/handoffs/$year/$month"
handoff_path="$handoff_dir/$ts-$project_slug-$topic_slug.md"

ensure_dir "$agents_home"
ensure_dir "$agents_home/memory"
ensure_dir "$agents_home/memory/handoffs"
ensure_dir "$agents_home/memory/handoffs/$year"
ensure_dir "$handoff_dir"

if [[ -e "$handoff_path" ]]; then
  die "Handoff path already exists: $handoff_path"
fi

if [[ "$dry_run" == "true" ]]; then
  log "DRY RUN: write $handoff_path"
  exit 0
fi

umask 077
cat > "$handoff_path" <<EOF
# Handoff

- Project: $project_slug
- Topic: $topic_slug
- Timestamp: $ts

## Goal
- <target outcome>

## Completed this session
- <change 1>

## Current state
- <done/in-progress/pending>

## Blockers
- <blocker> (owner: <name>, unblock path: <action>)

## Next steps
1. <smallest next action>
2. <follow-up action>

## Validation
- Ran: <checks>
- Not run: <checks and why>

## Resume command
- <first command to run>
EOF

log "Created handoff packet: $handoff_path"
