---
name: ask
description: OpenCode ask overlay - search work notes first, then session memory, codebase, and web.
version: 0.1.0
portable: false
tags: [qa, knowledge-search, opencode, obsidian]
---

# Ask - OpenCode Overlay

Use the portable ask workflow with OpenCode-specific tool routing.

## OpenCode Tool Order

### 1. Search work notes first

Use Obsidian work-note paths and tools first:

- `bash ~/.config/opencode/scripts/obsidian-notes.sh search "<question>" --limit 10 --json`
- For tag intent: `bash ~/.config/opencode/scripts/obsidian-notes.sh query-tag "<topic>" --limit 10 --json`

If results are sufficient, answer from them and cite note titles naturally.

### 2. Fall back to session memory

- `get_project_conventions({ project_id: "<git-basename>" })`
- `retrieve_session_context({ session_id: "<git-basename>" })`

### 3. Fall back to codebase

- Use grep/glob/read in the current repository.

### 4. Fall back to web (last resort)

- Use only when other sources are empty.
- After answering, optionally offer to capture findings in work notes.

## Rules

- Keep responses concise and sourced.
- Do not modify notes or code during ask-only requests.
- If the user explicitly asks for codebase-only or web-only lookup, skip earlier steps.
