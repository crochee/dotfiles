# ADR-{{number}}: {{decision as a verb phrase}}

<!-- Title names the choice, not the area: "Publish order events through a transactional outbox",
     not "Order event strategy". One decision per file. -->

- Status: {{proposed | accepted | rejected | deprecated | superseded}}
- Date: {{YYYY-MM-DD}}
- Supersedes: {{ADR-NNNN | none}}
- Superseded by: {{ADR-NNNN | none}}
- Deciders: {{names or roles}}
- Evidence: {{ticket, benchmark, incident, load test — a pointer, not a summary}}

<!-- Update status in place; never rewrite an accepted decision. When superseding, the successor
     carries the back pointer and this file gains the forward pointer, permanently. -->

## Context

<!-- The forces and the numbers, written so a reader with no history can argue the other way.
     Include: what forced a decision now; measured or projected figures with units and sources;
     organisational reality (owners, on-call, team size); what was already fixed and could not
     change; the accepted risk. Do not include the decision or praise for an option. -->

{{Situation, with figures.}}

- {{Constraint with a number and a unit}}
- {{Constraint with a number and a unit}}
- {{What could not be changed, and why}}

## Decision

<!-- One active sentence, present tense, naming the chosen option. If it needs a qualifier to be
     true, the qualifier belongs in Consequences or in a second ADR. -->

We will {{decision}}.

## Alternatives

<!-- Each candidate a competent engineer would defend. State what each wins and loses, and why it
     lost. A straw man weakens the record; leave it out instead. -->

| Candidate | Wins on | Loses on | Why rejected |
|---|---|---|---|
| {{candidate}} | {{axis}} | {{axis}} | {{evidence, not taste}} |
| {{candidate}} | {{axis}} | {{axis}} | {{evidence, not taste}} |

## Consequences

<!-- Forecast, not praise. Four moves: what gets easier and for whom; what gets harder, with the
     first thing that will hurt; what is now forbidden; when to revisit, with an observable
     threshold. If nothing got harder, the decision was trivial or not yet understood. -->

- **Easier:** {{what improves, for which role}}
- **Harder:** {{the cost, and where it lands first}}
- **Forbidden:** {{options this decision closes}}
- **Accepted risk:** {{the risk, and how it is tracked}}
- **Revisit if:** {{observable threshold, e.g. p99 lag > 30 s for a week, volume > 5,000/min}}

## References

- {{ticket}}
- {{benchmark or load test with path}}
- {{incident or postmortem}}
