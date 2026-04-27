---
name: python-standards
description: "Use when writing, reviewing, or refactoring Python code to apply engineering standards for type safety, error handling, structure, and observability. Triggers on .py files or Python-related tasks."
version: 0.1.0
portable: true
tags: [python, standards, type-safety, error-handling, structure, observability]
---

# Python Standards

## Type Safety

- All functions have type annotations. Use `from __future__ import annotations` for forward refs.
- Follow mypy or pyright strict mode conventions. No `Any` without a comment explaining why.
- Prefer `TypedDict` for structured data. Prefer dataclasses or Pydantic models for domain objects.

## Error Handling

- Catch specific exceptions. Never bare `except:` or `except Exception:` without re-raise or explicit logging.
- Use custom exception classes for domain errors. Inherit from a base project exception.
- Log at the catch site. Never silently swallow exceptions.
- Any function that intentionally drops an error must have a comment explaining intent and a metric or log confirming the drop.

## Structure

- One class per file for domain objects. Utility modules grouped by concern.
- No mutable default arguments. No global mutable state.
- Use `__all__` in public modules to define the exported API explicitly.

## Observability

- Use structured logging (`structlog` or `logging` with a JSON formatter). No f-string log concatenation in production paths.
- Emit metrics at error boundaries and at I/O call sites.

## Testing

- Pytest. No unittest unless the project already uses it.
- Tests in `tests/` mirroring the source tree. One test file per source module.
- Use `pytest.mark.parametrize` for table-driven tests.
- Mock at the boundary (I/O, external calls), not deep in the call chain.

## Tooling

- `ruff` for linting and formatting. `mypy` for type checking.
- Do not introduce new tools without checking existing project config.
- `pyproject.toml` as the single configuration file. No `setup.py` or `setup.cfg` in new code.
