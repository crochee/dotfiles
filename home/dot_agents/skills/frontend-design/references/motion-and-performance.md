**Load this reference when:** specifying motion, responsive behaviour or a performance budget, or auditing any of the three.

# Motion, responsive behaviour and performance

**Motion is one directed load sequence plus purposeful transitions.** The sequence runs once on first paint and stages the hierarchy; every other transition explains a change the user just caused. Random hover effects are not motion design.

- Durations come from the token file (`fast` 120ms, `base` 200ms, `slow` 320ms); easings are `standard`, `entrance`, `exit`.
- Animate `transform` and `opacity` only — never `width`, `height`, `top` or `left`, which force layout every frame.
- `prefers-reduced-motion: reduce` disables the load sequence and every non-essential transition. The content still appears; only the movement is removed.

**Responsive behaviour** is defined at the declared breakpoints and nowhere else. Content reflows rather than disappearing; nothing that carries meaning is hidden at a narrow width.

**Target size:** 24×24 CSS px is the WCAG 2.2 AA floor and is never traded away (SC 2.5.8). 44×44 CSS px is the target for a primary mobile action — it is the size a thumb actually hits. Where the two conflict, 24×24 is the compliance line and the 44×44 gap is recorded as a finding, not silently accepted.

| Metric | Budget |
|---|---|
| CLS | ≤ 0.1 |
| LCP | ≤ 2.5 s |
| Images | sized (`width`/`height` or `aspect-ratio`), lazy below the fold |
| Fonts | at most two families, `font-display: swap`, preloaded |
| Layout | no layout thrash — batch reads before writes, animate off the layout path |

Measure before claiming. A budget with no attached measurement is a wish, and the audit records it as *not run*.
