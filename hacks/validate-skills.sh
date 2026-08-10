#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

PORTABLE_ROOT="$REPO_ROOT/portable"  # this repo IS the skills root
RUNTIME_OPENCODE_ROOT="$REPO_ROOT/runtime-specific/opencode"

ERRORS=0
CHECKED=0

pass() {
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1"
  ERRORS=$((ERRORS + 1))
}

normalize_scalar() {
  local raw="$1"
  raw="${raw#\"}"
  raw="${raw%\"}"
  printf '%s' "$raw"
}

extract_frontmatter_value() {
  local file="$1"
  local key="$2"

  python3 - "$file" "$key" <<'PY'
import re, sys
path, key = sys.argv[1], sys.argv[2]
with open(path, encoding="utf-8") as f:
    text = f.read()
m = re.match(r"^---\n(.*?)\n---", text, re.DOTALL)
if not m:
    sys.exit(0)
block = m.group(1)
top, meta = {}, {}
in_meta = False
for line in block.splitlines():
    if not line.strip():
        in_meta = False
        continue
    if line[:1] in (" ", "\t"):
        if in_meta and ":" in line:
            k, v = line.strip().split(":", 1)
            meta[k.strip()] = v.strip()
        continue
    if ":" not in line:
        in_meta = False
        continue
    k, v = line.split(":", 1)
    k, v = k.strip(), v.strip()
    if k == "metadata" and v == "":
        in_meta = True
        continue
    in_meta = False
    top[k] = v
val = top.get(key, meta.get(key, ""))
if val.startswith('"') and val.endswith('"'):
    val = val[1:-1]
print(val)
PY
}

has_frontmatter() {
  local file="$1"

  awk '
    NR == 1 && $0 == "---" { started = 1; next }
    started && $0 == "---" { print "yes"; exit }
    END { if (!started) print "no" }
  ' "$file"
}

read_manifest_fields() {
  local manifest_file="$1"

  python3 - "$manifest_file" <<'PY'
import json
import sys

manifest_path = sys.argv[1]

try:
    with open(manifest_path, "r", encoding="utf-8") as f:
        data = json.load(f)
except Exception as exc:
    print(f"ERROR\t{exc}")
    raise SystemExit(1)

def norm(value):
    if isinstance(value, bool):
        return "true" if value else "false"
    if value is None:
        return ""
    return str(value)

print("OK")
for key in ("name", "version", "portable", "runtime", "personal_machine_only"):
    print(f"{key}\t{norm(data.get(key, ''))}")

print(f"local_overlay_only\t{norm(data.get('local_overlay_only', ''))}")

adapters = data.get("adapters")
if isinstance(adapters, dict):
    for runtime, adapter in adapters.items():
        if not isinstance(adapter, dict):
            continue
        path = norm(adapter.get("path", ""))
        mode = norm(adapter.get("mode", ""))
        print(f"adapter\t{runtime}\t{path}\t{mode}")

compatibility = data.get("compatibility")
if isinstance(compatibility, dict):
    runtimes = compatibility.get("runtimes")
    if isinstance(runtimes, dict):
        for runtime, details in runtimes.items():
            if not isinstance(details, dict):
                continue
            min_version = norm(details.get("min_version", ""))
            print(f"compatibility\t{runtime}\t{min_version}")
PY
}

