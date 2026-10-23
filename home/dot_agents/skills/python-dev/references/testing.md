# Python Testing Reference

**Load this reference when:** building or repairing a pytest suite — configuration, fixtures, database
isolation, parametrization, property tests, mocking, async and integration tests, coverage. A test that
cannot fail is decoration.

## Contents

- [Configuration](#configuration) · [Fixtures](#fixtures) · [Database fixture](#database-fixture) · [Parametrization](#parametrization) · [Property tests](#property-tests)
- [Mocking](#mocking) · [Async tests](#async-tests) · [Integration tests](#integration-tests) · [Running the suite](#running-the-suite)
- [Coverage](#coverage) · [What a good suite contains](#what-a-good-suite-contains)

## Configuration

`pytest-asyncio` and `pytest-cov` are plugins, not part of pytest: without the first, every async test
fails with `async def functions are not natively supported`, and under `--strict-markers` it fails at
collection because the `asyncio` marker is unknown. Without the second, `--cov` is an unknown option.

```toml
# pyproject.toml — requires Python >= 3.15, pytest >= 9.2
[dependency-groups]
dev = [
    "pytest>=9.2,<10",
    "pytest-asyncio>=1.4,<2",
    "pytest-cov>=7.1,<8",
    "pytest-xdist>=3.6,<4",
    "hypothesis>=6.170,<7",
]

[tool.pytest.ini_options]
minversion = "9.0"
testpaths = ["tests"]
addopts = "-ra --strict-markers --strict-config"
asyncio_mode = "strict"
# Pinned deliberately: unset, the plugin derives this from the fixture scope, and a
# future release plans to default it to "function". Writing it down freezes today's behaviour.
asyncio_default_fixture_loop_scope = "function"
markers = [
    "slow: long-running test; deselect with -m 'not slow'",
    "integration: needs a real service; CI runs -m 'not integration' by default",
]
filterwarnings = ["error"]
```

`asyncio_mode = "strict"` requires `@pytest.mark.asyncio` on every async test; `auto` collects them
without the marker — pick one for the whole suite. `filterwarnings = ["error"]` turns a deprecation into
a failing test at the moment its cause is upgraded, the only cheap time to fix it.

## Fixtures

A fixture is a generator with `yield`: setup before, teardown after, and teardown runs even when the
test raises.

```python
# tests/conftest.py — requires Python >= 3.15
from collections.abc import Iterator
from pathlib import Path

import pytest


@pytest.fixture
def workspace(tmp_path: Path) -> Iterator[Path]:
    """A scratch directory; teardown runs even when the test raises."""
    target = tmp_path / "workspace"
    target.mkdir()
    yield target
```

Reach for the built-ins before writing a fixture: `tmp_path`, `monkeypatch`, `capsys`, `caplog`,
`request`. Scopes must not fight: a function-scoped fixture may not depend on a session-scoped one that
depends on a function-scoped fixture.

## Database fixture

Two traps decide this section. **In-memory SQLite is per-connection**: with the dialect's default
`SingletonThreadPool`, a second thread or a `-n auto` worker gets a *different, empty* database.
**Nothing creates the schema** unless the fixture does, and a schema from `create_all` is not the schema
Alembic builds.

```python
# tests/conftest.py — requires sqlalchemy >= 2.1
from collections.abc import Iterator

import pytest
from sqlalchemy import Engine, create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from myapp.adapters.db.models import Base


@pytest.fixture(scope="session")
def engine() -> Iterator[Engine]:
    """One shared in-memory database for the whole session.

    `StaticPool` keeps a single connection alive, so every session and every
    thread sees the same database; `check_same_thread=False` allows that one
    connection to be used from the test thread.
    """
    test_engine = create_engine(
        "sqlite+pysqlite:///:memory:",
        poolclass=StaticPool,
        connect_args={"check_same_thread": False},
    )
    Base.metadata.create_all(test_engine)
    try:
        yield test_engine
    finally:
        test_engine.dispose()


@pytest.fixture
def db_session(engine: Engine) -> Iterator[Session]:
    """A session that never commits: the transaction is discarded on the way out."""
    with sessionmaker(bind=engine)() as session:
        yield session
        session.rollback()
```

- `create_all` plus Alembic is a two-track schema: a model change with no migration passes the suite
  and fails the deploy. Either run `alembic upgrade head` against the test database, or assert
  `alembic check` reports no pending revision in CI.
- Use a real Postgres (testcontainers) once the query needs `ON CONFLICT`, `RETURNING`, `jsonb`, window
  functions or transactional DDL — SQLite accepts some and rejects others, so a green suite proves
  nothing about production.
- An async session fixture needs the same `StaticPool` treatment via `create_async_engine`; without it
  each `AsyncSession` opens a fresh empty memory database.

## Parametrization

One test function, many inputs; `ids` name the cases in the failure output.

```python
# tests/test_text.py — requires pytest >= 9.2
import pytest

from mypkg.text import slugify


@pytest.mark.parametrize(
    ("value", "expected"),
    [("Hello World", "hello-world"), ("  Trim  Me  ", "trim-me"), ("UPPER", "upper")],
    ids=["spaces", "padded", "uppercase"],
)
def test_slugify(value: str, expected: str) -> None:
    assert slugify(value) == expected
```

Parameters multiply: five values cross four values is twenty tests, which is intended only when both
axes matter. `pytest.param(..., marks=pytest.mark.slow)` tags a single case.

## Property tests

Hypothesis generates inputs a hand-written table never covers. Use it where an invariant is cheaper to
state than the cases: parsers, serializers, normalizers, money arithmetic, state machines.

```python
# tests/test_slug.py — requires hypothesis >= 6.170
from hypothesis import example, given, settings
from hypothesis import strategies as st

from mypkg.text import slugify


@settings(max_examples=200, deadline=None)
@given(st.text())
@example("  --Hello--  ")
def test_slug_is_idempotent_and_safe(value: str) -> None:
    slug = slugify(value)
    assert slugify(slug) == slug
    assert all(char.isalnum() or char == "-" for char in slug)
```

- `@example(...)` keeps a case that once broke the code as a regression test; `deadline=None` suits
  slow-but-finite work — never raise the deadline to hide a performance regression.
- `st.from_type(T)` derives a strategy from annotations, `st.builds(...)` covers a dataclass, and
  `RuleBasedStateMachine` is for bugs that depend on a *sequence* (a cache, a queue, a ledger).
- "No exception" is a weak property. State the invariant and, where possible, compare against a second,
  independent implementation.

## Mocking

**Patch the name where it is looked up.** `@patch("mypkg.client")` replaces the module object; the code
under test then calls `mypkg.client.urlopen(...)` on a mock and gets a child mock, so configuring the
module mock changes nothing observable. Patch the symbol that is called, in the namespace where it is
looked up. `spec=` / `autospec=True` makes the mock enforce the real signature, and `AsyncMock` is
required for `async def` targets — a `MagicMock` returns a non-awaitable.

```python
# tests/test_client.py — requires Python >= 3.15
from unittest.mock import patch

from mypkg.client import fetch_status


def test_fetch_status_returns_the_status_code() -> None:
    # `urlopen` is looked up in `mypkg.client`'s globals, so that is the name to patch.
    with patch("mypkg.client.urlopen", autospec=True) as urlopen_mock:
        urlopen_mock.return_value.__enter__.return_value.status = 200
        assert fetch_status("https://example.test/health") == 200

    urlopen_mock.assert_called_once_with("https://example.test/health", timeout=5)
```

| Need | Use |
|---|---|
| Replace a function or object | `unittest.mock.patch(..., autospec=True)` |
| Replace an `async def` target | `patch(..., new_callable=AsyncMock)` |
| Replace an env var, an attribute or `sys.path` | the `monkeypatch` fixture |
| Fake an HTTP service | `respx` (httpx) or `responses` (requests) — never patch `urlopen`/`requests.get` |
| A protocol-shaped collaborator (clock, repo, client) | a hand-written fake class; no mocking library needed |

Prefer a fake where the collaborator is our own protocol: it is reusable, has behaviour a test can
reason about, and cannot drift from the interface without a type error. Reserve `patch` for third-party
call sites.

## Async tests

Every async test needs the plugin installed and `asyncio_mode` configured; under `strict`, the marker
too.

```python
# tests/test_async_client.py — requires pytest-asyncio >= 1.4
import pytest

from mypkg.async_client import fetch_all


@pytest.mark.asyncio
async def test_fetch_all_returns_one_result_per_key() -> None:
    results = await fetch_all(["a", "b"])
    assert [result["key"] for result in results] == ["a", "b"]
```

Test the cancellation and timeout paths too: `asyncio.timeout` around a deliberately slow fake, asserting
the timeout surfaces instead of hanging the suite.

## Integration tests

Mark them, keep them out of the default run, and make readiness a condition, never a sleep.

- `@pytest.mark.integration` on every test that needs Postgres, Redis, a broker or a network peer. CI
  runs the fast suite with `-m "not integration"` and a second job with `-m integration` plus the
  service containers, so a red unit job is never blocked by an external service.
- Wait for readiness, do not sleep: `docker compose up --detach --wait` blocks until health checks
  pass, and testcontainers' `wait_for_logs` / `HttpWaitStrategy` does the same for a single container.
- Skip nothing silently: a missing `DOCKER_HOST` in the integration job is a failure, not a skip.

## Running the suite

| Command | Purpose |
|---|---|
| `pytest -x` | Stop at the first failure |
| `pytest -k "name"` | Run tests whose name matches |
| `pytest -m "not slow"` | Deselect by marker |
| `pytest --lf` | Re-run only the tests that failed last time |
| `pytest -n auto` | Parallel across processes (needs `pytest-xdist`) |
| `pytest --durations=10` | The ten slowest tests |

`-n auto` requires independence: no shared mutable state, no ordering assumption, each test creating its
own data. A test that passes only in one order is a defect `-n auto` exposes — as is a suite that passes
in parallel and fails serially, which usually means a module-level cache.

## Coverage

```toml
# pyproject.toml
[tool.coverage.run]
branch = true          # a line covered is not a branch covered
relative_files = true  # paths in CI match paths locally
source = ["src"]
```

```bash
pytest --cov --cov-report=term-missing
```

`--cov` with no value reads `source`; naming a package by hand (`--cov=pkg` under a `src/` layout)
usually reports 0%, because the importable name is the directory under `src/`. `term-missing` lists the
unexecuted lines — the part worth reading.

Do **not** put `--cov-fail-under` in the config: one global number is either meaningless or fights
every refactor. Keep a floor in a file and ratchet it in CI:

```bash
pytest --cov --cov-report=term-missing --cov-fail-under="$(cat .coverage-floor)"
```

Raise the floor when the number rises; never lower it in the same commit that removes tests.

## What a good suite contains

- A test that fails when the implementation is reverted — run it, quote the failure.
- One behaviour per test, named for the behaviour (`test_user_rejects_invalid_email`), not for the
  function (`test_user_2`).
- Failure output that contains the input: parametrized `ids`, or `assert result == expected, payload`.
- Error paths, not only the happy path: exception type, `code`, and the state left behind.
- No shared mutable state, no dependence on another test's side effect or execution order; the same
  results under `-n auto` as serially; injected time, randomness and identifiers.
