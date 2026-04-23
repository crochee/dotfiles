# TDD Details

## Red-Green-Refactor Cycle

### RED - Write Failing Test

Write one minimal test showing what should happen.

**Requirements:**
- One behavior
- Clear name
- Real code (no mocks unless unavoidable)

```pseudocode
test('retries failed operations 3 times', async () => {
  attempts = 0
  operation = () => {
    attempts += 1
    if attempts < 3:
      throw Error('fail')
    return 'success'
  }

  result = await retryOperation(operation)

  expect(result).toBe('success')
  expect(attempts).toBe(3)
})
```

### Verify RED - Watch It Fail

**MANDATORY. Never skip.**

```bash
# Run your test command
npm test path/to/test.test.ts
# or: pytest path/to/test.py
# or: cargo test
```

Confirm:
- Test fails (not errors)
- Failure message is expected
- Fails because feature missing (not typos)

### GREEN - Minimal Code

Write simplest code to pass the test. Don't add features, refactor other code, or "improve" beyond the test.

```pseudocode
async function retryOperation(fn):
    for i in range(3):
        try:
            return await fn()
        catch e:
            if i == 2:
                throw e
    throw Error('unreachable')
```

### Verify GREEN - Watch It Pass

**MANDATORY.**

```bash
# Run your test command
npm test path/to/test.test.ts
# or: pytest path/to/test.py
# or: cargo test
```

Confirm:
- Test passes
- Other tests still pass
- Output pristine (no errors, warnings)

### REFACTOR - Clean Up

After green only:
- Remove duplication
- Improve names
- Extract helpers

Keep tests green. Don't add behavior.

## Why Order Matters

**"I'll write tests after to verify it works"**

Tests written after code pass immediately. Passing immediately proves nothing:
- Might test wrong thing
- Might test implementation, not behavior
- Might miss edge cases you forgot
- You never saw it catch the bug

**"I already manually tested all the edge cases"**

Manual testing is ad-hoc. You think you tested everything but:
- No record of what you tested
- Can't re-run when code changes
- Easy to forget cases under pressure

**"Deleting X hours of work is wasteful"**

Sunk cost fallacy. The time is already gone. Your choice now:
- Delete and rewrite with TDD (X more hours, high confidence)
- Keep it and add tests after (30 min, low confidence, likely bugs)

## Example: Bug Fix

**Bug:** Empty email accepted

**RED**
```pseudocode
test('rejects empty email', async () => {
  result = await submitForm({ email: '' })
  expect(result.error).toBe('Email required')
})
```

**Verify RED**
```bash
$ npm test
FAIL: expected 'Email required', got undefined
```

**GREEN**
```pseudocode
function submitForm(data):
    if not data.email?.trim():
        return { error: 'Email required' }
    // ...
```

**Verify GREEN**
```bash
$ npm test
PASS
```

**REFACTOR**
Extract validation for multiple fields if needed.

## Good Tests

| Quality | Good | Bad |
|---------|------|-----|
| **Minimal** | One thing. "and" in name? Split it. | `test('validates email and domain and whitespace')` |
| **Clear** | Name describes behavior | `test('test1')` |
| **Shows intent** | Demonstrates desired API | Obscures what code should do |

## When Stuck

| Problem | Solution |
|---------|----------|
| Don't know how to test | Write wished-for API. Write assertion first. Ask your human partner. |
| Test too complicated | Design too complicated. Simplify interface. |
| Must mock everything | Code too coupled. Use dependency injection. |
| Test setup huge | Extract helpers. Still complex? Simplify design. |

## Debugging Integration

Bug found? Write failing test reproducing it. Follow TDD cycle. Test proves fix and prevents regression.

Never fix bugs without a test.

## Red Flags - STOP and Start Over

- Code before test
- Test passes immediately
- Can't explain why test failed
- Tests added "later"
- Rationalizing "just this once"
- "I already manually tested it"
- "Tests after achieve the same purpose"
- "Keep as reference" or "adapt existing code"
- "Already spent X hours, deleting is wasteful"
- "TDD is dogmatic, I'm being pragmatic"
- "This is different because..."

**All of these mean: Delete code. Start over with TDD.**

## Final Rule

```
Production code → test exists and failed first
Otherwise → not TDD
```

No exceptions without your human partner's permission.