# API Versioning Strategy

**Load this reference when:** planning versioning, handling deprecation.

## URL Path Versioning (Recommended)

```
/api/v1/users
/api/v2/users
```

**Pros:** Explicit, easy to route, cacheable
**Cons:** URL changes between versions

## Header Versioning

```
GET /api/users
Accept: application/vnd.myapp.v2+json
```

**Pros:** Clean URLs
**Cons:** Harder to test, easy to forget

## Versioning Rules

### When to Create New Version

Non-breaking changes DON'T need new version:
- Adding new fields to responses
- Adding new optional query parameters
- Adding new endpoints

Breaking changes REQUIRE new version:
- Removing or renaming fields
- Changing field types
- Changing URL structure
- Changing authentication method
- Changing required vs optional parameters

### Version Lifecycle

```
1. Start with /api/v1/ — don't version until you need to
2. Maintain at most 2 active versions (current + previous)
3. Deprecation timeline:
   - Announce deprecation (6 months notice for public APIs)
   - Add Sunset header
   - Return 410 Gone after sunset date
```

## Deprecation Headers

```bash
# Announce deprecation
HTTP/1.1 200 OK
Deprecation: true
Sunset: Sat, 01 Jan 2026 00:00:00 GMT
Link: <https://api.example.com/v2/users>; rel="successor-version"

# After sunset date
HTTP/1.1 410 Gone
{
  "error": {
    "code": "gone",
    "message": "This API version has been sunset",
    "successor": "/api/v2/users"
  }
}
```

## Migration Guide

When releasing new version:

1. **Announce** (6+ months before sunset)
   - Email developers
   - Add Deprecation header
   - Update documentation

2. **Migrate** (during deprecation period)
   - Update client code to new version
   - Test with new endpoints
   - Coordinate with API consumers

3. **Sunset** (after deprecation date)
   - Return 410 Gone
   - Redirect to new version if applicable
   - Archive old documentation

## Example Migration: Breaking Field Change

### v1 Response

```json
{
  "user": {
    "id": "123",
    "full_name": "Alice Smith"  // snake_case
  }
}
```

### v2 Response

```json
{
  "user": {
    "id": "123",
    "fullName": "Alice Smith"  // camelCase
  }
}
```

### Migration Steps

1. Add new field in v2
2. Keep old field in v1
3. Announce v1 deprecation
4. Update clients to v2
5. Remove old field after transition