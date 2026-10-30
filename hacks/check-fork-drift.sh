#!/usr/bin/env bash
#
# Compare frontmatter metadata between a portable skill in this repo and a
# git-tracked (non-symlinked) fork of that skill elsewhere on disk.
#
# Only `metadata.version` and `metadata.tags` are compared. A `metadata.version`
# difference is a hard failure (exit 1); a tags-only difference is reported as a
# warning (exit 0) because forks legitimately add runtime-specific tags.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
PORTABLE_ROOT="${PORTABLE_ROOT:-$REPO_ROOT/portable}"

FIELDS=("metadata.version" "metadata.tags")

usage() {
  cat <<'EOF'
Check frontmatter drift between a portable skill and a git-tracked fork.

Usage:
  check-fork-drift.sh <skill-name> <fork-path>
  check-fork-drift.sh --help

Arguments:
  skill-name    Portable skill name under portable/ (e.g. "lean-ctx")
  fork-path     Path to a non-symlinked fork directory (or its SKILL.md)

Compared fields:
  metadata.version, metadata.tags

Supported frontmatter syntax:
  Top-level and nested mappings, flow lists (`[a, b]`), block lists (`- a`),
  quoted keys/values, and folded/literal scalars (`>` / `|`). PyYAML is used
  when installed; otherwise a strict built-in parser handles the subset above
  and rejects anything else with exit 2 (rather than silently misparsing).

Environment:
  PORTABLE_ROOT   Override the portable skills root (default: <repo>/portable)
  FORK_DRIFT_DEBUG  Set to 1 to print resolved paths

Exit codes:
  0   Versions match (tag differences are warnings only)
  1   metadata.version differs
  2   Usage or input error
EOF
}

die() {
  printf 'Error: %s\n' "$1" >&2
  exit 2
}

