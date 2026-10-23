# Python Patterns Reference

**Load this reference when:** writing or reviewing Python source — the version floor of a feature,
typing depth, dataclasses, the static/runtime boundary, generators, context managers, decorators or
paths. Every snippet parses as a complete module and imports every name it uses.

## Contents

- [Version gates](#version-gates) · [Typing style](#typing-style) · [Typing depth](#typing-depth)
- [Dataclasses](#dataclasses) · [Static vs runtime](#static-vs-runtime) · [Generators](#generators)
- [Context managers](#context-managers) · [Decorators](#decorators) · [Paths](#paths)
- [Async and logging](#async-and-logging) · [Anti-patterns](#anti-patterns)

## Version gates

Use a feature only when the project's `requires-python` admits it. The column states the floor; the
last column is the decision, not the feature list.

| Feature | Floor | PEP | Use when |
|---|---|---|---|
| `class Repo[T]:` / `type Alias = ...` / `def f[T](x: T)` | 3.12 | [695](https://peps.python.org/pep-0695/) | A generic is needed at all: the pre-3.12 `TypeVar` dance is now noise |
| `@typing.override` | 3.12 | [698](https://peps.python.org/pep-0698/) | Any method that overrides a base: the checker then catches a renamed parent method |
| `itertools.batched(items, n)` | 3.12 | — | Fixed-size chunks; replaces the `range(0, len(x), n)` slice loop |
| `TypeVar` defaults: `class Box[T = int]:` | 3.13 | [696](https://peps.python.org/pep-0696/) | A generic whose argument is usually implied, so callers may omit it |
| `copy.replace(obj, field=v)` | 3.13 | — | A modified copy of a frozen dataclass or named tuple, without re-listing every field |
| Free-threaded build (`python3.13t`) | 3.13, experimental | [703](https://peps.python.org/pep-0703/) | Only after every C extension has a free-threaded wheel; see [async-and-concurrency.md](async-and-concurrency.md#free-threading) |
| Deferred annotations (no `from __future__`) | 3.14 | [649](https://peps.python.org/pep-0649/) | Forward references and cheaper imports; string annotations become unnecessary |
| Template strings: `t"Hi {name}"` | 3.14 | [750](https://peps.python.org/pep-0750/) | A library that must see the template and its values separately (SQL, HTML, i18n) |
| `map(f, a, b, strict=True)` | 3.14 | — | Zipping inputs of assumed equal length; the mismatch then raises instead of truncating |
| `lazy import json` / `lazy from x import y` | 3.15 | [810](https://peps.python.org/pep-0810/) | CLI startup dominated by imports that most invocations never use |
| `frozendict` | 3.15 | [814](https://peps.python.org/pep-0814/) | A hashable, immutable mapping as a default argument or a cache key |
| `sentinel` | 3.15 | [661](https://peps.python.org/pep-0661/) | A distinguishable "not provided" default, replacing a module-level `object()` |
| `TypedDict(closed=True, extra_items=...)` | 3.15 | [728](https://peps.python.org/pep-0728/) | A wire format that must reject unknown keys at the type level |
| UTF-8 as the default encoding | 3.15 | [686](https://peps.python.org/pep-0686/) | Still pass `encoding="utf-8"` explicitly: the file must read correctly on 3.14 too |

## Typing style

One style per project: PEP 604 unions, PEP 585 builtin generics, `collections.abc` for the abstract
collection types. `typing.Optional`, `typing.Union`, `typing.List` and `typing.Callable` are the
pre-3.10 spellings of the same things and must not appear in new code.

```python
# requires-python >= 3.11
from collections.abc import Callable, Iterable, Mapping, Sequence
from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class User:
    id: str
    email: str


def find_user(user_id: str, users: Sequence[User]) -> User | None:
    """Return the user with `user_id`, or None when there is no such user."""
    for user in users:
        if user.id == user_id:
            return user
    return None


def count_by_domain(users: Iterable[User], key: Callable[[User], str]) -> Mapping[str, int]:
    """Count users per email domain, computed through a caller-supplied projection."""
    counts: dict[str, int] = {}
    for user in users:
        domain = key(user).split("@", 1)[-1]
        counts[domain] = counts.get(domain, 0) + 1
    return counts
```

Annotate every public signature including `-> None`; annotate locals only where inference is
ambiguous. A mixed file (one `Optional`, one `X | None`) is a defect: the project has one spelling.

## Typing depth

The constructs below are what a strict checker needs to accept real code without `Any`. Each one has a
condition for use and a cost for misuse.

| Construct | Use when | Cost / rule |
|---|---|---|
| `Protocol` | A consumer needs a shape, not a base class (a repository, a clock, a client) | Structural: an unrelated class with a matching method passes silently. `@runtime_checkable` only adds `isinstance` for method presence, not signatures |
| `TypeVar` | A relationship between parameter and return types (`def first(xs: list[T]) -> T`) | Bound it (`T: str | bytes`) or the body can only call `object` methods |
| `ParamSpec` | A decorator that must preserve the wrapped signature | Requires the wrapper to be annotated `P.args` / `P.kwargs`; a plain `Callable[..., T]` erases the signature |
| `@overload` | The return type depends on the argument type or value | Two or more stubs plus one implementation whose parameters are the union; the implementation is not checked against the stubs |
| `TypedDict` + `Required`/`NotRequired` | A JSON-shaped dict with known keys | Only the keys are typed at runtime; values still need validation at the boundary |
| `Literal["a", "b"]` | A closed set of string values | Exhaustiveness is checked only inside `match`/`if` chains that the checker can see |
| `Self` | A method returning the same type as the receiver (fluent builders, `from_dict`) | Not a substitute for a protocol: subclasses must be constructible the same way |
| `Final` | A module-level constant or a field that must not be reassigned | Reassignment is a *checker* error, not a runtime one; do not rely on it for safety |
| `cast(T, v)` | Only after a runtime check that the checker cannot see | Never a fix for a real mismatch: it silences the check and moves the failure to production |
| `if TYPE_CHECKING:` + string annotations | Breaking an import cycle for annotations only | The imported name does not exist at runtime: never use it in `isinstance`, a decorator or a default |

```python
# requires-python >= 3.12
from collections.abc import Callable
from typing import ParamSpec, Protocol, override


class Clock(Protocol):
    """A shape, not a base class: any object with `now()` satisfies it."""

    def now(self) -> float: ...


P = ParamSpec("P")


def logged(func: Callable[P, float]) -> Callable[P, float]:
    """ParamSpec keeps the decorated signature intact."""

    def wrapper(*args: P.args, **kwargs: P.kwargs) -> float:
        return func(*args, **kwargs)

    return wrapper


class Repo[T]:
    """PEP 695 generic: the 3.12 syntax, no TypeVar declaration above."""

    def __init__(self, items: list[T]) -> None:
        self._items = list(items)

    def first(self) -> T | None:
        return self._items[0] if self._items else None


class ListRepo[T](Repo[T]):
    @override
    def first(self) -> T | None:
        """`@override` makes a renamed base method a type error."""
        return super().first()
```

## Dataclasses

A dataclass is the default container for internal records. Three flags matter, and one interacts:

| Flag | Effect | Cost |
|---|---|---|
| `frozen=True` | The instance cannot be mutated after construction | With `eq=True` (default) it also gets `__hash__`; the non-frozen default is unhashable |
| `slots=True` | No per-instance `__dict__` | Breaks `functools.cached_property` and any attribute not declared on the class |
| `kw_only=True` | Fields only by keyword | No positional construction; removes a class of argument-order bugs |

```python run
# requires-python >= 3.11
from dataclasses import dataclass, field
from datetime import UTC, datetime


@dataclass(frozen=True, slots=True, kw_only=True)
class Account:
    id: str
    email: str
    created_at: datetime = field(default_factory=lambda: datetime.now(UTC))
    tags: tuple[str, ...] = ()

    def __post_init__(self) -> None:
        if "@" not in self.email:
            raise ValueError(f"invalid email: {self.email!r}")


if __name__ == "__main__":
    account = Account(id="u1", email="a@b.test")
    assert account.created_at.tzinfo is not None
```

`default_factory` (not `default=`) is required for any call-time or mutable value: `default=now()`
freezes one timestamp at class-definition time. `datetime.now(UTC)` is the 3.11+ form; on 3.10 and
earlier it is `datetime.now(timezone.utc)`, and the project's floor decides which spelling appears.
`slots=True` plus `functools.cached_property` raises `TypeError` at decoration time — pick one.

## Static vs runtime

Annotations are erased at runtime, so they validate nothing. Values from outside the process are
validated once at the edge, converted to a frozen dataclass, and typed statically inside.

```python run
# requires-python >= 3.11, pydantic >= 2.14
from pydantic import BaseModel, ConfigDict, Field


class CreateUserRequest(BaseModel):
    """The only place an untrusted payload is trusted."""

    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)

    email: str = Field(pattern=r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
    display_name: str = Field(min_length=1, max_length=120)


if __name__ == "__main__":
    body = {"email": "a@b.test", "display_name": "Ada"}
    assert CreateUserRequest.model_validate(body).display_name == "Ada"
```

`extra="forbid"` turns a client typo into a 422 instead of a silently dropped field. Where the model
becomes a domain object is a layering question: see
[architecture-and-errors.md](architecture-and-errors.md#boundary-mapping).

## Generators

A generator is lazy: it holds one item, and laziness only pays when the consumer pulls one at a time.

```python run
# requires-python >= 3.11
import tempfile
from collections.abc import Iterator
from itertools import islice
from pathlib import Path


def read_lines(path: Path) -> Iterator[str]:
    """Stream a file without loading it: constant memory for any size."""
    with path.open(encoding="utf-8") as handle:
        for line in handle:
            yield line.rstrip("\n")


def take(path: Path, limit: int) -> list[str]:
    """`islice` stops the generator early; the rest of the file is never read."""
    return list(islice(read_lines(path), limit))


if __name__ == "__main__":
    with tempfile.TemporaryDirectory() as folder:
        sample = Path(folder) / "lines.txt"
        sample.write_text("a\nb\nc\n", encoding="utf-8")
        assert take(sample, 2) == ["a", "b"]
```

`sum(x * x for x in range(10**6))` allocates nothing, but it consumes the generator completely — it is
not the lazy pattern it looks like.

## Context managers

Setup before `yield`, teardown after it, and a `try/finally` so teardown survives an exception in the
body. `contextlib.contextmanager` turns a generator into one.

```python
# requires-python >= 3.11
import time
from collections.abc import Iterator
from contextlib import contextmanager


@contextmanager
def timed(label: str) -> Iterator[None]:
    """Report elapsed time even when the block raises."""
    start = time.perf_counter()
    try:
        yield
    finally:
        print(f"{label} took {time.perf_counter() - start:.4f}s")
```

For a class-based manager, `__exit__` returning `True` swallows the exception — return `False` unless
suppression is the documented contract.

## Decorators

`functools.wraps` copies `__name__`, `__doc__` and `__wrapped__`, so the decorated function still
describes itself to `help()`, loggers and tracebacks. A decorator that changes the signature needs
`ParamSpec` (see [Typing depth](#typing-depth)).

```python
# requires-python >= 3.12 — `def f[**P, R]` is PEP 695 syntax
import functools
import time
from collections.abc import Callable


def timed[**P, R](func: Callable[P, R]) -> Callable[P, R]:
    """Measure one call; the 3.12 syntax preserves the signature exactly."""

    @functools.wraps(func)
    def wrapper(*args: P.args, **kwargs: P.kwargs) -> R:
        start = time.perf_counter()
        try:
            return func(*args, **kwargs)
        finally:
            print(f"{func.__name__} took {time.perf_counter() - start:.4f}s")

    return wrapper
```

## Paths

Use `pathlib`, not string concatenation: `Path` composes with `/` and carries the filesystem
operations. Always pass `encoding=`: the default is the platform's locale encoding, which differs
between a laptop and a container.

```python run
# requires-python >= 3.11
import tempfile
from pathlib import Path

with tempfile.TemporaryDirectory() as tmp:
    config = Path(tmp) / "app" / "settings.toml"
    config.parent.mkdir(parents=True, exist_ok=True)
    config.write_text("[app]\nname = 'demo'\n", encoding="utf-8")
    assert config.read_text(encoding="utf-8").startswith("[app]")
```

## Async and logging

Concurrency model, cancellation and shutdown: [async-and-concurrency.md](async-and-concurrency.md).
Handler configuration, JSON formatting and correlation ids: [tooling.md](tooling.md#logging). Library
code logs through `logging.getLogger(__name__)` and configures nothing.

## Anti-patterns

Anything a linter catches is not a review finding — `B006` (mutable default), `E711` (`== None`),
`F403` (star import), `E722` (bare `except`), `DTZ` (naive datetime), `T20` (`print`). Run ruff. What
remains is semantic, and a reviewer must see it:

| Anti-pattern | Why it fails | Fix |
|---|---|---|
| `except Exception` that neither translates nor re-raises | Every bug becomes a business failure; the traceback is gone | Catch the specific class; translate at the boundary with `from exc` |
| `.result()` after `asyncio.TaskGroup` | The group already awaited the tasks; the call re-raises or blocks pointlessly | Collect inside the worker |
| Blocking call inside `async def` | Stalls every coroutine on the loop | `await asyncio.to_thread(...)` |
| Import-time work (env read, connection, thread, `logging.basicConfig`) | Import order becomes behaviour; tests cannot isolate it | Move to `main()` / the composition root |
| Unvalidated boundary value typed as if validated | `dict[str, Any]` flows in and every downstream annotation is a lie | One runtime validation at the edge, then a typed object |
| `field(default=datetime.now(UTC))` | Evaluated once, at class-definition time | `default_factory=lambda: ...` |
| Upper bound on a published library's dependency | Forces your consumer's resolver to downgrade; breaks co-installation | Lower bound only; the app pins |
| `cast()` over a real mismatch | Silences the checker, moves the failure to production | Fix the type or validate at the boundary |
