---
name: technical-writing
description: "Produces engineering prose a named reader can act on: design docs, RFCs, Diátaxis documentation sets, located critiques. Use when drafting or reviewing a doc, or restructuring a doc set. Judges structure, not word-level style. Not for word-level polishing (de-ai-tone), API contracts (api-design), repository inventories (repo-wiki), or cited research notes (deep-research). 中文：写设计文档、RFC、重组文档集、评审文稿结构。"
license: MIT
metadata:
  version: "1.1.0"
---

# Technical Writing

Produces engineering prose a named reader can act on: a design doc or RFC, a documentation
set split by reader intent, or a critique whose every finding names a location and a fix.

## When to Use

Three modes, one per artefact class:

- **Draft** — a design doc or an RFC for a decision that is still forming, or an RFC that is
  about to go to review.
- **Restructure** — an existing documentation set whose pages teach, instruct, list and
  explain all at once, so none of those jobs is done well.
- **Critique** — someone else's draft, before it reaches its reviewers.

The test that separates this skill from adjacent ones: it judges **structure and evidence**
— whether the reader can restate the decision and the next action. Word-level style
polishing of text that is already structured is `de-ai-tone`; the contract an API exposes is
`api-design`; an inventory of an existing repository is `repo-wiki`; a cited findings note gathered
from primary sources is `deep-research`. Copywriting, marketing pages and grant applications are
outside all three.

A design spec produced by an earlier design conversation is the document of record until its plan is approved: review it where it lives, and do not re-author it into `docs/design/` or `docs/rfc/`.

## Workflow

1. **Name the reader and the document type.** Write down the reader's role, what they
  already know, what they will do after reading, and how long they will give it. Then pick
  exactly one mode from the decision table below. A page that tries to teach, instruct and
  explain at once fails each reader; that is the mixing failure explained in
  `references/diataxis.md`.
  *Exit criterion:* one sentence on the page itself — "For a <reader> who <need>, this
    <type> lets them <action>" — and the type named in the header.
2. **Outline before prose.** Headings only, each phrased as the question the reader has at
  that point ("Why change now?", "What happens when the leader dies?"), not as a topic
  ("Background"). List which required sections you are omitting and why. →
  `references/rfc.md` for the RFC section list, `references/diataxis.md` for the per-mode
  shape.
  *Exit criterion:* the outline can be accepted or rejected by a reviewer without reading a
    sentence of prose, and no heading is a bare noun.
3. **Draft with the argument order fixed.** Decision docs run: problem in the reader's terms
  → proposal → evidence → drawbacks → alternatives → open questions. The proposal goes in
  the first screen; an RFC whose motivation arrives after three pages of history is read as
  an archaeology report. Expand every acronym once, define every coined term at first use,
  one idea per paragraph with the idea in the first sentence.
  *Exit criterion:* every section answers exactly one question, the decision or ask is
    visible without scrolling a second screen, and no paragraph opens with a transition
    whose only job is to announce the next paragraph.
4. **Run the adversarial pass on your own draft.** Take each item from the critique table
  and ask its question of your draft. Fix it, demote it to a declared open question, or
  record why it does not apply. → `references/critique.md`
  *Exit criterion:* every critique question has an answer in the document, and no claim is
    left without an owner or a number — "we think" is not evidence, "the p99 was 2.4 s on
    2026-10-14 (metrics dashboard)" is.
5. **Draw only where prose fails.** A diagram earns its place when the reader must hold
  three or more relations at once: topology, a message sequence across services, a state
  machine, a schema. Linear steps and two-item comparisons stay prose or a table. Render
  every diagram and inspect the output. → `references/diagrams.md`
  *Exit criterion:* each diagram renders without error, and one sentence of prose states
    what the reader should take from it.
6. **Test with a reader who was not in the room.** Ask them to restate the decision and the
  next action, not to "review" the doc — reviewers are polite, restaters are not. Ask two
  questions and write the answers down verbatim: *what are we doing and why*, and *what
  happens next*. A reader who has to think before the second is answering a question the
  document does not ask. Record each stumble, and either fix it or declare it a known gap.
  *Exit criterion:* the reader restates the decision correctly and names the next action and
    its owner; the record of the test is attached to the deliverable.

