**Load this reference when:** the change touches an HTTP server or client: timeouts, shutdown, routing, middleware, the tokens it issues, or the listener address.

## The four timeouts

A server without timeouts is a denial-of-service target: a slow client holds a connection open
forever, and one connection per client is enough to exhaust the process. Every `http.Server`
sets all four. `[SEC]` `[CRC]` `[UBER]`
```go
srv := &http.Server{
	Addr:              ":8080",
	Handler:           mux,
	ReadHeaderTimeout: 5 * time.Second,
	ReadTimeout:       30 * time.Second,
	WriteTimeout:      30 * time.Second,
	IdleTimeout:       120 * time.Second,
}
```

| Field | Covers | Consequence of leaving it zero |
|---|---|---|
| `ReadHeaderTimeout` | the request line and headers | a client that sends headers one byte at a time holds the connection open (Slowloris) |
| `ReadTimeout` | headers plus the whole body | a body that trickles in never ends |
| `WriteTimeout` | the whole handler, headers included | a slow handler writes forever |
| `IdleTimeout` | a kept-alive connection between requests | idle connections accumulate until the file descriptor limit |

`ReadTimeout` and `WriteTimeout` are absolute deadlines from the start of the request, not
idle timeouts: a handler that legitimately needs longer must move the deadline onto its own
context. `WriteTimeout` also covers the whole handler, so a long-lived stream — SSE, a
websocket upgrade — cannot rely on it; those need their own deadline management. `IdleTimeout`
is the only one of the four that a zero value leaves unlimited on purpose.

`http.ListenAndServe` and `http.ListenAndServeTLS` create a `Server` with every timeout left
at zero. A service reachable from the public internet must not use them; construct the
`http.Server` explicitly. `[SEC]`

## Graceful shutdown

A container receives `SIGTERM` and then, after a grace period, `SIGKILL`. The server has to
stop accepting connections, let the in-flight requests finish, and exit inside that window. `[SEC]` `[CRC]` `[DOC]`
```go
ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
defer stop()

srv := &http.Server{Addr: ":8080", Handler: mux, /* the four timeouts */ }

go func() {
	if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
		log.Fatalf("listen: %v", err)
	}
}()

<-ctx.Done()

shutdownCtx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
defer cancel()
if err := srv.Shutdown(shutdownCtx); err != nil {
	// The grace period expired: drop the connections that are still open.
	srv.Close()
	log.Printf("shutdown: %v", err)
}
```

`Shutdown` stops accepting new connections, waits for the active ones to return, and returns
`context.DeadlineExceeded` if the deadline passes first — it does not force the connections
closed. `Close` does that, at the cost of aborting the in-flight requests.

A hijacked connection — a websocket, an `http.Hijacker` upgrade — is no longer the server's
to close: `Shutdown` does not wait for it and does not close it. The upgrade path owns that
connection's lifetime and must close it itself in the same shutdown branch. `[DOC]`

`signal.NotifyContext` has been available since Go 1.16. Registering the signals also stops
the default behaviour: the second `SIGTERM` is delivered to the context, not to the process,
so a stuck shutdown can be forced with a second signal or by the orchestrator.

## The request context

`r.Context()` is cancelled when the client disconnects or the handler returns. Pass it down;
never store it in a struct field. Report the failure to the client as a status code and keep
the detail in the log, not in the response body. `[CRC]` `[DOC]` `[EFF]`
```go
func handler(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	rows, err := store.List(ctx, r.PathValue("id"))
	if err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	// …
}
```

`http.Server.BaseContext` sets the root context every request derives from — the place to
put a process-wide value such as a logger. `http.Server.ConnContext` attaches a value to a
single connection, which is the right granularity for a per-connection id. Neither replaces
`r.Context()` for cancellation.

## Routing and middleware

`http.ServeMux` has pattern routing since Go 1.22: a method, a wildcard path, and a host
pattern, with no third-party router. `[GOOG]` `[DOC]`
```go
mux := http.NewServeMux()
mux.HandleFunc("GET /items/{id}", getItem)
mux.HandleFunc("POST /items", createItem)
mux.HandleFunc("GET /items/{id}/parts/{part}", getPart)
mux.HandleFunc("GET /api.example.com/items", apiItems) // host pattern
mux.HandleFunc("/", root)                             // {$} matches only "/"
```

