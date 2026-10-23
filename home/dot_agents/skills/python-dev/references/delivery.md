# Python Delivery Reference

**Load this reference when:** writing `pyproject.toml`, setting up a uv workspace that ships an SDK and an
app, deciding what the lockfile carries, building or publishing, CI, containers, servers or supply chain.
Delivery is the part a reviewer cannot fix in review.

## Contents

- [pyproject.toml](#pyprojecttoml) · [uv workflow](#uv-workflow) · [uv workspaces](#uv-workspaces) · [Lock policy](#lock-policy)
- [Build and release](#build-and-release) · [CI](#ci) · [Container](#container) · [Servers](#servers)
- [Supply chain](#supply-chain) · [Config and secrets](#config-and-secrets) · [Production checklist](#production-checklist)

## pyproject.toml

```toml
# pyproject.toml — requires hatchling >= 1.33
[build-system]
requires = ["hatchling>=1.33,<2"]
build-backend = "hatchling.build"

[project]
name = "REPLACE-ME-PKG"
version = "0.1.0"
description = "REPLACE-ME-DESC"
readme = "README.md"
requires-python = ">=3.15"
license = "MIT"                      # PEP 639 SPDX expression, not a {text = ...} table
license-files = ["LICENSE"]
dependencies = ["pydantic>=2.14,<3"]

[project.scripts]
REPLACE-ME-PKG = "REPLACE-ME-PKG.cli:main"

[dependency-groups]                  # PEP 735: development-only, never installed by a consumer
dev = [
    "pytest>=9.2,<10",
    "pytest-asyncio>=1.4,<2",
    "pytest-cov>=7.1,<8",
    "hypothesis>=6.170,<7",
    "ruff>=0.17,<1",
    "pyright>=1.1.414,<2",
]

[tool.hatch.build.targets.wheel]
packages = ["src/REPLACE-ME-PKG"]
```

- `license` is an SPDX string with `license-files` alongside it (PEP 639). The old
  `license = {text = "MIT"}` table is deprecated and rejected by newer backends.
- `[project.scripts]` is the only supported way to ship a command: an entry point installs a console
  script, a `__main__.py` only supports `python -m`.
- `src/<pkg>/py.typed` (empty) must be inside the package; hatchling then includes it in the wheel.
- `[project.optional-dependencies]` are published extras (`pip install pkg[redis]`); `[dependency-groups]`
  are never visible to a consumer.

## uv workflow

```bash
uv init --package mypkg        # pyproject.toml + src/mypkg/ + a console script
uv add "httpx>=0.28,<1"        # runtime dependency: pyproject.toml + uv.lock
uv add --dev "pytest>=9.2,<10" # the dev group
uv lock                        # re-resolve uv.lock from pyproject.toml
uv sync --locked               # install exactly the lock, failing if it is stale
uv run pytest -q               # run inside the project environment
uv build                       # dist/*.whl and dist/*.tar.gz
```

| Flag | Resolves | Fails when the lock is stale | Use for |
|---|---|---|---|
| `uv sync` | Yes, updates `uv.lock` | No | Local development |
| `uv sync --locked` | No | **Yes** | CI: a forgotten `uv lock` is an error, not a silent drift |
| `uv sync --frozen` | No | No | Containers: install the shipped lock, whatever the manifest says |

`uv pip install --system` is a different model — it writes into the active interpreter's
`site-packages` — and belongs only in a system-wide tool image. A project is installed with `uv sync`
into its own `.venv`.

## uv workspaces

One repository ships two artifacts (see [architecture-and-errors.md](architecture-and-errors.md#sdk-and-app)):
the SDK others install, and the app you deploy. A uv workspace gives them one lockfile, one resolution,
and independent wheels.

```toml
# pyproject.toml — the workspace root; it is not a package
[tool.uv.workspace]
members = ["packages/sdk", "packages/app"]

[tool.uv]
package = false          # the root has no build backend: it only holds the lock and dev tools
```

```toml
# packages/app/pyproject.toml
[project]
name = "myapp"
requires-python = ">=3.15"
dependencies = ["mysdk>=0.3,<1"]     # the one legitimate upper bound: pin the SDK's major
```

```toml
# packages/sdk/pyproject.toml — the published library
[project]
name = "mysdk"
requires-python = ">=3.15"
dependencies = ["pydantic>=2.14"]    # lower bound only
```

```bash
uv sync --locked --package myapp       # one member's environment
uv run --package mysdk pytest -q       # run inside that member
uv build --package mysdk               # one wheel; --all-packages builds every member
uv publish --package mysdk dist/*      # publish the SDK only
```

Only the SDK is published; the app ships as an image. `uv build` without `--package` in a workspace
builds the root, which here has no package — the flag is not optional.

## Lock policy

- **Commit `uv.lock` in both cases.** It makes CI reproducible and makes a dependency change reviewable
  as a diff. A library still commits it: the lock is for *its* CI, never for its consumers.
- **The published metadata comes only from `pyproject.toml`.** A wheel's `Requires-Dist` is generated
  from `dependencies`; the lockfile is not consulted by a consumer's resolver.
- **Library dependencies carry lower bounds only** (`pydantic>=2.14`). An upper bound in a published
  library forces every consumer to satisfy it, and one strict transitive pin can block a whole
  ecosystem upgrade.
- **Application dependencies carry bounds** (`httpx>=0.28,<1`) plus the lock, because the app is the one
  that must stay installable tomorrow. An internal dependency (`mysdk>=0.3,<1`) is the exception: the app
  pins the SDK's major, which is how a breaking SDK release stays out of production until the app is ready.

## Build and release

```bash
uv build                                        # sdist + wheel into dist/
uvx twine check dist/*                          # metadata renders and validates
uv run python -c "import zipfile,glob; print(zipfile.ZipFile(glob.glob('dist/*.whl')[0]).namelist())"
uv publish --trusted-publishing always          # OIDC from CI; no token in the repo
```

`py.typed` must appear in that `namelist()`; without it the package is untyped for every consumer.
`twine check` is the cheapest way to catch a README that breaks the PyPI render. Trusted publishing
exchanges the CI job's OIDC identity for a short-lived upload token, so no long-lived secret exists to
leak; `--trusted-publishing always` fails rather than silently falling back to a token.

Tag releases (`mysdk-v0.3.0`) and derive the version from one place — either a literal in
`pyproject.toml` bumped by the release commit, or `hatch-vcs` from the tag. Two sources of truth
disagree eventually.

## CI

```yaml
# .github/workflows/ci.yml
name: ci
on:
  push: { branches: [main] }
  pull_request:

permissions:
  contents: read

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: astral-sh/setup-uv@v10.3.3
        with: { enable-cache: true, cache-dependency-glob: uv.lock }
      - run: uv sync --locked --all-packages
      - run: uv run ruff check .
      - run: uv run ruff format --check .
  type:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: astral-sh/setup-uv@v10.3.3
        with: { enable-cache: true, cache-dependency-glob: uv.lock }
      - run: uv sync --locked --all-packages
      - run: uv run pyright
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix: { python: ["3.15"] }      # a published library adds the oldest supported minor
    steps:
      - uses: actions/checkout@v7
      - uses: astral-sh/setup-uv@v10.3.3
        with: { enable-cache: true, cache-dependency-glob: uv.lock }
      - run: uv sync --locked --all-packages
      - run: uv run pytest -q -m "not integration" --cov --cov-report=term-missing
      - run: uv build --all-packages
```

- `setup-uv` is pinned to a release tag: the repository publishes no moving major tag past `v7`, so a
  floating `@v10` does not exist. Bump the pin deliberately. Three jobs run in parallel, each starting
  from `uv sync --locked`, so a lint failure never hides a test failure.
- Add a second job for integration tests with service containers — see
  [testing.md](testing.md#integration-tests).

## Container

```dockerfile
# syntax=docker/dockerfile:1
FROM python:3.15-slim AS builder
COPY --from=ghcr.io/astral-sh/uv:0.13.6 /uv /uvx /bin/

ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy UV_PYTHON_DOWNLOADS=never
WORKDIR /app

COPY pyproject.toml uv.lock ./
COPY packages/sdk/pyproject.toml packages/sdk/
COPY packages/app/pyproject.toml packages/app/
RUN --mount=type=cache,target=/root/.cache/uv uv sync --frozen --no-dev --no-install-workspace

COPY packages/ packages/
COPY README.md LICENSE ./
RUN --mount=type=cache,target=/root/.cache/uv uv sync --frozen --no-dev --no-editable

FROM python:3.15-slim AS runtime
ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1 PATH="/app/.venv/bin:$PATH"
WORKDIR /app
RUN useradd --create-home --uid 10001 appuser
COPY --from=builder --chown=appuser:appuser /app/.venv /app/.venv
USER appuser
CMD ["myapp"]
```

Why each line:

- `COPY --from=ghcr.io/astral-sh/uv:0.13.6` pins uv exactly and keeps it out of the runtime image. Manifest
  copies come before source, so the dependency layer is cached until a `pyproject.toml` or `uv.lock`
  changes; `--no-install-workspace` installs dependencies but no member, so the source is not needed yet.
- `--no-editable` installs the app into the venv as a snapshot, so the runtime stage needs no source tree
  and no build backend. `WORKDIR /app` is set in both stages because console scripts in `.venv/bin` carry
  the absolute path `/app/.venv/bin/python`.
- The base image minor equals `requires-python`'s minor and no tag is ever `latest`; the non-root user is
  created in the runtime stage only, since a builder-stage user does not exist here.
- `PYTHONUNBUFFERED=1` keeps container logs immediate; `PYTHONDONTWRITEBYTECODE=1` avoids writing
  `__pycache__` into a read-only layer.

## Servers

| Server | Protocol | Use for | Note |
|---|---|---|---|
| Gunicorn | WSGI | Django, Flask | No ASGI worker: FastAPI needs `-k uvicorn.workers.UvicornWorker`; unsupported on Windows |
| Uvicorn | ASGI | FastAPI, Starlette | `--workers` needs `uvicorn[standard]` |
| Hypercorn | ASGI + WSGI | Quart | One server for both protocols |
| Granian | ASGI / WSGI / RSGI | mixed workloads | Rust core |

Sizing: blocking WSGI starts at `2 × CPU + 1` workers; an ASGI app waiting on I/O usually needs one worker
per CPU, since each multiplexes many connections — `--workers` is a process count, not a concurrency
limit. Always set `--timeout` and `--graceful-timeout` so a deploy drains in-flight requests.

## Supply chain

```bash
uv export --no-dev --no-emit-project --format requirements-txt > requirements.txt
uvx pip-audit --strict -r requirements.txt
ruff check --select S .
```

`--no-emit-project` keeps the local project out of the export, which `pip-audit` cannot resolve; `--strict`
fails the job on a resolution error. `ruff --select S` (flake8-bandit) covers the common sinks without a
second tool. Review the `uv.lock` diff in every dependency PR: a transitive package with no reason is the
signal.

## Config and secrets

```python
# src/myapp/settings.py — requires pydantic-settings >= 2.16
from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_nested_delimiter="__", env_file=".env", extra="forbid")

    database_url: SecretStr
    request_timeout_s: float = 2.0
```

- Read settings once, in the composition root; every other module receives values.
  `env_nested_delimiter="__"` maps `DB__HOST` onto `settings.db.host` without inventing a naming scheme.
- `SecretStr` keeps the value out of `repr()`, tracebacks and logs; call `.get_secret_value()` only at
  the point of use.
- Secrets never enter the image, the repository or a `uv.lock`. The container receives them from the
  orchestrator's secret store; `.env` is for local runs and is git-ignored.

## Production checklist

- [ ] `uv sync --locked` exits 0 in a clean checkout.
- [ ] `ruff check .` and `ruff format --check .` exit 0.
- [ ] `pyright` exits 0 with `typeCheckingMode = "strict"`.
- [ ] `pytest -q -m "not integration"` exits 0 and the coverage floor did not drop.
- [ ] `uv build --all-packages` produces the wheels, and `py.typed` is inside the SDK wheel.
- [ ] `pip-audit --strict` exits 0 against the exported requirements.
- [ ] `docker build` succeeds; `docker run --rm <image> id -u` is not 0.
- [ ] The image tag is not `latest`, and its minor matches `requires-python`.
- [ ] `alembic upgrade head` runs against a scratch database and `alembic check` reports no pending
      revision.
- [ ] `python -X importtime -c "import myapp"` shows no I/O and no configured logging at import.
