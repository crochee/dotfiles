**Load this reference when:** specifying an agent loop, its caps or its claim bookkeeping, before the first model call is wired.

# Architecture: Accounting and State

An agent is a loop with a budget. The prompt describes the job; the accounting decides whether the job ends well. Write the accounting first — it is the part a prompt cannot retrofit.

## Run accounting

Every run is bounded on four axes — iterations, wall clock, tokens and cost, tool calls — plus a no-progress rule, and stops for one recorded reason.

| Cap | Starting value | Enforced at | Breach result |
|---|---|---|---|
| Iterations | 25 model calls | Counter incremented at the top of the loop | `budget-exhausted` |
| Wall clock | 15 minutes | Deadline compared before each model call and each tool dispatch | `budget-exhausted` |
| Tokens | 1.5× the measured cost of a known-good run | Usage accumulated after every call; pre-flight estimate for large inputs | `budget-exhausted` |
| Cost | Tokens × the price table for the model in use | Same accumulator, converted once at the boundary | `budget-exhausted` |
| Tool calls | 3× the iteration cap, or a per-tool cap for expensive tools | Dispatcher, before the call is made | `budget-exhausted` |
| No progress | 3 identical actions | Signature of `(tool, args, result)` kept for the last N steps | `stalled` |

The starting values are defaults for a first build, not laws. Set them from one observed run: run the task manually, count what it took, and put the cap at roughly one and a half times that. A cap set without a measurement is a guess, and a guess is either free (too high, no protection) or harmful (too low, truncates good runs).

### Stop results

The loop returns exactly one of four values. Callers, logs and evals branch on these strings, so they are part of the interface.

| Result | Meaning | What the caller does |
|---|---|---|
| `done` | The task's acceptance was checked and passed | Consume the artefact |
| `budget-exhausted` | A cap fired with work unfinished | Report the partial artefact and the cap; do not claim success |
| `stalled` | Repeated actions produced no new state | Report the repeated action; the loop will not recover without a new input |
| `error` | A tool or the model failed in a way the loop cannot route | Surface the error text; decide retry outside the loop |

`done` is not "the model said it finished". It is "the acceptance check passed". Those differ precisely when the agent is wrong.

## Enforcement in code

Caps in the system prompt are advice. A model that ignores "you have ten steps" produces an eleventh step, and nothing stops it. Put one guard at the top of the loop and make every path pass through it.

```python
class Budget:
    def __init__(self, iterations=25, seconds=900, tokens=200_000, tool_calls=75):
        self.iterations = iterations
        self.deadline = time.monotonic() + seconds
        self.tokens = tokens
        self.tool_calls = tool_calls
        self.used = {"iterations": 0, "tokens": 0, "tool_calls": 0}

    def spend(self, kind, amount=1):
        self.used[kind] += amount
        if self.used[kind] > getattr(self, kind):
            raise BudgetExhausted(kind)
        if time.monotonic() > self.deadline:
            raise BudgetExhausted("wall_clock")
```

The loop catches `BudgetExhausted` at one place and converts it to `Stop("budget-exhausted", kind=kind)`. Three properties make this work:

- The guard is called **before** the spend it protects — before the model call, before the tool dispatch — so a breached cap never produces another side effect.
- Token usage is recorded from the provider's response, not estimated from characters. An estimate that is 30% low turns a token cap into a wall-clock cap.
- The stop result carries which cap fired. "It ran out of budget" is not diagnosable; "tool_calls exceeded 75 at step 12" is.

Log one line per step: step index, model, tokens in and out, tools called, cumulative cost, elapsed. That log is the only evidence for attributing a later cost spike.

## Loop skeleton

Language-neutral shape; the mechanics matter more than the syntax.

```text
run(task, budget, registry):
    history = [system, tools, task]
    for step in 1..budget.iterations:
        budget.guard()                        # caps checked before spending
        reply = model(history)                # one call, complete history
        budget.spend("tokens", reply.usage)
        history.append(reply)

        if reply.tool_calls is empty:
            if accept(task.artefact): return Stop("done")
            history.append(nudge(accept.missing()))   # bounded: max 2
            continue

        for call in reply.tool_calls:
            budget.spend("tool_calls")
            result = dispatch(call)           # returns text + structured fields
            history.append(result)
            signature = hash(call.name, call.args, result.summary)
            if signature in recent(3):
                return Stop("stalled")
            remember(signature)

    return Stop("budget-exhausted", cap="iterations")
```

Two details carry most of the value. The acceptance check runs against the artefact, not the narration. And the stall signature includes the result, so a tool that legitimately returns different data twice is not mistaken for a loop.

## State registry

A plan mixes things that were observed with things that were decided, and a long run compacts the conversation until the distinction is gone. Write the distinction down and keep it on disk.

| Class | Means | Evidence required | Permitted use |
|---|---|---|---|
| `source-confirmed` | Read from the repository, the docs or the running system | `path:line` or a URL and the quoted line | May drive the plan |
| `requirement` | Stated by the user in this task | The user's words, quoted | May drive the plan |
| `proposal` | A design choice made by the author | The rationale and the alternative rejected | May drive the plan; must be revisitable |
| `assumption` | Believed but unverified | What observation would falsify it | May drive the plan only with a stated fallback |
| `open question` | Unresolved and consequential | What resolves it, and by when | May not drive an irreversible step |

The rule is mechanical: **every claim in a plan carries one class**. A claim with no label is a belief, and a plan built from unlabelled beliefs fails at the first place reality disagrees — usually after the expensive work.

Registry format, in the plan document rather than in chat:

| # | Claim | Class | Evidence or falsifier |
|---|---|---|---|
| 1 | The service exposes a cursor-paginated `/users` endpoint | source-confirmed | `api/openapi.yaml:412` |
| 2 | The agent must run on the existing 8k-token model | requirement | "we ship on the small model" |
| 3 | One tool per endpoint beats four workflow tools | proposal | Rejected: workflow tools hide recoverable errors |
| 4 | Rate limit is 10 requests/second | assumption | Falsified by a 429 burst; fallback: exponential backoff |
| 5 | Whether retries are counted against the token cap | open question | Answered by the platform owner before the budget is final |

An `open question` blocks only irreversible work. Everything reversible can proceed with the default written next to the question.

## Failing modes

| Pattern | Why it fails | Fix |
|---|---|---|
| Caps only in the system prompt | The model is not the enforcement layer | One guard in code, checked before spending |
| `done` when the model says "finished" | The model reports intent, not state | Acceptance check against the artefact |
| Token budget estimated from characters | Drift of 20–40% across content types | Sum provider-reported usage |
| No-progress detection disabled for "creativity" | Loops burn the whole budget before anyone notices | Compare result signatures; three repeats is enough |
| Registry kept in the transcript | Compaction deletes exactly the evidence | Persist the registry as a file, reload after compaction |
| Plan states conclusions without classes | Unverifiable work looks the same as verified work | Class + evidence column, checked in review |
