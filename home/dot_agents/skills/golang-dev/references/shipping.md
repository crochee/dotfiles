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
ARG GO_VERSION=1.24
FROM golang:${GO_VERSION}-bookworm AS builder
WORKDIR /src
COPY go.* ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/server ./cmd/server
FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=builder /out/server /server
ENTRYPOINT ["/server"]
```
Declare `ARG` before the first `FROM`; four reasons for the image above:
- **bookworm, not alpine** — a glibc builder avoids musl-only behaviour in `net` and `os/user`.
- **`COPY go.*` before `COPY . .`** — the dependency layer stays cached.
- **exec form** — no shell, so `HEALTHCHECK` is `CMD ["…"]` with `--start-period` and `--retries`.
- **the `nonroot` tag is the non-root user** — uid 65532, no `USER` line to forget.

## Pre-deploy checks

Run all five; each catches a class the others do not. `[LINT]` `[SEC]`

```bash
go build ./...
go vet ./...
go test -race -cover ./...
golangci-lint run
govulncheck ./...
```

`govulncheck` walks the call graph; `osv-scanner` over-reports. `[SEC]`

## Module hygiene

- `go get example.com/pkg@v1.2.3` — add a dependency; `go mod why -m pkg` explains it.
- `go mod tidy` — drop unused entries, in the change that adds or removes an import.
- `go mod verify` — check the module cache against `go.sum`, which is committed.
- `go get -tool golang.org/x/tools/cmd/stringer@latest`, then `go tool stringer …` — track a build tool.

## Sources

| Tag | Source |
|---|---|
| [LINT] | golangci-lint linters — https://golangci-lint.run/docs/linters/ |
| [MOD] | Go Modules Reference — https://go.dev/ref/mod |
| [SEC] | Go Security Best Practices — https://go.dev/doc/security |
