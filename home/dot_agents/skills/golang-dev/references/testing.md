**Load this reference when:** writing table-driven, fuzz, or benchmark tests, waiting on
asynchronous state, testing an HTTP handler, or picking a `go test` flag.

## Table-driven tests

Put cases in a slice of named structs, run each in its own `t.Run`, and assert the error
with `errors.Is` against a sentinel, not a boolean. `[GOOG]` `[UBER]`
```go
package calc

import (
	"errors"
	"testing"
)

// ErrNegative reports a negative input.
var ErrNegative = errors.New("calc: negative input")

// Square returns n*n, or ErrNegative when n is negative.
func Square(n int) (int, error) {
	if n < 0 {
		return 0, ErrNegative
	}
	return n * n, nil
}

func TestSquare(t *testing.T) {
	tests := []struct {
		name    string
		n       int
		want    int
		wantErr error
	}{
		{name: "zero", n: 0, want: 0},
		{name: "positive", n: 3, want: 9},
		{name: "negative", n: -1, wantErr: ErrNegative},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := Square(tt.n)
			if !errors.Is(err, tt.wantErr) || got != tt.want {
				t.Errorf("Square(%d) = %d, %v; want %d, %v", tt.n, got, err, tt.want, tt.wantErr)
			}
		})
	}
}
```

Compare structs with `github.com/google/go-cmp/cmp` (`cmp.Diff`) instead of `reflect.DeepEqual`: the diff names the field that differs. `t.Setenv` restores the variable after the test and cannot be combined with `t.Parallel` in the same test; `t.TempDir` gives scratch files that are removed with the test. `[UBER]`

## Integer overflow is the callee's job

Go's `+` wraps silently: `math.MaxInt64 + 1` is `math.MinInt64`. When overflow is an error by contract, the callee checks it and returns a sentinel. `[EFF]` `[UBER]`
```go
func Add(a, b int64) (int64, error) {
	if b > 0 && a > math.MaxInt64-b {
		return 0, fmt.Errorf("add(%d, %d): %w", a, b, ErrOverflow)
	}
	return a + b, nil
}
```

## Fuzz targets assert both outcomes

Assert both outcomes, with the expected value computed by another route: a target that only
skips rejections lets a parser that rejects everything pass forever. `t.Skip` skips one input;
`f.SkipNow` abandons the target. `[GOOG]`
```go
f.Fuzz(func(t *testing.T, input string) {
	port, err := ParsePort(input)
	want, ok := validPort(input)
	if ok && (err != nil || port != want) {
		t.Fatalf("ParsePort(%q) = %d, %v; want %d", input, port, err, want)
	}
	if !ok && err == nil {
		t.Fatalf("expected error for %q", input)
	}
})
```

## The version gate is a test

Since Go 1.27 `go test` runs the `stdversion` vet check by default: a standard library symbol newer than the module's `go` directive (or the file's build tag) is reported and the test binary fails to build. `go vet ./...` reports the same. A module with `go 1.24` that calls `sync.WaitGroup.Go` fails with `requires go1.25 or later (module is go1.24)`. `[REL]` `[CRC]`

## Modernize before you measure

`go fix` (Go 1.26+) applies the toolchain's modernizers: `any`, `atomictypes`, `buildtag`, `embedlit`, `errorsastype`, `forvar`, `hostport`, `inline`, `mapsloop`, `minmax`, `newexpr`, `omitzero`, `plusbuild`, `rangeint`, `reflecttypefor`, `slicesbackward`, `slicescontains`, `slicessort`, `stditerators`, `stringsbuilder`, `stringscut`, `stringscutprefix`, `stringsseq`, `testingcontext`, `unsafefuncs`, `waitgroupgo`. Run `go fix -diff ./...` and read the diff; the fixers are meant to preserve behaviour, but the diff is the review. The modernizers respect the module's `go` directive — a `go 1.24` module gets the `any` rewrite but not `wg.Go`. `[REL]`

## Wait without sleeping

A `time.Sleep` in a test is a wall-clock guess: too short is flaky, too long is slow. Poll on a
ticker and let the context supply the deadline. `[UBER]`
```go
for !ready.Load() {
	select {
	case <-ctx.Done():
		return ctx.Err()
	case <-ticker.C:
	}
}
```

## `t.Context()` and `b.Context()`

Go 1.24 added `t.Context()` and `b.Context()`, cancelled just before the `t.Cleanup` functions
run: a goroutine the test started can watch `ctx.Done()` and be gone by the time a cleanup
asserts on it. `[EFF]` `[DOC]`
```go
ctx := t.Context()
t.Cleanup(func() {
	if ctx.Err() == nil {
		t.Error("t.Context() was still live when cleanup ran")
	}
})
```

