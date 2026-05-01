---
name: git-workflow
description: Git workflow patterns including branching strategies, commit conventions, merge vs rebase, conflict resolution, and collaborative development best practices for teams of all sizes.
metadata:
  author: skills-team
  version: 2.0.0
---

# Git Workflow

Best practices for Git version control, branching strategies, and collaborative development.

## When to Activate

- Setting up Git workflow for a new project
- Deciding on branching strategy
- Writing commit messages and PR descriptions
- Resolving merge conflicts
- Managing releases and version tags
- Onboarding new team members

## Quick Start

### 1. Choose Branching Strategy

- **GitHub Flow** - Simple, continuous deployment (recommended for most)
- **Trunk-Based** - High-velocity teams with feature flags
- **GitFlow** - Enterprise, scheduled releases

See [references/branching-strategies.md](references/branching-strategies.md) for complete guide.

### 2. Use Conventional Commits

```
<type>(<scope>): <subject>

[optional body]

[optional footer(s)]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `perf`, `ci`, `revert`

See [references/commit-conventions.md](references/commit-conventions.md) for examples and templates.

### 3. Merge vs Rebase

- **Merge** - Preserves history, good for shared branches
- **Rebase** - Linear history, good for local feature branches

See [references/merge-rebase.md](references/merge-rebase.md) for workflow and guidelines.

## Core Workflows

### Starting a Feature

```bash
git checkout main
git pull origin main
git checkout -b feature/description
# Make changes, commit
git push -u origin feature/description
# Open Pull Request
```

See [references/common-workflows.md](references/common-workflows.md) for more workflows.

## References

| Topic | File |
|-------|------|
| Branching Strategies | [references/branching-strategies.md](references/branching-strategies.md) |
| Commit Conventions | [references/commit-conventions.md](references/commit-conventions.md) |
| Merge vs Rebase | [references/merge-rebase.md](references/merge-rebase.md) |
| Pull Request Workflow | [references/pr-workflow.md](references/pr-workflow.md) |
| Conflict Resolution | [references/conflict-resolution.md](references/conflict-resolution.md) |
| Branch Management | [references/branch-management.md](references/branch-management.md) |
| Release Management | [references/release-management.md](references/release-management.md) |
| Git Configuration | [references/git-config.md](references/git-config.md) |
| Common Workflows | [references/common-workflows.md](references/common-workflows.md) |

## Assets

Use these templates in your projects:

- [assets/.gitmessage](assets/.gitmessage) - Commit message template
- [assets/pr-template.md](assets/pr-template.md) - Pull Request description template
- [assets/.gitignore](assets/.gitignore) - Common Gitignore patterns
