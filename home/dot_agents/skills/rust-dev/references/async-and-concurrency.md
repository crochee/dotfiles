**Load this reference when:** writing or reviewing async Rust, choosing a runtime, sharing state between tasks, or diagnosing a task that blocks the executor.

## Contents

- [Sync first: when async earns its cost](#sync-first-when-async-earns-its-cost)
- [Runtime and feature selection](#runtime-and-feature-selection)
- [Send and Sync across .await](#send-and-sync-across-await)
- [Structured concurrency with JoinSet](#structured-concurrency-with-joinset)
- [Cancellation: a token, not a flag](#cancellation-a-token-not-a-flag)
- [select! and cancellation safety](#select-and-cancellation-safety)
- [Never block the executor](#never-block-the-executor)
- [Channels and back-pressure](#channels-and-back-pressure)
- [Mutex in async code](#mutex-in-async-code)
- [async fn in traits](#async-fn-in-traits)

## Sync first: when async earns its cost

Async is a cost: a state machine instead of a stack frame, a runtime to own, and a `.await` at every suspension point. Pay it only when the workload is genuinely I/O-bound **and** the concurrency is real. `[ASYNC]`

| Situation | Use |
|---|---|
| One request, one response, no waiting on anything else | Synchronous code |
| Many connections, each waiting on a socket | Async |
| CPU-heavy work | A thread pool — `std::thread::scope` for a scoped fan-out |
| A blocking call inside an async task | `tokio::task::spawn_blocking` |

Without concurrent I/O to overlap, synchronous code is simpler and usually faster. `[ASYNC]`

## Runtime and feature selection

Tokio is the default for network services; the runtime choice is a dependency-level decision, made once. `[TOKIO]`

| Feature | Required for |
|---|---|
| `rt` | `tokio::spawn`, the runtime itself |
| `rt-multi-thread` | `#[tokio::main(flavor = "multi_thread")]`, the multi-thread scheduler |
| `macros` | `#[tokio::main]`, `#[tokio::test]`, `select!` |
| `sync` | `tokio::sync::mpsc`, `tokio::sync::Mutex`, `tokio::sync::broadcast` |
| `time` | `tokio::time::timeout`, `tokio::time::sleep` |
| `net` | `tokio::net::TcpListener`, `tokio::net::TcpStream` |

Enable only what the crate uses; one dependency entry lists them all:

```toml
[dependencies]
tokio = { version = "1", features = ["rt", "rt-multi-thread", "macros", "sync", "time", "net"] }
```

Declaring `tokio = "1"` with no features compiles until the first gated API, then fails to resolve that path.

## Send and Sync across .await

`tokio::spawn` requires the future to be `Send`: it may move between worker threads at every await point. A future is `Send` only if every value held across an await is `Send`. `[TOKIO]`

| Type | `Send` | `Sync` | Consequence |
|---|---|---|---|
| `Rc<T>` | no | no | Cannot cross a task boundary at all |
| `Arc<T>` | yes if `T: Send + Sync` | yes if `T: Send + Sync` | The default for cross-task sharing |
| `std::sync::MutexGuard<T>` | no | no | **Cannot be held across `.await`** — the future stops being `Send` |
| `tokio::sync::MutexGuard<T>` | yes if `T: Send` | yes if `T: Send + Sync` | Safe to hold across `.await` |

## Structured concurrency with JoinSet

`JoinSet` is a task set with structured scope: it owns its tasks, so dropping it aborts every task it still holds. `tokio::spawn` hands a task to the runtime and gives up the handle — a detached task that keeps running after the function that started it has returned. `[TOKIO]`

```rust
use tokio::task::JoinSet;

async fn fetch_one(url: &str) -> Result<String, String> { Ok(url.to_string()) }

/// Fetch every URL concurrently, stopping every task at the first failure.
pub async fn fetch_all(urls: Vec<String>) -> Result<Vec<String>, String> {
    let mut set = JoinSet::new();
    for url in urls {
        set.spawn(async move { fetch_one(&url).await });
    }
    let mut bodies = Vec::new();
    while let Some(joined) = set.join_next().await {
        match joined {
            Ok(Ok(body)) => bodies.push(body),
            Ok(Err(err)) => { set.shutdown().await; return Err(err); }
            Err(join_err) => { set.shutdown().await; return Err(join_err.to_string()); }
        }
    }
    Ok(bodies)
}
```

`set.abort_all()` only *requests* the aborts; it does not wait for them. `set.shutdown().await` aborts and then waits, so on return every task has really stopped. `[TOKIO]`

## Cancellation: a token, not a flag

Rust has no `context.Context`, so a shutdown signal has to be passed explicitly. The idiomatic carrier is `tokio_util::sync::CancellationToken`: a cloneable handle whose `cancel()` method wakes every task watching it, and whose `cancelled()` future resolves when it fires. A `bool` flag cannot do this — a task blocked on a socket cannot poll a flag to discover it was set. [tokio-util](https://docs.rs/tokio-util/latest/tokio_util/)

```rust
use std::future::Future;
use tokio_util::sync::CancellationToken;

/// Run `worker` until `token` is cancelled.
pub async fn supervise(token: CancellationToken, worker: impl Future<Output = ()> + Send) {
    tokio::select! {
        _ = worker => {}
        _ = token.cancelled() => {}
    }
}
```

The token is the *only* way a long-lived task learns to stop, so it must reach every task that has to stop — pass it down explicitly rather than reaching for a global. `token.child_token()` creates a token that is cancelled when the parent is, which gives a subtree its own lifetime without losing the parent's. Cancelling a token does not abort the tasks holding it: it only makes `cancelled()` resolve, so each task must select on it and return.

A server also needs to stop when the process is asked to: `tokio::signal::ctrl_c()` waits for `SIGINT` and `tokio::signal::unix::signal(SignalKind::terminate())` for `SIGTERM`. A container's default stop signal is `SIGTERM`, so a service that only handles `SIGINT` needs the image to declare `STOPSIGNAL SIGINT`. [tokio-signal](https://docs.rs/tokio/latest/tokio/signal/)

## select! and cancellation safety

`tokio::select!` polls several branches and drops the ones that did not complete. A branch is therefore *cancelled* at an arbitrary point, and the operation inside it must be safe to abandon mid-way. `[TOKIO]`

```rust
use tokio::sync::mpsc;

/// Consume the next message, but give up after `timeout_ms`.
pub async fn recv_with_timeout(rx: &mut mpsc::Receiver<String>, timeout_ms: u64) -> Result<String, String> {
    tokio::select! {
        // `recv` is cancellation-safe: dropping the future loses no message.
        msg = rx.recv() => msg.ok_or_else(|| "channel closed".to_string()),
        _ = tokio::time::sleep(std::time::Duration::from_millis(timeout_ms)) => Err("timed out".to_string()),
    }
}
```

Without a `biased;` prefix the macro picks a **random** ready branch; with `biased;` it polls in source order, and fairness becomes the author's responsibility. Cancellation-safe operations can be restarted without losing data; a partially consumed read or a committed transaction must be wrapped so it can be resumed, or driven to completion outside the `select!`.

## Never block the executor

A worker thread runs one task at a time. A blocking call inside an async task stalls every other task on that worker — the runtime cannot preempt it. `[TOKIO]`

| Situation | Fix |
|---|---|
| The library offers an async API | Use it |
| The call is genuinely blocking (file I/O, CPU-heavy work, a sync DB driver) | `tokio::task::spawn_blocking` |
| You are inside a multi-thread runtime and must call a blocking function inline | `tokio::task::block_in_place` (multi-thread runtime only) |

```rust
/// Read a file without blocking a worker thread.
pub async fn read_file(path: std::path::PathBuf) -> std::io::Result<Vec<u8>> {
    tokio::task::spawn_blocking(move || std::fs::read(path)).await?
}
```

`spawn_blocking` runs on a thread pool that grows up to a cap (`max_blocking_threads`, 512 by default) and queues the work past it. A `spawn_blocking` task that has already started **cannot be cancelled**. `[TOKIO]`

## Channels and back-pressure

| | `std::sync::mpsc::channel()` | `std::sync::mpsc::sync_channel(n)` | `tokio::sync::mpsc::channel(n)` |
|---|---|---|---|
| Producers | many — `Sender` is `Clone` | many — `SyncSender` is `Clone` | many — `Sender` is `Clone` |
| Buffer | unbounded | `n` | `n` |
| `send` | returns immediately | **blocks the thread** when full | `.await`s when full (back-pressure) |
| `recv` | **blocks the thread** | **blocks the thread** | `.await`s |

`sync_channel` differs from `channel()` by being bounded and blocking on `send` — not by being single-producer; `SyncSender` has been `Clone` since 1.0.0. With `n = 0` it is a rendezvous channel. Every `std::sync::mpsc` operation that waits parks the OS thread, so none of it belongs in async code. `[REF]`

`Receiver::recv` returns `Err` only after **every** `Sender` clone has been dropped, so a leaked sender hangs the consumer forever. Drop the sender explicitly when production ends. For many consumers use `tokio::sync::broadcast` (each receiver gets every message) or `tokio::sync::watch` (the latest value only). An unbounded channel removes back-pressure but moves the problem to memory growth.

## Mutex in async code

`std::sync::Mutex` locks with a blocking OS call; `tokio::sync::Mutex` locks with an async wait. `[TOKIO]`

| | `std::sync::Mutex` | `tokio::sync::Mutex` |
|---|---|---|
| Lock operation | Blocks the OS thread | `.lock().await` suspends the task |
| Fairness | Not guaranteed | Fair, in call order |
| Poisoning | Possible | Never poisoned |
| Use when | The critical section never awaits | The guard must survive an `.await`, or fairness matters |

When the critical section only touches plain data, `std::sync::Mutex` is often the better choice in async code — the tokio Mutex costs an allocation per acquisition. Holding a `std::sync::MutexGuard` across an `.await` is a compile error only when the future must be `Send` (as under `tokio::spawn`); when the future stays on one thread the compiler does not stop it, and the lock still stalls the worker. Use `tokio::sync::Mutex` when the guard must cross an await point.

## async fn in traits

Two separate facts, often confused. `[REF]`

- A trait with an `async fn` method is **never** dyn-compatible, which has nothing to do with `Send`.
- A bare `async fn` in a public trait exposes no `Send` bound: `async_fn_in_trait` warns about it, and auto-trait leakage lets an implementor return a `Send` future that generic callers cannot rely on.

```rust
use std::future::Future;
/// A source of values.
pub trait Source {
    fn next_value(&self) -> impl Future<Output = Option<String>> + Send;
}

pub struct ListSource { values: Vec<String> }

impl Source for ListSource {
    fn next_value(&self) -> impl Future<Output = Option<String>> + Send {
        let values = &self.values;
        async move { values.first().cloned() }
    }
}
```

For a public trait, declare `-> impl Future<Output = ..> + Send` so the caller can require a `Send` future. Use `trait_variant::make` when the crate needs both a local and a `Send` variant. Use `async-trait` only when a `dyn Trait` is genuinely required — it boxes every future.
