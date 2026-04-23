# Test-Driven Development

> **Language-Agnostic Note:** These principles apply to any programming language. Adapt test syntax to your testing framework while respecting the underlying concepts.

## The Core Loop

```
RED → GREEN → REFACTOR → RED → ...
```

### RED Phase

Write a failing test that describes the behavior you want.

The test should:
- Use domain language, not technical jargon
- Describe **WHAT**, not **HOW**
- Be a concrete example, not an abstract statement

```
BAD: "can add numbers"
GOOD: "when adding 2 + 3, returns 5"
```

### GREEN Phase

Write the **simplest possible code** to make the test pass.

Two strategies:
1. **Fake It** - Return a hardcoded value
2. **Obvious Implementation** - If you know the solution

**Prefer Fake It** when learning or unsure. Let more tests drive the real implementation.

### REFACTOR Phase

This is where **design happens**.

Look for:
- Duplication (but wait for Rule of Three)
- Long functions to extract
- Poor names to improve
- Complex conditions to simplify

---

## The Three Laws of TDD

1. You cannot write production code unless it makes a failing test pass
2. You cannot write more test code than sufficient to fail (compilation failures count)
3. You cannot write more production code than sufficient to pass the one failing test

---

## The Rule of Three

**Don't extract duplication until you see it THREE times.**

Why? Wrong abstractions are worse than duplication.

```
Duplication #1 → Leave it
Duplication #2 → Note it, leave it
Duplication #3 → NOW extract it
```

---

## Triangulation

Each new test "sculpts" the solution toward a general, robust implementation.

Think of **degrees of freedom** - each test carves out one degree of freedom until the implementation handles all cases.

---

## Transformation Priority Premise

When going from RED to GREEN, prefer simpler transformations:

| Priority | Transformation |
|----------|----------------|
| 1 | nil → constant |
| 2 | constant → variable |
| 3 | unconditional → conditional |
| 4 | scalar → collection |
| 5 | value → mutated value |

Higher priority = simpler. Avoid jumping to complex transformations too early.

---

## Test Naming

Principles:
- Use **behavior-driven names** with domain language
- Provide **concrete examples**, not abstract statements
- **One example per test** for easy debugging
- Avoid leaking implementation details

```
BAD: "should set the data property to 1"
GOOD: "should recognize 'mom' as a palindrome"
```

---

## Classic vs Mockist TDD

### Classic (Detroit/Chicago) TDD

- Test with real dependencies
- Higher confidence, slower tests
- Best for: Pure functions, integration tests

### Mockist (London) TDD

- Mock external dependencies
- Faster tests, more isolated
- Best for: Components with infrastructure dependencies

Start with Classic TDD to learn the technique. Add mocks when testing code with databases, APIs, etc.

---

## Common Mistakes

1. **Writing code before tests** - Violates the fundamental principle
2. **Writing too much test** - Just enough to fail
3. **Writing too much code** - Just enough to pass
4. **Skipping refactor** - This is where design lives
5. **Testing implementation** - Test behavior, not how it's done
6. **Abstract test names** - Use concrete examples
7. **Extracting too early** - Wait for Rule of Three
