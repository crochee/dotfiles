# Rewrite playbook

**Load this reference when:** turning scan hits into a rewrite, or deciding whether a flagged sentence should be deleted, reworded or left alone.

Eight moves, ordered by payoff. Work down the list: apply move 1 everywhere it works, then move 2,
and so on. The order matters because deletion removes more slop than any rewrite and cannot
introduce an error, while later moves edit sentences and can.

Each move names the pattern numbers it serves. A hit may need a move whose numbers do not list it;
the number points to the section of `references/patterns-*.md` holding that pattern's watch-for list.

Contents: 1 Delete the sentence · 2 Cut the hedge · 3 Split the long sentence · 4 Concrete noun ·
5 Active voice · 6 Number next to the claim · 7 Three items to two · 8 Logical relation ·
Technical precision beats style · Worked example · Order of operations · When not to act

## Which group a hit belongs to, and the first move for it

| Group | What the hits look like | First move |
|---|---|---|
| A — Staging | The sentence signals importance instead of adding a fact: contrasts, closers, run-ups, self-answered questions | Delete it (§A2, §A4, §A5, §A6, §A7, §A8); state the point (§A1, §A3, §A9) |
| B — Rhythm | The shape repeats by rule: triads, dashes, hedges, stacked modifiers, parallel openings | Vary the shape: two items not three (§B1), one hedge not four (§B4), split the sentence (§B2, §B7, §B8), name the actor (§B6) |
| C — Inflation | An ordinary fact is dressed as a turning point, expert-backed or universally significant | Keep the fact, drop the dressing (§C1–§C5); name the source or cut it (§C6); use *is*, *are*, *has* (§C7); end on the last concrete fact (§C8, §C10) |
| D — Formatting | Decoration on every item: bold labels, emoji, title case, curly quotes, half-width punctuation in Chinese | Strip the decoration; one bold per section at most (§D1–§D5) |
| E — Leftovers | Chat wrappers, knowledge disclaimers, a heading restated, narration about the document | Delete the wrapper and keep the content (§E1–§E5) |
| F — Wrong reader | A reply rebuilds context the reader already has | Lead with the decision (§F1) |

## 1. Delete the sentence

**Serves:** A2, A4, A5, A6, A7, A8, A9, D1, D3, E1, E2, E3, E4, E5, F1

Also covers the mechanical deletions: D1 (bold used as decoration) and D3 (emoji, decorative headings).

Most hits are sentences that exist to connect other sentences. Delete the sentence, reread the
paragraph, and check that the argument still holds. If it does, the sentence was scaffolding.

Delete: "In this section we will…", "It is important to note that…", "In conclusion, …", the
paragraph that restates its own heading, "让我们一起……".

Do not delete a sentence that carries the only statement of a fact, a constraint or a decision. When
unsure, delete and paste it into the change log; you can put it back with a reason.

## 2. Cut the hedge to the one real uncertainty

**Serves:** B4

A hedge stack contains at most one real uncertainty. Find it, keep it, delete the rest. If no
uncertainty survives, the sentence is an assertion and should read like one.

| Before | After |
|---|---|
| The migration may potentially take longer than expected. | The migration takes 12 minutes on the staging dataset; we have not timed production. |
| This could possibly affect latency under some conditions. | Above 2,000 concurrent connections, p99 rises to 300 ms. |

When the uncertainty is real but unnamed, name the gap instead of hedging: "We have not tested this
above 5,000 rps." That sentence tells the reader more than four hedges did.

## 3. Split the long sentence

**Serves:** B2, B3, B5, B7, B8, B10, D2, D4, D5

Also covers the mechanical formatting fixes: D2 (turn a labelled list back into prose), D4 (normalise curly quotes), D5 (Chinese punctuation and CJK spacing).

Past about 35 words a sentence stops being parsed and starts being skimmed. Split at the clause
boundary where the subject changes, then decide which half carries the claim and make that one
short.

| Before | After |
|---|---|
| The worker reads each batch from the queue and writes it to the warehouse while retrying transient failures with exponential backoff and recording the final error in a dead-letter table for later inspection. | The worker reads a batch, writes it to the warehouse and retries transient failures with exponential backoff. A batch that fails three times goes to the dead-letter table. |

Splitting also makes the second half available for deletion — which is how moves 1 and 3 cooperate.

## 4. Replace the abstraction with the concrete noun

**Serves:** A3, B9, B13, C1, C3, C5, C9

"Solution", "platform", "capability", "approach", "生态", "体系" are containers. Replace with the
thing inside: the binary, the table, the cron job, the function. If no concrete noun comes to mind,
the writer did not know what the sentence was about.

| Before | After |
|---|---|
| The platform delivers a robust solution for data movement. | `sync` copies changed rows every 5 minutes; it reads `updated_at` and writes in 1,000-row batches. |
| 这套体系支撑了业务的快速发展。 | 这套调度器每周跑 4,200 个任务，失败率 0.3%。 |

## 5. Convert passive to the actor

**Serves:** B6, C7

Passive is right when the actor is unknown or irrelevant ("the table is truncated nightly"). It is a
tell when the actor is the point and has been removed to sound neutral.

| Before | After |
|---|---|
| It was decided that retries would be capped at three. | We capped retries at three because the upstream clears transient faults in 30 s. |
| 相关配置已被调整。 | 我们把 `max_conn` 从 10 调到 40。 |

Ask who did it. If the answer is "nobody knows", say that: "Something lowers the cap; the cause is
unknown."

## 6. Move the number next to the claim

**Serves:** B1, C2, C10

