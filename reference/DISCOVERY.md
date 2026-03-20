# Skills Discovery & Convention

Guidelines for naming, structuring, and discovering skill packages across runtimes.

## Quick Ref

- **Location**: `skills/portable/<name>/` (portable) or `skills/runtime-specific/<runtime>/` (runtime-specific)
- **Core files**: `SKILL.md`, `manifest.json`
- **Triggers**: Document in SKILL.md frontmatter + "Use when" section
- **Metadata**: YAML frontmatter in `SKILL.md`

## Naming

- Use lowercase with hyphens: `my-skill-name`
- Keep it short (1-3 words)
- Use nouns or verb-noun pairs: `python-code-style`, `release-skills`, `ask`
- Avoid generic names like `utilities` or `helpers`

## Directory Structure

Minimal required:

```
skills/portable/<skill-name>/
├── SKILL.md           # Main skill document with metadata
├── manifest.json      # Adapter mappings and versioning
├── examples/          # Optional: concrete usage examples
├── reference/         # Optional: supporting docs
└── scripts/           # Optional: helper automation
```

## Required Files

### SKILL.md

Main documentation with **YAML frontmatter** followed by content.

**Frontmatter fields:**

```yaml
---
name: skill-name                     # Must match directory name
description: One-line purpose        # ~60 chars, discovery text
version: 0.1.0                      # Semantic versioning
portable: true|false                # true=works across runtimes
tags: [tag1, tag2]                  # Searchable categories
---
```

**Frontmatter rules:**
- All fields required for discovery
- `portable: true` for `portable/` skills
- `portable: false` for `runtime-specific/` skills
- Tags help discovery and filtering

**Content structure:**

```markdown
# [Skill Name]

## What this skill does
Brief explanation.

## Use when
- Bullet list of trigger scenarios
- Should match typical OpenCode/IDE workflow prompts
- Include both positive cases and anti-patterns

## Do not use when
- Bullet list of anti-patterns or exclusions

## Inputs expected
What parameters/context the skill needs.

## Workflow
Step-by-step process or key patterns.

## Core patterns
Key decisions or patterns users should know.

## Examples and reference
Links to `examples/` or `reference/` files.
```

### manifest.json

Maps skill to runtime adapters and versioning.

**Minimal example:**

```json
{
  "schema_version": "1.0",
  "name": "skill-name",
  "version": "0.1.0",
  "portable": true,
  "entrypoint": "SKILL.md",
  "tags": ["category", "tag"],
  "adapters": {
    "opencode": {
      "path": "SKILL.md",
      "mode": "native"
    },
    "cursor": {
      "path": "SKILL.md",
      "mode": "import"
    },
    "claude": {
      "path": "SKILL.md",
      "mode": "include"
    }
  },
  "compatibility": {
    "runtimes": {
      "opencode": {
        "min_version": "*"
      },
      "cursor": {
        "min_version": "*"
      },
      "claude": {
        "min_version": "*"
      }
    }
  }
}
```

**Compatibility metadata:**
- `compatibility.runtimes` must exist in `manifest.json`
- Runtime keys should match `adapters` keys
- `min_version` can be `*` (no minimum) or a runtime version constraint string
- Optional `personal_machine_only: true` keeps a skill disabled unless enabled via local allowlist (`~/.config/opencode/personal-machine-skills.txt`)

**Adapter modes:**
- `native`: Runtime loads and executes directly
- `import`: Runtime imports via reference
- `include`: Runtime embeds in context

## Canonical Metadata Sources

When fields appear in both `manifest.json` and `SKILL.md` frontmatter, follow this guidance:

- **`manifest.json` is authoritative** for runtime loading, adapter resolution, and version control.
- **`SKILL.md` frontmatter is authoritative** for discovery-facing metadata that appears in documentation and IDE search results.
- **Keep overlapping fields in sync** (name, version, portable, tags) to prevent discovery/runtime mismatch.

This split ensures runtimes can load skills reliably while discovery tools surface current, accurate metadata.

## Trigger Documentation

Triggers describe when and how a skill is invoked.

### In "Use when" section

Write natural language trigger scenarios matching typical prompts:

**Good:**
```markdown
## Use when

- User says "release", "new version", "bump version"
- User mentions deploying or publishing a package
- Workflow involves updating changelog and tags
```

**Avoid:**
```markdown
## Use when

- trigger_key: "release|publish|deploy"
- Internal API mode
```

### In frontmatter tags

Include at least one category tag:
- `starter` - template or reference
- `workflow` - multi-step process
- `diagnostic` - analysis or inspection
- `reference` - documentation or guidance
- `integration` - external tool/API integration

### Discovery patterns

Natural language patterns that tools can match:
1. Exact word match: "release", "standup"
2. Semantic match: "update version" -> version-bumping skills
3. Tag match: user asks about "markdown" -> skills tagged "writing"

Keep "Use when" and anti-patterns explicit in SKILL.md.

## Portable vs Runtime-Specific

### Portable (`skills/portable/`)

- Works across multiple runtimes without modification
- Core logic in `SKILL.md`; adapters in `manifest.json`
- Example: reference docs, code style guides, workflows
- Should have `portable: true` in frontmatter

### Runtime-Specific (`skills/runtime-specific/<runtime>/`)

- Tailored to one runtime (OpenCode, Cursor, etc.)
- May reference runtime-specific tools or APIs
- Example: OpenCode workflow extensions
- Should have `portable: false` in frontmatter
- Organized by runtime subdirectory

## Scaffolding & Validation

### Generate New Skill Scaffold

Use the scaffolding script to create a new skill with correct structure and templates:

```bash
./scripts/new-skill.sh my-skill-name
```

Creates a portable skill under `skills/portable/my-skill-name/` with:
- `SKILL.md` template
- `manifest.json` with adapter stubs
- Optional directories (`examples/`, `reference/`)

For runtime-specific skills:

```bash
./scripts/new-skill.sh my-skill-name --runtime opencode
```

### Validate Skill Metadata

Run validation to check all skills for completeness and correctness:

```bash
./scripts/validate-skills.sh
```

Checks:
- Frontmatter completeness (name, description, version, portable, tags)
- Directory naming conventions
- `manifest.json` JSON validity
- Metadata field consistency
- Adapter path health (`adapters.*.path` points to an existing file)
- Compatibility coverage for adapter runtimes

### Quality Checks

Before committing a new skill:

- [ ] `name` in frontmatter matches directory name
- [ ] `SKILL.md` has complete YAML frontmatter
- [ ] `manifest.json` is valid JSON
- [ ] `description` is ~60 chars or less
- [ ] "Use when" has 2+ concrete trigger examples
- [ ] Directory structure follows convention
- [ ] No hardcoded file paths (use relative or placeholder)
- [ ] Validation passes: `./scripts/validate-skills.sh`

## Integration with Agent System

Skills are loaded into agent context via:

1. **Direct reference** in agent config:
   ```json
   "skills": ["skills/portable/my-skill"]
   ```

2. **Discovery lookup** by tags/triggers:
   - Runtime searches `skills/` for matching tags
   - Frontmatter metadata enables fuzzy matching

3. **Adapter resolution**:
   - `manifest.json` tells runtime which file to load
   - Different runtimes load via different `modes`

## Migration from Old Locations

Skills previously scattered across agent directories:

- `~/.claude/skills/` -> `skills/portable/`
- `~/.agents/skills/` -> `skills/portable/`
- `~/.config/opencode/skills/` -> `skills/runtime-specific/opencode/`

Index them in `skills/INDEX.md` under the appropriate section once migrated.
