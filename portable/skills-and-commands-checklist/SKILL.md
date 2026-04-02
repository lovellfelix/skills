---
name: skills-and-commands-checklist
description: Use when authoring or maintaining portable skills and custom commands to ensure correctness, discoverability, and long-term maintainability across tools and machines.
version: 1.0.0
portable: true
tags: [authoring, skills, commands, quality, portability, validation, maintenance]
---

# Skills and Commands Best-Practices Checklist

## Scope

This checklist covers both **portable skills** (SKILL.md + manifest.json) and **custom commands** (shell scripts, utilities, and automation). Apply sections selectively based on artifact type.

---

## 1. AUTHORING PHASE

### 1.1 Intent & Scope Validation

**Before writing any code or documentation:**

- [ ] **Define trigger condition:** When will a user invoke this? ("Use when..."). Avoid vague descriptions.
- [ ] **Confirm artifact type:** Is this a skill (technique, pattern, reference) or a command (shell utility, MCP tool)?
- [ ] **Document boundaries:** What is explicitly NOT covered? (prevents scope creep, clarifies assumptions)
- [ ] **Identify dependencies:** Does this skill/command depend on other skills, tools, or external services?
- [ ] **Check for duplicates:** Search existing skills/commands to avoid overlap.

**Rule:** If you cannot complete this section clearly, wait; the idea may not be ready.

### 1.2 Skill-Specific Authoring

**For portable skills only:**

- [ ] **Name in kebab-case:** Globally unique, no spaces, no underscores. Examples: `python-code-style`, `security-audit`, `frontend-design`.
- [ ] **Frontmatter completeness:**
  - [ ] `name:` (kebab-case)
  - [ ] `description:` (150–500 chars, starts with "Use when...")
  - [ ] `version:` (semantic: MAJOR.MINOR.PATCH)
  - [ ] `portable:` (true for cross-tool skills)
  - [ ] `tags:` (3–5 relevant tags for discovery)
  
- [ ] **Content structure matches skill type:**
  - [ ] **Technique skill:** Step-by-step procedures, workflow, decision trees, pseudocode
  - [ ] **Pattern skill:** Core patterns explained, do's/don'ts, common mistakes, aesthetic guidance
  - [ ] **Reference skill:** Comprehensive lookup guide, tools list, API examples, decision matrices
  
- [ ] **Supporting files organized:**
  - [ ] `SKILL.md` for main content
  - [ ] `manifest.json` for metadata and adapters (required)
  - [ ] `examples/` directory if content includes walkthroughs (optional)
  - [ ] `reference/` directory if content references external material (optional)
  - [ ] `scripts/` directory if content describes runnable automation (optional)

### 1.3 Command-Specific Authoring

**For custom commands (shell scripts, utilities, automation):**

- [ ] **File naming:** Use descriptive kebab-case names: `sync-memory-to-mcp.sh`, `validate-skills.sh`, `health-check.sh`.
- [ ] **Shebang declared:** `#!/usr/bin/env bash` (portable across systems).
- [ ] **Strict mode enabled:** `set -euo pipefail` to catch errors early.
- [ ] **Usage/help text:** Include `--help` or document expected arguments.
- [ ] **Exit codes documented:** Clear success (0) vs failure (non-zero) signaling.
- [ ] **Error handling:** All error paths should exit with `die()` or equivalent.

---

## 2. PORTABILITY PHASE

### 2.1 Source-of-Truth Grounding

**Skills:**

- [ ] **SKILL.md is the canonical source:** All content lives in one versioned file (+ supporting files).
- [ ] **Metadata in frontmatter mirrors manifest.json:** Name, version, tags, description must match exactly.
- [ ] **No platform-specific assumptions:** Content works in OpenCode, Cursor, Claude, and generic environments.
- [ ] **External references are durable:** Links to examples, docs, or APIs should be stable or flagged as "subject to change."

**Commands:**

- [ ] **Standalone executability:** Script runs without tool-specific dependencies (e.g., not tied to OpenCode-only APIs).
- [ ] **Environment detection:** If tool-specific (OpenCode, Cursor, etc.), detect runtime gracefully and fail with clear error.
- [ ] **Cross-platform compatibility:** Use `/usr/bin/env bash` and avoid macOS-only or Linux-only flags without fallback.

### 2.2 Metadata Parity

**Shared fields (skills):**

