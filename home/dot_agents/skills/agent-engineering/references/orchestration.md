**Load this reference when:** deciding whether to fan work out to subagents, writing a child's brief, or diagnosing a fan-out that produced volume instead of progress.

# Orchestration

A subagent is a fresh context with its own budget. It costs the tokens to brief it and the tokens to read what it returns, and it saves the parent from carrying a whole investigation in its window. That trade is worth it only when the child's work is genuinely separable.

## When a subagent beats an inline step

| Situation | Inline | Subagent |
|---|---|---|
| Read one known file, return a value | Yes — a child would cost more than the read | No |
| Map an unfamiliar area (which files, which entry points) | No — it floods the parent's context | Yes, one scout |
| Two or more slices that touch disjoint files | No | Yes, one batch |
| A long search whose result is three facts | No | Yes, with the facts as the required return |
| Review of work the author just wrote | Risk of shared assumptions | Yes, read-only reviewer |
| A judgement that needs the whole plan | Yes | No — the child would re-plan |

The tell is **disjointness**. If two slices would read the same files, they are one slice. If a slice needs the parent's full reasoning to start, it is not a slice.

## The decomposition contract

Every child gets four things. A child missing any of them fills the gap with its own plan, and that plan competes with the parent's.

1. **Target** — the files or directories it may touch, and what it must not touch.
2. **Slice** — the one question it answers or the one change it makes. Stated as a sentence with one verb.
3. **Solution space** — how open the problem is: `one fix, names given`; `single-flight cache load, the race is easy to miss`; `several retry shapes, error classes to choose`. This is a hint to reasoning depth, not a volume of work.
4. **Acceptance** — the observable result that ends the task: a file exists, a command prints a value, a test passes, a table has rows.

```text
# Target
src/parser/*.ts only. Do not edit src/cli/*.

# Slice
Move the offset arithmetic out of parse() into a single helper, keeping behaviour.

# Solution space
One fix; the helper name and signature are yours to choose.

# Acceptance
`bun test src/parser` passes and no call site in src/parser still adds offsets by hand.
```

Briefs are self-contained. The child cannot see the conversation, the user's tone, or the reason the parent chose this slice. Anything the child needs must be in the brief, and anything the child does not need is context it will pay for on every step.

## Fan-out width

Parallelism is bounded by two things: the number of disjoint slices, and the reviewer's attention.

- One batch per wave. Spawn every independent task in one call; spawning one, waiting, then spawning the next is serial work wearing a parallel costume.
- Practical ceiling: **8 concurrent children** per wave for code work, fewer when each writes files. Beyond that, merge cost and conflicting edits dominate the time saved.
- Never pad the batch to reach a number. Two genuine slices beat five slices where three are make-work.
- A wave ends when every child has returned or been cancelled. Do not start the next wave while a child that owns shared files is still running.

## What the parent owns

The parent keeps the work that cannot be split:

| Owned by the parent | Why it cannot be delegated |
|---|---|
| The plan and its ordering | A child given the plan re-plans it, differently |
| Shared contracts — interfaces, naming, file ownership | Two children inventing the same interface produce two incompatible ones |
| The merge | Only the parent sees all the returned evidence |
| Final verification | Each child verifies its slice; nobody verifies the seam |
| Communication with the user | A child answering the user fragments the decision |

Put the shared contract in the parent's context block and pass it verbatim to every child that needs it. A child that has to infer the interface will produce a plausible one, and the merge becomes a rewrite.

## Failure propagation

A child that cannot finish does not get to shrink the deliverable silently.

- Return the blocker, not a partial artefact dressed as complete: what was tried, what failed, what information is missing.
- The parent decides: retry with a narrower brief, take the slice inline, or change the plan. A child never decides to abandon an acceptance criterion.
- A timeout is a failure. Record it as such; a cancelled child that returns "done" on a partial result corrupts the merge.
- When one child fails, its siblings do not need to stop — unless they depend on the contract it was supposed to establish. Then the wave is invalid and the contract must be fixed before the second wave.
- Children must not edit files a sibling owns. If coordination is needed mid-flight, message the owner; the alternative is a race that produces a file neither child wrote intentionally.

## Anti-patterns

| Symptom | What happened | Fix |
|---|---|---|
| Ten children, all reading the same files | Slices were never disjoint | Re-cut by file or by question, not by verb |
| Wave after wave with no merge | Work was spawned to feel parallel | Batch one wave, merge, then decide |
| Every child returned a plan, no change | Briefs lacked a target and an acceptance | Add both; a child with no artefact to produce writes prose |
| Child rewrote files outside its slice | Target was implicit | State the allowed paths and the forbidden ones |
| Parent's context is full after the fan-out | Children returned transcripts instead of findings | Cap the return: findings, evidence, artefacts |
| Merge takes longer than the work | Conflicting interfaces | Parent owns the contract and passes it verbatim |
| Some children still running after the merge | Next wave started too early | One wave at a time; wait for the batch |

## What a child returns

The return is a handoff, not a story:

1. **Result** — what is now true that was not before. One paragraph.
2. **Evidence** — `path:line`, commands and their output, measurements. Anything claimed without a location is an opinion.
3. **Artefacts** — the files written, by path.
4. **Unfinished** — acceptance criteria not met, and why. Empty when complete.
5. **Surprises** — anything the parent's plan did not anticipate: a broken invariant, a file that contradicted the brief, a cost that is ten times the estimate.

The parent merges from these five fields. A child that returns a narrative forces the parent to re-read the work, which is the cost the fan-out was meant to avoid.
