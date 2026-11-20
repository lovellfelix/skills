---
name: llm-wiki-workflow
description: Use when searching, reading, ingesting, or exporting ~/llm-wiki. Wiki is the human-readable archive for knowledge kept in ~/.agents/memory; session-memory is for live in-session context.
metadata:
  version: 0.4.0
  portable: true
  tags: [llm-wiki, memory, workflow, obsidian, markdown]
---

# LLM Wiki Workflow

`~/llm-wiki` is the human-readable archive for project knowledge. Use the `~/.agents/memory/` files (global facts in `global/`, per-repo facts in `projects/<repo>/`, each folder with a `MEMORY.md` index) as the runtime source of truth; use the wiki for human-readable project summaries, exported decisions, and immutable imported sources.

CLI: `llm-wiki` — standalone bash script (no external dependencies beyond git and coreutils) that defaults to `~/llm-wiki`. Override the vault path with `LLM_WIKI_PATH`.

## Personal Machine Activation

This skill is personal-machine only.

- Linked automatically when `~/.overlay/local/.enabled` is absent (no allowlist to maintain).

## Memory hierarchy

| Layer | Store | Use for | Lifetime |
| --- | --- | --- | --- |
| Live context | harness todo list / plan file | Active blockers, task state | Current session |
| Durable runtime truth | `~/.agents/memory/` files | Project facts, corrections, reusable knowledge | Long-term |
| Exported curated notes | `~/llm-wiki/notes/` | Human-readable project synthesis promoted from agent memory | Long-term |
| Exported raw sources | `~/llm-wiki/sources/` | Immutable imports from session or external sources | Permanent |
| Memory mirror | `~/llm-wiki/sources/agents-memory/` | Weekly fleet job mirrors `~/.agents/memory` here | Permanent |

**Rule:** write durable project knowledge to `~/.agents/memory/` first. Export or promote to `~/llm-wiki` when you need a human-readable archive.

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

The `llm-wiki` command is a standalone bash script managing the `~/llm-wiki` vault.

```
llm-wiki search <query>               # full-text search across notes and sources
llm-wiki read <path>                  # read a note (relative to vault root)
llm-wiki recent                       # list recently modified notes
llm-wiki write <path> --title "T" \
  --content "..." --tags tag1,tag2    # create or overwrite a note at that exact path
llm-wiki append <path> --content "…" # append to an existing note
llm-wiki backlinks <path>             # show notes that link to this note
llm-wiki query-tag <tag>             # list notes with a given tag
llm-wiki import <path> [--project <slug>] # import a durable artifact into sources/durable/
llm-wiki commit --type notes \
  --message "dotfiles: session notes" # commit vault changes to git
```

## Session-start protocol

1. Read the project's `MEMORY.md` index under `~/.agents/memory/` (and `global/`) first.
2. `llm-wiki read notes/projects/<project>.md` when you need the exported human-readable project summary.
3. `llm-wiki recent` to inspect recent archive changes if context is stale.
4. Transient state not yet saved lives in the harness todo list or a plan file.

```bash
llm-wiki read notes/projects/dotfiles.md
llm-wiki recent
```

## Session-end / milestone protocol

After completing significant work, promote insights from `~/.agents/memory` into the wiki archive:

1. Confirm the durable fact or decision already exists in `~/.agents/memory/`.
2. Update the project note with exported decisions and status.
3. Pull and reconcile remote wiki changes (e.g. `git -C ~/llm-wiki pull --rebase` or `git -C ~/llm-wiki pull`) and resolve any conflicts; then commit vault changes locally and push the branch to publish the exported note.
4. If the insight is reusable, add to `notes/workflows/`.

```bash
# update note
llm-wiki append notes/projects/dotfiles.md --content "$(cat <<'EOF'
## [2026-05-20] session summary
- Improved llm-wiki skill (standalone CLI)
EOF
)"
# reconcile remote, resolve conflicts, then commit & push
git -C ~/llm-wiki pull --rebase   # or 'git pull' to merge; resolve any conflicts
llm-wiki commit --type notes --message "dotfiles: session summary"
git -C ~/llm-wiki push
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
    agents-memory/ — weekly mirror of ~/.agents/memory (fleet job)
    durable/        — imported from durable_memory (immutable)
    session/        — promoted session-memory snapshots (immutable)
```

## Project note pattern

`notes/projects/<project>.md` is the human-readable export/archive note for a project. The `~/.agents/memory/` files remain the canonical source of truth for runtime facts, corrections, and durable project knowledge. This replaces the old `durable_memory` `current.md` pattern as the preferred archive format.

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
- Always pull and reconcile remote changes before committing and pushing; commit after resolving any conflicts and do not leave uncommitted or unresolved wiki state.

## Validation

Before committing or pushing, pull remote changes and resolve any conflicts:

```bash
git -C ~/llm-wiki pull --rebase   # or 'git pull' to merge; resolve conflicts if any
# resolve conflicts, then verify
llm-wiki recent
git -C ~/llm-wiki status --short
# finally push
git -C ~/llm-wiki push
```

## Bootstrap

`llm-wiki` is installed at `~/.local/bin/llm-wiki` via stow (shared module). Bootstrap's `setup_note_tools_cli()` verifies it with a help check after stow.

- Requires `git` and coreutils (verified by bootstrap).
- Override vault path: `LLM_WIKI_PATH=/path/to/vault llm-wiki <command>`.

## Wiki maintenance procedure

### Corrections file format

```
### <topic>

<one-sentence rule>

**Why:** <the incident or reason>

**How to apply:** <where/when this guidance kicks in>
```

Add under `## Active` in `notes/learnings/corrections.md`. Move stale entries to `## Archive`.

### Promotion triggers

Promote session work to wiki when ≥1 is true:

- ≥2 corrections in the session
- A new reusable pattern or workflow was established
- Significant project state changed (new blocker, decision, milestone)
- User says "remember this", "add to wiki", or "promote this"

### After any wiki write → commit and push

```bash
cd ~/llm-wiki
git add -A
git commit -m "<type>(<scope>): <summary>"  # feat | ingest | curate | config | fix
git push
```

One commit per logical batch. Do this immediately after the write step, not at session end.

## Relationship to session-memory-mcp

- `~/.agents/memory/` files: durable project and global facts.
- llm-wiki: exported synthesis, project history, decision records, workflow notes.

Promote from `~/.agents/memory` to the wiki at session end or milestone. Query the wiki when you need the exported human-readable summary, not as the primary runtime store.

See also: `session-memory-mcp` skill (file-memory conventions). The legacy `knowledgebase-workflow` skill is archived.
