# HTTP Semantics

**Load this reference when:** a status code, a response body shape, the error catalogue, a
required header, retry safety, caching, or a cross-origin question.

The status line carries the outcome. A `200` with an error flag is a defect whatever the body
says.

## Status codes

| Code | Use for |
|---|---|
| `200 OK` | Success with a body: `GET`, `PUT`, `PATCH`, and `POST` actions that return a result. |
| `201 Created` | A resource was created. **Carry `Location`, dereferenceable.** |
| `202 Accepted` | Work started, not finished: an asynchronous operation. **Carry `Location`** at the operation resource. |
| `204 No Content` | Success with no body: `DELETE`, or a `PUT` with nothing to return. No `Content-Type`, no body. |
| `304 Not Modified` | The client's copy is current; **no body**. |
| `400 Bad Request` | The request could not be parsed, or a parameter is malformed or cannot be turned into a value. |
| `401 Unauthorized` | Not authenticated: missing, expired or invalid credentials. **Carry `WWW-Authenticate`.** |
| `403 Forbidden` | Authenticated, but not allowed. Never used to hide a resource's existence. |
| `404 Not Found` | The resource does not exist — also the answer for one the caller may not know exists. |
| `405 Method Not Allowed` | The method is not supported here. **Carry `Allow`.** |
| `406 Not Acceptable` | `Accept` asks for a representation the API cannot produce. |
| `409 Conflict` | The request conflicts with *current server state*: a duplicate unique key, a forbidden transition. |
| `410 Gone` | Deliberately removed; do not retry. The body names the successor when one exists. |
| `412 Precondition Failed` | `If-Match` / `If-Unmodified-Since` did not hold. |
| `415 Unsupported Media Type` | The body's format is not one the endpoint accepts. |
| `422 Unprocessable Content` | The request parsed but a rule rejected a value, in the body or in a query parameter. |
| `428 Precondition Required` | The endpoint refuses an unconditional write to a stateful resource. |
| `429 Too Many Requests` | The caller exceeded the published limit. **`Retry-After` is REQUIRED.** |
| `451 Unavailable For Legal Reasons` | Withheld on legal grounds; the contract says whether it carries the error body. |
| `500 Internal Server Error` | Unexpected failure: log the detail, return a generic message. |
| `503 Service Unavailable` | Temporarily unavailable: overload, maintenance, a dependency down. **`Retry-After` is REQUIRED.** |

Redirects: `301`/`308` are permanent, `302`/`307` temporary; `307`/`308` preserve the method and
body, `303` answers with a `GET` at another URI. Never redirect an authenticated request to another
scheme. `304` is the one redirect a client does not follow.

A status not in this table is selected by its IANA meaning, and its required headers still apply.

## Required headers

| Status | Header | Why the client needs it |
|---|---|---|
| `201`, `202` | `Location` | The created resource, or the operation to poll. |
| `304` | `ETag` | The validator the client should keep using. |
| `401` | `WWW-Authenticate` | The challenge names how to authenticate. |
| `405` | `Allow` | The methods this resource supports. |
| `429`, `503` | `Retry-After` | When to retry. |
| `301`, `302`, `303`, `307`, `308` | `Location` | Where the request is being sent. |

`204` carries no body at all — not an empty JSON object, and no `Content-Type`; some clients reject
a `204` with a body.

The block below is the machine-readable copy of the table above; `scripts/validate.py` parses it
and fails a response that omits a listed header. Keep the two in step.

```yaml required-headers-vocabulary
"201": [Location]
"202": [Location]
"204": []
"301": [Location]
"302": [Location]
"303": [Location]
"304": [ETag]
"307": [Location]
"308": [Location]
"401": [WWW-Authenticate]
"405": [Allow]
"429": [Retry-After]
"503": [Retry-After]
```

## Similar codes

**`400` versus `422`.** `400` means the server could not turn the request into a value: malformed
JSON, a body that does not match the declared format, or a parameter that is missing, malformed, or
unparseable. `422` means the request parsed and a rule rejected a value — in the body or in a query
parameter: a required field is missing, a number is out of range, a sort key is not in the
allow-list. Tie-breaker: could the server produce a value at all? No → `400`. A value was produced
and a rule rejected it → `422`.

