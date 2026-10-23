# Authentication and Authorization

**Load this reference when:** a credential, an authorization check, tenant derivation, enumeration
resistance, or a rate limit.

## The order of the checks

Every protected endpoint runs the same checks:

1. **Authenticate** — who is the caller? Failure → `401 Unauthorized` with a
   `WWW-Authenticate` challenge.
2. **Resolve the tenant and the resource** within that tenant. Absence → `404 Not Found`.
3. **Authorize the action** — may this caller perform this operation on this resource? Failure →
   `403 Forbidden`, or `404 Not Found` when the caller may not know the resource exists.

Authorization is checked after authentication, never instead of it: "may this principal delete
this order?" cannot be answered before the principal is known. Skipping authentication because
"the endpoint is internal" turns a missing credential into a `403` that hides the misconfiguration.

## The credential

The credential travels in the registered `Authorization` field:

```http
GET /v1/users
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

`Bearer` comes from the IANA HTTP Authentication Scheme Registry. A key or a custom token uses a
scheme token in the same field: `Authorization: ApiKey sk_live_abc123`. Where no registered scheme
fits, declare a local scheme name in `Authorization`, record `auth_scheme: local_scheme` in the
conventions block, and name the token in that axis's `notes` entry. A credential never goes in a
private header; the retired spellings are in
[conventions](conventions.md#headers-not-to-invent).

## The WWW-Authenticate challenge

`401` without `WWW-Authenticate` tells the client nothing about how to authenticate; every `401`
carries it:

```http
HTTP/1.1 401 Unauthorized
WWW-Authenticate: Bearer realm="api", error="invalid_token", error_description="The access token expired"
Content-Type: application/problem+json
```

The parameters follow RFC 6750: `realm` may scope the protection, `error` is one of
`invalid_request`, `invalid_token`, `insufficient_scope`, and `error_description` carries
human-readable text. Never put an internal detail in `error_description`. For another scheme, name
that scheme in the challenge.

A valid token that lacks a required scope is `403 Forbidden` with
`WWW-Authenticate: Bearer realm="api", error="insufficient_scope"`: the credential authenticated
the caller, but the authorization check failed.

## Hiding a resource

A resource the caller may not know exists answers `404`, not `403` — the same status and body as
one that exists nowhere — because `403` admits the identifier exists and turns a read endpoint
into a directory of another tenant's users.

```http
GET /v1/role_policy_bindings/778
Authorization: Bearer <token of a different principal>

HTTP/1.1 404 Not Found
Content-Type: application/problem+json

{
  "type": "https://identity.internal/problems/not-found",
  "title": "Resource not found",
  "status": 404,
  "detail": "role_policy_binding 778 does not exist"
}
```

A caller who is authenticated but lacks a role gets `403` when the resource's existence is not the
question:

```http
DELETE /v1/users/42
Authorization: Bearer <token without the admin role>

HTTP/1.1 403 Forbidden
Content-Type: application/problem+json

{
  "type": "https://identity.internal/problems/forbidden",
  "title": "Forbidden",
  "status": 403,
  "detail": "this operation requires a different role"
}
```

A policy that does not exist **denies** the action; an unmatched (resource, action) pair is never a
default-allow.

## Tenant scoping

The tenant comes from the credential, never from a client-supplied identifier. Resolve the
principal, bind its tenant to the request context, and run every query with it as a predicate — in
the query, not a response filter, so `total` counts only the caller's rows and a filter bug cannot
become a cross-tenant read.

A scope the request supplies — path segment, query parameter, body field — is a *claim about* the
tenant, never the tenant: compare it with the derived value, answer `404` on a mismatch with the
body of a resource that exists nowhere, and overwrite the context with the derived tenant. A caller
entitled to several tenants gets the authorised scope, never its literal value. A cursor is not a
scope: it says where to continue, not which tenant may, and never encodes a tenant or permission.

Privileged operator access reaches past tenant scope, so it takes its own check, recorded with the
endpoint: the operator's role, the tenant being addressed, and the audit entry the call writes.

## Enumeration resistance

An endpoint acting on a user-supplied identity — a password reset, an account lookup — must not
reveal whether the account exists:

```http
POST /v1/password_reset
Content-Type: application/json

{ "email": "ada@example.com" }
```

```http
HTTP/1.1 200 OK
Content-Type: application/json

{ "message": "if the account exists, a reset message has been sent" }
```

The body is identical whether or not the account exists and carries no field whose presence
depends on the answer. The work is internal, so `200`, not `202`: there is no operation resource
to poll. The miss path must cost the same as the hit path: an instant miss leaks existence through
timing even though the body does not.

## Rate limiting

The decision, in order:

1. **Pick a limit** — a quota and a window, from the capacity the API actually has.
2. **Publish it** — the limit, the window, and what happens when it is exceeded.
3. **Key it** — per API key for machine callers, per user for end users, per IP for anonymous
   traffic; say which, because "per IP" punishes users behind a shared NAT.
4. **Answer an exceeded limit with `429`**, the REQUIRED `Retry-After` header (also required on
   `503`), and the recorded error body.

```http
HTTP/1.1 429 Too Many Requests
Retry-After: 60
RateLimit-Policy: "default";q=100;w=60
RateLimit: "default";r=0;t=60
Content-Type: application/problem+json

{
  "type": "https://identity.internal/problems/rate-limit-exceeded",
  "title": "Too many requests",
  "status": 429,
  "detail": "rate limit exceeded, try again in 60 seconds"
}
```

A published remaining count is not a guarantee. Emit the IETF field set
(`draft-ietf-httpapi-ratelimit-headers-11`, Standards-Track, not yet an RFC):
`RateLimit-Policy: "default";q=100;w=60` states the quota and window, and
`RateLimit: "default";r=50;t=30` states the remaining count and reset. The contract states the
limit, the window, the partition key, and that an intermediary may tighten them.
