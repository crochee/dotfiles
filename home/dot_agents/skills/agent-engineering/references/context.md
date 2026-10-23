**Load this reference when:** fitting a task into a context window, choosing what to compact, or diagnosing a run that overflowed or answered from truncated data.

# Context Engineering

The window is a budget with a hard ceiling and a soft cost curve. Treat every token as spent on purpose: what the model sees at step *n* is the only thing it can reason from at step *n*.

## Window arithmetic

Before the first call, add up the five consumers and check the total.

| Consumer | Grows with | Typical share | Control |
|---|---|---|---|
| System prompt and policies | A fixed size per deployment | 5–15% | Move procedure into tools or files the model reads |
| Tool schemas | Number of tools × fields | 10–25% | Fewer, coarser tools; short descriptions on rare ones |
| Conversation history | Steps × reply size | Unbounded without a rule | Compaction checkpoints |
| Tool results | Page size, verbosity | Often the largest consumer | Structured, paginated, capped |
| Working set (files, records in play) | The task's data | Task-dependent | Retrieve on demand; hold pointers |
| Reserve for the reply | Output budget | 10–20% | Never allocate down to zero |

Two rules follow from the table:

- Keep the live total at or below **70%** of the window before a compaction checkpoint. The top of the window is where the model's attention is least reliable, and the reserve is not optional: a request that leaves 500 tokens for a 4,000-token answer truncates the answer, not the prompt.
- Recompute the arithmetic whenever the tool set changes. Adding a schema is a permanent tax on every step, which is why a tool nobody calls is worse than a tool that does not exist.

### A worked example

A 32k-token window, seven tools, a task that reads four files.

| Item | Estimate |
|---|---|
| System prompt | 1,200 |
| Tool schemas (7 tools) | 3,400 |
| Task and acceptance | 300 |
| History after 6 steps | 4,000 |
| Current tool result | 1,800 |
| Working set (2 files held in full) | 9,000 |
| Reserve | 6,000 |
| **Total** | **25,700 / 32,000** |

The headroom is 6,300 tokens — enough for two more steps. The correct move is not to raise the ceiling but to stop holding whole files: keep the two paths and the relevant excerpts, retrieve the rest on demand. The same task then runs with roughly 18k live tokens at every step.

## What survives compaction

Compaction is lossy by design. Decide in advance what may be lost, and write the survivors to disk before the summariser runs.

| Artefact | Survives compaction | Why |
|---|---|---|
| The task and its acceptance | Yes, re-injected verbatim | The summariser paraphrases it into something the acceptance check no longer matches |
| The state registry | Yes, read from its file | Claims and their evidence are the decisions |
| Paths, ids, URLs, schema names | Yes, verbatim | A paraphrase of an identifier is a hallucination |
| Tool results older than the last two steps | Summarised to counts and ids | The full text is re-fetchable; the pointer is not |
| Reasoning narrative | Summarised or dropped | It is the cheapest thing to lose |
| Raw file contents held in the working set | Dropped, paths kept | Retrieval is one call; retention is every call |

Two operational rules: summarise at a checkpoint (after a tool returns a large result, after a subagent joins), never mid-reasoning-string; and after compaction, re-inject the task, the registry and the acceptance before the next model call, because the summary is a lossy view of them.

## Retrieval over retention

Holding data costs every subsequent step; fetching it costs one call.

- Prefer a search tool plus an id over pasting a corpus into the prompt. The model does not need the catalogue, it needs the row.
- Keep a small working set of *pointers* — paths, ids, line ranges — and a bounded excerpt only for the item under active work.
- When the task needs the whole document, split it by a semantic boundary (section, table) and process one part per step, with a running result that is itself short.
- A retrieval call that returns 200 rows and gets truncated is worse than one that returns 20 and says there are more. The model can act on the second.

## Tool results are context

Most context bloat comes from tools, not from prompts. A tool result is a message the model pays for on every later step.

- Return structured values with stable keys, not a paragraph about the values. `{"id": "U1", "name": "Ada", "role": "admin"}` costs less and is less ambiguous than a sentence describing the same record.
- Return counts and page boundaries explicitly: `count` and `next_cursor`, plus `total` only when the upstream can report it. Then a large result can be summarised as "20 of 1,340 rows, next cursor `abc`" without lying.
- Cap the response by **items**, not by characters. A character cut lands mid-record, and the model cannot tell which half survived. If the cap must be characters, shrink the item list until the text fits and report where the returned page ended.
- Separate the machine-readable payload from the human-readable rendering. If both are returned, make them agree, or the model will quote whichever suits it.

## Truncation must be visible

Silent truncation is the highest-severity context defect, because it produces confident wrong answers rather than errors. The model sees a complete-looking list and concludes it is complete.

Every truncated result carries three facts in the result itself:

```json
{
  "items": ["..."],
  "truncated": true,
  "omitted": 1180,
  "next": "cursor:eyJvZmZzZXQiOjIwfQ=="
}
```

The model can then ask for more, narrow the query, or state that the answer is partial. Without `truncated` and `next`, none of those behaviours are available. Apply the same rule to file reads: a range read returns `start_line`, `end_line`, `total_lines`.

## Summarisation checkpoints

Summarise at boundaries — after a large tool result, after a subagent joins, at a phase change — and never midway through a reasoning step. The trigger is a threshold, not a feeling: the first time the live count crosses the budget, the oldest steps go.

A summary has to be auditable. Require three properties of every one:

- **Falsifiable** — it states counts and ids rather than adjectives: "4 of 19 fields kept, ids U1–U4", not "a concise view".
- **Navigable** — every dropped artefact leaves a path or a cursor behind, so the next step can retrieve it in one call.
- **Bounded** — it is meaningfully shorter than what it replaces. A summary within 20% of the original cost a model call and bought risk.

Write "3 files read, contents dropped, paths kept" rather than a smooth paragraph that reads as a complete account. The paragraph is the failure mode: it is shaped like knowledge and carries less.

## The bigger-window fallacy

"Use a bigger window" is not a budget policy. Four reasons:

- **Attention degrades before the hard limit.** Retrieval quality across a long context falls well inside the ceiling; a fact at position 60k is not used as reliably as the same fact at position 2k.
- **Cost is linear and paid every step.** The prefix is re-sent on each call unless it is cached, and cached prefixes are invalidated by a changed tool schema or system prompt.
- **Latency compounds.** A longer prompt slows every step; an agent with 30 steps pays that cost 30 times.
- **Failure gets quieter.** An overflow is an error; a 90%-full window is a plausible-looking answer built from the wrong half of the input.

Use the window you have, keep the live set small, and let retrieval carry the scale.
