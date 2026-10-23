# Python Async and Concurrency Reference

**Load this reference when:** choosing a concurrency model, writing `async def`, fanning out I/O,
setting timeouts, handling cancellation or shutdown, or moving work off the event loop. The decision
costs one paragraph now and a rewrite later.

## Contents

- [Decision table](#decision-table) · [TaskGroup vs gather](#taskgroup-vs-gather) · [Timeouts and cancellation](#timeouts-and-cancellation)
- [Backpressure](#backpressure) · [Entry points](#entry-points) · [Threads and processes](#threads-and-processes) · [Free-threading](#free-threading)

## Decision table

| Workload | Primitive | Why |
|---|---|---|
| Many concurrent network or database calls | `asyncio` + `TaskGroup` | One thread, thousands of in-flight waits |
| A blocking library inside `async def` | `await asyncio.to_thread(...)` | The call has no async API; the loop must stay free |
| Pure-Python CPU work | `ProcessPoolExecutor` | The GIL serialises threads; processes do not share it |
| CPU work in a C extension that releases the GIL | `ThreadPoolExecutor` | numpy, `hashlib`, `zlib` already release it |
| Fan-out from synchronous code | `concurrent.futures.ThreadPoolExecutor` | No event loop to run, no `async` to leak |
| A few sequential steps, no concurrency | plain functions | Concurrency adds cancellation and ordering bugs for nothing |

Write synchronous code until a profile or a wait shows the need. `async def` everywhere costs
cancellation safety at every call site, and buys nothing when there is no concurrent wait.

## TaskGroup vs gather

| | `asyncio.TaskGroup` (3.11+) | `asyncio.gather` |
|---|---|---|
| On first failure | Cancels the remaining tasks, then raises `ExceptionGroup` | Raises the first exception; **siblings keep running** |
| Error shape | `ExceptionGroup` — handle with `except*`, one branch per type | The exception itself, or a list with `return_exceptions=True` |
| Result order | Completion order; collect into a keyed structure | Input order |
| Multiple failures | All of them, nested in the group | Only the first |
| Use when | A unit of work must either finish whole or stop | Order matters, or you are on 3.10 and earlier |

A leaked sibling task after a failed `gather` is the classic production bug: the request returns 500
while the uncancelled tasks keep writing to the database.

```python run
import asyncio


async def fetch(key: str) -> str:
    await asyncio.sleep(0)
    return key.upper()


async def fetch_all(keys: list[str]) -> dict[str, str]:
    """Keyed results: completion order does not matter."""
    results: dict[str, str] = {}

    async def worker(key: str) -> None:
        results[key] = await fetch(key)

    async with asyncio.TaskGroup() as group:
        for key in keys:
            group.create_task(worker(key))
    return results


if __name__ == "__main__":
    assert asyncio.run(fetch_all(["a", "b"])) == {"a": "A", "b": "B"}
```

```python
import asyncio


async def fetch(key: str) -> str:
    await asyncio.sleep(0)
    return key.upper()


async def fetch_in_order(keys: list[str]) -> list[str]:
    """`gather` preserves input order; a failure does not cancel the siblings."""
    return list(await asyncio.gather(*(fetch(key) for key in keys)))
```

`except*` on a `TaskGroup` sees one subgroup per exception type, not one per task; when a group mixes
`ValueError` and `TimeoutError`, both branches run.

## Timeouts and cancellation

Every `await` is a cancellation point. `asyncio.timeout()` (3.11+) is the modern form: on expiry it
cancels the enclosed work and raises `TimeoutError`, and the `async with` block exits cleanly.

```python
import asyncio


async def fetch(key: str) -> str:
    await asyncio.sleep(0)
    return key


async def fetch_with_deadline(key: str) -> str | None:
    try:
        async with asyncio.timeout(2.0):
            return await fetch(key)
    except TimeoutError:
        return None
```

Rules that keep cancellation correct:

- Never catch `CancelledError` to "finish up" — cleanup belongs in `finally`, which runs on
  cancellation too. A swallowed `CancelledError` turns a cancelled task into a hung one.
- Do not `await` inside `finally` without a fresh timeout; the task may already be cancelled and the
  cleanup will hang.
- `asyncio.wait_for` predates `asyncio.timeout()`; use `timeout()` for new code and keep `wait_for`
  only where a project already standardised on it.
- Prefer a timeout on every external call over one global timeout: a single outer deadline turns an
  unrelated slow dependency into a total failure with no useful log line.

## Backpressure

An unbounded `asyncio.create_task` loop or an unbounded queue converts a slow consumer into OOM.
Bound both: `asyncio.Queue(maxsize=...)` blocks producers, `Semaphore` caps in-flight calls.

```python
import asyncio


async def call(i: int) -> int:
    await asyncio.sleep(0)
    return i


async def bounded(items: list[int], limit: int = 4) -> list[int]:
    """At most `limit` calls in flight, whatever the input size."""
    gate = asyncio.Semaphore(limit)
    results: list[int] = []

    async def guarded(item: int) -> None:
        async with gate:
            results.append(await call(item))

    async with asyncio.TaskGroup() as group:
        for item in items:
            group.create_task(guarded(item))
    return results
```

`Semaphore` bounds concurrency, not memory: the results list still grows with input, so cap the batch
size or stream into the consumer.

## Entry points

`asyncio.run(main())` creates a loop, runs one coroutine and closes the loop. Call it once, at the
bottom of an entry point; never inside a library, and never twice in one test (use
`asyncio.Runner` when a loop must be reused).

```python
import asyncio
import signal


async def serve(stop: asyncio.Event) -> None:
    """Stand-in for a server loop that exits when the event is set."""
    await stop.wait()


async def main() -> None:
    stop = asyncio.Event()
    loop = asyncio.get_running_loop()
    for sig in (signal.SIGINT, signal.SIGTERM):
        loop.add_signal_handler(sig, stop.set)
    async with asyncio.TaskGroup() as group:
        group.create_task(serve(stop))


if __name__ == "__main__":
    asyncio.run(main())
```

Signal handlers are only registrable on the main thread of the main interpreter; in a worker thread
install them in the sync wrapper and set the event through `loop.call_soon_threadsafe`. On shutdown,
stop accepting new work first, then let in-flight tasks finish under a deadline — a `SIGKILL` after
the deadline is the orchestrator's job, not yours.

## Threads and processes

```python
import asyncio
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path


def size_of(path: str) -> int:
    """Blocking call: the filesystem has no async API."""
    return Path(path).stat().st_size


async def sizes(paths: list[str]) -> list[int]:
    """Threads keep input order and do not block the loop."""
    return list(await asyncio.gather(*(asyncio.to_thread(size_of, p) for p in paths)))


def total_digits(count: int) -> int:
    """CPU-bound: one process per call, chunked by the executor."""
    return sum(len(str(n)) for n in range(count))


def process_total(counts: list[int]) -> list[int]:
    with ProcessPoolExecutor() as pool:
        return list(pool.map(total_digits, counts, chunksize=8))
```

- `asyncio.to_thread` is not interruptible: cancelling the `await` abandons the thread, which keeps
  running to completion. Bound the pool and the timeout, and make the blocking function itself
  cancellable (a socket timeout, not a loop).
- `contextvars` propagate into `to_thread` and into tasks, not into `ProcessPoolExecutor` jobs:
  re-send correlation data as an argument.
- Default sizes: `ThreadPoolExecutor` uses `min(32, cpu_count + 4)`; `ProcessPoolExecutor`
  defaults to the CPU count. Both are ceilings, not targets — size from measurement.
- Every pool argument must be picklable for processes: no closures, no open handles, no `lambda`.

## Free-threading

A free-threaded build (PEP 703) runs without the GIL, so threads execute Python bytecode in parallel.

- 3.13 introduced it as an experimental build (`python3.13t`); 3.14 finished the PEP 703 work; 3.15
  adds a stable ABI for free-threaded builds (PEP 803) and ships macOS binaries with free-threading
  support by default.
- The status is version-dependent and still moving. Check `sys._is_gil_enabled()` at runtime rather
  than assuming, and confirm every C extension in the dependency set has a free-threaded wheel.
- Existing code is not automatically thread-safe: `x += 1` on shared state is still a race, and
  `dict`/`list` operations being individually atomic does not make a read-modify-write atomic.
- Decide with a measurement: ThreadPool versus ProcessPool on the real workload, including
  serialisation cost. For pure-Python CPU work that ships data between processes, free-threading
  often wins; for C extensions without a free-threaded wheel, it is not an option at all.
