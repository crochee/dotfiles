# OpenAPI

**Load this reference when:** writing or reviewing the OpenAPI 3.1 document — a `components`
section, a vendor extension, a security scheme, or the validation commands.

## The document is the contract

An OpenAPI document is not documentation *about* the API — it is the API's contract as a
machine-readable file. Three rules follow:

1. **The document and the implementation must not disagree.** If the document says `limit` is
   capped at 100 and the code accepts 1000, the document is wrong and it is the thing clients read.
2. **Every example is a payload.** A response example the server would never produce teaches
   clients to parse a fiction.
3. **One source of truth.** If the document is written by hand, its endpoint table, status-code map
   and error catalogue must match the design document exactly. If it is generated, CI compares the
   committed file with the generator's output.

Keep the document beside the design document it encodes. The complete worked contract is
[examples/identity-openapi.yaml](../examples/identity-openapi.yaml).

## What each part must contain

| Part | Must contain |
|---|---|
| `info` | The API title, a version, and a one-paragraph description of the audience. |
| `servers` | The production URL; never a placeholder in a shipped document. |
| `security` | The credential every endpoint requires, declared once at the root. A public endpoint overrides it with `security: []` — an empty list, not an omitted key, which would inherit the root requirement. |
| `securitySchemes` | The schemes the API accepts, declared once under `components.securitySchemes`. |
| `paths` | Every endpoint, with its `operationId`, parameters and response map. |
| `parameters` | Every reusable parameter. The page-size parameter is the recorded `page_size_param` value, with the recorded `page_size_default` and `page_size_max` in its schema; a cursor collection adds `cursor` and, when `total` is served, the `include_total` boolean; an offset collection adds `offset` and carries `offset` and `total` in its response schema. |
| `schemas` | The resource schemas, the collection shape, and the error body the API recorded — see [HTTP semantics](http-semantics.md) and [pagination](pagination.md). |
| `responses` | The reusable error responses, so every endpoint answers the same error with the same shape. |
| `examples` | One real example per response, inline or under `components.examples`. |
| `x-conventions` | The recorded `Conventions` block — one value per axis — in a root vendor extension. |
| `x-error-catalogue` | One entry per code: its `type` URI, its status, and its meaning. |
| `x-auth` / `x-privileged-check` | On each operation: the label (`public`, `authenticated`, `privileged`) and, when privileged, the check in one sentence. |

- Every endpoint lists every status it can answer: a `responses` map with only `200` documents an
  API that cannot fail. Framework-generated failures every operation can answer — the router's
  `405` — are declared once as shared components; the body parser's `415` is declared on operations
  that accept a request body.
- Each status's required headers are declared once in the shared response component; the
  per-status list is in [HTTP semantics](http-semantics.md#required-headers).
- `x-auth` is written, not implied: the root `security` says which credential, not which check, and
  no linter checks the label — `security: []` on an operation lints clean.
- `operationId` is unique and follows the recorded field casing — it becomes the method name in
  every SDK.
- The error body and the collection shape live only in `components.schemas`, referenced everywhere;
  a second, slightly different shape in one endpoint is the two-shapes bug in document form.
- `additionalProperties: false` documents that unknown fields are not expected — set it only when
  the server really strips them, because adding a field is then a breaking change for strict
  clients.
- Parameters optional in the implementation are optional here, with the real default in
  `schema.default`.

## The conventions travel with the document

The `Conventions` block goes in an `x-conventions` vendor extension at the document root, with the
design document's keys and values.

```yaml
x-conventions:
  path_casing: kebab-case
  field_casing: snake_case
  error_format: problem_json
  pagination: offset
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
  notes:
    - axis: pagination
      reason: The admin console needs page numbers, and every collection is bounded and stable.
```

The extension is a copy, not a summary: one value per axis, the values the design document records,
and a `notes` entry for every departure. A document whose extension disagrees with the design
document has drifted.

## Security schemes

- A credential in `Authorization` is `type: http` with the scheme the API uses — `scheme: bearer`
  for a bearer token, or the registered scheme token. Declaring it `type: apiKey` with `name:
  Authorization` describes a private field, and generated clients look for the wrong thing.
- `type: apiKey` is for a session cookie or a query parameter (`in: cookie` or `in: query`); a key
  that travels in a request header uses a scheme token in `Authorization` instead. `in: query`
  puts the credential in URLs, logs and cache keys, so it is a last resort the contract must state.
- OAuth 2.0 and OIDC flows are out of scope for this skill: consume the token, and declare the
  scheme the contract accepts.

## Examples must be real payloads

An example is a promise: "this is what the server returns". A fabricated example — a field the
server does not send, a `total` the query never produces, an error code not in the catalogue — is
worse than no example.

- Take examples from a real response: run the request against a staging environment and paste the
  body.
- Keep them consistent with the schema and the catalogue: the example validates against the schema
  next to it, and every error `type` is one the API can return, at the status the catalogue maps it
  to.
- Include the failure cases: a contract with only the happy path teaches clients that errors do
  not happen.

The worked contract keeps the same ids throughout — users `42` and `43` — so it reads as one
system.

## Validate and lint

```console
uvx --from openapi-spec-validator openapi-spec-validator openapi.yaml
npx --yes @redocly/cli lint openapi.yaml
npx --yes @stoplight/spectral-cli lint openapi.yaml
```

The schema validator checks that the document is valid OpenAPI 3.1; Redocly flags missing
`operationId`s, undocumented responses and example mismatches; Spectral applies a house ruleset.
The skill's own gate is a separate check: `python3 scripts/validate.py --contract <file>` asserts
the skill's absolutes — the recorded conventions against the vocabulary in
[conventions](conventions.md), the error catalogue, auth labels, required headers, the page-size
default and maximum against the parameter schema, collection fields, the `2xx` error-flag ban, the
`cors` rules, and internal detail. It does not replace schema validation or lint.

A breaking-change diff against the published document is in the
[versioning reference](versioning.md#machine-checked-breaking-change-detection).

## Version coverage

**OpenAPI 3.1 is the baseline.** It aligns with JSON Schema 2020-12, so a schema in the document is
a JSON Schema and `$ref` can point anywhere in it, not only at `components`.

A document that still says `openapi: 3.0.3` is not the baseline: `type: [string, "null"]` replaces
`nullable: true`, `exclusiveMinimum` carries the value rather than a flag, and a schema's `example`
becomes the `examples` array. OpenAPI 3.2 is out of scope for this skill.
