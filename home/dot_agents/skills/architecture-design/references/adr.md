**Load this reference when:** writing, superseding or reviewing an Architecture Decision Record.

# Working with ADRs

An ADR is a short, dated, immutable note that records one structural decision, the forces that made it necessary, the alternatives that lost, and what the team now has to live with. Its reader is a future engineer who wants to know whether the decision still holds and what would have to change for it to be revisited.

## One decision per file

A decision is a choice between at least two defensible options at a level above a single module: a boundary, a data-ownership rule, a store engine, a protocol, a consistency model, a deployment shape, a build-versus-buy call.

| Belongs in an ADR | Belongs somewhere else |
|---|---|
| Adopt a queue between order intake and fulfilment | Which queue library, which API — a design doc or code review |
| Postgres owns order state; the search index is derived | The index mapping — a schema migration |
| Services communicate by events, not synchronous calls | The event schema — a contract document |
| Multi-tenant isolation by schema-per-tenant | The tenant resolution code — a pull request |
| Deploy per region with an active-passive pair | The deployment pipeline — infrastructure code |

If the record needs the word "and" twice in its title, it is two ADRs. They will be superseded at different times, and a combined record forces the team to keep a half-obsolete decision alive because the other half still holds.

## Anatomy

Seven parts, in this order. The template asset carries the same order.

| Section | What it does | Failure when it is weak |
|---|---|---|
| Title | Names the choice, not the area | "Database strategy" — nobody can tell what was decided |
| Status | Proposed, accepted, rejected, deprecated, superseded | A rejected option looks current six months later |
| Context | The forces, the numbers, and what the organisation could not change | A future reader cannot judge whether the rationale still applies |
| Decision | One active sentence: "We will …" | A paragraph of intent that can be read two ways |
| Alternatives | Each candidate with the reason it lost | The record becomes advocacy, and nobody learns from the loss |
| Consequences | What gets easier, what gets harder, what is now forbidden, when to revisit | The cost is discovered in production instead of in the record |
| References | Ticket, RFC, benchmark, incident | The evidence cannot be re-examined |

## Status lifecycle

| Status | Meaning | Who sets it | What must accompany it |
|---|---|---|---|
| Proposed | Written, not yet binding | Author | A named decider and a deadline |
| Accepted | Binding now | Decider | The date it took effect |
| Rejected | Considered and declined | Decider | The ADR stays; the reason is the value |
| Deprecated | Still true, no longer recommended | Owner | The replacement direction or the reason it decayed |
| Superseded | Replaced by a later ADR | Owner | A forward pointer: `Superseded by ADR-0017` |

Rules that keep the file set usable:

- An accepted ADR is **not edited** except to change its status and add the supersession pointer. Rewriting the decision destroys the record of what was believed at the time and makes every later reference a lie.
- A superseded ADR keeps its forward pointer permanently. The superseding ADR carries the matching back pointer in its header: `Supersedes ADR-0009`.
- A decision that turns out to be wrong is superseded, not deleted. Deletion is how the same mistake gets made twice.
- Deprecated and superseded are different states: deprecated means the decision still describes reality but should not be extended; superseded means it no longer describes reality.
- Proposed ADRs expire. Give each a date after which it is either accepted or rejected, otherwise the set fills with decisions that were never made.

## Writing context a future reader can re-litigate

The test: a competent engineer with no history should be able to read the context, reconstruct the argument, and say what evidence would overturn it. That requires facts, forces and numbers — not a narrative of the meetings.

Include:

- The constraint that forced a decision now: a deadline, a scale figure, a compliance rule, a team size, a contract.
- Measured or projected numbers with their source. "Peak 1,800 req/s at 09:00 UTC, from the load test on 2026-03-04" beats "high traffic".
- The organisational reality: who owns the system, how many people can operate it, what the on-call rotation covers.
- What was already fixed and could not be changed: an existing store, a vendor contract, a deployment target.
- The accepted risk, stated in one line.

Exclude: the decision itself, praise for the chosen option, and any sentence that only makes sense to someone who attended the discussion.

## Writing the decision

One sentence, active voice, present tense, with the chosen option named exactly as it will appear elsewhere in the repository.

> We will move order event publication into a transactional outbox in the orders database, with a relay process that publishes to the event broker.

If the sentence needs a qualifier to be true, the qualifier belongs in the consequences or in a second ADR — not in a subordinate clause that readers will skip.

## Consequences as forecast, not praise

The consequences section is a prediction of the system after the decision, not a list of benefits. Write it in four moves:

