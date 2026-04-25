---
name: go-standards
description: Apply Go idioms and engineering standards when writing, reviewing, or refactoring Go code. Triggers on .go files, go.mod references, or Go-related tasks.
version: 0.1.0
portable: true
tags: [go, standards, portable]
---

# Go Standards

## Error Handling

- Prefer explicit error returns over panic. Always handle errors at the call site.
- Use `errors.Is` / `errors.As` for error inspection. Never string matching.
- Wrap errors with `fmt.Errorf("context: %w", err)` to preserve the chain.
- Never silently discard errors. If an error is intentionally ignored, add a comment explaining why.

## Interfaces

- Interfaces belong in the consumer package, not the implementer's.
- Accept interfaces, return concrete types.
- Prefer small, single-method interfaces. Avoid large interface definitions.

## Structure

- One package per directory. Package name matches directory name. No `_util` or `_helper` suffixes.
- Keep `main.go` thin — only wiring and entry point. Business logic in separate packages.
- Use `internal/` for packages not intended as public API.
- Table-driven tests using `t.Run` subtests. No test helper libraries unless already in the project.

## Concurrency

- Document goroutine ownership and lifetime at the declaration site.
- Channels for coordination, mutexes for shared state protection. Do not mix.
- Always define goroutine exit conditions. No goroutine leaks.
- Use `context.Context` as the first parameter for any function that may block or call I/O.

## Observability

- Emit structured logs using the project's established logger. Check existing usage before introducing a new one.
- Instrument error paths — errors returned to callers should have corresponding log or metric emission at the boundary.
- Prefer named return values in exported functions for documentation clarity, not for naked returns.

## Anti-patterns

- No `init()` unless strictly necessary and documented.
- No global mutable state.
- No naked `_` in error position unless the error is provably safe to ignore. Comment required.
