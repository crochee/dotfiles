# {{PRODUCT}} — usability test script

**Build under test:** {{commit / URL / build id}}
**Date:** {{YYYY-MM-DD}} — **Round:** {{1}}
**Moderator:** {{name — someone who did not design the screen}}
**Participants:** {{n}} × {{the user group}} — **Medium:** {{desktop 1440 / mobile 390}}
**Recording:** {{tool, or "notes only"}} — **Consent:** {{how consent was asked and recorded}}

## Session plan

| # | Task | Success criterion (observable) | Time box |
|---|---|---|---|
| 0 | Warm-up: {{a task that must succeed}} | {{observable end state}} | 3 min |
| 1 | {{task}} | {{observable end state}} | 5 min |
| 2 | {{task}} | {{observable end state}} | 5 min |
| 3 | {{task, the primary job}} | {{observable end state}} | 8 min |
| 4 | {{task, a recovery path — trigger the error state}} | {{observable end state}} | 5 min |

## Script

Read aloud, do not improvise:

> "Thanks for coming. We are testing the screen, not you — you cannot do anything wrong here.
> I will stay quiet while you work, because I want to see what the screen tells you on its
> own. Please think out loud: say what you are looking at and what you expect to happen.
> If you get stuck, that is a finding for us, not a failure for you. You can stop at any
> time, and you can ask me to delete the recording."

Then, per task:

> "**{{setup context in one sentence}}.** Your task: {{the goal, never the steps}}.
> Tell me when you think you are done."

Prompts allowed — and only these:

| Situation | Say |
|---|---|
| Silence longer than ~15 s | "What are you thinking?" |
| Participant asks for help | "What would you try next?" |
| Participant asks "is this right?" | "What do you expect it to do?" |
| Participant finishes | "How did that go?" then "What did you expect would happen when you did that?" |
| Participant gives up | "What would you have needed to see to keep going?" |

Never say: the name of a control, "just", "you should see", "try the top right", or anything
that confirms an action was correct before the task ends.

## Observation sheet

One row per observation, recorded live. Event first, interpretation later.

| Participant | Task | Step | What happened | Quote (verbatim) | Pass / fail | Severity |
|---|---|---|---|---|---|---|
| {{P1}} | {{1}} | {{after submit}} | {{clicked Pay twice, then checked the balance}} | {{"did that work?"}} | {{fail}} | {{3}} |

Severity: 4 catastrophic · 3 major · 2 minor · 1 cosmetic · 0 not a problem. Grade after all
sessions, in the analysis — not during the session.

## Per-task result

| Task | Pass | Median time | Notable detours |
|---|---|---|---|
| {{1}} | {{n}}/{{N}} | {{mm:ss}} | {{what the failures had in common}} |

No averages across tasks: a mean of task times is a number with no meaning.

## Analysis

**Findings, ordered by severity then frequency**

| # | Finding | Evidence (participants, quotes) | Severity | Fix | Location |
|---|---|---|---|---|---|
| 1 | {{finding}} | {{P2, P4: "…"}} | {{3}} | {{the change}} | {{path:line or screen + control}} |

**What worked** (at most three, to preserve)

| Pattern | Evidence |
|---|---|
| {{pattern}} | {{participants who succeeded without hesitation}} |

**Three-participant rule:** a problem seen in ≥3 of 5 sessions is a defect of the design, not
of those participants. A problem seen once stays in the list and is retested next round — it
is not fixed blind.

**Not answered by this round**

| Question | How the next round answers it |
|---|---|
| {{question the sessions raised}} | {{new task, or a different user group}} |

**Change log since the previous round**

| Previous finding | Change made | Confirmed by retest? |
|---|---|---|
| {{finding}} | {{what changed, with the commit}} | {{yes: round 2, P1/P3 / not yet}} |