1. **What becomes easier**, and for whom — the team, the operator, the user.
2. **What becomes harder**, and the first thing that will hurt. "Every event schema change now needs a relay-compatible migration; the first one lands in the same sprint as the checkout rewrite."
3. **What is now forbidden** — the options this decision closes. "No service may write to the orders tables directly."
4. **When to revisit**, with a threshold that can be observed: "Revisit if relay lag exceeds 30 s at p99 for a week, or if order volume passes 5,000/min."

Consequences are not neutral observations. If nothing gets harder, the decision was either trivial or not yet understood.

## Numbering and file layout

```text
docs/
└── adr/
    ├── README.md                  index: number, title, status
    ├── 0001-use-postgres-for-orders.md
    ├── 0002-event-broker-between-orders-and-fulfilment.md
    ├── 0003-schema-per-tenant-isolation.md
    └── template.md
```

- Four digits, zero-padded, monotonically increasing. Never renumber to fill a gap; a gap is cheaper than a broken reference.
- Filename is the number plus a lowercase-hyphenated slug of the title. The slug is a mnemonic, not a contract — links use the number.
- If the repository already has an ADR directory, adopt its naming and template exactly. Two conventions in one directory is worse than either.
- The index is generated or maintained by hand; either way it lists every file, its status and its date, because the index is what people actually read.
- If the repository has no docs directory, create `docs/adr/` at the project root and add the index. Colocating ADRs with the code they constrain keeps them reviewable in the same pull request.

## Worked example

```markdown
# ADR-0002: Publish order events through a transactional outbox

- Status: Accepted, 2026-02-11
- Supersedes: none
- Superseded by: none
- Deciders: platform lead, orders lead
- Evidence: load test 2026-03-04; incident INC-4412

## Context

Checkout writes an order row and then publishes `order.created` to the broker.
On 2026-01-27 a broker timeout after a successful commit lost 41 events; the
fulfilment service never saw them and shipping labels were produced from a
manual reconciliation (INC-4412).

The constraint is bounded: order writes peak at 1,800 req/s, each write
produces exactly one event of about 600 bytes, and the broker accepts
publishing at 5,000 msg/s per partition. Orders live in one PostgreSQL
cluster with synchronous replicas. The team operating this is four engineers
with no dedicated messaging specialist, so any mechanism has to be visible in
the existing database and alertable from existing dashboards.

The current approach (publish after commit, retry on failure) can duplicate
events when the commit succeeds and the retry fires, and can lose them when
the process dies between the two steps. Exactly-once delivery is not offered
by the broker.

## Decision

We will write order events to an `outbox` table in the same transaction as
the order row, and publish them from a relay that tails the table and marks
rows published only after broker acknowledgement.

## Alternatives

| Candidate | Wins on | Loses on | Why rejected |
|---|---|---|---|
| Publish after commit with retry | No schema change, ships this week | Loses events on process death; duplicates on retry | Does not fix the incident class |
| Change data capture from the write-ahead log | No application change | Requires a CDC connector and a second pipeline to operate | Operational load on a four-engineer team with no messaging specialist |
| Broker transactions where available | Strongest guarantee | Only covers the broker, not the order write | Does not span the two systems |
| Transactional outbox | Atomic with the write; no new infrastructure to operate | Adds a table, a relay and a cleanup job | Chosen |

## Consequences

- **Easier:** an order and its event commit or roll back together; the broker
  can be down for hours and events accumulate safely.
- **Harder:** the relay is a new process to deploy, monitor and restart, and
  every event schema change needs a relay-compatible migration. The first
  such migration coincides with the checkout rewrite, so the relay must land
  a sprint earlier.
- **Forbidden:** no service may publish `order.*` events directly; the broker
  topic accepts writes only from the relay's credential.
- **Accepted risk:** at-least-once delivery, so every consumer must be
  idempotent on the event id. Audit of the four consumers is tracked in
  PLAT-812.
- **Revisit if:** relay lag exceeds 30 s at p99 for a week, outbox depth
  exceeds 500,000 rows, or order writes pass 5,000/min.

## References

- INC-4412 postmortem
- Load test 2026-03-04, `perf/results/orders-1800rps.txt`
- PLAT-812, consumer idempotency audit
```

## Reviewing an ADR

Read in this order, stop at the first failure:

1. Does the title name a choice, and is it one choice?
2. Does the status tell you whether the decision binds today, and does a supersession pointer resolve?
3. Would the context alone let you argue the other way? If not, the record cannot be re-litigated and will be treated as policy.
4. Does the decision sentence match what the code does now?
5. Does any alternative have a real winning axis, or were the alternatives straw men?
6. Do the consequences name something that got harder, and is the revisit trigger observable?
7. Is the evidence reachable — a ticket, a benchmark, an incident?

An ADR that fails 3 or 6 is a decision nobody can revisit; it will be inherited rather than maintained.