is_valid_compat_version() {
  local version="$1"
  if [[ "$version" == "*" ]]; then
    return 0
  fi
  [[ -n "$version" && ${#version} -le 64 ]]
}

lowercase() {
  local input="$1"
  printf '%s' "$input" | tr '[:upper:]' '[:lower:]'
}

has_personal_activation_guidance() {
  local file="$1"

  awk '
    BEGIN {
      has_heading = 0
      has_allowlist = 0
      has_path = 0
    }
    {
      line = tolower($0)
      if (line ~ /^##[[:space:]]+personal[ -]machine[ -]activation([[:space:]]|$)/) {
        has_heading = 1
      }
      if (line ~ /allowlist/) {
        has_allowlist = 1
      }
      if (index($0, "~/.personal-machine-skills.txt") > 0) {
        has_path = 1
      }
    }
    END {
      if (has_heading && has_allowlist && has_path) {
        print "yes"
      } else {
        print "no"
      }
    }
  ' "$file"
}

has_local_overlay_activation_guidance() {
  local file="$1"

  awk '
    BEGIN {
      has_heading = 0
      has_flag_path = 0
    }
    {
      line = tolower($0)
      if (line ~ /^##[[:space:]]+local[ -]overlay[ -]activation([[:space:]]|$)/) {
        has_heading = 1
      }
      if (index($0, "~/.overlay/local/.enabled") > 0) {
        has_flag_path = 1
      }
    }
    END {
      if (has_heading && has_flag_path) {
        print "yes"
      } else {
        print "no"
      }
    }
  ' "$file"
}

validate_skill_dir() {
  local dir="$1"
  local is_runtime_specific="$2"
  local rel_dir="${dir#$REPO_ROOT/}"

  CHECKED=$((CHECKED + 1))

  local skill_file="$dir/SKILL.md"
  local manifest_file="$dir/manifest.json"

  if [[ ! -f "$skill_file" ]]; then
    fail "$rel_dir missing SKILL.md"
    return
  fi

  if [[ ! -f "$manifest_file" ]]; then
    fail "$rel_dir missing manifest.json"
    return
  fi

  pass "$rel_dir has SKILL.md and manifest.json"

  local manifest_output
  if ! manifest_output="$(read_manifest_fields "$manifest_file" 2>&1)"; then
    fail "$rel_dir manifest.json is not valid JSON ($manifest_output)"
    return
  fi

  pass "$rel_dir manifest.json is valid JSON"

  if [[ "$(has_frontmatter "$skill_file")" != "yes" ]]; then
    fail "$rel_dir SKILL.md missing YAML frontmatter"
    return
  fi

  local fm_name=""
  local fm_description=""
  local fm_version=""
  local fm_portable=""
  local fm_tags=""

  fm_name="$(normalize_scalar "$(extract_frontmatter_value "$skill_file" "name")")"
  fm_description="$(normalize_scalar "$(extract_frontmatter_value "$skill_file" "description")")"
  fm_version="$(normalize_scalar "$(extract_frontmatter_value "$skill_file" "version")")"
  fm_portable="$(normalize_scalar "$(extract_frontmatter_value "$skill_file" "portable")")"
  fm_tags="$(normalize_scalar "$(extract_frontmatter_value "$skill_file" "tags")")"

  if [[ -z "$fm_name" ]]; then
    fail "$rel_dir SKILL.md frontmatter missing name"
  fi
  if [[ -z "$fm_description" ]]; then
    fail "$rel_dir SKILL.md frontmatter missing description"
  fi
  if [[ -z "$fm_version" ]]; then
    fail "$rel_dir SKILL.md frontmatter missing version"
  fi
  if [[ -z "$fm_portable" ]]; then
    fail "$rel_dir SKILL.md frontmatter missing portable"
  fi
  if [[ -z "$fm_tags" ]]; then
    fail "$rel_dir SKILL.md frontmatter missing tags"
  fi

  if [[ -n "$fm_name" && -n "$fm_description" && -n "$fm_version" && -n "$fm_portable" && -n "$fm_tags" ]]; then
    pass "$rel_dir SKILL.md frontmatter includes required fields"
  fi

  local manifest_name=""
  local manifest_version=""
  local manifest_portable=""
  local manifest_runtime=""
  local manifest_personal_machine_only=""
  local manifest_local_overlay_only=""
  local adapter_count=0
  local compatibility_count=0
  local adapter_records=""
  local compatibility_records=""
  local has_opencode_adapter="false"

  while IFS=$'\t' read -r key value extra1 extra2; do
    case "$key" in
      name) manifest_name="$(normalize_scalar "$value")" ;;
      version) manifest_version="$(normalize_scalar "$value")" ;;
      portable) manifest_portable="$(normalize_scalar "$value")" ;;
      runtime) manifest_runtime="$(normalize_scalar "$value")" ;;
      personal_machine_only) manifest_personal_machine_only="$(normalize_scalar "$value")" ;;
      local_overlay_only) manifest_local_overlay_only="$(normalize_scalar "$value")" ;;
      adapter)
        adapter_count=$((adapter_count + 1))
        adapter_records+="$value"$'\t'"$(normalize_scalar "$extra1")"$'\t'"$(normalize_scalar "$extra2")"$'\n'
        if [[ "$value" == "opencode" ]]; then
          has_opencode_adapter="true"
        fi
        ;;
      compatibility)
        compatibility_count=$((compatibility_count + 1))
        compatibility_records+="$value"$'\t'"$(normalize_scalar "$extra1")"$'\n'
        ;;
    esac
  done < <(printf '%s\n' "$manifest_output" | awk 'NR > 1')

  if [[ "$adapter_count" -eq 0 ]]; then
    fail "$rel_dir manifest.json missing adapters"
  fi

  while IFS=$'\t' read -r runtime adapter_path adapter_mode; do
    [[ -n "$runtime" ]] || continue

    if [[ -z "$adapter_path" ]]; then
      fail "$rel_dir adapter '$runtime' missing path"
      continue
    fi
    if [[ -z "$adapter_mode" ]]; then
      fail "$rel_dir adapter '$runtime' missing mode"
      continue
    fi
    if [[ "$adapter_mode" != "native" && "$adapter_mode" != "import" && "$adapter_mode" != "include" ]]; then
      fail "$rel_dir adapter '$runtime' has unsupported mode '$adapter_mode'"
    fi
    if [[ ! -f "$dir/$adapter_path" ]]; then
      fail "$rel_dir adapter '$runtime' path does not exist: $adapter_path"
    fi
  done < <(printf '%s' "$adapter_records")

  if [[ "$adapter_count" -gt 0 ]]; then
    pass "$rel_dir adapter definitions are present and link to existing files"
  fi

  if [[ "$compatibility_count" -eq 0 ]]; then
    fail "$rel_dir manifest.json missing compatibility.runtimes metadata"
  fi

  while IFS=$'\t' read -r runtime min_version; do
    [[ -n "$runtime" ]] || continue

    if [[ -z "$min_version" ]]; then
      fail "$rel_dir compatibility runtime '$runtime' missing min_version"
      continue
    fi
    if ! is_valid_compat_version "$min_version"; then
      fail "$rel_dir compatibility runtime '$runtime' has invalid min_version '$min_version'"
    fi
    if ! printf '%s' "$adapter_records" | awk -F'\t' -v runtime="$runtime" '$1 == runtime { found = 1 } END { exit !found }'; then
      fail "$rel_dir compatibility runtime '$runtime' has no matching adapter"
    fi
  done < <(printf '%s' "$compatibility_records")

  while IFS=$'\t' read -r runtime _rest; do
    [[ -n "$runtime" ]] || continue
    if ! printf '%s' "$compatibility_records" | awk -F'\t' -v runtime="$runtime" '$1 == runtime { found = 1 } END { exit !found }'; then
      fail "$rel_dir adapter runtime '$runtime' missing compatibility metadata"
    fi
  done < <(printf '%s' "$adapter_records")

  if [[ "$compatibility_count" -gt 0 ]]; then
    pass "$rel_dir compatibility metadata is present for adapter runtimes"
  fi

  if [[ -n "$fm_name" && -n "$manifest_name" && "$fm_name" != "$manifest_name" ]]; then
    fail "$rel_dir name mismatch (SKILL.md=$fm_name, manifest.json=$manifest_name)"
  fi
  if [[ -n "$fm_version" && -n "$manifest_version" && "$fm_version" != "$manifest_version" ]]; then
    fail "$rel_dir version mismatch (SKILL.md=$fm_version, manifest.json=$manifest_version)"
  fi
  if [[ -n "$fm_portable" && -n "$manifest_portable" && "$(lowercase "$fm_portable")" != "$(lowercase "$manifest_portable")" ]]; then
    fail "$rel_dir portable mismatch (SKILL.md=$fm_portable, manifest.json=$manifest_portable)"
  fi

  if [[ -n "$fm_name" && -n "$manifest_name" && "$fm_name" == "$manifest_name" ]] \
    && [[ -n "$fm_version" && -n "$manifest_version" && "$fm_version" == "$manifest_version" ]] \
    && [[ -n "$fm_portable" && -n "$manifest_portable" && "$(lowercase "$fm_portable")" == "$(lowercase "$manifest_portable")" ]]; then
    pass "$rel_dir shared fields match between SKILL.md and manifest.json"
  fi

  if [[ -n "$manifest_personal_machine_only" ]] && [[ "$manifest_personal_machine_only" != "true" && "$manifest_personal_machine_only" != "false" ]]; then
    fail "$rel_dir manifest personal_machine_only must be a boolean when set"
  fi

  if [[ -n "$manifest_local_overlay_only" ]] && [[ "$manifest_local_overlay_only" != "true" && "$manifest_local_overlay_only" != "false" ]]; then
    fail "$rel_dir manifest local_overlay_only must be a boolean when set"
  fi

  if [[ "$manifest_personal_machine_only" == "true" ]]; then
    if [[ "$(has_personal_activation_guidance "$skill_file")" != "yes" ]]; then
      fail "$rel_dir personal-machine-only skill must document activation in SKILL.md (section '## Personal Machine Activation' with allowlist instructions and ~/.personal-machine-skills.txt path)"
    else
      pass "$rel_dir personal-machine-only activation guidance is documented"
    fi
  fi

  if [[ "$manifest_local_overlay_only" == "true" ]]; then
    if [[ "$(has_local_overlay_activation_guidance "$skill_file")" != "yes" ]]; then
      fail "$rel_dir local-overlay-only skill must document activation in SKILL.md (section '## Local Overlay Activation' with ~/.overlay/local/.enabled flag guidance)"
    else
      pass "$rel_dir local-overlay-only activation guidance is documented"
    fi
  fi

  if [[ "$is_runtime_specific" == "true" ]]; then
    if [[ "$(lowercase "$fm_portable")" != "false" ]]; then
      fail "$rel_dir must have frontmatter portable: false"
    fi
    if [[ "$(lowercase "$manifest_portable")" != "false" ]]; then
      fail "$rel_dir must have manifest portable: false"
    fi
    if [[ "$(lowercase "$fm_portable")" == "false" && "$(lowercase "$manifest_portable")" == "false" ]]; then
      pass "$rel_dir correctly marked portable: false for runtime-specific skill"
    fi

    if [[ -n "$manifest_runtime" && "$manifest_runtime" != "opencode" ]]; then
      fail "$rel_dir runtime-specific skill manifest runtime must be opencode"
    fi
    if [[ -z "$manifest_runtime" ]]; then
      fail "$rel_dir runtime-specific skill manifest missing runtime field"
    fi
    if [[ -n "$manifest_runtime" && "$manifest_runtime" == "opencode" ]]; then
      pass "$rel_dir runtime-specific skill has expected runtime metadata"
    fi

    if [[ "$has_opencode_adapter" != "true" ]]; then
      fail "$rel_dir runtime-specific skill must include opencode adapter"
    fi
  fi
}

main() {
  if [[ ! -d "$PORTABLE_ROOT" ]]; then
    fail "Missing directory: ${PORTABLE_ROOT#$REPO_ROOT/}"
    exit 1
  fi

  echo "Validating skills in: ${PORTABLE_ROOT#$REPO_ROOT/}"
  for dir in "$PORTABLE_ROOT"/*; do
    [[ -d "$dir" ]] || continue
    validate_skill_dir "$dir" "false"
  done

  if [[ -d "$RUNTIME_OPENCODE_ROOT" ]]; then
    echo "Validating skills in: ${RUNTIME_OPENCODE_ROOT#$REPO_ROOT/}"
    for dir in "$RUNTIME_OPENCODE_ROOT"/*; do
      [[ -d "$dir" ]] || continue
      validate_skill_dir "$dir" "true"
    done
  fi

  echo
  if [[ "$ERRORS" -gt 0 ]]; then
    echo "Validation completed with $ERRORS failure(s) across $CHECKED skill(s)."
    exit 1
  fi

  echo "Validation passed for $CHECKED skill(s)."
}

main "$@"
