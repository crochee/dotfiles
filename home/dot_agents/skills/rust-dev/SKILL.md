---
name: rust-dev
description: "Produces Rust whose public API is documented, whose errors a caller can match, and whose release build reproduces from the committed lockfile. Use when writing, reviewing or shipping Rust code, Cargo layout, async runtimes and channels, test tooling (unit, property, fuzz, benchmark), or release images. Not for shell or YAML editing, CI work with no Rust source, a non-Rust toolchain, or a conceptual question with no code. 中文：写/审 Rust、API、async、测试、发布产物。"
license: MIT
metadata:
  version: "1.1.0"
---

# Rust Development

Produces Rust whose public API is documented, whose errors a caller can match on, whose concurrency cannot leak, and whose release build reproduces from a committed lockfile. Every rule carries a source tag.

## When to Use
- Designing or changing a crate's public API: ownership, error types, trait bounds, module surface.
- Choosing between a named generic, `impl Trait` and `dyn Trait`.
- Writing async code: runtime choice, structured concurrency, channels, blocking calls.
- Choosing a test tool: unit, table-driven, mock, async, property-based, fuzz, benchmark, doc.
- Wiring Cargo features, MSRV, workspace layout, a release profile or a multi-stage image.
Not for: shell or YAML editing, CI work with no Rust source, a non-Rust toolchain, or a conceptual question with no code.

## Workflow
1. **Establish the baseline.** Read `Cargo.toml`, `rust-toolchain.toml`, the workspace layout, the feature set and the existing CI; edition 2024 needs Rust 1.85 or newer. `[EDITION]` *Exit:* edition, `rust-version`, members, features and the project's own lint and test commands are stated. → `references/deployment.md`
2. **Fix the type, trait and error surface.** Settle ownership, the polymorphism form and the error type. *Exit:* every new public item has a written signature and a chosen error type. → `references/patterns.md`
3. **Write the failing test.** Unit test next to the code, property test for invariants, doctest for public items, matrix for feature sets. *Exit:* the new test fails before the change and passes after it. → `references/testing.md`
4. **Implement synchronously by default.** Introduce async only for real concurrent I/O, and give every long-lived task a cancellation path. *Exit:* every await point has a reason, no blocking call lands on a worker, every long task selects on a cancel token. → `references/async-and-concurrency.md`
5. **Run the gate.** Format, lint, test, document, audit. *Exit:* every command exits 0 and its output is quoted. → `references/testing.md`
6. **Ship.** Release profile and size, multi-stage image, semver check, publish. *Exit:* the artefact reproduces from the committed lockfile, the audit passes, the public API is unbroken. → `references/supply-chain.md`

## Quick Decisions
| Trait surface | Form |
|---|---|
| Caller names the type | named generic `fn f<T: Bound>(t: T)` |
| Implementor chosen by the caller | `&dyn Trait` borrowed, `Box<dyn Trait>` owned |
| Caller never names it | `impl Trait` argument position |
| Type hidden from the caller | `-> impl Trait` return position |
| Nobody outside the crate may implement it | a sealed supertrait |

| Ownership | Form |
|---|---|
| The callee only reads | `&T` |
| The callee needs to modify | `&mut T` |
| The callee stores it | `T`, moved |
| The callee stores it, callers share | `Arc<T>` across threads, `Rc<T>` in one |

| Error type | Choice |
|---|---|
| Library whose callers branch on failure | `thiserror` typed enum |
| Application that logs and exits | `anyhow::Result` + `with_context` |
| Library that must not add a dependency | hand-written `Display` + `Error` |
| Error that wraps another error | a `#[from]` variant — it implies `#[source]` |

| Concurrency | Choice |
|---|---|
| Default | synchronous |
| Real concurrent I/O | async on a runtime |
| Blocking call inside a task | `spawn_blocking` |
| Stopping a long-lived task | a `CancellationToken`, not a flag |

| Channel | Choice |
|---|---|
| Sync code, unbounded | `std::sync::mpsc::channel` |
| Sync code, bounded | `sync_channel` — `send` blocks |
| Async back-pressure | bounded `tokio::sync::mpsc` |
| Async fan-out | `broadcast` (every consumer) or `watch` (latest value only) |

## Output Contract
| Deliverable | Must contain |
|---|---|
| Source | The changed files at their final paths, each public item documented. |
| Public API table | `Symbol \| Signature \| Semantics`, one row per added or changed public item, signature copied verbatim from the source. |
| Tests | A test that fails when the change is reverted, with that failure shown. |
| Command output | Quoted output of `cargo fmt --all -- --check`, `CARGO_BUILD_WARNINGS=deny cargo clippy --all-targets --all-features`, `cargo nextest run --locked --all-features` (`cargo test` when nextest is absent), `cargo test --doc --locked`, `RUSTDOCFLAGS="-D warnings" cargo doc --no-deps --locked`. |
| Dependency and release delta | Dependencies added and removed with their `cargo add` lines and the declared `rust-version`; for a release, the target triple, the artefact path, and the `cargo audit`, `cargo deny check` and `cargo semver-checks` results. |

