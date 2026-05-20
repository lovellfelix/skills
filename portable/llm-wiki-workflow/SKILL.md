---
name: llm-wiki-workflow
description: Use when searching, reading, ingesting, or updating ~/llm-wiki from durable memory and session-memory context.
metadata:
  version: 0.1.0
  portable: true
  tags: [llm-wiki, memory, workflow, obsidian, markdown]
---

# LLM Wiki Workflow

Use this skill for the personal Obsidian vault at `~/llm-wiki`.

## Personal Machine Activation

This skill is personal-machine only.

- Add `llm-wiki-workflow` to `~/.personal-machine-skills.txt`.
- Keep one skill name per line.
- Rerun the runtime sync/bootstrap step after updating the allowlist.

## Use when

- You need to search or read existing wiki notes.
- You are promoting durable memory into source notes.
- You are turning useful session-memory into a reusable wiki note.
- You are updating curated notes, index pages, or the append-only log.

## Do not use when

- The context is only useful for the current response.
- The content is sensitive, secret, or credential-like.
- You are about to overwrite a source note instead of preserving it.

## Vault rules

- `sources/` is immutable source material.
- `notes/` is LLM-maintained synthesis.
- `index.md` is the entry point.
- `log.md` is append-only history.
- `schema.md` is the note contract.

## Memory-to-wiki ingestion rules

- Durable memory artifacts → `sources/durable/`.
- Session-memory snapshots → `sources/session/` only when they are worth keeping.
- Keep the original provenance: source path, timestamps, and a short summary.
- Preserve `immutable: true` on source notes.
- Keep `derived_from` links from curated notes back to source notes.
- If the context is transient, leave it in session-memory and do not ingest it.
- Never store secrets, tokens, or raw noise.

## Search / read / update flow

1. Search for an existing note first.
2. Read the exact note path.
3. Update or create the smallest note that fits.
4. Append a log entry for the change.
5. Validate frontmatter and backlinks.

## Concise commands

### Search

```bash
rg -n "gitops-homelab|grenadianbuzz|personal-assistant" ~/llm-wiki
```

### Read

```bash
sed -n '1,160p' ~/llm-wiki/notes/workflows/ingest-memory.md
sed -n '1,160p' ~/llm-wiki/sources/durable/grenadianbuzz.md
```

### Update a curated note

```bash
$EDITOR ~/llm-wiki/notes/projects/grenadianbuzz.md
printf '\n## [2026-05-20] update | added llm-wiki workflow note\n- Linked new source and synthesis notes.\n' >> ~/llm-wiki/log.md
```

### Import a durable memory artifact

```bash
cat > ~/llm-wiki/sources/durable/grenadianbuzz.md <<'EOF'
---
title: "GrenadianBuzz Handoff"
type: source
created: 2026-05-20
updated: 2026-05-20
source_kind: durable_memory
source_ref: /Users/lovellfelix/.agents/memory/handoffs/2026/05/20260503T154100Z-grenadianbuzz.md
immutable: true
tags: [memory, handoff, grenadianbuzz]
---
EOF
```

## Minimal frontmatter shape

```yaml
---
title: "Source title"
type: source
created: 2026-05-20
updated: 2026-05-20
source_kind: durable_memory
source_ref: /absolute/path/to/source.md
immutable: true
tags: [memory]
---
```

## Validation

```bash
find ~/llm-wiki -name '*.md' | sort
rg -n '^---$|^title: |^type: |^created: |^updated: |^source_kind: |^immutable:' ~/llm-wiki
rg -n 'source_ref|derived_from|immutable: true' ~/llm-wiki
git -C ~/llm-wiki status --short
```

## Related notes

- `~/llm-wiki/notes/workflows/ingest-memory.md`
- `~/llm-wiki/notes/workflows/query-wiki.md`
- `~/llm-wiki/notes/workflows/personal-assistant.md`
- `~/llm-wiki/notes/decisions/wiki-principles.md`
