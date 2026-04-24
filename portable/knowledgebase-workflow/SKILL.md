---
name: knowledgebase-workflow
description: Use this skill when organizing, searching, or updating the personal knowledgebase.
version: 0.1.0
portable: false
personal_machine_only: true
tags: [knowledgebase, workflow, documentation, notes, reference]
---

# Knowledgebase Workflow

## What this skill does

Provides a practical operating guide for working in `~/knowledgebase`.

Use it to:

- find the right place for new notes
- process inbox material into durable docs
- update hub pages without adding clutter
- keep `.mcp` metadata aligned with the repository layout
- prefer canonical docs over duplicative fragments

## Use when

- The user asks where a note should live in the knowledgebase.
- The task involves processing `📝 Notes/Inbox/`.
- The task involves cleaning up, reorganizing, or simplifying KB docs.
- The task involves updating hub pages such as `README.md` files.
- The task changes major KB structure and `.mcp/manifest.json` may need updates.
- The user asks how to use, search, or maintain this knowledgebase.

## Do not use when

- The task is unrelated to `~/knowledgebase`.
- The task is pure software implementation in another repository.
- The task only needs a one-off file edit with no KB placement or structure question.

## Inputs expected

- The target note or notes to create, update, or process.
- The current repository structure under `~/knowledgebase`.
- Existing related documents, if the task may be duplicative.

## Repository Rules

- `📊 Dashboard/` is for top-level dashboards and navigation.
- `📚 Reference/` is for cheatsheets and quick references.
- `📝 Notes/` is for operational notes, monitoring, AI notes, journal, and inbox.
- `🚀 Projects/` is for project-specific working docs and design material.
- `📦 Archive/` is for archived or superseded content.

Use the actual emoji-based paths in links and edits.

## Placement Rules

- Operations procedures -> `📝 Notes/⚙️ Operations/`
- Monitoring guides -> `📝 Notes/📊 Monitoring/`
- AI notes and agent material -> `📝 Notes/🤖 Artificial Intelligence/`
- Quick references -> `📚 Reference/🔧 Cheatsheets/`
- Project-specific material -> `🚀 Projects/[area]/`
- Temporary intake -> `📝 Notes/Inbox/`

## Inbox Workflow

When processing inbox notes:

1. Read the note and identify whether it is operational, reference, project, or duplicate material.
2. Merge into an existing canonical note when possible.
3. If it should stand alone, rewrite it into a polished note with frontmatter and a clear title.
4. Move or promote it into the correct destination.
5. Remove the original inbox copy after promotion or merge.

## Writing Defaults

- Keep notes concise, practical, and scannable.
- Start promoted notes with a short blockquote describing purpose.
- Use explicit section headers.
- Label fenced code blocks with a language.
- Prefer `modified`, not `last_modified`.

Minimum promoted frontmatter:

```yaml
---
title: "Document Title"
tags: [category, topic, type]
aliases: ["Alt Name"]
created: YYYY-MM-DD
modified: YYYY-MM-DD
type: reference|note|dashboard|project
---
```

## Metadata and runtime guidance

This knowledgebase includes local `.mcp/` metadata and helper scripts.

- `.mcp/server.js` runs the KB MCP server.
- `.mcp/manifest.json` defines search categories and taxonomy.
- `.mcp/generate-index.js` refreshes `.mcp/index.json`.
- `.mcp/validate-metadata.js` validates frontmatter coverage.

Rules:

- Treat `.mcp/manifest.json` as search metadata, not the source of truth for content placement.
- In Pi, prefer harness-native tools when available instead of assuming a directly exposed knowledgebase MCP server.
- If folder structure changes materially, update `.mcp/manifest.json`.
- After large doc reorganizations, run `node .mcp/generate-index.js`.
- After broad frontmatter cleanup, run `node .mcp/validate-metadata.js`.
- Do not hand-edit `.mcp/index.json`.

## Hub Page Rules

- Keep hub pages short and navigational.
- Link to the most useful destinations, not every related file.
- Remove stale summaries, dead references, and speculative structure.
- Use `README.md` only when a folder genuinely needs a hub.

## Canonicalization Rules

- Prefer updating an existing canonical note over creating a near-duplicate.
- If two notes overlap heavily, keep the better destination and merge useful content into it.
- Archive or remove stale copies only after useful content has been preserved.

## Maintenance Checks

When doing KB cleanup, inspect:

- inbox backlog in `📝 Notes/Inbox/`
- old oncall notes in `📝 Notes/⚙️ Operations/oncall/`
- broken or stale hub links
- malformed or missing frontmatter
- docs that are too long and should become quick references

## Examples and reference

- Root KB guide: `~/knowledgebase/AGENTS.md`
- MCP metadata: `~/knowledgebase/.mcp/manifest.json`
- Main hubs:
  - `~/knowledgebase/📊 Dashboard/README.md`
  - `~/knowledgebase/📝 Notes/README.md`
  - `~/knowledgebase/📚 Reference/README.md`
  - `~/knowledgebase/🚀 Projects/README.md`

## Personal Machine Activation

This skill is personal-machine-only and stays disabled unless explicitly allowlisted.

- Add `knowledgebase-workflow` to `~/.personal-machine-skills.txt` (one skill name per line).
- Re-run your runtime link sync after updating the allowlist.
