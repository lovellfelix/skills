---
name: obsidian-work-notes
description: Official Obsidian CLI-first workflow for work notes, with local wrapper fallback for custom search, writes, and graph operations
tags: [obsidian, notes, knowledge, work-notes, search, backlinks, graph, vault]
applies_to: [notes, ask, kb, engineering, personal-assistant]
---

# Obsidian Work Notes Skill

Use this skill for work-note retrieval, note updates, and note graph workflows in `~/knowledgebase`.

## Goals

- Prefer the official `obsidian` CLI when it supports the operation.
- Use the local `obsidian-notes.sh` wrapper for custom or structured workflows.
- Keep markdown in the vault as the source of truth.
- Keep graph relationships in session-memory, not in a separate notes MCP.

## Routing Rule

Use this order:

1. `~/.config/opencode/scripts/obsidian-notes.sh` first for background automation.
2. Official `obsidian` CLI only for explicitly interactive/app-native operations.
3. Session-memory graph tools or wrapper graph commands for backlinks/traversal.

## Use Official Obsidian CLI First

Prefer the official CLI only when you intentionally want Obsidian app behavior for:

- `search`
- `read`
- `backlinks`
- `links`
- `open`
- `daily:*`
- rename/move flows where Obsidian-managed link updates matter

Preferred patterns:

```bash
obsidian vault="knowledgebase" search query="UCM rollout" format=json
obsidian vault="knowledgebase" read path="Projects/UCM/rollout-plan.md"
obsidian vault="knowledgebase" backlinks path="Projects/UCM/rollout-plan.md" format=json
```

Rules:

- Always pass `vault=...` explicitly.
- Prefer `path=` over `file=` when you know the exact note path.
- Prefer machine-readable output when the CLI supports it.
- The official CLI is app-native and may launch or require the Obsidian desktop app.
- For unattended automation, do not use the official CLI by default.
- If the official CLI errors, fall back silently.
- To opt into official CLI from the wrapper, set `OBSIDIAN_NOTES_PREFER_OFFICIAL=1`.

## Use The Wrapper For Custom Cases

Use `obsidian-notes.sh` for:

- `write`
- `append`
- `query-tag`
- `query-type`
- `parse-links`
- `sync-note`
- `reindex-graph`
- `graph`
- any workflow that needs structured frontmatter normalization or local graph indexing

Examples:

```bash
bash ~/.config/opencode/scripts/obsidian-notes.sh query-tag "ucm" --limit 10 --json
bash ~/.config/opencode/scripts/obsidian-notes.sh write "Projects/UCM" "Rollout Plan" "..." --tags "ucm,rollout" --type project --json
bash ~/.config/opencode/scripts/obsidian-notes.sh reindex-graph --json
bash ~/.config/opencode/scripts/obsidian-notes.sh graph "Rollout Plan" --depth 2 --json
```

## Read Patterns

- Known exact note -> wrapper by default; official `obsidian ... read path=...` only when app-native behavior is desired
- Broad text query -> wrapper by default; official `obsidian ... search ...` only when explicitly opted in
- Tag/type filtering -> wrapper
- Need relationship context -> official `backlinks` first, wrapper/session-memory graph for broader traversal

## Write Patterns

- New or updated note content -> wrapper
- Section append -> wrapper
- Standardized frontmatter -> wrapper
- Bulk or scripted edits -> wrapper

## Graph Patterns

- Quick backlinks -> wrapper by default; official CLI only when explicitly opted in
- Durable note graph -> wrapper + session-memory
- Full vault rebuild -> wrapper only

## Failure Handling

- If `obsidian` is missing or broken, keep using the wrapper without surfacing internal noise.
- If the wrapper needs `python3`, surface a concise dependency error.
- If note resolution is ambiguous, prefer exact path/permalink.

## Installation Notes

- Official CLI comes from the Obsidian desktop app.
- On macOS, enable it in Obsidian: `Settings -> General -> Command line interface`.
- Bootstrap should verify the official CLI and install the `obsidian-notes` wrapper.

## Agent Guidance

- `notes`: load this skill by default for work-note tasks.
- `/ask`: load this skill when the question depends on work notes.
- `/kb`: load this skill every time.
- `language-coder`: load this skill only when checking work-note patterns or runbooks.
- `jr-orchestrator`: do not deep-load this skill unless routing depends on work-note lookup.

## Short Rule

If the task is "use work notes", load `obsidian-work-notes`, use `obsidian-notes.sh` for automation, and opt into official `obsidian` only when app-native behavior is specifically useful.
