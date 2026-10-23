# Conventions

**Load this reference when:** a recorded convention axis, the Conventions block, a private
request header, or PATCH and null semantics.

A convention is a decision an API makes once, writes down, and applies everywhere. There is no
universal best spelling: `snake_case` paths with a slug code and a wrapped error body is as
defensible as `kebab-case` paths with a problem document. What separates a good API is that it
picked one, recorded it, and applied it without exception — two values for one axis is an
inconsistency, never a style violation.

## The twelve axes

Twelve axes cover the stylistic choices in an HTTP contract. Each row gives the recommended
default, the other accepted tokens, and what the contract records.

| Axis | Default | Other tokens | Record |
|---|---|---|---|
| `path_casing` | `kebab-case` | `snake_case` | The casing rule and one example path |
| `field_casing` | `snake_case` | `camelCase` | The casing rule and one example body |
| `error_format` | `problem_json` | `wrapped` | The exact error body, and the catalogue it uses |
| `pagination` | `cursor` | `offset` | The one strategy for the API |
| `page_size_param` | `limit` | `per_page` | The parameter's name; the response member matches it |
| `filter_syntax` | `named` | `bracket` | The syntax and one example |
| `version_placement` | `path` | `header`, `media_type`, `date` | The scheme and the version identifier |
| `auth_scheme` | `oauth_bearer` | `api_key`, `mtls`, `dpop`, `local_scheme`, `none` | The one scheme accepted, and how it is presented |
| `tenant_scoping` | `credential` | `path`, `query` | The model, and the claim the tenant arrives in |
| `datetime_format` | `rfc3339_utc` | `rfc3339_offset`, `epoch_seconds` | The format and the zone |
| `nullable_semantics` | `absent` | `explicit_null`, `sentinel` | The rule, and the field classes it applies to |
| `cors` | `not_used` | `enabled` | Whether browsers call the API, and the permitted origins |

The token set in each row is closed. A value outside it is a defect: two spellings may read alike.
`not_used` is legal for every axis and needs no `notes` entry — an API with no timestamps records
`datetime_format: not_used`; an absent key reads like an oversight. The one exception is
`pagination`: an API with any collection cannot record `not_used`, because every collection
paginates from v1.

A value that differs from the default is a departure: it needs a `notes` entry naming the axis
and giving the reason. A value that equals the default needs none.

## The page-size numbers

`page_size_param` records the parameter's *name*. Two integers beside it record the size; they are
not axes, because their values are not tokens.

| Key | Recommended | Rule |
|---|---|---|
| `page_size_default` | `50` | Applied when the parameter is absent; never above the maximum. |
| `page_size_max` | `500` | Rejected above with `422`; never below `1`. |

`500` is a recommendation, not a fence. A smaller maximum is legal and sometimes right — rows that
carry a large document cannot be served five hundred at a time — but it is a departure: it needs a
`notes` entry naming `page_size_max` and giving the reason. A hundred is the number a default
cap lands on when nobody chose one, and it turns a thousand-row export into twenty round trips.

The recorded numbers and the parameter schema must agree. The gate reads both from the document and
fails them when they differ, so the maximum has one owner per layer: the design record states it,
the schema publishes it, and they are checked against each other.

## Recording template

The contract embeds these fixed keys in its `Conventions` section; each value is its own choice.

```yaml
path_casing: kebab-case
field_casing: snake_case
error_format: problem_json
pagination: cursor
page_size_param: limit
page_size_default: 50
page_size_max: 500
filter_syntax: named
version_placement: path
auth_scheme: oauth_bearer
tenant_scoping: credential
datetime_format: rfc3339_utc
nullable_semantics: absent
cors: not_used
header_fields: []
notes: []
```

`header_fields` holds the private request-header fields the API defines, each with the reason no
registered field carries the information:

```yaml
header_fields:
  - name: X-Deployment-Channel
    reason: Selects a deployment channel that no registered field carries; it is
      application data that must not appear in a cache key.
```

An empty list is healthy; an unrecorded private field is a defect.

`notes` holds every departure, with its reason. A differing axis names the axis in `axis` — and so
does a page-size integer, which is recorded beside the axes rather than among them. A fact with no
axis — a second auth scheme, an enum's openness — names it in `subject`.

