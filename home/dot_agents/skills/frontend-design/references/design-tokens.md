**Load this reference when:** defining, extending, or auditing the token set — i.e. whenever colours, type sizes, spacing, radii, shadows or durations need to be named, generated, or checked.

## Contents

- [The single source of truth](#the-single-source-of-truth)
- [File shape](#file-shape)
- [Naming scheme and CSS mapping](#naming-scheme-and-css-mapping)
- [Dark mode lives in the token layer](#dark-mode-lives-in-the-token-layer)
- [Contrast roles](#contrast-roles)
- [Breakpoints](#breakpoints)
- [Change protocol](#change-protocol)
- [Token file checklist](#token-file-checklist)

## The single source of truth

`design-tokens.json` **is** the token set. Everything else is derived:

```
design-tokens.json  ──generate──▶  :root { --token: value }        (CSS custom properties)
                                 └▶ [data-theme="dark"] { ... }      (dark overrides)
design-tokens.json  ──generate──▶  tokens.ts / tokens.tsx           (typed constants)
```

- Components consume **custom properties only**. A component that writes
  `#1f4fd8` instead of `var(--color-accent-default)` is a defect, not a
  preference.
- A token value is written in **exactly one place**: the JSON file. The CSS
  `:root` block is generated output — never hand-edited. If the project has no
  generator yet, the CSS block is a *checked copy*: a script (or a review
  checklist item) compares it against the JSON and fails on drift.
- Changing a value means editing the JSON and regenerating. Editing only the
  CSS creates a second source of truth and is how visual drift starts.
- Names are semantic (`--color-content-muted`, not `--color-gray-500`). A
  component asks for a role, so re-theming does not require touching
  components.

## File shape

The file is plain JSON with these top-level keys. `assets/design-tokens.template.json`
is a complete, valid instance of this shape.

```json
{
  "meta": { "name": "acme-web", "version": "1.0.0" },
  "color": {
    "surface": {
      "canvas": { "light": "#ffffff", "dark": "#0e0e11" }
    }
  },
  "typography": {
    "fontFamily": { "body": "\"Söhne\", Helvetica, Arial, sans-serif" },
    "fontSize": { "md": "1rem" },
    "lineHeight": { "normal": "1.5" },
    "fontWeight": { "regular": "400" },
    "letterSpacing": { "normal": "0" }
  },
  "spacing": { "0": "0", "4": "1rem" },
  "radius": { "md": "8px" },
  "shadow": { "md": "0 4px 16px rgba(17, 17, 19, 0.10)" },
  "motion": {
    "duration": { "base": "200ms" },
    "easing": { "standard": "cubic-bezier(0.2, 0, 0, 1)" },
    "group": {
      "hover": { "duration": "fast", "easing": "standard", "property": "opacity, transform" }
    }
  },
  "breakpoint": { "md": "768px" },
  "contrast": {
    "body-text": [["content.primary", "surface.canvas"]]
  }
}
```

Rules:

- `color.<group>.<name>` carries a `light` and a `dark` value. Every colour
  token has both, even if they are identical.
- `motion.group.<name>` bundles the three values a transition needs. `duration`
  and `easing` are **names of other tokens** (`"fast"`, `"standard"`) and
  `property` is the list of animated properties — so a transition is one token
  reference rather than three hand-picked literals, and no duration or easing
  value is written twice.
- `contrast` declares the **pairs the design actually uses**, grouped by the
  role that fixes the minimum ratio (the ratios themselves are specified in
  the audit rubric). The file itself is the list, so nothing has to be
  remembered.
- `meta.version` is bumped when a token value changes.

## Naming scheme and CSS mapping

The CSS custom property name is derived mechanically from the JSON path:
lowercase, `-` between path segments, `color` kept as the first segment.

| JSON path | CSS custom property |
|---|---|
| `color.surface.canvas` | `--color-surface-canvas` |
| `color.content.onAccent` | `--color-content-on-accent` |
| `color.accent.default` | `--color-accent-default` |
| `typography.fontFamily.body` | `--font-family-body` |
| `typography.fontSize.md` | `--font-size-md` |
| `typography.lineHeight.normal` | `--line-height-normal` |
| `typography.fontWeight.semibold` | `--font-weight-semibold` |
| `typography.letterSpacing.wide` | `--letter-spacing-wide` |
| `spacing.4` | `--space-4` |
| `radius.md` | `--radius-md` |
| `shadow.md` | `--shadow-md` |
| `motion.duration.base` | `--duration-base` |
| `motion.easing.standard` | `--easing-standard` |
| `motion.group.hover` | `--motion-hover-duration`, `--motion-hover-easing`, `--motion-hover-property` — the duration and easing resolve to `var(--duration-…)` and `var(--easing-…)` |
| `breakpoint.md` | `--breakpoint-md` (documentation only — see below) |

Camel-case JSON keys become kebab-case custom properties
(`onAccent` → `--color-content-on-accent`). Numeric spacing keys keep their
number: `spacing.4` → `--space-4`.

Generated CSS for the values above:

```css
:root {
  --color-surface-canvas: #ffffff;
  --color-content-on-accent: #ffffff;
  --color-accent-default: #1f4fd8;
  --font-family-body: "Söhne", Helvetica, Arial, sans-serif;
  --font-size-md: 1rem;
  --line-height-normal: 1.5;
  --font-weight-semibold: 600;
  --letter-spacing-wide: 0.02em;
  --space-4: 1rem;
  --radius-md: 8px;
  --shadow-md: 0 4px 16px rgba(17, 17, 19, 0.10);
  --duration-fast: 120ms;
  --duration-base: 200ms;
  --easing-standard: cubic-bezier(0.2, 0, 0, 1);
  --motion-hover-duration: var(--duration-fast);
  --motion-hover-easing: var(--easing-standard);
  --motion-hover-property: opacity, transform;
}
```

## Dark mode lives in the token layer

Dark mode is **one override block in the token file**, not a branch in every
component.

```css
/* tokens.css — generated */
:root { --color-surface-canvas: #ffffff; --color-content-primary: #111113; }

[data-theme="dark"] {
  --color-surface-canvas: #0e0e11;
  --color-content-primary: #f2f2f4;
}
```

- A component never reads the theme and never writes a dark-mode rule. It
  references `--color-*` and gets the right value.
- The switch is one attribute on `<html>`: `document.documentElement.dataset.theme = 'dark'`.
- `color-scheme` is set alongside it (`color-scheme: light` in `:root`,
  `color-scheme: dark` in `[data-theme="dark"]`) so form controls, scrollbars
  and the canvas colour follow the theme instead of staying light.

## Contrast roles

The `contrast` block lists pairs as `[foregroundPath, backgroundPath]`, where each
path is relative to the `color` group — `content.primary`, `surface.canvas`.
Roles and their minimum ratios:

| Role | Minimum ratio | Applies to |
|---|---|---|
| `body-text` | 4.5:1 | Text below 24px, or below 18.66px bold |
| `large-text` | 3:1 | Text ≥24px, or ≥18.66px bold |
| `non-text` | 3:1 | Control boundaries, focus indicators, meaningful graphics |
| `decorative` | none | Dividers and rules that carry no information |

A pair that appears in more than one role must satisfy the strictest one.
Decorative pairs are listed explicitly so that "we did not check it" is a
recorded decision rather than an omission.

## Breakpoints

`breakpoint.*` values are recorded in the token file and **mirrored by hand in
the stylesheet's media queries**, because CSS media queries cannot read a
custom property:

```css
/* breakpoints mirror the token file: sm 480, md 768, lg 1024, xl 1280 */
@media (min-width: 48rem) { ... }
@media (min-width: 64rem) { ... }
```

- Express breakpoints in `rem`, not `px`, so they respect the user's font size.
- The token file is the list of record; the stylesheet mirrors it. If they
  disagree, the stylesheet is wrong — fix the stylesheet.
- `--breakpoint-*` custom properties exist for JavaScript (matchMedia) and for
  documentation only. Never branch a stylesheet on them.

## Change protocol

1. Edit the value in `design-tokens.json`.
2. Regenerate the CSS custom properties (or update the checked copy).
3. Re-run the contrast check for every pair that uses the changed token.
4. Bump `meta.version`.

Never: edit a generated `:root` block directly; introduce a second literal for
a value that already has a token; delete a token that a component still uses
without migrating that component in the same change.

## Token file checklist

- [ ] Every colour used by the UI has a token with `light` and `dark` values.
- [ ] Every spacing, size, radius, shadow and duration used by the UI has a token.
- [ ] `contrast` lists every foreground/background pair the UI actually renders.
- [ ] No component file contains a raw hex value, `px` size or `ms` duration
      that has a token (grep for `#`, `px` and `ms` outside the token file).
- [ ] The generated CSS matches the JSON — regenerate and diff, no drift.
- [ ] `meta.version` was bumped for the change.