**`409` versus `412` versus `422`.** `409` is a conflict with *current server state* — a duplicate
unique key, a forbidden transition, an exhausted quota — and the client re-reads and retries with a
different value. `412` is a precondition the client asserted that did not hold — `If-Match` did not
match the current `ETag` — and the client re-reads and re-computes. `422` is a rule independent of
current state; retrying the same payload fails the same way. A duplicate email is `409`, not `412`
— the client asserted nothing about current state.

**`429` versus `503`.** `429` is the caller's rate exceeding the published quota; retrying at the
same rate reproduces it. `503` is the service's own capacity — overload, a dependency down, a
deployment. The tie-breaker is whose limit was hit.

## Success bodies

One body shape per API. The default is bare resources, not a universal envelope:

- **Single resource:** the resource's own fields at the top level.
- **Collection:** `{"data": [...], ...pagination fields}`. The array is always under `data`, and
  the pagination fields sit beside it. The shape is defined in [pagination](pagination.md).
- **No content:** `204`, with no body and no `Content-Type`.

```json
{
  "id": "42",
  "email": "ada@example.com",
  "display_name": "Ada Lovelace"
}
```

A client that receives a single resource never unwraps a wrapper. A collection always has room
for pagination state; a bare top-level array does not.

A `2xx` body carries the result, never a verdict on it. `error`, `errors` or `success` at the top
level of a `2xx` is the `200`-plus-error-flag defect in body form. A resource may legitimately have
a field named `status` — a user is `active` or `suspended` — so the field name alone is not an
error flag; the flag is the *member that reports the outcome*.

## Error bodies

The default is RFC 9457 Problem Details, served as `application/problem+json`. The stable identity
is `type`; `title`, `status`, `detail` and `instance` are advisory, and extension members carry
field-level detail.

```json
{
  "type": "https://identity.internal/problems/validation-error",
  "title": "Request validation failed",
  "status": 422,
  "detail": "The request body has one invalid field.",
  "errors": [
    { "pointer": "/display_name", "code": "invalid-value", "detail": "Must not be empty" }
  ]
}
```

The `wrapped` alternative puts a stable `code` and a `message` under an `error` object:

```json
{
  "error": {
    "code": "validation-error",
    "message": "Request validation failed",
    "details": [
      { "field": "email", "code": "invalid-value", "message": "Must be a valid email address" }
    ]
  }
}
```

One error format per API. A client that must ask "problem document or error object?" on every
failure has two formats.

### How an error reads

**Group the catalogue by cause** — validation, authentication, authorization, conflict, not found,
server — so a reader can predict a code from the situation. Grouping is a property of presentation,
not of the code's shape: an API whose codes are numeric still groups its catalogue by cause.

**A message is one plain sentence** that says what happened and, for a client error, what to do
next: `"the role referenced by role_id 9 does not exist"`, `"the request body is missing the
required field display_name"`. The code carries the class; the message carries the specifics. No
internal jargon, no stack text, no echoed payload, and no class prefix — `"not found: user 42"`
writes the taxonomy twice, once in the code and once in the prose. Drop the prefix and keep the
domain's words: `"user 42 does not exist"`.

## The error catalogue

One catalogue per API. Each code maps to exactly one HTTP status and exactly one meaning,
whatever shape the codes take.

