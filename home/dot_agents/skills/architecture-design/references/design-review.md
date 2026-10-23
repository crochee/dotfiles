**Load this reference when:** reviewing a design, assembling the NFR table, RPO/RTO, failure modes, capacity arithmetic or the verdict.

# Design Review

A review answers one question: will this design meet its stated requirements under the failures it will actually see? Everything below serves that question — the NFR table supplies the requirements, the failure and capacity passes supply the evidence, and the verdict says whether the evidence is sufficient.

## NFR question checklist

Ask each question and write the answer as a number with a unit. "Good performance" is not an answer; `p95 < 200 ms at 1,800 req/s` is.

| Category | Question | Record as | What an unusable answer looks like |
|---|---|---|---|
| Scale | Requests per second at peak, and the peak-to-average ratio? | `peak QPS`, `peak factor` | "high traffic" |
| Scale | Concurrent sessions and their working set? | `sessions`, `MB active per session` | "many users" |
| Scale | Data volume now, and growth per month? | `rows`, `bytes/row`, `growth/month` | "grows organically" |
| Latency | Target at which percentile, for which endpoint class? | `p50`, `p95`, `p99` per class | "fast" |
| Latency | Which dependencies sit on the synchronous path? | list with per-hop budget | "the database is fast" |
| Availability | Target as a percentage and as downtime per year? | `%`, `minutes/year` | "always up" |
| Consistency | What may a reader observe after a write? | staleness bound in seconds | "eventually consistent" |
| Durability | How much acknowledged data may be lost? | `RPO` in seconds/minutes | "no data loss" without a mechanism |
| Recovery | How long until service resumes after loss of a component or region? | `RTO` in minutes | "quickly" |
| Security | Which data classes, which identity model, which tenancy boundary? | classification, `RBAC/ABAC/ACL`, isolation unit | "secure by default" |
| Compliance | Which regimes constrain storage location and retention? | named regimes, regions, retention periods | "we are compliant" |
| Cost | Ceiling per month at current and at 10× scale? | currency/month, per-request | "whatever it takes" |
| Operability | Who is paged, with what runbook, at what hour? | on-call scope, runbook link, alert thresholds | "the team" |
| Reversibility | How is this rolled back, and how long does rollback take? | rollback procedure, `minutes` | "we can revert" |

Two habits make this table useful. First, mark each row's source: measured, contracted, assumed. Assumptions are legitimate; unlabelled assumptions are not. Second, carry the same rows into the ADR context — a reviewer should not have to ask for a number twice.

## Availability arithmetic

Availability targets are only meaningful against downtime and against the architecture that can deliver them.

| Target | Downtime per year | Downtime per month | What the architecture must have |
|---|---|---|---|
| 99% | 3.65 days | 7.3 h | Single instance, manual restart tolerated |
| 99.9% | 8.77 h | 43.8 min | Redundancy within one zone, automated failover, alerts |
| 99.95% | 4.38 h | 21.9 min | Multi-zone, rehearsed failover, no single deploy path |
| 99.99% | 52.6 min | 4.4 min | Multi-zone active-active or fast failover, tested rollback, dependency budgets |
| 99.999% | 5.26 min | 26 s | No human in the recovery loop, geo-redundancy, capacity held in reserve |

Check the target against the dependency chain. Serial dependency availability multiplies: three dependencies at 99.9% each give at best 99.7% for the composed path, before the service's own failures. If the product target is 99.95% and the synchronous path has three 99.9% dependencies, the design fails on arithmetic and no amount of retries fixes it — the options are removing a dependency from the path, adding a fallback, or lowering the target in writing.

## RPO and RTO

RPO is the amount of data loss the business accepts; RTO is the time to restore service. Both are business figures, and both imply a mechanism.

| RPO | Mechanism it implies | Test that proves it |
|---|---|---|
| 0 | Synchronous replication across failure domains, or write-ahead durability on a quorum | Kill the primary under write load; no acknowledged write is missing |
| Seconds | Asynchronous replication with a bounded lag | Measure lag at p99 under peak write load, not at idle |
| Minutes | Frequent snapshots plus continuous log shipping | Restore from the latest point and compare row counts |
| Hours | Periodic backups | Restore into a clean environment and time it |

| RTO | Mechanism it implies | Test that proves it |
|---|---|---|
| Under a minute | Automated failover with pre-warmed capacity | Fail over in a game day and time it end to end |
| Minutes | Automated failover with cold capacity | Same, including instance start and connection re-establishment |
| Hours | Documented manual runbook | A person who did not write the runbook executes it |

An RPO with no replication lag figure is a wish. An RTO with no rehearsal is a guess. Record the last test date beside both; an untested recovery path is an untested recovery path regardless of the target.

## Failure-mode pass

Walk each row against the design. The pattern catalogue supplies the mitigations; this table supplies the questions.

