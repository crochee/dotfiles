# Go Deployment Reference

**Load this reference when:** deploying Go applications, building Docker images.

## Static Build

```bash
CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /app/server ./cmd/server
```

## Multi-Stage Dockerfile

```dockerfile
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /server ./cmd/server

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=builder /server /server
EXPOSE 8080
ENTRYPOINT ["/server"]
```

## Pre-Deploy Checks

```bash
go vet ./...
golangci-lint run
go test -race -cover ./...
```

## Environment Management

| Tool | Purpose |
|------|---------|
| `go mod` | Dependency management |
| `golangci-lint` | Linting |
| `staticcheck` | Static analysis |

## Health Checks

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s CMD /server -health
```

## Security

- Run as non-root user
- Use distroless/static base image
- Scan dependencies: `go list -json -m all | jq -r '.Path + "@" + .Version' | gorilla_audit`
- Pin dependencies in go.sum