---
name: python-dev
description: "Delivers Python a reviewer can check: contracts before implementation, one gate per fact, examples that run. Use when writing, reviewing or shipping Python source, tests, packaging, CI or containers; choosing a concurrency model, a type gate or a data layer; setting up pytest, ruff, pyright or uv; or calling into a Python service as a tool. Not for other languages' toolchains or shell/CI work with no Python. 中文：写/审 Python、pytest/ruff/pyright/uv、打包、并发、数据层。"
license: MIT
metadata:
  version: "1.1.0"
compatibility: "Requires Python 3.15 for the examples; the rules follow the project's `requires-python`."
---

# Python Development

Deliver Python a reviewer can check. Baseline 3.15; rules degrade to `requires-python`.

## When to Use

- Writing or reviewing Python source, tests, packaging or CI configuration.
- Laying out a service that ships as an installable SDK **and** a deployed app.
- Choosing a concurrency model, a type gate, a data layer or a container base.
- Setting up pytest, ruff, pyright, uv or a lock policy; auditing a tree for swallowed errors.

## Workflow

1. **Read the project:** `requires-python`, backend, layout, the gates CI runs. *Exit:* you can name the
   package, the floor, every gate command. → [delivery.md](references/delivery.md)
2. **Fix layering and the error contract:** domain, application, adapters, entrypoints; one exception
   base with stable `code`s. *Exit:* the direction is an import-linter contract.
   → [architecture-and-errors.md](references/architecture-and-errors.md)
3. **Settle the static/runtime boundary:** one validation point per untrusted payload, then a typed
   object. *Exit:* no `dict[str, Any]` crosses a layer.
4. **Write the failing test first.** *Exit:* the new test fails on old code; quote that failure.
   → [testing.md](references/testing.md)
5. **Implement, standard library first,** justifying each dependency (Guardrail 7). *Exit:* each import
   is justified. → [patterns.md](references/patterns.md)
6. **Decide the concurrency model before writing `async def`.** *Exit:* the decision-table row is named.
   → [async-and-concurrency.md](references/async-and-concurrency.md)
7. **Ship:** gates, `uv build`, CI, image. *Exit:* every Verification command exits 0.
   → [delivery.md](references/delivery.md)

## Output Contract

| Item | Must contain |
|---|---|
| Source | Files in the project's layout, plus the `pyproject.toml` diff with dependency bounds. |
| Public API | `Symbol \| Signature \| Purpose` per public change, annotated, `-> None` explicit. |
| Tests | Added tests, plus the command and output proving they fail on reverted code. |
| Gate output | Verbatim `ruff check`, `ruff format --check`, `pyright`, `pytest` output, with exit status. |
| Packaging | Wheel and sdist names, `py.typed` in the wheel, image tag for a release change. |

## Guardrails

1. Validate untrusted values once, at the process boundary (pydantic v2 or `ValueError`);
   the interior takes frozen dataclasses. `[PYD]`
2. Translate once, always `raise X from exc`. Never bare `except:` or `except BaseException`;
   `except Exception` only at a boundary. `[PEP8]`
3. Annotate every public signature (`-> None` explicit) with `X | None`, builtin generics and
   `collections.abc`; no `typing.Optional|Union|List|Callable` in new code. `[PEP604]`
4. All time is `datetime.now(UTC)`; transport is UTC ISO 8601 or epoch, with no lint exemption.
   `[DTZ]`
5. Nothing blocks the loop: blocking calls go to `asyncio.to_thread`, CPU work to
   `ProcessPoolExecutor`; every `await` is cancellable, cleanup in `finally`. `[ASYN]`
6. Module import has no side effects: no env read, connection, thread or logging setup; config is read
   at the composition root. `[12F]`
7. Dependency admission: stdlib first; an application uses `>=x,<y` and commits `uv.lock`; a published
   library declares a lower bound only and tracks latest in CI. `[PYPA]`
8. One environment model: `uv sync --locked`; `--system` only for a system-wide tool image. `[UV]`
9. New code passes all three gates; each test fails when the implementation is reverted. `[PYTEST]`
10. Containers: non-root, never `latest`, base minor equal to `requires-python`, `PYTHONUNBUFFERED=1`,
    no runtime toolchain. `[12F]`

## Review Mode

| Check | How to verify | Source |
|---|---|---|
| Validated once | `grep -rn "BaseModel\|BaseSettings" src/` — per entrypoint, never in `domain/` | `[PYD]` |
| No swallowed error | `ruff check --select BLE,TRY,EM,LOG,G .` | `[PEP8]` |
| Fully annotated | `pyright` reports zero diagnostics | `[PYRIGHT]` |
| Aware datetimes | `ruff check --select DTZ .` | `[DTZ]` |
| No blocking call in `async` | `grep -rn "time\.sleep\|requests\.\|open(" src/`, inspect callers | `[ASYN]` |
| No import side effect | `python -X importtime -c "import REPLACE-ME-PKG"`, env unset | `[12F]` |
| Library unbounded | `grep -n "<" pyproject.toml` — only dev groups or the SDK pin | `[PYPA]` |
| Lock current | `uv sync --locked` exits 0 | `[UV]` |
| `py.typed` shipped | `unzip -l dist/*.whl \| grep py.typed` | `[PYPA]` |
| Schema reachable | `alembic upgrade head` on a scratch DB, then `alembic check` | `[DATA]` |

## References

| File | Load when |
|---|---|
| [architecture-and-errors.md](references/architecture-and-errors.md) | Layers, the SDK/app split, exceptions, boundary mapping. |
| [patterns.md](references/patterns.md) | Version gates, typing depth, dataclasses, generators, decorators, paths. |
| [async-and-concurrency.md](references/async-and-concurrency.md) | asyncio vs threads vs processes; TaskGroup, timeouts, cancellation. |
| [data-and-resilience.md](references/data-and-resilience.md) | SQLAlchemy 2.1, units of work, Alembic, pooling, retries, caching. |
| [testing.md](references/testing.md) | pytest config, fixtures, database isolation, property tests, coverage. |
| [tooling.md](references/tooling.md) | ruff, pyright, pre-commit, logging, profiling, legacy adoption. |
| [delivery.md](references/delivery.md) | `pyproject.toml`, uv workspaces, lock policy, build, CI, containers. |

## Verification

```console
uv run ruff check .
uv run ruff format --check .
uv run pyright
uv run pytest -q
uv build
python3 scripts/check.py
```

## Sources

| Tag | Source |
|---|---|
| `[PEP604]` | https://peps.python.org/pep-0604/ |
| `[PEP8]` | https://peps.python.org/pep-0008/ |
| `[PYPA]` | https://packaging.python.org/en/latest/guides/ |
| `[PYD]` | https://docs.pydantic.dev/ |
| `[DTZ]` | https://docs.astral.sh/ruff/rules/#flake8-datetimez-dtz |
| `[ASYN]` | https://docs.python.org/3/library/asyncio-task.html |
| `[PYTEST]` | https://docs.pytest.org/en/stable/ |
| `[PYRIGHT]` | https://microsoft.github.io/pyright/ |
| `[UV]` | https://docs.astral.sh/uv/ |
| `[12F]` | https://12factor.net/ |
| `[DATA]` | https://docs.sqlalchemy.org/en/21/ |
