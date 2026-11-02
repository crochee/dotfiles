---
name: agent-engineering
description: "Builds or evaluates an LLM agent as a bounded system: context budget, tool schemas the model can act on, subagent slices, and a measured eval pass rate. Use when designing an agent loop, its tools, MCP integration, or its eval suite. Not for prompt copywriting, model training, Kubernetes operators (k8s-operator), or an HTTP contract (api-design). 中文：设计 agent 循环、工具 schema、子 agent、eval 通过率。"
license: MIT
metadata:
  version: "1.1.0"
---

# Agent Engineering

Builds or evaluates an LLM agent as a bounded system: a task decomposed against a context budget, tools whose schemas and errors the model can act on, subagents with disjoint slices, and an eval suite whose pass rate is measured per run rather than asserted.

## When to Use

Three modes, and the mode decides where the work starts:

| Mode | You are here when | Start at | First artefact |
|---|---|---|---|
| Build | There is no loop, or the loop is a prompt with no accounting | Step 1 | The step table and the caps |
| Extend | A running agent needs a tool, a compaction rule or a child | Step 3 (tools) or step 4 (orchestration) | The changed interface, plus the eval that covers it |
| Evaluate | The agent exists and nobody can quote its pass rate | Step 6 | `evals/evals.json` and a three-run baseline |

The same rules apply to a single-loop agent and to a supervisor with children: a child is an agent with a smaller window and the same accounting. A skill is evaluated with the same machinery and a different baseline — see `references/skill-evals.md`.

Reviewing an agent you did not write is Evaluate plus a code pass: walk steps 2–7 against the source, and cite `path:line` for every finding. A finding without a location is an opinion about taste.

Not for prompt copywriting, model training or fine-tuning, and not for Kubernetes operators — those belong to `k8s-operator`. An HTTP contract behind a tool belongs to `api-design`. It does not schedule this session's own work; it decides only what the agent being built runs as a child.

## Stack Selection

Read the repository before writing server code. The dependency file decides which guidance applies; the request only says what the agent should do.

| Repository signal | Guidance | Read |
|---|---|---|
| `package.json` depends on `@modelcontextprotocol/server` or `@modelcontextprotocol/sdk` | TypeScript SDK | `references/mcp.md#typescript` |
| `pyproject.toml` declares `mcp` (FastMCP) | Python SDK | `references/mcp.md#python` |
| `Cargo.toml` depends on `rmcp` | Rust SDK | `references/mcp.md#rust` |
| Two or more of the above | one SDK per existing server; a new server follows the repository's dominant language | the matching section |
| None | no server work to do; review against the shared invariants | `references/architecture.md`, `references/context.md` |

Read the lockfile, not memory, for the SDK version. The TypeScript SDK splits at v1 (`@modelcontextprotocol/sdk`) and v2 (`@modelcontextprotocol/server`), and `rmcp` changed its macro shape across 3.x — a snippet recalled from training data is the most common way a new server fails to compile or, worse, compiles and never answers a second request.

Three cases the table does not cover, and neither should you:

- **The repository consumes an MCP server but does not build one.** There is no SDK section to read; the interface rules still apply to how the client is configured and how its results are handled.
- **A client and a server live in different languages.** Each side follows the section for its own file; the wire contract is the shared one.
- **The SDK is present but the task is not server work.** Presence is a signal, not an instruction. An agent loop in a Rust repository needs no `rmcp` section. Start from the shared invariants and load the SDK section only when the tool surface is actually being written.

## Workflow

1. **Decompose the task and budget the context.** Write the loop before the prompt: one step is one model call with a known input set. List what enters the window at each step — system, tool schemas, history, working set — and the reserve for the reply. → `references/context.md`
   *Exit:* a step table names each step's inputs, output artefact and token estimate; the total fits the window with the reserve, or the point where compaction runs is named.
2. **Set limits and stop conditions.** Four caps — iterations, wall clock, tokens (and the cost derived from them), tool calls — plus a no-progress rule. The run ends with exactly one of `done`, `budget-exhausted`, `stalled`, `error`. → `references/architecture.md`
   *Exit:* every cap is a named constant read by one guard inside the loop, and the run log records which stop result fired.
