---
name: ask
description: Quick Q&A workflow with source-priority search and concise, cited answers.
---

# Ask - Knowledge-First Q&A (Portable Core)

Answer questions by searching available trusted sources in priority order, then respond concisely with clear sourcing.

## Instructions

### 1. Search trusted project knowledge first

- Prefer runbooks, internal notes, and project documentation before anything external.
- Use the most relevant search capability available in the current runtime.

### 2. Fall back to session or local context

- Check active session context, project conventions, and recent workflow memory.

### 3. Fall back to codebase

- Use targeted search/read of the current repository for implementation truth.

### 4. Fall back to web (last resort)

- Use only if all higher-priority sources are empty or insufficient.
- Clearly mark web-derived guidance and uncertainty when applicable.

### 5. Answer format

- Keep to 2-3 short paragraphs or concise bullets.
- Cite source naturally inline.
- Include examples only when they add clarity.

## Rules

- Do not make code changes in ask-only flows.
- Prefer established project guidance over generic advice.
- If user explicitly asks for codebase-only or web-only results, honor that request.
