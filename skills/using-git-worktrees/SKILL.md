---
name: using-git-worktrees
description: >
  Create isolated git worktrees for parallel development branches. Keeps main workspace clean, enables context switching, and prevents dirty state. Use when starting new features, fixing bugs, or when the user mentions worktrees, isolated development, parallel branches, or clean workspace.
---

# Using Git Worktrees

## When to Use This Skill

This skill should be used when:
- Starting a new feature development
- Fixing a bug that requires investigation
- The user mentions worktrees, isolated development, or parallel branches
- Before any development that might take > 30 minutes
- Working on multiple related changes simultaneously

## Core Workflow

### 1. Verify Clean State

```bash
git status
```

If dirty: commit or stash before proceeding.

### 2. Create Worktree

```bash
# Create worktree in ../<feature-name>
git worktree add ../<feature-name> -b <feature-name>
```

### 3. Run Project Setup

```bash
cd ../<feature-name>
# Install dependencies if needed
npm install  # or equivalent for your project
# Verify baseline tests pass
npm test
```

### 4. Develop in Isolation

All development happens in the worktree directory:
- Branch is isolated from main workspace
- Can switch between worktrees freely
- Main workspace stays clean and usable

### 5. Finish Work

When done, use `finishing-a-development-branch` skill to:
- Verify tests pass
- Present merge/PR/keep/discard options
- Clean up worktree

## Worktree Management

### List Active Worktrees
```bash
git worktree list
```

### Remove a Worktree
```bash
# After merging or discarding branch
git worktree remove ../<feature-name>
```

### Prune Stale Worktrees
```bash
git worktree prune
```

## Output Specification

- Always show worktree creation confirmation
- Provide cleanup instructions when work is done
- Never leave orphaned worktrees

## When NOT to Use

- Trivial changes (< 5 lines)
- Documentation-only updates
- Quick experiments you plan to discard