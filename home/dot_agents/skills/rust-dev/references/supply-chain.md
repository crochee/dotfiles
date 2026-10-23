**Load this reference when:** adding or removing a dependency, auditing the dependency graph, checking a release for breaking changes, publishing a crate to a registry, or preparing the pre-release checklist.

## Contents

- [Dependency hygiene with cargo built-ins](#dependency-hygiene-with-cargo-built-ins)
- [Auditing the dependency graph](#auditing-the-dependency-graph)
- [Licensing and attribution](#licensing-and-attribution)
- [Finding unused dependencies](#finding-unused-dependencies)
- [Proving a release is not breaking](#proving-a-release-is-not-breaking)
- [Publishing to a registry](#publishing-to-a-registry)
- [Pre-release checklist](#pre-release-checklist)

## Dependency hygiene with cargo built-ins

Never hand-edit the dependency tables: `cargo add` writes the entry, the feature flags and the lockfile together, and a hand-written entry is how version drift starts. `cargo add serde --features derive` adds a dependency, `cargo remove serde_json` removes one. Add with `--no-default-features` when the defaults pull in what you do not want. [cargo-add](https://doc.rust-lang.org/cargo/commands/cargo-add.html)

```bash
cargo add serde --features derive
cargo add --no-default-features flate2 --features zlib-rs
cargo remove serde_json
```

Pin one crate without disturbing the rest of the graph: the package spec is **positional**, so `cargo update serde --precise <version>` pins `serde` alone. [cargo-update](https://doc.rust-lang.org/cargo/commands/cargo-update.html)

```bash
cargo update serde --precise <version>   # the exact version to pin to
```

`cargo tree -d` lists every crate that appears at more than one version — it implies `--invert`, so it shows the reverse edges that pull each duplicate in. `cargo tree -i serde` shows what pulls a crate in, and `cargo tree -e features` shows which features are enabled and by whom: that is how you find out why a dependency you never asked for is in the graph. [cargo-tree](https://doc.rust-lang.org/cargo/commands/cargo-tree.html)

```bash
cargo tree -d
cargo tree -i serde
cargo tree -e features -i serde
```

## Auditing the dependency graph

`cargo audit` checks `Cargo.lock` against the RustSec advisory database. Its **configuration** comes from `.cargo/audit.toml` in the current directory or from `$CARGO_HOME/audit.toml`; it does not search parent directories the way `cargo deny` does, and it never reads `Cargo.toml` for configuration. The allow-list is an `[advisories]` table with an `ignore` array of advisory IDs. [cargo-audit](https://github.com/rustsec/rustsec)

```toml
# .cargo/audit.toml
[advisories]
ignore = [
    # Unreachable in our deployment: the vulnerable code path is behind a
    # feature flag we never enable. Re-evaluate before each release.
    "RUSTSEC-2024-0001",
]
```

Every ignored advisory needs a comment saying why it is safe. An unexplained entry is an unreviewed vulnerability. A missing lockfile makes `cargo audit` generate one first, so it reads `Cargo.toml` in that case, and `cargo audit fix` rewrites `Cargo.toml` as well.

`cargo deny` covers what `cargo audit` does not — banned crates, duplicate versions and licence policy. It looks for its configuration, walking up from the manifest directory, in `deny.toml`, `.deny.toml`, `.cargo/deny.toml` and `.config/deny.toml`; the first existing file wins. `cargo deny check` runs every check by default. [cargo-deny-cfg](https://embarkstudios.github.io/cargo-deny/checks/advisories/cfg.html)

```toml
# deny.toml
[advisories]
unmaintained = "workspace"
[bans]
multiple-versions = "warn"
wildcards = "deny"
deny = [{ crate = "openssl", reason = "use rustls instead" }]
[licenses]
allow = ["MIT", "Apache-2.0", "Apache-2.0 WITH LLVM-exception", "BSD-3-Clause", "ISC", "Unicode-3.0"]
```

`unmaintained` is a **scope**, not a severity: it takes `all` (the default), `workspace`, `transitive` or `none`. A severity value such as `warn` is not a valid setting for that key — Cargo-deny rejects it as an unknown value.

For a stronger guarantee, `cargo vet` matches the third-party dependencies against audits that real people have reviewed and signed, so a compromised release is caught even before it reaches the advisory database. `cargo vet init` records the audits for the current dependency set, and `cargo vet` checks the graph against them. [cargo-vet](https://github.com/mozilla/cargo-vet)

## Licensing and attribution

`cargo deny check licenses` enforces the allow-list, but it does not tell you what to put in the notice file. `cargo-about` generates that: `cargo about init` writes an `about.toml`, and `cargo about generate` renders the licence text of every dependency into a file you ship with the binary. A dependency added under a permissive licence still needs its attribution in the artefact. [cargo-about](https://github.com/EmbarkStudios/cargo-about)

```bash
cargo install --locked cargo-about
cargo about init
cargo about generate about.hbs > licenses.html
```

## Finding unused dependencies

A dependency nobody imports is a dependency that still gets compiled, audited and shipped. Two tools find them, and they answer different questions: `cargo machete` works from the manifest and is fast but approximate, while `cargo udeps` compiles the crate and inspects the real linkage, so it is exact but needs a nightly toolchain and takes minutes. [cargo-machete](https://github.com/bnjbvr/cargo-machete) · [cargo-udeps](https://github.com/est31/cargo-udeps)

```bash
cargo install cargo-machete && cargo machete
cargo install cargo-udeps --locked && cargo +nightly udeps
```

`cargo machete` exits non-zero when it finds an unused dependency, so it drops into CI as-is. Both tools take an ignore list for the dependencies that are used in a way neither can see — a build script, a `#[cfg]`-gated module, or a macro that expands to a use.

## Proving a release is not breaking

A library's semver promise is about its public API, and the compiler does not check it. `cargo semver-checks` builds the rustdoc JSON of the released version and of the current one, compares the public API, and reports the differences that violate semver. It exits `0` when there are no violations, `100` when it finds deny-level violations, and `101` when the check could not complete — so a `101` is a broken gate, not a pass. [cargo-semver-checks](https://github.com/obi1kenobi/cargo-semver-checks)

```bash
cargo install cargo-semver-checks --locked
cargo semver-checks
```

`cargo public-api` answers the complementary question: not "is this breaking" but "what exactly is the public surface now". It renders the API to a text file that can be committed and diffed, so a review sees the surface change rather than inferring it from the diff. It needs a recent nightly for the rustdoc JSON. [cargo-public-api](https://github.com/cargo-public-api/cargo-public-api)

```bash
cargo public-api diff latest
```

The tools only see what is public. A type that is `pub` in a private module, or a field that is public but undocumented, is part of the surface whether or not a tool noticed.

## Publishing to a registry

`cargo package` builds the crate exactly as it will be uploaded and verifies it compiles from the packaged tarball; `cargo publish --dry-run` runs the same checks without uploading. Run both before every release — the packaged crate is what consumers get, and it can differ from the working tree. [cargo-publish](https://doc.rust-lang.org/cargo/commands/cargo-publish.html)

```bash
cargo package --allow-dirty
cargo publish --dry-run --allow-dirty
```

A crate that is not published from a clean tree needs `--allow-dirty`; the alternative is a commit. `cargo publish` needs a token — `cargo login` stores one in `$CARGO_HOME/credentials.toml`, and the `CARGO_REGISTRY_TOKEN` environment variable overrides it for CI. A registry source **replacement** in `~/.cargo/config.toml` — a mirror, which is common behind a corporate proxy — makes `cargo publish` fail with "crates-io is replaced with non-remote-registry source"; pass `--registry crates-io` to publish to the real registry anyway.

The manifest is the package metadata. `description`, `license` and `repository` are what crates.io shows on the crate page, and a missing `license` is a legal problem, not a cosmetic one.

```toml
[package]
name = "myapp-core"
version = "0.1.0"
edition = "2024"
rust-version = "1.85"
description = "Core domain types for myapp."
license = "MIT OR Apache-2.0"
repository = "https://github.com/example/myapp"
readme = "README.md"
keywords = ["domain", "types"]
categories = ["data-structures"]
```

`include` and `exclude` control what goes into the uploaded tarball. The default already excludes `target/` and the VCS directory; anything the build needs at compile time — a `build.rs` input, a schema file, a template — must be inside the package, and `cargo package` is what proves it.

## Pre-release checklist

The gate commands themselves — `cargo fmt --all -- --check`, `CARGO_BUILD_WARNINGS=deny cargo clippy --all-targets --all-features`, `cargo nextest run --locked --all-features` and `RUSTDOCFLAGS="-D warnings" cargo doc --no-deps --locked` — are the ones the output contract requires; run all of them before shipping. Then the release-specific checks:

```bash
cargo test --locked --all-features        # doctests, which nextest does not run
cargo semver-checks                       # the public API did not break
cargo audit && cargo deny check           # no known vulnerability, no banned crate
cargo package --allow-dirty               # the packaged tarball builds
cargo build --release --locked            # the artefact reproduces from the lockfile
```

Verify the artefact: `ldd target/release/myapp` prints nothing when the binary is statically linked, and `./target/release/myapp --version` proves it starts. If the crate is published, `cargo publish --dry-run` is the last check before the upload, and `cargo yank` is the reversal if the upload turns out to be wrong.