3. **Design the tools and the MCP interface.** One tool per verb the model would say; the description is the trigger and the schema is the documentation. Errors name the next action. Lists paginate. → `references/mcp.md`
   *Exit:* for every tool you can quote its name, description, described input fields, error path, annotations, and the cursor field if it can return more than one page.
4. **Decide what runs as a subagent.** A child earns its cost only when its slice is disjoint from everything else running, self-contained, and cheap to merge. Otherwise run the step inline. → `references/orchestration.md`
   *Exit:* a fan-out plan lists, per child, its slice, its solution space and its acceptance; the parent's plan, shared contracts and merge are owned by the parent.
5. **Register the state.** Every claim in the plan is written down and classified — `source-confirmed`, `requirement`, `proposal`, `assumption` or `open question`. → `references/architecture.md`
   *Exit:* no claim in the plan lacks a class, and every open question names what resolves it.
6. **Build the eval suite and measure the pass rate.** Assertions first, then runs; at least three runs per configuration, each with tokens and duration. Every suite carries the three fabrication checks — the artefact exists, the required sections are present, no number is untraceable to a source the run read. → `references/evals.md`
   *Exit:* the report states `n/N` per configuration, the difference between configurations, and the per-run cost — not a percentage harvested from one lucky run.
7. **Gate the cost regression.** Compare cost per **successful** task against the baseline, not cost per run. A cheaper run that fails more is more expensive. Default thresholds: a pass-rate drop of more than 5 points blocks, a cost-per-success rise above 20% blocks, and any new fabrication or destructive-side-effect failure blocks regardless of the averages. → `references/cost.md`
   *Exit:* the decision (ship, revert, re-tier) is recorded next to the measured numbers that produced it.

## Quick Decisions

A symptom is evidence of a specific missing mechanism. Check the mechanism, not the symptom.

| Symptom | Likely cause | First check |
|---|---|---|
| The agent repeats the same call | No no-progress detector, or the tool result omits what changed | The `(tool, args, result)` signature history; add the `stalled` stop |
| Context overflows mid-run | No budget arithmetic, or tool results arrive unbounded | The step table's per-step token estimate versus the window |
| A storm of small tool calls | Tool set is too granular; no batch or filter argument | Count calls per task; collapse list+get into a search with filters |
| Answers cite data that was truncated | Truncation was silent | The tool result's pagination/truncation fields |
| Pass rate cannot be reproduced | One run per configuration, or model grading with an unstated rubric | Number of runs, the grader prompt, per-task results |
| Cost spikes with no task change | Tool schema or system prefix changed and the cache was invalidated | The cacheable prefix between two runs; the tool-call count |
| Fan-out that loses the plot | Slices overlap, or a child re-planned the whole task | The slice boundaries and whether each child had its own acceptance |

| Need | Reach for | Avoid |
|---|---|---|
| A step that reads one file and returns a value | Inline tool call | A subagent that costs a full context to start |
| A step that maps an unknown area | One scout, then a decision | Parallel scouts on the same files |
| 3+ independent slices the agent being built spawns | Fan-out, one batch | Serial spawning dressed as parallelism |
| The model needs one record from a large source | A query tool with filters | Pasting the whole source into the prompt |
| A check that must hold every run | Deterministic assertion | Model grading, which drifts with the grader |
| A judgement call (tone, design fit) | Model or human grading with a stated rubric | A brittle string match |

Compaction is a decision with a trigger, not an instinct. Act at the first trigger, not after an overflow.

| Trigger | Action | Must survive verbatim |
|---|---|---|
| Live tokens above 70% of the window | Summarise steps older than the last two | Task, registry, acceptance, last tool result |
| A single tool result above ~10% of the window | Page it; keep the first page, the count and the cursor | Ids and the cursor |
| A subagent returns | Compress its transcript into findings | Findings, artefact paths, evidence |
| A phase ends (research → build) | Compress the phase into decisions | Decisions, registry rows, evidence |

