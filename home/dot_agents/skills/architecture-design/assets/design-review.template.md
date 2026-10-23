# Design review: {{system or change}}

- Date: {{YYYY-MM-DD}}
- Reviewer: {{name}}
- Design under review: {{ADR-NNNN | doc path | commit}}
- Scope reviewed: {{components, paths, environments}}
- Not reviewed: {{explicitly out of scope — so the next reviewer knows the edges}}

## 1. Requirements as reviewed

<!-- Copy the design's own numbers. Mark each row measured, contracted or assumed. A missing number
     is a finding, not a gap to fill by guessing. -->

| Category | Requirement | Source |
|---|---|---|
| Peak throughput | {{N req/s, peak factor N×}} | {{load test path / contract}} |
| Latency | {{p50 / p95 / p99 per endpoint class}} | {{SLO doc}} |
| Availability | {{99.9% = 8.77 h/year}} | {{product requirement}} |
| Consistency | {{staleness bound in seconds}} | {{ADR-NNNN}} |
| RPO | {{seconds / minutes}} | {{business owner}} |
| RTO | {{minutes}} | {{business owner}} |
| Cost ceiling | {{currency/month at current and 10×}} | {{budget}} |
| Compliance | {{regimes, regions, retention}} | {{legal}} |
| Operability | {{on-call scope, runbook, alert thresholds}} | {{team}} |

## 2. Availability arithmetic

<!-- Serial dependencies multiply. Show the chain and the composed figure, then compare with the
     target. A composed figure below the target is a blocking finding unless the target changes. -->

| Path | Dependencies (in series) | Composed availability | Target | Gap |
|---|---|---|---|---|
| {{critical path}} | {{a, b, c}} | {{0.999^3 = 99.7%}} | {{99.95%}} | {{blocking}} |

- Last failover drill: {{date, result}}
- Last restore drill: {{date, result, duration}}

## 3. Failure modes

<!-- Trigger, observable signal, mitigation. A mitigation with no detection is a hope. -->

| Failure | Trigger | Detection signal | Mitigation | Gap |
|---|---|---|---|---|
| Dependency down | {{...}} | {{alert, metric}} | {{degraded behaviour}} | {{none / blocking}} |
| Dependency slow | {{...}} | {{timeout rate, pool saturation}} | {{timeout, shed}} | {{...}} |
| Partial failure | {{...}} | {{reconciliation job output}} | {{compensation}} | {{...}} |
| Retry storm | {{...}} | {{attempts per request}} | {{backoff with jitter, budget}} | {{...}} |
| Thundering herd | {{...}} | {{reconnect spike, cache miss rate}} | {{jitter, coalescing}} | {{...}} |
| Split brain | {{...}} | {{dual leadership, write conflicts}} | {{quorum lease}} | {{...}} |
| Backpressure | {{...}} | {{queue depth, oldest age}} | {{bounded queue, shed policy}} | {{...}} |
| Cold start | {{...}} | {{first-request latency}} | {{warm capacity}} | {{...}} |
| Poison message | {{...}} | {{dead-letter depth}} | {{DLQ, replay procedure}} | {{...}} |
| Clock skew | {{...}} | {{ordering inversions, TTL misses}} | {{monotonic clocks, tolerance}} | {{...}} |
| Data corruption | {{...}} | {{checksum, restore test}} | {{idempotent writes, drills}} | {{...}} |
| Deploy rollback | {{...}} | {{canary error rate}} | {{compatible migration order}} | {{...}} |

## 4. Capacity numbers

<!-- Re-derive every figure the design states. Show inputs, formula and result so a reader can
     change one input and re-check. Carry units on every line. -->

| Quantity | Inputs | Formula | Result |
|---|---|---|---|
| Egress bandwidth | {{1,800 req/s, 9,216 B/response}} | {{QPS × bytes × 8}} | {{133 Mbit/s; 173 Mbit/s at 30% headroom}} |
| Storage | {{40M rows × 620 B, 35% indexes}} | {{rows × row_bytes × (1+index)}} | {{33.5 GB}} |
| Annual growth | {{60,000 rows/day}} | {{rows/day × row_bytes × 365}} | {{18.3 GB/year}} |
| Connections | {{40 pods × pool 15}} | {{instances × pool}} | {{600 vs max_connections 400}} |
| Queue drain | {{900k backlog, 12 consumers × 45/s}} | {{depth / throughput}} | {{1,667 s ≈ 28 min}} |
| Cache | {{hot set 2M × 3 KB}} | {{entries × bytes × 1.3}} | {{7.8 GB}} |

## 5. Findings

<!-- Blocking: data loss, corruption, compliance breach, an NFR missed by arithmetic, or a design
     the owning team cannot operate. Advisory: a cheaper or simpler option, an unbounded risk, an
     undocumented gap. Every finding carries evidence and an owner. -->

### Blocking

| # | Finding | Evidence | Required change | Owner |
|---|---|---|---|---|
| B1 | {{...}} | {{path:line / measurement / arithmetic}} | {{smallest change that lifts it}} | {{name}} |

### Advisory

| # | Finding | Evidence | Recommendation | Owner |
|---|---|---|---|---|
| A1 | {{...}} | {{path:line / measurement}} | {{alternative and why it is better}} | {{name}} |

## 6. Verdict

{{proceed | proceed with conditions | do not proceed}}

- Conditions (if any), stated as checkable facts: {{"the pooler is in production before the load test"}}
- Blocking findings with an accepted workaround, and who accepted it: {{...}}
- Advisory findings to be tracked, with tickets: {{...}}
- Date of next review, or the trigger that forces one: {{...}}
