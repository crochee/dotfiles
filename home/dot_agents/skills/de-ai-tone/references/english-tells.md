**Load this reference when:** removing English LLM tells from a draft, or judging whether a flagged English hit is load-bearing.

# English tells

A tell is a sentence shape that survives translation from an outline into prose: it fills space, sounds
confident and says nothing a reader can act on. The fix is rarely a synonym. It is deletion, or a
concrete noun, or a number that was already in the source.

Each section names the detector category that flags it, so a scan hit maps to a fix.

## Hedge stacking

Hedges hide behind each other: a framing clause ("it is important to note that"), a modal ("may"),
a softener ("potentially"). Any one is survivable. Two in one sentence means the writer did not know
what the sentence claimed.

Detector: `hedge-stacking`.

| Before | After |
|---|---|
| It is important to note that the endpoint may potentially return a 429 when the bucket is empty. | The endpoint returns a 429 when the bucket is empty. |
| It should be noted that this setting might possibly affect throughput. | This setting caps throughput at 200 rps. |
| Please note that it may be worth considering whether to enable compression. | Compression is off by default; turn it on for payloads above 1 KB. |

If the uncertainty is real, keep exactly one modal and attach the condition: "Returns a 429 when the
bucket is empty; the bucket drains in about 30 s." What goes is the frame, not the uncertainty.

## Empty transitions

"Moreover", "Furthermore", "Additionally", "That said" open a paragraph and carry no relation the
reader did not already infer. They are rhythm, not argument. Delete them and check whether the
paragraph still advances; when it does not, the paragraph was padding.

Detector: `empty-transition`.

| Before | After |
|---|---|
| Moreover, the cache is cleared on deploy. | The cache is cleared on deploy. |
| Furthermore, we recommend a 30 s timeout. | A 30 s timeout covers the p99 we measured (22 s). |
| That said, the migration is reversible. | The migration is reversible: `migrate down` restores the previous schema. |

When a real contrast exists, name it: "The old queue reordered messages; this one preserves order."
The connector was standing in for a fact.

## Triadic padding

Three items is the shape a model reaches for when it has two. The third is almost always an
adjective that repeats the second, or a noun that belongs to the same marketing family. Count what
the items distinguish; if two do the work, the third is decoration.

Detector: `triadic-padding` (closed lexicon of value adjectives and manner adverbs).

| Before | After |
|---|---|
| The API is fast, reliable, and scalable. | p99 is 40 ms at 2,000 rps; adding a node is a config change. |
| We built the tool to be simple, intuitive, and easy to use. | Two commands: `init` and `deploy`. |
| The result is clearer, faster, and more maintainable code. | The diff removes 300 lines and one layer of indirection. |

A three-item list of real, distinct things — three statuses, three regions, three error codes —
is not padding. The tell is three synonyms.

## "Not just X but Y"

The construction promises a second, larger claim. It usually delivers a restatement plus an
adjective. It is load-bearing only when X is the alternative you rejected and Y is the thing you
actually did.

Detector: `not-just-x`.

| Before | After |
|---|---|
| This isn't just a cache, it's a performance strategy. | The cache absorbs 90% of reads; Postgres handles the rest. |
| We're not just fixing a bug, we're raising the bar. | The fix removes the retry storm behind the 14:20 outage. |
| It's not just a formatter but also a type checker. | It formats and type-checks; both run in CI. |

The third pair keeps the construction's content while dropping the crescendo. If you keep the
sentence, keep it flat.

## Meta-narration

"In this section we will explore", "let's dive in", "by the end of this article" describe the
document instead of doing its job. The reader already knows they are reading. Open with the first
fact, and the section starts one paragraph earlier.

Detector: `meta-narration`.

| Before | After |
|---|---|
| In this section, we will explore how retries work. | A failed batch is retried three times (2 s, 8 s, 32 s), then parked. |
| Let's dive into the configuration. | `retry.max` sets the attempt count; the default is 3. |
| By the end of this article you'll understand sharding. | Sharding splits a table by tenant id; the router reads the id from the token. |

A cross-reference that helps navigation — "see the migration notes in `docs/upgrade.md`" — is not
meta-narration. The difference is whether the sentence points at content or performs content.

## Empty summary paragraphs

A closing paragraph that restates the heading, or opens with "In conclusion", adds no decision and
no next action. Summaries earn their place by naming what changed and what to do about it.

Detector: `empty-summary`.

