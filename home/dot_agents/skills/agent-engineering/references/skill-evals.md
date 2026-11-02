**Load this reference when:** evaluating a skill itself — whether its description triggers in the right situations, whether it improves output, or whether a revision is actually better.

# Skill Evals

A skill is a prompt fragment selected by a description. It can fail in two independent ways: it never loads when it should, or it loads and does not help. Test the two separately; a single "it looked good" check hides both.

## Three measurements

| Measurement | Question | Method |
|---|---|---|
| Trigger recall | Would the skill be selected for a request that needs it? | Phrasing set, clean session, record which skill won |
| Output quality | Does following the skill beat not following it? | With-skill versus baseline runs, graded against assertions |
| Efficiency | What does the improvement cost? | Tokens and duration per run, recorded at completion |

## Trigger recall

The description is the only mechanism that selects a skill. Nothing in the body matters if the description never matches.

### Build the phrasing set

At least three phrasings per skill, deliberately spread:

1. **The stated intent** — "design the login flow and its empty states".
2. **The symptom, in the user's words** — "this interface reads like it was generated".
3. **A negatively phrased request** — "it depends on nothing, stop hardcoding the colours". Negative phrasing is where weak descriptions fail: the words `nothing`, `stop`, `avoid` do not appear in most descriptions, so the match has to come from the intent.
4. **An adjacent-skill trap** — a request that shares vocabulary with the skill but belongs to a neighbour. For this skill, "design the HTTP contract for login" shares *design* and *login* and must select the API skill, not this one.

Write phrasings the way the user types them: lowercase, abbreviations, a little backstory, no skill name. A phrasing that names the skill tests nothing.

### Run them

1. Start from a clean session where only the skill index (name + description) is visible.
2. Ask: "Which skill, if any, would you use for this? Name it and say why." Do not paste the skill body.
3. Record: the phrasing, the skill named, hit or miss, and — for the trap — which skill won.
4. Anything that misses is a description bug, not a model failure. The description failed to cover the words or the intent.

A skill that wins its own phrasings but also wins the trap has a description that is too broad; narrow it by adding the boundary clause (`Not for ...`). A skill that loses all informal phrasings has a description written in the wrong register.

### What the index looks like to the selector

The selector sees one line per skill: name and description, with no body. That is why the description must state the situation — a `Use when ...` clause saying when to reach for it, never the workflow it follows — and why the `Not for` clause earns its space: it is the only defence against a neighbouring skill. Naming the deliverable is optional and, when present, comes first: this repository's convention, not a requirement.

## With-skill versus without-skill

The comparison proves the skill earns its tokens.

1. **Snapshot the baseline.** For a new skill, the baseline is no skill. For a revision, snapshot the current version to a separate directory first; the baseline is the previous version, not nothing.
2. **Spawn both runs in the same batch.** Same prompt, same inputs, separate output directories. Running the with-skill case first and the baseline later lets the environment drift.
3. **Keep the prompts identical.** The only variable is the skill.
4. **Grade both against the same assertions.** An assertion that only the with-skill run could satisfy is not an assertion, it is a description of the skill.

Spawn runs with the task tool, one child per configuration per task; each child gets the prompt, the skill path (or the baseline path), and the directory to write into. Have each child load the skill the way your agent loads it — a registry entry, a skill URI, or the installed directory — so the run exercises deployment, not a local file that hosts cannot see.

### Assertions for a skill

Borrow the three fabrication classes and add one:

| Class | Check |
|---|---|
| Artefact exists | The required file or file set was written this run |
| Required sections present | The skill's output contract headings exist in order |
| No invented number | Every figure traces to a source the run read |
| No bypass | The run did not skip a gate the skill declares (an accessibility scan, a required verification command) |

Record tokens and duration per run. A skill that doubles the pass rate for a tripled cost may still be right, but the decision needs the number.

## Transcript review

Read the transcript, not only the output. An output can be right for the wrong reasons.

| Look for | Meaning |
|---|---|
| The same helper written in every with-skill run | The skill should bundle it — one script replaces three improvisations |
| Steps the skill made the model do that produced nothing | Cut the instruction that caused them |
| The skill's own vocabulary echoed without the work | The instruction is being recited; make it do something observable |
| A verification step the skill requires, skipped | The requirement is buried; move it into a checklist or an exit criterion |
| The without-skill run doing better on one task | Either the skill over-constrains that task, or the assertion is blind to quality |

## Iterating the description

Change one thing at a time and re-measure the whole phrasing set.

1. **Add the user's words.** The phrasing that missed contains the vocabulary the description lacks; add it in the user's register, not in jargon.
2. **State the situation, with a `Use when ...` clause, and optionally the deliverable first.** "Use when someone is doing Y. Produces X." The trigger is what the selector matches, so a description that only lists situations still routes; this repository's convention of leading with the deliverable is a prefix, and a deliverable with no trigger clause under-triggers.
3. **Name the boundary.** `Not for ... (other-skill)` prevents the trap that keywords alone cannot.
4. **Re-run the full set, including the previously passing phrasings.** A fix that breaks two working triggers is a net loss.
5. **Hold out phrasings.** Keep two or three unseen during tuning and run them at the end; otherwise the description is fitted to the test set and will not generalise.

A description rewrite is done when every intended phrasing hits, every trap misses, and the held-out set hits too.

## Reporting

```markdown
## Trigger recall
| Phrasing | Expected | Selected | Result |
|---|---|---|---|
| ... | this skill | this skill | hit |

## With-skill vs baseline
| Task | Baseline (n/N) | With skill (n/N) | Tokens | Duration |
|---|---|---|---|---|

## Transcript findings
- ...

## Verdict
Ship / revise — and the one change that would move the number.
```

The verdict names the mechanism, not the mood: "the empty-state phrasing misses because the description says *interfaces* but the user says *screens*" is a revision; "feels better" is not.
