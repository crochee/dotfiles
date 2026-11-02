**Load this reference when:** choosing the document type for a reader's need, diagnosing why a reader stops, or deciding whether a claim is citable yet.

# Quick decisions

## Reader need → document type

Read the left column as the need the reader arrives with, not as the artefact you were asked for.

| Reader's need | Type | Shape it must have | The test that fails it |
|---|---|---|---|
| "Teach me this from nothing" | Tutorial | Linear, one path, every step verified from a clean environment, expected output shown | Fails if the reader must make a choice to proceed |
| "I have a goal, give me the steps" | How-to | Opens with the goal, assumes competence, one numbered path per task | Fails if it teaches concepts or lists every option |
| "Tell me exactly what this is" | Reference | Complete, scannable, uniform structure, no narrative | Fails if a fact is missing or a section is shaped differently from its neighbours |
| "Why is it like this?" | Explanation | Argument and context, links out instead of instructing | Fails if it contains a procedure |
| "Decide between these and record it" | Decision record → `architecture-design` | One decision, candidates with real costs, consequences, `supersedes` | Fails if it holds more than one decision |
| "Propose a change and let me review it" | RFC | Reviewable before acceptance, one worked sample, section list from `references/rfc.md` | Fails if a reviewer cannot tell what would be built |

A decision record is an ADR, owned by `architecture-design`: the template, the
`docs/adr/NNNN-<slug>.md` path and the five-value status vocabulary (proposed, accepted,
rejected, deprecated, superseded). This skill reviews its prose; a design doc's own status
uses draft, review, accepted, rejected, withdrawn.

## Symptom in the draft → structural fix

Symptoms are what a reader does, not what they say: a reader who stops, re-reads or asks is reporting
a structural fault, not a vocabulary preference.

| Symptom | Usual cause | Fix |
|---|---|---|
| Reader asks the same question twice | The answer is split across two sections | Merge into one section at the point of first need; the second occurrence becomes a link |
| Reader stops before the ask | Argument order wrong — history first, proposal last | Move problem and proposal to the top; history becomes an appendix |
| "What does that mean?" | Term used before it is defined, or defined twice differently | Define at first use, one definition, acronym expanded once |
| "Why are we doing this?" | Motivation written as a description of the current system | State the cost and who pays it, with a number or an incident |
| "Says who?" | Claim with no owner or measurement | Attach the evidence, or downgrade the sentence to a named assumption |
| "What if it fails?" | Failure modes absent or reduced to "should be fine" | Add the failure table: trigger, symptom, blast radius, mitigation |
| "How will we know it worked?" | Success stated as an adjective | Name a metric, a threshold and a date |
| "We already decided that" | A decision smuggled into the prose as a fact | Lift it to an explicit proposal with its alternatives |
| Reviewer argues against an option you invented | Straw-man alternatives | Describe the real alternative at the effort a reader would recognise, including the one you rejected |
| Draft grows every round | Scope creep | Cut to one decision; unfinished material becomes linked open questions |

## Claim → what makes it citable

Apply this before the adversarial pass, not during review.

| Claim kind | Citable form |
|---|---|
| Quantity | Number, unit and measurement date; the source named in the same sentence |
| Performance | Percentile and load conditions — "p99 340 ms at 200 rps", not "fast" |
| Cost | Currency, period and basis — monthly cloud spend, engineer-weeks |
| Behaviour | A file, a test name or a command output that demonstrates it |
| Intention | An owner and a date, marked as a commitment rather than a fact |
| External fact | A link to the primary source, not to a summary of it |
