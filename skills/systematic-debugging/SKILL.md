---
name: systematic-debugging
description: >
  4-phase root cause debugging process: reproduce, locate, fix, regression test.
  Includes root-cause-tracing, defense-in-depth, and condition-based-waiting techniques.
  Use when debugging bugs, investigating failures, or when the user mentions debugging,
  root cause analysis, troubleshooting, or systematic investigation.
---

# Systematic Debugging

## When to Use This Skill

This skill activates when:
- A bug report is received
- Tests are failing and root cause is unknown
- The user mentions debugging, troubleshooting, root cause analysis
- Behavior differs from expected
- System is crashing or producing incorrect output

## Core Principle

**Never guess. Never apply random fixes.** Every debugging step must be deliberate and evidence-based.

## 4-Phase Process

```
Phase 1: REPRODUCE → Phase 2: LOCATE → Phase 3: FIX → Phase 4: REGRESSION
```

### Phase 1: Reproduce

**Goal:** Establish a reliable, minimal reproduction case.

1. **Gather symptoms:** What exactly is failing? Error messages, stack traces, unexpected output.
2. **Create minimal reproduction:** Strip away everything non-essential. Find the smallest input/state that triggers the bug.
3. **Verify reproducibility:** Run the reproduction case 3 times. It must fail consistently.
4. **Document:** Write the reproduction steps to `.agents/debug/reproduction.md`.

**Exit criteria:** You can trigger the bug on command with a minimal test case.

### Phase 2: Locate

**Goal:** Identify the exact line(s) of code causing the failure.

Apply techniques from:
- [references/root-cause-tracing.md](references/root-cause-tracing.md) — Binary search, git bisect, data flow analysis
- [references/defense-in-depth.md](references/defense-in-depth.md) — Assertion injection, boundary checking

**Techniques by situation:**

| Situation | Technique |
|-----------|-----------|
| Known failing test | Binary search through code path |
| Regression (worked before) | `git bisect` to find breaking commit |
| Intermittent failure | Condition-based-waiting, add logging |
| Wrong output | Data flow tracing from input to output |
| Crash/panic | Stack trace analysis, core dump |

**Process:**
1. Start from the symptom (error/failure)
2. Trace backward through the call stack
3. At each layer, add assertions or logging to narrow scope
4. Stop when you find the first point where reality diverges from expectation
5. Verify: if you fix THIS line, would the symptom disappear?

**Exit criteria:** You can point to specific file:line(s) and explain WHY they cause the failure.

### Phase 3: Fix

**Goal:** Apply the minimal fix that resolves the root cause.

1. **Write the fix:** Minimal change that addresses the root cause identified in Phase 2.
2. **Verify fix:** Run the reproduction case. It must now pass.
3. **Delete workaround code:** If you wrote any code before the fix (e.g., debugging patches), delete it. The fix should be clean.
4. **Document:** Write what was fixed and why to `.agents/debug/fix.md`.

**Exit criteria:** Reproduction case passes. Fix is minimal and targeted.

### Phase 4: Regression Test

**Goal:** Ensure the fix is permanent and doesn't break anything else.

1. **Write regression test:** Add a test case that covers the exact reproduction scenario. This test MUST fail without the fix and pass with it.
2. **Red-Green verification:**
   - Temporarily revert the fix
   - Run the new test — it MUST fail
   - Restore the fix
   - Run the new test — it MUST pass
3. **Full test suite:** Run all existing tests. No regressions allowed.
4. **Edge cases:** Consider related edge cases. Add tests if needed.

**Exit criteria:** Regression test is committed. Full test suite passes. Fix is proven permanent.

## Anti-Patterns

| Anti-Pattern | Why It Fails | Correct Approach |
|---|---|---|
| "Let me try this fix" | Random guessing wastes time | Reproduce first, then locate |
| Increasing timeouts | Masks race conditions | Find the real synchronization issue |
| Adding try-catch everywhere | Hides root cause | Find why exception is thrown |
| "I'll fix it without a test" | No regression protection | Always write regression test |
| Fixing symptoms | Bug will resurface | Find root cause, not surface error |

## Debug Session State

Write to `.agents/debug/session.json` at each phase transition:

```json
{
  "schemaVersion": "1.0",
  "phase": 2,
  "status": "in_progress",
  "reproduction": ".agents/debug/reproduction.md",
  "suspectFiles": ["src/module/file.ts:123"],
  "hypothesis": "Null value not handled in edge case",
  "lastCheckpoint": "2024-01-15T10:30:00Z"
}
```

## Output Specification

- Always report: root cause, fix applied, regression test added
- Provide file:line references for all findings
- Include reproduction steps for future reference
- Flag if fix has side effects or performance implications

## When NOT to Use

- Bug is already fully understood (skip to Phase 3)
- Adding new features (use TDD instead)
- Performance optimization (use profiling tools)

## References

- [references/root-cause-tracing.md](references/root-cause-tracing.md) — Advanced tracing techniques
- [references/defense-in-depth.md](references/defense-in-depth.md) — Assertion injection, boundary checking, condition-based-waiting
