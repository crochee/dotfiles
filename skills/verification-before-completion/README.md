# Verification Before Completion

Enforce verification before making any success claims. Evidence before assertions, always.

## Core Principle

**NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE**

Claiming work is complete without verification is dishonesty, not efficiency.

## The Gate Function

Before claiming any status or expressing satisfaction:

1. **IDENTIFY**: What command proves this claim?
2. **RUN**: Execute the FULL command (fresh, complete)
3. **READ**: Full output, check exit code, count failures
4. **VERIFY**: Does output confirm the claim?
5. **ONLY THEN**: Make the claim

## When To Apply

**ALWAYS before:**
- Any variation of success/completion claims
- Any expression of satisfaction
- Any positive statement about work state
- Committing, PR creation, task completion
- Moving to next task
- Delegating to agents

## Common Verification Requirements

| Claim | Requires |
|-------|----------|
| Tests pass | Test command output: 0 failures |
| Linter clean | Linter output: 0 errors |
| Build succeeds | Build command: exit 0 |
| Bug fixed | Test original symptom: passes |
| Regression test works | Red-green cycle verified |

## Red Flags - STOP Immediately

- Using "should", "probably", "seems to"
- Expressing satisfaction before verification
- About to commit/push/PR without verification
- Trusting agent success reports
- Relying on partial verification
- Thinking "just this once"

## The Bottom Line

**No shortcuts for verification.**

Run the command. Read the output. THEN claim the result. This is non-negotiable.
