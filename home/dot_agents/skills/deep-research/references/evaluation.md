**Load this reference when:** auditing a completed run, reading the lint output, or changing the
activation thresholds. The suites themselves live in `evals/`; this file carries the rubric.

# Evaluation

Two different questions, two different artefacts.

| Question | Artefact |
|---|---|
| Did the skill fire when it should, and stay quiet when it should not? | `evals/trigger_queries.json`, measured by the repository's `bin/skill-trigger-eval` |
| Did the run produce a report that holds up? | `evals/evals.json`, the output-quality cases |
| Did the script keep its own rules? | `tests/run.py`, the gate's own fixtures |

The prompt set is not repeated here. It lives in the two JSON files, so there is one copy of every
prompt in the skill.

## Run-quality rubric

### Coverage

- [ ] The question, scope, exclusions, freshness requirement, risk level, and deliverable are explicit.
- [ ] The effort tier matches the risk of the question.
- [ ] The aspect map covered definitions, primary evidence, implementation or empirical evidence,
      limitations, and counterevidence.
- [ ] The source classes were diverse enough for the task.
- [ ] The run did not overfit to one phrasing, one domain, or one vendor.
- [ ] Local files, if present, carry exact locators and are not treated as truth.

### Accuracy

- [ ] Every high-impact claim has an evidence id.
- [ ] Every locator is specific enough for someone else to re-check.
- [ ] Current or version-sensitive claims carry a date, a version, or a freshness status.
- [ ] Primary sources carry the factual claims.
- [ ] A secondary source never quietly overrides a primary one.
- [ ] Conflicting evidence is represented on both sides.

### Source quality

- [ ] Every evidence row has `source_type`, `quality_score`, `stance`, and `claim`.
- [ ] Every high-impact row has `claim_id`, `source_family`, `independence_status`, and
      `freshness_status`.
- [ ] At least one primary source supports the central claim.
- [ ] The independence of the central claim's sources was assessed, not assumed.
- [ ] The bias that mattered is named.
- [ ] Popularity metrics are not treated as proof.

### Verification

- [ ] At least one adversarial route was searched for a nontrivial topic.
- [ ] The false-premise check was run.
- [ ] The limitations, failures, deprecations, and security issues that bore on the question were
      checked.
- [ ] The weak, single-source, stale, contested, and unknown claims carry labels.

### Synthesis

- [ ] The report opens with the answer, not with the process.
- [ ] The structure matches the deliverable the user asked for.
- [ ] The tables compare things rather than repeat them.
- [ ] The method appendix is short and useful.
- [ ] The next steps, if any, are concrete.
- [ ] The evidence ids sit on the high-impact claims, not only in a table at the end.

## Reading the lint output

`lint` prints a JSON object with two lists. **Errors** mean the run is structurally broken and the
report cannot be trusted. **Warnings** mean a research risk is present; they are the things to fix
or to disclose.

| Warning | What it means | What to do |
|---|---|---|
| only N independent support source families | the supporting evidence may be one organisation restated | find a second family, or label the claim `single-source` |
| only N source classes recorded | the search was narrow for the effort tier | broaden the routes, or explain in the method appendix why a class is irrelevant |
| no primary or near-primary evidence recorded | every row is a container, not an artefact | open the paper, the source file, the release note, the standard |
| no contradictory/unclear evidence recorded | the adversarial route found nothing, or was not run | run the adversarial search; if the topic is not debatable, say so |
| claim C00N has no contradictory or unclear evidence row | that claim was never tested against a counterexample | test it, or label the row `not-applicable` with a reason |
| is high-impact but missing quote_or_locator | the claim cannot be re-checked | open the source and find the locator |
| is high-impact but missing source_family | the independence of the claim is unknown | record the family |
| is high-impact but missing date_or_version | the claim may have gone stale | record the date or the version |
| is high-impact but has unresolved freshness_status | the freshness was never assessed | set the status, or label it `unknown` and say so |
| is a supporting row with quality>=3 but missing source_family | the row counts towards a claim but names no family | record the family |
| hop count N exceeds target T | the run went past its plan | explain in the method appendix why the extra hops mattered |
| final_report.md does not cite evidence ids like [E0001] | the tables carry the ids but the prose does not | cite the high-impact claims inline |
| may contain a secret/token | a row was hand-edited to include something that looks like a credential | replace the value with `[REDACTED]` |

