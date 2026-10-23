**Load this reference when:** laying out a Cargo workspace, pinning a toolchain and MSRV, cross-compiling, building a multi-stage container image, wiring Rust into CI, migrating a crate to a new edition, or choosing a release profile.

## Contents

- [Workspace layout](#workspace-layout)
- [Workspace lints and shared configuration](#workspace-lints-and-shared-configuration)
- [Cargo features](#cargo-features)
- [Toolchain, edition and MSRV](#toolchain-edition-and-msrv)
- [Cross-compilation](#cross-compilation)
- [Container image](#container-image)
- [CI pipeline](#ci-pipeline)
- [Migrating to Rust 2024](#migrating-to-rust-2024)
- [Release profile and binary size](#release-profile-and-binary-size)

## Workspace layout

The root `Cargo.toml` holds `[workspace]`, `[workspace.package]` and `[workspace.dependencies]`; `Cargo.lock` is committed for binaries; `rust-toolchain.toml` pins the toolchain for everyone and for CI; `crates/` holds the members.

```toml
[workspace]
resolver = "3"
members = ["crates/myapp-core", "crates/myapp-cli"]
default-members = ["crates/myapp-cli"]
[workspace.package]
version = "0.1.0"
edition = "2024"
rust-version = "1.85"

[workspace.dependencies]
tokio = { version = "1", features = ["rt", "rt-multi-thread", "macros", "sync", "time"] }
```

`default-members` decides what a bare `cargo build` at the root builds, so a workspace with several binaries does not compile all of them by accident. `resolver = "3"` is the edition-2024 default and needs Rust 1.84+; it matters in a virtual workspace with no root package, and it makes the resolver prefer dependency versions whose own `rust-version` is at or below yours. A member inherits with `version.workspace = true`, `edition.workspace = true` and `tokio.workspace = true`. [cargo-workspaces](https://doc.rust-lang.org/cargo/reference/workspaces.html)

## Workspace lints and shared configuration

Lint levels live in the manifest, not in a `.clippy.toml` that each member duplicates: `[workspace.lints]` defines them once and a member opts in with `[lints] workspace = true`. `[workspace.metadata]` carries keys other tools read, such as `cargo-udeps`'s ignore list. [cargo-workspaces](https://doc.rust-lang.org/cargo/reference/workspaces.html)

```toml
[workspace.lints.rust]
unsafe_code = "forbid"
missing_docs = "warn"

[workspace.lints.clippy]
todo = "deny"
unwrap_used = "warn"
```

`forbid` on `unsafe_code` is the manifest equivalent of `#![forbid(unsafe_code)]` and reaches every member that opts in; a crate that genuinely needs `unsafe` overrides it in its own manifest with a documented reason.

## Cargo features

Features are **additive**: enabling one must not disable functionality, and any combination must be safe to enable. A feature must not introduce a semver-incompatible change, so it cannot remove a public item or change a type's meaning. Model optional `std` support as a `std` feature that *enables* `std`, never as a `no_std` feature that removes it. [cargo-features](https://doc.rust-lang.org/cargo/reference/features.html)

Two consequences bite. `default-features = false` only holds if *every* dependent sets it — one omission re-enables the defaults through feature unification. And a feature-gated item is still public API: removing it later is a breaking change unless the crate was published as `#[non_exhaustive]`.

```toml
[features]
default = ["std"]
std = []
```

Test the matrix, not just the default set: `cargo hack check --feature-powerset --no-dev-deps` builds every combination, `--each-feature` builds one at a time. A feature that compiles only with the defaults set is a broken feature. [cargo-hack](https://github.com/taiki-e/cargo-hack)

## Toolchain, edition and MSRV

Three settings, three jobs: `edition` is the language edition (2024 requires Rust 1.85 or newer), `rust-version` is the MSRV that Cargo refuses to build below, and `channel` in `rust-toolchain.toml` is the toolchain developed and tested against. 1.85 is the edition's **floor**, not a recommendation: read the project's own `rust-toolchain.toml` and `rust-version` and use those. [rust-toolchain](https://doc.rust-lang.org/cargo/reference/config.html#nested-places)

The declared `rust-version` is a **claim**; the dependency graph is the **fact**. `cargo msrv find` resolves the graph the way the declared MSRV would and reports the highest MSRV actually required; `cargo msrv verify` checks the declared value against a build. [cargo-msrv](https://github.com/foresterre/cargo-msrv)

## Cross-compilation

Since Rust 1.44 the musl targets use **self-contained linking**: rustup's musl `rust-std` ships the musl libc and the CRT startup objects, so `cargo build --release --target x86_64-unknown-linux-musl` on a glibc Linux host produces a static binary with no extra linker setup, after `rustup target add x86_64-unknown-linux-musl`. The `cc: error: unrecognized command line option '-static'` symptom belongs to macOS/clang hosts. `cross` runs the same build in a container with the toolchain and linker preinstalled — a convenience, not a prerequisite. A musl binary swaps the system allocator for musl's slower one; a glibc builder with a matched glibc runtime keeps the default allocator. [linux_musl](https://github.com/rust-lang/rust/blob/master/compiler/rustc_target/src/spec/base/linux_musl.rs)

## Container image

Build the artefact in one stage and ship only the artefact in another: the builder needs a C toolchain, the source and the crates, the runtime needs the binary. Caching is the hard part — copying `Cargo.toml` alone does not work for a workspace with path dependencies, and stubbing out `src/main.rs` breaks on the first build script or proc-macro. `cargo chef prepare` writes a `recipe.json` describing the minimal manifests and `cargo chef cook` builds only the dependencies, so the recipe is the dependency layer's cache key. [cargo-chef](https://github.com/LukeMathWalker/cargo-chef)

```dockerfile
# syntax=docker/dockerfile:1
ARG RUST_VERSION=1.98
ARG DISTROLESS=gcr.io/distroless/cc-debian13:nonroot

FROM rust:${RUST_VERSION}-slim AS chef
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends gcc make perl m4 && rm -rf /var/lib/apt/lists/*
RUN --mount=type=cache,target=/usr/local/cargo/registry,sharing=locked --mount=type=cache,target=/usr/local/cargo/git,sharing=locked \
    cargo install cargo-chef --locked
WORKDIR /build

FROM chef AS planner
COPY Cargo.toml Cargo.lock ./
COPY crates crates
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS cacher
COPY --from=planner /build/recipe.json recipe.json
RUN --mount=type=cache,target=/usr/local/cargo/registry,sharing=locked --mount=type=cache,target=/usr/local/cargo/git,sharing=locked \
    cargo chef cook --release -p myapp --bin myapp --recipe-path recipe.json

FROM cacher AS builder
COPY Cargo.toml Cargo.lock ./
COPY crates crates
RUN --mount=type=cache,target=/usr/local/cargo/registry,sharing=locked --mount=type=cache,target=/usr/local/cargo/git,sharing=locked \
    cargo build --release --locked -p myapp && mkdir -p /build/data /build/tmp && chmod 0755 /build/data /build/tmp

FROM ${DISTROLESS}
COPY --chown=65532:65532 --from=builder /build/target/release/myapp /usr/local/bin/myapp
COPY --chown=65532:65532 --from=builder /build/data /data
COPY --chown=65532:65532 --from=builder /build/tmp /tmp
USER 65532:65532
ENTRYPOINT ["/usr/local/bin/myapp"]
```

- **The runtime base ships the same libc major version as the builder.** `rust:1.98-slim` is Debian 13 with glibc 2.41 and `cc-debian12` has 2.36, so a binary that references a newer symbol dies at startup with `GLIBC_2.x not found`; a trivial program needs only 2.34 and survives, which is why the mismatch ships quietly until a dependency pulls in a newer symbol. Match the Debian release, or build against musl and use `scratch`. [distroless](https://github.com/GoogleContainerTools/distroless)
- **`cc`, not `base`.** `cc` adds `libgcc_s` and `libstdc++`, which Rust's unwinder and some allocators need; `base` lacks them.
- **The runtime user is 65532.** `:nonroot` runs as uid 65532, and the explicit `USER 65532:65532` keeps the image default aligned with a Kubernetes `runAsUser`/`runAsGroup`/`fsGroup`.
- **Ownership and writable directories are fixed outside the runtime stage.** Distroless has no shell, so `chown` and `mkdir` cannot run there: use `COPY --chown=65532:65532` and create `/data` and `/tmp` in the builder.
- **`ENTRYPOINT` and `HEALTHCHECK` use the exec form.** No shell exists to interpret the shell form.
- **`STOPSIGNAL SIGINT` for a server that handles `ctrl_c`.** Docker's default is `SIGTERM`; a Tokio service that traps `SIGINT` needs the image to send it.
- **Probe endpoints live in the application.** A `HEALTHCHECK` needs a binary in the image; a service exposing `/livez` and `/readyz` does not need one, and adding `curl` costs more than it saves.
- **`.dockerignore` excludes `target/` and local secrets.** A build context carrying a multi-gigabyte `target/` makes every build slow.

## CI pipeline

Five jobs: lint, test, docs, MSRV, security. `permissions: contents: read` at the top is not decoration — without it the workflow inherits the repository's token defaults, often write-all.

```yaml
name: CI
on: [push, pull_request]
permissions: { contents: read }
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: Swatinem/rust-cache@v2
      - run: cargo fmt --all -- --check && CARGO_BUILD_WARNINGS=deny cargo clippy --all-targets --all-features
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: taiki-e/install-action@nextest
      - run: cargo nextest run --locked --all-features
      - run: cargo test --doc --locked
  docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: RUSTDOCFLAGS="-D warnings" cargo doc --no-deps --locked
  msrv:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: cargo +1.85 build --locked --all-features
  security:
    runs-on: ubuntu-latest
    permissions: { contents: read, security-events: write }
    steps:
      - uses: actions/checkout@v4
      - uses: rustsec/audit-check@v2
        with: { token: "${{ secrets.GITHUB_TOKEN }}" }
      - run: cargo install cargo-deny --locked && cargo deny check
```

`rust-toolchain.toml` names the toolchain and `rustup` installs it on first use, so no step installs it. The MSRV job builds rather than tests, because a dev-dependency may need a newer compiler than the crate's `rust-version`; the third-party tools have their own MSRV and run in the default-toolchain job. Cargo 1.97+ prefers `[build] warnings = "deny"` or `CARGO_BUILD_WARNINGS=deny` over `-D warnings`, which defeats the build cache. [rustsec](https://github.com/rustsec/rustsec)

## Migrating to Rust 2024

`cargo fix --edition` rewrites code but not the manifest: set `edition = "2024"` yourself, run `cargo test`, then run `cargo fix --edition` again for the fixes that only apply under the new edition. What bites, in rough order of surprise:

| Change | What it means |
|---|---|
| RPIT lifetime capture | `impl Trait` in return position now captures every lifetime in scope; `+ use<>` bounds it back. |
| `if let` temporary scope | The scrutinee drops before the `else` block, not after it. |
| Tail-expression temporary scope | Temporaries in a block's tail drop before the block's locals. |
| Match ergonomics reservations | Patterns that bound by default are reserved and need an explicit binding mode. |
| `unsafe extern` blocks | `extern "C" { … }` must be `unsafe extern "C" { … }`. |
| `unsafe` attributes | `#[no_mangle]`, `#[export_name]`, `#[link_section]` become `#[unsafe(no_mangle)]` and so on. |
| `unsafe_op_in_unsafe_fn` | An `unsafe` operation inside an `unsafe fn` is now a warning; the block needs its own `unsafe`. |
| `static mut` references | A reference to a `static mut` is denied; use an `AtomicX` or a `SyncUnsafeCell` wrapper. |
| `gen` keyword | `gen` is reserved for future use. |
| rustfmt 2024 style | `cargo fmt` reformats; run it and read the diff. |
| `Box<[T]>: IntoIterator` | `Box<[T]>` now iterates by value, changing some `into_iter()` call sites. |

[edition-2024](https://doc.rust-lang.org/edition-guide/rust-2024/index.html)

## Release profile and binary size

```toml
[profile.release]
lto = "thin"        # cross-crate LTO without full LTO's memory spike
codegen-units = 1   # one codegen unit: smaller and slower to build
strip = "symbols"   # drop symbols from the artefact
panic = "abort"     # smaller binary — only if the process never unwinds
```

`"fat"` is the smallest binary and the most likely to hang a constrained builder. `panic = "abort"` is only safe when nothing catches a panic: a server that reports a failed request and keeps serving cannot abort. `strip` belongs in the profile, not a post-build invocation, because the profile applies to every artefact cargo produces. [profiles](https://doc.rust-lang.org/cargo/reference/profiles.html)

Measure instead of guessing: `cargo bloat --release --crates` reports which crates occupy the binary; its numbers are estimates and it does not support WASM. A release build uses `--locked` and the lockfile is committed for binaries, because that is what makes the artefact reproducible; libraries do not commit it, since the published package carries none. [cargo-bloat](https://github.com/RazrFalcon/cargo-bloat) · [cargo-lock](https://doc.rust-lang.org/cargo/guide/cargo-toml-vs-cargo-lock.html)