- [ ] **SKILL.md frontmatter `name`, `version`, `tags`** match exactly in `manifest.json`.
- [ ] **manifest.json `adapters` section:** Maps to real files in the skill directory.
  - [ ] `opencode.path` points to existing file
  - [ ] `cursor.path` points to existing file
  - [ ] `claude.path` points to existing file
  - [ ] Adapter `mode` is one of: `native`, `import`, `include`
  
- [ ] **manifest.json `compatibility` block:** Lists minimum versions for each runtime.
  - [ ] At least one runtime specified (usually `opencode`, `cursor`, `claude`)
  - [ ] `min_version` is either `*` (any version) or a version constraint

### 2.3 Runtime Isolation

**Avoid runtime-specific code in portable skills:**

- [ ] No OpenCode-only APIs in core logic (if used, document clearly).
- [ ] No Cursor-only syntax rules or Claude-specific system prompts.
- [ ] If a section is runtime-specific, use a clear header: "## OpenCode-Specific: ...".
- [ ] Fallback guidance provided for users on other platforms.

**Commands:**

- [ ] Detect available tools gracefully: `command -v opencode >/dev/null 2>&1 || die "opencode not found"`.
- [ ] Provide clear error messages if platform-specific code is required.
- [ ] Document minimum tool versions in comments or `--version` check.

### 2.4 Personal-Machine-Only Marking

**If skill/command should only run on your personal machine:**

- [ ] **In manifest.json:** Add `"personal_machine_only": true`.
- [ ] **In SKILL.md:** Include a `## Personal Machine Activation` section explaining:
  - Why it's personal-only (e.g., contains private integrations, personal workflows, or irrelevant for shared machines)
  - How to enable locally: Add skill name to `~/.config/opencode/personal-machine-skills.txt` (one per line)
  - Reference the allowlist file explicitly
  
- [ ] **Alternative: Work-machine-only skills:**
  - [ ] **In manifest.json:** Add `"work_machine_only": true`.
  - [ ] **In SKILL.md:** Include a `## Work Machine Activation` section:
    - Reference `~/.work-env-skills` flag file
    - Explain how to create the flag file if needed
    - Document behavior when flag is missing

**Rule:** If metadata says `personal_machine_only: true` or `work_machine_only: true`, the SKILL.md MUST have corresponding activation guidance section.

---

## 3. VALIDATION PHASE

### 3.1 Metadata Validation

**Run before commit:**

```bash
./hacks/validate-skills.sh
```

Checks include:

- [ ] All required frontmatter fields present in SKILL.md
- [ ] manifest.json schema is valid JSON
- [ ] All `adapters.<runtime>.path` files exist
- [ ] Version in SKILL.md matches manifest.json
- [ ] Name in SKILL.md matches manifest.json (kebab-case)
- [ ] Tags in SKILL.md match manifest.json
- [ ] If `personal_machine_only: true`, SKILL.md includes activation section
- [ ] If `work_machine_only: true`, SKILL.md includes activation section

### 3.2 Content Validation

**For skills:**

- [ ] **Completeness:** No TODO, FIXME, or placeholder sections remain.
- [ ] **Quality:** No generic, boilerplate, or filler content.
- [ ] **Examples are real:** All code examples work as written (test them).
- [ ] **Length:** Core content fits ~300–800 tokens; supporting files for overflow.
- [ ] **Tone:** Professional, direct, free of jargon without explanation.
- [ ] **Links work:** All external references are accessible (test before submit).

**For commands:**

- [ ] **Syntax check:** `bash -n script.sh` passes without errors.
- [ ] **Linting:** Run `shellcheck script.sh` and fix all warnings.
- [ ] **Manual test:** Execute script on intended platform with typical inputs.
- [ ] **Error cases:** Test with missing files, invalid arguments, network failures.

### 3.3 Portability Validation

**For skills:**

