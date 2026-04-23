# Software Architecture

> **Language-Agnostic Note:** These principles apply to any programming language and system. Adapt to your technology stack while respecting the underlying concepts.

## The Goal of Architecture

Enable the development team to:
1. **Add** features with minimal friction
2. **Change** existing features safely
3. **Remove** features cleanly
4. **Test** features in isolation
5. **Deploy** independently when possible

---

## Architectural Principles

### 1. Vertical Boundaries (Features/Slices)

Organize by **feature**, not by technical layer.

```
BAD: Layer-first organization
src/
  controllers/
  services/
  repositories/

GOOD: Feature-first organization
src/
  users/
  orders/
  payments/
```

**Why:** Changes to "users" feature stay in `users/`. High cohesion within features.

---

### 2. Horizontal Boundaries (Layers)

Separate concerns into layers with clear dependencies.

```
┌─────────────────────────────────────────────────────────┐
│ Presentation              UI, Controllers, CLI         │
├─────────────────────────────────────────────────────────┤
│ Application              Use Cases, Orchestration     │
├─────────────────────────────────────────────────────────┤
│ Domain                   Business Logic, Entities     │
├─────────────────────────────────────────────────────────┤
│ Infrastructure           Database, APIs, External      │
└─────────────────────────────────────────────────────────┘
```

---

### 3. The Dependency Rule

**Dependencies point INWARD.**

```
Infrastructure → Application → Domain
↑              ↑            ↑
(outer)        (middle)    (inner)
```

- Inner layers know NOTHING about outer layers
- Domain has zero dependencies on infrastructure
- Use interfaces to invert dependencies

---

### 4. Contracts

Interfaces define boundaries between components.

```
The contract (interface)
PaymentGateway
  - charge(amount, card)
  - refund(chargeId)

Multiple implementations
  - StripeGateway
  - PayPalGateway
  - MockGateway (for tests)
```

---

### 5. Cross-Cutting Concerns

Concerns that span multiple features: logging, auth, validation, error handling.

**Options:**
- Middleware/interceptors
- Decorators
- Aspect-oriented approaches
- Base modules (use sparingly)

---

### 6. Conway's Law

> "Organizations design systems that mirror their communication structure."

**Implication:** Team structure affects architecture. Align both intentionally.

---

## Common Architectural Styles

### Layered Architecture

Traditional layers: Presentation → Business → Persistence

**Pros:** Simple, well-understood

**Cons:** Can become entangled without discipline

---

### Hexagonal Architecture (Ports & Adapters)

Domain at center, adapters around the edges.

```
┌─────────────────────────────────────────────────────────┐
│                    External Systems                      │
│    ┌───────────────────────────────────────────────┐   │
│    │              HTTP Adapter                      │   │
│    └───────────────────────┬───────────────────────┘   │
│                            │                             │
│    ┌───────────────────────┴───────────────────────┐   │
│    │                 DOMAIN                          │   │
│    │    ┌───────────────────────────────────────┐    │   │
│    │    │     Business Logic, Use Cases         │    │   │
│    │    └───────────────────────────────────────┘    │   │
│    └───────────────────────┬───────────────────────┘   │
│                            │                             │
│    ┌───────────────────────┴───────────────────────┐   │
│    │              Database Adapter                   │   │
│    └───────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘

Ports: Interfaces defined by the domain
Adapters: Implementations connecting to outside world
```

---

### Clean Architecture

Similar to Hexagonal, with explicit layers:
1. **Entities** - Enterprise business rules
2. **Use Cases** - Application business rules
3. **Interface Adapters** - Controllers, Presenters, Gateways
4. **Frameworks & Drivers** - Web, DB, External interfaces

---

## Feature-Driven Structure

### Frontend Organization

```
src/
  features/
    auth/
      components/
      hooks/
      services/
      types/
    checkout/
      components/
      hooks/
      services/
      types/
  shared/
    components/     # Truly shared UI
    hooks/          # Truly shared
    utils/          # Truly shared
```

### Backend Organization

```
src/
  modules/
    users/
      domain/
      application/
      infrastructure/
      presentation/
    orders/
      domain/
      application/
      infrastructure/
      presentation/
  shared/
    domain/          # Shared value types
    infrastructure/ # Shared infrastructure
```

---

## The Walking Skeleton

Start with a minimal end-to-end slice:
1. **Thinnest possible feature** that touches all layers
2. **Deployable** from day one
3. **Proves the architecture** works

**Example walking skeleton for e-commerce:**
- User can view ONE product
- User can add it to cart
- User can "checkout" (logs only)

From there, flesh out each feature fully.

---

## Testing Architecture

```
┌─────────────────────────────────────────────────────────┐
│ E2E / Acceptance Tests    Few, slow, high confidence  │
├─────────────────────────────────────────────────────────┤
│ Integration Tests        Some, medium speed           │
├─────────────────────────────────────────────────────────┤
│ Unit Tests              Many, fast, isolated         │
└─────────────────────────────────────────────────────────┘
```

**Test by layer:**
- **Domain:** Unit tests (most tests here)
- **Application:** Integration tests with mocked infrastructure
- **Infrastructure:** Integration tests with real dependencies
- **E2E:** Critical paths only

---

## Architecture Decision Records (ADRs)

Document significant decisions:

```markdown
# ADR 001: Use PostgreSQL for persistence

## Status
Accepted

## Context
We need a database. Options: PostgreSQL, MongoDB, MySQL

## Decision
PostgreSQL for:
- ACID compliance
- Team familiarity
- JSON support

## Consequences
- Need PostgreSQL expertise
- Schema migrations required
```

---

## Red Flags in Architecture

- **Circular dependencies** between modules
- **Domain depending on infrastructure**
- **Framework code in business logic**
- **No clear boundaries** between features
- **Shared mutable state** across modules
- **"Util" or "Common" packages** that grow forever
- **Database schema driving domain model**
