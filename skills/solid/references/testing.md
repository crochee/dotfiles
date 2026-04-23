# Testing Strategy

> **Language-Agnostic Note:** These principles apply to any programming language and framework. Adapt test syntax to your testing framework while respecting the underlying concepts.

## The Testing Pyramid

```
        /\
       /  \
  E2E / Acceptance Tests (Few)
     /  \
    /----\
   /      \
  Integration Tests (Some)
  /--------\
 /          \
Unit Tests (Many)
```

---

## Test Types

### Unit Tests

Test one component or function in isolation.

**Characteristics:**
- Fast (milliseconds)
- No external dependencies (mocked/stubbed)
- **Most tests should be unit tests**

### Integration Tests

Test multiple components working together.

**Characteristics:**
- Slower (may use real infrastructure)
- Tests boundaries between components
- Fewer than unit tests

### E2E / Acceptance Tests

Test the entire system from user perspective.

**Characteristics:**
- Slowest
- Most brittle (many moving parts)
- Test critical paths only

---

## Arrange-Act-Assert (AAA)

Structure every test in three phases:

```
ARRANGE: Set up test state
        - Create test data
        - Initialize components
        - Set up mocks/stubs

ACT: Execute the behavior under test
        - Call the function/method
        - Perform the operation

ASSERT: Verify the expected outcome
        - Check results
        - Verify side effects
```

### Writing AAA Backwards

Sometimes easier to write in reverse:
1. **Assert first** - What do you want to verify?
2. **Act** - What produces that result?
3. **Arrange** - What setup is needed?

---

## Test Naming

### Bad: Abstract, Technical

```
- "should work correctly"
- "handles the edge case"
- "sets the data property"
```

### Good: Concrete Examples, Domain Language

```
- "calculates 20% discount for premium users"
- "returns error when cart is empty"
- "recognizes 'racecar' as a palindrome"
```

### Recommended Formats

```
Option 1: should + behavior
  "should apply tax based on shipping state"

Option 2: when + then
  "when adding 2 + 3, then returns 5"

Option 3: Given-When-Then (for complex scenarios)
  "given a premium user, when they checkout, then they receive 20% discount"
```

---

## Test Doubles

Test doubles replace real dependencies for testing purposes.

### Dummy

Passed but never used. Fills parameter lists.

### Stub

Returns predefined responses to calls.

### Spy

Records how it was called. For verification.

### Mock

Pre-programmed with expectations. Verifies interactions.

### Fake

Working implementation with simplified logic (e.g., in-memory database).

---

## Testing Strategies by Layer

### Domain Layer (Most Tests)

- Unit tests with no mocking
- Test business rules, value types, entities
- Fast, comprehensive

### Application Layer

- Integration tests with mocked infrastructure
- Test use case orchestration

### Infrastructure Layer

- Integration tests with real dependencies
- Test database operations, API integrations

### E2E Layer

- Critical user journeys only
- High confidence, slow execution

---

## High-Value Integration Tests

Focus integration tests on:
1. **Boundaries** - Where systems meet
2. **Critical paths** - Money, security, core features
3. **Complex operations** - Database queries, multi-step processes

### Contract Tests

Verify implementations match interfaces.

```
UserRepository contract:
  - saves and retrieves user
  - returns null for missing user

Apply to:
  - InMemoryUserRepository
  - PostgresUserRepository
```

---

## Test Builders

Create test objects with fluent interfaces.

```
OrderBuilder
  .withId("order-1")
  .withCustomer("cust-1")
  .withItems([...])
  .paid()
  .build()
```

Benefits:
- Readable test setup
- Reusable test fixtures
- Clear intent

---

## Common Testing Mistakes

| Mistake | Problem | Solution |
|---------|---------|----------|
| Testing implementation | Brittle tests | Test behavior only |
| Too many mocks | Tests prove nothing | Use real objects when possible |
| Shared state | Flaky tests | Isolate each test |
| No assertions | False confidence | Always assert meaningful outcomes |
| Testing trivial code | Wasted effort | Focus on logic and edge cases |
| Slow tests | Reduced feedback | Optimize, prefer unit tests |

---

## Testing Across Paradigms

### Object-Oriented (Java, C++, C#, TypeScript)
- Test classes and methods
- Use mocking frameworks
- AAA pattern native to most frameworks

### Functional (Haskell, Scala, F#, Elixir)
- Test pure functions first
- Property-based testing for generativity
- Integration tests for side effects

### Procedural (C, Go, Rust)
- Test functions/modules
- Table-driven tests common
- Interface-based mocking

### Scripting (Python, JavaScript, Ruby)
- Test functions and modules
- Mock/stub as needed
- Flexible test frameworks
