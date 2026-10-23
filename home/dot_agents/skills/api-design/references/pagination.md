# Pagination

**Load this reference when:** a collection endpoint, the page-size parameter, a cursor, a sort
allow-list, or a pagination error.

## One strategy per API

Every collection paginates from the first release, under one strategy for the whole API. Adding
pagination later changes every client's response, so a collection that ships without it ships a
breaking change. The strategy is the `pagination` convention; the API records it once.

**Default: cursor.** Pick offset only when every collection in the API is bounded (roughly
≤10,000 rows), stable, and clients need page numbers or a total. Record the departure in `notes`:
a cursor cannot jump to a page, and an offset page is not stable while rows are inserted or
deleted.

| | Offset | Cursor |
|---|---|---|
| Request | `?limit=50&offset=100` | `?limit=50&cursor=7fJq2nXc9vKp4mTb` |
| Cost of a deep page | grows with depth | constant |
| Stable while rows are inserted or deleted | no | yes |
| Jump to an arbitrary position | yes | no |
| Counts the whole collection | yes, in `total` | no, unless requested |
| Fits | totals, page jumpers | feeds, infinite scroll, large tables |

A "keyset" cursor is not a third strategy: it is how a cursor is implemented and belongs to the
server, not the contract. Do not mix the two strategies in one API.

## The page-size parameter

One name across the API — the recorded `page_size_param`, `limit` by default. It is never
required; its absence applies `page_size_default`.

- **Recommended: default `50`, maximum `500`.** Both numbers are recorded in the Conventions
  block, and the parameter schema in the OpenAPI document publishes the same two values. The
  gate checks that the record and the schema agree.
- A maximum below `500` is legal — a page of Large rows cannot be five hundred of them — but it is
  a departure: it needs a `notes` entry naming `page_size_max` and giving the reason. A cap that
  nobody chose is `100`, and it turns a thousand-row read into twenty round trips.
- A value above the maximum is rejected with `422 validation-error`, not clamped. The schema
  publishes `maximum`, so a generated validator rejects it; a server that silently clamps makes
  the schema lie.
- A value of zero or a negative value is `422` — not the absent case. Passing zero through would
  drop the limit clause and let one request read the whole table.
- A non-integer is `400 bad-request`: the server cannot turn it into a value, so there is nothing
  to range-check.
- The response's page-size member has the same name as the parameter.

## Cursor pagination

Request:

```http
GET /v1/users?limit=50&cursor=7fJq2nXc9vKp4mTb&sort=created_at:desc HTTP/1.1
```

Response:

```json
{
  "data": [
    { "id": "42", "email": "ada@example.com", "display_name": "Ada Lovelace" }
  ],
  "limit": 50,
  "next_cursor": "9cQ2mZp1rLx8sVbN"
}
```

- `next_cursor` is present exactly when another page exists, and omitted on the last page. That
  absence is the only end-of-collection signal. A second flag beside it (`has_more`) is a second
  field for one fact, and the two drift.
- There is no `prev_cursor`. A client that needs backward navigation keeps the cursors it has
  already seen.
- An empty page is `{"data": [], "limit": 50}` with no `next_cursor`.
- `limit` in the response is the effective page size.
- `total` is absent by default. It is returned only when the client sends `include_total=true`,
  and then it counts the rows matching the filter and the tenant, not the collection before the
  filter. When it was not requested, the key is omitted — never `total: null`, so a client can
  tell "no count" from "count is zero". The count is opt-in because a cursor exists for a
  collection that may be unbounded, and an unconditional `COUNT` is the cost the cursor removes.

### The cursor is opaque

The cursor encodes the last row's position for the recorded sort key. A client never constructs
one.

- **Base64 is not opacity.** A client that can decode the cursor constructs its own, and the
  encoding becomes API surface. Sign or encrypt it.
- **The cursor carries no authority.** It says where to continue, nothing else — not the tenant,
  the principal, or a permission. The server authorizes the request as it would without one.
- **The cursor binds the sort key and the filter.** A cursor is valid only for the `sort` and the
  filter it was issued under. Changing either mid-sequence, or presenting a malformed or expired
  cursor, is `400 invalid-cursor`. Returning rows from another ordering is never an option.
- **Publish the expiry.** The server may expire cursors; the contract states the period — 24
  hours is the default because it matches the `Idempotency-Key` retention — and an expired cursor
  is `400 invalid-cursor`. A client that retries a sequence longer than the period must expect to
  restart from the first page.

## Sort stability

Every ordering ends with a unique tie-breaker column, so two rows sharing the primary sort value
still have a defined order. Without it, rows swap between pages under concurrent writes. The
default is `created_at:desc,id:desc`: the direction is explicit per key, and the tie-breaker is
ordered too. A tie-breaker with no direction is not a contract — the server is free to pick, and
then two pages can overlap.

A client-selectable sort key is an allow-list, never an arbitrary column name. `sort=created_at`
is a contract; `sort=` plus whatever the caller typed is an injection surface and a cardinality
explosion in the query planner. Publish the sortable keys, each with its direction
(`sort=created_at:desc`), and reject anything else with `422 invalid-sort`. If a key is published
in one direction only, say so; an allow-list that lists `email:asc` and nothing else reads as an
oversight rather than a decision.

## Offset pagination

Request `?limit=50&offset=100`. `offset` defaults to `0` and a negative value is `422`. The
response carries `offset`, `limit` and `total`; a pager is built on the total, so the count is
part of the strategy rather than an optional extra.

A deep offset costs a scan of everything it skips. The contract states the maximum offset the
service accepts, or that a deep page is served more slowly; it does not pretend the cost is
constant. Ordering follows the same tie-breaker rule as a cursor, so a row does not move between
pages while other rows are written.

## Errors

| Condition | Status | Code |
|---|---|---|
| `limit` is zero or negative, or above the maximum | `422` | `validation-error` |
| `limit` is not an integer | `400` | `bad-request` |
| `cursor` is malformed, expired, or bound to another sort or filter | `400` | `invalid-cursor` |
| `sort` is not in the allow-list | `422` | `invalid-sort` |
| `offset` is negative | `422` | `validation-error` |

One response status can carry more than one code, so the collection's `400` declares both
`bad-request` and `invalid-cursor` as examples. The codes are in the
[error catalogue](http-semantics.md#the-error-catalogue).
