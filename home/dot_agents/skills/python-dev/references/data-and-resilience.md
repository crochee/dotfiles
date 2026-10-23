# Python Data and Resilience Reference

**Load this reference when:** modelling with SQLAlchemy 2.1, defining a unit of work, writing or
reviewing an Alembic migration, sizing a connection pool, or adding retries, timeouts, idempotency or
caching around a dependency. A data layer fails in production, not in review.

## Contents

- [SQLAlchemy 2.1 typed style](#sqlalchemy-21-typed-style) · [Unit of work](#unit-of-work) · [Alembic](#alembic)
- [Pooling](#pooling) · [Resilience](#resilience) · [Caching](#caching) · [Test isolation](#test-isolation)

## SQLAlchemy 2.1 typed style

SQLAlchemy 2.x is typed end to end: a `DeclarativeBase` subclass, `Mapped[T]` annotations and
`mapped_column()`. The annotation is the type; the column carries the DDL. `Mapped[str]` is
non-nullable, `Mapped[str | None]` is nullable — no `nullable=True` needed, and a type checker catches
a `None` that a query can return.

```python
# src/myapp/adapters/db/models.py — requires sqlalchemy >= 2.1
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String, func
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


class UserRow(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    email: Mapped[str] = mapped_column(String(320), unique=True, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class OrderRow(Base):
    __tablename__ = "orders"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
```

- `DateTime(timezone=True)` stores an aware timestamp; the column then round-trips UTC instead of
  silently becoming naive.
- `server_default=func.now()` keeps the clock server-side, so replicas and application hosts cannot
  disagree about "now".
- Never annotate a column with a domain dataclass: rows are the adapter's type. Convert in the
  repository (see [architecture-and-errors.md](architecture-and-errors.md#boundary-mapping)).

## Unit of work

One session per request or per job, never one module-level session: an `AsyncSession` is not
thread-safe and its identity map grows for as long as it lives.

```python
# src/myapp/adapters/db/session.py — requires sqlalchemy >= 2.1
from collections.abc import AsyncIterator

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine


def make_session_factory(dsn: str) -> async_sessionmaker[AsyncSession]:
    engine = create_async_engine(dsn, pool_pre_ping=True)
    # expire_on_commit=False: attribute access after commit must not emit IO;
    # in async code an expired attribute raises MissingGreenlet instead.
    return async_sessionmaker(engine, expire_on_commit=False)


async def unit_of_work(factory: async_sessionmaker[AsyncSession]) -> AsyncIterator[AsyncSession]:
    """Commit on success, roll back on any exception, always close."""
    async with factory() as session, session.begin():
        yield session
```

`async with session.begin():` commits when the block exits normally and rolls back when it raises, so
the use case never calls `commit()` — a use case that commits mid-way cannot be composed. The tradeoff
of `expire_on_commit=False` is staleness: an object read before the commit still holds pre-commit
values, so re-read what you return.

## Alembic

```bash
alembic init -t async migrations      # async template; a sync template against an async engine hangs
alembic revision --autogenerate -m "add orders"
alembic upgrade head
```

- **Autogenerate is a draft.** It misses server defaults, type changes (`compare_type=True`), enum and
  constraint renames, and data migrations. Read every generated file before committing it.
- **Migrations reference `sa.table` / `sa.column`, never the ORM model.** A migration that imports
  `UserRow` breaks the day a column is renamed in the model; the migration must describe the schema at
  its own point in time.

```python
# migrations/versions/0002_backfill_emails.py
import sqlalchemy as sa
from alembic import op

revision = "0002"
down_revision = "0001"


def upgrade() -> None:
    users = sa.table("users", sa.column("id", sa.Integer), sa.column("email", sa.String))
    op.execute(users.update().where(users.c.email.is_(None)).values(email="unknown@example.invalid"))


def downgrade() -> None:
    pass  # data backfills are not reversible; document that instead of pretending
```

- Migrations run as their own deployment step, before the new application version starts, and must be
  forward-compatible with the version still running (add nullable column, backfill, then tighten).
- `render_as_batch=True` is required for SQLite: it cannot `ALTER COLUMN`, so Alembic rebuilds the
  table.

## Pooling

| Setting | Meaning | Default | Set it when |
|---|---|---|---|
| `pool_size` | Persistent connections per process | 5 | The sum across processes must stay under the database's `max_connections` |
| `max_overflow` | Burst connections above `pool_size` | 10 | Bursts are real; remember they count against the server too |
| `pool_pre_ping` | Test a connection before handing it out | `False` | Always, for anything behind a load balancer or a proxy |
| `pool_recycle` | Recycle a connection after N seconds | -1 | Any idle timeout exists (MySQL `wait_timeout`, a proxy's TTL) |
| `pool_timeout` | Seconds to wait for a free connection | 30 | Fail fast when the pool is saturated instead of queueing |

Budget it: `processes × (pool_size + max_overflow)` must fit the server's connection limit. With four
ASGI workers and the defaults that is already 60 connections.

**PgBouncer in transaction mode** breaks server-side prepared statements: a session's statements land
on different backends. Disable the statement cache (`statement_cache_size=0` for `asyncpg`,
`prepare_threshold=None` for `psycopg`) and avoid session-scoped features — advisory locks,
`LISTEN`/`NOTIFY`, temp tables, `SET` without `LOCAL`.

## Resilience

Every call that leaves the process needs a timeout, a bounded retry policy, and a decision about
idempotency. Without all three, one slow dependency becomes an outage of everything that calls it.

```python
import asyncio
import random


class PermanentError(Exception):
    """Retrying cannot help: the server rejected the request itself."""


async def call_once(attempt: int) -> str:
    if attempt < 2:
        raise TimeoutError("upstream slow")
    return "ok"


async def with_retry(attempts: int = 4, base: float = 0.1) -> str:
    """Exponential backoff with full jitter; never retry a 4xx."""
    for attempt in range(attempts):
        try:
            return await asyncio.wait_for(call_once(attempt), timeout=2.0)
        except PermanentError:
            raise
        except (TimeoutError, OSError):
            if attempt == attempts - 1:
                raise
            await asyncio.sleep(random.uniform(0, base * 2**attempt))
    raise AssertionError("unreachable")
```

- **Retry only idempotent operations.** A `POST` that creates a row is not idempotent unless it carries
  an idempotency key the server de-duplicates. Retrying a payment without one is a double charge.
- **Never retry 4xx.** A 400 or 422 reproduces on every attempt; 429 is the exception — honour
  `Retry-After`.
- **Always jitter**, or every client in a fleet retries at the same instant (thundering herd).
- **Cap total attempts and total time**, including the time spent sleeping.
- **Circuit breakers are not a default.** Add one only after observing that fast failure is needed;
  they hide the timeout bug that caused the outage. Timeouts and bounded concurrency usually suffice.
- Log the attempt number, the backoff and the final cause once per operation — not once per attempt.

## Caching

| Cache | Survives | Invalidated by | Use when |
|---|---|---|---|
| `functools.lru_cache` | Process lifetime | Nothing — no TTL, no size by time | Pure functions of hashable arguments, small argument domain |
| `cachetools.TTLCache` | Process lifetime | TTL | Bounded, time-based staleness is acceptable |
| Redis / Memcached | Process restart | Delete on write, or TTL | Shared across replicas |

- `lru_cache` keys keep their arguments alive for as long as the entry lives and never expire: a cache
  keyed on request objects is a memory leak with a hit rate.
- Cache-aside order is write the database, then delete the key. Deleting first lets a reader refill the
  stale value and leave it there for a full TTL.
- Include the schema version in the key (`v2:user:42`), so a deploy invalidates what it should.
- A cache failure must degrade to the source, not to an error: wrap the cache access, log, continue.

## Test isolation

The in-memory SQLite fixture needs `StaticPool` plus `create_all`, and a schema built by Alembic in
production but by `create_all` in tests drifts silently — both points are covered in
[testing.md](testing.md#database-fixture). Use a real Postgres (testcontainers) when the query under
test relies on anything SQLite does not implement: `ON CONFLICT`, `RETURNING`, window functions,
`jsonb`, transactional DDL.
