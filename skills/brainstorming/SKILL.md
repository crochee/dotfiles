---
name: brainstorming
description: >
  Activate before writing code to clarify requirements through Socratic questioning. Explores alternatives, presents design in sections for validation, and saves design document. Use when starting any new feature, refactoring, or when the user mentions brainstorming, requirements clarification, design exploration, or Socratic questioning.
---

# Brainstorming

## When to Use This Skill

This skill activates BEFORE any code is written, when:
- Starting a new feature
- Beginning a refactoring task
- The user asks "how should I approach X?"
- Requirements are unclear or vague
- Exploring alternative solutions
- The user mentions brainstorming, design, requirements, or architecture discussions

## Core Workflow

### 1. Socratic Questioning

Before proposing any solution, ask clarifying questions to understand the REAL problem:

- What are you trying to achieve? (Not how - WHAT)
- Who is this for?
- What constraints exist? (time, budget, technical)
- What have you tried before?
- What does "done" look like?

### 2. Explore Alternatives

Present at least 2-3 approaches with trade-offs:

| Approach | Pros | Cons | When to Use |
|----------|------|------|-------------|
| Simple/Conservative | Low risk, fast | Limited flexibility | MVP, tight deadlines |
| Balanced | Good compromise | Moderate complexity | Most cases |
| Sophisticated | Scalable, flexible | High complexity | Long-term, complex needs |

### 3. Present Design in Sections

Show design in digestible chunks, NOT walls of text:

1. Problem statement
2. Constraints identified
3. Options considered
4. Recommended approach
5. High-level architecture
6. Key decisions and trade-offs

Wait for user validation after each section.

### 4. Save Design Document

After validation, save to `.agents/design.md`:

```markdown
# Design: [Feature Name]

## Problem
[What problem are we solving?]

## Constraints
- [List of constraints]

## Chosen Approach
[Why this approach over alternatives?]

## Architecture
[High-level design]

## Key Decisions
| Decision | Rationale |
|----------|-----------|
| [Decision] | [Why] |

## Open Questions
- [Unresolved items]
```

## Output Specification

- Always present options with explicit trade-offs
- Never assume requirements - ask
- Save design document after validation
- Flag open questions explicitly

## CRITICAL CONSTRAINT: NO Task Generation

This skill's ONLY responsibility is requirements clarification and design exploration.

**MUST NOT:**
- Generate task lists, implementation plans, or step-by-step instructions
- Write any code or code snippets beyond minimal examples
- Proceed to implementation
- Call `writing-plans` or any task-generation skill

**Task generation is exclusively handled by `openspec-propose`.**
When used within the workflow skill, output is fed to `openspec-propose`, not to implementation.

## When NOT to Use

- Requirements are crystal clear and documented
- User explicitly wants to jump into coding
- Trivial changes (< 10 lines)