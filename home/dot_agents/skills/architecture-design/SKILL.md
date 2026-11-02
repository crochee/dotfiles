---
name: architecture-design
description: "Produces a decision record and design review: NFR numbers, candidates that lost, failure modes, C4 and Mermaid views. Use when making a structural decision, writing an ADR, or reviewing scalability, consistency, or RPO/RTO. Not for HTTP contracts (api-design), code-level review (golang-dev, rust-dev, python-dev), page flows (frontend-design), or prose critique (technical-writing). 中文：写 ADR、架构设计与评审、NFR、失败模式。"
license: MIT
metadata:
  version: "1.1.0"
---

# Architecture Design

Produces a decision record and a reviewable design: the numbers the design is held to, the candidates that lost, the failure modes it tolerates, and one rendered diagram per question asked.

## When to Use

Three modes, one deliverable each:

- **Decide** — write an ADR for a structural choice: a boundary, a store, a protocol, a consistency model, a deployment shape.
- **Review** — assess an existing design against NFRs, failure modes and capacity, and return a verdict that separates blocking findings from advice.
- **Diagram** — draw the C4 view and Mermaid source the question needs, at the level the question asks for.

A structural decision is one that is expensive to reverse and crosses a component or team boundary. A choice confined to one module with a cheap local undo is code review, and does not earn an ADR. The skill is language-independent: it reads Go, Rust, TypeScript or anything else for the structure, and delegates syntax-level findings to the language skill.

Not for HTTP contract design (api-design), implementation-level review (rust-dev, golang-dev, python-dev), page and flow structure (frontend-design), a prose critique of a document (technical-writing), or an interview that stress-tests the decider's thinking before the decision exists — this skill delivers the record, not the interview.

## Workflow

Settle the scope before step 1: which decision or design is under review, who decides, and what evidence already exists in the repository. With no named decider, record the decision as proposed and name who must accept it — an ADR with no decider is a proposal that will be mistaken for policy.

1. **Fix the constraints and NFRs as numbers.** Write scale, latency percentiles, availability, RPO, RTO, cost ceiling and compliance scope into one table, each with a unit and a source. An NFR with no number is a preference; record the unknowns as open questions with an owner rather than inventing figures. Availability is written twice — as a percentage and as downtime per year — because the second form is what the architecture has to survive. → `references/design-review.md`
   *Exit criterion:* every constraint that can veto the design appears with a number, unit and source, and every unknown is an open question with an owner.
2. **Generate candidates and name the trade-off axis.** Two or more candidates a competent engineer would defend. For each, state the axis it wins on and the axis it loses on — consistency against latency, operability against cost, coupling against duplication. A single candidate is a memo; a candidate that wins on nothing is a straw man and weakens the record. → `references/adr.md`
   *Exit criterion:* each candidate has its winning axis and its losing axis written down, and at least one candidate is rejected on evidence rather than taste.
3. **Walk the failure modes, then do the arithmetic.** For each dependency, ask what happens when it is slow, down, or lying. Then compute load: QPS into bandwidth, rows into storage, instances into connections, burst into drain time. Every mitigation needs a detection signal beside it, because a mitigation nobody can observe is indistinguishable from no mitigation until the incident. → `references/design-review.md`
   *Exit criterion:* every failure mode has impact, detection signal and mitigation; every capacity figure is computed from stated inputs and printed in the document.
4. **Choose the C4 views and answer only the level asked.** Context for "who talks to whom", container for "what runs where", component only when a boundary inside one container is contested. Choose the level from the question, not from what is easy to draw; a diagram that answers two questions answers neither. → `references/c4.md`
   *Exit criterion:* each diagram states its level and scope, and no arrow or box exists without an owner in the system.
5. **Write the Mermaid source and render it.** Quote every label that contains punctuation, avoid reserved node ids, close every block, and run the renderer before delivering. Commit the source, not only the image, and record the command and renderer version in the document that embeds it. → `references/mermaid.md`
   *Exit criterion:* every diagram file renders with exit code 0 through the recorded command; no unrendered diagram is delivered.
6. **Write the ADR — one decision, with status, supersession and forecast consequences.** → `references/adr.md`
   *Exit criterion:* the ADR sits in the repository's ADR sequence, its status is one of the five, its supersedes and superseded-by pointers resolve or say none, and its consequences name what gets harder.
7. **Close with a verdict that separates blocking from advisory.** → `references/design-review.md`
   *Exit criterion:* each blocking finding has an owner and evidence, advisory findings are ordered by impact, and the verdict is one of proceed, proceed with conditions, or do not proceed.

