---
name: python-quality-checklist
description: Use when implementing or reviewing Python code to enforce minimum quality gates before completion.
version: 0.1.0
portable: true
tags: [python, quality, typing, docstrings, validation]
---

# Python Quality Checklist

## What this enforces

- Type hints on all function parameters and returns.
- Docstrings for public functions with args/returns/raises.
- Explicit error handling for external I/O and parsing paths.
- Input validation with clear, actionable error messages.
- Pythonic patterns for readability and maintainability.

## Mandatory Pre-Submission Checks

### 1) Types
- Every function signature is typed.
- Nullable values use explicit optional/union types.

```python
def process(data: dict[str, object], timeout: int = 30) -> str | None:
    """Process input and return a token if successful."""
    ...
```

### 2) Docstrings
- Public functions and classes include concise docstrings.
- Include exceptions that callers should expect.

```python
def calculate(x: int, y: int) -> int:
    """Return the sum of two integers.

    Raises:
        ValueError: If either input is negative.
    """
    if x < 0 or y < 0:
        raise ValueError("Inputs must be non-negative")
    return x + y
```

### 3) Error Handling
- Wrap risky external operations in specific `try/except` blocks.
- Re-raise with context using `raise ... from e`.

```python
try:
    payload = json.loads(raw)
except json.JSONDecodeError as e:
    raise ValueError("Invalid JSON payload") from e
```

### 4) Input Validation
- Validate user-provided values early.
- Fail fast with actionable messages.

```python
if not email or "@" not in email:
    raise ValueError(f"Invalid email: {email}")
```

### 5) Pythonic Patterns
- Prefer comprehensions over unnecessary `map`/`filter` chains.
- Use context managers for files/resources.
- Prefer `pathlib.Path` for filesystem work.
- Prefer f-strings for string formatting.

## Submission Rule

If any required check fails, fix it before reporting task completion.
