# {{PRODUCT}} — UX spec

> Fill every `{{PLACEHOLDER}}`. A state cell marked *not applicable* needs its reason next to
> it. Do not ship a filled-in-looking spec with empty cells: a blank state is an unbuilt
> state, and the implementer will invent one.

**Surface under design:** {{the screen or flow this spec covers}}
**Date / version:** {{YYYY-MM-DD, v1}}
**Owner:** {{who approves a change to this spec}}

## Job

**Who:** {{the role, in the product's own words}}
**Trigger:** {{what starts the job — an email, a deadline, a failed payment}}
**Job:** {{what they want to be true when they are done}}
**Success signal:** {{the observable event that proves it — where is it recorded?}}
**Today they do:** {{the incumbent: spreadsheet, phone call, competitor}}
**Out of scope:** {{the adjacent job this design will not do}}

## Journey

```mermaid
flowchart LR
    T["{{Trigger}}"] --> S1["{{Step 1}}"]
    S1 --> S2["{{Step 2}}"]
    S2 --> S3["{{Step 3}}"]
    S3 --> D{"{{Decision}}"}
    D -->|{{yes}}| OK["{{Done state}}"]
    D -->|{{no}}| R["{{Recovery}}"]
    R --> S2
```

**Abandonment point:** {{the step where the user is most likely to leave, and why}}
**Steps:** {{numbered list, one action per step, each mapped to a screen or a state}}

## Screens

### {{Screen name}}

**Route:** {{/path/:param}} — **Roles:** {{who sees it, and what changes for each}}
**Content priority:** {{1. … 2. … 3. … — a ranking, not a list}}
**Primary action:** {{action}} — {{placement and behaviour at narrow widths}}
**Secondary actions:** {{actions, or "none"}}
**Layout:** {{column structure, max width, what sits next to what}}
**Responsive collapse:** {{what moves, what stacks, what stays visible at ≤md and at 320 px}}

## State matrix

| Screen | Empty | Loading | Error | Partial | No permission |
|---|---|---|---|---|---|
| {{Screen}} | {{what it says and offers when there is nothing}} | {{skeleton or indicator, and after how long}} | {{what failed, is data safe, next action}} | {{which parts are stale or degraded, and whether rows stay actionable}} | {{who can grant access and how to ask}} |
| {{Screen}} | | | | | |

## Roles

| Role | What the screen gives them |
|---|---|
| New user | {{first-run path; how the first action is taught in place}} |
| Returning user | {{what is preserved — position, filters, sort}} |
| Power user | {{the keyboard path; what does not interrupt it}} |
| No permission | {{what is hidden, what is shown with a reason and a route to access}} |
| Offline / flaky | {{queued vs saved; what is never claimed before confirmation}} |

## Forms

| Field | Label | Type / `inputmode` | Required | Hint (before) | Error (after) | Autocomplete |
|---|---|---|---|---|---|---|
| {{field}} | {{visible label}} | {{type}} | {{yes/no}} | {{the rule, stated}} | {{what went wrong + the fix}} | {{token}} |

**Submit behaviour:** {{disabled only while in flight, with the reason visible; never cleared on error}}
**Cross-field rules:** {{rules checked on submit, and where the summary appears}}

## Error copy

| Kind | Message | Next action |
|---|---|---|
| Field validation | {{message}} | {{the fix, at the field}} |
| Recoverable failure | {{message + "your data is safe"}} | {{Retry}} |
| Permanent failure | {{message}} | {{the only viable route}} |
| Permission | {{message}} | {{Ask {{owner}} for access}} |
| Partial degradation | {{message with the timestamp of the last successful load}} | {{none / refresh}} |

## Open questions

| Question | Owner | Needed by |
|---|---|---|
| {{unanswered question}} | {{who can answer it}} | {{date}} |

## Assumptions

{{Numbered list of every assumption made because a question was unanswered. Each one is a
claim the design would fail on if wrong, not a note about the weather.}}
