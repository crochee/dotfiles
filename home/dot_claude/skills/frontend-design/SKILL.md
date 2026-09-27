---
name: frontend-design
description: Use when building web components, pages, or visually distinctive interfaces where design quality matters as much as code quality.
metadata:
  author: skills-team
---

# Frontend Design

Use when the task is "make it look designed," not just "make it work."

For: landing pages, dashboards, app shells, components, visual systems, design systems.

**Core principle:** Pick a direction and commit to it. Safe-average UI is usually worse than a strong, coherent aesthetic with a few bold choices.

## Design Workflow

### 1. Frame the Interface

Settle before coding:
- purpose, audience, emotional tone, visual direction
- one thing the user should remember

Directions: brutal minimal, editorial, industrial, luxury, playful, geometric, retro-futurist, soft organic, maximalist

**Do not mix directions.** Choose one and execute cleanly.

### 2. Build Visual System

Define:
- type hierarchy, color variables, spacing rhythm
- layout logic, motion rules, surface/border/shadow treatment

Use CSS variables/token system for coherence.

### 3. Compose with Intention

Prefer:
- asymmetry when it sharpens hierarchy
- overlap when it creates depth
- strong whitespace when it clarifies focus

Avoid defaulting to symmetrical card grid unless clearly right.

### 4. Make Motion Meaningful

Use animation to reveal hierarchy, stage information, reinforce user action, create memorable moments.

**One well-directed load sequence > twenty random hover effects.**

## Strong Defaults

| Element | Guideline |
|---------|-----------|
| Typography | Fonts with character, distinctive display + readable body |
| Color | One dominant field + selective accents (avoid generic purple gradients) |
| Background | Atmosphere: gradients, meshes, textures, subtle noise |
| Layout | Break grid when composition benefits, use diagonals/offsets |

**See [references/design-audit.md](references/design-audit.md) for 10-dimension scoring rubric.**

## Component Patterns

```typescript
// Composition over inheritance
function Card({ children, variant = 'default' }) {
  return <div className={`card card-${variant}`}>{children}</div>
}

// Custom hooks
function useToggle(initialValue = false): [boolean, () => void] {
  const [value, setValue] = useState(initialValue)
  return [value, useCallback(() => setValue(v => !v), [])]
}
```

**See [references/react-patterns.md](references/react-patterns.md) for compound components, performance, accessibility.**

## Design System Audit

| Mode | Purpose | Output |
|------|---------|--------|
| **Generate** | Create cohesive design system | `DESIGN.md`, `design-tokens.json`, `design-preview.html` |
| **Visual Audit** | Score UI across 10 dimensions | Score + fixes with file:line |
| **AI Slop Detection** | Identify generic patterns | Flag: gradients, purple-blue, glass morphism |

**See [references/design-audit.md](references/design-audit.md) for full rubric.**

## Quality Gate

Before delivering:
- [ ] Clear visual point of view
- [ ] Intentional typography and spacing
- [ ] Color/motion support product (not random decoration)
- [ ] Does not read like generic AI UI
- [ ] Production-grade implementation

## References

- [references/react-patterns.md](references/react-patterns.md) - Compound components, hooks, memoization, virtualization
- [references/design-audit.md](references/design-audit.md) - 10-dimension scoring, AI slop detection