```yaml
notes:
  - axis: pagination
    reason: Every collection is bounded and the admin console needs page numbers.
  - axis: page_size_max
    reason: A user row carries an avatar blob, so a page above 100 is not servable.
  - subject: second_auth_scheme
    reason: A machine caller on the partner integration uses an API key; bearer is primary.
  - subject: users.role_policy_binding.status
    reason: The enum is open — a client must tolerate a status it does not know.
```

## The gate reads this file

The block below is the machine-readable copy of the rules above; `scripts/validate.py` parses it
and checks the document's `x-conventions` against it. The table above is for the reader, this block
is for the gate — keep the two in step. A fenced `yaml <marker>` block is the marker.

```yaml conventions-vocabulary
axes:
  path_casing: {default: kebab-case, tokens: [kebab-case, snake_case]}
  field_casing: {default: snake_case, tokens: [snake_case, camelCase]}
  error_format: {default: problem_json, tokens: [problem_json, wrapped]}
  pagination: {default: cursor, tokens: [cursor, offset]}
  page_size_param: {default: limit, tokens: [limit, per_page]}
  filter_syntax: {default: named, tokens: [named, bracket]}
  version_placement: {default: path, tokens: [path, header, media_type, date]}
  auth_scheme: {default: oauth_bearer, tokens: [oauth_bearer, api_key, mtls, dpop, local_scheme, none]}
  tenant_scoping: {default: credential, tokens: [credential, path, query]}
  datetime_format: {default: rfc3339_utc, tokens: [rfc3339_utc, rfc3339_offset, epoch_seconds]}
  nullable_semantics: {default: absent, tokens: [absent, explicit_null, sentinel]}
  cors: {default: not_used, tokens: [not_used, enabled]}
integers:
  page_size_default: {recommended: 50, minimum: 1}
  page_size_max: {recommended: 500, minimum: 1}
```

## Headers not to invent

A private request header exists only when no registered field carries the information. The names
below are retired; use the registered field instead.

| Private field | Use instead | Why |
|---|---|---|
| `X-API-Key` | `Authorization: <scheme> <token>` | A registered field with a registered scheme token; see [auth](auth.md). |
| `X-Request-Id` | `traceparent` / `tracestate` | W3C Trace Context already carries a trace id and vendor state. |
| `X-Tenant-Id` | The tenant claim in the credential, or a tenant path segment | Tenant scope is identity, carried in a standard field; a caller-asserted header can be rewritten. |
| `X-Forwarded-For`, `X-Forwarded-Host`, `X-Forwarded-Proto`, `X-Real-IP` | `Forwarded` | RFC 7239 carries client address, host and protocol in one registered field. |
| `X-Idempotency-Key` | `Idempotency-Key` | The unprefixed spelling is the draft's field name; `X-` makes it a different, unregistered field. |
| `X-Feature-Flag`, `X-Experiment-*` | A query parameter or a request-body field | Feature selection is application data; a header leaks into every proxy log and cache key. |
| `X-Client-Id`, `X-Correlation-Id`, `X-Session-Id` | `traceparent` / `tracestate`, or a body field | One correlation identifier, carried in a registered field. |

A Standards-Track draft field is not a private field. The test is not "is it prefixed `X-`" but
"does a registry or current draft already carry this name"; such a field is named with its draft
revision and is no `header_fields` entry.

## Methods and null

`PUT` replaces the representation, so a member the request omits is gone. `PATCH` is a family, and
`Content-Type` says what the body means: `application/merge-patch+json` (RFC 7386) merges a partial
document — an omitted member is left alone, a `null` member is **removed**;
`application/json-patch+json` (RFC 6902) applies `add`/`remove`/`replace`/`move`/`copy`/`test` in
order. The contract records the accepted media type; the server advertises it in `Accept-Patch`.

That `null` collides with `nullable_semantics`, so the contract states one: `null` deletes the
member, or a `null` for a held member is refused with `422`.

`HEAD` answers wherever `GET` answers, with the same status and validators and no body. `OPTIONS`
exists only where meaningful: `Allow`, and `Accept-Patch` when `PATCH` exists.

## Changing a convention

Changing a recorded value is breaking, with a version bump and a migration note (see
[versioning](versioning.md)). Adding a new axis value is a new decision, not a change to an
existing one.
