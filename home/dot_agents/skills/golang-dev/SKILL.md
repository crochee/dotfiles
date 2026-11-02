---
name: golang-dev
description: "Produces Go that survives review: documented exported API, branchable errors, leak-free concurrency, a Go release binary in a non-root container. Use when writing, reviewing, refactoring or shipping Go code, tests, packages, binaries or container images. Not for shell or CI work with no Go source, another language's toolchain, or a Go version upgrade. 中文：写/审 Go 代码、包 API、并发、测试、发布镜像。"
license: MIT
metadata:
  version: "1.1.0"
---

# Go Development

Produces Go that survives review: a documented exported API, errors a caller can branch on, concurrency that
cannot leak, and a release image that runs as non-root. Every rule carries a source tag. Requires Go 1.24+.

## When to Use

- Implementing, reviewing, or refactoring Go code.
- Designing a Go package's exported API.
- Writing table-driven, fuzz, or benchmark tests.
- Diagnosing a race, a goroutine leak, or a slow hot path.
- Building a release binary or container image.

Not for: shell or CI work with no Go source, another language's toolchain, or a Go version upgrade.

## Workflow

1. **Fix the target.** Read `go.mod`: the `go` directive sets the language semantics, not the toolchain. → `references/api-idioms.md`
2. **Design the API.** Fix the package boundary; write the `Symbol | Signature | Purpose` table first. → `references/api-idioms.md`
3. **Error and context contract.** One sentinel per failure mode, `%w` once, `ctx` first, never in a struct. → `references/api-idioms.md`
4. **Choose the concurrency primitive.** Every goroutine gets a named owner and a stop condition. → `references/concurrency.md`
5. **Write the failing test.** Table-driven first, fuzz for untrusted input, benchmark for a hot path. → `references/testing.md`
6. **Package and verify.** Static binary, non-root container, every pre-deploy command green. → `references/shipping.md`

## Output Contract

| Deliverable | Must contain |
|---|---|
| Source files | The layout of `references/api-idioms.md`; a doc comment on every exported symbol. |
| API table | `Symbol \| Signature \| Purpose`, one row per exported identifier added or altered. |
| Tests | A test that fails when the change is reverted, with that failure shown. |
| Command output | Quoted output of `go build ./...`, `go vet ./...`, `go test -race ./...`, `golangci-lint run`. |

## Guardrails

- No error is discarded with `_, _ = f()` unless a comment at the call site says why it is safe. `[LINT]`
- `context.Context` is never stored in a struct field. `[CRC]`
- No goroutine starts without a stop condition. `[CRC]`
- Interfaces live with the consumer, hold one to three methods, and no constructor returns an interface. `[GOOG]`
- Every exported identifier has a doc comment that starts with its name. `[CRC]`
- No goroutine outlives the request that owns it. `[UBER]`

## Review Mode

| Check | How to verify | Source |
|---|---|---|
| Every exported identifier has a doc comment starting with its name | `go doc ./pkg` | `[CRC]` |
| No error is discarded | `golangci-lint run` (errcheck) | `[LINT]` |
| Errors wrap once, and wrap a sentinel or a typed error | grep `%w` | `[CRC]` |
| No context lives in a struct field | grep struct definitions for `context.Context` | `[CRC]` |
| Every goroutine has a stop condition | `go test -race ./...` plus goleak | `[CRC]` `[UBER]` |
| No test sleeps on wall-clock time | grep `Sleep(` in `*_test.go` | `[UBER]` |
| One receiver kind per type, and no copied lock | `go vet ./...` (copylocks) | `[CRC]` `[GOOG]` |
| Package layout matches cmd/internal/pkg | directory listing | `[GOOG]` |
| `go.mod` is tidy and `go.sum` is committed | `go mod tidy -diff` | `[MOD]` |
| No reachable vulnerability | `govulncheck ./...` | `[SEC]` |

## References

| File | Load when |
|---|---|
| [references/api-idioms.md](references/api-idioms.md) | Writing errors, choosing a receiver, defining an interface, laying out a package, picking a standard-library helper. |
| [references/concurrency.md](references/concurrency.md) | Starting goroutines, choosing `errgroup`, `sync.WaitGroup`, channels or atomics, propagating a context, diagnosing a race. |
| [references/testing.md](references/testing.md) | Writing table-driven, fuzz or benchmark tests, waiting on asynchronous state, profiling a hot path, picking a `go test` flag. |
| [references/shipping.md](references/shipping.md) | Building the release binary, writing the Dockerfile, running the pre-deploy and vulnerability checks. |

## Verification Checklist

- [ ] `go build ./...` passes.
- [ ] `go vet ./...` passes.
- [ ] `go test -race ./...` passes and its output is quoted.
- [ ] The new test fails when the change is reverted, and the failure is shown.
- [ ] The API table lists every exported identifier added or altered.
- [ ] Every goroutine the change starts has a documented stop condition.
- [ ] No error is discarded without a comment saying why it is safe.
- [ ] `golangci-lint run` reports nothing new and `govulncheck ./...` reports no reachable vulnerability.

## Sources

| Tag | Source |
|---|---|
| [CRC] | Go Code Review Comments — https://go.dev/wiki/CodeReviewComments |
| [GOOG] | Google Go Style Guide — https://github.com/google/styleguide/blob/gh-pages/go/guide.md |
| [LINT] | golangci-lint linters — https://golangci-lint.run/docs/linters/ |
| [MOD] | Go Modules Reference — https://go.dev/ref/mod |
| [SEC] | Go Security Best Practices — https://go.dev/doc/security |
| [UBER] | Uber Go Style Guide — https://github.com/uber-go/guide/blob/master/style.md |
