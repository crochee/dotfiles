---
name: finishing-a-development-branch
description: >
  Complete development branch lifecycle: verify tests, present merge/PR/keep/discard options, and clean up worktree. Use when tasks are complete, before merging, or when the user mentions finishing, merging, or branch cleanup.
---

# Finishing a Development Branch

## When to Use This Skill

This skill should be used when:
- All tasks from the implementation plan are complete
- Development in a worktree is finished
- The user mentions finishing, merging, or branch cleanup
- Before closing a development branch

## Core Workflow

### 1. Verify Tests Pass

```bash
# Run full test suite
npm test  # or equivalent
```

Verify:
- All tests pass
- No new warnings
- Coverage thresholds met
- Lint passes

### 2. Present Options

Show the user four clear options:

| Option | Action | When to Use |
|--------|--------|-------------|
| **Merge** | Merge into main/master locally | Confident, small change |
| **PR** | Push and create pull request | Team review required |
| **Keep** | Keep branch for later | More work needed |
| **Discard** | Delete branch and worktree | Experiment failed |

### 3. Execute Chosen Option

#### Merge Locally
```bash
git checkout main
git merge <feature-branch>
git worktree remove ../<feature-name>
git branch -d <feature-branch>
```

#### Create PR
```bash
git push origin <feature-branch>
# Platform-specific PR creation (gh, glab, etc.)
gh pr create --title "<title>" --body "<description>"
```

#### Keep Branch
```bash
# Leave worktree intact for future work
git worktree list  # Show active worktrees
```

#### Discard
```bash
git worktree remove ../<feature-name>
git branch -D <feature-branch>
```

### 4. Clean Up Worktree

```bash
# Verify no stale worktrees
git worktree list
git worktree prune
```

## Output Specification

- Always show test results before presenting options
- Present all 4 options with clear recommendations
- Confirm cleanup actions completed
- If tests fail, block and require fixes first

## When NOT to Use

- Tasks not yet complete
- Still actively developing
- Tests failing (fix first)