**Load this reference when:** running the adversarial pass on your own draft, critiquing
someone else's design doc or RFC, or judging how severe a finding is.

# Adversarial critique

The pass has one job: find the places where a reader could reach a different conclusion than
the author, or reach none at all. It is adversarial in method and constructive in output —
every finding names a location, a question and an acceptable fix, so the author can act
without guessing what was meant.

## How to read the draft

Read it three times, as three different people, in this order:

1. **The approver.** Has budget authority and no context. Question: *what am I being asked
  to approve, and what does it cost me if I am wrong?*
2. **The implementer.** Will build it next quarter and cannot ask follow-ups. Question:
  *what do I do on the case the doc does not mention?*
3. **The operator.** Inherits it at 03:00. Question: *what does this look like when it is
  broken?*

Each pass will surface a different set. An approver catches missing cost, an implementer
catches undefined behaviour, an operator catches missing failure modes.

## The nine targets

| Target | How it appears | The question to ask | Acceptable fix |
|---|---|---|---|
| **Unstated constraint** | A design that is correct only if a limit holds, and the limit is never named — "this fits in memory", "the tenant count is small" | What must be true for this to work, and who verified it? | Name the constraint, its current value and its headroom; or add the test that fails when it is exceeded |
| **Undefined term** | A coined word, an internal codename, or a common word used technically — "the pipeline", "the registry", "normalised" | What exactly does this word mean here, and is it the same meaning as in §3? | One definition at first use; one word for one concept throughout |
| **Claim with no evidence** | "This is faster", "widely used", "well understood", "production-ready" | What measurement, source or owner backs this sentence? | Attach the number and its conditions, or rewrite as a labelled assumption with an owner |
| **Decision smuggled into prose** | A choice stated as a fact of nature — "the service will use Postgres", "events are processed in order" | Was this decided, and were the alternatives considered? | Lift it into a numbered decision with its alternatives and cost, or mark it as an inherited constraint |
| **Missing failure mode** | Only the success path is described; dependencies are assumed available; retries are assumed to work | What happens when this dependency is slow, down, or returns garbage? | Add the failure table: trigger, symptom, blast radius, mitigation, detection |
| **Unmeasurable success criteria** | "Improved reliability", "better developer experience", "reduced toil" | By what number, measured how, by when, and who looks? | Metric, current value, target, date, owner |
| **Straw-man alternatives** | The alternative is described in a sentence and dismissed in the next — "we could also rewrite everything, which is too expensive" | Is this alternative described at the effort its advocates would recognise? | Describe each real alternative at implementable detail, including the cost of the one rejected |
| **Scope creep** | Two decisions sharing one document; a proposal that also fixes the build, the naming and the deployment | What single decision is this document asking for? | Split; the surplus becomes linked open questions or a second document |
| **Passive voice hiding the actor** | "It was decided", "the data is validated", "mistakes were made" | Who decided, who validates, who is accountable if it fails? | Name the actor and the moment; passive is correct only when the actor genuinely does not matter |

Two of these deserve their own treatment, because they are the ones authors most often
defend.

### Smuggled decisions

*"The system will store events in Kafka."* Nothing in the sentence invites disagreement, so
no reviewer disagrees, and a decision that shapes the whole document passes without review.
The tell is a definite noun phrase where a proposal should be: a decision reads as
description.

Fix by making the sentence claimable: "**Decision 2 — event transport:** Kafka, because the
replay window must exceed seven days and the existing operational tooling already covers it
(see Alternatives for the queue-based option)." A reader can now argue with it, which is the
point.

### Straw men

An alternative that is obviously worse than the proposal is not an alternative; it is
decoration, and reviewers read it as evidence that the author did not look. The test: could
a competent engineer hold that position after reading this description? If not, the
description is too thin to be the version its advocates would write.

Fix by giving each alternative the strongest case, then the reason it loses *here*. "Rewrite
the ingest path end to end: removes the shim, costs two quarters and blocks the audit work
until Q3; rejected because the audit deadline is Q1." That is reviewable even by the person
who preferred it.

## Worked critique

The draft below is short so the findings fit on one screen. It is realistic: every defect in
it is a defect that ships.