Adjectives beg for evidence. When the document already contains the measurement, put it in the same
sentence as the claim it supports. This is a move, not an addition — the number must already exist
in the source.

| Before | After |
|---|---|
| The service is highly available. | The service has been up 99.98% over 90 days (12 minutes down in March). |
| 性能提升明显。 | p99 从 240 毫秒降到 80 毫秒。 |

Never invent the number. If the source has the claim and not the measurement, the rewrite says so:
"Availability is 99.98% (measured; see `ops/status.md`)" or "we have not measured availability".

## 7. Collapse a three-item list to the two that mean something

**Serves:** A1, B1, B11, B12, B14

Rank the items. If two carry different information and the third repeats, delete the third. If all
three are distinct, keep all three and say why in the log — a real triad is not padding.

| Before | After |
|---|---|
| Fast, scalable, and reliable. | 40 ms p99; adding a node is a config change. |
| 高效、稳定、可靠。 | 构建 6 秒，连续 90 天没有失败。 |

The same test applies to the "not just X but Y" construction: if Y restates X, keep X alone.

## 8. Replace the connective with the logical relation

**Serves:** A4, C8

"Moreover", "总的来说", "综上所述" state that something follows without saying how. Replace with
the relation the reader needs: cause, contrast, sequence, exception. If no relation exists, the
sentence is a list item, not a step in an argument.

| Before | After |
|---|---|
| 总的来说，这个方案更适合小团队。 | 三个人以下的团队用这个方案，因为它不需要专职运维。 |
| Moreover, the cache is cleared on deploy. | The cache is cleared on deploy, so the first request after a release is slow. |

Cause: because, so, which means. Contrast: but, unlike, where the old one. Sequence: first, then,
after. Exception: unless, except when, except for.

## Technical precision beats style

The rule that outranks every move above: **if a rewrite loses a fact, keep the original and log it.**
A document that scores zero and states a different system is worse than one that scores three and
states the right one.

Cases where you keep the awkward sentence:

- **Unknown quantities.** "May fail under load" is vague, but the tested range is unknown. Rewrite
  to name the gap; do not delete the caveat.
- **Qualifiers with legal or safety weight.** "Must not be used above 85 °C" keeps its modal.
- **Error strings, log lines and API names.** Reproduce them byte for byte; they are data, not prose.
- **Quoted material.** A quoted bad example stays bad. Suppress the line with a marker instead of
  editing the quote.
- **Enumeration that is genuinely three items.** No collapse.

The marker takes either the category token or the pattern number, and markers written before v2
keep working:

```html
<!-- scan: ignore not-just-x the contrast is the design decision -->
<!-- scan: ignore A1 the contrast is the design decision -->
```

When a hit survives because of this rule, record it: the before-after table's `Reason` column says
why, and `Precision kept?` says `yes — modal retained` or similar. A surviving hit with a reason is
a correct outcome; a surviving hit with no reason is unfinished work.

## Worked example

Before:

> In today's fast-paced landscape, teams must leverage observability to unlock the power of their
> data. Moreover, it is important to note that our platform may potentially reduce diagnosis time by
> up to 80% — reliably — at scale — across every environment. It's not just a dashboard, it's a new
> way of working.

After:

> Diagnosis takes 40 minutes today because nobody can see queue depth. Our platform adds that metric
> and three others to the dashboard you already run, which cut the last two incidents to 12 minutes.

Moves used: 1 (delete the frame), 8 (replace "Moreover" with the cause), 2 (cut "may potentially"
for the measured 12 minutes), 7 (drop "reliably, at scale, across every environment"), 6 (put 40
and 12 next to the claim), 4 ("platform" kept only where it names a thing the reader installs).

What did not change: the 80% figure. The source measured two incidents, so the rewrite states the
incident duration instead of generalising a percentage — if the 80% came from a benchmark, the
rewrite would keep it and say where it came from.

## Order of operations

1. Scan and save the baseline output.
2. Apply moves 1–8 in order across the whole document.
3. Rescan. Apply the precision rule to every remaining hit and log the reason.
4. Diff the numbers: every figure, date, identifier and proper noun in the rewrite appears in the
   original, and vice versa.

## When not to act

Each pattern is a default choice, and a person can make it on purpose.

- Leave a watched phrase alone inside a quotation, a title, a proper name, or a passage that
  discusses the phrase rather than uses it.
- Salutations and sign-offs on a letter or a comment predate chatbots.
- Text written before November 30, 2022 is not AI-written.
- People who judge by feel do little better than chance, and human writing keeps absorbing AI habits,
  so several tells together are the safeguard.
- Keep the details that carry the writer's voice unless they hurt the meaning:
  - A specific, unusual detail: a real address, an odd quote, "the lawyer who used to work upstairs
    from my dentist."
  - Mixed feelings and unresolved tension: "mostly good, but it bothers me, and I can't explain why."
  - Dated, era-bound references: slang, memes and in-jokes that map to a specific year and subculture.
  - A first-person choice the writer can explain.
  - A genuine aside or self-correction: "(I keep wanting to say 'almost' here, but it was certain.)"

Rules for the Chinese cases that are easiest to over-correct:

- Idioms and elevated diction — "事半功倍", "未雨绸缪", "行云流水" — are register, not AI vocabulary.
- An isolated transition word is a connective; only a mechanical repeat at every paragraph opening is
  a tell.
- Necessary passive and standard phrasing in technical or academic writing: "实验数据由传感器自动记录".
- A necessary list — an API parameter table, an action-item list — is already the clearest form.
- Deliberate rhetorical parallelism keeps the author's voice.
