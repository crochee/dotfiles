---
name: python-dev
description: Use when writing Python code, setting up tests with pytest, or configuring Python application deployment.
metadata:
  author: skills-team
---

# Python Development

## When to Use

- Writing or reviewing Python code
- Setting up test infrastructure
- Containerizing/deploying Python applications

**Invoke `test-driven-development` skill** when implementing via TDD.

## Patterns Summary

| Problem | Solution |
|---------|----------|
| Type hints | Annotate function signatures |
| Internal containers | `@dataclass` |
| Runtime validation | Pydantic |
| Large datasets | Generators (lazy evaluation) |
| File paths | `pathlib.Path` |
| Preserving metadata | `@functools.wraps` |

**See [references/patterns.md](references/patterns.md) for detailed patterns.**

## Testing Summary

| Pattern | Example |
|---------|---------|
| Fixtures | `@pytest.fixture` with `yield` for setup/teardown |
| Parametrization | `@pytest.mark.parametrize` |
| Mocking | `@patch` decorator |
| Running | `pytest --cov=pkg`, `--lf` (last-failed), `-k "test_name"` |

**See [references/testing.md](references/testing.md) for complete testing guide.**

## Deployment Summary

| Tool | Use |
|------|-----|
| `venv` | Standard library |
| `uv` | Fast resolution (recommended) |
| `pipx` | Global CLI tools |
| `pyproject.toml` | Package definition |

**See [references/deployment.md](references/deployment.md) for Docker, Gunicorn/Uvicorn.**

## DO / DON'T

| DO | DON'T |
|----|--------|
| Type hints on signatures | Mutable defaults (`def foo(x=[])`) |
| `is None` check | `== None` |
| Generators for large data | Load all in memory |
| `@functools.wraps` in decorators | Share state between tests |
| Pin dependency versions | Use `:latest` Docker tags |

## References

- [references/patterns.md](references/patterns.md) - Type hints, dataclasses, decorators, pathlib
- [references/testing.md](references/testing.md) - pytest fixtures, mocking, coverage
- [references/deployment.md](references/deployment.md) - Docker, servers, environment