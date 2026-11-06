**Load this reference when:** starting goroutines, choosing between `errgroup`, `sync.WaitGroup` and
channels, propagating a `context.Context`, or diagnosing a race, a leak, or a deadlock.

## Choosing the primitive

| Need | Use | Why not the others |
|---|---|---|
| Fan-out where the first failure must cancel the rest | `errgroup.WithContext` | `WaitGroup` has no error channel, so it cannot abort the others |
| Fan-out that cannot fail, needs only a barrier | `sync.WaitGroup` | `errgroup` adds context and error plumbing nobody uses |
| Streaming values between stages, or bounding a producer | plain channels | a wait group carries no values and gives no back-pressure |
| One counter or one flag | `sync/atomic` | a mutex around one `int64` blocks every reader |
| Shared mutable state read by many | `sync.RWMutex` | an atomic cannot guard a map |

`errgroup` lives in `golang.org/x/sync`; declare it in `go.mod`. `[GOOG]` `[UBER]` `[MOD]`

## Context rules

A `ctx` is never nil, the first parameter, named `ctx`, and never in a struct field. Pass
`context.Background()` at a request's entry point, `context.TODO()` while refactoring. `[CRC]` `[GOOG]`

`context.WithoutCancel(ctx)` (Go 1.21) keeps the values but drops the cancellation, for work that must outlive the request. `context.AfterFunc(ctx, f)` (Go 1.21) runs `f` when the context is cancelled. `[REL]`

## Derive and cancel

Derive with `context.WithTimeout` or `WithCancel` and cancel with `defer`, so every return path
releases the child's resources. Anything outliving its caller selects on `ctx.Done()`. `[CRC]`
```go
ctx, cancel := context.WithTimeout(ctx, 2*time.Second)
defer cancel()

select {
case <-ctx.Done():
	return ctx.Err()
default:
	return work(ctx)
}
```

## Fan-out with errgroup

`errgroup.WithContext` cancels the derived context on the first non-nil error. Set
`g.SetLimit(n)` when the input exceeds what the downstream tolerates. `[UBER]` `[GOOG]`
```go
package mirror

import (
	"context"
	"fmt"

	"golang.org/x/sync/errgroup"
)

// FetchAll runs fetch concurrently; the first failure cancels the rest.
func FetchAll(ctx context.Context, urls []string,
	fetch func(context.Context, string) (string, error)) ([]string, error) {
	g, ctx := errgroup.WithContext(ctx)
	bodies := make([]string, len(urls))

	for i, url := range urls {
		g.Go(func() error {
			body, err := fetch(ctx, url)
			if err != nil {
				return fmt.Errorf("mirror %s: %w", url, err)
			}
			bodies[i] = body
			return nil
		})
	}

	if err := g.Wait(); err != nil {
		return nil, err
	}
	return bodies, nil
}
```

The closure captures `i` and `url` per iteration only when the module's `go` directive is 1.22
or newer; on 1.21 or lower every goroutine observes the last value of `url`. `[BLOG]`

## Fan-out that cannot fail

Use `sync.WaitGroup`. On Go 1.25 or newer call `wg.Go` — it counts the goroutine and releases it, so there is no `Add`/`Done` pair to get wrong. `[REL]`
```go
var wg sync.WaitGroup
for _, task := range tasks {
	wg.Go(task) // Go 1.25+: the Add/Done pair is gone
}
wg.Wait()
```

On Go 1.24 and older `wg.Go` does not exist: call `wg.Add(1)` before the `go` statement, never inside it, and `defer wg.Done()` inside. `go vet`'s `waitgroup` analyzer (Go 1.25+) reports a misplaced `Add`. `[GOOG]` `[REL]`
```go
var wg sync.WaitGroup
for _, task := range tasks {
	wg.Add(1) // before the go statement, never inside it
	go func() {
		defer wg.Done()
		task()
	}()
}
wg.Wait()
```

## Channels

