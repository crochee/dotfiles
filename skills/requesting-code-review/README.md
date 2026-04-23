# Requesting Code Review

Systematic code review between tasks using severity-based issue reporting.

## Purpose

Ensures code quality by conducting structured reviews after each task completion. Issues are categorized by severity, with critical issues blocking progress.

## Features

- **Severity Classification**: Critical, Major, Minor, Nit
- **Plan Compliance**: Verifies implementation matches plan
- **Pre-Review Checklist**: Tests, lint, scope verification
- **Progress Gating**: Critical issues block, major must fix soon

## When to Use

- After completing a task
- Before moving to next task
- Before merging
- After any significant code change (> 50 lines)

## Workflow

```
Checklist → Compare to Plan → Classify Issues → Gate Progress
```

## Severity Matrix

| Level | Examples | Action |
|-------|----------|--------|
| Critical | Security, data loss, broken | BLOCK immediately |
| Major | Missing error handling | Fix within 2 tasks |
| Minor | Style, naming | Fix or document |
| Nit | Comments, formatting | Optional |