`r.PathValue("id")` reads the captured segment. A wildcard matches one path segment;
`{rest...}` matches the rest of the path. The pattern `{$}` anchors to the end of the path,
so `"/"` matches the root only and not every unmatched path.

A middleware is a function that takes a handler and returns a handler:
```go
func withLogging(log *slog.Logger, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		next.ServeHTTP(w, r)
		log.InfoContext(r.Context(), "request", slog.String("path", r.URL.Path), slog.Duration("took", time.Since(start)))
	})
}
```

A middleware that wraps `http.ResponseWriter` must implement `Unwrap() http.ResponseWriter`
(Go 1.20+). Without it, `http.ResponseController` cannot reach the underlying writer, and
`Flush` and `Hijack` stop working for every handler behind the middleware. `[DOC]`
```go
type gzipWriter struct {
	http.ResponseWriter
	gz *gzip.Writer
}

func (w *gzipWriter) Unwrap() http.ResponseWriter { return w.ResponseWriter }

func (w *gzipWriter) Write(p []byte) (int, error) { return w.gz.Write(p) }
```

## Tokens and identifiers

Every token, session id, password reset link and api key comes from `crypto/rand`. `math/rand`
is not a cryptographic generator: its internal state can be recovered from a handful of
observed outputs, so a token it produced is predictable by anyone who has seen one. `[SEC]` `[DOC]`
```go
// An opaque token: at least 128 bits of entropy, RFC 4648 base32.
token := rand.Text()

// Raw bytes: base64url, no padding.
buf := make([]byte, 32)
if _, err := rand.Read(buf); err != nil {
	return err
}
raw := base64.RawURLEncoding.EncodeToString(buf)
```

`crypto/rand.Text` has been available since Go 1.24 and returns at least 128 bits of
randomness. Go 1.27's `uuid` package generates and parses UUIDs (`uuid.New`, `uuid.NewV4`,
`uuid.NewV7`, `uuid.Parse`) with a cryptographically secure source; a v4 UUID carries 122
random bits in a fixed shape, which is not the same thing as an opaque bearer token. `[REL]`

`math/rand` is fine for a jitter, a load-balancing tie-break or a test fixture. It is not
fine for anything an attacker can guess.

## The listener address

`net.JoinHostPort` puts the host and the port together correctly. `fmt.Sprintf("%s:%d", host,
port)` does not: it produces `::1:8080` for an IPv6 literal, which is not an address. Since
Go 1.25 `go vet`'s `hostport` analyzer reports it as `address format "%s:%d" does not work
with IPv6`. `[CRC]` `[DOC]`
```go
addr := net.JoinHostPort(host, strconv.Itoa(port)) // "[::1]:8080"
```

## TLS

`http.Server` has no certificate field: TLS is the server's job, not the handler's.
`srv.ListenAndServeTLS(certFile, keyFile)` loads the certificate and key from disk, and
`TLSConfig` carries the rest — the minimum version, the cipher suites, the client
certificate policy. `[SEC]` `[DOC]`
```go
srv.TLSConfig = &tls.Config{
	MinVersion: tls.VersionTLS13,
}
err := srv.ListenAndServeTLS("/certs/tls.crt", "/certs/tls.key")
```

A service behind a proxy that terminates TLS keeps the hop to the backend in plain HTTP, and
that hop is where the four timeouts and the shutdown path still apply. `X-Forwarded-For` and
friends are the proxy's to set; a backend that trusts them without a trusted proxy in front
is trusting the client.

## Sources

| Tag | Source |
|---|---|
| [CRC] | Go Code Review Comments — https://go.dev/wiki/CodeReviewComments |
| [DOC] | Standard library docs — https://pkg.go.dev/ |
| [EFF] | Effective Go — https://go.dev/doc/effective_go |
| [GOOG] | Google Go Style Guide — https://github.com/google/styleguide/blob/gh-pages/go/guide.md |
| [REL] | Go release notes — https://go.dev/doc/devel/release |
| [SEC] | Go Security Best Practices — https://go.dev/doc/security/best-practices |
| [UBER] | Uber Go Style Guide — https://github.com/uber-go/guide/blob/master/style.md |
