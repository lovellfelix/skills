#!/usr/bin/env bash
#
# Tests for hacks/check-fork-drift.sh. Self-contained: builds throwaway
# portable-root/fork fixtures in a temp dir and asserts exit codes + output.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CHECK="$REPO_ROOT/hacks/check-fork-drift.sh"

TMPDIR_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_ROOT"' EXIT

PASSED=0
FAILED=0

pass() { printf 'PASS: %s\n' "$1"; PASSED=$((PASSED + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAILED=$((FAILED + 1)); }

make_skill() {
  local dir="$1" version="$2" tags="$3"
  mkdir -p "$dir"
  {
    printf -- '---\n'
    printf 'name: demo\n'
    printf 'description: Demo skill.\n'
    printf 'metadata:\n'
    printf '  version: %s\n' "$version"
    printf '  portable: true\n'
    printf '  tags: %s\n' "$tags"
    printf -- '---\n\n'
    printf '# Demo\n'
  } >"$dir/SKILL.md"
}

# run_check <expected-exit> <label> <args...>
run_check() {
  local expected="$1" label="$2"
  shift 2
  local out status
  set +e
  out="$(PORTABLE_ROOT="$TMPDIR_ROOT/portable" "$CHECK" "$@" 2>&1)"
  status=$?
  set -e
  if [[ "$status" -ne "$expected" ]]; then
    fail "$label (expected exit $expected, got $status)"
    printf '%s\n' "$out" | sed 's/^/    /'
    return 1
  fi
  printf '%s' "$out"
  return 0
}

portable="$TMPDIR_ROOT/portable/demo"
make_skill "$portable" "0.2.0" "[alpha, beta]"

# 1. Identical fork passes.
make_skill "$TMPDIR_ROOT/fork-ok" "0.2.0" "[alpha, beta]"
if out="$(run_check 0 "matching fork exits 0" demo "$TMPDIR_ROOT/fork-ok")"; then
  [[ "$out" == *"PASS: no frontmatter drift"* ]] \
    && pass "matching fork reports PASS" \
    || fail "matching fork output: $out"
fi

# 2. Version drift exits non-zero and names the field.
make_skill "$TMPDIR_ROOT/fork-old" "0.1.0" "[alpha, beta]"
if out="$(run_check 1 "version drift exits 1" demo "$TMPDIR_ROOT/fork-old")"; then
  [[ "$out" == *"metadata.version"* ]] \
    && pass "version drift names metadata.version" \
    || fail "version drift output: $out"
  [[ "$out" == *"0.2.0"* && "$out" == *"0.1.0"* ]] \
    && pass "version drift prints both values" \
    || fail "version drift values missing: $out"
fi

# 3. Tags drift is reported but does not fail.
make_skill "$TMPDIR_ROOT/fork-tags" "0.2.0" "[alpha, gamma]"
if out="$(run_check 0 "tags-only drift exits 0" demo "$TMPDIR_ROOT/fork-tags")"; then
  [[ "$out" == *"metadata.tags"* ]] \
    && pass "tags drift names metadata.tags" \
    || fail "tags drift output: $out"
fi

# 4. Tag order/quoting differences are not drift.
make_skill "$TMPDIR_ROOT/fork-tag-order" "0.2.0" "['beta', \"alpha\"]"
run_check 0 "tag order is normalised" demo "$TMPDIR_ROOT/fork-tag-order" >/dev/null \
  && pass "tag order is normalised"

# 5. Both fields drifting is reported together, exit 1.
make_skill "$TMPDIR_ROOT/fork-both" "0.0.1" "[delta]"
if out="$(run_check 1 "both fields drift exits 1" demo "$TMPDIR_ROOT/fork-both")"; then
  [[ "$out" == *"metadata.version"* && "$out" == *"metadata.tags"* ]] \
    && pass "both drifted fields are named" \
    || fail "both fields output: $out"
fi

# 6. Multi-line tags list is parsed.
mkdir -p "$TMPDIR_ROOT/fork-multiline"
{
  printf -- '---\n'
  printf 'name: demo\n'
  printf 'description: Demo skill.\n'
  printf 'metadata:\n'
  printf '  version: 0.2.0\n'
  printf '  tags:\n'
  printf '    [alpha,\n'
  printf '     beta]\n'
  printf -- '---\n'
} >"$TMPDIR_ROOT/fork-multiline/SKILL.md"
run_check 0 "multi-line tags parse" demo "$TMPDIR_ROOT/fork-multiline" >/dev/null \
  && pass "multi-line tags parse"

# 7. Passing SKILL.md directly instead of the directory works.
run_check 0 "accepts SKILL.md path" demo "$TMPDIR_ROOT/fork-ok/SKILL.md" >/dev/null \
  && pass "accepts SKILL.md path"

# 8. Symlinked fork is rejected with exit 2.
ln -s "$TMPDIR_ROOT/fork-ok" "$TMPDIR_ROOT/fork-link"
out="$(run_check 2 "symlink rejected" demo "$TMPDIR_ROOT/fork-link" || true)"
[[ "$out" == *"symlink"* ]] && pass "symlink rejection message" \
  || fail "symlink rejection output: $out"

# 9. Unknown skill is an input error (exit 2).
run_check 2 "unknown skill exits 2" nope "$TMPDIR_ROOT/fork-ok" >/dev/null \
  && pass "unknown skill exits 2"

# 10. Missing fork path is an input error (exit 2).
run_check 2 "missing fork exits 2" demo "$TMPDIR_ROOT/absent" >/dev/null \
  && pass "missing fork exits 2"

# 11. Missing metadata key is an input error, not silent success.
mkdir -p "$TMPDIR_ROOT/fork-nokey"
printf -- '---\nname: demo\ndescription: Demo.\n---\n' >"$TMPDIR_ROOT/fork-nokey/SKILL.md"
run_check 2 "missing metadata key exits 2" demo "$TMPDIR_ROOT/fork-nokey" >/dev/null \
  && pass "missing metadata key exits 2"

printf '\n%d passed, %d failed\n' "$PASSED" "$FAILED"
[[ "$FAILED" -eq 0 ]]