Deciding *where* a capability lives is the recurring design question. Put it where the failure can be caught:

| The work is | Put it in | Because |
|---|---|---|
| A fixed transformation with a testable output | Code | Deterministic, cheap, and a failing test says so |
| A choice that depends on the task | A tool the model may call | The model knows when; the code does not |
| A procedure that must hold on every run | The loop, or the skill text | Stated once instead of hoped for in each prompt |
| A fact the model needs at every step | The system prompt, briefly | A tool call per step is a tax on the budget |
| A disjoint slice needing its own context | A subagent | The parent's window is not spent on it |

## Output

Default locations; an existing repository layout wins and is stated in the report.

| Mode | Deliverable | Must contain |
|---|---|---|
| Build / Extend | `docs/agent/architecture.md` | Caps table, stop-result vocabulary, loop skeleton, state registry, the enforcement point for each cap |
| Build / Extend | `docs/agent/context-budget.md` | Per-step inputs, token estimates, reserve, compaction point |
| Tool / MCP work | Server module plus a smoke test | Tool inventory with schemas, annotations, error messages, pagination, transport and auth |
| Evaluate | `evals/evals.json` | Task id, prompt, expected artefact, assertion list |
| Evaluate | `evals/report.md` | `n/N` per configuration over ≥3 runs, tokens, duration, regression verdict |
| Evaluate (review) | `docs/agent/review.md` | One row per finding — severity, location, mechanism missing, evidence — and no finding without a `path:line` or a run-log line |

An eval suite starts from `assets/eval-suite.template.py`; fill the placeholders and keep its runner shape so results stay comparable across iterations.

`evals/report.md` carries one table per configuration plus the comparison, then the unstable tasks, the per-task delta, and the decision. The table shape and the tool inventory — one row per tool, next to the server — are in `references/evals.md`; a report without a decision is a table looking for an owner, and an inventory row that cannot be filled is a tool that is not finished.

## References

| File | Load when |
|---|---|
| [references/architecture.md](references/architecture.md) | Specifying the loop, its caps or the claim registry — the run accounting table, stop results, enforcement in code, the five record classes. |
| [references/context.md](references/context.md) | Fitting a task into a window — budget arithmetic, compaction, retrieval, structured tool results, visible truncation. |
| [references/mcp.md](references/mcp.md) | Building or reviewing an MCP server — cross-language rules first, then the TypeScript, Python or Rust SDK section. |
| [references/orchestration.md](references/orchestration.md) | Deciding whether to fan out, writing a child's contract, or diagnosing a fan-out that lost the plot. |
| [references/evals.md](references/evals.md) | Designing an eval suite, choosing assertions, reporting a pass rate, setting a regression threshold. |
| [references/skill-evals.md](references/skill-evals.md) | Evaluating a skill itself — trigger recall, with-skill versus without-skill runs, transcript review, description tuning. |
| [references/cost.md](references/cost.md) | Accounting tokens per phase, designing cacheable prefixes, tiering models, or attributing a cost spike. |
| [assets/eval-suite.template.py](assets/eval-suite.template.py) | Starting an eval suite — the task list, assertion functions, runner and results table. |

## Verification Checklist

- [ ] Every cap has one enforcement point in code; none is enforced only by prose in the prompt.
- [ ] A run that hits a cap returns its stop result (`budget-exhausted`, `stalled`, `error`) and does not silently continue.
- [ ] Every claim in the plan carries one of the five record classes; assumptions name what would falsify them.
- [ ] Every tool has a description that says when to use it and when to use its sibling, a schema with described fields, and an error message that names the next action.
- [ ] Every list-returning tool has a pagination field, and truncation is visible in the result itself.
- [ ] The SDK section used matches the lockfile version, not a remembered snippet.
- [ ] The eval suite reports `n/N` per configuration over at least three runs, with tokens and duration per run.
- [ ] Assertions cover the three fabrication classes: artefact exists, required sections present, no invented number.
- [ ] The cost comparison is per successful task and is recorded with the decision it caused.
- [ ] No number in the deliverable is unmeasured; an unrun check is written as *not run*.
