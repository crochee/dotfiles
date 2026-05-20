---
name: api-design
description: Use when designing REST or GraphQL endpoints, defining request/response schemas, or establishing API versioning and authentication conventions.
metadata:
  author: skills-team
---

# API Design Patterns

Conventions and best practices for designing consistent, developer-friendly REST APIs.

## When to Use

- Designing new API endpoints, reviewing existing API contracts
- Adding pagination, filtering, or sorting
- Implementing error handling for APIs
- Planning API versioning strategy

**See [references/status-codes.md](references/status-codes.md) for complete status code reference.**

## Resource Design

### URL Structure

```
# Resources are nouns, plural, lowercase, kebab-case
GET    /api/v1/users
GET    /api/v1/users/:id
POST   /api/v1/users
PUT    /api/v1/users/:id
PATCH  /api/v1/users/:id
DELETE /api/v1/users/:id

# Sub-resources for relationships
GET    /api/v1/users/:id/orders

# Actions (use verbs sparingly)
POST   /api/v1/orders/:id/cancel
POST   /api/v1/auth/login
```

### Naming Rules

| GOOD | BAD |
|------|-----|
| `/api/v1/team-members` | `/api/v1/getUsers` (verb) |
| `/api/v1/orders?status=active` | `/api/v1/user` (singular) |
| `/api/v1/users/123/orders` | `/api/v1/team_members` (snake_case) |

## HTTP Methods and Status Codes

| Method | Idempotent | Safe | Use For |
|--------|-----------|------|---------|
| GET | Yes | Yes | Retrieve resources |
| POST | No | No | Create resources, trigger actions |
| PUT | Yes | No | Full replacement |
| PATCH | No* | No | Partial update |
| DELETE | Yes | No | Remove resource |

**See [references/status-codes.md](references/status-codes.md) for complete status code reference with examples.**

## Response Format

### Success Response

```json
{
  "data": {
    "id": "abc-123",
    "email": "alice@example.com",
    "name": "Alice"
  }
}
```

### Collection Response (Pagination)

```json
{
  "data": [...],
  "meta": { "total": 142, "page": 1, "per_page": 20 },
  "links": { "self": "...", "next": "..." }
}
```

### Error Response

```json
{
  "error": {
    "code": "validation_error",
    "message": "Request validation failed",
    "details": [{ "field": "email", "message": "Must be valid email" }]
  }
}
```

**See [references/response-formats.md](references/response-formats.md) for envelope variants and field-level error formatting.**

## Pagination

| Use Case | Type |
|----------|------|
| Admin dashboards, small datasets | Offset |
| Infinite scroll, feeds, large datasets | Cursor |
| Search results (users expect page numbers) | Offset |

**See [references/pagination.md](references/pagination.md) for implementation details.**

## Filtering and Sorting

```
# Filtering
GET /api/v1/orders?status=active&customer_id=abc-123
GET /api/v1/products?price[gte]=10&price[lte]=100

# Sorting (prefix - for descending)
GET /api/v1/products?sort=-created_at,price

# Sparse fieldsets
GET /api/v1/users?fields=id,name,email
```

## Authentication

```bash
# Bearer token
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...

# API key (server-to-server)
X-API-Key: sk_live_abc123
```

**See [references/auth-patterns.md](references/auth-patterns.md) for authorization patterns.**

## Rate Limiting

| Tier | Limit | Window |
|------|-------|--------|
| Anonymous | 30/min | Per IP |
| Authenticated | 100/min | Per user |
| Premium | 1000/min | Per API key |

## Versioning

```
/api/v1/users
/api/v2/users
```

**Rule:** Non-breaking changes don't need new version. Breaking changes require new version.

**See [references/versioning.md](references/versioning.md) for deprecation timeline and breaking change guidelines.**

## References

- [references/status-codes.md](references/status-codes.md) - Complete HTTP status code reference
- [references/response-formats.md](references/response-formats.md) - Response envelope variants
- [references/pagination.md](references/pagination.md) - Offset vs cursor implementation
- [references/auth-patterns.md](references/auth-patterns.md) - Auth and authorization
- [references/versioning.md](references/versioning.md) - Versioning strategy and deprecation

## Checklist

- [ ] Resource URL follows naming (plural, kebab-case, no verbs)
- [ ] Correct HTTP method used
- [ ] Appropriate status codes returned
- [ ] Input validated with schema
- [ ] Error responses follow standard format
- [ ] Pagination for list endpoints
- [ ] Authentication required
- [ ] Authorization checked
- [ ] Rate limiting configured
- [ ] No internal details leaked