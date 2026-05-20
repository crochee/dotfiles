# HTTP Status Codes Reference

**Load this reference when:** designing API responses, choosing status codes.

## Success Status Codes

| Code | Meaning | When to Use |
|------|---------|-------------|
| 200 OK | Success | GET, PUT, PATCH with response body |
| 201 Created | Created | POST, include Location header |
| 204 No Content | Success, no body | DELETE, PUT without response |

### 201 Created Example

```json
HTTP/1.1 201 Created
Location: /api/v1/users/abc-123

{
  "data": { "id": "abc-123", ... }
}
```

## Client Error Status Codes

| Code | Meaning | When to Use |
|------|---------|-------------|
| 400 Bad Request | Malformed request | Invalid JSON, missing required fields |
| 401 Unauthorized | Not authenticated | Missing or invalid credentials |
| 403 Forbidden | Not authorized | Authenticated but lacks permission |
| 404 Not Found | Resource missing | Resource doesn't exist |
| 409 Conflict | State conflict | Duplicate entry, version conflict |
| 422 Unprocessable Entity | Semantic invalid | Valid JSON but data is invalid |
| 429 Too Many Requests | Rate limited | Exceeded rate limit |

### 400 vs 422

- **400**: Syntax error (malformed JSON, invalid format)
- **422**: Semantic error (valid JSON, but data fails validation)

### Error Response Format

```json
{
  "error": {
    "code": "validation_error",
    "message": "Request validation failed",
    "details": [
      { "field": "email", "message": "Must be valid email", "code": "invalid_format" },
      { "field": "age", "message": "Must be positive", "code": "out_of_range" }
    ]
  }
}
```

## Server Error Status Codes

| Code | Meaning | When to Use |
|------|---------|-------------|
| 500 Internal Server Error | Unexpected failure | Never expose details |
| 502 Bad Gateway | Upstream failed | External service down |
| 503 Service Unavailable | Temporary overload | Include Retry-After |

### 500 Best Practices

- Log details internally
- Return generic message to client
- Never expose stack traces, SQL errors, internal paths

```json
{
  "error": {
    "code": "internal_error",
    "message": "An unexpected error occurred"
  }
}
```

## Common Mistakes

```
# BAD: 200 for everything
{ "status": 200, "success": false, "error": "Not found" }

# GOOD: Use HTTP status codes semantically
HTTP/1.1 404 Not Found
{ "error": { "code": "not_found", "message": "User not found" } }

# BAD: 500 for validation errors
# GOOD: 400 or 422 with field-level details

# BAD: 200 for created resources (no Location)
# GOOD: 201 with Location header
```

## Status Code Decision Tree

```
Is request successful?
├── YES
│   ├── Resource created? → 201 + Location
│   ├── Delete/put no body? → 204
│   └── Other success → 200
└── NO
    ├── Not authenticated? → 401
    ├── Not authorized? → 403
    ├── Not found? → 404
    ├── Duplicate/conflict? → 409
    ├── Validation failed? → 400/422
    └── Server error? → 500
```