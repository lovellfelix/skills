---
name: llm-wiki-workflow
description: Use when searching, reading, ingesting, or updating ~/llm-wiki. Wiki is the primary durable layer for curated project knowledge; session-memory is for live in-session context.
metadata:
  version: 0.2.0
  portable: true
  tags: [llm-wiki, memory, workflow, obsidian, markdown]
---

# LLM Wiki Workflow

`~/llm-wiki` is the primary durable knowledge store. It replaces `durable_memory` for curated, long-lived content and complements session-memory, which handles fast in-session context.

## Personal Machine Activation

This skill is personal-machine only.

- Add `llm-wiki-workflow` to `~/.personal-machine-skills.txt`.
- Keep one skill name per line.
- Rerun the runtime sync/bootstrap step after updating the allowlist.

## Memory hierarchy

| Layer           | Store                        | Use for                                            | Lifetime        |
| --------------- | ---------------------------- | -------------------------------------------------- | --------------- |
| Live context    | session-memory (SQLite)      | Active blockers, decisions, task state             | Current session |
| Durable curated | `~/llm-wiki/notes/`          | Project synthesis, decisions, workflow notes       | Long-term       |
| Durable raw     | `~/llm-wiki/sources/`        | Immutable imports from session or external sources | Permanent       |
| _(legacy)_      | `~/.agents/memory/projects/` | Old durable_memory artifacts — migrate to wiki     | Deprecated      |

**Rule:** when you'd write a `durable_memory` record for project knowledge, write to `~/llm-wiki` instead.

## Use when

- Searching or reading existing wiki notes across projects.
- Promoting a session-memory insight into a durable curated note.
- Ingesting a durable_memory artifact into `sources/durable/`.
- Updating curated notes, index pages, or the append-only log.
- Starting/ending a session and needing persistent context for a project.

## Do not use when

- The context is only useful for the current response.
- Content is sensitive, secret, or credential-like.
- About to overwrite a source note (sources are immutable).

## Session-start protocol

1. Check `~/llm-wiki/index.md` for the active project entry.
2. Read `~/llm-wiki/notes/projects/<project>.md` if it exists.
3. Scan `~/llm-wiki/log.md` (last 30 lines) for recent activity.
4. Fall back to session-memory `assemble_active_context` for transient state not yet promoted.

```bash
tail -30 ~/llm-wiki/log.md
cat ~/llm-wiki/notes/projects/dotfiles.md
```

## Session-end / milestone protocol

After completing significant work, promote durable insights:

1. Update `~/llm-wiki/notes/projects/<project>.md` with decisions and status.
2. Append a log entry to `~/llm-wiki/log.md`.
3. If the insight is a reusable workflow, add to `~/llm-wiki/notes/workflows/`.
4. Leave transient task state in session-memory; do not promote noise.

```bash
printf '\n## [%s] dotfiles | <summary>\n- <bullet>\n' "$(date +%Y-%m-%d)" >> ~/llm-wiki/log.md
```

## Vault structure

```
~/llm-wiki/
  index.md          — entry point; project registry
  log.md            — append-only activity log
  schema.md         — note contract and frontmatter rules
  notes/
    projects/       — one note per project (curated, LLM-maintained)
    decisions/      — ADRs and principles
    workflows/      — reusable process notes
  sources/
    durable/        — imported from durable_memory (immutable)
    session/        — promoted session-memory snapshots (immutable)
```

## Project note pattern

`~/llm-wiki/notes/projects/<project>.md` is the single source of truth for a project. It replaces the old `durable_memory` `current.md` pattern.

```yaml
---
title: "Project Name"
type: note
project: project-slug
status: active
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [project]
---

## Status
Current state in one sentence.

## Active work
- What is in progress

## Decisions
- Key choices and their rationale

## Open questions
- Unresolved items
```

## Ingestion commands

### Import a durable_memory artifact

```bash
cp ~/.agents/memory/projects/<project>/current.md \
   ~/llm-wiki/sources/durable/<project>-$(date +%Y%m%d).md
# then add immutable frontmatter and link from the project note
```

### Promote a session insight

```bash
# Write the curated note
$EDITOR ~/llm-wiki/notes/projects/<project>.md
# Append log entry
printf '\n## [%s] <project> | <change>\n- <detail>\n' "$(date +%Y-%m-%d)" >> ~/llm-wiki/log.md
# Commit
git -C ~/llm-wiki add -A && git -C ~/llm-wiki commit -m "<project>: <summary>"
```

## Search / read / update flow

1. Search for an existing note first — don't create duplicates.
2. Read the exact note path before editing.
3. Update the smallest note that fits; prefer existing notes over new files.
4. Append a log entry.
5. Validate frontmatter and commit.

## Concise commands

### Search

```bash
rg -n "gitops-homelab\|grenadianbuzz\|personal-assistant\|dotfiles" ~/llm-wiki
```

### Read a project note

```bash
cat ~/llm-wiki/notes/projects/dotfiles.md
```

### Read sources

```bash
sed -n '1,160p' ~/llm-wiki/sources/durable/grenadianbuzz.md
```

## Vault rules

- `sources/` entries are **immutable** — never edit, only append frontmatter.
- `notes/` is LLM-maintained synthesis — edit freely.
- `log.md` is **append-only** — never delete or reorder entries.
- `schema.md` is the note contract — follow it for all frontmatter.

## Validation

```bash
find ~/llm-wiki -name '*.md' | sort
rg -n '^---$|^title: |^type: |^created: |^updated: |^immutable:' ~/llm-wiki
git -C ~/llm-wiki status --short
```

## Relationship to session-memory-mcp

The two layers are complementary, not competing:

- session-memory: fast lookup, current blockers, live task state, cross-session conventions.
- llm-wiki: curated synthesis, project history, decision records, workflow notes.

Promote from session-memory to wiki at session end or milestone. Query wiki at session start to restore project context without relying on session-memory being warm.

See also: `session-memory-mcp` skill for in-session memory operations.
