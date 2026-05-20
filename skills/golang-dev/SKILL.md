---
name: golang-dev
description: Use when writing Go code, structuring packages, handling errors, managing concurrency, writing tests, or building deployable Go applications.
metadata:
  author: skills-team
---

# Go Development

## When to Use

- Writing idiomatic Go code
- Writing unit tests, table-driven tests, benchmarks, fuzz tests
- Building Docker images or CI/CD pipelines for Go services

**Invoke `test-driven-development` skill** when implementing features via TDD.

## Patterns Summary

| Problem | Solution |
|---------|----------|
| Error handling | Sentinel errors + `%w` wrapping |
| Interface design | Accept interfaces, return structs |
| Concurrency | `errgroup`, buffered channels, context propagation |
| Configurable structs | Functional options pattern |
| Shared state | `sync.Mutex` |

**Key idioms:**
- Handle all errors explicitly
- Use `context.Context` as first parameter for cancellation/timeout
- Preallocate slices when size is known
- Build static binaries with `CGO_ENABLED=0`

**See [references/patterns.md](references/patterns.md) for detailed error handling, concurrency, and struct patterns.**

## Testing Summary

| Type | Pattern |
|------|---------|
| Table-driven tests | Define test cases as struct, iterate with `t.Run()` |
| Mocking | Interface-based mocking (define in consumer package) |
| Benchmarks | `b.ResetTimer()`, run with `-bench=. -benchmem` |
| Fuzzing | `f.Fuzz()` with `f.Add()` seed values |

**See [references/testing.md](references/testing.md) for complete testing patterns.**

## Deployment Summary

| Task | Command |
|------|---------|
| Static build | `CGO_ENABLED=0 go build -ldflags="-s -w"` |
| Pre-deploy | `go vet`, `golangci-lint run`, `go test -race` |

**See [references/deployment.md](references/deployment.md) for multi-stage Dockerfile, distroless images.**

## DO / DON'T

| DO | DON'T |
|----|--------|
| Handle all errors explicitly | Ignore errors with `_, _ = ...` |
| Context as first parameter | Pass context in structs |
| Use `sync.Pool` for frequent allocations | Use `time.Sleep()` in tests |
| Preallocate slices | Run containers as root |

## References

- [references/patterns.md](references/patterns.md) - Error handling, concurrency, struct patterns
- [references/testing.md](references/testing.md) - Table-driven tests, mocking, benchmarks
- [references/deployment.md](references/deployment.md) - Docker, CI/CD, pre-deploy checks