---
name: workflow
description: >
    Total controller for spec-driven development using OpenSpec.Use when starting any conversation - establishes how to find and use skills, requiring Skill tool invocation before ANY response including clarifying questions
compatibility: Requires OpenSpec CLI
---

# Workflow Skill

## When to Use

Use this skill for:
- New feature development
- Complex refactoring
- Complex bug fixes
- User mentions "workflow", "SDD", "spec-driven", "openspec", "structured development"

## Iron Rules (Must Follow Unconditionally)

1. **OpenSpec is mandatory** - No fallback, no manual mode
2. **Workflow is total controller** - Sub-skills cannot decide next steps
3. **Fixed task generation path** - brainstorming → openspec-propose → approval → workflow
4. **Only proposal phase may require human review** - All other phases proceed without interruption
5. **Sequential execution** - Never parallelize phases
6. **Style and version locking** - code-style-spec + dependency versions
7. **Single responsibility** - One change solves exactly one problem

## Five-Phase Workflow

```
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4
(Init)   (Legacy) (Requirements) (Implementation) (Sync)
```

### Phase 0: Initialization

Check if OpenSpec config is complete. Execute `openspec init --tools <ide>` if needed. Write `phase0-init.json`.

### Phase 1: Legacy Analysis

Use `Skill` tool to invoke `openspec-explore`. Agent review (no human interruption). Write `phase1-legacy.json`.

### Phase 2: Requirements Specification

- If requirements are vague: Use `Skill` tool to invoke `brainstorming`
- Use `Skill` tool to invoke `openspec-propose`
- If requirements were vague: Get human approval on change proposal; otherwise: Agent review (no human interruption)
- Write `phase2-proposal.json`

### Phase 3: Implementation

Core task loop.

**CRITICAL: Do NOT invoke `openspec-apply-change`. Workflow manages task loop manually.**

First use `Skill` tool to invoke `using-git-worktrees` to create isolated workspace.

#### Task Scheduling Decision
- **Independent tasks** (no dependencies): Use `Skill` tool to invoke `dispatching-parallel-agents`
- **Dependent tasks** (requires previous output): Use `Skill` tool to invoke `executing-plans`

#### Per-Task Execution Loop

For each task in `tasks.md`:
1. Use `Skill` tool to invoke `test-driven-development`
2. Use `Skill` tool to invoke `solid` - Apply SOLID principles, clean code practices, and professional software design
3. Use `Skill` tool to invoke `requesting-code-review`
4. If issues found: Use `Skill` tool to invoke `receiving-code-review`
5. If tests fail: Use `Skill` tool to invoke `systematic-debugging`
6. Mark task complete (`- [x]`)
7. Update state file

#### Final Commit (All Tasks Completed)

After **all tasks complete** and verified:
1. Verify git status and ensure all changes are staged
2. Git add changed files: `git add <files>`
3. Git commit with conventional format: `git commit -m "<type>[scope]: <description>"`
4. Use `Skill` tool to invoke `verification-before-completion`

### Phase 4: Synchronization

1. Use `Skill` tool to invoke `openspec-archive-change`
2. Use `Skill` tool to invoke `finishing-a-development-branch`
3. Agent review (no human interruption)
4. Write `phase4-archive.json`

## Skill Invocation Matrix

| Phase | Skill | When to Use
|-------|-------|------------
| 0 | — | openspec init
| 1 | openspec-explore | System spec snapshot
| 2 | brainstorming(optional) + openspec-propose | Requirements clarification + change proposal
| 3 | using-git-worktrees | Create isolated workspace
| 3 | dispatching-parallel-agents | For independent tasks (optional)
| 3 | executing-plans | For dependent tasks (optional)
| 3 | test-driven-development | Every task (RED-GREEN-REFACTOR)
| 3 | solid | Apply SOLID principles, clean code, professional design
| 3 | requesting-code-review + receiving-code-review | Code review per task
| 3 | systematic-debugging | Root cause analysis
| 3 | verification-before-completion | Quality gates (after all tasks + commit)
| 4 | openspec-archive-change + finishing-a-development-branch | Spec archive + merge decision

## Quality Gates

### Pre-Implementation Gates
- Clean workspace
- Baseline tests pass
- Dependencies installed

### Per-Task Gates
- Tests pass
- No new warnings
- Follows plan
- No scope creep
- Error handling covered
- Style compliance

### Integration Gates (All Tasks Completed)
- Full test suite passes
- Build successful
- Lint clean
- Typecheck clean
- Coverage >= 80%
- openspec validate passes

## Commit Format

```
<type>[scope]: <description>
```

Types: feat, fix, docs, style, refactor, perf, test, chore, revert, build, ci

Examples:
```
feat(auth): add OAuth2 login
fix(api): correct response schema
```

## Resume from Existing State

If state files exist, check for highest completed phase and resume from next phase:
- Read all `phase*.json` files
- Resume from appropriate phase based on existing progress
- Re-verify completed tasks before proceeding

## State Files

```
.agents/state/
├── phase0-init.json
├── phase1-legacy.json
├── phase2-proposal.json
├── phase3-impl.json
└── phase4-archive.json
```
