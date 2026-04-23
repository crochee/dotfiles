# Defense in Depth Debugging

Techniques for narrowing down bug scope through layered investigation.

## Assertion Injection

Systematically add assertions to eliminate possibilities:

```
Layer 1: Input validation — Is the input what we think it is?
Layer 2: State validation — Is internal state consistent?
Layer 3: Pre-condition validation — Are function assumptions met?
Layer 4: Post-condition validation — Does output match contract?
Layer 5: Integration validation — Do components agree on protocol?
```

When all layers have assertions, the first failing assertion = the bug.

## Boundary Checking

Many bugs live at boundaries:

- Empty inputs: `[]`, `{}`, `""`, `None`
- Single-element inputs: `[1]`
- Maximum-size inputs: lists with 10,000 items
- Zero and negative numbers: `0`, `-1`
- Boundary values: `len(array) - 1`, `len(array)`

Test each boundary. The one that behaves differently = the bug.

## Condition-Based Waiting

For timing-dependent bugs (race conditions, async issues):

**Never use fixed timeouts.** They mask the problem and make tests flaky.

Instead, wait for the condition you actually care about:

```pseudocode
// BAD — arbitrary timeout, might be too short or waste time
sleep(5 seconds)
check_result()

// GOOD — poll until condition is met, with max wait
function wait_for(condition, max_wait=10s, interval=100ms):
    start = now()
    while now() - start < max_wait:
        if condition():
            return true
        sleep(interval)
    return false  // Timeout — this IS a bug

// Usage
assert wait_for(task.is_complete()), "Task did not complete"
```

This approach:
- Fails fast when condition is met (no wasted time)
- Fails explicitly when condition is NEVER met (this is the real bug)
- Makes timing bugs deterministic and reproducible

## Isolating the Variable

When multiple factors could cause the bug:

1. Change ONE variable at a time
2. Keep everything else constant
3. Observe: does behavior change?
4. If yes: that variable is involved. If no: move to next variable.

Example for a failing API call:
- Same code, different endpoint → different behavior? Network vs code issue.
- Same endpoint, different code → different behavior? Code issue.
- Same everything, different time → different behavior? Time-dependent state.

## Logging Strategy

When you need to add logging for debugging:

- Log at decision points (if/else branches)
- Log at state transitions (state machine changes)
- Log at boundaries (entering/leaving functions)
- Include: what you expected, what you got, why they differ
- Remove or convert to debug-level logging after fix

```pseudocode
// Good debug log
logger.debug(
    "ProcessX: expected status=200, got status=%s for request_id=%s. "
    "This means %s.",
    response.status, request_id,
    "server rejected our input" if response.status == 400 else "server error"
)
```
