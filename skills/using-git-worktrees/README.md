# Using Git Worktrees

Isolated development branches using git worktrees.

## Purpose

Keeps the main workspace clean while developing features. Enables parallel work on multiple branches without stashing or context switching overhead.

## Features

- **Clean Workspace**: Main directory stays on main branch
- **Parallel Development**: Multiple worktrees simultaneously
- **Quick Setup**: One command to create isolated environment
- **Easy Cleanup**: Simple removal when done

## When to Use

- Starting a new feature
- Fixing a complex bug
- Working on multiple related changes
- Any development taking > 30 minutes

## Workflow

```
Verify Clean → Create Worktree → Setup → Develop → Finish
```

## Commands

| Command | Purpose |
|---------|---------|
| `git worktree add ../feature -b feature` | Create worktree |
| `git worktree list` | Show active worktrees |
| `git worktree remove ../feature` | Clean up |
| `git worktree prune` | Remove stale entries |
