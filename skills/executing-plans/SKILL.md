---
name: executing-plans
description: >
  Serial batch execution of implementation plans with human checkpoints.
  Reads tasks from tasks.md or plan.md, executes each with TDD + review,
  supports resume from state. Use after planning, during implementation,
  or when user mentions executing plans, batch implementation, or task execution.
  Different from dispatching-parallel-agents: this is for dependent task chains.
---

# Executing Plans

## When to Use This Skill

This skill activates when:
- An implementation plan exists (from `writing-plans` or `openspec-propose`)
- Tasks have dependencies and must be executed in order
- You need serial execution with checkpoints (not parallel)
- The user mentions executing plans, implementing tasks, or batch execution

**vs `dispatching-parallel-agents`:**
- Use THIS skill for tasks with dependencies (Task B needs Task A's output)
- Use `dispatching-parallel-agents` for independent tasks (3+ unrelated failures)

## Core Workflow

### Step 0: Load Plan and State

1. **Identify task source:**
   - OpenSpec available: `openspec/changes/<name>/tasks.md`
   - Fallback mode: `.agents/plan.md`

2. **Check for resume state:**
   - Read `.agents/state/phase5-impl.json` if exists
   - If `status === "in_progress"`: resume from `currentTask`
   - If no state file: start from first task

3. **Verify prerequisites:**
   - Workspace is clean (`git status`)
   - Dependencies installed
   - Baseline tests pass

### Step 1: Execute Task Loop

For each task in dependency order:

#### 1.1 Read Task Specification

```
Task: [ID] [Name]
Files: [exact paths]
Action: [what to do]
Code: [expected output]
Verify: [how to confirm]
```

If task specification is ambiguous: **STOP**. Flag the ambiguity. Do NOT guess.

#### 1.2 Implement with TDD

Delegate to `test-driven-development` skill:
- RED: Write failing test for the task
- GREEN: Write minimal code to pass
- REFACTOR: Clean up (tests stay green)

**Iron law:** No production code without a failing test first.

#### 1.3 Two-Round Review

After TDD completes for this task:

**Round 1: Code Quality Review**
- Delegate to `requesting-code-review` skill (code quality round)
- Checks: tests pass, no warnings, follows plan, clean code, error handling
- Critical/Major issues: BLOCK, fix immediately

**Round 2: Spec Compliance Review**
- Check implementation against spec requirements:
  - Does code match the task's expected output?
  - Are all edge cases from spec covered?
  - Is the implementation within task scope (no scope creep)?
- Critical mismatches: BLOCK, fix immediately

#### 1.4 Human Checkpoint

After every 3-5 tasks (or at dependency boundaries):
- Present progress summary
- Ask: "Continue with next batch or review?"
- Wait for confirmation before proceeding

#### 1.5 State Checkpoint

After each task completes successfully:

```json
{
  "schemaVersion": "1.0",
  "phase": 5,
  "changeName": "<name>",
  "status": "in_progress",
  "tasksCompleted": ["1.1", "1.2", "1.3"],
  "currentTask": "1.4",
  "source": "openspec|plan",
  "lastCheckpoint": "2024-01-15T10:30:00Z"
}
```

Write atomically: write to temp file, then `mv` to target.

### Step 2: Integration Checkpoint

When all tasks complete:

1. Run full test suite — all must pass
2. Run `verification-before-completion`: verify ALL gates pass
3. Present implementation summary:
   - Tasks completed: X/Y
   - Tests passing: all
   - Review status: passed
   - Scope: within bounds / deviations noted

## Error Handling

| Situation | Action |
|-----------|--------|
| Task fails TDD after 3 attempts | Flag as blocked, continue with other tasks |
| Review finds critical issue | Fix immediately, re-review |
| Ambiguous task spec | STOP, flag ambiguity, ask for clarification |
| State file corrupted | Start from scratch, warn user |
| Test suite regression | Identify which task caused it, rollback that task |

## Resume Behavior

When resuming from a checkpoint:

1. Read last state from `.agents/state/phase5-impl.json`
2. Verify completed tasks still pass tests
3. Skip completed tasks
4. Resume from `currentTask`
5. If `currentTask` was in progress: re-verify it from scratch

## Output Specification

- Report progress after each task: `[X/Y] Task name: PASS/FAIL`
- Report integration checkpoint with full test results
- Present summary at completion with evidence (test output)
- Flag any tasks that deviated from plan

## When NOT to Use

- Tasks are independent (use `dispatching-parallel-agents` instead)
- No plan exists yet (use `writing-plans` or `openspec-propose` first)
- Trivial single-task change (just do it directly)
- Debugging unknown issues (use `systematic-debugging` first)