## Guardrails
- No `.unwrap()` or `.expect()` in library code — return a `Result`, or panic on a documented invariant. `[RAPI]`
- No `.clone()` without a stated ownership reason that names who holds the copy. `[RAPI]`
- No `std::sync::MutexGuard` held across an `.await` — the guard is not `Send`, and it stalls the executor task. `[TOKIO]`
- No blocking call on a runtime worker — use the async API, `spawn_blocking` or `block_in_place`. `[TOKIO]`
- Cargo features stay additive — enabling one never removes functionality and never breaks semver. `[CARGO]`
- `unsafe` is off by default via `#![forbid(unsafe_code)]`, and every `unsafe` block carries a `SAFETY:` comment naming its invariant. `[NOM]`

## Review Mode
| Check | How to verify | Source |
|---|---|---|
| Library code has no `unwrap()` or `expect()` | grep `src/`, excluding `#[cfg(test)]` | `[RAPI]` |
| Every public item is documented and has a doctest | `RUSTDOCFLAGS="-D warnings" cargo doc --no-deps --locked` and `cargo test --doc` | `[STYLE]` |
| No `MutexGuard` is held across an `.await` | grep `lock()` inside `async fn` | `[TOKIO]` |
| Every long-lived task can be cancelled | grep for `select!` with `cancelled()` in task bodies | `[TOKIO]` |
| Edition and `rust-version` are declared and CI builds with that MSRV | `cargo metadata` plus the CI job | `[CARGO]` |

## References
| File | Load when |
|---|---|
| [references/patterns.md](references/patterns.md) | Ownership and borrowing, error types, `Cow`, iterators, generics vs `impl Trait` vs `dyn`, sealed traits, `Arc`/`Rc`, `Mutex`/`RefCell`, minimal public surface, the serialization boundary, `tracing`, unsafe policy. |
| [references/async-and-concurrency.md](references/async-and-concurrency.md) | Sync-first judgement, runtime and feature selection, `Send`/`Sync` across awaits, `JoinSet`, cancellation tokens, `select!`, blocking work, channels, `Mutex` in async, `async fn` in traits. |
| [references/testing.md](references/testing.md) | The `cargo nextest` runner, unit, `rstest`, `mockall`, `#[tokio::test]`, `proptest`, feature-matrix builds, `criterion`, doc tests, coverage, Miri, fuzzing, profiling. |
| [references/deployment.md](references/deployment.md) | Workspace layout, workspace lints, Cargo features, edition and MSRV, cross-compilation, multi-stage container images, CI pipeline, edition migration, release profile and binary size. |
| [references/supply-chain.md](references/supply-chain.md) | Adding and removing dependencies, `cargo tree`, auditing with `cargo audit` and `cargo deny`, `cargo vet`, licensing with `cargo about`, unused dependencies, `cargo semver-checks`, publishing, the pre-release checklist. |

## Verification Checklist
- [ ] `cargo fmt --all -- --check` and `CARGO_BUILD_WARNINGS=deny cargo clippy --all-targets --all-features` pass with no warning. `[CLIPPY]`
- [ ] `cargo nextest run --locked --all-features` (or `cargo test --locked --all-features`) passes, the new test fails when the change is reverted, and `cargo test --doc --locked` passes.
- [ ] `RUSTDOCFLAGS="-D warnings" cargo doc --no-deps --locked` emits no warning; with `cargo-hack` installed, `cargo hack check --feature-powerset --no-dev-deps` passes.
- [ ] `cargo audit` and `cargo deny check` pass; with `cargo-semver-checks` installed, `cargo semver-checks` reports no breaking change. `[SEC]` `[DENY]`

## Sources
| Tag | Source |
|---|---|
| `[RAPI]` | Rust API Guidelines — https://rust-lang.github.io/api-guidelines/ |
| `[REF]` | The Rust Reference — https://doc.rust-lang.org/reference/ |
| `[STYLE]` | Rust Style Guide — https://doc.rust-lang.org/style-guide/ |
| `[CLIPPY]` | Clippy — https://doc.rust-lang.org/clippy/ |
| `[CARGO]` | The Cargo Book — https://doc.rust-lang.org/cargo/ |
| `[EDITION]` | Rust 2024 Edition Guide — https://doc.rust-lang.org/edition-guide/ |
| `[ASYNC]` | Rust Async Book — https://rust-lang.github.io/async-book/ |
| `[TOKIO]` | Tokio docs — https://docs.rs/tokio/latest/tokio/ |
| `[SEC]` | RustSec / cargo-audit — https://github.com/rustsec/rustsec |
| `[DENY]` | cargo-deny — https://embarkstudios.github.io/cargo-deny/ |
| `[NOM]` | The Rustonomicon — https://doc.rust-lang.org/nomicon/ |
| `[PERF]` | Rust Performance Book — https://nnethercote.github.io/perf-book/ |
