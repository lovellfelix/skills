---
name: python
description: "Use when writing, reviewing, refactoring, or testing Python code, writing pytest tests or mocks, configuring ruff/mypy/pyright, or setting up a Python project's style, typing, and CI quality gates."
metadata:
  version: 2.0.0
  portable: true
  tags: [python, pytest, style, linting, type-safety, testing, quality]
---

# Python

Write the smallest reviewable change that preserves behavior, adds regression coverage, and passes the project's quality gates. Prefer direct control flow, explicit types, and tests that prove behavior over framework-shaped ceremony.

**Repo conventions win.** If the project already standardizes on a tool or style (black, flake8, unittest, `pytest-mock`, NumPy docstrings, relative imports), follow it instead of mixing in these defaults.

## Default posture

- Start from the changed behavior: write or update the failing pytest first for bug fixes and risky logic.
- Prefer plain functions, small `@dataclass(slots=True)` types, and stdlib features over new layers.
- Extract helpers only for reuse or clearer intent; keep them local.
- Raise specific exceptions and chain context: `raise X(...) from e`. Never bare `except:` or swallow errors silently.
- Document public APIs and non-obvious invariants; skip comments that narrate obvious code.

## Types

- Annotate all public signatures and meaningful locals: `list[str]`, `T | None`, `collections.abc.Iterable`, `pathlib.Path`.
- Structured data: `dataclass(slots=True)` for internal objects, Pydantic for validated external input, `TypedDict` for unvalidated mapping shapes.
- `Any` needs a reason in a comment. Prefer `object` or a `Protocol`.

## Modern syntax

- f-strings, comprehensions, `enumerate`, `zip`, `any`/`all`.
- Walrus (`:=`) only when it removes duplicate work inside a readable condition.
- `match` only for real shape/enum dispatch, not as a replacement for a clear `if/elif`.
- Keep truthiness explicit when `None`, `0`, and `""` mean different things.

```python
def parse_limit(raw: str | None) -> int:
    if raw is None or not (value := raw.strip()):
        return 10
    limit = int(value)
    if limit < 1:
        raise ValueError("limit must be positive")
    return limit
```

## Naming, imports, docstrings

- PEP 8: `snake_case` functions/variables/modules, `PascalCase` classes (acronyms stay uppercase: `HTTPClient`), `SCREAMING_SNAKE_CASE` constants. Spell words out (`user_repository.py`, not `usr_repo.py`).
- Imports grouped stdlib / third-party / local (ruff `I` enforces this). Prefer absolute imports.
- Google-style docstrings on public APIs: one-line summary, then `Args`/`Returns`/`Raises` only when they add information.

```python
def process_batch(items: list[Item], max_workers: int = 4) -> BatchResult:
    """Process items concurrently using a worker pool.

    Args:
        items: Items to process. Must not be empty.
        max_workers: Maximum concurrent workers.

    Raises:
        ValueError: If items is empty.
    """
```

## Testing

- `pytest` function tests in `tests/` mirroring the source tree.
- Narrow fixtures; move to `conftest.py` only once reused. `@pytest.mark.parametrize` for behavior matrices.
- Prefer dependency injection. When patching is necessary: patch where the symbol is **looked up**, use `autospec=True`, and annotate the injected mock.
- Use `create_autospec(...)` or `Mock(spec_set=...)`, never a loose `Mock()`.
- Test public behavior; don't test private helpers directly when the public path covers them.

```python
from typing import cast
from unittest.mock import MagicMock, create_autospec, patch

import pytest

from app.sync import DirectoryClient, sync_user


@pytest.fixture
def client() -> DirectoryClient:
    return cast(DirectoryClient, create_autospec(DirectoryClient, instance=True))


@patch("app.sync.fetch_profile", autospec=True)  # patched where sync_user looks it up
def test_sync_user_uses_profile_lookup(mock_fetch: MagicMock, client: DirectoryClient) -> None:
    mock_fetch.return_value = {"id": "42"}

    assert sync_user(client, "42") == {"id": "42"}
    mock_fetch.assert_called_once_with(client, "42")
```

## Project configuration

`pyproject.toml` is the single config source. Starting point for new projects:

```toml
[tool.ruff]
line-length = 120
target-version = "py312"

[tool.ruff.lint]
select = ["E", "W", "F", "I", "B", "C4", "UP", "SIM"]
ignore = ["E501"]  # formatter owns line length

[tool.mypy]
python_version = "3.12"
strict = true
warn_unused_ignores = true

[[tool.mypy.overrides]]
module = "tests.*"
disallow_untyped_defs = false
```

Pyright alternative: `[tool.pyright]` with `typeCheckingMode = "strict"`.

## Quality gates before done

```bash
ruff check --fix . && ruff format .   # local cleanup
ruff check . && ruff format --check . # CI-equivalent
pytest -q                             # plus --cov if coverage gates exist
mypy .                                # or the repo's configured type checker
```

Every behavior change gets regression coverage. Do not report completion while lint, format, types, or tests fail.

## Avoid

- ABCs, factories, or wrappers for a single call site.
- Global mutable state and mutable default arguments.
- Untyped mocks, deep patching, or asserting on implementation noise.
- Mega-fixtures that hide the inputs that matter.
- Clever walrus/`match` that makes code harder to scan.
