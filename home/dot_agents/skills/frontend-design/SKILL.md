---
name: frontend-design
description: "Produces a screen a user can finish a job on: flows and five-state coverage, a token-driven visual system, accessible React, and rubric-scored audits. Use when planning UX flows, building a design system, fixing a templated UI, or auditing an interface against the visual and UX rubrics. Not for backend or API work, throwaway UI variants, or formal conformance statements (VPAT/ACR). 中文：UX 流程、设计系统、页面实现、界面打分审计。"
license: MIT
metadata:
  version: "1.1.0"
---

# Frontend Design

Produces a screen a user can finish a job on, and an interface that survives measurement: flows and state coverage first, a token-driven visual system second, accessible implementation third. Every quality claim carries evidence — a contrast ratio, a scan output, a screenshot of the real rendered surface.

## When to Use

Name the mode before starting; the deliverable differs.

- **UX** — plan a page or flow: user, job, journey, the five states, information architecture, wireframe specs. Needs no running surface and no code: the output is a spec an implementer can build from without coming back with questions.
- **Generate** — visual system and implementation: direction, token set, composed components, preview.
- **Audit** — score an existing interface on the visual rubric (10 dimensions) *and* the UX rubric (6 dimensions), then rank the fixes.
- **AI-slop** — find generic interface patterns, structural or stylistic, and name the concrete alternative for each.

Audit and AI-slop need a surface that can be observed: render it, or work from source and mark the visual dimensions `not scored`. The UX dimensions can be scored from source, because flows and states live in the code. A formal conformance claim (VPAT/ACR, procurement) is a different job — this skill produces design evidence, not a legal statement. Exploring what a UI should look like by building throwaway variants is separate work: build the variants, throw them away, and bring back what they taught; this skill's deliverable is the one surface that ships, with tokens and five states, and a mockup never satisfies its verification.

## Workflow

1. **Map product context.** Who the user is, the job they are hiring this screen for, the signal that the job succeeded, and the binding constraint (deadline, platform, a field the backend cannot supply). → `references/ux-flows.md`
   *Exit criterion:* one sentence names who completes what, where, and how you would know it worked.
2. **Model flows and states.** Draw the main journey, then walk the state matrix: empty, loading, error, partial, no-permission. Decide per screen whether a state is implemented or deliberately out of scope. → `references/ux-flows.md`
   *Exit criterion:* every screen's five states have an owner — an implementation, an explicit "not applicable, because …", or a recorded gap.
3. **Information architecture and wireframes.** Navigation structure, page inventory, and a wireframe spec per screen: content priority, primary action, secondary actions, responsive collapse, states. → `references/ia-wireframes.md`
   *Exit criterion:* an implementer can build the screen from the spec without asking what dominates, what the action is, or what happens while it loads.
4. **Visual direction and token set (Generate).** Write one sentence naming the direction, the audience and the one thing the user should remember; choose exactly one direction. Then write `design-tokens.json` as the single source of truth. → `references/design-tokens.md`
   *Exit criterion:* every colour, size, spacing value, radius, shadow and duration the UI uses resolves to a token, and the CSS matches the JSON.
5. **Compose and implement.** Apply the type scale, colour roles and spacing scale to the real components; implement the states the spec declared — a state that exists only in the spec is not implemented. → `references/react-patterns.md`
   *Exit criterion:* the primary surface renders at every declared breakpoint in both themes, with motion removed for users who ask for it, and every declared state is reachable in the build.
6. **Verify.** Contrast over the declared pairs, the automated accessibility scan, keyboard walk-through, reduced-motion, the performance measurement, and the UX checks (five states reachable, error copy actionable, form errors located at the field, keyboard path complete). → `references/design-audit.md`
   *Exit criterion:* every check ran and its output is recorded; a check that could not run is recorded as *not run*, never as a pass.
7. **Deliver.** Produce the artefact set for the mode and attach the evidence. → `## Output Contract`
   *Exit criterion:* the artefact set for the mode is complete and every claim points at a file, a measurement or a command output.

## Design Direction and Composition

### Hard floors

Pass/fail, not adjectives; they hold in every mode.

- **WCAG 2.2 AA contrast and keyboard operability** — every rendered pair meets the ratio for its role; every control is keyboard-operable with a visible, unobscured focus state.
- **`prefers-reduced-motion` honoured** — the opt-out is implemented, not promised.
- **A named performance budget** — CLS ≤ 0.1 and LCP ≤ 2.5 s, measured rather than estimated.
- **Functional equivalence** — restyling changes no behaviour; a component's contract is unchanged.
- **No clobbering of an existing token system** — extend it, or state the migration before replacing it.