A run is finished when `lint` exits 0, or when every remaining warning is stated in the report's
limitations.

## The two suites

### Trigger queries

`evals/trigger_queries.json` carries the skill name, the workflow marker and an array of
`{"query": ..., "should_trigger": true|false, "holdout": true|false}`:

```json
{"skill": "deep-research", "workflow_marker": "research_ledger", "queries": [...]}
```

`workflow_marker` is the string that proves the skill's workflow took the task over — the ledger
script's name. The negative cases are **near-misses** that share the skill's vocabulary — a negative
that shares no words with the trigger surface tests nothing.

**Every query must be self-contained.** A query that says "this paragraph" or "the PDF I uploaded"
without supplying the material makes the agent go looking for it; it searches the filesystem, finds
the skill's own files, reads them, and the run is scored as a trigger that the description never
caused. The material belongs in the prompt.

The repository's `bin/skill-trigger-eval` runs each query several times in a clean temporary
directory and measures two signals from the event stream:

| Signal | What it means | The gate |
|---|---|---|
| **consulted** | the skill's `SKILL.md` was read | a should-trigger query must exceed the threshold |
| **workflow** | the skill's ledger script ran, so the skill's workflow took the task | a should-not-trigger query must stay below the threshold |

Both are printed for every query, because an over-consulted skill is a description smell even when
the workflow never starts. The rates land in `evals/trigger_results.json`.

**Why two signals.** Loading the skill — a registry entry, a skill URI, or the installed directory
— is how an agent both loads it and *checks* whether it applies. The transcripts show the
difference: for "find me papers about RAG, just a list of titles", the model ran an ordinary arXiv
search, consulted the skill part-way through, and delivered the list the user asked for. The
consultation cost context; it did not change the deliverable. A gate that failed on the consultation
alone would call that a trigger, so the gate asks the question that matters: did the skill's
workflow take the task over?

**Run count.** The model's choice to consult a skill is noisy. One query measured 100% over three
runs and 33% over nine. The harness defaults to five runs; three is enough to misclassify a
borderline query.

**The suite has two parts.** The tuning set carries `"holdout": false` and is what a description
change is fitted against. The holdout set carries `"holdout": true`, was written after the last
description change, and is the honest generalisation check: the harness prints the two pass counts
separately, and a change that fits the tuning set while losing the holdout set has overfitted.

**What the measurement found.** The description upstream carried — a list of trigger nouns
("deep research, literature review, paper review, ... cited reports") — drew the skill for anything
that merely mentioned research or papers: a definition of what a literature review is, a request
for a list of paper titles, a chat about why research is hard. All ten positive queries fired at
100%, and seven of ten negatives also fired. Four description revisions later — deliverable-first
phrasing, then dropping the domain nouns, then dropping the source-class list, then naming the
single-source exclusion — the positives hold at 67–100% and the negatives no longer hand the task
to the skill's workflow.

Two residuals are measured and reported rather than tuned away:

- **Over-consultation.** Seven of the thirteen negatives are still *consulted* (mostly at 100%),
  because a skill named `deep-research` is checked by any query about papers, whatever the
  description says. In the transcripts the model does the work itself and delivers what the user
  asked for; the cost is context, not a wrong deliverable. The harness prints these under
  "over-consulted".
- **Two negatives occasionally hand over.** For "find me papers about RAG" and "list the ten
  most recent papers on RAG" the skill's workflow ran in one run out of three, which is under the 0.5
  threshold but not zero. A literature request that names the domain is the hardest case for this
  skill, and the honest summary is that the boundary holds for a report-shaped request and is
  soft for a paper-shaped one. The artefact is on disk: the run directory the workflow created
  under the run directory's parent, with an empty ledger and `quick` effort.

### Output-quality cases

`evals/evals.json` follows the community's eval format: a `skill_name` key and an `evals` array
whose entries carry an `id`, a `prompt`, an `expected_output`, optional `files`, and optional
`assertions`.

The assertions are the ones a reader can check mechanically:

- the artefact exists and is not empty;
- the required sections are present;
- every citation resolves to a row in `evidence_ledger.csv`;
- the report names the effort tier and the source classes it searched;
- the report contains at least one row whose stance is `contradicts` or `unclear`;
- no unresolved `{placeholder}` text survives.

A prose expectation that nobody checks is a wish. Every assertion above is a command someone can
run against a finished run.
