**Load this reference when:** building a release binary, writing the Dockerfile, running the
pre-deploy and vulnerability checks, or keeping modules tidy.

## Static build

`CGO_ENABLED=0` gives a binary with no dynamic loader; `-trimpath` drops local build paths and
`-s -w` strips symbols. Set `GOOS`/`GOARCH` in CI too. `[MOD]` `[SEC]`

```bash
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -trimpath -ldflags="-s -w" -o bin/server ./cmd/server
```

## Container

```dockerfile
ARG GO_VERSION=1.27
FROM golang:${GO_VERSION}-bookworm AS builder
WORKDIR /src
COPY go.* ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/server ./cmd/server
FROM gcr.io/distroless/static-debian13:nonroot
COPY --from=builder /out/server /server
ENTRYPOINT ["/server"]
```
Declare `ARG` before the first `FROM`; five reasons for the image above:
- **bookworm, not alpine** — a glibc builder avoids musl-only behaviour in `net` and `os/user`.
- **`COPY go.*` before `COPY . .`** — the dependency layer stays cached.
- **exec form** — no shell, so `HEALTHCHECK` is `CMD ["…"]` with `--start-period` and `--retries`.
- **the `nonroot` tag is the non-root user** — uid 65532, no `USER` line to forget.
- **the runtime base is Debian 13** — `gcr.io/distroless/static-debian13:nonroot`; `static-debian12:nonroot` still exists for images pinned to the older base.

## Pre-deploy checks

Run all six; each catches a class the others do not. `[LINT]` `[SEC]`

```bash
go build ./...
go vet ./...
go test -race -cover ./...
golangci-lint run
govulncheck ./...
go mod tidy -diff
```

`govulncheck` walks the call graph; `osv-scanner` over-reports. `[SEC]`

`go mod tidy -diff` (Go 1.23+) prints the diff `go mod tidy` would make and exits non-zero when the tree is untidy. `[REL]`

## Module hygiene

- `go get example.com/pkg@v1.2.3` — add a dependency; `go mod why -m pkg` explains it.
- `go mod tidy` — drop unused entries, in the change that adds or removes an import.
- `go mod verify` — check the module cache against `go.sum`, which is committed.
- `go get -tool golang.org/x/tools/cmd/stringer@latest`, then `go tool stringer …` — track a build tool.

## The container's CPU and memory

Since Go 1.25 the runtime reads the cgroup CPU limit and sizes `GOMAXPROCS` itself; do not set `GOMAXPROCS` to the node's CPU count, and do not set it at all unless a measured workload needs it. Set `GOMEMLIMIT` below the container's memory limit (a 1 GiB container gets `GOMEMLIMIT=900MiB`): it is a soft limit, and that headroom is what keeps the process inside the cgroup instead of being OOM-killed. `[REL]`

## The lint tool's own version

golangci-lint v2 reads a `version: "2"` config; migrate a v1 config with `golangci-lint migrate` and check it with `golangci-lint config verify`. `golangci-lint run` is unchanged. `[LINT]`

## Sources

| Tag | Source |
|---|---|
| [LINT] | golangci-lint linters — https://golangci-lint.run/docs/linters/ |
| [MOD] | Go Modules Reference — https://go.dev/ref/mod |
| [REL] | Go release notes — https://go.dev/doc/devel/release |
| [SEC] | Go Security Best Practices — https://go.dev/doc/security |
