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

Use `sync.WaitGroup`, and put `wg.Add(1)` before the `go` statement, never inside the
goroutine. `[GOOG]`
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
| [UBER] | Uber Go Style Guide — https://github.com/uber-go/guide/blob/master/style.md |
