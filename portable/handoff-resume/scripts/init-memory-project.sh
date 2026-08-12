#!/usr/bin/env bash
set -euo pipefail

dry_run=false
agents_home="${AGENTS_HOME:-$HOME/.agents}"
project=""

usage() {
  cat <<'EOF'
init-memory-project.sh - scaffold ~/.agents/memory/projects/<project>

Usage:
  ./hacks/init-memory-project.sh --project <project-slug> [--agents-home <path>] [--dry-run]

Example:
  ./hacks/init-memory-project.sh --project dotfiles
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

  [[ -n "$lowered" ]] || die "Project slug cannot be empty after normalization"
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

write_if_missing() {
  local path=$1
  local content=$2

  if [[ -e "$path" ]]; then
    log "Preserving existing file: $path"
    return 0
  fi

  if [[ "$dry_run" == "true" ]]; then
    log "DRY RUN: write $path"
    return 0
  fi

  umask 077
  printf '%s\n' "$content" > "$path"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      [[ $# -ge 2 ]] || die "Missing value for --project"
      project="$2"
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

[[ -n "$project" ]] || die "--project is required"

project_slug=$(slugify "$project")
project_dir="$agents_home/memory/projects/$project_slug"
artifacts_dir="$project_dir/artifacts"

ensure_dir "$agents_home"
ensure_dir "$agents_home/memory"
ensure_dir "$agents_home/memory/projects"
ensure_dir "$project_dir"
ensure_dir "$artifacts_dir"

write_if_missing "$project_dir/README.md" "---
artifact_type: project-readme
project: $project_slug
source: init-memory-project
created_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
updated_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
---

# Project Memory: $project_slug

## Objective
- <target outcome>

## Key Files
- MEMORY.md — consolidated project memory (Claude Code compatible)
- current.md — status, blockers, next actions
- decisions.md — durable choices and learnings
- artifacts/ — autodream artifacts and supporting files

## Usage
- MEMORY.md is the primary memory file, auto-populated by autodream.
- Update current.md at session start/end.
- Record durable choices in decisions.md.
- Store supporting artifacts in artifacts/.
"

write_if_missing "$project_dir/current.md" "---
artifact_type: project-current
project: $project_slug
source: init-memory-project
created_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
updated_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
---

# Current State

## Status
- <in-progress summary>

## Blockers
- <blocker> (owner: <name>, unblock: <action>)

## Next Actions
1. <smallest next step>
2. <follow-up step>
"

write_if_missing "$project_dir/decisions.md" "---
artifact_type: project-decisions
project: $project_slug
source: init-memory-project
created_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
updated_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
---

# Decisions

- YYYY-MM-DD: <decision> - <why>
"

log "Project memory scaffold ready: $project_dir"
