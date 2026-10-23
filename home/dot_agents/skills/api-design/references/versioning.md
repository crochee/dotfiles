# Versioning and Deprecation

**Load this reference when:** version placement, an additive-versus-breaking call, an enum's
openness, a breaking-change diff, or a deprecation and sunset.

## Version placement

The placement is the `version_placement` convention. **Path versioning is the default** —
`/v1/users` — unless there is a specific reason not to: it is the only placement a path-prefix
router can act on, and each version has its own cache key by construction.

- **Media type** (`Accept: application/vnd.example.v2+json`) keeps the URL stable but fragments the
  CDN cache on `Vary: Accept` and silently serves the old representation on a wrong `Accept`.
- **Header** (`X-API-Version: 2`) is invisible in a log line and in a bookmark; it is a private
  field and must be recorded in `header_fields` with its reason.
- **Date** (`?version=2024-06-01`) forks every later version and is easy to drop from a cached URL.

Never mix two schemes in one API. The URL segment (`/v1`) names the contract revision a client
pins; `info.version` names the revision of the document. They move independently: a documentation
fix bumps `info.version` alone, a breaking change bumps both.

## Additive versus breaking

**Additive** — ships in the current version:

- A new endpoint.
- A new optional request parameter.
- A new field in a response.
- A new member in an open enum, or in a request enum.

An additive change is safe only if clients tolerate unknown fields: one that rejects them, or
validates against a closed schema, breaks on a new field — until such clients are fixed, the new
field is breaking. Check before shipping.

**Breaking** — requires a new version:

- A field is removed or renamed.
- A field's type changes, or a field becomes nullable.
- A request parameter becomes required, or its accepted values narrow.
- A response enum loses or renames a member, or gains one a closed client enum rejects.
- A request enum loses or renames a member a client may send.
- A URL, a path parameter, or the pagination scheme changes.
- The authentication method or the required scope changes.
- An error code is renamed, removed, or reused for a different meaning.
- The response body shape changes — a bare resource becoming a `data` envelope, or the reverse.

**Pagination is not a later change.** Adding it later changes every existing client's response, so
a collection paginates from the first release; the [pagination reference](pagination.md) owns the
rule.

## Enum evolution

An enum's openness is a recorded decision: **open** — clients MUST tolerate a member they do not
know — or **closed** — clients MUST reject one. It is a `notes` entry whose `subject` names the
enum and whose `reason` says it is open; an enum with no note is closed.

A member added to an **open** enum is not breaking — the client ignores it. A member added to a
**closed** enum is breaking. A **response** enum that loses or renames a member is breaking; a
**request** enum that loses or renames a member a client may send is breaking. A member added to a
request enum is additive, and the server must accept it. The error catalogue is open: a client must
tolerate a code it does not know.

## Machine-checked breaking-change detection

A list of breaking changes in a release note is a claim; a diff between two published OpenAPI
documents is a proof. Run it in CI:

```console
oasdiff breaking --fail-on ERR openapi.v1.yaml openapi.v2.yaml
```

Without `--fail-on ERR` the command **always exits `0`**, whatever it finds. The tool enforces its
own ruleset, not the list above: it reports a removed endpoint, a removed response, a removed or
renamed property, a changed property type, a new required request parameter, a removed enum value,
and a value added to a response enum. What the diff cannot see, the reviewer must judge: the error
catalogue and error-body shape, and the retirement of an error code.

## Version lifecycle

1. Start at `/v1/`. Keep it until a breaking change forces `/v2/`.
2. Keep at most two active versions: the current one and the previous one.
3. Announce the break, ship the deprecation headers, migrate consumers during the notice period,
   and answer the old version with `410 Gone` after the sunset date.

## The deprecation headers

RFC 9745 defines `Deprecation` as an Item Structured Header Field: a Date in structured-fields `@`
form, seconds since the Unix epoch.

```http
HTTP/1.1 200 OK
Deprecation: @1767225600
Sunset: Fri, 01 Jan 2027 00:00:00 GMT
Link: <https://identity.internal/docs/deprecation>; rel="deprecation"; type="text/html"
Link: </v2/users>; rel="successor-version"
```

- `Deprecation` — a timestamp (`@1767225600`), never the obsolete `Deprecation: true` form.
- `Sunset` — RFC 8594, in HTTP-date format (not `@`), and **not earlier than** `Deprecation`.
- `Link: ...; rel="deprecation"` — the human-readable documentation: what is deprecated, why, and
  what replaces it.
- `Link: ...; rel="successor-version"` — the successor version.

Both link relations belong in the same response. A retired error code is announced the same way:
it stays in the catalogue with its retirement date, never deleted, and the endpoints that can
return it carry `Deprecation` and `Sunset`.

The header is a hint, not a promise: the resource works until the sunset date.

## After the sunset date

```http
HTTP/1.1 410 Gone
Content-Type: application/problem+json

{
  "type": "https://identity.internal/problems/gone",
  "title": "Version sunset",
  "status": 410,
  "detail": "this API version has been sunset; use /v2/users instead"
}
```

Answer a sunset version with `410 Gone` and the successor in the error body; the `410` meaning is
stated in the [HTTP semantics reference](http-semantics.md#status-codes).

## Migration guide

1. **Announce** — at least six months before the sunset date for a public API, at least three
   months for a partner API, and at least one month for an internal API. The contract publishes the
   period, and the sunset date never falls inside it. Publish the successor version, send the
   deprecation headers on every response of the old version, and publish the migration guide.
2. **Migrate** — during the notice period: update client code, run both versions in parallel and
   compare responses, and contact the consumers still on the old version.
3. **Sunset** — after the sunset date: answer the old version with `410 Gone` and the successor,
   and archive the old documentation with a link to the successor.
