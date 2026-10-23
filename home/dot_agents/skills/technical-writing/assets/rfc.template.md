# RFC {{NNNN}} — {{TITLE}}

> Fill every `{{PLACEHOLDER}}`. A section that does not apply stays in place and says why.
> Delete this note before circulating. Status moves only forward: `draft` → `review` →
> `accepted`, `rejected` or `superseded`.

| Field | Value |
|---|---|
| Status | `draft` |
| Owner | {{NAME}} |
| Reviewers | {{NAMES_OR_TEAM}} |
| Created | {{YYYY-MM-DD}} |
| Review closes | {{YYYY-MM-DD}} |
| Approver | — (filled when accepted) |
| Supersedes | none |
| Superseded by | none |

## Summary

{{FOUR_SENTENCES}}. What is proposed, for whom, and what changes for them. No history, no
diagram, no alternatives. A reader who stops here has the shape of the proposal.

## Motivation

- **Cost today:** {{WHO_BEARS_IT}}, {{IN_THEIR_UNITS}}, per {{PERIOD}}.
- **Trend:** {{WHAT_IT_BECOMES_IF_NOTHING_CHANGES}}.
- **Trigger:** {{WHY_NOW}}.
- **Cost of being wrong:** {{WHAT_THIS_PROPOSAL_COSTS_IF_IT_IS_THE_WRONG_DIRECTION}}.

Every number carries its source in the same sentence: a dashboard, an incident, a capacity
plan, a customer contract. "Widely felt" is not a measurement.

## Guide-level explanation

How {{USER_OR_CALLING_TEAM}} experiences this: the workflow they have now, the workflow they
get instead, and the one example they will recognise. Written in their vocabulary, with no
internal type names, no repository paths and no implementation detail.

## Reference-level detail

What an implementer builds. Cover, in this order:

1. **Surface:** endpoints, commands, flags, configuration keys, with defaults and limits.
2. **Data:** shapes, ownership, retention, migration of existing rows or messages.
3. **Behaviour at boundaries:** empty input, maximum size, duplicate request, concurrent
  writer, clock skew.
4. **Errors:** each condition, its signal, and what the caller is expected to do about it.

No "simply", "just", "somehow" or "and so on" in this section. If the mechanism is not
settled, it belongs in Unresolved questions, not here in weaker words.

### Sample of one

Required before `review`. One realistic instance carried through the whole document.

- **Input:** {{A_REAL_PAYLOAD_WITH_PLAUSIBLE_VALUES}}
- **Output:** {{THE_EXPECTED_RESULT}}
- **Error case:** {{THE_CASE_THE_DESIGN_MOST_NEEDS_TO_HANDLE}} → {{WHAT_HAPPENS}}
- **State before:** {{...}}
- **State after:** {{WHAT_ACTUALLY_CHANGED}}

## Drawbacks

What gets worse, for whom, and how the reader would notice. A drawback nobody would object
to is a sentence that should be deleted; the section is credible only if one item is
genuinely uncomfortable.

- {{DRAWBACK_1}}
- {{DRAWBACK_2}}

## Alternatives

Each alternative described at the detail its strongest advocate would write, then the reason
it loses *here*.

### {{ALTERNATIVE_1}}

{{DESCRIPTION_AT_IMPLEMENTABLE_DETAIL}} — rejected because {{REASON_WITH_COST}}.

### {{ALTERNATIVE_2}}

{{DESCRIPTION_AT_IMPLEMENTABLE_DETAIL}} — rejected because {{REASON_WITH_COST}}.

### Do nothing

{{WHAT_HAPPENS_IF_WE_SHIP_NOTHING}} — rejected because {{REASON}}.

## Unresolved questions

An open question without an owner and a date resolves itself by default.

| Question | Owner | Decide by | Blocks |
|---|---|---|---|
| {{QUESTION}} | {{NAME}} | {{YYYY-MM-DD}} | {{NOTHING_OR_THE_SECTION}} |

## Backwards compatibility

| Change | Breaks | Migration | Deprecation window |
|---|---|---|---|
| {{CHANGE}} | {{WHO_AND_HOW}} | {{PATH_OR_TOOLING}} | {{START_TO_END}} |

"No breaking changes" is a claim, not a default: list the callers checked, or say which were
not checked.

## Changes

| Date | Revision | What changed | In response to |
|---|---|---|---|
| {{YYYY-MM-DD}} | draft 1 | Initial draft | — |