The sender closes the channel, exactly once, when it has nothing more to send; a receiver never
closes a channel it did not create. Size a buffer for the burst you will hold in memory. Every
blocking send and receive selects on `ctx.Done()`. `[CRC]` `[UBER]`
```go
func Produce(ctx context.Context, source []int, out chan<- int) {
	defer close(out) // the sender closes, once
	for _, v := range source {
		select {
		case out <- v:
		case <-ctx.Done():
			return
		}
	}
}
```

## Shared state

Read-mostly state uses `sync.RWMutex`, otherwise `sync.Mutex`; a counter or flag uses
`sync/atomic`. Never hold a lock across a blocking call — a network round trip, a channel send,
a `ctx` wait: copy what you need out, unlock, then work. `[CRC]` `[GOOG]` `[LINT]`
```go
func (c *Cache) Get(key string) (string, bool) {
	c.mu.RLock()
	defer c.mu.RUnlock()
	v, ok := c.items[key]
	return v, ok
}
```

Use `sync.Pool` only when a profile shows allocation pressure. A pooled item may be removed at
any time without notice, so a pool never holds state that is still needed. `[CRC]` `[UBER]`

## Goroutine ownership

Every goroutine has a named owner and a stop condition — cancellation on `ctx.Done()`, or a
closed channel. One that outlives its request keeps that request's resources alive. `[CRC]`
`[UBER]`

## Leak detection

Run `go test -race ./...` on every change; add `goleak.VerifyTestMain(m)`. `[UBER]` `[LINT]`
```go
package worker_test

import "go.uber.org/goleak"

func TestMain(m *testing.M) {
	goleak.VerifyTestMain(m)
}
```

`goleak` proves a leak inside one test binary. Go 1.27's `goroutineleak` pprof profile reports the goroutines a running service leaked: goroutines blocked on a primitive that no runnable goroutine can unblock. Use both — the test asserts, the profile finds what escaped. `[REL]` `[UBER]`

## Timers

Go 1.23 made `time.Timer` channels unbuffered and Go 1.27 removed the `asynctimerchan` GODEBUG, so timer channels are always unbuffered now. A timer nobody references is collected, so the old leak worry is gone, but `time.After` inside a loop still allocates one timer per iteration — keep a `*time.Timer` and `Reset` it when the interval is fixed. A deadline that must reach the caller belongs in `context.WithTimeout`, not in a timer channel. `[REL]`

## Goroutines and the CPU limit

Since Go 1.25 the runtime reads the cgroup CPU limit of its container and updates `GOMAXPROCS` when that limit changes, so a container does not need `GOMAXPROCS` set by hand — and setting it to the node's CPU count defeats the limit. Kubernetes `limits.cpu` becomes the cgroup quota; `requests.cpu` does not. `[REL]`

## Message passing or shared state

| Situation | Choose |
|---|---|
| Ownership of a value transfers from one stage to the next | channel — the hand-off is the synchronisation |
| Several goroutines read and update the same state | mutex — a channel would rebuild a shared variable badly |
| One producer, many consumers | one channel per consumer, or a fan-out goroutine per consumer |
| A result is needed once, by one caller | a function call, not a channel |

Communicate when ownership moves; share with a lock when state persists. A channel
where a function call would do adds a goroutine, a buffer decision, and a shutdown path.
`[UBER]`

## Sources

| Tag | Source |
|---|---|
| [CRC] | Go Code Review Comments — https://go.dev/wiki/CodeReviewComments |
| [BLOG] | The Go Blog — https://go.dev/blog/ |
| [GOOG] | Google Go Style Guide — https://github.com/google/styleguide/blob/gh-pages/go/guide.md |
| [LINT] | golangci-lint linters — https://golangci-lint.run/docs/linters/ |
| [MOD] | Go Modules Reference — https://go.dev/ref/mod |
| [REL] | Go release notes — https://go.dev/doc/devel/release |
| [UBER] | Uber Go Style Guide — https://github.com/uber-go/guide/blob/master/style.md |