Two readers whose needs are incompatible produce two documents. The approver wants cost, risk
and the decision; the implementer wants behaviour at the boundaries. One document written for
both is read at the wrong depth by each, and the compromise is always the longest version —
split it, and let the decision document link to the detailed one.

## Quick Decisions

Three tables in `references/quick-decisions.md`: what the reader needs → document type (with the test each type fails), symptom in the draft → structural fix, and claim kind → what makes it citable. Pick the type in step 1 with the first table, and apply the third before step 4.

A decision record is an ADR, owned by `architecture-design`: one decision, candidates with real costs, consequences, `supersedes`. This skill reviews its prose; a design doc's own status uses draft, review, accepted, rejected, withdrawn.

## Output

Every mode emits Markdown and starts with a header block: `Status`, `Owner`, `Reviewers`,
`Date`, `Supersedes` (or `none`). The path is stated in the document's first line if the
repository has no convention.

| Mode | Files | Required content |
|---|---|---|
| Draft — design doc | `docs/design/<slug>.md`, from `assets/design-doc.template.md` | Context, goals and non-goals, proposal, data model, API surface, failure modes, rollout, open questions. |
| Draft — RFC | `docs/rfc/NNNN-<slug>.md`, from `assets/rfc.template.md` | Summary, motivation, guide-level explanation, reference-level detail, drawbacks, alternatives, unresolved questions, backwards compatibility. |
| Restructure | `docs/tutorials/`, `docs/how-to/`, `docs/reference/`, `docs/explanation/`, plus `docs/README.md` | Index with one row per page: page, mode, reader, what it answers. A `current → new` split table with a reason per row. |
| Critique | `<original-stem>.critique.md` beside the draft | Findings table: `Severity \| Location \| Problem \| Question to ask \| Fix`. Blocking findings first, ordered by consequence. |

The critique table's `Location` is `path:line` or a quoted heading; a finding without a
location is a preference. Severity is `blocking`, `should-fix` or `nit`, and the difference
between the first two is whether a wrong decision could be made without the fix.

A design review of the architecture itself — NFRs, failure modes, capacity, verdict — belongs to
`architecture-design`'s Review mode; its `advisory` findings map to `should-fix` here.

## References

| File | Load when |
|---|---|
| [references/diataxis.md](references/diataxis.md) | Choosing between tutorial, how-to, reference and explanation, or splitting a page that mixes them. |
| [references/quick-decisions.md](references/quick-decisions.md) | Picking the type from the reader's need, diagnosing why a reader stops, or checking whether a claim is citable. |
| [references/rfc.md](references/rfc.md) | Drafting or shepherding an RFC — lifecycle, required sections, the reviewable-sample rule, answering reviewers. |
| [references/critique.md](references/critique.md) | Running the adversarial pass, writing findings an author can act on, or calibrating severity. |
| [references/diagrams.md](references/diagrams.md) | Deciding whether a diagram pays for itself, writing Mermaid that renders, or debugging one that does not. |
| [assets/rfc.template.md](assets/rfc.template.md) | Draft mode, RFC — copy and fill; every required section is present as a prompt. |
| [assets/design-doc.template.md](assets/design-doc.template.md) | Draft mode, design doc — copy and fill; goals, failure modes and rollout are already separated. |

## Verification Checklist

- [ ] The document names one reader, one type and one action that reader can take
  afterwards.
- [ ] Every claim has an owner or a number; nothing rests on "should", "generally" or "we
  believe" alone.
- [ ] Every acronym is expanded once, at first use; every coined term has exactly one
  definition in the document.
- [ ] The proposal or ask appears in the first screen of the document, before any history.
- [ ] Every required section for the chosen type is present, or its omission is stated with
  a reason.
- [ ] Every diagram renders without error, and one sentence of prose states what it shows.
- [ ] A reader who was not in the room can restate the decision, the next action and its
  owner.
- [ ] Every critique finding carries `path:line`, a question and a fix, and blocking
  findings come first.
- [ ] No section ends with a summary paragraph that repeats what was already said.
- [ ] No statement of fact hides an actor — a passive "it was decided" names who decided and
  when.
