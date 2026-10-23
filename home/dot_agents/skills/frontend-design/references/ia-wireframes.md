**Load this reference when:** choosing a navigation pattern, writing the page inventory, writing a wireframe spec per screen, or designing forms and their error handling.

## Contents

- [Information architecture](#information-architecture)
- [Navigation patterns](#navigation-patterns)
- [The wireframe spec](#the-wireframe-spec)
- [Forms](#forms)
- [Errors and recovery](#errors-and-recovery)

## Information architecture

The IA is the tree of what exists and how it is reached. Write it before the wireframes; a
wireframe without an IA is a drawing of an opinion.

Write the inventory as a table — every page, its parent, its reason to exist, and its
primary action. A page with no reason is a page to delete; a page with two primary actions is
two pages.

| Page | Parent | Why it exists (the user's question it answers) | Primary action |
|---|---|---|---|
| `{{Invoice list}}` | `{{Billing}}` | "Which invoices are unpaid?" | `{{Pay}}` |
| `{{Invoice detail}}` | `{{Invoice list}}` | "What is this invoice for?" | `{{Pay}}` / `{{Dispute}}` |

Rules that catch the common IA failures:

- **Depth before breadth.** Three levels of five is easier to hold in mind than two levels of
  twenty. Flatten only when the labels are unambiguous to a first-time user.
- **Labels are the user's nouns**, not the system's tables. `Invoices`, not
  `BillingDocuments`; one term per concept across the whole product.
- **Every page is reachable in at most three clicks** from the entry point, or it needs a
  shortcut that is documented in the navigation itself.
- **No orphan screens**: a page with no inbound link is either dead or missing a link; both
  are bugs.
- **Cross-links follow the task**, not the data model: from an invoice to the customer who
  owes it, if paying it involves calling them.

## Navigation patterns

| Signal | Pattern | Why it fits | Cost |
|---|---|---|---|
| 3–5 destinations, flat content | Top bar with the destinations visible | Everything is one click, no discovery cost | Breaks down past five items — the sixth is where labels start truncating |
| 6–12 destinations, hierarchical | Sidebar with one level of groups | Scales without hiding the first level | Eats horizontal space; needs a collapse rule at narrow widths |
| Deep hierarchy, infrequent switching | Sidebar with collapsible groups | Keeps depth legible | Collapsed state hides the destination — remember expansion and mark the current path |
| One dominant task, few secondary | Single-column shell with a persistent primary action | Focus; the action is always in reach | Everything that is not the primary task becomes second class |
| Content is the product (feeds, docs, media) | Persistent left nav + content column | Reading width is preserved | Nav competes with content for attention at narrow widths |
| Mobile-first, ≤5 destinations | Bottom bar | Thumb reachable; always visible | Max five items; the rest goes under "More", which is where destinations go to die |

Decide the mobile collapse explicitly for whatever pattern is chosen: a sidebar becomes a
drawer or a bottom bar, a top bar becomes a menu — and name what stays visible when collapsed
(the primary action and the current location, at minimum).

**Current-location marking** is not optional: the navigation must show where the user is,
and the marker must be more than colour alone (WCAG 1.4.1).

## The wireframe spec

A wireframe is a specification, not a sketch. Each screen gets one block with these fields —
the point is that an implementer reads it and does not have to invent a decision.

```markdown
### {{Screen name}}

**Job:** {{the user's job this screen serves, one line}}
**Route:** {{/billing/invoices/:id}}
**Roles:** {{who sees it — and what changes for each}}

**Content priority** (top three, in order):
1. {{the amount due — the reason the user is here}}
2. {{the due date — the constraint}}
3. {{the invoice lines — the evidence}}

**Primary action:** {{Pay}} — {{placement: header right, sticky at narrow widths}}
**Secondary actions:** {{Download PDF, Dispute}} — {{placement: overflow menu below md}}

**Layout:** {{single column, max-width 64ch; summary card above the line items}}
**Responsive collapse:** {{≤md: summary card stacks above items; actions move to a sticky
footer bar; the items table becomes a definition list, never a horizontal scroll}}

**States:** {{link to the screen's row in the five-state matrix — do not restate it}}
```

A spec is finished when these are answered: what the eye hits first, what the one action is,
where it sits at 320 CSS px, what happens while the request is in flight, and what a user
with no permission sees. If any is missing, the screen is not specified yet.

**Content priority is a ranking, not a list.** Two items cannot both be first. When a
stakeholder insists everything is important, the ranking is what gets negotiated — that is
the value of writing it down.

## Forms

Forms are where interfaces lose the most users, so the rules are mechanical rather than
tasteful:

- **One column.** Multi-column forms create a reading order that assistive technology and
  the eye disagree about.
- **Labels above the input**, always visible. A placeholder is not a label: it vanishes on
  the first keystroke, taking the question with it.
- **Group by the user's mental model**, not the database schema. One question per field; no
  field asking two things (`Full name` is two fields).
- **Ask for the minimum.** Every optional field is a decision the user has to make; make the
  default answer the common one.
- **Validate on blur, not on keystroke**, except for constraints that are cheap and certain
  (a character counter, a format hint). Keystroke validation shouts at the user while they
  are still typing.
- **Validate on submit for cross-field rules**, and put the summary at the top with links to
  each field.
- **Constraint text before the input**, error text after it. The hint states the rule; the
  error states what went wrong and how to fix it.
- **Never clear the form on error.** Losing typed input is the failure users remember.

| Decision | Good default | Why |
|---|---|---|
| Required marking | Mark the optional fields when most are required; mark required when most are optional | Fewer marks, same information |
| Autofill | Set `autocomplete` on every identity, address and payment field | Native autofill beats typing, and the field names are what enables it |
| Input type | `inputmode` and `type` matching the data (`email`, `tel`, `numeric`) | The right keyboard removes a class of errors |
| Submit affordance | One primary submit; disable only while the request is in flight, with the reason visible | A disabled-until-valid button hides *why* it is disabled |
| Destructive action | Separate, confirmed, and not adjacent to the primary submit | Proximity to a primary action is how accidental deletion happens |

## Errors and recovery

An error message has a job: get the user back to the task. Three parts, in this order — what
happened, why, what to do now.

| Kind | Copy shape | Do not |
|---|---|---|
| Field validation | "{{Due date}} must be in the future — pick a date after today." | "Invalid input" |
| Recoverable request failure | "Could not load invoices. Your data is safe. Retry." | Stack trace, or a code with no meaning |
| Permanent failure | "This invoice was already paid, so it cannot be paid again. View the payment." | A retry button that can never succeed |
| Permission | "You need finance-admin access to pay invoices. Ask {{owner}} for access." | A bare 403 |
| Partial degradation | "Showing invoices from before {{time}}; newer ones could not be loaded." | Silently showing stale data as current |

Error text is never colour-only, never abbreviated to a code, and never blames the user. If
the interface cannot name the next action, the error is not designed yet.
