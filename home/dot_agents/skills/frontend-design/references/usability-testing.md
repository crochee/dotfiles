**Load this reference when:** planning or running a usability test — writing the task script, running sessions, recording observations, or grading and reporting the findings.

## Contents

- [What a usability test answers](#what-a-usability-test-answers)
- [The five-participant protocol](#the-five-participant-protocol)
- [Task scripts](#task-scripts)
- [Running a session](#running-a-session)
- [Observations](#observations)
- [Severity grading](#severity-grading)
- [The report](#the-report)

## What a usability test answers

A usability test answers one question: can someone who is not the designer complete this job,
and where do they fail. It does not answer whether people like the interface, whether they
would pay, or how the design compares to a competitor. Those are different studies; asking
all of them at once gets an answer to none.

The test is run on the task, not on the person. When a participant fails, the finding is
about the screen — the screen is what you can change.

## The five-participant protocol

Five participants per homogeneous group finds the majority of the blocking problems in a
flow. This is a heuristic, not a guarantee: it works because the severe problems repeat
across users, and it stops working when the group is not homogeneous. Run five, fix, run
five again — two rounds beat one round of ten, because the second round tests the fix.

| Decision | Default | Reason |
|---|---|---|
| Participants | 5 per distinct user group; run a separate round for a materially different group | Mixing groups averages away the finding |
| Recruitment | Representative of the role that does the job, not of the demographic | The variable that matters is familiarity with the task |
| Session length | 30–45 minutes, 3–5 tasks | Longer sessions trade attention for coverage |
| Moderation | A moderator who did not design the screen | The designer hears the intent and stops hearing the confusion |
| Medium | The real build, at the real breakpoint; two participants on mobile if mobile matters | A prototype that cannot fail hides the failures |
| Data | Observations and pass/fail per task, recorded live | Memory rewrites itself in the direction of the hypothesis |
| Incentive | Whatever the context requires — but the same for every participant | Recruitment bias is the cheapest bias to avoid |

**Ethics, briefly:** say what is being tested (the screen, not them), ask permission before
recording, let them stop at any point, and never make them feel stupid for failing. A
participant who feels judged starts performing and stops being a user.

## Task scripts

A task script is a goal and a context, never a set of steps. The test is whether the
interface communicates the steps; writing them into the script tests the script.

| Part | Write it as | Bad version |
|---|---|---|
| Setup | "You are a finance admin. Two invoices are overdue." | "Click Invoices." |
| Task | "Find the overdue invoices and pay the older one." | "Use the filter at the top right, then press Pay." |
| Success | "The older invoice shows as paid." — observable, binary | "The user feels it went well." |
| Time box | 5 minutes, then move on | No limit — one stuck participant eats the session |

Task count: 3–5, ordered from simple to complex, with the primary job of the screen always
included. The first task is a warm-up that must succeed, so the participant is not already
lost when the real task starts.

The script lives in the artefact set as `usability-test.md`, written from
`assets/usability-script.template.md`, and is versioned with the design it tests.

## Running a session

The moderator's job is to shut up. Four rules carry most of the value:

1. **Think aloud, without prompting.** Ask for a running commentary once, at the start, then
   stay quiet. Silence for ten seconds is data, not a gap to fill.
2. **Never name the control.** "What would you do next?" not "What about the button at the
   top?" A hint destroys the observation it was meant to clarify.
3. **Ask about the expectation, not the action.** "What do you expect to happen?" surfaces
   the mental model; "why did you click that?" invites a rationalisation.
4. **Record the failure verbatim.** The exact words of the confusion ("I don't see where to
   add one") are the finding; "struggled with the empty state" is the summary and loses the
   cause.

After each task ask two questions, in this order: "How did that go?" and "What did you expect
would happen when you did that?" Then move on.

## Observations

Record one row per observation, live, during the session. Columns that pay for themselves:

| Participant | Task | Step | What happened | Quote | Pass / fail | Severity |
|---|---|---|---|---|---|---|
| P3 | Find overdue invoice | after list load | looked for a filter; found the search instead | "where do I narrow this down?" | fail | 3 |

Rules that keep the sheet useful:

- **Event, not interpretation.** "Clicked Pay twice, then checked the balance" is an event;
  "confused by the button" is a conclusion you draw after all five sessions.
- **Separate the observation from the cause.** Record the event first; hypothesise later, in
  the analysis, where the hypothesis can be wrong without corrupting the data.
- **Note what worked too.** The step where participants succeeded without hesitation tells
  you which pattern to extend when fixing the failure.
- **Timestamp or step number every row**, so a video, if there is one, can be trimmed to the
  finding instead of reviewed whole.

## Severity grading

Grade after the sessions, not during, and grade the problem rather than the participant.

| Severity | Meaning | Response |
|---|---|---|
| 4 — Catastrophic | The task cannot be completed, or the user loses data | Fix before shipping; blocks the release |
| 3 — Major | The task completes but with a detour, or the user needs help | Fix before shipping |
| 2 — Minor | Slows the user down; they recover without help | Fix in the next iteration |
| 1 — Cosmetic | Noticed, has no effect on completion | Fix when the area is touched anyway |
| 0 — Not a problem | An observation without a cost | Record it; change nothing |

Grade against three inputs, and record all three: does it stop completion, does it recur
across participants, and does it cost time or a support ticket. A problem found once with a
severe cost is still severe; a problem found five times that costs nothing is cosmetic.

**Three-participant rule.** When the same problem appears in three of five sessions, treat it
as a defect of the design rather than of those participants. When it appears once, keep it in
the list — retest it in the next round rather than fixing blind.

## The report

The report is short. It exists so someone can act, not so the study looks thorough.

1. **What was tested** — the build, the date, the two user groups, and what was out of scope.
2. **The tasks, with pass rates** — `n/N` per task, plus the median time. No averages across
   tasks: a mean of task times is a number with no meaning.
3. **Findings, ordered by severity then by frequency** — each with the observation, the
   quote, the severity, and the recommended fix with a location (`path:line` when the finding
   is in the code, the screen and control when it is in the design).
4. **What worked** — at most three items; patterns to preserve.
5. **What was not answered** — the questions the study raised and did not settle. This is
   where the next round's tasks come from.
6. **The change log** — what was fixed since the last round, and whether the retest confirmed
   the fix. A fix is confirmed by the next round, never by its own author.

**Never report a finding without a quote or an observation behind it, and never report a pass
rate for a task that was not run.** Five participants who were sent the wrong build produce
zero data, not five passes.
