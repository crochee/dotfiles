# Response Format Variants

**Load this reference when:** designing API responses, choosing envelope format.

## Option A: Envelope with Data Wrapper (Recommended for public APIs)

```typescript
interface ApiResponse<T> {
  data: T;
  meta?: PaginationMeta;
  links?: PaginationLinks;
}

interface ApiError {
  error: {
    code: string;
    message: string;
    details?: FieldError[];
  };
}
```

### Usage

```json
// Success
{
  "data": { "id": "abc-123", "name": "Alice" }
}

// Collection
{
  "data": [
    { "id": "abc-123", "name": "Alice" },
    { "id": "def-456", "name": "Bob" }
  ],
  "meta": { "total": 142, "page": 1, "per_page": 20 },
  "links": { "self": "...", "next": "..." }
}
```

## Option B: Flat Response (Simpler, common for internal APIs)

- **Success:** return the resource directly
- **Error:** return error object
- **Distinguish by HTTP status code**

### Usage

```json
// Success (200)
{ "id": "abc-123", "name": "Alice" }

// Error (404)
{ "error": { "code": "not_found", "message": "User not found" } }
```

## Field-Level Error Formatting

For validation errors, include field-level details:

```json
{
  "error": {
    "code": "validation_error",
    "message": "Request validation failed",
    "details": [
      { "field": "email", "message": "Must be a valid email address", "code": "invalid_format" },
      { "field": "age", "message": "Must be between 0 and 150", "code": "out_of_range" }
    ]
  }
}
```

## When to Use Which

| Factor | Envelope | Flat |
|--------|----------|------|
| API type | Public/third-party | Internal |
| Error handling | Need structured errors | Simple status codes |
| Consistency | Uniform format | Varies by success/error |
| Client needs | Meta info, links | Direct access |

## Envelope Advantages

- Consistent structure for clients
- Easy to add pagination meta
- Clear data vs metadata separation
- HATEOAS support (links)

## Flat Advantages

- Simpler responses
- Less nesting
- Direct resource access
- Lower payload size