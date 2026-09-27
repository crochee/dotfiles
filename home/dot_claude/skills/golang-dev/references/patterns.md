# Go Patterns Reference

**Load this reference when:** writing Go code, handling errors, designing APIs.

## Error Handling

### Sentinel Errors

```go
var (
    ErrNotFound = errors.New("resource not found")
    ErrInvalidInput = errors.New("invalid input")
)
```

### Wrapping Errors

```go
if err != nil {
    return nil, fmt.Errorf("load config %s: %w", path, err)
}
```

### Checking Errors

```go
if errors.Is(err, ErrNotFound) { ... }
var ve *ValidationError
if errors.As(err, &ve) { ... }
```

## Interfaces

### Define Where Consumed

```go
type UserStore interface {
    GetUser(id string) (*User, error)
    SaveUser(user *User) error
}
```

## Concurrency

### Context Propagation

```go
func FetchWithTimeout(ctx context.Context, url string) ([]byte, error) {
    ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
    defer cancel()
    req, _ := http.NewRequestWithContext(ctx, "GET", url, nil)
    // ...
}
```

### errgroup

```go
g, ctx := errgroup.WithContext(ctx)
for _, url := range urls {
    g.Go(func() error {
        return fetch(ctx, url)
    })
}
if err := g.Wait(); err != nil { return err }
```

## Structs

### Functional Options Pattern

```go
type Option func(*Server)

func WithTimeout(d time.Duration) Option {
    return func(s *Server) { s.timeout = d }
}
```

## Sync Primitives

| Primitive | Use |
|-----------|-----|
| `sync.Mutex` | Shared mutable state |
| `sync.WaitGroup` | Goroutine coordination |
| `sync.Pool` | Frequent allocations |
| `sync.Once` | One-time initialization |

## Best Practices

- Accept interfaces, return structs
- Small interfaces (1-3 methods)
- Context as first parameter
- Error wrapping with `%w` for context
- Use slices over maps for iteration
- Preallocate with `make([]T, 0, capacity)` when size known
- Use `strings.Builder` for string concatenation