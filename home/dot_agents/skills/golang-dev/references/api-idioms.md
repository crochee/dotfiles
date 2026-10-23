**Load this reference when:** writing error handling, choosing a receiver, defining an interface or a
generic type, laying out a package, or picking a standard-library helper instead of hand-rolling one.

## Errors a caller can branch on

Declare one sentinel per expected failure mode; the caller matches it with `errors.Is`, never
with message text. Return a typed error when the caller needs a field, recovered with
`errors.As`. Wrap with `%w` only where meaning is added, and only once. `[CRC]` `[EFF]`
```go
package catalog

import (
	"errors"
	"fmt"
)

// ErrNotFound is the sentinel callers branch on with errors.Is.
var ErrNotFound = errors.New("catalog: item not found")

// InvalidItemError carries the field that failed; errors.As reads it.
type InvalidItemError struct{ SKU, Field string }

func (e *InvalidItemError) Error() string {
	return fmt.Sprintf("catalog: item %s: invalid %s", e.SKU, e.Field)
}

// Add stores an item; every failure is a typed error a caller can match.
func Add(sku, name string) error {
	switch {
	case sku == "":
		return &InvalidItemError{SKU: sku, Field: "sku"}
	case name == "":
		return &InvalidItemError{SKU: sku, Field: "name"}
	}
	return nil
}

// Reason maps an error from Add onto a decision the caller can make.
func Reason(err error) string {
	var invalid *InvalidItemError
	switch {
	case errors.As(err, &invalid):
		return "fix the " + invalid.Field + " field"
	case errors.Is(err, ErrNotFound):
		return "item is missing"
	}
	return "unexpected failure"
}
```

`errors.As` takes a pointer to the variable holding the error type; anything else is a vet
error.
```go
var errs []error
if name == "" {
	errs = append(errs, fmt.Errorf("name is required"))
}
return errors.Join(errs...)

// one wrap, at the layer that adds meaning
if err := os.ReadFile(path); err != nil {
	return fmt.Errorf("load config %s: %w", path, err)
}
```

Independent failures are reported together with `errors.Join`; one wrap hides nothing. Wrapping
the same error at every level buries the sentinel. `[EFF]`

## What an error carries

An error crossing a package boundary carries the operation, the subject, the rejected value,
the limit, and the cause wrapped with `%w` — no secret. `[EFF]` `[UBER]`
```go
if spent+cost > limit {
	return fmt.Errorf("check quota for %s: spent %d + cost %d exceeds limit %d: %w",
		account, spent, cost, limit, ErrExhausted)
}
```

## Interfaces belong to the consumer

Declare an interface in the package that calls it, with only the methods that package calls:
the bigger the interface, the weaker the abstraction. Define one only when two implementations
exist or a consumer needs a fake. Accept an interface, return a concrete type; a constructor
never returns an interface. `[GOOG]` `[CRC]`
```go
// Ledger is this package's own view of a ledger.
type Ledger interface {
	Charge(ctx context.Context, account string, cents int64) error
}

// NewService accepts the interface and returns the concrete type.
func NewService(ledger Ledger) *Service { return &Service{ledger: ledger} }
```

## Pointer or value receiver

Take a pointer receiver when the method mutates the receiver or the type holds a mutex or
another field that must not be copied; take a value receiver for a small immutable value copied
freely. Never mix value and pointer receivers on one type: the type then has two method sets,
and copying a struct with a lock is a bug `go vet` reports as `copylocks`. `[CRC]` `[GOOG]`

| Use a pointer receiver | Use a value receiver |
|---|---|
| the method mutates the receiver | the method only reads it |
| the type holds a mutex or a non-copyable field | small, immutable, copied freely |

## Generics

Give a type parameter at least two real instantiations; one instantiation is an interface in
disguise. Constrain it with `comparable` or `cmp.Ordered`. `[EFF]`
```go
func Sorted[T cmp.Ordered](in map[T]struct{}) []T {
	out := make([]T, 0, len(in))
	for v := range in {
		out = append(out, v)
	}
	slices.Sort(out)
	return out
}
```

## Modern Go helpers

| Feature | Since | Use it for |
|---|---|---|
| `errors.Join` | 1.20 | combining failures into one error |
| `slices`, `maps` | 1.21 | `slices.Sort`, `maps.Clone` instead of hand loops |
| `min`, `max` builtins | 1.21 | clamping without a helper |
| `log/slog` | 1.21 | structured logging with levels |
| `http.ServeMux` method and wildcard patterns | 1.22 | `mux.HandleFunc("GET /items/{id}", …)`, no router |
| `for range n` | 1.22 | counting loops with no index variable |
| `os.Root` | 1.24 | filesystem access confined to one directory |
| `testing.B.Loop` | 1.24 | benchmarks whose setup runs once |

Map iteration order is unspecified, so sort the keys before comparing or persisting anything
derived from a map. Build a string once and read it many times with `strings.Builder` behind a
`sync.Once`. `[EFF]` `[UBER]` `[DOC]`
```go
names := slices.Sorted(maps.Keys(counts))
v := min(max(v, lo), hi)

var b strings.Builder
b.Grow(8 * len(parts))
b.WriteString(strings.Join(parts, "."))
```

Confine filesystem access to one directory with `os.Root`: it rejects `..` and a symlink that
points out. `[DOC]`
```go
root, err := os.OpenRoot(dir)
if err != nil {
	return err
}
defer root.Close()
f, err := root.Open(name)
```

## Structured logging

Take `*slog.Logger` as a constructor argument; a package never calls `slog.Default()`. Log
attributes, never a message assembled with `fmt.Sprintf` — a formatted message cannot be
filtered or aggregated on one field. Use the JSON handler in production, the text handler for a
human, and a `slog.LevelVar` for a level that changes at run time. `[EFF]` `[UBER]`
```go
// Recorder writes audit events under an injected logger.
type Recorder struct{ log *slog.Logger }

// Record writes one event; ctx carries the caller's request id.
func (r *Recorder) Record(ctx context.Context, action string) {
	r.log.InfoContext(ctx, "audit event", slog.String("action", action))
}
```

## Package layout and dependencies

| Location | Purpose |
|---|---|
| `cmd/<name>/` | one `main` package per binary; flags and wiring only |
| `internal/<pkg>/` | code other modules cannot import: the "not public API" boundary |
| `pkg/` | only when an outside module must import it |
| `go.mod` | module path and the `go` directive |
| `go.work` | multi-module checkout; commit it |

Standard library first; every third-party module is an audit surface. Pick one test-double
library per repository — `go.uber.org/mock` or `testify` — and say which. `[GOOG]` `[UBER]`

## Sources

| Tag | Source |
|---|---|
| [CRC] | Go Code Review Comments — https://go.dev/wiki/CodeReviewComments |
| [DOC] | Standard library docs — https://pkg.go.dev/ |
| [EFF] | Effective Go — https://go.dev/doc/effective_go |
| [GOOG] | Google Go Style Guide — https://github.com/google/styleguide/blob/gh-pages/go/guide.md |
| [UBER] | Uber Go Style Guide — https://github.com/uber-go/guide/blob/master/style.md |
