**Load this reference when:** designing a Rust API, choosing ownership or error types, deciding between generics, `impl Trait` and `dyn Trait`, or setting the wire format and the log surface.

## Contents

- [Borrow before you own](#borrow-before-you-own)
- [Error types: thiserror vs anyhow](#error-types-thiserror-vs-anyhow)
- [Enums and exhaustive matching](#enums-and-exhaustive-matching)
- [Cow: borrow or own](#cow-borrow-or-own)
- [Iterators, including fallible iteration](#iterators-including-fallible-iteration)
- [Generics, impl Trait and dyn Trait](#generics-impl-trait-and-dyn-trait)
- [Shared ownership and shared mutability](#shared-ownership-and-shared-mutability)
- [Minimal public surface](#minimal-public-surface)
- [Sealed traits: an API you can extend later](#sealed-traits-an-api-you-can-extend-later)
- [The serialization boundary](#the-serialization-boundary)
- [Structured logging with tracing](#structured-logging-with-tracing)
- [Unsafe policy](#unsafe-policy)

## Borrow before you own

Take `&str` / `&[T]` parameters and return borrowed data unless the callee must own it; ownership transfer is a decision, not a default. `[RAPI]` `AsRef<str>` covers `String`, `&str` and `Cow<'_, str>`; `Path` and `PathBuf` implement `AsRef<Path>` and `AsRef<OsStr>`, never `AsRef<str>`. Byte-index slicing of a `str` panics off a UTF-8 character boundary, so use `str::get`. `[REF]`

```rust
fn first(s: &str) -> &str {
    let end = s.chars().next().map_or(0, char::len_utf8);
    s.get(..end).unwrap_or_default()
}
```

## Error types: thiserror vs anyhow

`thiserror` derives `Display` and `Error`; `#[from]` implies `#[source]`, so `Error::source()` walks the chain. `anyhow::Context::with_context` attaches context at the call site without inventing types, so the chain survives the conversion. `[RAPI]`

```rust
use thiserror::Error;

#[derive(Debug, Error)]
pub enum AppError {
    #[error("entity {0} not found")]
    NotFound(String),
    /// `#[from]` also makes this the `source`.
    #[error("io error")]
    Io(#[from] std::io::Error),
}
```

## Enums and exhaustive matching

Model states as an enum and let the compiler enforce every case. `[RAPI]` `#[non_exhaustive]` only counts where the *defining* crate put it: it has no effect inside that crate, and only downstream matches gain a required wildcard arm. `[REF]`

```rust
#[derive(Debug, Clone, Copy)]
pub enum State {
    Idle,
    Running,
}
```

## Cow: borrow or own

`Cow<'_, str>` holds a `&str` until a transformation needs an owned `String`. Prefer `&str` in the signature and `Cow` in the return type when the function usually returns its input unchanged: `Cow::Borrowed(s)` while nothing changed, `Cow::Owned(next)` after a rewrite that had to allocate. `[RAPI]`

## Iterators, including fallible iteration

Chain adapters and collect once. `[STYLE]` `try_for_each` and `try_fold` are iterator methods, not free functions, and `?` needs a closure that returns `Result` — a bare `.try_for_each(|f| …?)` with a `()` body does not compile. `try_fold` threads the accumulator and ends at the first `Err`. `[RAPI]`

```rust
fn parse_all(fields: &[&str]) -> Result<Vec<u32>, std::num::ParseIntError> {
    fields.iter().try_fold(Vec::with_capacity(fields.len()), |mut acc, field| {
        acc.push(field.parse::<u32>()?);
        Ok(acc)
    })
}
```

## Generics, impl Trait and dyn Trait

`impl Trait` in argument position is an **anonymous type parameter**: the caller cannot name it, cannot turbofish it, and it does not appear in the generic list. Multiple bounds are legal — `impl Display + Clone` is one anonymous parameter with two bounds. `[REF]` C-GENERIC covers generics versus a concrete type, not turbofishing. `[RAPI]` A generic parameter is monomorphised: no vtable, no allocation, and it inlines; `dyn` costs an indirection and accepts an open set of implementors.

```rust
use std::fmt::Display;
/// Argument position: anonymous, and several bounds are legal.
fn show(item: impl Display + Clone) -> String {
    format!("{item}")
}
/// A named generic: the caller may turbofish.
fn parse_it<T: std::str::FromStr>(s: &str) -> Result<T, T::Err> { s.parse() }
```

## Shared ownership and shared mutability

| Need | Use | Reason |
|---|---|---|
| Shared ownership across threads | `Arc<T>` | `Send`/`Sync` only when `T` is; the atomic count is the cost. |
| Shared ownership in one thread | `Rc<T>` | No atomics; not `Send`. |
| Mutable access from several threads | `Mutex<T>` | The lock serialises access; a panicked holder poisons it. |
| Mutable access in one thread | `RefCell<T>` | Runtime borrow checks, no OS lock; not `Sync`. |

A poisoned `Mutex` still yields its data: recover the guard with `counter.lock().unwrap_or_else(|err| err.into_inner())` instead of unwrapping the poison. `[REF]`

## Minimal public surface

`pub mod api;` publishes the module and everything in it; `mod api;` plus `pub use` publishes only the names you name. `[RAPI]`

```rust
// The module is private; only the re-exported names are public.
mod api {
    pub struct Request;
    pub struct Service;
}

pub use api::{Request, Service};
```

## Sealed traits: an API you can extend later

A public trait promises that any type may implement it; a trait nobody outside the crate should implement is a different promise, and you cannot retract it once the trait is public. Sealing closes the set of implementors without changing the signature: a private supertrait the public trait requires.

```rust
mod sealed {
    pub trait Sealed {}
}

/// A store only this crate's types may implement.
pub trait Store: sealed::Sealed {
    fn get(&self, key: &str) -> Option<String>;
}

pub struct MapStore;

impl sealed::Sealed for MapStore {}
impl Store for MapStore {
    fn get(&self, key: &str) -> Option<String> { Some(key.to_string()) }
}
```

A user sees `impl Store for MyType` fail with a private-trait error rather than a missing-method error, which is the point.

## The serialization boundary

Derives belong to the *wire* type, not the domain type: keep them apart and convert in between, so a schema change never rewrites the business rules. Untrusted input gets its own type, a closed schema via `#[serde(deny_unknown_fields)]`, and a `TryFrom` into the domain type — a `Deserialize` impl that can build an invalid domain value is a bug waiting for a bad payload. `#[serde(default)]` marks an optional field, `#[serde(rename_all = "camelCase")]` renames only where the wire format demands it, and adding or removing a field is a breaking change for `cargo semver-checks` to catch. [serde](https://serde.rs/)

```rust
use serde::Deserialize;
/// The wire format of a new-account request.
#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
struct NewAccountRequest {
    name: String,
}

/// A validated domain account.
pub struct Account { pub name: String }

impl TryFrom<NewAccountRequest> for Account {
    type Error = String;
    fn try_from(r: NewAccountRequest) -> Result<Self, Self::Error> {
        let name = r.name.trim().to_string();
        if name.is_empty() { return Err("name must not be empty".into()); }
        Ok(Account { name })
    }
}
```

## Structured logging with tracing

A library emits events; it never installs a subscriber — the binary installs exactly one. Events carry fields rather than an interpolated string so a log index can filter on them, `#[instrument]` opens a span around the call, and a `?` on a failed call ends the span while the caller adds context. Never log a secret or a personal datum, and emit no `debug!` per iteration on a hot path; the subscriber reads `RUST_LOG`. [tracing](https://docs.rs/tracing/latest/tracing/)

```rust
use tracing::instrument;

/// Load one user and record what happened.
#[instrument(fields(user_id = %user_id))]
pub fn load_user(user_id: u64) -> anyhow::Result<u64> {
    let found = user_id; // stands in for the storage query
    tracing::info!(user_id = %found, "user loaded");
    Ok(found)
}
```

## Unsafe policy

Default to `#![forbid(unsafe_code)]` at the crate root: `forbid` cannot be overridden by an inner `allow` or `warn`. `[REF]` A crate that genuinely needs `unsafe` keeps it in one module, drops that attribute, and documents the invariant that makes it sound in a `SAFETY:` comment above every block — the invariant, not the operation. Expose only a safe wrapper whose `# Safety` section states what the caller must guarantee. `[NOM]`

```rust
#![allow(unsafe_code)]

use std::mem::MaybeUninit;

/// View the initialized prefix of a partially initialized buffer.
///
/// # Safety
/// The first `len` bytes of `buf` must be initialized.
pub unsafe fn from_raw(buf: &[MaybeUninit<u8>], len: usize) -> &[u8] {
    // SAFETY: the caller guarantees the first `len` bytes are initialized.
    unsafe { std::slice::from_raw_parts(buf.as_ptr().cast::<u8>(), len) }
}
```
