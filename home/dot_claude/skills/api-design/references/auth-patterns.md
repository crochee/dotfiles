# Authentication Patterns

**Load this reference when:** implementing auth, designing authorization checks.

## Token-Based Authentication

### Bearer Token (OAuth2/JWT)

```bash
GET /api/v1/users
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

```typescript
// Middleware
function authMiddleware(req: Request, res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    return res.status(401).json({ error: { code: 'unauthorized' } });
  }

  const token = header.slice(7);
  try {
    const payload = verifyJWT(token, process.env.JWT_SECRET);
    req.user = payload;
    next();
  } catch {
    return res.status(401).json({ error: { code: 'invalid_token' } });
  }
}
```

### API Key (Server-to-Server)

```bash
GET /api/v1/data
X-API-Key: sk_live_abc123
```

```typescript
function apiKeyMiddleware(req: Request, res: Response, next: NextFunction) {
  const key = req.headers['x-api-key'];
  if (!key) {
    return res.status(401).json({ error: { code: 'missing_api_key' } });
  }

  const service = validateAPIKey(key);
  if (!service) {
    return res.status(403).json({ error: { code: 'invalid_api_key' } });
  }

  req.service = service;
  next();
}
```

## Authorization Patterns

### Resource-Level (Ownership)

```typescript
app.get("/api/v1/orders/:id", async (req, res) => {
  const order = await Order.findById(req.params.id);
  if (!order) {
    return res.status(404).json({ error: { code: 'not_found' } });
  }

  // Check ownership
  if (order.userId !== req.user.id && !req.user.isAdmin) {
    return res.status(403).json({ error: { code: 'forbidden' } });
  }

  return res.json({ data: order });
});
```

### Role-Based (Permissions)

```typescript
function requireRole(role: string) {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user.roles.includes(role)) {
      return res.status(403).json({ error: { code: 'forbidden' } });
    }
    next();
  };
}

app.delete("/api/v1/users/:id", requireRole("admin"), async (req, res) => {
  await User.delete(req.params.id);
  return res.status(204).send();
});
```

### Policy-Based (Complex Rules)

```typescript
const policies = [
  { resource: 'order', action: 'delete', condition: (user, order) =>
    user.id === order.userId || user.hasRole('admin')
  },
  { resource: 'order', action: 'read', condition: (user, order) =>
    user.id === order.userId || user.hasRole('viewer')
  },
];

function checkPolicy(user: User, resource: string, action: string, obj: any) {
  const policy = policies.find(p => p.resource === resource && p.action === action);
  return policy?.condition(user, obj) ?? false;
}
```

## Rate Limiting Headers

```bash
HTTP/1.1 200 OK
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640000000

# When exceeded
HTTP/1.1 429 Too Many Requests
Retry-After: 60
Content-Type: application/json

{
  "error": {
    "code": "rate_limit_exceeded",
    "message": "Rate limit exceeded. Try again in 60 seconds.",
    "retry_after": 60
  }
}
```

## Token Refresh Flow

```bash
# 1. Initial login
POST /api/v1/auth/login
{ "email": "...", "password": "..." }

# Response
{
  "access_token": "eyJ...",
  "refresh_token": "abc...",
  "expires_in": 3600
}

# 2. Refresh when expired
POST /api/v1/auth/refresh
{ "refresh_token": "abc..." }

# Response (same format as login)
{
  "access_token": "eyJ...",
  "refresh_token": "xyz...",
  "expires_in": 3600
}
```