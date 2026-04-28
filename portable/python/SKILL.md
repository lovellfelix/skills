---
name: python
description: "Use when writing, reviewing, or testing Python code — establishes project style, type-safety, testing defaults, and CI quality gates."
version: 1.0.0
portable: true
tags: [python, style, testing, type-safety, quality]
---

# Python (Style, Safety, Testing)

Overview

This consolidated skill captures the pragmatic, modern conventions we use for Python projects: a single fast linter/formatter, strict static typing on public APIs, readable docstrings, small focused tests, and CI quality gates. It prioritizes reviewability and safety over cleverness.

When to use

- Bootstrapping or hardening a Python project (linting, types, tests).
- Writing or reviewing public APIs, docstrings, and error-handling.
- Adding or updating pytest tests and CI quality gates.
- Choosing idiomatic modern syntax for readability and maintainability.

Core patterns

Tooling & configuration

- Use pyproject.toml as the single source of configuration.
- Prefer ruff as the primary linter/formatter (fast, pluggable). Use mypy or pyright for strict type checks.

```toml
# pyproject.toml (minimal)
[tool.ruff]
line-length = 120
target-version = "py312"

[tool.mypy]
python_version = "3.12"
strict = true
warn_return_any = true
```

Type safety

- Annotate all public function signatures. Use `from __future__ import annotations` for forward refs.
- Prefer dataclasses (slots=True) or Pydantic models for structured domain objects; use TypedDict for unvalidated mapping shapes.
- Avoid casual use of Any; justify and document any exception to strict typing.

```python
from __future__ import annotations
from dataclasses import dataclass

@dataclass(slots=True)
class User:
    id: str
    email: str

def find_user(email: str) -> User | None:
    ...
```

Naming & imports

- Follow PEP 8: snake_case for functions/variables, PascalCase for classes, SCREAMING_SNAKE_CASE for constants.
- Group imports: standard library, third-party, local. Prefer absolute imports for clarity.

Docstrings & small-API contracts

- Use concise Google-style docstrings for public APIs. Document args, returns, raises and give a short example when behavior is non-obvious.

```python
def process_batch(items: list[Item], max_workers: int = 4) -> BatchResult:
    """Process items using a worker pool.

    Args:
        items: Items to process (must not be empty).
        max_workers: Max parallel workers.

    Raises:
        ValueError: If items is empty.
    """
    ...
```

Error handling & observability

- Catch specific exceptions and re-raise with context: `raise X(...) from e`.
- Use custom domain exceptions to represent recoverable vs fatal errors.
- Emit structured logs and metrics at error boundaries and key I/O sites.

```python
try:
    payload = json.loads(raw)
except json.JSONDecodeError as e:
    raise ValueError("invalid json payload") from e
```

Modern idioms

- Prefer f-strings, comprehensions, enumerate/zip, and small dataclasses.
- Use the walrus operator (`:=`) sparingly — when it reduces duplication without harming readability.

```python
def parse_limit(raw: str | None) -> int:
    if raw is None or not (value := raw.strip()):
        return 10
    limit = int(value)
    if limit < 1:
        raise ValueError("limit must be positive")
    return limit
```

Testing

- Use pytest. Place tests in `tests/` mirroring the source tree.
- Start from a failing test when fixing bugs. Add regression coverage for every behavior change.
- Prefer fixtures for shared setup; keep them narrow. Use `@pytest.mark.parametrize` for matrices.
- Mock at the boundary (I/O/third-party). Use `create_autospec` or `Mock(spec_set=...)` to keep mocks typed and explicit.

```python
from unittest.mock import create_autospec

class DirectoryClient:
    def fetch(self, user_id: str) -> dict[str, str]:
        ...


def test_sync_user_uses_profile_lookup(client: DirectoryClient):
    mock_client = create_autospec(DirectoryClient, instance=True)
    mock_client.fetch.return_value = {"id": "42"}
    assert sync_user(mock_client, "42") == {"id": "42"}
```

Quality gates

Run these locally and in CI before marking work done:

```bash
# autofix and format
ruff check --fix .
ruff format .

# checks
ruff check .
ruff format --check .
pytest -q
pytest --cov
mypy .  # or pyright, if configured
```

- Require a test for every behavior change and ensure linters, type checks, and coverage gates pass in CI.
- Keep changes small and reviewable; prefer incremental commits that each pass the quality gates.

Avoid

- Bare `except:` or swallowing exceptions without logging/metrics.
- Global mutable state and mutable default arguments.
- Untyped mocks or broad, deep patching that ties tests to implementation details.
- Over-engineering: no abstract factories, single-use ABCs, or mega-fixtures for single-test needs.
- Abusing `match`/`:=` when a clear `if`/`elif` is more readable.