**One direction per screen.** Brutal minimal, editorial, industrial, luxury, playful, geometric, retro-futurist, soft organic, maximalist — pick one and execute it cleanly. Two directions on one screen read as indecision, not as range.

| Element | Rule |
|---|---|
| Typography | A distinctive display face with a readable body face, or a deliberate system stack; a scale of at least five steps, each a token; measure 45–75 characters |
| Colour | One dominant field plus selective accents; the accent means one thing per screen (the primary action); status colours stay reserved for status |
| Background | Atmosphere where it serves the content — a texture, a gradient, a surface shift — not decoration on every surface |
| Layout | Break the grid where the composition gains hierarchy; whitespace is structure, not filler |

Composition choices (asymmetry, overlap, offset) are free **only** where they cost no contrast, focus visibility or target size. A dramatic layout that fails the accessibility gate is a bug.

## Token System

`design-tokens.json` is the single source of truth; the CSS custom properties are generated from it or checked against it, never where a value is first written. Components consume custom properties only — a raw hex, `px` size or `ms` duration in a component is a defect. Dark mode is one `[data-theme="dark"]` override block in the token layer; breakpoints are declared in the token file and mirrored by hand in media queries, because a media query cannot read a custom property.

Changing a value means: edit the JSON → regenerate the CSS → re-check every pair that uses the token → bump `meta.version`. Hand-editing generated CSS creates a second source of truth, which is how visual drift starts. Adopting an existing token system is the default when one exists.

Naming scheme, JSON shape, CSS mapping, dark-mode mechanics and the contrast-pair block are in `references/design-tokens.md`.

## Motion, Responsive Behaviour and Performance

One directed load sequence plus purposeful transitions; durations and easings from the token file; `transform` and `opacity` only; `prefers-reduced-motion: reduce` honoured. Responsive behaviour is defined at the declared breakpoints and nowhere else. Target size 24×24 CSS px is the SC 2.5.8 floor, 44×44 the primary-mobile target. Budget: CLS ≤ 0.1, LCP ≤ 2.5 s, measured. → `references/motion-and-performance.md`

## Audit Rubric and AI-Slop Detection

Two rubrics, scored separately: **visual `V`, 10 dimensions** weighted across accessibility, typography, colour roles, spacing, component consistency, responsive behaviour, density, polish and states, motion, dark mode; **UX `U`, 6 equal-weight dimensions** — `flow_coverage`, `state_completeness`, `ia_clarity`, `form_usability`, `content_hierarchy`, `error_recovery`.

`total = 0.6 × V + 0.4 × U`; pass requires `total ≥ 7.0`, `V ≥ 7.0`, `U ≥ 7.0` and zero critical or serious accessibility violations. When the visual surface cannot be observed, the visual dimensions are `not scored` and `total = U`, and the visual gate is reported as not run rather than passed. Weights, bands, the dimensional definitions, the normalization rule and the old-threshold note are in `references/design-audit.md`.

**Accessibility conformance is a gate, not a score** — a design that fails AA fails the audit whatever the total says.

Every finding cites evidence — a file, a line, a measured ratio — and names the fix as `path:line`. A finding without a location is an opinion.

The AI-slop table is a set of **observable symptoms**, each with a priority and a concrete alternative; it bans no font, brand or colour by name. It also flags **structural** slop, which is the harder class: no states, no empty state, invented data, a wall of identical cards. Both tables live in `references/design-audit.md`.

## Output Contract

State the directory you used; defaults are shown.

**UX mode** → `design/`:

- `flows.md` — Mermaid journey plus the five-state matrix per screen (from `assets/ux-spec.template.md`).
- `wireframes.md` — one spec per screen: content priority, primary and secondary actions, responsive collapse, states.
- `usability-test.md` — task script, success criteria, observation sheet (from `assets/usability-script.template.md`), when the plan calls for a test.

