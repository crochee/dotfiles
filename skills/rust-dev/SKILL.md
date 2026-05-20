---
name: rust-dev
description: Use when writing Rust code, structuring packages, handling errors, managing concurrency, implementing tests, or setting up deployment with Docker/cross-compilation
metadata:
  author: skills-team
---

# Rust Development

## When to Use

- Writing idiomatic Rust (ownership, borrowing, lifetimes)
- Structuring error handling, type design, API surface
- Writing tests (unit, integration, async, property-based, benchmarks)
- Building/deploying Rust binaries (cross-compilation, MUSL, Docker)

**Invoke `test-driven-development` skill** when implementing features via TDD.

## Patterns Summary

| Problem | Solution |
|---------|----------|
| Optional value | `Option<T>` |
| Fallible operation | `Result<T, E>` |
| Library errors | `thiserror` derive |
| App-level errors | `anyhow::Result<T>` |
| Shared ownership | `Arc<T>` / `Rc<T>` |
| Shared mutability | `Mutex<T>` / `RefCell<T>` |
| Owned or borrowed string | `Cow<'_, str>` |
| Message passing | `mpsc::channel` / `tokio::sync::mpsc` |

**Key idioms:**
- Prefer `&`/`&mut` over ownership transfer when data doesn't need to be consumed
- Use `match` exhaustively; add `_` only for non-exhaustive external enums
- Use `impl Trait` in return position for opaque return types
- Keep internal modules private (`mod` not `pub mod`)

**See [references/patterns.md](references/patterns.md) for detailed ownership, error handling, concurrency patterns.**

## Testing Summary

| Type | Tool |
|------|------|
| Unit tests | `#[cfg(test)]` + `#[test]` |
| Parameterized | `rstest` |
| Mocking | `mockall` |
| Async tests | `#[tokio::test]` |
| Property-based | `proptest` |
| Benchmarks | `criterion` |

**See [references/testing.md](references/testing.md) for examples of parameterized tests, mocking, property-based testing, benchmarks.**

## Deployment Summary

| Task | Command |
|------|---------|
| Cross-compile | `cross build --target x86_64-unknown-linux-musl` |
| MUSL static build | `cargo build --release --target x86_64-unknown-linux-musl` |
| Security audit | `cargo audit` |

**See [references/deployment.md](references/deployment.md) for Docker scratch images, security auditing.**

## DO / DON'T

| DO | DON'T |
|----|--------|
| `Result`/`Option` over exceptions | `.unwrap()` in library code |
| `impl Trait` over generic params | `String` everywhere (use `&str`) |
| `clippy` + `rustfmt` in CI | Skip error context |
| Doc tests for public API | Chain `.clone()` without reason |
| Design types for invalid states | Block in async contexts |

## Quick Reference

**See references for detailed patterns:**
- [references/patterns.md](references/patterns.md) - Ownership, errors, concurrency
- [references/testing.md](references/testing.md) - All test types with examples
- [references/deployment.md](references/deployment.md) - Cross-compilation, Docker, security