**Load this reference when:** turning scan hits into a rewrite, or deciding whether a flagged sentence should be deleted, reworded or left alone.

# Rewrite playbook

Eight moves, ordered by payoff. Work down the list: apply move 1 everywhere it works, then move 2,
and so on. The order matters because deletion removes more slop than any rewrite and cannot
introduce an error, while later moves edit sentences and can.

## 1. Delete the sentence

Most hits are sentences that exist to connect other sentences. Delete the sentence, reread the
paragraph, and check that the argument still holds. If it does, the sentence was scaffolding.

Delete: "In this section we will…", "It is important to note that…", "In conclusion, …", the
paragraph that restates its own heading, "让我们一起……".

Do not delete a sentence that carries the only statement of a fact, a constraint or a decision. When
unsure, delete and paste it into the change log; you can put it back with a reason.

## 2. Cut the hedge to the one real uncertainty

A hedge stack contains at most one real uncertainty. Find it, keep it, delete the rest. If no
uncertainty survives, the sentence is an assertion and should read like one.

| Before | After |
|---|---|
| The migration may potentially take longer than expected. | The migration takes 12 minutes on the staging dataset; we have not timed production. |
| This could possibly affect latency under some conditions. | Above 2,000 concurrent connections, p99 rises to 300 ms. |

When the uncertainty is real but unnamed, name the gap instead of hedging: "We have not tested this
above 5,000 rps." That sentence tells the reader more than four hedges did.

## 3. Split the long sentence

Past about 35 words a sentence stops being parsed and starts being skimmed. Split at the clause
boundary where the subject changes, then decide which half carries the claim and make that one
short.

| Before | After |
|---|---|
| The worker reads each batch from the queue and writes it to the warehouse while retrying transient failures with exponential backoff and recording the final error in a dead-letter table for later inspection. | The worker reads a batch, writes it to the warehouse and retries transient failures with exponential backoff. A batch that fails three times goes to the dead-letter table. |

Splitting also makes the second half available for deletion — which is how moves 1 and 3 cooperate.

## 4. Replace the abstraction with the concrete noun

"Solution", "platform", "capability", "approach", "生态", "体系" are containers. Replace with the
thing inside: the binary, the table, the cron job, the function. If no concrete noun comes to mind,
the writer did not know what the sentence was about.

| Before | After |
|---|---|
| The platform delivers a robust solution for data movement. | `sync` copies changed rows every 5 minutes; it reads `updated_at` and writes in 1,000-row batches. |
| 这套体系支撑了业务的快速发展。 | 这套调度器每周跑 4,200 个任务，失败率 0.3%。 |

## 5. Convert passive to the actor

Passive is right when the actor is unknown or irrelevant ("the table is truncated nightly"). It is a
tell when the actor is the point and has been removed to sound neutral.

| Before | After |
|---|---|
| It was decided that retries would be capped at three. | We capped retries at three because the upstream clears transient faults in 30 s. |
| 相关配置已被调整。 | 我们把 `max_conn` 从 10 调到 40。 |

Ask who did it. If the answer is "nobody knows", say that: "Something lowers the cap; the cause is
unknown."

## 6. Move the number next to the claim

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

Rank the items. If two carry different information and the third repeats, delete the third. If all
three are distinct, keep all three and say why in the log — a real triad is not padding.

| Before | After |
|---|---|
| Fast, scalable, and reliable. | 40 ms p99; adding a node is a config change. |
| 高效、稳定、可靠。 | 构建 6 秒，连续 90 天没有失败。 |

The same test applies to the "not just X but Y" construction: if Y restates X, keep X alone.

## 8. Replace the connective with the logical relation

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
- **Quoted material.** A quoted bad example stays bad. Mark the line `scan: ignore` with a reason
  instead of editing the quote.
- **Enumeration that is genuinely three items.** No collapse.

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
and replace it with the measured 12 minutes), 7 (drop "reliably, at scale, across every
environment"), 6 (put 40 and 12 next to the claim), 4 ("platform" kept only where it names a thing
the reader installs).

What did not change: the 80% figure. The source measured two incidents, so the rewrite states the
incident duration instead of generalising a percentage — if the 80% came from a benchmark, the
rewrite would keep it and say where it came from.

## Order of operations

1. Scan and save the baseline output.
2. Apply moves 1–8 in order across the whole document.
3. Rescan. Apply the precision rule to every remaining hit and log the reason.
4. Diff the numbers: every figure, date, identifier and proper noun in the rewrite appears in the
   original, and vice versa.
