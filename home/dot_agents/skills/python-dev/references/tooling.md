# Python Tooling Reference

**Load this reference when:** configuring ruff, pyright or pre-commit; deciding what is checked
statically and what at runtime; setting up logging, profiling or adopting tooling in a legacy tree.
One fact, one gate: a rule enforced twice is argued about twice.

## Contents

- [Ruff](#ruff) · [Type checking](#type-checking) · [Static vs runtime](#static-vs-runtime) · [Pre-commit](#pre-commit)
- [Logging](#logging) · [Profiling](#profiling) · [Legacy adoption](#legacy-adoption)

## Ruff

One binary for linting, import sorting and formatting. The rule families below are the ones worth the
noise; `ANN` is deliberately absent because annotations are pyright's job, not a second linter's.

```toml
# pyproject.toml — requires ruff >= 0.17
[tool.ruff]
target-version = "py315"
line-length = 100
src = ["src", "tests"]

[tool.ruff.lint]
select = [
    "E", "W", "F", "I", "UP", "B", "BLE", "SIM", "C4", "PIE", "RET", "PERF", "FURB", "RUF",
    "S", "T10", "T20", "PTH", "DTZ", "LOG", "G", "EM", "TRY", "RSE", "SLOT", "INP", "ISC",
    "ICN", "TID", "PGH", "FIX", "ERA", "N", "A", "PL", "ASYNC", "PT", "TC", "FA", "TD",
]
ignore = [
    "TRY003",   # messages belong inline; a message catalogue is not this project's concern
    "PLR0913",  # many arguments: a dataclass or a deps object is a design call, not a lint error
    "PLR2004",  # a literal compared to a value: named constants are for meaning, not every int
    "COM812",   # conflicts with the formatter
    "ISC001",   # conflicts with the formatter
    "TD003",    # a TODO without an issue link is still a TODO
]

[tool.ruff.lint.per-file-ignores]
"tests/**" = ["S101", "SLF001"]          # asserts and private access are the point of a test
"migrations/versions/**" = ["E501"]      # generated migrations are not hand-wrapped
"scripts/**" = ["T201"]                  # a CLI reports to stdout: that is its output contract

[tool.ruff.lint.isort]
known-first-party = ["REPLACE-ME-PKG"]
```

| Command | Purpose |
|---|---|
| `ruff check .` | Report violations |
| `ruff check . --fix` | Apply safe fixes (rewrites code) |
| `ruff format .` | Format (whitespace only) |
| `ruff format --check .` | Fail if anything would change — the CI gate |
| `ruff check --select S .` | Security rules on demand |
| `ruff check --show-settings path.py` | Prove which config and which rules apply |

Run `ruff check --fix` before `ruff format`: the first rewrites code, the second only moves whitespace,
so the reverse order leaves the file needing a second fix pass. `target-version = "py315"` prints
`Support for Python 3.15 is under development` on current releases — that warning is expected; enabling
`preview` to silence it turns on unstable rules, which is the worse trade.

## Type checking

pyright strict is the only type gate. Two checkers produce two vocabularies and two arguments about
which is right; a project that already runs mypy may keep it, but never adds the other alongside.

```toml
# pyproject.toml — requires pyright >= 1.1.414
[tool.pyright]
include = ["src", "tests"]
pythonVersion = "3.15"
typeCheckingMode = "strict"
reportUnnecessaryTypeIgnoreComment = true
reportMissingTypeStubs = false
```

- `reportUnnecessaryTypeIgnoreComment` retires stale suppressions: an ignore that no longer suppresses
  anything fails the build, so a fixed bug cannot leave a `# type: ignore` behind.
- A suppression must name the rule: `# type: ignore[arg-type]`. A bare `# type: ignore` disables the
  whole line, including errors introduced later.
- `reportMissingTypeStubs = false` keeps third-party packages without stubs from failing the build;
  annotate our own wrappers and keep going.
- If pyright rejects the target version, set the newest one it accepts and note why in the comment next
  to it. Never lower `typeCheckingMode` to make a legacy module pass — narrow `include` instead.

## Static vs runtime

| Region | Checked by | Tool |
|---|---|---|
| Outside the process: HTTP bodies, files, env vars, queue messages, CLI args | Runtime validation | pydantic model, or an explicit check raising `ValueError` |
| Inside the process: functions, classes, internal calls | Static checking | pyright strict |

Annotations are erased at runtime, so an unvalidated `dict[str, Any]` boundary is a hole: everything
downstream is typed against a lie. Validate once at the edge, convert to a frozen dataclass, and let
the checker cover the interior (see [architecture-and-errors.md](architecture-and-errors.md#boundary-mapping)).

## Pre-commit

The same commands run locally and in CI, so a violation is caught before the push. Pin every `rev` to a
released tag: a branch pin makes the build depend on whatever upstream contains that day.

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.17.3
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v6.0.0
    hooks:
      - id: check-toml
      - id: check-yaml
      - id: end-of-file-fixer
      - id: trailing-whitespace
      - id: check-merge-conflict
```

```bash
pre-commit install           # the git hook
pre-commit run --all-files   # every hook over the tree, as CI does
pre-commit autoupdate        # bump revs deliberately, in their own commit
```

Type checking stays out of pre-commit: pyright needs the whole project and the project environment,
which makes it slower than the fix-what-changed loop a commit hook is for. It belongs in CI and in the
editor.

## Logging

Library code logs through `logging.getLogger(__name__)` and configures nothing: no handler, no level,
no `basicConfig`. Configuration happens once, in the entry point, so the host application keeps control.

```python
# src/myapp/logging_setup.py — requires Python >= 3.15
import json
import logging
from contextvars import ContextVar

request_id: ContextVar[str] = ContextVar("request_id", default="-")


class JsonFormatter(logging.Formatter):
    """One JSON object per line: what a log shipper can index."""

    def format(self, record: logging.LogRecord) -> str:
        payload: dict[str, object] = {
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "request_id": request_id.get(),
        }
        payload.update(getattr(record, "extra_fields", {}))
        if record.exc_info:
            payload["exc"] = self.formatException(record.exc_info)
        return json.dumps(payload, ensure_ascii=False)


def configure(level: int = logging.INFO) -> None:
    """Called once from main(); never at import time."""
    handler = logging.StreamHandler()
    handler.setFormatter(JsonFormatter())
    logging.basicConfig(level=level, handlers=[handler])
```

- `logger.info("parsed %d rows", count)` formats lazily; an f-string is built even when the level is
  off, and the `LOG`/`G` ruff families flag it.
- Correlation: set the `ContextVar` in the request middleware or CLI entry; `contextvars` propagate into
  `asyncio` tasks and `asyncio.to_thread`, so every line carries the id without passing it around.
- Structured extras go through `extra=`: `logger.info("charged", extra={"extra_fields": {"amount": 5}})`.
- Never log secrets, tokens, full request bodies or PII; log an id and hold credentials in `SecretStr`.

## Profiling

Measure before optimising; intuition about the slow line is usually wrong.

```bash
python -X dev -m mypkg                  # dev mode: extra checks, warnings visible
python -m cProfile -o profile.out -m mypkg
python -c "import pstats; pstats.Stats('profile.out').sort_stats('cumtime').print_stats(20)"
py-spy top --pid 12345                  # live sampling of a running process
py-spy dump --pid 12345                 # every thread's stack, once
python -m profiling.sampling run script.py   # 3.15+: Tachyon, `attach <pid>` / `dump` too
```

`cProfile` measures every call and distorts the run with its own overhead; `py-spy` samples, so it fits
a production-shaped workload. 3.15 ships the `profiling` package (PEP 799), which organises the tools —
`profiling.tracing` wraps `cProfile`, `profiling.sampling` is the high-frequency sampler. `python -X dev`
plus `PYTHONWARNINGS=error` is the mode for a test run that should surface warnings early.

## Legacy adoption

Turning on the full rule set and `strict` over an old tree produces a diff nobody can review, and it
gets reverted. Stage it:

1. **Baseline.** Run the gate as-is, record the error count; every later commit must not raise it.
2. **Small rule set first** (`E`, `F`, `I`), fixed across the whole tree in one commit.
3. **Type-check new code only**: point `include` at the new package, add `# type: ignore[code]` at the
   edge of untyped legacy modules, each with its error code.
4. **Widen one package per release**, keeping the baseline non-increasing.
5. **Migrate the checker only if the current one is not actually being run.** Never run two.

`ruff check --add-noqa` is an escape hatch for a legacy file, not a fix: every generated `# noqa`
suppresses all rules on that line until someone narrows it to `# noqa: E501`.