| Before | After |
|---|---|
| In conclusion, retries improve reliability. | Retries cut failed ingestions from 4,100 to 90 a day. |
| The key takeaway is that observability matters. | Queue depth is the metric that paged us at 14:20; it is now on the dashboard. |
| `## Deployment` — This section covers deployment. | `## Deployment` — then straight to the command. |

## Translated and corporate diction

Two vocabularies arrive together: calques from another language ("in today's fast-paced landscape",
"delve into") and management English ("leverage", "seamless", "robust solution", "synergy"). Both
replace a verb the domain already has with a word that signals effort instead of describing work.

Detectors: `translated-diction`, `corporate-jargon`.

| Before | After |
|---|---|
| We leverage a queue to unlock the power of asynchronous processing. | A queue keeps the request path at 40 ms; the writer drains it in batches. |
| The seamless integration lets you delve into your data. | `import ingest` gives you `ingest.batch(path)`. |
| In today's fast-paced landscape, teams need observability. | The 14:20 outage took 40 minutes to diagnose because nobody could see queue depth. |
| Let's circle back on the value-add. | We still owe a retention window; 30 days is the proposal. |
| Our cutting-edge, best-in-class pipeline processes events. | The pipeline handles 1,200 jobs an hour on four nodes. |

`leverage` is legitimate as a noun in finance ("the fund's leverage is 3:1"). `robust` is legitimate
in statistics. The tell is the verb form used where "use" or "call" would be exact, and the
adjective used where a number belongs.

## Em-dash chains

One em dash is punctuation. Three in a sentence is a rhythm tic: each dash invites an aside, and the
sentence stops having a spine. Split it, or make the asides a list.

Detector: `emdash-chain` (three or more on one line).

| Before | After |
|---|---|
| The tool is fast — really fast — faster than the old one — and simpler. | The tool is faster than the old one and 300 lines smaller. |
| Deploys are safe — tested — reversible — and fast. | Deploys are tested and reversible; a rollback takes 40 s. |
| We chose Postgres — not MySQL — because — you know. | We chose Postgres for JSONB indexing; MySQL 8 is slower on our query. |

## Uniform sentence length

Generated prose tends to land every sentence between 18 and 25 words. The paragraph reads smoothly
and carries no emphasis, because emphasis comes from contrast. The fix is not shorter sentences
throughout; it is one short sentence where the verdict is.

No detector: this is a measurement, not a phrase. Count words per sentence; if the spread is under
about 8 words, vary it.

| Before | After |
|---|---|
| The service accepts requests and places each batch on a queue where it waits for the writer to drain it into the warehouse at a steady rate. | Requests go onto a queue. The writer drains it at 1,200 batches an hour, which keeps the request path at 40 ms even during the Monday spike. |
| Retries are configured per connector and the defaults are chosen to cover the latency of most upstream providers in production. | Retries are per connector. Defaults: three attempts, 2/8/32 s, which covers the p99 of every provider we use. |
| The dashboard shows queue depth and it also shows the age of the oldest message in the queue so that operators can decide. | The dashboard shows queue depth and the age of the oldest message. Both page someone at 14:20. |

## Over-bolding

Bold is a pointer: it says "this is the term you will need again". A line with three bold spans
points at everything, which is the same as pointing at nothing.

Detector: `over-bold` (three or more spans on one line).

| Before | After |
|---|---|
| **Fast:** 40 ms. **Cheap:** $0.02. **Simple:** one file. | 40 ms p99, $0.02 per 1,000 requests, one file. |
| **Key insight:** **The** queue **is** the bottleneck. | The queue is the bottleneck. |
| **Note:** **always** run **the migrator** before **deploying**. | Run the migrator before deploying. |

## Emoji bullets and list-itis

An emoji carries no information the sentence lacks, and it marks the list as generated. The same
applies to bullets that should be a sentence: when the relation between items matters (cause,
sequence, exception), a list destroys it.

Detector: `emoji-bullet`. List-itis is a judgement call; no detector.

| Before | After |
|---|---|
| - 🚀 **Speed** — 40 ms | - p99 40 ms |
| ✅ Done ✅ Reviewed ✅ Shipped | Done, reviewed and shipped; the tag is `v2.3.0`. |
| - **Cause:** pool exhaustion<br>- **Effect:** 14:20 outage<br>- **Fix:** raise `max_conn` | The pool ran out of connections at 14:20; raising `max_conn` to 40 fixed it. |

A bullet list is right when the items are parallel and order-free: flags, endpoints, error codes.
It is wrong when the items are a sentence split at its commas.
