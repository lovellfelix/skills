---
name: writing-modern-python
description: Use when implementing or modifying Python code and pytest tests and need concise, typed, production-ready changes with modern syntax, walrus-operator patterns, fixtures, annotated mocks, @patch usage, and Ruff/pytest quality gates.
version: 0.1.0
portable: true
tags: [python, pytest, quality, testing, portable]
---

# Writing Modern Python

Write the smallest reviewable change that preserves behavior, adds regression coverage, and passes the project's quality gates. Prefer direct control flow, explicit types, and tests that prove behavior without adding framework-shaped ceremony.

## Default posture

- Start from the changed behavior: add or update the failing pytest first for bug fixes and risky logic.
- Prefer plain functions, small `dataclass(slots=True)` types, and existing stdlib features over new layers.
- Keep helpers small and local; extract only for reuse or clearer intent.
- Type public functions and meaningful locals. Prefer `list[str]`, `dict[str, object]`, `T | None`, `collections.abc`, and `pathlib.Path`.
- Document public APIs and non-obvious invariants; skip comments and docstrings that only narrate obvious code.
- Raise specific exceptions and chain context with `raise ... from e`.

## Modern syntax rules

- Prefer f-strings, comprehensions, `enumerate`, `zip`, `any`, and `all`.
- Use the walrus operator (`:=`) only when it removes duplicate work inside a readable condition.
- Use `match` only when branching on real shapes or enums; do not replace a clear `if/elif` chain just because it is available.
- Keep truthiness checks explicit when `None`, `0`, and `""` mean different things.

```python
def parse_limit(raw: str | None) -> int:
    if raw is None or not (value := raw.strip()):
        return 10

    limit = int(value)
    if limit < 1:
        raise ValueError("limit must be positive")
    return limit
```

## Testing defaults

- Use `pytest` function tests unless the repo already standardizes on something else.
- Prefer fixtures for shared setup or collaborators; keep fixtures narrow and move them to `conftest.py` only after reuse appears.
- Use `@pytest.mark.parametrize` for behavior matrices instead of copy-paste tests.
- Prefer dependency injection first. When patching is necessary, patch where the symbol is looked up, use `autospec=True`, and annotate the injected mock.
- Prefer `create_autospec(...)` or `Mock(spec_set=...)` over loose `Mock()`.
- If the repo already standardizes on `pytest-mock` or `monkeypatch`, follow that local style instead of mixing test APIs.

```python
from typing import cast
from unittest.mock import MagicMock, create_autospec, patch

import pytest


class DirectoryClient:
    def fetch(self, user_id: str) -> dict[str, str]:
        raise NotImplementedError


def fetch_profile(client: DirectoryClient, user_id: str) -> dict[str, str]:
    return client.fetch(user_id)


def sync_user(client: DirectoryClient, user_id: str) -> dict[str, str]:
    return fetch_profile(client, user_id)


@pytest.fixture
def client() -> DirectoryClient:
    return cast(DirectoryClient, create_autospec(DirectoryClient, instance=True))


@patch(__name__ + ".fetch_profile", autospec=True)
def test_sync_user_uses_profile_lookup(
    mock_fetch_profile: MagicMock,
    client: DirectoryClient,
) -> None:
    mock_fetch_profile.return_value = {"id": "42"}

    assert sync_user(client, "42") == {"id": "42"}
    mock_fetch_profile.assert_called_once_with(client, "42")
```

## Quality gates before done

- Local cleanup: `ruff check --fix .` and `ruff format .`
- Final verification / CI equivalent: `ruff check .` and `ruff format --check .`
- `pytest -q`
- `pytest --cov` or the repo's coverage command, if coverage gates are configured
- `mypy .` or the repo's configured type checker, if present
- Add or update regression coverage for every behavior change.
- Do not report completion while lint, format, coverage, or tests still fail.

## Avoid

- Abstract base classes, wrappers, or factories for a single call site.
- Untyped mocks, broad patching, or assertions on implementation noise.
- Clever walrus or `match` usage that makes code harder to scan.
- Mega-fixtures that hide the inputs that actually matter.
- Testing private helpers directly when public behavior can cover the case.

## See also

- `python-code-style` for wider linting, naming, docstring, and project-level tooling guidance.
