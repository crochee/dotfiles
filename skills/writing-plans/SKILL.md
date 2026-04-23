---
name: writing-plans
description: >
  Break approved designs into bite-sized implementation tasks (2-5 minutes each). Every task has exact file paths, complete code, and verification steps. Use after design approval, before implementation, or when the user mentions implementation plan, task breakdown, writing plans, project planning, or work estimation.
---

# Writing Plans

## When to Use This Skill

This skill should be used when:
- Design has been approved via `brainstorming` skill
- Before any implementation begins
- Breaking work into granular tasks
- The user mentions implementation plan, task breakdown, or writing plans

## Core Principles

- **Bite-sized tasks**: Each task should take 2-5 minutes
- **Exact file paths**: No vague references
- **Complete code examples**: Show what to write
- **Clear verification**: How to know it works

## Plan Format

Save to `.agents/plan.md`:

```markdown
# Implementation Plan: [Feature Name]

## Task 1: [Descriptive Name]
- **Files**: `src/path/to/file.ts`
- **Action**: [What to do]
- **Code**: [Complete code snippet]
- **Verify**: [How to confirm it works]
- **Time**: ~3 minutes

## Task 2: [Descriptive Name]
...
```

## Task Structure

Each task must include:

1. **Exact file path**: `src/modules/users/UserService.ts`
2. **Specific action**: "Create UserService class with findById method"
3. **Complete code**: Full implementation, not pseudocode
4. **Verification step**: "Run `npm test -- UserService` - expect 3 tests passing"

## Example Tasks

### Task: Add User Validation

- **Files**: `src/users/validation.ts`
- **Action**: Create validation function for email and password
- **Code**:
  ```pseudocode
  function validateUser(input):
    errors = []
    if not isValidEmail(input.email):
      errors.add("Invalid email")
    if len(input.password) < 8:
      errors.add("Password too short")
    return { valid: len(errors) == 0, errors }
  ```
- **Verify**: Run `npm test -- validation` - expect 4 tests passing
- **Time**: ~3 minutes

## Ordering Rules

1. Dependencies first (types before implementations)
2. Tests before code (TDD principle)
3. Infrastructure before business logic
4. Backend before frontend integration

## Output Specification

- Always save plan to `.agents/plan.md`
- Include task count and estimated total time
- Mark tasks that can be parallelized
- Flag any tasks that seem > 5 minutes and split them

## When NOT to Use

- Design not yet approved (use `brainstorming` first)
- Trivial changes (< 3 tasks total)
- Exploratory work (scope unclear)