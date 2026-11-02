**Load this reference when:** scoring an existing interface, producing an audit or AI-slop report, or checking a design against the accessibility, contrast and verification requirements.

## Contents

- [Scoring model](#scoring-model)
- [The 10 visual dimensions](#the-10-visual-dimensions)
- [The 6 UX dimensions](#the-6-ux-dimensions)
- [Combined score and verdict](#combined-score-and-verdict)
- [Accessibility: WCAG 2.2 AA targets](#accessibility-wcag-22-aa-targets)
- [AI-slop indicators](#ai-slop-indicators)
- [Structural AI-slop](#structural-ai-slop)
- [Mode 0 — UX spec](#mode-0--ux-spec)
- [Mode 1 — Generate](#mode-1--generate)
- [Mode 2 — Audit](#mode-2--audit)
- [Mode 2 — Audit report shape](#mode-2--audit-report-shape)
- [Mode 3 — AI-slop](#mode-3--ai-slop)
- [Verification evidence](#verification-evidence)

## Scoring model

Two rubrics are scored independently and combined: a **visual** rubric of 10
weighted dimensions producing `V`, and a **UX** rubric of 6 equal dimensions
producing `U`. Both land on 0–10 so they can be averaged.

### Visual — `V`

Each of the 10 visual dimensions is scored **0–10** against observable
criteria, and each dimension carries a **weight**. The weights sum to 100.

| # | Dimension | Weight |
|---|---|---|
| 1 | Accessibility & contrast | 20 |
| 2 | Typography hierarchy | 10 |
| 3 | Colour roles & consistency | 10 |
| 4 | Spacing rhythm | 10 |
| 5 | Component consistency | 10 |
| 6 | Responsive behaviour | 10 |
| 7 | Information density | 10 |
| 8 | Polish & states | 10 |
| 9 | Motion | 5 |
| 10 | Dark mode | 5 |

**Visual total** (0–100), then normalized to `V` (0–10):

```
weighted_total = Σ( score_i × weight_i ) / 10
V              = weighted_total / 10
```

A dimension scoring 10 with weight 20 contributes 20 points; a dimension
scoring 10 with weight 5 contributes 5. All scores 10 → 100 → `V = 10`; all
scores 0 → `V = 0`.

### UX — `U`

Six dimensions, equal weight, each scored **0–10** against observable
criteria (see [the 6 UX dimensions](#the-6-ux-dimensions)):

```
U = Σ( ux_score_i ) / 6
```

### Combined total

```
total = 0.6 × V + 0.4 × U
```

Visual quality carries the larger share because the visual rubric already
contains behaviour (responsive, states, motion, dark mode); UX carries enough
weight that a beautiful screen with an unreachable empty state cannot pass.

### Pass threshold and verdict

The audit passes when **all** of these hold:

- `total ≥ 7.0`;
- `V ≥ 7.0` and `U ≥ 7.0` — a strong rubric does not carry a weak one;
- **no dimension, visual or UX, scores below 5** (one broken dimension fails
  the audit even if the total is high);
- the accessibility scan reports **zero critical or serious violations**.

This supersedes the v2 rule (`weighted_total ≥ 80` alone): the total now
averages in UX, so the visual threshold `V ≥ 7.0` is the floor the old 80
implied once the visual rubric had to hold up on its own.

**When the surface cannot be observed**, the visual dimensions are `not
scored`. Then `V` is not computed, `total = U`, and the verdict is `pass on UX
only` or `fail on UX` — the visual gate is reported as **not run**, never as
passed. The UX rubric is scoreable from source, because flows, states,
navigation and error copy are all in the code.

Accessibility conformance is a **gate, not a score**: a design that fails AA
fails the audit regardless of its weighted total. The score describes design
quality; the gate describes conformance, and both must hold.

**Tie-break.** When two dimensions disagree about the same element — for
example *Colour roles & consistency* wants a wider palette range while
*Component consistency* wants every instance identical — the dimension with
the **higher weight** decides, and the losing dimension's finding is recorded
in the fix list as `deferred: <dimension>`. If the weights are equal, the
dimension with the **lower band score** wins, because the weaker dimension is
the one that needs the fix.

**Fix ordering.** Rank the fix list by `impact ÷ effort`, where impact is the
weighted points the fix would recover (weight × points of the band gap) and
effort is 1 (small) to 3 (large). Ties break on the higher weight first.

## The 10 visual dimensions

Bands: **0–3 broken**, **4–6 workable**, **7–10 good**. A band requires
*observable* evidence — a file, a line, a measured ratio. "Looks clean" is
not a band.

### 1. Accessibility & contrast (weight 20)

- **0–3** — colour pairs unchecked; interactive elements unreachable by
  keyboard; no visible focus indicator; body text below its contrast minimum.
- **4–6** — pairs checked, but the focus indicator is missing on some
  controls, or some targets are under 24×24 CSS px, or motion is not reduced
  for users who ask for it.
- **7–10** — every rendered pair meets the minimum for its role; every
  interactive element is keyboard-operable with a visible, unobscured
  `:focus-visible` state; targets ≥ 24×24 CSS px; `prefers-reduced-motion`
  honoured; the automated scan is clean.

### 2. Typography hierarchy (weight 10)

- **0–3** — sizes are ad hoc; no hierarchy; more than three unrelated families.
- **4–6** — two or three sizes; a hierarchy exists but is applied inconsistently.
- **7–10** — every size, weight and line-height is a token; at least five
  scale steps; a distinct display and body role; line measure between 45 and
  75 characters; labels and captions distinguished by weight or size, not by
  colour alone.

### 3. Colour roles & consistency (weight 10)

- **0–3** — raw hex values in components; colours chosen per instance; no
  semantic naming.
- **4–6** — mostly tokenised, but the accent colour is used for several
  different purposes (link, primary action, decoration, badge).
- **7–10** — no raw colour value outside the token file; every colour has a
  documented role; the accent is used for one action type per screen; status
  colours are reserved for status.

### 4. Spacing rhythm (weight 10)

- **0–3** — arbitrary spacing; no shared scale.
- **4–6** — a scale exists but is applied inconsistently; repeated patterns
  use different gaps.
- **7–10** — every gap is a step of the scale; repeated patterns are
  identical; where a value deviates from the scale for optical reasons, the
  deviation is named in the design doc.

### 5. Component consistency (weight 10)

- **0–3** — the same concept looks different in different screens.
- **4–6** — shared components exist, but one-off duplicates remain.
- **7–10** — one primitive per role; variants are explicit and named; no
  one-off copies of an existing component; spacing and states come from the
  same source.

### 6. Responsive behaviour (weight 10)

- **0–3** — layout breaks or overflows at common widths.
- **4–6** — works at desktop and mobile, but one or two flows break in
  between, or content is hidden rather than reflowed.
- **7–10** — verified at 320, 768, 1024 and 1440 CSS px; no horizontal
  scroll; content is preserved rather than dropped; touch targets stay ≥
  24×24 CSS px; the breakpoints are the ones declared in the token file.

### 7. Information density (weight 10)

- **0–3** — the screen is either a wall of undifferentiated content or
  almost empty with no hierarchy.
- **4–6** — workable, but more than one element competes for primacy.
- **7–10** — one primary action and one primary message per screen;
  whitespace separates groups rather than filling space; the eye can find the
  next element without reading everything.

### 8. Polish & states (weight 10)

- **0–3** — only the default state exists; controls jump or break on press.
- **4–6** — hover and focus exist; loading, empty and error states are missing
  or inconsistent.
- **7–10** — hover, focus-visible, active, disabled, loading, empty and
  error states all exist and are consistent; transitions are interruptible;
  long text and long values do not break the layout.

### 9. Motion (weight 5)

- **0–3** — no motion at all, or motion on scroll for every section.
- **4–6** — a mix of purposeful and decorative motion; durations picked ad hoc.
- **7–10** — one directed load sequence on first paint; transitions only
  where they explain a change; named durations and easings from the token
  file; only `transform` and `opacity` are animated; `prefers-reduced-motion`
  disables the sequence and every non-essential transition.

### 10. Dark mode (weight 5)

- **0–3** — no dark mode, or a half-applied one (some surfaces stay light).
- **4–6** — implemented, but some surfaces, images or charts ignore the theme.
- **7–10** — implemented as one override block in the token layer with no
  per-component theme branches; the dark pairs were re-checked for contrast;
  media, charts and shadows are themed.

## The 6 UX dimensions

Equal weight, 1/6 each. Same bands as the visual rubric: **0–3 broken**,
**4–6 workable**, **7–10 good**, and every band needs a location. These are
scoreable from source: the flow, the states, the navigation and the error copy
are all in the code.

### `flow_coverage`

- **0–3** — the primary journey cannot be completed in the build: a step has
  no screen, or two screens disagree about what the previous one promised.
- **4–6** — the happy path completes, but a required branch (retry, back,
  edit-before-confirm, second item) dead-ends.
- **7–10** — every step of the documented journey has a screen, the primary
  action is reachable at each step, and recovery paths loop back to a step
  that exists.

*Evidence:* the journey (from `flows.md`) mapped to routes in the code.

### `state_completeness`

- **0–3** — only the populated state exists. Empty data renders as a blank
  region or an undefined error.
- **4–6** — empty and loading exist; error is a generic toast, or partial and
  no-permission are unhandled.
- **7–10** — all five states are implemented per screen with distinct copy
  and distinct actions; *no data yet* is distinguished from *no results for
  this filter*.

*Evidence:* the state matrix from `flows.md` matched to the branches in the
code (`if (isLoading)`, `if (error)`, `!items.length`, `403` handling).

### `ia_clarity`

- **0–3** — the page hierarchy is unpredictable: no current-location marker,
  orphan pages, or two names for one concept.
- **4–6** — navigation exists but the current location is colour-only, a page
  is reachable only by URL, or a label uses the system's noun instead of the
  user's.
- **7–10** — every page in the inventory is reachable, the current location
  is marked by more than colour, labels are the user's nouns and consistent,
  and no destination requires more than three clicks from the entry point.

*Evidence:* routes in the router, navigation components, and a link-crawl of
the page inventory.

### `form_usability`

- **0–3** — placeholder-as-label, keystroke validation, or the form clears on
  error.
- **4–6** — labels exist and validation works, but errors are summarised far
  from the field, or the required-marking scheme is inconsistent.
- **7–10** — visible labels, one column, constraints before the input and
  errors after it, validation on blur, cross-field rules on submit with a
  summary that links each field, correct `autocomplete` and `inputmode`, and
  typed input survives a failed submit.

*Evidence:* the form components and one submitted-error render.

### `content_hierarchy`

- **0–3** — no stated priority: everything on the screen is weighted the
  same, or five elements compete for first.
- **4–6** — a primary action exists, but the first-screen content does not
  answer the question the user came with.
- **7–10** — the screen states a ranked content priority, the top item is the
  reason the user is there, and there is one primary action; secondary
  actions are visually subordinate rather than merely smaller.

*Evidence:* the wireframe spec's priority list against the rendered first
screen; the heading and action order in the markup.

### `error_recovery`

- **0–3** — errors are codes, apologies, or disappeared toasts; the user
  cannot tell whether their data is safe.
- **4–6** — the error says what failed, but not what to do next, or offers a
  retry on a failure that cannot be retried.
- **7–10** — every error names what happened, whether the data is safe, and
  the next action; retryable and permanent failures are distinguished;
  permission errors name who can grant access.

*Evidence:* the error branches in the code and their rendered copy.

## Accessibility: WCAG 2.2 AA targets

**WCAG 2.2 AA is the conformance target.** WCAG 2.1 and 2.2 removed the AAA
requirement, and no mainstream rubric scores AAA contrast as its top band —
so the top band of the accessibility dimension is "meets AA, verified", not
"exceeds AA".

| Requirement | Target | Success criterion |
|---|---|---|
| Body text contrast | ≥ 4.5:1 | SC 1.4.3 Contrast (Minimum) |
| Large text contrast (≥24px, or ≥18.66px bold) | ≥ 3:1 | SC 1.4.3 |
| UI component boundaries and focus indicators | ≥ 3:1 | SC 1.4.11 Non-text Contrast |
| Target size | ≥ 24×24 CSS px (hard floor); primary mobile actions target 44×44 | SC 2.5.8 Target Size (Minimum) |
| Focus not obscured by other content | required | SC 2.4.11 Focus Not Obscured (Minimum) |
| Keyboard operability | every control reachable and operable | SC 2.1.1 Keyboard |
| Visible focus | a distinct `:focus-visible` state | SC 2.4.7 Focus Visible |
| Reduced motion | `prefers-reduced-motion` honoured | SC 2.3.3 Animation from Interactions is a Level AAA criterion; honouring `prefers-reduced-motion` is nevertheless the expected baseline for any design that ships motion, and this skill requires it |

Additional expectations for a design system: an accessible name for every
icon-only control, a `lang` attribute, and form controls with programmatic
labels.

Automated tools cannot see focus order, focus obscuration, target size or
motion preference — those are checked by hand (keyboard walk-through) and
recorded as evidence.

**Target-size adjudication.** WCAG 2.2 AA requires 24×24 CSS px and that floor
is not negotiable: a control below it is a conformance failure whatever else
the design achieves. 44×44 CSS px is the design target for a primary mobile
action, because that is the size a thumb hits reliably. When a design cannot
meet the target without breaking the layout, ship 24×24, record the shortfall
as a finding, and never describe a 24-pixel control as comfortably tappable.

## AI-slop indicators

The list is a set of **observable symptoms**, each with a priority and a
concrete alternative. It deliberately does not ban font or brand names: a
legible, accessible system font stack is a legitimate choice, and the defect
is the absence of intent, not the typeface.

| Priority | Symptom | Alternative |
|---|---|---|
| P1 | A gradient applied to every surface (hero, cards, buttons, backgrounds) | One gradient or none. Flat surfaces + one accent colour; reserve the gradient for one hero element |
| P1 | The same purple-to-blue gradient on buttons and backgrounds | One accent taken from the product's own domain; derive it from the brand or the data |
| P1 | Scroll-linked animation on several sections | One load sequence on first paint; at most one scroll effect, on the hero |
| P2 | Every element is a rounded card | Use dividers, whitespace and surface elevation; reserve cards for grouped, actionable content |
| P2 | Glass morphism (blur + translucent fill) as the default card | Opaque surface + 1px border; use blur only over a known, static backdrop |
| P2 | A default system font stack with no stated reason | Either pick a family with a written rationale (display vs body), or commit to the system stack and set the scale, measure and weights deliberately |
| P2 | A centred hero over a stock gradient with a generic headline | Show the product's real artefact in the hero; headline states a concrete outcome |
| P2 | Icon family and type family disagree (stroke weight, corner style, optical size) | One icon family, matched to the type's x-height and weight |
| P2 | Placeholder copy ("Feature One", lorem ipsum) shipped as content | Real copy, or content explicitly marked as a placeholder |
| P2 | Six equally-weighted navigation items | Four or five primary items; the rest secondary or under a menu |
| P3 | Uniform shadow on every element | An elevation scale with two or three steps, used by role |
| P3 | Uniform radius on everything, including elements that should be square | Radius per component role: inputs 6–8px, cards 12–16px, avatars pill, code and data cells square |

**P1** = fix before shipping. **P2** = fix before the next release. **P3** =
polish.

Good design is not "not slop" — it is intentional variety (elements that should
differ do differ), purposeful constraints (a limited palette, a consistent
scale), a point of view, and context: the design fits this product, not a
generic template.

## Structural AI-slop

The table above catches surface tells. This one catches the deeper class: an
interface that *looks* finished because nothing hard was decided. These are
found in the source, not the screenshot, and they are the ones that break on
the first real user.

| Priority | Symptom | How to see it | Alternative |
|---|---|---|---|
| P1 | No state handling at all — only the populated branch is written | Grep the data path: no `isLoading`, no `error`, no `!items.length` branch | Implement the five-state matrix per screen (empty, loading, error, partial, no permission) |
| P1 | No empty state: first-run renders a blank region | Create a record-less account or filter to no matches | An empty state that says what belongs here and how to create the first item |
| P1 | Invented data shipped as content — hardcoded rows, fake metrics, `lorem ipsum` | Grep for literal arrays of plausible records, `36.6%`, `John Doe` | Real data, or a labelled placeholder with a tracked gap |
| P2 | A card wall: every unit rendered as an identical rounded card in a uniform grid | Count the DOM nodes sharing one class; if it is all of them, it is a wall | Differentiate by role — a list for records, a card for grouped action, a table for comparison |
| P2 | The three-feature-column landing page ("Fast / Simple / Secure") with icons | Count the sections; three identical columns with one-word headings | State the concrete outcome with a number, show the artefact, or delete the section |
| P2 | Error paths that exist but say nothing — `Something went wrong` | Search the error copy | Name what failed, whether data is safe, and the next action |
| P2 | Pagination or filtering absent on an unbounded list | Check the fetch: does it limit? | Bound the query and paginate; an unbounded list is a performance bug with a UI |
| P3 | Every screen is the same screen — the same layout with different data | Compare the route implementations structurally | Vary layout by the job: a dashboard, a detail page and a form should not be the same grid |

**The test that separates structural slop from real design:** name the decision
that produced each visible element — the state, the empty case, the difference
between this screen and the last. If the answer is "the template", the element
is slop.

## Mode 0 — UX spec

1. Answer the jobs-to-be-done questions — user, job, success measure, constraints — and write
   the answers down; an unanswered question becomes a recorded assumption.
2. Draw the journey: one arrow per user action, numbered steps, and the
   abandonment point named.
3. Build the five-state matrix. Every screen gets a row; every cell is either
   a design or *not applicable* with its reason.
4. Write the page inventory and choose the navigation pattern from the five
   patterns (sidebar, top bar, breadcrumb-plus-content, hub-and-spoke,
   wizard), including the mobile collapse.
5. Write one wireframe spec per screen with all fields filled: job, route,
   roles, content priority (ranked), primary action, secondary actions,
   layout, responsive collapse, states.
6. Write the form table and the error-copy table for the screens that have
   inputs, using the field rules in the same reference.
7. Run the UX exit test — every screen has a five-state row, every state has a
   design or a reason — and the `## Verification Checklist` UX items in
   `SKILL.md`.

Deliverables: `flows.md`, `wireframes.md` (from `assets/ux-spec.template.md`)
and, when a test is planned, `usability-test.md` (from
`assets/usability-script.template.md`).

## Mode 1 — Generate

1. Confirm the UX spec exists. Tokens without flows produce a system for
   screens nobody has specified; if `flows.md` and `wireframes.md` are
   missing, run Mode 0 first. Then scan the stylesheets, Tailwind config,
   CSS-in-JS theme files and existing token files for patterns already in use.
2. Extract colours, typography, spacing, radii, shadows, breakpoints and
   durations.
3. *Optional* — look at comparable products using whatever reference material
   is available to you (screenshots, a description from the user, an existing
   moodboard). Skip this step when nothing is available; never block on it and
   never require a specific browsing tool.
4. Write the token set into `design-tokens.json`, following the schema in the
   token reference and the template in `assets/design-tokens.template.json`.
5. Write `DESIGN.md` from `assets/DESIGN.md.template`: direction, rationale
   per decision, type scale, colour roles, spacing scale, motion rules.
6. Write `design-preview.html` from `assets/design-preview.template.html`:
   self-contained, no build step, no network requests, showing the token set
   applied to the real components of the product.
7. Verify (below).

## Mode 2 — Audit

1. Identify the primary surfaces and the files that style them.
2. Capture the current state: a screenshot of the real rendered surface when
   the UI can be run; otherwise work from source and mark the visual
   dimensions `not scored` — never score what was not observed.
3. Score each of the 10 visual dimensions against the bands above, citing
   evidence (a file and line, or a measured ratio) and the fix as `path:line`.
4. Score each of the 6 UX dimensions against the bands above, from source
   where the surface cannot be rendered. The evidence is the branch, the
   route, the copy or the missing one.
5. Compute `V`, `U` and `total = 0.6 × V + 0.4 × U` with the formulas above;
   report each one, not just the total.
6. Apply the pass threshold; state the verdict and, if it failed, which gate
   failed (total, a rubric floor, a dimension below 5, or the accessibility
   scan).
7. Order the fixes by `impact ÷ effort`.
8. Verify (below).

## Mode 2 — Audit report shape

Two tables and a verdict; every row carries evidence and a located fix.

| Dimension | Score (0–10) | Weight | Evidence | Fix (`path:line`) |
|---|---|---|---|---|

| UX dimension | Score (0–10) | Evidence | Fix (`path:line`) |
|---|---|---|---|
| `flow_coverage` | | | |
| `state_completeness` | | | |
| `ia_clarity` | | | |
| `form_usability` | | | |
| `content_hierarchy` | | | |
| `error_recovery` | | | |

The AI-slop report uses one table:

| Symptom | Location (`path:line`) | Priority | Alternative |
|---|---|---|---|

## Mode 3 — AI-slop

1. Scan the rendered surface and the source for the indicators above.
2. Run the structural pass over the source: states, empty state, invented
   data, card walls, unbounded lists, error copy.
3. For each occurrence: `path:line`, the priority, and the specific
   alternative.
4. If two indicators overlap at one location, report the higher priority and
   mention the other in the same row.
5. Verify (below).

## Verification evidence

Every mode ends with the same three artefacts. Serve the surface locally
first (a static preview is enough):

```bash
# 1. serve the surface on loopback
python3 -m http.server 8000 --bind 127.0.0.1

# 2. contrast: every pair listed in the token file's "contrast" block,
#    checked against the role minimum, with the measured ratio recorded
#    (compute it, do not assume it)

# 3. automated accessibility scan (needs Chrome + chromedriver:
#    npx browser-driver-manager install chrome)
npx @axe-core/cli http://127.0.0.1:8000/ --exit

# 4. alternative scan when no chromedriver is available (bundles its own Chrome)
npx lighthouse http://127.0.0.1:8000/ --only-categories=accessibility \
  --output json --output-path=./lighthouse-accessibility.json

# 5. performance budget: CLS and LCP
npx lighthouse http://127.0.0.1:8000/ --only-categories=performance \
  --output json --output-path=./lighthouse-performance.json

# 6. screenshot of the real surface
npx playwright screenshot --viewport-size=1280,800 http://127.0.0.1:8000/ ./surface.png
```

Record for each: the command, the output, and the conclusion. A scan that was
not run is reported as **not run** — never as "no violations found".
