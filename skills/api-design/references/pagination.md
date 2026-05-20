# Pagination Implementation

**Load this reference when:** implementing list endpoints, choosing pagination strategy.

## Offset-Based (Simple)

```
GET /api/v1/users?page=2&per_page=20

# SQL
SELECT * FROM users
ORDER BY created_at DESC
LIMIT 20 OFFSET 20;
```

### Response

```json
{
  "data": [...],
  "meta": {
    "total": 142,
    "page": 2,
    "per_page": 20,
    "total_pages": 8
  },
  "links": {
    "self": "/api/v1/users?page=2&per_page=20",
    "first": "/api/v1/users?page=1&per_page=20",
    "prev": "/api/v1/users?page=1&per_page=20",
    "next": "/api/v1/users?page=3&per_page=20",
    "last": "/api/v1/users?page=8&per_page=20"
  }
}
```

**Pros:** Easy to implement, supports "jump to page N"
**Cons:** Slow on large offsets (OFFSET 100000), inconsistent with concurrent inserts

## Cursor-Based (Scalable)

```
GET /api/v1/users?cursor=eyJpZCI6MTIzfQ&limit=20

# SQL
SELECT * FROM users
WHERE id > :cursor_id
ORDER BY id ASC
LIMIT 21;  -- fetch one extra to determine has_next
```

### Response

```json
{
  "data": [...],
  "meta": {
    "has_next": true,
    "next_cursor": "eyJpZCI6MTQzfQ"
  }
}
```

**Pros:** Consistent performance regardless of position, stable with concurrent inserts
**Cons:** Cannot jump to arbitrary page, cursor is opaque

## When to Use Which

| Use Case | Pagination Type |
|----------|----------------|
| Admin dashboards, small datasets (<10K) | Offset |
| Infinite scroll, feeds, large datasets | Cursor |
| Public APIs | Cursor (default) with offset (optional) |
| Search results | Offset (users expect page numbers) |

## Implementation Examples

### Go (Cursor)

```go
type CursorPagination struct {
    Limit    int
    Cursor   string // base64 encoded {id: int}
}

func (h *UserHandler) ListUsers(w http.ResponseWriter, r *http.Request) {
    var p CursorPagination
    if err := queryDecoder.Decode(&p, r.URL.Query()); err != nil {
        // default limit
        p.Limit = 20
    }

    // Decode cursor
    var lastID int64
    if p.Cursor != "" {
        decoded, _ := base64.StdEncoding.DecodeString(p.Cursor)
        json.Unmarshal(decoded, &struct{ ID int64 }{lastID})
    }

    users, err := h.repo.ListAfter(lastID, p.Limit+1)
    if err != nil {
        writeError(w, http.StatusInternalServerError, "db_error", err.Error())
        return
    }

    hasNext := len(users) > p.Limit
    if hasNext {
        users = users[:p.Limit]
    }

    var nextCursor string
    if hasNext && len(users) > 0 {
        cursor := struct{ ID int64 }{users[len(users)-1].ID}
        b, _ := json.Marshal(cursor)
        nextCursor = base64.StdEncoding.EncodeToString(b)
    }

    writeJSON(w, http.StatusOK, map[string]any{
        "data": users,
        "meta": map[string]any{
            "has_next": hasNext,
            "next_cursor": nextCursor,
        },
    })
}
```

### Python (Offset)

```python
from rest_framework.pagination import PageNumberPagination

class UserPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = 'per_page'
    max_page_size = 100

class UserViewSet(viewsets.ModelViewSet):
    serializer_class = UserSerializer
    pagination_class = UserPagination

    def get_paginated_response(self, data):
        return Response({
            'data': data,
            'meta': {
                'total': self.paginator.page.paginator.count,
                'page': self.paginator.page.number,
                'per_page': self.paginator.page_size,
            },
            'links': {
                'self': self.request.build_absolute_uri(),
                'next': self.get_next_link(),
                'prev': self.get_previous_link(),
            }
        })
```