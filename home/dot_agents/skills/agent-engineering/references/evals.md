**Load this reference when:** designing an eval suite, choosing assertions, reporting a pass rate honestly, or setting a regression threshold.

# Evals

An eval suite answers one question with a number: does this change make the agent better at the tasks it exists for? Everything below serves that number being trustworthy.

## Task set

| Property | Target | Why |
|---|---|---|
| Size | 10–20 tasks for a working agent; 20+ for a release gate | Fewer cannot separate a real change from noise; more cost more than they add |
| Coverage | Every mode and every tool used at least once | A tool no task exercises is untested |
| Realism | Phrased as a user would phrase it, with the mess included | Clean prompts measure the suite, not the agent |
| Independence | No task depends on another's artefacts | A failure should not cascade |
| Determinism | The same inputs, the same starting state | Otherwise the pass rate moves on its own |
| Difficulty mix | ~60% routine, ~30% hard, ~10% edge, plus 2 refusal cases | A suite that only contains hard cases cannot measure a fix |
| Stability | Fixtures pinned; no live upstream data | A drifting answer makes a flaky test look like a regression |

Negative cases matter as much as positive ones. "Do not send the email" and "refuse the destructive command" are tasks, with an expected outcome of *no side effect*.

## Assertions

Two kinds, and the choice is not a preference — it decides whether the result repeats.

| Assertion kind | Use when | Cost | Failure mode |
|---|---|---|---|
| Deterministic | The property is checkable: file exists, section present, command exits 0, value equals | Cheap, fast, repeatable | Can miss quality; a padded document passes |
| Model grading | The property needs judgement: tone, design fit, whether a summary is faithful | Slower, noisy, costs tokens | Rubric drift; the grader is another model with its own moods |

Rule: **every deterministic property is checked deterministically**, even when a grader also runs. A grader checking whether a file exists wastes a model call and introduces variance around a file-system fact. Reserve grading for what a `grep` cannot see, and give the grader the rubric in the prompt, not in its memory.

## The three fabrication assertions

An agent can pass every semantic check and still invent its way through. These three catch that class of failure and belong in every suite:

1. **Artefact exists.** The claimed deliverable resolves to a real path, non-empty, written this run. A transcript that describes a file it never wrote fails here.
2. **Required sections present.** The contract's headings exist, in order. This catches a fluent document that quietly dropped the constraints section.
3. **No invented number.** Every number in the output traces to a source the run actually read: a command output, a file, a measurement. Store the source with the claim, then compare. A plausible "improved by 34%" with no run behind it fails.

The third is the one worth writing first. It is cheap to check when the agent records evidence, and it is impossible to check after the fact when it does not — which is why the output contract asks for `path:line` and command output next to every figure.

## Measuring the pass rate

- Run each configuration **at least three times**. One run is an anecdote; two runs disagree and tell you nothing about the third.
- Report `n/N` per task and the aggregate, never a bare percentage. `17/20` over 3 runs means 60 task-runs with 51 passes; say which.
- Record per run: task id, configuration, passed, failed, token count, wall-clock duration, and any error.
- Report variance, not just the mean. A task that passes 2/3 is unstable and should be fixed or removed, not averaged into a number that hides it.
- A change that raises the pass rate by one task in twenty, on a single run, is not a result. Either run more or call it noise.

### Reporting shape

| Configuration | Runs | Passed / total | Tokens (mean) | Duration (mean) |
|---|---|---|---|---|
| without skill | 3 × 20 | 31/60 (52%) | 41,200 | 96 s |
| with skill | 3 × 20 | 54/60 (90%) | 58,900 | 142 s |

Follow the table with the delta per task where it matters, the unstable tasks, and the cost of the improvement: +17.7k tokens and +46 s per task buys +38 points of pass rate. That trade is a decision someone can make; a single percentage is not.

## Regression thresholds

Set the threshold before the run, or the result will be explained into acceptability.

| Signal | Block | Warn |
|---|---|---|
| Pass rate, aggregate | Drop > 5 points across runs | Drop 2–5 points |
| Any task that passed before | Now fails twice in three runs | Fails once |
| Cost per successful task | +20% | +10% |
| Duration, p50 | +30% | +15% |
| New failure class (fabrication, destructive side effect) | Always | — |

A drop in pass rate is a regression even when cost fell. A cost increase is acceptable only when it is bought deliberately, with the pass-rate gain recorded next to it.

## Failure analysis

Group failures before fixing. The groups have different fixes.

| Failure | Look at | Typical cause |
|---|---|---|
| Same task, every run | The task or the tool it needs | Ambiguous prompt, missing tool, wrong schema |
| Same task, some runs | Ordering, temperature, a race | Non-deterministic fixture or a shared resource |
| Many tasks, one assertion | The assertion or the contract | Assertion stricter than the contract, or the contract unstated |
| Many tasks, varied assertions | The context budget or the model tier | Compaction losing state, or a step rated below its difficulty |
| Passes but produces bad work | The assertion set | Assertions test presence, not correctness — add the fabrication checks |

## Working with the template

`assets/eval-suite.template.py` holds the shape: a task list, one assertion function per task, a runner that records pass rate, tokens and duration, and a `main` that prints the results table. Fill the placeholders, keep the runner's output schema stable across iterations, and write `evals/report.md` from the JSON it emits rather than by hand.

When the thing being evaluated is a skill rather than a tool-calling loop, the machinery holds and the baseline changes: no-skill versus with-skill, plus a trigger measurement the task suite cannot see.
