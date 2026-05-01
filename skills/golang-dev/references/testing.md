# Go Testing Reference

**Load this reference when:** writing Go tests, understanding test patterns.

## Table-Driven Tests

```go
func TestAdd(t *testing.T) {
    tests := []struct {
        name     string
        a, b     int
        expected int
        wantErr  bool
    }{
        {"positive", 2, 3, 5, false},
        {"zero", 0, 0, 0, false},
        {"negative", -1, -1, -2, false},
        {"overflow", math.MaxInt, 1, 0, true},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := Add(tt.a, tt.b)
            if tt.wantErr {
                if err == nil {
                    t.Error("expected error")
                }
                return
            }
            if got != tt.expected {
                t.Errorf("Add(%d, %d) = %d; want %d", tt.a, tt.b, got, tt.expected)
            }
        })
    }
}
```

## Mocking

```go
type MockStore struct {
    GetFunc func(id string) (*User, error)
}

func (m *MockStore) Get(id string) (*User, error) {
    return m.GetFunc(id)
}
```

## Benchmarks

```go
func BenchmarkProcess(b *testing.B) {
    data := genData(1000)
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        Process(data)
    }
}

func BenchmarkProcessParallel(b *testing.B) {
    data := genData(1000)
    b.RunParallel(func(pb *testing.PB) {
        for pb.Next() {
            Process(data)
        }
    })
}
```

## Fuzzing

```go
func FuzzParse(f *testing.F) {
    f.Add(`{"key":"value"}`)
    f.Fuzz(func(t *testing.T, input string) {
        _, err := Parse(input)
        if err != nil {
            t.SkipNow()
        }
    })
}
```

## HTTP Handler Tests

```go
func TestHandler(t *testing.T) {
    req := httptest.NewRequest("GET", "/users/123", nil)
    rr := httptest.NewRecorder()
    Handler(rr, req)

    if rr.Code != http.StatusOK {
        t.Errorf("expected %d, got %d", http.StatusOK, rr.Code)
    }
}
```

## Test Helpers

```go
func testutil.WaitFor condition func() bool, opts ...option

// Common patterns:
testutil.WaitFor(func() bool { return len(items) > 0 }, testutil.WithTimeout(5*time.Second))
```

## Running Tests

| Command | Purpose |
|--------|---------|
| `go test ./...` | Run all tests |
| `go test -v` | Verbose output |
| `go test -run TestName` | Run specific test |
| `go test -bench=.` | Run benchmarks |
| `go test -cover` | Show coverage |
| `go test -race` | Race detector |
| `go test -fuzz=FuzzTest` | Fuzzing |

## Coverage

```bash
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```