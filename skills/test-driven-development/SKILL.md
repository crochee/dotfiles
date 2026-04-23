---
name: test-driven-development
description: >
  Test-driven development workflow (RED → GREEN → REFACTOR). Write failing tests first, then minimal code to pass, then refactor. Use when implementing any feature or bugfix, always before writing implementation code.
---

# Test-Driven Development

## Core Flow

```
RED → GREEN → REFACTOR → repeat
```

1. **RED** - Write failing test
2. **GREEN** - Minimal code to pass
3. **REFACTOR** - Clean up (tests stay green)

## Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Write code before test? Delete it. Start over.

## Workflow

| Step        | Action                      | Verify                 |
| ----------- | --------------------------- | ---------------------- |
| 1. RED      | Write one minimal test      | `npm test` - must fail |
| 2. GREEN    | Write simplest code to pass | `npm test` - must pass |
| 3. REFACTOR | Clean up (no new behavior)  | All tests green        |
| 4. Repeat   | Next failing test           | —                      |

## Verification Checklist

- [ ] Watched test fail before implementing
- [ ] Test failed for expected reason
- [ ] Wrote minimal code to pass
- [ ] All tests pass, output pristine
- [ ] Mocks only if unavoidable
- [ ] Edge cases covered

## Common Rationalizations

| Excuse                         | Reality                                   |
| ------------------------------ | ----------------------------------------- |
| "I'll test after"              | Tests passing immediately prove nothing   |
| "Too simple to test"           | Simple breaks too. Test = 30 sec          |
| "Deleting X hours is wasteful" | Sunk cost. Keeping unverified code = debt |

## References

- [references/anti-patterns.md](references/anti-patterns.md) — 5 anti-patterns with fixes
- [references/tdddetails.md](references/tdddetails.md) — detailed flow, examples, debugging