## Virtual time with `testing/synctest`

Generally available since Go 1.25. On Go 1.24 the package exists only behind `GOEXPERIMENT=synctest` and with the older API (`synctest.Run`); that API was removed in Go 1.26. Inside the bubble `t.Context()` uses the fake clock and `synctest.Wait()` blocks until every other goroutine is durably blocked. `[EFF]` `[DOC]` `[REL]`
```go
//go:build go1.25

synctest.Test(t, func(t *testing.T) {
	ctx, cancel := context.WithTimeout(t.Context(), 30*time.Minute)
	defer cancel()
	<-ctx.Done()
	if ctx.Err() != context.DeadlineExceeded {
		t.Fatal("the deadline did not fire")
	}
})
```

## Handler tests

Build the real router, then call `mux.ServeHTTP` with `httptest.NewRequest` and
`httptest.NewRecorder`: no listener, no port, no network. Use `httptest.NewServer` for a full round trip. `[GOOG]`
```go
mux := http.NewServeMux()
mux.HandleFunc("GET /greet/{name}", Handler)
req := httptest.NewRequest(http.MethodGet, "/greet/ada", nil).WithContext(t.Context())
rec := httptest.NewRecorder()
mux.ServeHTTP(rec, req)
if rec.Code != http.StatusOK {
	t.Fatalf("status = %d, want %d", rec.Code, http.StatusOK)
}
```

## Benchmarks

`b.Loop()` resets the timer on its first call, so setup above the loop is not measured, and it
keeps the loop body's values alive so the compiler cannot drop it. `b.RunParallel` cannot
use `b.Loop`; it excludes setup with `b.ResetTimer()`. Compare runs with `benchstat`.
`[EFF]` `[UBER]`
```go
func BenchmarkSum(b *testing.B) {
	data := make([]int, 1000)
	b.ReportAllocs()
	for b.Loop() {
		sink.Store(int64(Sum(data)))
	}
}
```

## Profiling

Mount the pprof handlers on a dedicated mux bound to loopback, never on `http.DefaultServeMux`:
the profiles expose goroutine stacks and heap addresses. `-inuse_space` answers what holds
memory now; `-alloc_space` what allocated the most over the lifetime. `[EFF]`
```go
mux := http.NewServeMux()
mux.HandleFunc("/debug/pprof/", pprof.Index) // heap, goroutine, profile, symbol
return mux
```

```bash
go tool pprof -top http://127.0.0.1:6060/debug/pprof/profile?seconds=30
go tool pprof http://127.0.0.1:6060/debug/pprof/heap
go tool pprof -raw http://127.0.0.1:6060/debug/pprof/goroutine?debug=2
```

## Command reference

| Command | Purpose |
|---|---|
| `go test ./...` | run every test in the module |
| `go test -race ./...` | run with the race detector; required before merging |
| `go test -count=1 ./...` | ignore cached results, re-run |
| `go test -shuffle=on ./...` | random order, exposing order dependence |
| `go test -run '^TestAdd$/overflow' ./pkg` | one named subtest |
| `go test -coverprofile=cover.out ./...` | write coverage; `go tool cover -html=cover.out` |
| `go test -bench=. -benchmem ./pkg` | benchmarks with allocation counts |
| `go test -fuzz=FuzzParsePort -fuzztime=30s ./pkg` | fuzz one target for fixed time |
| `go vet ./...` | the toolchain checks, including `copylocks`, `waitgroup`, `hostport`, `stdversion` |
| `go test -run='^$' -bench=. -cpuprofile=cpu.out ./pkg/` | profile a benchmark without running tests |
| `go test -timeout 5m ./...` | bound the run; the default is 10m per package |
| `go test -json ./...` | machine-readable output; Go 1.27 adds an `OutputType` field |
| `go fix -diff ./...` | show the modernizers' patch without touching the tree (Go 1.26+) |

`golangci-lint run` applies the repository's configured linters on top of what `go vet` already checks; it is a gate, not a formatter. A new finding there is a bug to fix or a linter to disable in the config, with the reason written next to it. `[LINT]`

## Sources

| Tag | Source |
|---|---|
| [CRC] | Go Code Review Comments — https://go.dev/wiki/CodeReviewComments |
| [DOC] | Standard library docs — https://pkg.go.dev/ |
| [EFF] | Effective Go — https://go.dev/doc/effective_go |
| [GOOG] | Google Go Style Guide — https://github.com/google/styleguide/blob/gh-pages/go/guide.md |
| [LINT] | golangci-lint linters — https://golangci-lint.run/docs/linters/ |
| [REL] | Go release notes — https://go.dev/doc/devel/release |
| [UBER] | Uber Go Style Guide — https://github.com/uber-go/guide/blob/master/style.md |
