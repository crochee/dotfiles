**Load this reference when:** writing Rust tests, choosing a test tool, wiring coverage and benchmarks into CI, or hunting undefined behaviour and slow paths.

## Contents

- [Manifest: the dependencies the tools need](#manifest-the-dependencies-the-tools-need)
- [The test runner: cargo nextest](#the-test-runner-cargo-nextest)
- [Unit tests](#unit-tests)
- [Table-driven tests with rstest](#table-driven-tests-with-rstest)
- [Mocking with mockall](#mocking-with-mockall)
- [Async tests](#async-tests)
- [Property-based tests with proptest](#property-based-tests-with-proptest)
- [Feature-flag matrix testing](#feature-flag-matrix-testing)
- [Benchmarks with criterion](#benchmarks-with-criterion)
- [Doc tests](#doc-tests)
- [Coverage with cargo-llvm-cov](#coverage-with-cargo-llvm-cov)
- [Finding undefined behaviour with Miri](#finding-undefined-behaviour-with-miri)
- [Fuzzing boundaries with cargo-fuzz](#fuzzing-boundaries-with-cargo-fuzz)
- [Profiling hot paths](#profiling-hot-paths)

## Manifest: the dependencies the tools need

Every test tool is a dev-dependency, and each needs specific features. Add them with `cargo add --dev proptest mockall rstest criterion` and `cargo add --dev tokio --features macros,rt,rt-multi-thread,time`. Pin a version only to reproduce an existing setup, and check that version's MSRV against the crate's own `rust-version` first. Criterion needs the bench harness disabled with a `[[bench]]` entry carrying `harness = false`.

## The test runner: cargo nextest

`cargo nextest run` runs **each test in its own process**, while `cargo test` runs a binary's tests in one shared process. That difference decides the flaky-test question: under `cargo test`, a test that panics takes down the whole binary and every other test in it is cancelled with it; under nextest only the panicking test dies. The per-test process also gives each test its own timeout and its own environment, so tests cannot corrupt each other's state through a global. [nextest](https://github.com/nextest-rs/nextest)

```bash
cargo install cargo-nextest --locked
cargo nextest run --locked --all-features   # --profile ci for retries
```

Installing from source requires `--locked`. **nextest does not run doctests** — `cargo test --doc` stays a separate step. For a large suite, `--partition slice:m/n` splits the tests into `n` contiguous slices and `--partition hash:m/n` splits them by a hash of the test name, so the partition is stable across runs; `cargo nextest archive` captures the build and test binaries so a failed CI job reproduces locally without rebuilding. [nextest-partitioning](https://nexte.st/docs/ci-features/partitioning/)

## Unit tests

Keep tests in the same file as the code they cover, in a `#[cfg(test)]` module. A private item is reachable from the test module; a public API is tested from an integration test in `tests/`. Name the behaviour, not the mechanics: `adds_two_positive_numbers` survives a refactor of `add`; `test_add` does not.

```rust
pub fn add(a: i32, b: i32) -> i32 { a + b }

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn adds_two_positive_numbers() { assert_eq!(add(2, 2), 4); }
}
```

## Table-driven tests with rstest

`rstest` gives each case a name, so a failure points at the case rather than at a line number. [rstest](https://docs.rs/rstest/latest/rstest/)

```rust
use rstest::rstest;
/// A validated email address.
pub fn is_valid_email(input: &str) -> bool {
    input.split_once('@').is_some_and(|(l, d)| !l.is_empty() && d.contains('.'))
}

#[rstest]
#[case("valid@email.com", true)]
#[case("invalid", false)]
fn validates_email(#[case] input: &str, #[case] expected: bool) {
    assert_eq!(is_valid_email(input), expected);
}
```

## Mocking with mockall

`mockall` generates the mock from the trait, so the mock cannot drift from the trait's signature; `#[automock]` on the trait is what generates `MockStore`. Mock the trait you own, not the one you call: `#[automock]` on your own trait keeps the production code free of test-only attributes. A trait whose methods carry a `where` clause needs the `mock!` macro instead. [mockall](https://docs.rs/mockall/latest/mockall/)

```rust
use mockall::{automock, predicate::*};
#[automock]
pub trait Store {
    fn get(&self, key: &str) -> Option<String>;
}
#[test]
fn returns_the_stored_value() {
    let mut mock = MockStore::new();
    mock.expect_get().with(eq("key")).returning(|_| Some("v".into()));
    assert_eq!(mock.get("key"), Some("v".into()));
}
```

## Async tests

`#[tokio::test]` builds a runtime for the test. It needs `macros` and `rt`; `flavor = "multi_thread"` also needs `rt-multi-thread`; `start_paused = true` needs `test-util` and makes time deterministic — the clock does not advance on its own, so a test can assert on a timeout without sleeping. A timeout assertion tests the timeout, not the operation: assert `result.is_err()` rather than asserting on the value inside the `Ok`. [tokio](https://docs.rs/tokio/latest/tokio/)

```rust
#[tokio::test]
async fn times_out() {
    let pending = std::future::pending::<()>();
    let result = tokio::time::timeout(std::time::Duration::from_millis(50), pending).await;
    assert!(result.is_err(), "the operation should not have finished");
}
```

## Property-based tests with proptest

A property test generates many inputs and checks an invariant. **The oracle must assert only what the implementation guarantees.** This bites when the sort key is coarser than the element: sorting by key means elements the comparator calls "equal" can still differ, and an unstable sort is free to reorder them. An oracle that applies the *stable* `sort_by` and compares whole elements imposes a tie-break order the implementation never promised — and below roughly twenty elements the unstable sort happens to behave like a stable one, so the failure also looks intermittent. [proptest](https://docs.rs/proptest/latest/proptest/)

```rust
/// A work item ordered by priority only: ties are **unspecified**.
pub fn sort_by_priority(mut items: Vec<(u8, String)>) -> Vec<(u8, String)> {
    items.sort_unstable_by_key(|i| std::cmp::Reverse(i.0));
    items
}

#[cfg(test)]
mod tests {
    use super::*;
    use proptest::prelude::*;
    proptest! {
        #[test]
        fn priorities_are_descending(items in prop::collection::vec((0u8..4u8, "[a-c]{3}"), 0..64)) {
            let keys = |v: &[(u8, String)]| v.iter().map(|(p, _)| *p).collect::<Vec<_>>();
            let mut expected = keys(&items);
            expected.sort_unstable_by_key(|p| std::cmp::Reverse(*p));
            // Compare the projected keys — the only guarantee — not whole elements.
            prop_assert_eq!(keys(&sort_by_priority(items)), expected);
        }
    }
}
```

**`?` and `unwrap()` differ only in who writes the message.** `proptest` catches the panic with `catch_unwind` and turns it into `TestCaseError::Fail`, so the run still shrinks the input and reports the minimal failing case. `?` produces proptest's failure text, which carries the shrunk input; `unwrap()` produces your own panic text. `prop_assert_eq!` reports the mismatching values, `prop_assert!` checks a boolean, and `prop_assume!` rejects an input as out of scope instead of failing.

## Feature-flag matrix testing

Features are additive, so a crate that compiles with its default features may still fail with `--no-default-features`, or with a single optional dependency enabled. `--all-features` does not find that: it enables everything at once and hides the combination that breaks. `cargo hack` builds the combinations instead. [cargo-hack](https://github.com/taiki-e/cargo-hack)

```bash
cargo install cargo-hack --locked
cargo hack check --each-feature --no-dev-deps
cargo hack check --feature-powerset --no-dev-deps
```

`--each-feature` builds the package once per feature, each time with that feature alone plus the default set; `--feature-powerset` builds every combination, including the bare `--no-default-features` build and the default build. `--no-dev-deps` avoids a Cargo issue with dev-dependencies in the matrix, and a crate with an optional dependency needs that dependency's absence to be a supported configuration.

## Benchmarks with criterion

Benchmark the code as it is used, including the setup a caller would pay. `b.iter` runs the closure many times and reports the distribution; `b.iter_batched` separates setup from the measured call. [criterion](https://docs.rs/criterion/latest/criterion/)

```rust
use criterion::{criterion_group, criterion_main, Criterion};
pub fn sort_benchmark(c: &mut Criterion) {
    let data: Vec<i32> = (0..1000).collect();
    c.bench_function("sort 1000", |b| b.iter(|| data.clone().sort_unstable()));
}
criterion_group!(benches, sort_benchmark);
criterion_main!(benches);
```

## Doc tests

Doc tests run under `cargo test`, so an example that does not compile fails the build. They are the only tests that show the public API to a reader. A `#`-prefixed line is hidden from the rendered documentation but still compiled and run.

````rust
/// Adds one to a number.
/// ```
/// assert_eq!(add_one(2), 3);
/// ```
pub fn add_one(x: i32) -> i32 { x + 1 }
````

## Coverage with cargo-llvm-cov

`cargo-llvm-cov` uses the same LLVM instrumentation as the compiler, so the numbers match `cargo test` exactly, and it is considerably faster than `cargo-tarpaulin`. `--summary-only` narrows the export to per-file summary data, and it only takes effect together with `--json`, `--lcov`, `--cobertura` or `--codecov` — on its own it is a no-op, because the text output is already a summary. For a terminal summary use `--text`. `--ignore-filename-regex` **skips** the matching files — it is not a changed-files filter. The `llvm-tools` component was renamed from `llvm-tools-preview` in rustup 1.27.0. Coverage is a way to find untested branches, not a target to hit; a percentage with no threshold is noise. [cargo-llvm-cov](https://github.com/taiki-e/cargo-llvm-cov)

```bash
cargo install cargo-llvm-cov && rustup component add llvm-tools
cargo llvm-cov --text
cargo llvm-cov --lib --ignore-filename-regex 'src/main.rs|tests/'
```

## Finding undefined behaviour with Miri

`cargo miri test` interprets the test suite and detects undefined behaviour that the optimiser would otherwise silently accept: out-of-bounds access, invalid `unsafe` code, leaking a `Box`, misaligned references. It is orders of magnitude slower than a normal test run, so it belongs on the unsafe modules, not in the default gate. [miri](https://github.com/rust-lang/miri)

```bash
rustup +nightly component add miri && cargo +nightly miri test
```

## Fuzzing boundaries with cargo-fuzz

A fuzzer feeds generated input to a target and keeps whatever crashes it. Point it at the parser, the decoder and the `unsafe` boundary — the code that turns bytes into values. The corpus is worth keeping: it makes a crash reproducible and each new crash a regression test. [cargo-fuzz](https://github.com/rust-fuzz/cargo-fuzz)

```bash
cargo install cargo-fuzz && cargo +nightly fuzz run parse_target
```

## Profiling hot paths

Measure before optimising. `cargo flamegraph` renders a call-graph flame chart from a `perf` recording; `perf record` produces the raw profile. Both need debug symbols in the profiled build, so profile a release build with `debug = true` under `[profile.release]`. For async code, `tokio-console` shows the runtime's internal state — task counts, wake-up latencies, resource polls — which a sampling profiler alone cannot show. `[PERF]` [flamegraph](https://github.com/flamegraph-rs/flamegraph) · [tokio-console](https://github.com/tokio-rs/console)

```bash
cargo install flamegraph && cargo flamegraph --release --bin myapp -- --serve
```
