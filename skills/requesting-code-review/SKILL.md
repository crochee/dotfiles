---
name: requesting-code-review
description: >
  Conduct systematic code review between tasks using pre-review checklist. Reviews against plan, reports issues by severity. Critical issues block progress. Use after completing a task, before merging, or when the user mentions code review, quality check, or peer review.
---

# Requesting Code Review

## When to Use This Skill

This skill should be used when:
- A task from the implementation plan is complete
- Before moving to the next task
- Before merging a branch
- The user mentions code review, quality check, or peer review
- After any significant code change (> 50 lines)

## Core Workflow

### Round 1: Code Quality Review

For each completed task, verify:

| Check | Status | Notes |
|-------|--------|-------|
| Tests pass | [ ] | All related tests green |
| No new warnings | [ ] | Lint, typecheck, build |
| Follows plan | [ ] | Matches task specification |
| No scope creep | [ ] | Only changed what was required |
| Error handling | [ ] | Edge cases covered |
| Clean code | [ ] | Readable, maintainable |

### Round 2: Spec Compliance Review

Verify implementation against the specification artifacts:

**Check against `proposal.md`:**
- [ ] Data model changes match proposal's data model definition
- [ ] Business logic aligns with proposal's acceptance criteria
- [ ] No changes outside the proposal's stated scope
- [ ] Compatibility requirements from proposal are met

**Check against `design.md` (if exists):**
- [ ] API interfaces match design's endpoint definitions (method, path, params, response)
- [ ] Data structures match design's schema definitions
- [ ] Integration patterns match design's architecture decisions
- [ ] Error handling matches design's error strategy

**Check against `tasks.md`:**
- [ ] All sub-items of the task are implemented
- [ ] Verification steps from task definition pass
- [ ] No additional functionality beyond task scope (YAGNI)
- [ ] Task dependencies are correctly wired

**Check against delta specs (if OpenSpec):**
- [ ] Each ADDED requirement has corresponding implementation
- [ ] Each MODIFIED requirement is updated correctly
- [ ] Each REMOVED requirement's code is cleaned up
- [ ] No orphaned imports, functions, or types from REMOVED items

### Compare Implementation to Plan

Compare implementation to the plan (`writing-plans` output or `tasks.md`):

```
Task: [name]
Plan expected: [description from plan]
Implementation: [what was actually done]
Match: [YES / NO - explain]
```

### 3. Report Issues by Severity

| Severity | Description | Action |
|----------|-------------|--------|
| **Critical** | Security, data loss, broken functionality | BLOCK progress, fix immediately |
| **Major** | Missing error handling, incorrect behavior | Fix before continuing |
| **Minor** | Style inconsistencies, naming | Fix or note for later |
| **Nit** | Comment clarity, formatting | Optional fix |

### Gate Progress

- **Critical issues**: BLOCK - cannot proceed until resolved
- **Major issues**: Must fix within 2 tasks
- **Minor/Nit**: Can defer with documentation

### Both Rounds Must Pass

Round 1 (Code Quality) AND Round 2 (Spec Compliance) must both pass for overall PASS status.
If either round fails, report combined issues and block on critical findings.

## Review Output Format

```markdown
## Code Review: [Task Name]

### Overall Status: [PASS / FAIL / PASS WITH NOTES]

---

### Round 1: Code Quality

#### Critical Issues
- [None / List with file:line references]

#### Major Issues
- [None / List]

#### Minor Issues
- [None / List]

#### Nits
- [None / List]

---

### Round 2: Spec Compliance

#### Proposal Compliance
- [ ] Data model matches: [YES/NO - details]
- [ ] Scope boundaries: [YES/NO - details]
- [ ] Compatibility: [YES/NO - details]

#### Design Compliance
- [ ] API interfaces: [YES/NO/N/A - details]
- [ ] Data structures: [YES/NO/N/A - details]

#### Task Compliance
- [ ] All sub-items implemented: [YES/NO - details]
- [ ] Verification steps pass: [YES/NO - details]
- [ ] No scope creep: [YES/NO - details]

#### Delta Spec Compliance (if OpenSpec)
- [ ] ADDED requirements: [ALL COVERED / MISSING - details]
- [ ] MODIFIED requirements: [ALL UPDATED / MISSING - details]
- [ ] REMOVED requirements: [ALL CLEANED / ORPHANS - details]

---

### Summary
[Brief assessment of implementation quality and spec compliance]
```

## Output Specification

- Always report issues by severity level
- Critical issues MUST block progress
- Provide specific file:line references for issues
- Suggest concrete fixes, not just problems

## When NOT to Use

- Trivial changes (< 10 lines)
- Documentation-only updates
- Quick experiments in worktrees