**Load this reference when:** drafting an RFC, deciding what a draft must contain before it
is reviewable, or answering review comments on one.

# RFCs

An RFC is a written proposal that a group of people can accept or reject before the work is
done. It is not a design doc with an audience: its job is to make disagreement cheap and
early.

## Lifecycle

The status header is the contract. A reader must be able to tell, from the header alone,
whether the content is binding.

| Status | Means | Required to enter it |
|---|---|---|
| `draft` | Open for author's changes; reviewers read at their own risk | Nothing |
| `review` | Frozen except for clarifications; comments are being collected | Author declares the review window (start and end date) and the reviewer list |
| `accepted` | The decision is binding; implementation may start | Named approver, decision date, and every blocking comment answered |
| `rejected` | Not being built | The reason, so the next person does not re-propose it unchanged |
| `superseded` | Replaced by a later RFC | A link to the successor; the old text stays as written |
| `withdrawn` | The author dropped it | The reason |

Two rules keep the header honest. **`accepted` requires an approver, not a consensus** — a
document approved by nobody in particular is a document that will be re-litigated.
**`superseded` is append-only** — editing an accepted RFC once the decision has changed
rewrites history and makes the record useless for the next argument.

## Required sections

Present all eight. A section that does not apply is present and says why, which is different
from being absent.

| Section | The question it answers | It has failed when |
|---|---|---|
| Summary | What is being proposed, in four sentences | The reader cannot repeat the proposal after it |
| Motivation | Why this, why now, who pays for the status quo | It argues from elegance rather than from a cost someone bears |
| Guide-level explanation | How a user or calling team experiences the change | It contains internal implementation detail |
| Reference-level detail | What an implementer must build, precisely | It contains "simply", "just", "somehow" or "and so on" |
| Drawbacks | What gets worse, and for whom | It lists drawbacks nobody would object to |
| Alternatives | The real options, with their real costs | Every alternative is obviously worse (a straw man) |
| Unresolved questions | What is still open, with an owner and a date | An open question has no owner, so it resolves itself by default |
| Backwards compatibility | What breaks, the migration path, the deprecation window | It says "no breaking changes" without having checked callers |

Guide-level and reference-level are separate sections because they serve different readers,
and merging them produces a document that an operator cannot plan from and an implementer
cannot build from. The guide level is written in the vocabulary of the people who will use
the feature; the reference level names types, defaults, limits, error conditions and the
exact behaviour at each boundary.

## The sample of one

An RFC is reviewable when it contains **at least one fully worked instance** — one real
request with a real payload and a real response, one real migration of one real caller, one
trace of one failure — carried through every section at the same concrete level.

The reason is mechanical. Without a sample, every reviewer evaluates a different imagined
system: the security reviewer imagines the worst input, the operations reviewer imagines the
largest deployment, the author imagines the intended path. The review then converges on
nothing, and the objections that surface are objections to the imagined system, not to the
proposal. One worked instance fixes the referent. Reviewers may still disagree, but they
disagree about the same thing, and their objections become answerable.

What a sample must show, at minimum:

- one input that is realistic rather than minimal — a plausible id, a plausible payload, a
  plausible tenant;
- the output, including an error output for the case the design most needs to handle;
- the state before and after, so the reader can see what the change actually alters;
- the boundary — what happens at the limit, in the empty case, and when a participant is
  unavailable.

A sample that works only on the happy path is not a sample of the design; it is a sample of
the diagram.

## Writing the motivation

Motivation is where an RFC is most often lost, because authors write it as a description of
the current system. The current system is not the problem; the cost it imposes on someone
is.

State, in this order, in the reader's own vocabulary:

1. **The cost.** Who bears it, in their units — incidents per month, engineer-hours per
  release, currency per tenant, a customer-visible latency figure.
2. **The trend.** What makes it worse if nothing changes. A flat, tolerable cost does not
  justify a change; a cost that doubles each quarter does.
3. **The trigger.** Why the decision is being made now rather than in six months. "We are
  about to triple the tenant count" is a trigger; "it would be nice" is not.
4. **The stakes of being wrong.** What the proposal costs if it turns out to be the wrong
  direction, which is the number a reviewer needs to size the risk.

Concrete: *"Adding a tenant requires a schema migration and a four-hour maintenance window;
with the 40 tenants planned for Q1, that is 160 engineer-hours and 40 windows in one quarter
(capacity plan, 2026-09). We propose per-tenant schemas resolved at connection time."* That
paragraph is reviewable. *"Our current architecture has scalability limitations"* is not: it
names no cost, no trend and no trigger, so every reviewer must invent one.

## Answering review comments

Every comment gets one of three responses, and the response is recorded — a comment answered
only in a chat thread is a comment that will be raised again.

| Comment type | Response | What is written in the thread |
|---|---|---|
| Correct — the design misses a case | **Concede**: change the RFC and describe the change | "Taken; §Reference-level detail now describes the case. Changed in commit `<sha>`." |
| Correct in principle, out of scope | **Defer**: add it to unresolved questions with an owner and a date | "Real, but separable. Added to unresolved questions, owner `<name>`, by `<date>`." |
| Wrong, or based on a misreading | **Push back with evidence**: a measurement, a constraint, a link to the primary source | "This assumes X; the load test at `<link>` shows Y at peak. Rejecting on that basis." |

Three behaviours to avoid:

- **Silent dropping.** The reviewer checks the next revision, finds it unchanged, and stops
  commenting — the RFC now looks accepted and is not.
- **Conceding under social pressure.** Changing a design to end a thread, without the change
  being defensible, trades one bad decision for a quiet one. If the objection is wrong,
  pushing back with evidence is the politer act.
- **Rewriting the thread's meaning.** Editing a section while leaving the discussion as if
  it already accounted for the change makes the record lie. Note the change.

Keep a `Changes` section at the end of the RFC listing each revision, the date and what
changed. Reviewers re-read a diff, not a document; a `Changes` section is what lets them do
that.