| Code | Status | Meaning |
|---|---|---|
| `validation-error` | 422 | Request parsed; a value is missing or invalid. |
| `invalid-value` | 422 | A value does not match its rule. |
| `invalid-sort` | 422 | A requested sort key is not in the allow-list. |
| `invalid-cursor` | 400 | The cursor is malformed, expired, or bound to another sort or filter. |
| `missing-parameter` | 400 | A required query parameter is absent. |
| `bad-request` | 400 | The request could not be parsed. |
| `unsupported-media-type` | 415 | Body in a format the endpoint does not accept. |
| `unauthorized` | 401 | No usable credential presented. |
| `invalid-token` | 401 | Credential expired, malformed or invalid. |
| `forbidden` | 403 | Authenticated, but not permitted. |
| `not-found` | 404 | Absent, or the caller may not know it exists. |
| `method-not-allowed` | 405 | Method unsupported on this resource. |
| `conflict` | 409 | Conflicts with current state. |
| `precondition-failed` | 412 | `If-Match` / `If-Unmodified-Since` did not hold. |
| `precondition-required` | 428 | Conditional request required. |
| `rate-limit-exceeded` | 429 | Published limit exceeded. |
| `gone` | 410 | Deliberately removed. |
| `internal-error` | 500 | Unexpected server failure. |
| `service-unavailable` | 503 | Temporarily unavailable. |

Rules:

1. **One meaning per code, forever.** A new meaning gets a new code.
2. **Exactly one HTTP status per code.**
3. **A removed code is retired, not reused.**
4. **A domain code names the subject and the condition** (`invoice-already-paid`), allocated in
   one published order.
5. **Adding a code is additive; renaming or repurposing one is breaking** and needs a version bump.

## Content-Type and Content-Language

- `Content-Type` describes the body in this message; `Accept` asks for what the caller wants back.
- A language is never encoded in the media type: use `Content-Language: zh`.
- Error responses use `application/problem+json` for problem documents; the `wrapped` format
  keeps the success media type.
- A response that negotiates on `Accept` sends `Vary: Accept`; one that localizes `error.message`
  sends `Content-Language` and varies on `Accept-Language`.
- Every response with a body sends a `Content-Type`; without one, many clients read the body as
  `application/octet-stream`.

## Methods

