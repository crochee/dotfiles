# Patterns F — Writing for the wrong reader

F1 Re-explaining what the reader knows

**Load this reference when:** rewriting a reply, a review comment, or a message in a thread where the reader already has the context.

A model writes for a reader who shares no context, because that fits the widest range of cases. A
reply in a thread has a reader who already knows the background, and the gap between those two
readers is what this group is about. It holds one pattern, and it is the only pattern in the skill
with no detector: the evidence sits in the conversation around the text, not in the words of it.

### F1. Re-explaining what the reader knows / 重复读者已知

**Strength:** act on one sighting — but only once the reader's context is visible.
**Watch for:** a short reply that restates the problem, walks through the diagnosis, and lays out the evidence before it reaches the decision; a query, command, or set of numbers included to prove a plan will work; background the other person wrote or already agreed to; the answer itself sitting in the last line; 先把问题再说一遍; 再走一遍诊断; 把证据摊开来说; 结论放在最后一句.

**Problem:** In a reply the reader already has the context, so rebuilding it adds nothing and buries
the point. Each sentence reads fine on its own, so the pattern survives sentence-level cleanup and
no scanner can flag it; only the surrounding conversation reveals it. Act when you can see that
conversation, or when the text plainly is a reply; if you cannot tell, ask or leave the text alone.

**Before:**
> Yeah, you're right, this works around the issue rather than fixing it. The real fix is in
> `MergeService`: when we move a child under a new parent, it should update `pipeline_id` along with
> `parent_id`. We can backfill the bad rows from the audit log with
> `Change.where(field: "pipeline_id", source: "merge")`. I checked QA: 123 past merges, only 6 rows
> wrong now, so the cleanup is small.
>
> Since `MergeService` is shared and not specific to this account, I'd rather open a separate ticket
> than widen this PR. The fallback here is fine to keep until then.

**After:**
> Agreed, this is a workaround. Fixing it properly in `MergeService` would widen this ticket well past
> its scope: it is shared code, so it means checking the merge flow for every account, plus a backfill
> for the rows that are already wrong.
>
> I'd rather keep this PR account specific and open a separate ticket for the `MergeService` fix and
> the backfill. Let me know if that works.

**Before (a query used as proof):**
> The cache rewrite should be safe. I ran `ab -n 2000 -c 50 http://localhost:8080/cache` and it gave
> p99 of 240 ms before the change and 80 ms after, and the hit rate went from 0.41 to 0.93 over 30
> minutes of replayed traffic. The old key path stays for one release, so both paths can run side by
> side.

**After:**
> The cache rewrite is safe to ship: the same replay gives p99 of 240 ms before and 80 ms after, and
> the hit rate goes from 0.41 to 0.93. The old key path stays for one release, so both paths run side
> by side.

**Before (background the reader already has):**
> As discussed on Tuesday, the auth service rotates session tokens every 24 hours, in place, and
> clients refresh transparently. We agreed not to restart the service on a cron job, because that
> would drop every active session. The billing service also rotates credentials nightly, so I would
> leave its current implementation alone for the same reason.

**After:**
> The auth service rotates session tokens in place, so restarting it on a cron job would drop every
> active session. Billing rotates credentials nightly on the same model, so I'd leave that
> implementation alone too.

**Before (the answer sits in the last line):**
> The release failed at the migration step. The `accounts` table has 4.2 million rows, and the
> migration adds a non-null `pipeline_id` column without a default. The migration took 90 seconds on
> the staging copy, which holds 12,000 rows. Postgres 14 avoids a table rewrite for a column with a
> constant default, but a subquery default is not constant. The fix is to add the column as nullable,
> backfill it in batches, and then set `NOT NULL`.

**After:**
> The release failed at the migration: adding a non-null `pipeline_id` column without a default
> rewrites 4.2 million rows, and Postgres 14 only skips the rewrite for a constant default. Add the
> column as nullable, backfill it in batches, then set `NOT NULL`.

**Before (a review comment):**
> The reviewer noted that the new endpoint should validate the tenant id. The tenant id is set by the
> gateway and stored on the `Account` row, so validating it in the handler costs a database lookup on
> every request. The check belongs in the gateway, where the tenant id is already resolved, and the
> handler only needs to assert that the id is present. There is also the open question of what should
> happen to requests that carry no tenant id at all, which currently fall through to the default
> tenant.

**After:**
> The tenant id check belongs in the gateway, where the id is already resolved; the handler only needs
> to assert that it is present. Requests with no tenant id currently fall through to the default
> tenant, so that case still needs a decision.

**Before (a reply that repeats the document it points to):**
> The incident review is in `docs/incident-2026-03-11.md`. The write-up covers the timeline, the root
> cause and the follow-up actions, and it explains why cache invalidation was skipped during the
> deploy. Since the report already lists every action item, we can use it as the tracker instead of
> opening a separate ticket.

**After:**
> The incident review is in `docs/incident-2026-03-11.md`. It already lists the follow-up actions, so
> we can use it as the tracker instead of opening a separate ticket.

**Before (a short chat reply):**
> Just to confirm the thing we were discussing: the release should run the migration before the
> deploy, and we split it into two steps because the migration is not backward compatible with the
> old code. The first step adds the column as nullable and the second sets it to `NOT NULL` once
> every reader of that column has shipped.

**After:**
> Two steps, as we discussed: the migration adds the column as nullable, and a later release sets it
> to `NOT NULL` once every reader of that column has shipped.

**Before (a reply that repeats the release note the reader just read):**
> The v2.3.0 release note covers the cache key format change, adds the `v2:` prefix, and says that old
> keys stay valid for 30 days. The change goes with the new `CacheReader` version, and the README is
> already updated. So the upgrade document does not need to repeat it.

**After:**
> The v2.3.0 release note covers the `v2:` prefix and the 30-day grace period for old keys, and the
> README is updated, so the upgrade document does not need to repeat it.

**Before (the problem restated before the answer):**
> Got it, I read your question as whether a staged rollout can be rolled back midway. A staged rollout
> sends part of the traffic, watches the metrics, and then decides to widen or stop. Rolling back
> midway is supported in this design, because every step records a batch number, and a rollback stops
> the current batch and replays the previous one.

**After:**
> Yes, it can be rolled back: every step records a batch number, and a rollback stops the current batch
> and replays the previous one.

**Action:** playbook move 1 — Delete the sentence
**Detector:** No detector — judge by reading.

## When not to act

- Act only when the reader's context is visible: the thread, the ticket, or the earlier message. If
  you cannot tell whether the text is a reply, ask or leave the text alone.
- Do not strip background from a document that will be read cold by someone who does not have it.
  Standalone documents still need their context; F1 applies to replies.
- A long reply to a long message is not this pattern. Length follows the thread; the only tell is
  the restatement the reader already has.
- A fact the reader does not have is not re-explanation. Keep the one fact that would change whether
  the reader agrees, and the link they need to act.
- A reviewer raising a topic is not a request for the full write-up. The diagnosis and the proof
  belong in the ticket or document that follows.
- Quoted material keeps its original context. Leave it alone and record the decision instead of
  editing the quote.
