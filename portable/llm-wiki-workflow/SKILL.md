---
name: llm-wiki-workflow
description: Use when searching, reading, ingesting, or updating ~/llm-wiki. Wiki is the primary durable layer for curated project knowledge; session-memory is for live in-session context.
metadata:
  version: 0.3.0
  portable: true
  tags: [llm-wiki, memory, workflow, obsidian, markdown]
---

# LLM Wiki Workflow

`~/llm-wiki` is the primary durable knowledge store. It replaces `durable_memory` for curated, long-lived content and complements session-memory, which handles fast in-session context.

CLI: `llm-wiki` — a thin wrapper around `obsidian-notes` that defaults to `~/llm-wiki`. Override the vault path with `LLM_WIKI_PATH`.

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

## CLI reference

The `llm-wiki` command wraps `obsidian-notes` against the `~/llm-wiki` vault.

```
llm-wiki search <query>               # full-text search across notes and sources
llm-wiki read <path>                  # read a note (relative to vault root)
llm-wiki recent                       # list recently modified notes
llm-wiki write <path> --title "T" \
  --content "..." --tags tag1,tag2    # create or overwrite a note at that exact path
llm-wiki append <path> --content "…" # append to an existing note
llm-wiki backlinks <path>             # show notes that link to this note
llm-wiki graph <path>                 # show relationship graph for a note
llm-wiki query-tag <tag>             # list notes with a given tag
llm-wiki commit --type notes \
  --message "dotfiles: session notes" # commit vault changes to git
```

## Session-start protocol

1. `llm-wiki read notes/projects/<project>.md` — restore project context.
2. `llm-wiki recent` — scan recent changes if context is stale.
3. Fall back to session-memory `assemble_active_context` for transient state not yet promoted.

```bash
llm-wiki read notes/projects/dotfiles.md
llm-wiki recent
```

## Session-end / milestone protocol

After completing significant work, promote durable insights:

1. Update the project note with decisions and status.
2. Commit vault changes.
3. If the insight is reusable, add to `notes/workflows/`.

```bash
llm-wiki append notes/projects/dotfiles.md --content "$(cat <<'EOF'
## [2026-05-20] session summary
- Improved llm-wiki skill to use obsidian-notes CLI
EOF
)"
llm-wiki commit --type notes --message "dotfiles: session summary"
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

`notes/projects/<project>.md` is the single source of truth per project. Replaces the old `durable_memory` `current.md` pattern.

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

Create it with:

```bash
llm-wiki write notes/projects/<project>.md \
  --title "Project Name" \
  --tags project,active \
  --content "## Status\n..."
```

## Ingestion: durable_memory artifact

```bash
cp ~/.agents/memory/projects/<project>/current.md \
   ~/llm-wiki/sources/durable/<project>-$(date +%Y%m%d).md
# add immutable: true frontmatter, then link from the project note
llm-wiki commit --type notes --message "<project>: import durable artifact"
```

## Vault rules

- `sources/` entries are **immutable** — never edit after import.
- `notes/` is LLM-maintained synthesis — edit freely.
- Always commit after writing. Do not leave uncommitted wiki state.

## Validation

```bash
llm-wiki recent
git -C ~/llm-wiki status --short
```

## Bootstrap

`llm-wiki` is installed at `~/.local/bin/llm-wiki` via stow (shared module). Bootstrap's `setup_note_tools_cli()` verifies it with a help check after stow.

- Requires `obsidian-notes` and `python3` (both verified by bootstrap).
- Override vault path: `LLM_WIKI_PATH=/path/to/vault llm-wiki <command>`.

## Relationship to session-memory-mcp

- session-memory: fast lookup, current blockers, live task state, cross-session conventions.
- llm-wiki: curated synthesis, project history, decision records, workflow notes.

Promote from session-memory to wiki at session end or milestone. Query wiki at session start to restore project context without relying on session-memory being warm.

See also: `session-memory-mcp` skill and `knowledgebase-workflow` skill (uses `~/knowledgebase` via same `obsidian-notes` backend).
