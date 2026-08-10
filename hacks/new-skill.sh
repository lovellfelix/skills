#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

dry_run=false
force=false
runtime=""
skill_name=""

die() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Create a new skill scaffold.

Usage:
  new-skill.sh <skill-name> [--runtime <runtime>] [--force] [--dry-run]
  new-skill.sh --help

Examples:
  new-skill.sh query-planner
  new-skill.sh graph-sync --runtime opencode
  new-skill.sh graph-sync --runtime opencode --force
  new-skill.sh query-planner --dry-run

Behavior:
  - Default target: portable/<skill-name>/
  - Runtime target: runtime-specific/<runtime>/<skill-name>/
  - Creates: SKILL.md, manifest.json, examples/, reference/
  - Refuses to overwrite existing files unless --force is provided
EOF
}

is_valid_slug() {
  [[ "$1" =~ ^[a-z0-9][a-z0-9-]*$ ]]
}

write_file() {
  local path="$1"
  local content="$2"

  if [[ -e "$path" && "$force" != true ]]; then
    die "Refusing to overwrite existing file: $path (use --force)"
  fi

  if [[ "$dry_run" == true ]]; then
    printf '[dry-run] write %s\n' "$path"
    return
  fi

  printf '%b\n' "$content" >"$path"
}

create_dir() {
  local path="$1"

  if [[ "$dry_run" == true ]]; then
    printf '[dry-run] mkdir -p %s\n' "$path"
    return
  fi

  mkdir -p "$path"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --runtime)
      [[ $# -ge 2 ]] || die "--runtime requires a value"
      runtime="$2"
      shift 2
      ;;
    --force)
      force=true
      shift
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    --*)
      die "Unknown option: $1"
      ;;
    *)
      if [[ -n "$skill_name" ]]; then
        die "Skill name already set to '$skill_name'"
      fi
      skill_name="$1"
      shift
      ;;
  esac
done

[[ -n "$skill_name" ]] || {
  usage
  exit 1
}

is_valid_slug "$skill_name" || die "Skill name must match: [a-z0-9][a-z0-9-]*"

if [[ -n "$runtime" ]]; then
  is_valid_slug "$runtime" || die "Runtime must match: [a-z0-9][a-z0-9-]*"
  base_dir="$REPO_ROOT/runtime-specific/$runtime/$skill_name"  # this repo IS the skills root
  portable_flag="false"
  runtime_field=",\n  \"runtime\": \"$runtime\""
  tags_json="    \"$runtime\""
  adapters_json="  \"adapters\": {\n    \"$runtime\": {\n      \"path\": \"SKILL.md\",\n      \"mode\": \"native\"\n    }\n  }"
  compatibility_json="  \"compatibility\": {\n    \"runtimes\": {\n      \"$runtime\": {\n        \"min_version\": \"*\"\n      }\n    }\n  }"
  title_prefix="Runtime Skill"
  description_mode="runtime-specific"
else
  base_dir="$REPO_ROOT/portable/$skill_name"
  portable_flag="true"
  runtime_field=""
  tags_json="    \"portable\""
  adapters_json="  \"adapters\": {\n    \"opencode\": {\n      \"path\": \"SKILL.md\",\n      \"mode\": \"native\"\n    },\n    \"claude\": {\n      \"path\": \"SKILL.md\",\n      \"mode\": \"include\"\n    },\n    \"pi\": {\n      \"path\": \"SKILL.md\",\n      \"mode\": \"include\"\n    }\n  }"
  compatibility_json="  \"compatibility\": {\n    \"runtimes\": {\n      \"opencode\": {\n        \"min_version\": \"*\"\n      },\n      \"claude\": {\n        \"min_version\": \"*\"\n      },\n      \"pi\": {\n        \"min_version\": \"*\"\n      }\n    }\n  }"
  title_prefix="Portable Skill"
  description_mode="portable"
fi

skill_md_path="$base_dir/SKILL.md"
manifest_path="$base_dir/manifest.json"
examples_dir="$base_dir/examples"
reference_dir="$base_dir/reference"

create_dir "$examples_dir"
create_dir "$reference_dir"

skill_md_content="---
name: $skill_name
description: Starter $description_mode skill scaffold.
version: 0.1.0
portable: $portable_flag
tags: [starter, scaffold, $description_mode]
---

# $title_prefix: $skill_name

## What this skill does

Describe the repeatable workflow this skill should provide.

## Use when

- Add concrete trigger patterns.
- Keep this section short and practical.

## Do not use when

- Explain boundaries and non-goals.

## Inputs expected

- Required inputs and constraints.

## Workflow

1. Define objective.
2. Apply repeatable process.
3. Validate output quality.

## Examples and reference

- examples/: usage snippets.
- reference/: supporting notes.
"

manifest_content="{
  \"schema_version\": \"1.0\",
  \"name\": \"$skill_name\",
  \"description\": \"Starter $description_mode skill scaffold.\",
  \"version\": \"0.1.0\",
  \"portable\": $portable_flag$runtime_field,
  \"entrypoint\": \"SKILL.md\",
  \"tags\": [
    \"starter\",
    \"scaffold\",
$tags_json
  ],
$adapters_json,
$compatibility_json
}"

write_file "$skill_md_path" "$skill_md_content"
write_file "$manifest_path" "$manifest_content"
write_file "$examples_dir/.gitkeep" ""
write_file "$reference_dir/.gitkeep" ""

if [[ "$dry_run" != true && -f "$SCRIPT_DIR/generate-skills-index.py" ]]; then
  if command -v python3 >/dev/null 2>&1; then
    python3 "$SCRIPT_DIR/generate-skills-index.py" >/dev/null
    printf 'Updated skills/INDEX.md and skills/registry.json\n'
  else
    printf 'Warning: python3 not found; generated skills artifacts not regenerated\n' >&2
  fi
fi

if [[ "$dry_run" == true ]]; then
  printf '[dry-run] skill scaffold planned at %s\n' "$base_dir"
else
  printf 'Created skill scaffold at %s\n' "$base_dir"
fi
