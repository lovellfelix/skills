---
name: knowledgebase-workflow
description: "Use when organizing, searching, or updating the personal knowledgebase via Obsidian vault or work notes."
version: 1.0.0
portable: false
personal_machine_only: true
tags: [knowledgebase, workflow, documentation, notes]
---

# Knowledgebase Workflow

Operating guide for working in `~/knowledgebase`. Use for note placement, inbox processing, hub maintenance, and KB cleanup.

## Repository Structure

| Path | Purpose |
|------|--------|
| `\U0001f4ca Dashboard/` | Top-level dashboards and navigation |
| `\U0001f4da Reference/` | Cheatsheets and quick references |
| `\U0001f4dd Notes/` | Operational notes, monitoring, AI, journal, inbox |
| `\U0001f680 Projects/` | Project-specific working docs |
| `\U0001f4e6 Archive/` | Archived or superseded content |

Use actual emoji-based paths in links and edits.

## Placement Rules

- Operations procedures \u2192 `\U0001f4dd Notes/\u2699\ufe0f Operations/`
- Monitoring guides \u2192 `\U0001f4dd Notes/\U0001f4ca Monitoring/`
- AI notes \u2192 `\U0001f4dd Notes/\U0001f916 Artificial Intelligence/`
- Quick references \u2192 `\U0001f4da Reference/\U0001f527 Cheatsheets/`
- Project material \u2192 `\U0001f680 Projects/[area]/`
- Temporary intake \u2192 `\U0001f4dd Notes/Inbox/`

## Inbox Processing

1. Read note; classify as operational, reference, project, or duplicate.
2. Merge into existing canonical note when possible.
3. If standalone, rewrite with frontmatter and clear title.
4. Move to correct destination.
5. Remove original inbox copy after promotion.

## Writing Defaults

- Concise, practical, scannable. Label code blocks with a language.
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

## Hub Page Rules

- Keep hub pages short and navigational.
- Link to useful destinations, not every related file.
- Remove stale summaries and dead references.
- Use `README.md` only when a folder genuinely needs a hub.

## Canonicalization

- Update existing canonical notes over creating near-duplicates.
- Merge overlapping notes; keep the better destination.
- Archive stale copies only after preserving useful content.

## Maintenance Checks

Inspect: inbox backlog, old oncall notes, broken hub links, malformed frontmatter, notes too long for quick reference.

## Validation Commands

```bash
npm run kb:check        # duplicate/frontmatter checks
npm run kb:backlinks    # generate backlinks index
npm run kb:all          # both in sequence
```

## Key Paths

- KB root guide: `~/knowledgebase/AGENTS.md`
- MCP metadata: `~/knowledgebase/.mcp/manifest.json`
- Dashboards: `~/knowledgebase/\U0001f4ca Dashboard/README.md`
