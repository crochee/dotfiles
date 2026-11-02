---
name: api-design
description: "Produces a reviewable REST or OpenAPI 3.1 contract: resources, status codes, errors, pagination, auth, versioning. Use when designing or reviewing an HTTP API, choosing a pagination scheme, or writing the OpenAPI document. Not for OAuth/OIDC, webhooks, GraphQL, gRPC or SOAP. 中文：设计或评审 REST/OpenAPI 契约、分页、错误码、版本。"
license: MIT
metadata:
  version: "1.1.0"
---

# API Design

Produce a reviewable HTTP contract: resources, conventions, HTTP semantics, cursor pagination,
auth, versioning, and the OpenAPI 3.1 document. Worked contract:
[`examples/identity-openapi.yaml`](examples/identity-openapi.yaml).

## When to Use

- Designing or reviewing a REST or OpenAPI 3.1 HTTP API contract.

Out of scope: OAuth/OIDC, webhooks, files, batches, streams, probes, metrics, implementation. Not
for GraphQL, gRPC or SOAP.

## Workflow

Settle first: resource model, credential type, tenant source, version placement. With no user,
record numbered assumptions.

1. **Model resources and vocabulary.** One resource or action per endpoint; one term per concept.
   → `references/design.md`
2. **Record one value per convention axis, plus the page-size integers.** `not_used` where the API
   has no such concern; every collection still paginates. Departures go in `notes`.
   → `references/conventions.md`
3. **Choose statuses, bodies, errors, headers, retries, and caching.**
   → `references/http-semantics.md`
4. **Paginate every collection with one strategy.** Default: cursor. → `references/pagination.md`
5. **Label every endpoint; derive the tenant from the credential.** → `references/auth.md`
6. **Classify additive vs breaking; a break needs a version bump and migration note.**
   → `references/versioning.md`
7. **Emit the OpenAPI 3.1 document and run the gate.** → `references/openapi.md`

## Pagination at a Glance

Cursor, whole API, from v1:

- `limit` plus an opaque `cursor`; `sort` from an allow-list ending in a unique tie-breaker.
- Recommended **default `50`, maximum `500`**. Both are recorded in the Conventions block and
  published in the parameter schema; the gate checks the record against the schema. A maximum
  below `500` is legal and needs a `notes` entry — one hundred is the number an unchosen cap lands
  on, and it turns a thousand-row read into twenty round trips.
- Response `{"data": [...], "limit": 50, "next_cursor": "..."}`; `next_cursor` is absent on the
  last page. No `has_more`, no `prev_cursor`.
- `limit` above the maximum, `limit <= 0`, or a negative offset is `422`; a non-integer `limit` is
  `400`.
- No `total` by default; cursor returns it only for `include_total=true`, otherwise the key is
  omitted. Offset always returns it.
- The cursor is signed, binds sort and filter, carries no authority, and expires after a published
  period — 24 hours by default. A changed sort/filter, or a malformed or expired cursor, is
  `400 invalid-cursor`. Order ends with `created_at:desc,id:desc`.
- Offset only when every collection is bounded, stable, and needs page numbers; record it.

## Output Contract

| Deliverable | Must contain |
|---|---|
| Endpoint table | `Method \| Path \| Purpose \| Success \| Errors \| Auth`; IANA statuses. |
| Per-endpoint section | Parameters, bodies, examples, auth, idempotency, headers, page-size default/max, pagination fields. |
| Conventions block | One value per axis, the page-size integers, `header_fields`, a `notes` entry per departure. |
| Error catalogue and breaks | One meaning/status per code; each break with its version bump and migration note. |
| OpenAPI 3.1 document | Validates and lints; real examples; `x-conventions`, `x-error-catalogue`, `x-auth`; passes the gate. |

## Guardrails

- One value per convention axis; two values for one axis is an inconsistency.
- The status carries the outcome; never `200` plus an error flag.
- One error catalogue: one code, one status, one meaning.
- Every collection paginates from v1, under one strategy; every endpoint is labelled
  `public`, `authenticated` or `privileged`, with the check named.
- No implementation code, framework names, stack traces, SQL, file paths, or internal detail.

## Verification

```console
uvx --from openapi-spec-validator openapi-spec-validator openapi.yaml
npx --yes @redocly/cli lint openapi.yaml
python3 scripts/validate.py --contract openapi.yaml   # requires PyYAML
python3 tests/run.py                                   # the gate's own fixtures
```

- Every endpoint names its auth label and uses IANA statuses; no `2xx` body carries `error`,
  `errors` or `success`.
- Every error example's code — `type` for problem documents, `error.code` for wrapped bodies — is
  in `x-error-catalogue`, at the catalogue's status.
- Every collection records its page-size parameter, default, maximum, and pagination fields, and
  the recorded default and maximum agree with the parameter schema.
- A `cors: enabled` API answers the preflight, sets `Vary: Origin`, and never reflects an
  arbitrary `Origin` when credentials are allowed; a `cors: not_used` API has none of it.
- No example is a placeholder; `x-conventions` matches the design and the vocabulary block in
  `references/conventions.md`.
