# Python Architecture and Errors Reference

**Load this reference when:** laying out a service or library — layer boundaries, dependency direction,
composition, the exception hierarchy, and where each exception is translated.

## Contents

- [Layering](#layering) · [Package boundaries](#package-boundaries) · [SDK and app](#sdk-and-app) · [Composition root](#composition-root)
- [Error contract](#error-contract) · [Result vs exception](#result-vs-exception) · [Boundary mapping](#boundary-mapping) · [Anti-patterns](#anti-patterns)

## Layering

Four layers, dependencies pointing **inward** only. A layer may import the layers below it in this
list and nothing above it; `domain` imports no third-party package at all.

| Layer | Holds | May import | Never imports |
|---|---|---|---|
| `domain/` | Entities, value objects, domain errors, repository **protocols** | stdlib | third-party, `application`, `adapters`, `entrypoints` |
| `application/` | Use cases; transaction and unit-of-work boundaries | `domain`, stdlib | `adapters`, `entrypoints`, web frameworks |
| `adapters/` | Repository **implementations**: HTTP clients, SQL, queues, caches | `domain`, `application`, third-party | `entrypoints` |
| `entrypoints/` | `cli/`, `http/`, `worker/` — parsing, pydantic models, status mapping, wiring | everything | — |

```
src/myapp/
  domain/       errors.py users.py
  application/  create_order.py
  adapters/     users.py
  entrypoints/  cli.py http.py worker.py
  composition.py
```

A protocol in `domain` and its implementation in `adapters` make the arrow legal: the use case depends
on the shape, never on the driver. Freeze the direction with a contract, not a review convention:

```toml
# pyproject.toml — requires import-linter >= 2.15
[dependency-groups]
dev = ["import-linter>=2.15,<3"]

[tool.importlinter]
root_packages = ["myapp"]

[[tool.importlinter.contracts]]
name = "Layered architecture"
type = "layers"
layers = ["myapp.entrypoints", "myapp.adapters", "myapp.application", "myapp.domain"]
```

`layers` lists the top layer first: a module in `myapp.domain` may not import any module above it. Add
a `type = "forbidden"` contract for what `layers` cannot express — `myapp.domain` must not import
`pydantic`, say — and run `lint-imports` in CI beside ruff.

## Package boundaries

- `__init__.py` re-exports public names and declares `__all__`. Nothing else: no object construction,
  no configuration read, no `logging.basicConfig`, no side effects of any kind. Everything outside
  `__all__` is private and free to move in a patch release.
- `py.typed` (an empty file) ships inside every distributed package. Without it a consumer's type
  checker treats the package as untyped and discards every annotation written for them.

```python
# src/myapp/domain/__init__.py
from myapp.domain.errors import AppError, NotFound
from myapp.domain.users import User, UserRepo

__all__ = ["AppError", "NotFound", "User", "UserRepo"]
```

An explicit `__all__` also silences re-export warnings (`reportPrivateImportUsage` in pyright,
`no_implicit_reexport` in mypy) that would otherwise fire on a legitimate public surface.

## SDK and app

A large project is distributed twice: as a **library other people install** and as a **service you
deploy**. One repository, one workspace, two artifacts — the split is a package boundary, not a fork.

| Artifact | Ships | Dependencies | Versioning | Entry points |
|---|---|---|---|---|
| SDK (`packages/sdk`) | `domain/`, `application/`, public client models; `py.typed`; `__all__` | lower bounds only | semver, independent of the app | none: no `main`, no CLI, no server |
| App (`packages/app`) | `adapters/`, `entrypoints/`, composition root | bounds, including `sdk>=x,<y` | tied to each deployment | CLI, ASGI, worker |

- The arrow is one-way: app → SDK. The SDK never imports the app, and the SDK's own tests import only
  the SDK, so a consumer can run them.
- The app reaches the SDK through its public API only. Importing `myapp._internal` from the app is a
  bug in the SDK's surface: export it or move it.
- Global state belongs to the app: logging configuration, env reads, thread pools, connection pools.
  An SDK that calls `logging.basicConfig()` hijacks its host's configuration.
- The SDK declares the protocols and the error hierarchy; the app supplies adapters and maps `code`
  to a status. A consumer can then bring its own HTTP or storage driver.
- The SDK's surface is frozen at each minor: every `__all__` name, signature and error `code`. Removing
  one takes a deprecation cycle — `warnings.warn(DeprecationWarning, stacklevel=2)` for one minor,
  removal at the next major — because the app's `sdk>=x,<y` bound is what lets a consumer pin it.

This is the one place an upper bound on a library dependency is correct: the app pins the SDK's major,
and the SDK itself pins nothing above a lower bound.

## Composition root

Construct every dependency once, in one place, and pass it in. Constructor injection keeps the graph
visible in a signature; module-level singletons, service locators and `import`-time construction make
it invisible and untestable.

```python
# src/myapp/composition.py
from dataclasses import dataclass
from decimal import Decimal

from myapp.adapters.users import InMemoryUserRepo
from myapp.application.create_order import CreateOrder
from myapp.domain.users import UserRepo


@dataclass(frozen=True, slots=True)
class Settings:
    price: Decimal


@dataclass(frozen=True, slots=True, kw_only=True)
class AppDeps:
    """The whole object graph. Frozen: nothing rewires dependencies at runtime."""

    users: UserRepo
    create_order: CreateOrder


def build_deps(settings: Settings) -> AppDeps:
    users: UserRepo = InMemoryUserRepo()
    return AppDeps(users=users, create_order=CreateOrder(users=users, price=settings.price))
```

`main()` (or a framework lifespan hook) calls `build_deps` and hands the result to the entrypoint; a
test calls it with test doubles, so production and test share one code path.

## Error contract

One base class, one subclass per failure mode, one stable machine-readable `code` per subclass. The
caller catches the class; the code crosses the process boundary.

```python
# src/myapp/domain/errors.py
from typing import ClassVar


class AppError(Exception):
    """Base class for every failure this application raises deliberately."""

    code: ClassVar[str] = "internal"


class NotFound(AppError):
    code: ClassVar[str] = "not-found"

    def __init__(self, entity: str, key: str) -> None:
        super().__init__(f"{entity} {key!r} not found")
        self.entity = entity
        self.key = key
```

**Translate once, at the boundary that knows both vocabularies, and always chain the cause.** A
`KeyError`, an `httpx.HTTPError` or an `sqlalchemy.exc.IntegrityError` escaping a use case means the
adapter leaked; a second `raise` that drops the original `__cause__` means the traceback stops there.

```python
# src/myapp/adapters/users.py
from collections.abc import Mapping

from myapp.domain.errors import NotFound
from myapp.domain.users import User, UserRepo


class InMemoryUserRepo(UserRepo):
    """Adapter: turns a missing key into a domain failure, cause preserved."""

    def __init__(self, rows: Mapping[str, User]) -> None:
        self._rows = rows

    def get(self, key: str) -> User:
        try:
            return self._rows[key]
        except KeyError as exc:
            raise NotFound("user", key) from exc  # KeyError stays in __cause__
```

| `code` | HTTP status | Meaning |
|---|---|---|
| `invalid-input` | 400 | Malformed before any business rule applies |
| `unauthorized` | 401 | No credential, or an unusable one |
| `forbidden` | 403 | Authenticated, not permitted |
| `not-found` | 404 | The addressed resource does not exist |
| `conflict` | 409 | Contradicts current state (duplicate, version mismatch) |
| `unprocessable` | 422 | Well-formed, fails a business rule |
| `rate-limited` | 429 | Quota exhausted; retry after the advertised delay |
| `unavailable` | 503 | A dependency is down; the caller may retry |
| `internal` | 500 | A bug or an unmapped failure; never carries detail outward |

The map is one function in `entrypoints/`. The domain never learns a status code.

Concurrent failures aggregate into an `ExceptionGroup` (3.11+); `except*` handles the subgroups and
must not swallow the rest:

```python
# requires-python >= 3.11
import asyncio


async def charge(customer: str) -> None:
    raise ValueError(f"charge failed for {customer}")


async def count_failures(customers: list[str]) -> int:
    """Count failures instead of losing all but the first one."""
    caught = 0
    try:
        async with asyncio.TaskGroup() as group:
            for customer in customers:
                group.create_task(charge(customer))
    except* ValueError as errors:
        caught = len(errors.exceptions)
    return caught
```

## Result vs exception

| Situation | Mechanism | Why |
|---|---|---|
| A business outcome the caller handles ("email already registered") | Return value: `Err` member, or `None` plus a reason enum | It is in the signature; the caller cannot silently ignore it |
| An invariant that must not be violated (a negative quantity reached the domain) | Raise, in the layer that detects it | There is no sensible value to return; continuing is corruption |
| A programming error (`TypeError`, `AttributeError`) | Let it propagate | Catching it hides the bug a test should have caught |
| Loop termination | `break` / `return` | An exception per element costs orders of magnitude more |

Use exceptions for control flow and failures become indistinguishable from bugs: `try` blocks widen to
cover whole loops, and a genuine defect gets logged as "expected". Encode the outcome as
`type Outcome[T] = Ok[T] | Err` (3.12+ alias syntax) with frozen members, so the caller must match to
reach the value and an unhandled failure is a type error rather than a 500 at runtime.

## Boundary mapping

One pydantic model per endpoint validates an untrusted payload; an explicit mapper converts it into a
domain object. The request model dies with the handler; the domain object travels through the use case.

```python run
# src/myapp/entrypoints/http.py — requires pydantic >= 2.14
from dataclasses import dataclass

from pydantic import BaseModel, ConfigDict, Field


@dataclass(frozen=True, slots=True, kw_only=True)
class Order:
    """Domain record: no pydantic, no framework, no I/O."""

    sku: str
    quantity: int
    price_cents: int


class CreateOrderRequest(BaseModel):
    """Boundary record: the only place an untrusted body is trusted."""

    model_config = ConfigDict(extra="forbid")

    sku: str = Field(min_length=1, max_length=64)
    quantity: int = Field(ge=1, le=1_000)
    price_cents: int = Field(gt=0)


def to_order(request: CreateOrderRequest) -> Order:
    """Explicit mapper: the one translation point between the two models."""
    return Order(sku=request.sku, quantity=request.quantity, price_cents=request.price_cents)


body = {"sku": "A-1", "quantity": 2, "price_cents": 999}
assert to_order(CreateOrderRequest.model_validate(body)).quantity == 2
```

`model_validate` raises `pydantic.ValidationError`, which the entrypoint maps to `422` before the use
case is entered. The mapper is a plain function, never a method on the model, so no arrow from
`domain` to `entrypoints` ever appears.

## Anti-patterns

| Anti-pattern | Why it fails | Fix |
|---|---|---|
| `except Exception: pass` | The failure disappears; the caller sees success | Catch the specific class; return `Err` if it is expected |
| `raise X()` inside `except` without `from` | The cause is lost from logs that print only the top exception | `raise X(...) from exc` |
| Message contains a token, password or full payload | Messages reach logs, traces and error trackers | Log a key or an id; hold credentials in `SecretStr` |
| A traceback or `str(exc)` in an HTTP response | Reveals paths, queries, library versions | Fixed body per `code`; detail to the log only |
| `except Exception` inside `domain/` | Turns every bug into a business failure | Let it propagate; catch only at an entrypoint |
| An adapter returns ORM rows to a use case | Couples the domain to lazy loading and session lifetime | Return domain objects |
| `if TYPE_CHECKING: from adapters import X` in `domain/` | The arrow is violated in annotation | Depend on a `Protocol` declared in `domain/` |
