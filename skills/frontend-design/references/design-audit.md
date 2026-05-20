# Design Audit Reference

**Load this reference when:** auditing existing UI, scoring design quality, detecting AI slop.

## 10-Dimension Scoring Rubric

Score each dimension 0-10 with specific examples and fixes (file:line).

### 1. Color Consistency
- 0-3: Random hex values, no palette
- 4-6: Some palette but inconsistent usage
- 7-10: Cohesive palette, intentional usage

### 2. Typography Hierarchy
- 0-3: No hierarchy, all same size/weight
- 4-6: Some hierarchy, h1 > h2 > body clear
- 7-10: Clear h1 > h2 > h3 > body > caption

### 3. Spacing Rhythm
- 0-3: Arbitrary spacing
- 4-6: Some scale (8px/16px/24px) but inconsistent
- 7-10: Consistent scale throughout

### 4. Component Consistency
- 0-3: Similar elements look different
- 4-6: Some consistency, exceptions exist
- 7-10: All similar elements look identical

### 5. Responsive Behavior
- 0-3: Broken at breakpoints
- 4-6: Mostly responsive, some issues
- 7-10: Fluid, works at all sizes

### 6. Dark Mode
- 0-3: None or half-done
- 4-6: Partial support
- 7-10: Complete dark mode

### 7. Animation
- 0-3: None or gratuitous
- 4-6: Some purposeful, some random
- 7-10: Purposeful, enhances UX

### 8. Accessibility
- 0-3: Poor contrast, no focus states
- 4-6: Meets AA, some issues
- 7-10: AAA contrast, clear focus states

### 9. Information Density
- 0-3: Cluttered, overwhelming
- 4-6: Some density issues
- 7-10: Clean, appropriate density

### 10. Polish
- 0-3: No hover states, broken transitions
- 4-6: Some polish, missing details
- 7-10: Hover states, transitions, loading states, empty states

## AI Slop Detection

### Indicators of Generic AI Design

- **Gratuitous gradients** on everything
- **Purple-to-blue defaults** without purpose
- **"Glass morphism"** cards with no purpose
- **Excessive rounded corners** on things that shouldn't be rounded
- **Excessive animations** on scroll
- **Generic hero** with centered text over stock gradient
- **Sans-serif font stack** with no personality
- **Inter/Roboto/Open Sans** without customization
- **Card grids** that all look the same
- **Stock photo** heroes with generic people
- **Blue/purple gradients** on buttons and backgrounds
- **Shadows everywhere** without purpose

### What Good Design Looks Like

- **Intentional variety** — elements that should differ do differ
- **Purposeful constraints** — limited color palette, consistent spacing
- **Personality** — distinctive fonts, unique layouts
- **Context-appropriate** — design fits the product, not generic

## Mode 1: Generate Design System

### Process
```
1. Scan CSS/Tailwind/styled-components for existing patterns
2. Extract: colors, typography, spacing, border-radius, shadows, breakpoints
3. Research 3 competitor sites for inspiration (via browser MCP)
4. Propose design token set (JSON + CSS custom properties)
5. Generate DESIGN.md with rationale for each decision
6. Create interactive HTML preview page (self-contained, no deps)
```

### Output
- `DESIGN.md` — Design decisions and rationale
- `design-tokens.json` — Token definitions
- `design-preview.html` — Interactive preview

## Mode 2: Visual Audit

### Process
```
1. Take snapshot of UI
2. Score across 10 dimensions
3. For each low score: specific examples + fix with file:line
4. Generate prioritized fix list
```

## Mode 3: AI Slop Detection

### Process
```
1. Scan for generic patterns (see indicators above)
2. Flag specific instances
3. Propose alternatives
4. Generate cleaner design direction
```