# Prints the value of a frontmatter key path (e.g. "metadata.version").
# Exits 3 when the file/frontmatter could not be read or parsed, and 4 when
# the requested key is missing, so callers can report the specific cause.
#
# Uses PyYAML when available; otherwise falls back to a strict line-based
# parser covering the metadata subset this repo uses (block mappings, flow
# lists, block lists, quoted keys/values, folded/literal scalars) and rejects
# anything else with exit 3 instead of guessing.
extract_frontmatter_value() {
  local file="$1"
  local key="$2"

  python3 - "$file" "$key" <<'PY'
import re
import sys

path, key = sys.argv[1], sys.argv[2]

try:
    with open(path, encoding="utf-8") as f:
        text = f.read()
except OSError as exc:
    print(f"cannot read {path}: {exc}", file=sys.stderr)
    raise SystemExit(3)

m = re.match(r"^---\r?\n(.*?)\r?\n---", text, re.DOTALL)
if not m:
    print(f"no frontmatter block in {path}", file=sys.stderr)
    raise SystemExit(3)
block = m.group(1)


def load_yaml(raw):
    """Return parsed frontmatter via PyYAML, or None when unavailable."""
    try:
        import yaml
    except ImportError:
        return None
    try:
        data = yaml.safe_load(raw)
    except yaml.YAMLError as exc:
        print(f"invalid YAML frontmatter in {path}: {exc}", file=sys.stderr)
        raise SystemExit(3)
    if data is None:
        return {}
    if not isinstance(data, dict):
        print(f"frontmatter in {path} is not a mapping", file=sys.stderr)
        raise SystemExit(3)
    return data


class Unsupported(Exception):
    pass


def unquote(value):
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        return value[1:-1]
    return value


def split_flow_list(value):
    items, current, quote, depth = [], [], None, 0
    for ch in value:
        if quote:
            current.append(ch)
            if ch == quote:
                quote = None
            continue
        if ch in "\"'":
            quote = ch
            current.append(ch)
        elif ch in "[{":
            depth += 1
            current.append(ch)
        elif ch in "]}":
            depth -= 1
            current.append(ch)
        elif ch == "," and depth == 0:
            items.append("".join(current))
            current = []
        else:
            current.append(ch)
    items.append("".join(current))
    return [unquote(i) for i in items if i.strip()]


def indent_of(line):
    return len(line) - len(line.lstrip(" \t"))


def parse_fallback(raw):
    """Strict line-based parser for the frontmatter subset we support."""
    data, stack = {}, {}
    lines = raw.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        i += 1
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        indent = indent_of(line)
        stripped = line.strip()

        if stripped.startswith("- "):
            target = None
            for depth in sorted(stack, reverse=True):
                if stack[depth]["indent"] < indent:
                    target = stack[depth]
                    break
            if target is None or not isinstance(target["data"], list):
                raise Unsupported(f"unexpected block-sequence item: {stripped!r}")
            target["data"].append(unquote(stripped[2:]))
            continue

        if ":" not in stripped:
            raise Unsupported(f"unparseable frontmatter line: {stripped!r}")
        k, v = stripped.split(":", 1)
        k, v = unquote(k), v.strip()

        while stack and stack[max(stack)]["indent"] >= indent:
            del stack[max(stack)]

        if not stack and indent != 0:
            raise Unsupported(f"unexpected indentation: {stripped!r}")
        container = stack[max(stack)]["data"] if stack else data
        if not isinstance(container, dict):
            raise Unsupported(f"unexpected mapping entry: {stripped!r}")

        if v in (">", "|", ">-", "|-", ">+", "|+"):
            # Folded/literal block scalar: gather more-indented lines verbatim.
            gathered = []
            while i < len(lines):
                nxt = lines[i]
                if nxt.strip() and indent_of(nxt) <= indent:
                    break
                gathered.append(nxt.strip())
                i += 1
            joiner = " " if v.startswith(">") else "\n"
            container[k] = joiner.join(g for g in gathered if g).strip()
        elif v == "":
            # Look ahead: block sequence or nested mapping?
            j = i
            is_list = False
            while j < len(lines):
                nxt = lines[j]
                if not nxt.strip():
                    j += 1
                    continue
                if indent_of(nxt) <= indent:
                    break
                is_list = nxt.strip().startswith("- ")
                break
            child = [] if is_list else {}
            container[k] = child
            stack[indent] = {"indent": indent, "data": child}
        elif v.startswith("{") or v.startswith("["):
            closer = "}" if v.startswith("{") else "]"
            if not v.endswith(closer):
                raise Unsupported(f"unterminated flow collection: {v!r}")
            if v.startswith("["):
                container[k] = split_flow_list(v[1:-1])
            else:
                child = {}
                for part in split_flow_list(v[1:-1]):
                    if ":" not in part:
                        raise Unsupported(f"bad flow mapping entry: {part!r}")
                    fk, fv = part.split(":", 1)
                    child[unquote(fk)] = unquote(fv)
                container[k] = child
        else:
            container[k] = unquote(v)
    return data


data = load_yaml(block)
if data is None:
    try:
        data = parse_fallback(block)
    except Unsupported as exc:
        print(
            f"unsupported frontmatter syntax in {path}: {exc} "
            "(install PyYAML for full YAML support)",
            file=sys.stderr,
        )
        raise SystemExit(3)

if "." in key:
    value = data
    for part in key.split("."):
        if not isinstance(value, dict) or part not in value:
            value = None
            break
        value = value[part]
else:
    value = data.get(key)

if value is None:
    print(f"missing frontmatter key '{key}' in {path}", file=sys.stderr)
    raise SystemExit(4)

if isinstance(value, list):
    value = ",".join(str(v) for v in value)
else:
    value = str(value).strip()
print(value)
PY
}