Repeat steps 2–6 per decision, not per document. One ADR carrying three decisions cannot be superseded cleanly, because the three will age at different rates.

## Quick Decisions

**Repository signal → what to write.** Read the signal before choosing notation; the repository's existing shape wins over a preference.

| Signal in the repository | Deliverable | Notation |
|---|---|---|
| `docs/adr/` with numbered files | the next number in that directory | match the existing file template |
| no ADR directory, decision being made | create `docs/adr/0001-<slug>.md` | ADR from the asset template |
| `.mmd` files, a Mermaid renderer in CI, or mkdocs/Backstage | `.mmd` source beside the doc | the renderer already wired |
| diagrams only as fenced code in README or docs | a fenced `mermaid` block in place | Mermaid, no new toolchain |
| an SVG committed with no source file | regenerate from source, or redraw and commit both | do not edit the SVG |
| the question is who calls whom | C4 context plus one interaction table | `C4Context` |
| the question is what runs where | C4 container | `C4Container` |
| the question is call order or retries | sequence | `sequenceDiagram` |
| the question is record lifecycle | state | `stateDiagram-v2` |
| the question is entity relationships | entity relationship | `erDiagram` |
| several services with queues and retries | pattern selection | `references/patterns.md` |
| ASCII art already in the doc and CI has no renderer | keep it, or add the renderer first | do not half-migrate |

**Change class → how much of the workflow is owed.** The depth follows the reversibility cost, not the size of the diff.

| Change | Artefacts | Depth |
|---|---|---|
| New service or team boundary | ADR, context and container views, sequence for the critical call path | full workflow |
| New store, or a change of data ownership | ADR, capacity arithmetic, restore and failover drills scheduled | full workflow |
| Protocol or consistency change | ADR, sequence diagram, compatibility and rollback note | full workflow; capacity pass only on the affected path |
| Deployment shape change — region, stamp, tenancy | ADR, context view, RPO/RTO with a drill date | full workflow |
| Queue, cache or index inside an existing boundary | capacity and failure rows in the design doc; an ADR only if the undo is expensive | steps 1, 3, then a short record |
| Library swap inside one container | pull request | code review |
| Configuration or tuning change | the number and its source in the runbook | no review |

**What the decision touches → who decides, and what they need to see.** Authority follows the blast radius; an ADR records the decision, it does not grant it.

| The decision touches | Decider | Evidence they need |
|---|---|---|
| Internals of one service, reversible in a sprint | the owning team's lead, in the pull request | a sentence in the pull request; no ADR |
| A contract between two teams | both owners, recorded in an ADR | the caller's failure behaviour and the migration plan |
| Data ownership, retention or classification | the data owner with security | RPO/RTO, retention period, access model |
| Spend above the agreed budget threshold | the budget owner | monthly and 10× cost, plus the cost of leaving |
| A public SLO or API surface | the product owner | the user-visible consequence of missing it |
| An irreversible migration | the data owner and the on-call lead | restore drill date and measured rollback time |

**Symptom → the analysis that is missing.** A review that finds nothing usually skipped a step, not a flaw.

| Symptom | Missing analysis |
|---|---|
| "it will scale" with no figure | capacity arithmetic — QPS, payload, rows, connections |
| every review comment is stylistic | the NFR table has no numbers to argue against |
| one option, presented as obvious | candidates and the trade-off axis |
| arrows nobody owns, boxes nobody deploys | C4 scope and ownership discipline |
| "eventually consistent" with no bound | consistency model with a staleness or RPO figure |
| the plan cannot be rolled back | consequences and reversibility in the ADR |
| the same incident recurs | failure-mode table, specifically the detection column |
| review ends in agreement with no record | ADR plus written verdict |
| a diagram that renders locally fails in CI | Mermaid traps — quoting, reserved ids, renderer version |
| a pattern named before the problem | force first, then pattern; delete the name |
| three services calling each other in a loop | boundary placement, not more retries |

## Output

| Mode | Files | Must contain |
|---|---|---|
| Decide | `docs/adr/NNNN-<slug>.md`, seeded from `assets/adr.template.md` | context with constraint numbers, decision, alternatives with rejection reasons, consequences with a review trigger, status and supersession |
| Review | `docs/reviews/<date>-<topic>.md`, seeded from `assets/design-review.template.md` | NFR table, availability with downtime, RPO/RTO, failure modes, capacity arithmetic, findings split blocking/advisory, verdict |
| Diagram | `docs/diagrams/<level>-<scope>.mmd` plus the rendered `.svg` | level, scope, legend, numbered interactions, render command and renderer version |
| Any | the ADR or review it belongs to | the pattern names it relies on, each with the force it resolves |

