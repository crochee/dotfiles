# Finishing a Development Branch

Complete branch lifecycle: verify, present options, cleanup.

## Purpose

Provides a structured way to finish development work. Verifies tests pass, presents clear options (merge/PR/keep/discard), and ensures clean worktree cleanup.

## Features

- **Test Verification**: Full suite must pass before proceeding
- **Four Clear Options**: Merge, PR, Keep, or Discard
- **Worktree Cleanup**: Automatic cleanup of worktrees and branches
- **Stale Prevention**: Prunes orphaned worktrees

## When to Use

- All tasks complete
- Development finished
- Before merging or creating PR
- When closing a development branch

## Options

| Option | Action | Use Case |
|--------|--------|----------|
| Merge | Local merge | Confident, small change |
| PR | Push + pull request | Team review required |
| Keep | Leave for later | More work needed |
| Discard | Delete everything | Experiment failed |

## Workflow

```
Verify Tests → Present Options → Execute → Cleanup
```
