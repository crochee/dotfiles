# Rust Patterns Reference

**Load this reference when:** writing Rust code, understanding idiomatic patterns.

## Ownership & Borrowing

```rust
// Prefer borrowing over ownership
fn process(data: &str) { /* ... */ }

// Use .clone() only when necessary
fn flexible(s: impl AsRef<str>) {
    let owned = s.as_ref().to_string(); // Only allocate when needed
}

// Lifetimes: elide when possible
fn first(s: &str) -> &str { &s[0..1] }

// Annotate only when compiler requires
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() { x } else { y }
}
```

## Error Handling

### Library Errors (thiserror)

```rust
#[derive(Debug, Error)]
pub enum AppError {
    #[error("not found: {0}")]
    NotFound(String),
    #[error("permission denied")]
    PermissionDenied,
    #[error("io error")]
    Io(#[from] std::io::Error),
}
```

### Application Errors (anyhow)

```rust
fn run() -> anyhow::Result<()> {
    let config = std::fs::read_to_string("config.toml")?;
    // ... heavy context
    Ok(())
}
```

## Enums & Pattern Matching

```rust
enum State {
    Idle,
    Running,
    Done,
}

// Exhaustive matching
match state {
    State::Idle => { /* ... */ }
    State::Running => { /* ... */ }
    State::Done => { /* ... */ }
}

// #[non_exhaustive] for public enums
#[non_exhaustive]
pub enum ExternalEnum {
    VariantA,
    VariantB,
}
```

## Traits & Generics

```rust
// Prefer impl Trait for opaque return types
fn make_processor() -> impl Processor {
    // ...
}

// Constrain generics with trait bounds
fn process_all<T: Iterator<Item = String>>(iter: T) {
    for item in iter {
        // ...
    }
}
```

## Cow for Flexible Ownership

```rust
fn normalize(s: Cow<'_, str>) -> Cow<'_, str> {
    if s.contains('\r') {
        Cow::Owned(s.replace('\r', ""))
    } else {
        s
    }
}

// Usage
normalize("hello");           // &str - no allocation
normalize(String::from("a\r")); // String - allocates
```

## Iterators

```rust
// Chain operations before .collect()
let result: Vec<_> = items
    .iter()
    .filter(|x| x.active)
    .map(|x| &x.name)
    .collect();

// Fallible iteration
.try_for_each(|item| process(item))?;
.try_fold(0, |acc, item| Ok(acc + item))?;
```

## Concurrency

```rust
// Shared mutable state
let data = Arc::new(Mutex::new(vec![]));
let data_clone = Arc::clone(&data);

thread::spawn(move || {
    data_clone.lock().unwrap().push(1);
});

// Channels
use std::sync::mpsc;
let (tx, rx) = mpsc::channel();
tx.send(42).unwrap();
let value = rx.recv().unwrap();

// Tokio async
#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let handle = tokio::spawn(async { 42 });
    let result = handle.await?;
    Ok(())
}
```

## Minimal Pub Surface

```rust
// lib.rs
pub mod api;     // Only export public interface
mod internal;    // Internal implementation

// Crate-internal visibility
pub(crate) fn helper() { /* ... */ }
```