Placement rules, so two documents never compete for the same truth:

- Deliver into the structure the repository already has. If `docs/adr/` exists, continue it; if a design doc lives next to the service, put the review beside it. Creating a second documentation tree to avoid reading the first is how architecture documents become unread.
- If there is no documentation directory at all, create the minimum — `docs/adr/` with an index, `docs/diagrams/` — and say so in the pull request. Every later decision inherits the convention you pick here.
- Filenames are stable keys: four-digit ADR numbers that only increase, reviews dated `YYYY-MM-DD-topic.md`, diagrams named `<level>-<scope>.mmd`. Links use the key, never the title.
- Embed the diagram by file reference or fenced block and keep the render command in the same document. A diagram whose build command lives in someone's shell history stops being updated the first time it fails.
- A review states what it did not review. The edge of the evidence is part of the evidence.
- When a review is posted as a pull request comment rather than a document, keep the same content in four lines: verdict, blocking findings with owners, a count and link for advisory findings, and a link to the full review. Never post a verdict without the numbers it rests on; "looks fine" teaches the next author to skip the review.
- A decision made under time pressure is still an ADR. Record it as proposed with the missing evidence listed — that is more honest than an accepted record with no numbers, and it tells the next reader what would change the answer.
- When the deliverable contradicts existing documentation, update the old document in the same change or note the contradiction in the ADR. Two documents disagreeing about the same boundary is worse than either being wrong.

## References

| File | Load when |
|---|---|
| [references/adr.md](references/adr.md) | Writing, superseding or reviewing an ADR — anatomy, status lifecycle, context that lets a future reader re-litigate, worked example. |
| [references/design-review.md](references/design-review.md) | Reviewing a design, assembling the NFR table, RPO/RTO, failure modes, capacity arithmetic or the verdict. |
| [references/c4.md](references/c4.md) | Choosing a diagram level, or checking that a diagram is honest about ownership and direction. |
| [references/mermaid.md](references/mermaid.md) | Writing or debugging Mermaid — flowchart, sequence, C4, state and ER syntax, traps, pre-flight check, render command. |
| [references/patterns.md](references/patterns.md) | Selecting a distributed-system pattern, or defending one that is already in the design. |
| [assets/adr.template.md](assets/adr.template.md) | Starting an ADR. |
| [assets/design-review.template.md](assets/design-review.template.md) | Starting a design review. |

## Verification Checklist

- [ ] The ADR file is `docs/adr/NNNN-slug.md`, continuing the directory's existing sequence with no gap and no reused number.
- [ ] Status is exactly one of proposed, accepted, rejected, deprecated, superseded; a superseded ADR names its successor, and the successor names it back.
- [ ] Each ADR carries one decision; the title names the choice rather than the area.
- [ ] The context states the forces and the constraint numbers a new reader needs to challenge the decision, and contains no decision language.
- [ ] Consequences state what becomes harder, what is now forbidden, and a review trigger with a threshold.
- [ ] Every NFR that constrains the design has a number, a unit and a source; availability, RPO and RTO are written, not implied.
- [ ] Availability is expressed both as a percentage and as downtime per year.
- [ ] Capacity arithmetic shows its inputs — QPS, payload size, row size, growth rate — and its outputs — bandwidth, storage, connections, drain time.
- [ ] Every failure mode in the table has impact, detection signal and mitigation; no row has a mitigation without a detection.
- [ ] Every Mermaid diagram renders with exit code 0 using the recorded command, and the renderer version is recorded.
- [ ] Every diagram declares its C4 level and scope; a context diagram carries no technology, and a container diagram carries no library, ORM or internal module.
- [ ] Every arrow has a named initiator and one direction; no bidirectional arrow without a stated request and response direction.
- [ ] Numbered interactions on a diagram match the table beside it, and every number in the table appears on the diagram.
- [ ] Every pattern in the design is named with the force it resolves and its own failure mode.
- [ ] The verdict separates blocking from advisory; every blocking finding has an owner and evidence.
- [ ] The review names what it did not review.
- [ ] No number appears in the deliverable that was not computed, sourced, or marked as an assumption.