- [ ] **No tool-specific APIs** embedded without clear alternative guidance.
- [ ] **External references** point to durable sources (GitHub links, documentation, standards).
- [ ] **Examples work across platforms:** Python, Node, shell examples are cross-platform compatible.
- [ ] **Format is markdown:** No embedded proprietary syntax (e.g., Cursor's `.cursor/rules`).

**For commands:**

- [ ] **Shebang is portable:** `#!/usr/bin/env bash` (not `/bin/bash`).
- [ ] **No hardcoded paths:** Use `$HOME`, `$XDG_CONFIG_HOME`, or detect at runtime.
- [ ] **Dependencies are common:** Avoid obscure tools unless clearly documented.
- [ ] **Cross-platform tested:** If cross-platform claim, test on macOS and Linux.

### 3.4 Discoverability Validation

**Ensure humans and AI can find your artifact:**

- [ ] **Description is specific:** "Use when..." tells a clear story (not "Helpful utility for...").
- [ ] **Tags are descriptive:** 3–5 tags enable category search (e.g., `python`, `testing`, `ci-cd`).
- [ ] **README or INDEX entry:** Listed in `skills/INDEX.md` or equivalent with brief summary.
- [ ] **Related skills linked:** Document how this skill complements or depends on others.

---

## 4. GENERATION & REGISTRY PHASE

### 4.1 Index & Registry Updates

**After adding or updating a skill:**

```bash
python3 ./hacks/generate-skills-index.py
```

This updates:

- [ ] `skills/INDEX.md` — Human-readable skill catalog
- [ ] `skills/registry.json` — Machine-readable manifest registry

**Verification:**

- [ ] [ ] Your skill appears in `skills/INDEX.md` with correct summary
- [ ] [ ] Your skill is in `skills/registry.json` with matching metadata
- [ ] [ ] No duplicate entries in registry

### 4.2 Registry Freshness

**Ongoing maintenance:**

- [ ] **No stale entries:** Removed skills are deleted from registry.
- [ ] **Versions match:** Registry versions match manifest.json versions.
- [ ] **Adapter links alive:** All registry adapter paths point to existing files (validate with `validate-skills.sh`).

---

## 5. DISCOVERABILITY PHASE

### 5.1 For Skills

- [ ] **Repository index updated:** Skill listed in `/skills/INDEX.md` with correct category and summary.
- [ ] **Description triggers AI discovery:** "Use when..." phrases enable LLM context matching (test with `opencode ask ...`).
- [ ] **Tags enable search:** Skill findable via `opencode search <tag>` or equivalent.
- [ ] **Related skills documented:** Comments in SKILL.md note complementary skills ("See also: ...").

### 5.2 For Commands

- [ ] **Help text is clear:** `command --help` provides usage examples.
- [ ] **Location documented:** Lives in `hacks/` and is findable via `find`.
- [ ] **Dependencies documented:** Comments list required tools and versions.
- [ ] **Exported to PATH:** If intended for frequent use, add to shell config (`.zshrc`, `.bashrc`).

---

## 6. MAINTENANCE PHASE

### 6.1 Version Management

**Semantic versioning (MAJOR.MINOR.PATCH):**

- [ ] **PATCH bumps:** Fix typos, code examples, documentation clarity → patch version
- [ ] **MINOR bumps:** Add new sections, new examples, new adapter support, backwards-compatible changes → minor version
- [ ] **MAJOR bumps:** Breaking workflow changes, deprecated sections removed, backwards-incompatible API → major version

**Rule:** Update version in both `SKILL.md` frontmatter AND `manifest.json` simultaneously.

### 6.2 Stale Reference Prevention

**Prevent broken documentation:**

- [ ] **External links reviewed quarterly:** Update or remove dead links.
- [ ] **Tool versions noted:** If skill/command requires a specific tool version, document minimum version.
- [ ] **Deprecation warnings added:** If workflow changes, add a "Deprecated" banner with migration path.
- [ ] **Broken symlinks detected:** Run `git ls-files -d` and `git symbolic-ref` to find dead links.
- [ ] **Symlink targets resolved:** All symlinks in `.agents/`, `.claude/`, `opencode/` point to canonical files in `skills/portable/` or `skills/runtime-specific/`.

### 6.3 Cross-Reference Health

**Keep skill/command graph clean:**

- [ ] **No circular dependencies:** Skill A doesn't depend on Skill B which depends on Skill A.
- [ ] **Dependency graph documented:** If skill depends on others, list them in "Prerequisites" or "See also" section.
- [ ] **Broken "See also" links fixed:** If a skill references another skill that no longer exists, update the reference.
- [ ] **Registry consistency:** All symlinks resolve to canonical skill locations; no orphaned copies.

### 6.4 Metrics & Health Checks

**Run quarterly:**

```bash
./hacks/validate-skills.sh            # Metadata + adapter health
./hacks/generate-skills-index.py      # Rebuild registry (check for orphans)
git ls-files -d                       # List deleted tracked files
git symbolic-ref --list               # Check symlink targets
```

- [ ] **No validation errors:** All metadata consistent, all adapter paths live.
- [ ] **No orphaned files:** No skill directories exist without corresponding registry entry.
- [ ] **No dead symlinks:** All symlinks point to real files.
- [ ] **No broken cross-references:** "See also" and "Prerequisites" links are valid.

---

## 7. COMMON MISTAKES TO AVOID

### Skills

- [ ] ❌ Metadata mismatch: `SKILL.md` name ≠ `manifest.json` name → **Result:** Registry confusion, import failures
- [ ] ❌ Broken adapter paths: `manifest.json` lists `examples/foo.md` but file doesn't exist → **Result:** Runtime errors
- [ ] ❌ Vague description: "Helpful utility for..." instead of "Use when..." → **Result:** AI can't discover skill
- [ ] ❌ Platform-specific code without fallback: OpenCode-only API in core logic → **Result:** Fails in Cursor/Claude
- [ ] ❌ Missing version bumps: Skill updated but version stays the same → **Result:** Cache staleness, inconsistent deployments
- [ ] ❌ Stale external links: References to documentation, APIs, or tools that no longer exist → **Result:** Broken examples, lost context
- [ ] ❌ Missing activation documentation: `personal_machine_only: true` but no guidance in SKILL.md → **Result:** Users can't enable it

### Commands

- [ ] ❌ Hardcoded paths: `/Users/lovellfelix/` instead of `$HOME` or `dirname "$0"` → **Result:** Fails on other machines
- [ ] ❌ Missing error handling: No `set -euo pipefail` or error checks → **Result:** Silently fails or leaves corrupted state
- [ ] ❌ Tool-specific shebang: `#!/bin/bash` instead of `#!/usr/bin/env bash` → **Result:** Fails on Linux systems
- [ ] ❌ Undocumented dependencies: Script calls `jq`, `ripgrep`, or proprietary tools without checking → **Result:** Mysterious failures for users without tools installed
- [ ] ❌ No exit codes: Script runs but never signals success/failure clearly → **Result:** Automation chains can't detect problems
- [ ] ❌ Untracked versions: Tool versions hardcoded without checking if they're available → **Result:** Breaks on upgrades

---

## 8. SUBMISSION CHECKLIST

**Before marking a skill or command as complete:**

**Metadata (Skills):**
- [ ] `SKILL.md` has complete frontmatter (name, description, version, portable, tags)
- [ ] `manifest.json` exists and matches frontmatter exactly
- [ ] All adapter paths in `manifest.json` point to real files
- [ ] Version matches in both files
- [ ] If `personal_machine_only: true`, SKILL.md includes activation section
- [ ] If `work_machine_only: true`, SKILL.md includes activation section

**Content:**
- [ ] No TODO, FIXME, or placeholder sections remain
- [ ] All code examples tested and functional
- [ ] All external links verified as live
- [ ] Writing is professional, direct, jargon-explained
- [ ] Content fits core skill in ~300–800 tokens (supporting files for overflow)

**Portability:**
- [ ] No tool-specific APIs without clear fallback guidance
- [ ] No hardcoded paths or machine-specific assumptions
- [ ] Cross-platform compatibility verified
- [ ] Markdown format (no proprietary syntax)

**Validation:**
- [ ] `./hacks/validate-skills.sh` passes (metadata consistency)
- [ ] `./hacks/generate-skills-index.py` updates registry without errors
- [ ] Skill appears in updated `skills/INDEX.md`
- [ ] Manual spot-check: Can you find the skill via search/tags?

**Documentation:**
- [ ] Skill listed in appropriate section of `skills/INDEX.md`
- [ ] "See also" and "Prerequisites" links reference real skills
- [ ] Description triggers AI discovery ("Use when...")
- [ ] Tags enable category filtering

---

## 9. QUICK START BY ARTIFACT TYPE

### Creating a New Portable Skill

1. Run scaffold: `./hacks/new-skill.sh my-skill-name`
2. Edit `SKILL.md` frontmatter and content
3. Create `manifest.json` matching frontmatter exactly
4. Add examples or reference files to supporting directories if needed
5. Test examples; verify all links
6. Run validation: `./hacks/validate-skills.sh`
7. Run generation: `python3 ./hacks/generate-skills-index.py`
8. Verify skill in `skills/INDEX.md` and `skills/registry.json`
9. Commit with message: `feat(skills): add my-skill-name`

### Creating a New Command

1. Create file in `hacks/` with descriptive name: `hacks/my-command.sh`
2. Add shebang: `#!/usr/bin/env bash`
3. Add strict mode: `set -euo pipefail`
4. Document usage and error handling in comments
5. Test on intended platform(s)
6. Lint: `shellcheck hacks/my-command.sh`
7. Make executable: `chmod +x hacks/my-command.sh`
8. Document in `hacks/README.md` or project memory
9. Commit with message: `feat(hacks): add my-command`

### Updating an Existing Artifact

1. Make content changes in SKILL.md or script
2. If fixing bugs: bump patch version (0.1.0 → 0.1.1)
3. If adding features: bump minor version (0.1.0 → 0.2.0)
4. Update version in both SKILL.md and manifest.json (skills only)
5. Verify all links and examples still work
6. Run validation and generation scripts
7. Commit with message: `fix(skill-name): fix issue` or `feat(skill-name): add feature`

### Deprecating or Removing

1. **Deprecation (v2.0.0):** Add "## Deprecated" banner at top of SKILL.md with migration path
2. **Removal:** Delete skill directory, remove from registry manually or via script
3. Run `./hacks/validate-skills.sh` to confirm registry consistency
4. Commit with message: `deprecate(skill-name): reason` or `remove(skill-name): EOL`

---

## 10. REFERENCE: ARTIFACT ANATOMY

### Portable Skill (Complete Example)

```
skills/portable/my-skill/
├── SKILL.md                          # Required: Main content
├── manifest.json                     # Required: Metadata & adapters
├── examples/                         # Optional: Walkthroughs & code samples
│   ├── example1.md
│   └── example2.py
├── reference/                        # Optional: External links, reference tables
│   ├── tool-comparison.md
│   └── api-reference.md
└── scripts/                          # Optional: Runnable code
    └── setup.sh
```

**manifest.json structure:**
```json
{
  "schema_version": "1.0",
  "name": "my-skill",
  "version": "0.1.0",
  "portable": true,
  "entrypoint": "SKILL.md",
  "tags": ["category", "use-case"],
  "adapters": {
    "opencode": { "path": "SKILL.md", "mode": "native" },
    "cursor": { "path": "SKILL.md", "mode": "import" },
    "claude": { "path": "SKILL.md", "mode": "include" }
  },
  "compatibility": {
    "runtimes": {
      "opencode": { "min_version": "*" },
      "cursor": { "min_version": "*" },
      "claude": { "min_version": "*" }
    }
  }
}
```

### Custom Command (Complete Example)

```bash
#!/usr/bin/env bash
# hacks/my-command.sh — Short description of what command does
# Usage: my-command [OPTIONS] INPUT_FILE
# Dependencies: jq (for JSON parsing), curl (for HTTP)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'  # No color

die() {
    echo -e "${RED}ERROR: $*${NC}" >&2
    exit 1
}

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] INPUT_FILE

Options:
  -v, --verbose    Enable verbose output
  -o, --output     Output file (default: stdout)
  -h, --help       Show this help message

Examples:
  $(basename "$0") input.json
  $(basename "$0") -v -o output.txt input.json
EOF
    exit 0
}

# Check dependencies
command -v jq >/dev/null 2>&1 || die "jq not found. Install with: brew install jq"

# Main logic
main() {
    local input_file="${1:-}"
    [[ -z "$input_file" ]] && die "INPUT_FILE required"
    [[ -f "$input_file" ]] || die "File not found: $input_file"
    
    # Process and exit
    echo -e "${GREEN}✓ Processing complete${NC}"
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage ;;
        -v|--verbose) set -x; shift ;;
        -o|--output) output_file="$2"; shift 2 ;;
        *) break ;;
    esac
done

main "$@"
```

---

## Summary: Key Rules Every Time

1. **Metadata must match:** SKILL.md frontmatter = manifest.json exactly (names, versions, tags)
2. **Describe the trigger:** "Use when..." phrases enable discovery
3. **Ground in source truth:** One canonical SKILL.md or script; all symlinks resolve to it
4. **Test examples:** Every code snippet must work as written
5. **Check links quarterly:** Prevent stale references and broken documentation
6. **Mark personal-only clearly:** If `personal_machine_only: true`, document activation in SKILL.md
7. **Validate before commit:** Run `validate-skills.sh` and lint scripts with `shellcheck`
8. **Update registry after changes:** Run `generate-skills-index.py` so INDEX.md and registry.json stay fresh
9. **Version semantically:** Patch for fixes, minor for additions, major for breaking changes
10. **Prevent orphans:** Remove skills/commands completely or flag as deprecated; don't leave dead symlinks

---

## See Also

- **AUTHORING.md** — Detailed setup and scaffolding instructions
- **skills/INDEX.md** — Catalog of all portable skills
- **skills/registry.json** — Machine-readable skill manifest
- **SKILL-SPEC.md** — Technical specification for skill format
- **hacks/validate-skills.sh** — Automated metadata validation
- **hacks/generate-skills-index.py** — Registry regeneration tool
