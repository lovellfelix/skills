---
name: context-optimization
description: Use when exploring a large or unfamiliar codebase, handling long tool or log output, approaching context limits, or optimizing a session for token cost and context bloat.
metadata:
  version: 0.2.0
  portable: true
  tags: [performance, optimization, context, tokens, efficiency]
  applies_to: [all]
---

# Context Optimization

## Rules

1. Search before reading.
2. Read only the smallest useful window.
3. Load skills only when they materially help.
4. Cache small reusable findings.
5. Discard noisy tool output after completion.

## Recommended Flow

```text
glob("**/*.{ts,py,md}")
grep("class UserService")
read("src/user-service.ts", { offset: 42, limit: 40 })
```

## Read Strategy

- Files under ~100 lines: reading the whole file is usually fine.
- Files 100-500 lines: use judgment.
- Files over ~500 lines: locate the section first, then read a window.
- Prefer several small targeted reads over one full-file read.

## Cache Reusable Findings

Store small, reusable discoveries so later turns or sessions don't re-explore (see `session-memory-mcp`; argument names vary by harness):

```text
session_memory action=learn_project_convention project_id=dotfiles language=shell convention_type=style
session_memory action=store_context key=explored:auth-flow contextType=workflow value="entry: src/auth/index.ts:15"
```

## Shell Guidance

- Prefer dedicated tools over shell for file discovery and file reading.
- If shell is necessary, keep output narrow and machine-friendly (`| head`, `--json --jq`, `-q`).
- Avoid `find`, `cat`, and broad `ls` for routine exploration.
- Where `lean-ctx` is installed, route reads and shell output through it (see `lean-ctx`).

## Delegate Wide Searches

When answering requires sweeping many files and you only need the conclusion, hand the search to a subagent (if the harness has them) and keep only its summary in your context.

## Reporting

- Return only the outcome, touched paths, and validation status.
- Do not paste long code blocks unless the user asked.

## Goal

Keep free-agent tasks comfortably under 10k tokens whenever possible.