**Generate mode** → `design/`: `flows.md` and `wireframes.md` above, plus `DESIGN.md` (direction, rationale per decision, type scale, colour roles, spacing scale, motion rules — from `assets/DESIGN.md.template`), `design-tokens.json` (from `assets/design-tokens.template.json`), and `design-preview.html` (self-contained, no build step, no network requests, showing the token set on the product's real components — from `assets/design-preview.template.html`).

**Audit mode** → the visual table, the UX table, and the combined verdict. The two table shells are in `references/design-audit.md` (*Mode 2 — Audit report shape*), followed by `V`, `U`, `total`, the pass/fail verdict naming which gate failed if any, and a fix list ordered by impact ÷ effort.

**AI-slop mode** → the symptom table (same reference): symptom, location, priority, alternative.

**Every mode ends with the verification evidence**: the contrast result per declared pair (role and measured ratio), the accessibility scan (command and output), the keyboard walk-through result, and a screenshot of the real rendered surface.

## References

| File | Load when |
|---|---|
| [references/ux-flows.md](references/ux-flows.md) | Running UX mode — the jobs-to-be-done questions, the journey template, the five-state matrix, and the edge roles (new, returning, no-permission, offline). |
| [references/ia-wireframes.md](references/ia-wireframes.md) | Choosing a navigation pattern, writing the page inventory, or writing a wireframe spec, form or error design. |
| [references/usability-testing.md](references/usability-testing.md) | Planning or running a usability test — the 5-participant protocol, task scripts, the observation sheet, severity grading. |
| [references/design-tokens.md](references/design-tokens.md) | Defining, extending or auditing the token set — JSON shape, naming scheme, CSS mapping, dark mode, contrast roles. |
| [references/design-audit.md](references/design-audit.md) | Scoring an interface, writing an audit or AI-slop report, applying WCAG 2.2 AA targets and the verification commands. |
| [references/react-patterns.md](references/react-patterns.md) | Writing React components — accessible compound components, hooks, forms, dialogs, memoisation. |
| [references/motion-and-performance.md](references/motion-and-performance.md) | Specifying the motion sequence, responsive rules or target sizes, or measuring the performance budget. |
| [assets/ux-spec.template.md](assets/ux-spec.template.md) | UX or Generate mode — the flows and state-matrix skeleton. |
| [assets/usability-script.template.md](assets/usability-script.template.md) | Planning a usability test — the task script and observation sheet. |
| [assets/DESIGN.md.template](assets/DESIGN.md.template) · [assets/design-tokens.template.json](assets/design-tokens.template.json) · [assets/design-preview.template.html](assets/design-preview.template.html) | Generate mode — the design-system document, the starting token file, and the self-contained preview page. |

## Verification Checklist

**Accessibility and measurement**

- [ ] Every colour, size, spacing value, radius, shadow and duration in the UI resolves to a token; no raw value outside the token file.
- [ ] The CSS custom properties match `design-tokens.json` — regenerate and diff, no drift.
- [ ] Every declared pair meets its minimum: **4.5:1** body text, **3:1** large text (≥24px, or ≥18.66px bold), **3:1** UI boundaries and focus indicators; ratios recorded.
- [ ] The accessibility scan (`npx @axe-core/cli http://127.0.0.1:8000/ --exit`, or the Lighthouse fallback) reports zero critical or serious violations, with the command output attached.
- [ ] Keyboard walk-through: every control reachable and operable, `:focus-visible` visible and unobscured, every target ≥ 24×24 CSS px, primary mobile actions ≥ 44×44 or the gap recorded.
- [ ] `prefers-reduced-motion: reduce` removes the load sequence and every non-essential transition; content still appears.
- [ ] Dark mode is one override block in the token layer; no component branches on the theme; dark pairs re-checked.
- [ ] The layout holds at every declared breakpoint; no horizontal scroll at 320 CSS px; nothing meaningful hidden when narrow.
- [ ] The performance measurement is attached and within budget (CLS ≤ 0.1, LCP ≤ 2.5 s).

**UX**

- [ ] Every screen's five states are implemented or explicitly out of scope with a reason — no screen is silent about empty, loading, error, partial and no-permission.
- [ ] The main journey completes end to end in the build, with the primary action reachable at every step.
- [ ] Error copy states what happened and what to do next; no error message is a bare code or an apology.
- [ ] Form errors appear at the field, are announced programmatically, and are not colour-only.
- [ ] The keyboard path through the main journey is complete and in a sane order.
- [ ] Navigation reflects the page inventory: every page reachable, no orphan screen, no dead-end.
- [ ] No invented data ships as content; placeholder copy is labelled as placeholder.

**Evidence and contract**

- [ ] A screenshot of the **real rendered surface** exists and was reviewed against the direction — not a mockup, not a description.
- [ ] The existing token system was extended rather than replaced, or the migration is stated.
- [ ] Restyling changed no behaviour: component contracts and the existing test suite are unchanged and passing.
- [ ] The audit tables are complete when auditing: 10 visual rows, 6 UX rows, `V`, `U`, `total` from the published formula.
- [ ] Every claim in the deliverable points at a file, a measurement or a command output.