# Normalise a tag list (flow list, block list, or comma-separated string) into
# a sorted comma-joined string so ordering/quoting differences are not drift.
normalize_tags() {
  python3 - "$1" <<'PY'
import sys

raw = sys.argv[1].strip()
# Block sequences are flattened by the extractor into a newline-separated
# string; treat newlines the same as commas so both forms compare equally.
raw = raw.replace("\n", ",")
if raw.startswith("[") and raw.endswith("]"):
    raw = raw[1:-1]
tags = [t.strip().strip("\"'") for t in raw.split(",")]
tags = [t for t in tags if t]
print(",".join(sorted(tags)))
PY
}

main() {
  if [[ $# -eq 0 ]]; then
    usage >&2
    exit 2
  fi
  if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    usage
    exit 0
  fi
  if [[ $# -ne 2 ]]; then
    die "expected 2 arguments: <skill-name> <fork-path>"
  fi

  local skill_name="$1"
  local fork_path="$2"

  if [[ ! "$skill_name" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
    die "skill name must match [a-z0-9][a-z0-9-]*: $skill_name"
  fi

  local portable_skill_md="$PORTABLE_ROOT/$skill_name/SKILL.md"
  if [[ ! -f "$portable_skill_md" ]]; then
    die "portable skill not found: $portable_skill_md"
  fi

  local fork_skill_md="$fork_path"
  if [[ -d "$fork_path" ]]; then
    fork_skill_md="$fork_path/SKILL.md"
  fi

  if [[ -L "$fork_path" ]]; then
    die "fork path is a symlink, expected a real directory: $fork_path"
  fi
  # Check symlink before existence so a broken symlink reports the real cause.
  if [[ -L "$fork_skill_md" ]]; then
    die "fork SKILL.md is a symlink, expected a real file: $fork_skill_md"
  fi
  if [[ ! -e "$fork_skill_md" ]]; then
    die "fork SKILL.md not found: $fork_skill_md"
  fi

  if [[ "${FORK_DRIFT_DEBUG:-0}" == "1" ]]; then
    printf 'portable: %s\nfork:     %s\n' "$portable_skill_md" "$fork_skill_md" >&2
  fi

  local differing=() version_differs=0
  local field portable_value fork_value err status

  for field in "${FIELDS[@]}"; do
    status=0
    err="$(mktemp)"
    portable_value="$(extract_frontmatter_value "$portable_skill_md" "$field" 2>"$err")" || status=$?
    if [[ $status -ne 0 ]]; then
      local detail
      detail="$(cat "$err")"
      rm -f "$err"
      die "failed to read '$field' from $portable_skill_md${detail:+: $detail}"
    fi

    status=0
    fork_value="$(extract_frontmatter_value "$fork_skill_md" "$field" 2>"$err")" || status=$?
    if [[ $status -ne 0 ]]; then
      local fork_detail
      fork_detail="$(cat "$err")"
      rm -f "$err"
      die "failed to read '$field' from $fork_skill_md${fork_detail:+: $fork_detail}"
    fi
    rm -f "$err"

    if [[ "$field" == "metadata.tags" ]]; then
      portable_value="$(normalize_tags "$portable_value")"
      fork_value="$(normalize_tags "$fork_value")"
    fi

    if [[ "$portable_value" != "$fork_value" ]]; then
      differing+=("$field")
      printf 'DRIFT: %s\n  portable: %s\n  fork:     %s\n' \
        "$field" "$portable_value" "$fork_value"
      if [[ "$field" == "metadata.version" ]]; then
        version_differs=1
      fi
    fi
  done

  if [[ ${#differing[@]} -eq 0 ]]; then
    printf 'PASS: no frontmatter drift for skill "%s"\n' "$skill_name"
    exit 0
  fi

  printf '\n%s: %d field(s) differ (%s)\n' \
    "$([[ $version_differs -eq 1 ]] && printf 'FAIL' || printf 'WARN')" \
    "${#differing[@]}" \
    "$(IFS=', '; printf '%s' "${differing[*]}")"

  if [[ $version_differs -eq 1 ]]; then
    exit 1
  fi
  exit 0
}

main "$@"