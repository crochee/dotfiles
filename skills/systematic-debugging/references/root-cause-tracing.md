# Root Cause Tracing

Techniques for locating the exact source of bugs through systematic investigation.

## Binary Search Through Code Path

When you know input A causes failure but don't know where:

1. Find the entry point that processes A
2. Find the point where failure occurs (error/exception)
3. Pick a midpoint in the code path between entry and failure
4. Add logging/assertion at midpoint: "Is data still valid here?"
5. If valid: bug is after midpoint. If invalid: bug is before midpoint.
6. Repeat until you narrow to 1-3 lines.

## Git Bisect

For regressions (code worked before, broken now):

```bash
git bisect start
git bisect bad                  # Current broken commit
git bisect good <known-good>    # Last known working commit
# Git checks out midpoint commit
# Run test: does it pass or fail?
git bisect good   # or git bisect bad
# Repeat until git identifies the breaking commit
git bisect reset  # Clean up
```

Once you have the breaking commit:
- Read the diff: what changed?
- Why did that change cause this failure?
- Is the fix in the changed code, or did it expose a pre-existing bug?

## Data Flow Tracing

For "wrong output" bugs (no crash, just incorrect results):

1. Start from the expected output and work backward
2. At each transformation step, ask: "What should the data look like here?"
3. Add assertions: `assert data.expected_field is not None, "Field missing at step X"`
4. The first assertion that fires = the bug location

Example:
```pseudocode
// Expected: user.profile.avatar_url should be a valid HTTPS URL
// Actual: None

// Step 1: Is avatar_url set in DB?
assert user.profile.avatar_url is not None  // Passes - DB has data

// Step 2: Is it loaded in the query?
assert 'avatar_url' in loaded_fields  // Fails - field not in query

// Root cause: query missing avatar_url field
```

## Stack Trace Analysis

For crashes/exceptions:

1. Read the FULL stack trace (not just the top line)
2. Identify: which of these frames is YOUR code?
3. Start investigation from YOUR code frame, not the library frame
4. Ask: "What did I pass to this library that caused it to fail?"

Common mistake: Blaming the library. The library is usually correct; your input was wrong.

## Call Graph Tracing

When a function behaves unexpectedly:

1. Who calls this function? (callers)
2. What does this function call? (dependencies)
3. What global state does it depend on?
4. What assumptions does it make about its inputs?

Add defensive assertions at function entry:
```pseudocode
function process_data(data):
    assert data is not None, "process_data called with None"
    assert typeof(data) == dict, "Expected dict, got " + typeof(data)
    assert 'required_field' in data, "Missing required_field"
    // ... rest of function
```

The first failing assertion = the caller passing invalid data.