```markdown
# Data platform v2

## Background
The current data platform has scalability limitations and is hard to maintain.
We have decided to build a new streaming platform.

## Proposal
We will use Kafka for ingestion and Flink for processing. Storage will be in S3.
This gives us better reliability and improved developer experience.

## Design
Events arrive at the gateway, get validated, and are written to Kafka. Flink jobs
read from Kafka and write to S3. The system will handle 10x current volume.
It was decided to keep the existing schema registry for compatibility.

## Rollout
We will migrate tenants gradually and monitor closely. If problems arise we can
roll back.

## Alternatives
We could keep the current platform, but it has scalability limitations.
We could use a managed service, which is too expensive.
```

| # | Severity | Location | Problem | Question to ask | Fix |
|---|---|---|---|---|---|
| 1 | blocking | §Background, line 1 | Motivation states that limitations exist, not what they cost | Who pays for the current platform, in which units, and what breaks if nothing changes? | Replace with a cost, its trend and the trigger — incidents per month, engineer-hours, currency |
| 2 | blocking | §Background, line 2 | A decision is presented as background ("we have decided") | When was this decided, by whom, against which alternatives? | Move to a numbered decision with alternatives, or cite the prior decision record |
| 3 | blocking | §Design, line 4 | "Will handle 10x current volume" is a claim with no basis | What is the current volume, the 10x figure, and the measurement behind the capacity claim? | State events/s today, target, and the load test or sizing calculation |
| 4 | blocking | §Design, line 5 | A compatibility decision smuggled into the design, and passive | Who decided to keep the registry, and what does "compatibility" constrain? | Name the decider and the constraint it imposes on the new schema |
| 5 | blocking | §Proposal, line 3 | Success criteria are adjectives; nothing can be measured | What number proves reliability improved, and by when? | Metric, current value, target, date, owner |
| 6 | should-fix | §Rollout | Rollback is asserted, not designed | What state must be reversible, and what happens to events written during the migration? | State the rollback unit, the data that cannot be replayed, and the decision point |
| 7 | should-fix | §Alternatives | Both alternatives are straw men — "too expensive" is the entire analysis | What does the managed service cost per month at the target volume? | Give each option at implementable detail with its real cost |
| 8 | should-fix | whole document | No failure modes: no dependency failure, no partial write, no Flink job death | What does an operator see when Kafka is unavailable for an hour? | Add trigger/symptom/blast radius/mitigation per failure |
| 9 | should-fix | §Design, "validated" | Passive hides who validates and against what | Which component validates, against which schema, and what does it do on failure? | Name the component and the on-failure action |
| 10 | nit | §Design, "gateway", "Flink jobs" | Internal vocabulary used before it is defined | Is the gateway a component in this document or a product name? | Define at first use; one term per component |

Note what the table does not do: it does not rewrite the document. The author knows the
constraints (1, 3, 4) that the critic does not, and a rewritten section removes the author's
decision rather than informing it.

## Writing findings an author can use

- **Location first, then the defect.** `§Design, line 4` before "unsupported capacity
  claim". A finding the author cannot find is a finding that will be disputed instead of
  fixed.
- **Ask, do not accuse.** "What is the measurement behind this?" produces an answer; "this
  is unsupported" produces a defence.
- **One finding per row.** A row with three problems gets one of them fixed.
- **Name the fix class, not the sentence.** "Attach the measurement" lets the author supply
  the number only they have.
- **Order by consequence.** A blocking finding buried under twelve nits is a blocking
  finding that ships.
- **Say what holds.** One line, factual: "The failure handling in §Recovery is the strongest
  part; the rest of the document should be written to that standard." This calibrates the
  review and tells the author what not to change.

## Severity

Severity is a claim about consequence, not about effort.

| Severity | Definition | Test |
|---|---|---|
| `blocking` | Without the fix, a reader could approve the wrong design, or an implementer could build the wrong thing | Would a competent reviewer sign this off knowing the defect exists? |
| `should-fix` | The document is usable, but the gap will cost the reader a question, a meeting or a wrong first attempt | Would this generate a follow-up thread after acceptance? |
| `nit` | Wording, order, typography; no change to any decision | Would fixing it change what anyone builds? |

A critique made only of nits is a critique that failed to run the three passes. A critique
with fifteen blocking findings is usually a document with one missing motivation — find the
root and say so once.
