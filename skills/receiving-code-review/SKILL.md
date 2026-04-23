---
name: receiving-code-review
description: >
  Standard process for responding to code review feedback. Handles severity-graded
  issues (Critical/Major/Minor/Nit), fixes with verification, and re-review cycles.
  Use after receiving code review feedback, when addressing review comments,
  or when user mentions review response, fixing review issues, or review cycle.
---

# Receiving Code Review

## When to Use This Skill

This skill activates when:
- Code review feedback has been received
- Review issues need to be addressed
- The user mentions review response, fixing review comments, or review cycle
- After `requesting-code-review` returns findings

## Core Principle

**Every review finding is an opportunity to improve code quality, not a personal criticism.** Treat all feedback objectively, fix systematically, and verify thoroughly.

## Severity Response Protocol

| Severity | Response Time | Verification Required | Blocks Progress? |
|----------|--------------|----------------------|------------------|
| **Critical** | Immediate | Full re-review | YES |
| **Major** | Within 2 tasks | Re-run relevant tests | Conditional |
| **Minor** | Before completion | Self-verify | No |
| **Nit** | When convenient | Visual check | No |

## Response Workflow

### Step 1: Acknowledge and Categorize

Read the full review report. For each finding:

```
Finding: [reviewer's description]
Severity: [Critical/Major/Minor/Nit]
Agreement: [AGREE / DISAGREE WITH REASON]
Action: [FIX / CLARIFY / ACCEPT]
```

If you DISAGREE:
- State your reasoning clearly with evidence
- Ask for clarification, not debate
- Default to reviewer's judgement on style/preferences

### Step 2: Fix Critical Issues First

Critical issues BLOCK all progress:

1. **Read the finding** — Understand exactly what's wrong
2. **Locate the code** — File:line reference from review
3. **Apply the fix** — Minimal change that resolves the issue
4. **Verify the fix:**
   - Run relevant tests
   - Confirm the specific issue is resolved
   - Ensure no new issues introduced
5. **Mark as resolved** — Document what was fixed and how

### Step 3: Fix Major Issues

Major issues must be fixed within 2 tasks:

1. Group related major issues (fix together if possible)
2. Apply fixes following TDD discipline (test first if behavioral change)
3. Verify each fix independently
4. Mark as resolved with evidence

### Step 4: Address Minor Issues and Nits

Batch process minor issues and nits:

1. Group by file or by type (naming, comments, formatting)
2. Apply fixes efficiently
3. Self-verify — no full re-review needed
4. Mark as resolved

### Step 5: Re-Review Cycle

After all fixes are applied:

1. **Delegate to `requesting-code-review`** for re-review of fixed issues
2. Focus re-review on:
   - All Critical issues are resolved
   - All Major issues are resolved
   - Fixes don't introduce new problems
3. If re-review finds new issues: repeat from Step 1 for new findings only
4. Maximum 3 fix iterations per gate failure → escalate to human

## Response Format

After processing review feedback:

```markdown
## Review Response

### Critical Issues: [X/Y resolved]
- [ ] Issue 1: [description] → Fixed in file:line. Tests pass.
- [ ] Issue 2: [description] → Fixed in file:line. Tests pass.

### Major Issues: [X/Y resolved]
- [ ] Issue 1: [description] → Fixed in file:line.
- [ ] Issue 2: [description] → DISAGREE. Reason: [explanation]. Request clarification.

### Minor Issues: [X/Y resolved]
- [x] Issue 1: [description] → Fixed.
- [x] Issue 2: [description] → Fixed.

### Nits: [X/Y resolved]
- [x] All nits addressed.

### New Issues Introduced: [None / List]
[Verify no fixes caused regressions]

### Status: [READY FOR RE-REVIEW / BLOCKED ON CLARIFICATION]
```

## Anti-Patterns

| Anti-Pattern | Why It Fails | Correct Approach |
|---|---|---|
| Fixing without understanding | May apply wrong fix | Understand the root issue first |
| Defending bad code emotionally | Wastes time, damages trust | Accept feedback objectively |
| Fixing only what was explicitly named | Misses similar issues nearby | Apply the principle, not just the patch |
| Skipping verification after fix | Same bug may persist | Always re-test after fixing |
| Fixing nits before criticals | Wrong priority | Always: Critical → Major → Minor → Nit |

## Output Specification

- Always report resolution status for each finding
- Provide file:line references for all fixes
- Include test evidence for Critical/Major fixes
- Flag any disagreements with clear reasoning
- Present status: ready for re-review or blocked

## When NOT to Use

- No review feedback has been received yet
- You are the one initiating the review (use `requesting-code-review`)
- Trivial nits only (fix directly, no process needed)