| Failure | What to look for in the design | A passing answer contains |
|---|---|---|
| Dependency down | Every synchronous dependency on the critical path, and its fallback | A stated degraded behaviour, a timeout shorter than the caller's, and a user-visible consequence |
| Dependency slow | Timeouts, pool exhaustion, queue growth | Timeouts below the caller's budget; a bound on in-flight requests; a load-shedding rule |
| Partial failure | Multi-step writes across services | Either compensation (saga) or a reconciliation job with a named owner and schedule |
| Retry storm | Client retry policy and its interaction with server overload | Exponential backoff with jitter, a retry budget, and a cap on attempts |
| Thundering herd | Cache expiry, scheduled jobs, mass reconnect | Jittered expiry, request coalescing, staggered schedules |
| Split brain | Any leader election or dual-write path | A quorum-based lease with a bounded term, and a defined behaviour for the minority side |
| Backpressure | Producer rate against consumer capacity | A bounded queue with a reject-or-shed policy, queue depth as an autoscaling signal |
| Cold start | Autoscaled instances, cached state, first-request latency | Warm capacity or a pre-warm hook; cold-start latency measured, not assumed |
| Poison message | Consumer retry on malformed input | Dead-letter destination, alert on depth, replay procedure |
| Clock skew | Ordering, TTLs, token expiry across hosts | Monotonic clocks for durations, a tolerance window for comparisons, NTP assumed untrusted |
| Quota and rate limits | Third-party APIs and platform limits | Known limits, a budget per caller, behaviour on 429 |
| Data corruption | Writes, migrations, replay | Idempotent writes, checksummed backups, a restore drill date |
| Deploy rollback | Schema changes, feature flags, message formats | Backward-compatible migration order, a rollback that does not need a data restore |

Every finding in this pass needs three parts to be actionable: the trigger, the observable signal that it is happening, and the mitigation. A mitigation without a detection is a hope — you will know the fix exists, not that it is needed.

## Capacity arithmetic

Compute, do not estimate. Show inputs, formula and result in the document; a reviewer must be able to change one input and re-run it mentally.

**Bandwidth.** `bytes/s = QPS × average_response_bytes`. Multiply by 8 for bits; convert with 1e6 for Mbit/s.

```text
peak 1,800 req/s × 9,216 B = 16.6 MB/s ≈ 133 Mbit/s
plus 30% headroom for retries and protocol overhead ≈ 173 Mbit/s
```

Compare with the egress limit of the instance class or load balancer, not with the average. Egress is usually the first ceiling hit by a read-heavy service.

**Storage.** `bytes = rows × row_bytes × (1 + index_fraction)`. Add indexes explicitly; a 35% index overhead is normal for relational tables with several secondary indexes.

```text
orders:     40,000,000 × 620 B × 1.35 ≈ 33.5 GB
line items: 96,000,000 × 180 B × 1.20 ≈ 20.7 GB
total ≈ 54 GB; annual growth at 60,000 orders/day ≈ 18.3 GB/year
```

**Connections.** `connections = instances × pool_size`. Compare against the server's `max_connections` minus reserved slots; if the peak exceeds it, the design needs a pooler, a smaller pool, or fewer instances with more concurrency.

```text
40 pods × 15 = 600 vs max_connections 400
→ pooler in front, or pool_size 8 with an explicit queueing budget
```

**Queue drain.** `drain_s = burst_depth / (consumers × throughput_per_consumer)`.

```text
burst 900,000 messages / (12 × 45 msg/s) = 1,667 s ≈ 28 min
```

Twenty-eight minutes of drain may be acceptable for an audit pipeline and unacceptable for payment capture. Write which one it is.

**Working set.** Cache sizing starts from the hot set, not from the table: `bytes = hot_entries × entry_bytes × overhead` with overhead around 1.2–1.5 for key and allocator cost. If the hot set does not fit, the cache hit rate is a function of the eviction policy, not of hope.

Round once, at the end, and state the rounding. Carry units in every line — the common failure is a per-second figure compared against a per-minute limit.

## Writing the verdict

Separate findings by consequence, not by taste.

| Class | Test | Consequence if ignored | Verdict effect |
|---|---|---|---|
| Blocking | The design can lose data, corrupt it, breach a compliance boundary, fail its stated NFR by arithmetic, or cannot be operated by the team that owns it | A production incident or an unmet obligation | Design does not proceed until resolved or explicitly accepted in writing by the decider |
| Advisory | The design works but a cheaper, simpler or more operable option exists; a risk is unbounded; a gap is undocumented | Waste, surprise or avoidable toil | Proceed; the finding is recorded with an owner and a date |

Severity words that keep the split honest: `blocking` needs a consequence and an evidence pointer; `advisory` needs an alternative and a reason it is better. "Should consider" with neither is noise and belongs in the meeting, not the review.

Verdict states, in order of preference:

1. **Proceed** — no blocking findings; advisory findings listed with owners.
2. **Proceed with conditions** — blocking findings exist but have accepted workarounds and owners; state the conditions as checkable facts ("the pooler is in production before the load test").
3. **Do not proceed** — at least one blocking finding has no accepted resolution. Name the smallest change that would lift it.

Close the review with the NFR table and the numbers as reviewed. A verdict without the numbers it was decided on cannot be audited later, and the next review repeats the same argument from memory.

## Review procedure

1. Read the design's stated requirements; if a number is missing, that is a finding before anything else.
2. Fill the NFR table, marking each row measured, contracted or assumed.
3. Check availability arithmetic against the dependency chain.
4. Walk the failure-mode table; record trigger, signal, mitigation per gap.
5. Recompute every capacity figure the design states. Do not accept a number you did not re-derive.
6. Read the diagrams for ownership and direction; an unowned component is a finding.
7. Sort findings blocking/advisory, assign owners, write the verdict.
8. Record what you did not review, so the next reviewer knows the edges.
