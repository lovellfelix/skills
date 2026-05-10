---
name: knowledgebase-workflow
description: Use when organizing, searching, or updating the personal knowledgebase via Obsidian vault or work notes.
metadata:
  version: 1.1.0
  portable: true
  personal_machine_only: true
  tags: [knowledgebase, workflow, documentation, notes, obsidian, backlinks, graph]
---

# Knowledgebase Workflow

Operating guide for `~/knowledgebase` note retrieval, updates, and relationship-aware lookups.

## Personal Machine Activation

This skill is personal-machine only.

- Add `knowledgebase-workflow` to the personal allowlist file: `~/.personal-machine-skills.txt`.
- Keep one skill per line in that allowlist and rerun your runtime link-sync/bootstrap command.

## Tool Routing (Default)

1. Use `~/.config/opencode/scripts/obsidian-notes.sh` for automation (`search`, `read`, `write`, `append`, `query-*`, `backlinks`, `graph`, `reindex-graph`).
2. Use official `obsidian` CLI only when app-native behavior is explicitly useful (`open`, rename/move with Obsidian-managed link updates, interactive flows).
3. Use session-memory graph-shaped context as durability/continuity support, not as the source of note content.

## Work vs Personal Storage Split

- Work/project/runbook notes: `~/knowledgebase` (Obsidian markdown)
- Personal/family/life-admin notes: Apple Notes
- Do not mix personal content into work vault notes unless explicitly requested.

## Repository Structure

| Path | Purpose |
|------|--------|
| `📊 Dashboard/` | Top-level dashboards and navigation |
| `📚 Reference/` | Cheatsheets and quick references |
| `📝 Notes/` | Operational notes, monitoring, AI, journal, inbox |
| `🚀 Projects/` | Project-specific working docs |
| `📦 Archive/` | Archived or superseded content |

## Placement Rules

- Operations procedures → `📝 Notes/⚙️ Operations/`
- Monitoring guides → `📝 Notes/📊 Monitoring/`
- AI notes → `📝 Notes/🤖 Artificial Intelligence/`
- Quick references → `📚 Reference/🔧 Cheatsheets/`
- Project material → `🚀 Projects/[area]/`
- Temporary intake → `📝 Notes/Inbox/`

## Read/Write Patterns

- Exact note path known → `obsidian-notes.sh read`
- Broad query → `obsidian-notes.sh search`
- Structured creation/update → `obsidian-notes.sh write` or `append`
- Tag/type views → `obsidian-notes.sh query-tag` / `query-type`
- Relationship context → `obsidian-notes.sh backlinks` / `graph`

## Graph & Backlink Guidance

- Keep markdown as source of truth.
- Use backlinks/graph commands for traversal; use session-memory context for continuity between sessions.
- Keep graph links sparse and high-signal; avoid noisy cross-linking.
- If reindexing is needed, run `obsidian-notes.sh reindex-graph`.

## Inbox Processing

1. Classify note: operational, reference, project, duplicate.
2. Merge into canonical note when possible.
3. If standalone, rewrite with clean frontmatter and title.
4. Move to final destination.
5. Remove promoted inbox duplicate.

## Writing Defaults

- Concise, practical, scannable.
- Label code fences with language.
- Use `modified` (not `last_modified`).

Minimum frontmatter:

```yaml
---
title: "Document Title"
tags: [category, topic]
created: YYYY-MM-DD
modified: YYYY-MM-DD
type: reference|note|dashboard|project
---
```

## Validation Commands

```bash
npm run kb:check
npm run kb:backlinks
npm run kb:all
```

## Key Paths

- KB root guide: `~/knowledgebase/AGENTS.md`
- MCP metadata: `~/knowledgebase/.mcp/manifest.json`
- Dashboards: `~/knowledgebase/📊 Dashboard/README.md`
