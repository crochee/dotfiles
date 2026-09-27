# Rust Deployment Reference

**Load this reference when:** deploying Rust applications, setting up Docker, cross-compiling.

## Cross-Compilation

### Install cross

```bash
cargo install cross
```

### Set up targets

```bash
rustup target add x86_64-unknown-linux-musl
rustup target add aarch64-unknown-linux-gnu
```

### Build for different targets

```bash
# Linux x86_64 (MUSL - static)
cross build --release --target x86_64-unknown-linux-musl

# Linux ARM64
cross build --release --target aarch64-unknown-linux-gnu

# Linux x86_64 (gnu libc)
cross build --release --target x86_64-unknown-linux-gnu
```

## MUSL Static Builds

### Why MUSL?

- Fully static binaries (no libc dependency)
- Works on any Linux system without libc installed
- No_ld.so issues

### Build command

```bash
cargo build --release --target x86_64-unknown-linux-musl
```

### Docker scratch images work

```dockerfile
FROM scratch
COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/myapp /myapp
ENTRYPOINT ["/myapp"]
```

### Multi-stage Docker

```dockerfile
# Stage 1: Build
FROM rust:1.75 as builder
WORKDIR /app
COPY Cargo.toml Cargo.lock ./
COPY src ./src
RUN cargo build --release --target x86_64-unknown-linux-musl

# Stage 2: Run
FROM scratch
COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/myapp /myapp
ENTRYPOINT ["/myapp"]
```

## Security Auditing

### Install cargo-audit

```bash
cargo install cargo-audit
```

### Run audit

```bash
cargo audit
```

### CI integration

```yaml
# .github/workflows/security.yml
name: Security Audit
on: [push, pull_request]

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: rustsec/audit-check@v1
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
```

### Pin advisories

```bash
# Review advisory database
cargo audit --dry-run

# For known issues, add to allow list
echo '[[ advisories ]]' >> Cargo.toml
echo 'advisory = { id = "RUSTSEC-0001", reason = "acceptable"' >> Cargo.toml
```

## Docker Best Practices

### Minimal base image

```dockerfile
FROM alpine:latest AS certs
RUN apk --no-cache add ca-certificates
FROM scratch
COPY --from=certs /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/myapp /myapp
ENTRYPOINT ["/myapp"]
```

### Add health check

```dockerfile
FROM scratch
COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/myapp /myapp
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 CMD /myapp health
ENTRYPOINT ["/myapp"]
```

### Environment variables

```dockerfile
FROM scratch
ENV RUST_LOG=info
COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/myapp /myapp
ENTRYPOINT ["/myapp"]
```