`PUT` replaces the representation. `PATCH` is a family: `application/merge-patch+json` (RFC 7386)
merges a partial document, and `application/json-patch+json` (RFC 6902) applies operations in
order. The contract records the accepted media type and advertises it in `Accept-Patch`. The
`null` rules are in [conventions](conventions.md#methods-and-null).

`HEAD` answers wherever `GET` answers, with the same status and validators and no body. `OPTIONS`
exists only where meaningful: `Allow`, and `Accept-Patch` when `PATCH` exists.

## Asynchronous operations

Work that cannot finish inside the request is answered `202 Accepted` with a `Location` header
pointing at an **operation resource** — a first-class resource with its own identifier, route and
representation, read back with `GET`.

```http
HTTP/1.1 202 Accepted
Location: /v1/operations/op_8812
Retry-After: 2
Content-Type: application/json

{"id": "op_8812", "status": "running"}
```

The operation carries a `status` of `running`, `succeeded` or `failed`. A terminal state carries
the outcome: `result` holding the created or updated resource when `succeeded`, the recorded error
body when `failed`. A `202` is not replayable by default; an operation a client may retry needs an
`Idempotency-Key`.

## Retry safety

*Safe* means "does not change server state". *Idempotent* means "the effect of the second and
subsequent calls is the same as the effect of the first". `GET`, `HEAD` and `OPTIONS` are safe;
`GET`, `HEAD`, `OPTIONS`, `PUT` and `DELETE` are idempotent. `POST` and `PATCH` are not, unless the
contract supplies the mechanism that makes the repeat safe — an `Idempotency-Key`, or `If-Match`
for a state-changing write.

`POST` does not address a resource: sending the same `POST` twice creates two resources. `PUT` and
`DELETE` address a specific resource, so repeating them converges; the URL is the idempotency key.
`PATCH` sits between the two: use `If-Match` (the retry fails cleanly with `412` when the state
moved on) or an `Idempotency-Key` (the retry replays the original outcome).

## The Idempotency-Key header

`draft-ietf-httpapi-idempotency-key-header` is Standards-Track and **not yet an RFC**. This text
was written against revision **08** (October 2026); if the draft advances, keep the semantics and
update only the revision number.

```http
POST /v1/users HTTP/1.1
Idempotency-Key: "8e03978e-40d5-43e8-bc93-6894a57f9324"
Content-Type: application/json

{ "email": "ada@example.com", "display_name": "Ada Lovelace" }
```

- The value is a String Structured Header Field, so it is written in quotes.
- The client generates it: a UUID (RFC 9562) or an equally unpredictable random identifier.
- The key must be unique, and must never be reused with a different request payload.
- A key is scoped to `(principal, endpoint, tenant, key)`: the same value from two principals is
  two keys, and the same key in two tenants is two keys.
- A key is stored with a fingerprint of the request for a published TTL; a repeat with the same
  fingerprint replays the stored status, body and `Location`, and a different fingerprint is
  refused. The contract publishes the scope and the TTL (24 hours in the worked example).

| Situation | Response |
|---|---|
| First time — key and fingerprint unseen | Process normally; return and store the real response. |
| Retry after completion — key and fingerprint seen | Replay the stored status, body and `Location`. Never execute twice. |
| Retry while the original is in flight | `409 Conflict` with the recorded error body. |
| Key reused with a different payload | `422 Unprocessable Content` with an error body naming the conflict. |
| Key missing on an endpoint that requires one | `400 Bad Request`; the request is not processed. |

## Conditional requests

`ETag` is the stronger validator; `Last-Modified` is the coarser date form. A **strong** tag is
quoted with no prefix (`"u42-v3"`) and identifies the exact bytes; a **weak** tag carries `W/` and
promises only semantic equivalence. `If-Match` requires a strong tag, while `If-None-Match` and
cache revalidation accept the weak form.

A conditional read sends `If-None-Match`; when the client's copy is current, the server answers
`304 Not Modified` with no body, repeating the `ETag` and cache directives. A conditional write
sends `If-Match` with the tag it read; when the resource has changed, the server refuses with
`412 Precondition Failed` and the client re-reads. `If-None-Match: *` means "create it, but only if
it does not exist".

`428 Precondition Required` is the server-side policy of refusing an unconditional write: every
write must carry `If-Match`, and a write without one is answered `428` rather than applied blind.
That is what makes read-modify-write safe when more than one client writes the same resource.

## Caching

- **`no-store` for personal data.** A response carrying a token, a session identifier, or a
  personal document is `no-store` — not `private`, and not `no-cache`, which still permits storage.
- **`private` versus `s-maxage`.** `private` protects one client's response from a shared cache;
  `s-maxage` sets the lifetime a shared cache may use. A shared cache must not reuse a response to
  an authenticated request unless it carries `public`, `s-maxage` or `must-revalidate`.
- **State a lifetime.** A response carrying neither `Cache-Control` nor `Expires` invites heuristic
  freshness. A definite lifetime is `max-age`.
- **Vary on every header that selects a representation:** `Accept` when the API negotiates the
  format, `Accept-Encoding` when it serves compressed variants, and `Accept-Language` when it
  localizes the body. A private cache that stores an authenticated response discriminates with
  `Vary: Authorization`; a response carrying personal data is `no-store`.

## Cross-origin requests

Whether browsers call the API is the `cors` convention. When it is `not_used`, this section is
inert and the gate skips it; when it is `enabled`, the gate requires what follows.

- Answer the preflight with `OPTIONS`: `Allow`, and the `Access-Control-*` fields the API actually
  permits. Do not answer a preflight with a success status that omits them.
- **Never reflect an arbitrary `Origin` when credentials are allowed.** Name the permitted origins,
  send `Vary: Origin` on every response whose `Access-Control-Allow-Origin` depends on the request,
  and never combine `Access-Control-Allow-Credentials: true` with `*`.
- A cross-origin response that varies by `Origin` is a different representation; the cache key must
  say so.

## Framework-generated failures

A router-level `405`, a catch-all `404`, a body-parse `400`, or a size-limit `413` is produced
before the application's handler runs, yet it is still a response of this API. **Every error
response uses the recorded error body**: a `405` with a bare status line and no body is a defect.
The same applies to the body parser's `415` on operations that accept a request body.
