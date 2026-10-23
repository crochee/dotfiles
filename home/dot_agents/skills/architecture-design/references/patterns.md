**Load this reference when:** selecting a distributed-system pattern, or defending one that is already in the design.

# Distributed-System Patterns

A pattern is a named response to a force. The name is the least useful part: it compresses an argument, and once the name is in a design it tends to survive longer than the argument did. Each entry below therefore carries the force, the mechanism, the condition under which the pattern costs more than it saves, and the failure mode the pattern itself introduces.

## Contents

- Selection order
- Resilience and failure containment
- Read and write scaling
- Messaging and integration
- Boundaries and frontends
- Deployment and operations
- Security
- Events
- Combinations that work and combinations that fight
- Measuring that a pattern works

## Selection order

1. State the force in one sentence, with a number where one exists. "Writes spike to 9× average for 90 seconds at month end" is a force; "we need resilience" is not.
2. Pick the family from the force, not from a pattern you liked in another system.
3. Read the cost line before the mechanism line. A pattern whose cost line matches your constraints is the wrong pattern, however well it fits the mechanism.
4. If the cost line wins, remove the force instead — reduce the dependency, bound the payload, delay the requirement — and stop.
5. Write into the ADR: the force, the pattern, the cost you accepted, and the metric you will watch to know you were wrong.

## Resilience and failure containment

The forces here are failures of components you do not control, and the risk that one failure takes the product with it.

**Bulkhead**
- *Force:* one dependency's slowness consumes a shared pool and starves unrelated work.
- *Mechanism:* partition pools, thread budgets and instance counts by criticality so each class of work has its own capacity. Saturation in one partition then degrades only its own callers.
- *Costs more than it saves when:* traffic is low enough that a single pool never saturates, or the partition multiplier exceeds the capacity you actually have.
- *Its own failure mode:* idle capacity in one bulkhead while another queues, so the system looks under-provisioned and the obvious fix is to merge the pools back.

**Circuit breaker**
- *Force:* calls to a failing dependency block until timeout, and the blocked callers cascade.
- *Mechanism:* a state machine per dependency — closed, open, half-open — trips after a failure threshold, fails fast while open, and admits a trial request to close. The fallback is part of the design, not an afterthought.
- *Costs more than it saves when:* the dependency fails slowly rather than fast, or the fallback is as expensive as the call it replaces.
- *Its own failure mode:* one breaker for a shared dependency trips on a single tenant's errors and removes the dependency for everyone; half-open probes re-admit full load before recovery.

**Retry**
- *Force:* transient faults — dropped connections, brief unavailability — are common and self-healing.
- *Mechanism:* reissue a failed operation with exponential backoff, jitter and a bounded attempt count, and only for errors classified as transient. The caller's total budget, not the per-attempt timeout, sets the ceiling.
- *Costs more than it saves when:* the operation is not idempotent, or the failure is saturation rather than transience — retrying a saturated service is adding load.
- *Its own failure mode:* retries multiply into a storm synchronised by identical backoff schedules, turning a brief blip into a sustained overload; a retry inside a retry multiplies the budget by the product of both.

**Health endpoint monitoring**
- *Force:* an orchestrator, load balancer or on-call needs to know whether an instance can serve traffic.
- *Mechanism:* expose separate liveness and readiness checks; liveness answers "is the process wedged", readiness answers "should this instance receive traffic". Readiness checks the dependencies the instance needs, with a timeout shorter than the probe interval.
- *Costs more than it saves when:* readiness checks a dependency that every instance shares, so a dependency blip removes the entire fleet at once.
- *Its own failure mode:* a readiness probe that fails during normal startup causes restart loops; a liveness probe that checks dependencies restarts healthy instances because a peer is down.

**Leader election**
- *Force:* exactly one instance may perform a task — a schema migration, a partition assignment, a scheduled sweep.
- *Mechanism:* a lease held in a consistent store with a bounded term and a heartbeat. The holder renews; on expiry another contender acquires; the old holder must stop before its term would have expired locally.
- *Costs more than it saves when:* the work is idempotent and safe to run concurrently, in which case the election is a coordination cost for nothing.
- *Its own failure mode:* split brain when a paused leader resumes after losing its lease; work duplicated in the overlap, or worse, two writers to one resource.

**Ambassador**
- *Force:* a service needs connectivity behaviour — retries, auth, routing, observability — that it should not implement itself, often because it is legacy or polyglot.
- *Mechanism:* a helper process beside the service proxies its outbound calls and applies the shared policy. The service keeps talking to localhost; the policy lives in one place.
- *Costs more than it saves when:* the service can be changed directly, since an in-process client library has fewer moving parts and one less hop.
- *Its own failure mode:* the ambassador becomes a single point of failure and an unowned hop whose latency and error semantics differ from what the service assumes.

**Sidecar**
- *Force:* cross-cutting behaviour — proxying, log shipping, secret rotation — must apply uniformly across heterogeneous workloads.
- *Mechanism:* deploy the concern as a separate container in the same pod or unit, sharing lifecycle, network namespace and resource budget with the application.
- *Costs more than it saves when:* there are few workloads, or the concern is already handled by the platform (ingress, node agent, service mesh).
- *Its own failure mode:* resource requests multiply per pod and squeeze the application; sidecar version skew across workloads produces behaviour nobody can reproduce.

**Compensating transaction**
- *Force:* a multi-step operation spans systems that cannot join one atomic transaction.
- *Mechanism:* for each step, define the inverse action and the state needed to perform it. On failure, run the inverses in reverse order; each inverse must be idempotent because it may be retried.
- *Costs more than it saves when:* the steps are already atomic in one store, or the business can tolerate the partial state with a later reconciliation.
- *Its own failure mode:* compensation that cannot succeed — the refund fails, the email cannot be unsent — leaving a state no code path owns, which needs an operator and a runbook.

**Saga**
- *Force:* a business process spans several services, each with its own store, and consistency must be eventual but bounded.
- *Mechanism:* a sequence of local transactions, one per service, coordinated either by a central orchestrator that tracks state or by events that each participant reacts to. Failures trigger compensating steps; every step is idempotent and every transition is recorded.
- *Costs more than it saves when:* the workflow has two steps and both live in one store — a local transaction is simpler, faster and debuggable.
- *Its own failure mode:* an orchestrator holding all workflow state becomes a hidden monolith; choreography without a correlation identifier produces a process nobody can reconstruct during an incident.

**Sequential convoy**
- *Force:* messages within a group must be processed in order, while independent groups can proceed in parallel.
- *Mechanism:* partition by a group key (order id, session id), assign each partition to one consumer at a time, and let partitions run concurrently. Ordering is guaranteed within a key and nowhere else.
- *Costs more than it saves when:* ordering is not actually required, or one key dominates traffic and forms a hot partition.
- *Its own failure mode:* a stuck message blocks its entire partition indefinitely while other partitions drain, so a small defect looks like a total stall for one customer.

## Read and write scaling

These forces are about volume and shape: too many reads, too large a table, too skewed a workload.

**Cache-aside**
- *Force:* the same data is read far more often than it changes, and the primary store is the bottleneck.
- *Mechanism:* the application checks the cache, loads from the store on a miss and populates the cache, with a TTL and an explicit invalidation on write. The cache is never the only copy.
- *Costs more than it saves when:* the hit rate is low, the access pattern is uniformly random, or stale reads are not acceptable for the data class.
- *Its own failure mode:* invalidation bugs serve stale data indefinitely; a cold cache after a restart sends full read load to the store, which often fails under exactly that load.

**Materialized view**
- *Force:* the query the product needs requires joins or aggregations too expensive to run per request.
- *Mechanism:* precompute the result into a view or table, refreshed on a schedule or on change, and serve reads from it. The staleness bound is a design parameter, written down.
- *Costs more than it saves when:* the source changes faster than the refresh, or the query is cheap enough that the extra copy is pure overhead.
- *Its own failure mode:* silent staleness — the view is correct except for the rows that changed since the last refresh, and nothing in the response says so.

**Index table**
- *Force:* queries filter on fields the primary store cannot index efficiently.
- *Mechanism:* maintain a secondary table keyed by the query field, asynchronously populated from the source of truth, and route those queries to it. The source remains authoritative.
- *Costs more than it saves when:* the primary store can index the field, which is most of the time for relational engines.
- *Its own failure mode:* the index drifts from the source, so results are correct for misses and wrong for updates; rebuilds are expensive and rarely rehearsed.

**CQRS**
- *Force:* read and write workloads have different shapes, volumes or scaling needs, and one model cannot serve both well.
- *Mechanism:* separate the write model from the read model, with distinct interfaces, and synchronise them through events or a projection. Each side scales and evolves on its own.
- *Costs more than it saves when:* read and write volumes are comparable and the domain is simple — two models, two code paths and a synchronisation gap for no benefit.
- *Its own failure mode:* the read model lags and users see their own write missing, which reads as a data-loss bug; the projection becomes a second business-logic layer that drifts from the write side.

**Sharding**
- *Force:* a single store cannot hold the data or serve the write rate, and vertical scaling is exhausted.
- *Mechanism:* partition rows by a shard key — hash for even spread, range for locality — so each shard holds a subset and serves its own traffic. Routing, rebalancing and cross-shard queries become explicit concerns.
- *Costs more than it saves when:* the data fits one node with a replica, or the query patterns need joins across keys.
- *Its own failure mode:* a hot shard from a skewed key, and cross-shard operations that were not in the original design become application-level joins with no transaction boundary.

**Priority queue**
- *Force:* some work must complete faster than other work sharing the same capacity.
- *Mechanism:* separate queues or priority metadata per class, with the consumer choosing the highest-priority non-empty queue, and an ageing rule so low priorities eventually run.
- *Costs more than it saves when:* all work has the same urgency, or capacity is sufficient so priority only reorders latency.
- *Its own failure mode:* starvation of low-priority work during sustained high-priority load, which is invisible until a backlog of background obligations becomes a compliance problem.

**Queue-based load leveling**
- *Force:* demand arrives in bursts far above the capacity of the service that processes it.
- *Mechanism:* put a durable queue between producer and consumer; the queue absorbs the burst, the consumer drains at its own rate. Depth becomes the autoscaling signal and the backlog becomes visible.
- *Costs more than it saves when:* the caller needs a synchronous answer, or the burst is sustained rather than intermittent — a queue does not add capacity, it only defers the shortfall.
- *Its own failure mode:* unbounded growth becomes an invisible outage: producers succeed, consumers fall behind, and the lag is only noticed when the queue hits a retention limit and drops messages.

**Rate limiting**
- *Force:* one caller, tenant or client can consume capacity that others need.
- *Mechanism:* enforce a token-bucket or sliding-window budget per identity at the edge or gateway, return a retry hint with the rejection, and keep the limit configurable per tier.
- *Costs more than it saves when:* capacity is ample and limits only add a failure mode, or the limit is set from the average and rejects legitimate bursts.
- *Its own failure mode:* a limit shared by proxy identity throttles an entire customer because one of their jobs misbehaves; limits without a published retry hint turn throttling into retry amplification.

**Throttling**
- *Force:* the system must stay inside a capacity envelope it cannot exceed, even at the cost of rejecting work.
- *Mechanism:* at the point of admission, choose one behaviour per class — reject, queue, or degrade to a cheaper response — and apply it before the expensive work starts.
- *Costs more than it saves when:* the envelope is elastic, since throttling converts a capacity problem into a product problem.
- *Its own failure mode:* throttling at the wrong layer sheds the cheap requests and admits the expensive ones; degraded responses that are not labelled as degraded get cached and served as authoritative.

**Asynchronous request-reply**
- *Force:* processing takes longer than a client will hold a connection, but the client still needs a definite outcome.
- *Mechanism:* accept the request, return an identifier and a status location immediately, process in the background, and let the client poll or receive a callback. The identifier is the correlation key for every log and metric.
- *Costs more than it saves when:* processing fits comfortably inside the client's timeout, in which case the extra round trip and state store are cost without benefit.
- *Its own failure mode:* results nobody collects — the status record expires before the client polls, or the client retries the submission and produces duplicate work.

## Messaging and integration

These forces are about coupling between producers and consumers: who knows about whom, and what happens to a message in flight.

**Choreography**
- *Force:* a central orchestrator would add coupling, a bottleneck and a single point of failure to a flow several services already understand.
- *Mechanism:* each service publishes domain events and reacts to the events it cares about; the workflow emerges from the subscriptions. No component holds the whole flow.
- *Costs more than it saves when:* the flow has many steps, few services, or needs a visible status — then the flow exists only in the subscriptions and nobody can answer "where is this order".
- *Its own failure mode:* an emergent flow that nobody can trace end to end, where a missing subscription silently stops half the process and the only signal is a downstream backlog.

**Claim check**
- *Force:* messages exceed the broker's size limit, or large payloads crowd out small ones.
- *Mechanism:* store the payload in an object store or database, publish only a reference with enough metadata for routing, and have the consumer fetch the payload with its own credentials.
- *Costs more than it saves when:* payloads are small, since the extra round trip and access-control surface cost more than the broker saved.
- *Its own failure mode:* a reference whose object has expired or been deleted, producing a message that can never be processed and must be dead-lettered; storage lifecycle rules become a hidden correctness dependency.

**Competing consumers**
- *Force:* one consumer cannot keep up with the message rate, and messages are independent.
- *Mechanism:* run several consumers against the same queue; the broker distributes messages, and throughput scales with consumer count until a shared bottleneck appears.
- *Costs more than it saves when:* messages must be processed in order, or the bottleneck is downstream — more consumers then just move the queue.
- *Its own failure mode:* out-of-order processing that the producer assumed was impossible, and duplicate handling when a message is redelivered after a consumer dies post-processing.

**Messaging bridge**
- *Force:* two systems use incompatible messaging technologies and both must stay.
- *Mechanism:* one component subscribes on one side and publishes on the other, translating format, protocol and delivery semantics, while keeping the source's acknowledgement until the target confirms.
- *Costs more than it saves when:* the integration is temporary and a shared format would be cheaper, or one side can be migrated instead.
- *Its own failure mode:* the bridge acknowledges too early and loses messages in the gap, or becomes the one component whose failure is not monitored because it belongs to neither team.

**Pipes and filters**
- *Force:* a processing task contains several distinct transformations that need to be reused or reordered.
- *Mechanism:* decompose into single-purpose filters connected by channels; each filter reads, transforms and writes, and can run in parallel where the order allows.
- *Costs more than it saves when:* the transformation is trivial or must be atomic — splitting it creates partial state and more failure points.
- *Its own failure mode:* a long chain where a failure in the middle leaves the pipeline half-applied and no single component knows the overall state; latency accumulates at each hop.

**Publisher-subscriber**
- *Force:* one event is relevant to several consumers that must not be coupled to the publisher.
- *Mechanism:* publish to a topic; consumers subscribe with their own filters and delivery guarantees. The publisher knows the topic, not the audience.
- *Costs more than it saves when:* there is exactly one consumer, where a queue gives the same decoupling with clearer semantics and backpressure.
- *Its own failure mode:* subscription creep, where an event becomes an implicit API consumed by systems nobody registered, so changing the payload breaks consumers the publisher never knew existed.

**Scheduler agent supervisor**
- *Force:* a long-running workflow spans distributed actions and needs monitoring, retry and recovery per step.
- *Mechanism:* a scheduler dispatches tasks, agents perform them and report progress, and a supervisor tracks state, retries and compensates. State is persisted so a restart resumes rather than repeats.
- *Costs more than it saves when:* the workflow fits in one process, or the steps are quick and idempotent — a queue with retries covers it.
- *Its own failure mode:* the supervisor becomes a stateful single point of failure, and agents that report success without durable confirmation leave the workflow believing work that did not happen.

## Boundaries and frontends

These forces are about where a boundary falls and who adapts to whom.

**Anti-corruption layer**
- *Force:* a legacy or third-party model would leak into a new design if integrated directly.
- *Mechanism:* an adapter layer translates between the external model and your domain model in both directions, so the external vocabulary never reaches core code.
- *Costs more than it saves when:* the external model is stable and already close to yours, or the adapter has no owner and becomes a permanent translation tax.
- *Its own failure mode:* a leaky layer that translates most fields but passes a few through, so the foreign model enters the domain through the gap; duplicated translation logic spreads as callers bypass the layer.

**Backends for frontends**
- *Force:* one general-purpose backend cannot serve clients with different payload shapes, latency budgets and release cadences.
- *Mechanism:* one backend per client experience, each composing the services it needs into a payload shaped for that client, sharing the underlying domain services.
- *Costs more than it saves when:* there is one client, or the clients differ only in presentation — a single API with sparse fieldsets is cheaper.
- *Its own failure mode:* business logic duplicated across BFFs and drifting, so the same rule is implemented twice and disagrees; the number of deployables grows with the number of clients.

**Gateway aggregation**
- *Force:* a client needs data from several services and the round trips dominate latency.
- *Mechanism:* a gateway calls the services in parallel, merges the results into one response, and defines the behaviour for partial failure — omit, default or fail.
- *Costs more than it saves when:* the calls are sequential by nature, or one service is slow and drags the aggregate to its latency.
- *Its own failure mode:* the aggregate takes the maximum latency of its dependencies and inherits every partial-failure mode; a slow dependency makes the whole endpoint slow even when the other calls are fast.

**Gateway offloading**
- *Force:* the same cross-cutting work — TLS, authentication, request logging, rate limits — is implemented in every service.
- *Mechanism:* move the concern to the gateway, so services receive authenticated, rate-limited requests and implement only domain behaviour.
- *Costs more than it saves when:* services are few, or a concern needs domain context the gateway does not have (fine-grained authorisation, per-tenant quotas).
- *Its own failure mode:* the gateway becomes a chokepoint and a single point of failure for the whole estate; offloaded policy that services also enforce diverges and produces inconsistent decisions.

**Gateway routing**
- *Force:* clients need one stable entry point while services are split, moved or versioned underneath.
- *Mechanism:* route on path, header or query to the owning service, with health-aware routing so unhealthy targets are removed, and keep the external contract stable across internal moves.
- *Costs more than it saves when:* there is one backend, or the routing rules encode business logic that belongs in a service.
- *Its own failure mode:* routing rules accumulate into an undocumented second API surface, and a misrouted path reaches a service that answers plausibly, so the defect surfaces far from its cause.

**Strangler fig**
- *Force:* a legacy system is too risky and too large to replace in one move, but it must be replaced.
- *Mechanism:* put a facade in front, migrate one capability at a time to the new implementation, route each capability when it is ready, and decommission the legacy path once traffic is zero.
- *Costs more than it saves when:* the legacy system is small enough to replace outright, or the facade cannot route per capability without changing clients.
- *Its own failure mode:* dual running becomes permanent — two implementations, two data paths and reconciliation debt, with the decommissioning step never scheduled.

## Deployment and operations

These forces are about where code runs, how it is configured, and how it is restored.

**Compute resource consolidation**
- *Force:* many small workloads each hold their own overhead and waste capacity.
- *Mechanism:* pack related workloads with similar scaling and isolation needs onto shared units, keeping resource limits explicit per workload.
- *Costs more than it saves when:* workloads have different failure or scaling profiles — consolidation couples their blast radius and their scaling curve.
- *Its own failure mode:* a noisy neighbour consumes the shared unit's capacity; one workload's memory leak evicts another, and the two teams share an incident.

**Deployment stamps**
- *Force:* a single deployment cannot scale further, or tenants need isolation and data residency.
- *Mechanism:* replicate a complete, self-contained deployment — compute and data — per region or tenant group, with routing in front and infrastructure defined once.
- *Costs more than it saves when:* tenant count is small and residency is not required, since each stamp multiplies operational surface.
- *Its own failure mode:* stamp drift, where each was provisioned slightly differently and an upgrade that works in most fails in one; and a routing table that becomes the real single point of failure.

**External configuration store**
- *Force:* configuration is baked into artefacts, so every change needs a rebuild and redeploy.
- *Mechanism:* move configuration to a versioned store read at start and on change notification, cached locally so a store outage does not stop running instances.
- *Costs more than it saves when:* the application is deployed rarely and configuration is effectively static — the extra dependency costs more than the rebuild it saves.
- *Its own failure mode:* the configuration store becomes a critical dependency whose outage blocks cold starts; values change without review, so behaviour differs between two instances of the same version.

**Geode**
- *Force:* users are globally distributed and distance dominates their latency budget.
- *Mechanism:* deploy service nodes in several regions, each able to serve any request, with data replicated and requests routed to the nearest healthy node.
- *Costs more than it saves when:* users are concentrated in one region, or writes need global consistency that replication latency makes unaffordable.
- *Its own failure mode:* conflicting writes in multi-master regions resolved silently by last-write-wins, so a user's update disappears depending on routing; routing that is unaware of replication lag sends reads to a stale region.

**Static content hosting**
- *Force:* static assets consume compute and bandwidth that application instances should spend on requests.
- *Mechanism:* publish static assets to object storage behind a CDN, with cache headers and versioned paths, so instances never serve bytes that do not change.
- *Costs more than it saves when:* assets are small or request volume is low, so the CDN adds configuration and a second origin without measurable gain.
- *Its own failure mode:* cache invalidation by overwriting a path serves old and new content simultaneously; missing versioning makes a rollback serve mixed asset versions that fail in the browser.

## Security

These forces are about delegated trust and untrusted input.

**Federated identity**
- *Force:* every service implementing authentication multiplies the attack surface and diverges in policy.
- *Mechanism:* delegate authentication to an identity provider and validate its tokens at the edge, keeping minimal identity data locally and a defined behaviour for provider outage.
- *Costs more than it saves when:* the product has one internal audience and no external identity requirement, where a local identity store is simpler to operate.
- *Its own failure mode:* the provider becomes a hard dependency — no new sessions during an outage — and token validation implemented differently per service lets inconsistent claims through.

**Quarantine**
- *Force:* external content — uploads, packages, partner data — may be malicious or malformed and is consumed by production paths.
- *Mechanism:* accept into an isolated store, scan and validate against explicit gates, and promote only on pass. Rejected items stay available for investigation rather than being silently dropped.
- *Costs more than it saves when:* content is from a trusted producer with its own verified pipeline, where scanning duplicates an existing gate.
- *Its own failure mode:* the quarantine bypass — an alternate ingest path, a direct bucket URL, a shared credential — that reaches production without scanning; scans that time out and default to allow.

**Valet key**
- *Force:* proxying every byte of client data access through the application wastes capacity and adds latency.
- *Mechanism:* issue a scoped, short-lived credential that grants a client access to one resource with limited operations, so the client transfers directly.
- *Costs more than it saves when:* access is small or infrequent, or the resource needs per-request authorisation the token cannot express.
- *Its own failure mode:* a token with more scope or a longer lifetime than intended, leaked through logs or URLs; revocation that cannot reach an already-issued token.

## Events

**Event sourcing**
- *Force:* the history of state changes is itself a requirement — audit, replay, temporal queries — and mutating current state destroys it.
- *Mechanism:* persist every state change as an immutable event; derive current state by replaying or from a projection. Corrections are new events, never edits.
- *Costs more than it saves when:* the audit requirement can be met by an append-only audit log beside a normal store, which costs a fraction of the operational change.
- *Its own failure mode:* unbounded replay time as the log grows; schema evolution across years of events that must remain replayable; and a projection that is trusted so completely that nobody can rebuild it.

## Combinations that work and combinations that fight

| Combination | Effect |
|---|---|
| Retry + circuit breaker + bulkhead per outbound dependency | Standard outbound pattern: the bulkhead bounds the blast radius, the breaker stops the load, the retry survives a blip |
| Queue-based load leveling + competing consumers + queue depth as autoscaling signal | Bursts absorbed, throughput elastic, backlog visible |
| Saga + compensating transaction + idempotent steps | The only workable distributed write; the idempotency is what makes retries safe |
| CQRS + event sourcing + a tested projection rebuild | Read scale without losing the ability to reconstruct |
| Strangler fig + anti-corruption layer + gateway routing | Incremental migration with the legacy model contained |
| Circuit breaker + retry without jitter | Fighting: identical backoff schedules synchronise into a retry storm |
| Priority queue + competing consumers | Fighting: parallel consumers reorder the priorities the queue was built to enforce |
| Sharding + cross-shard joins | Fighting: joins move into the application and lose the transaction boundary |
| Valet key + quarantine | Fighting: direct client access bypasses the scan the quarantine exists to enforce |
| Event sourcing + mutable projection as the only read path | Fighting: no rebuild path means the log is trusted without being verifiable |

## Measuring that a pattern works

Each pattern has a metric that shows whether it is doing its job; without one, the pattern is decoration.

| Pattern | Metric |
|---|---|
| Circuit breaker | Open-state duration, fallback rate, recovery time after close |
| Retry | Attempts per request, retry share of total requests, error rate after retries |
| Bulkhead | Per-partition saturation, rejected requests per partition |
| Rate limiting / throttling | Rejection rate by identity, retry-after compliance |
| Queue-based load leveling | Queue depth, oldest-message age, drain time |
| Cache-aside | Hit rate, eviction rate, load on the source after a flush |
| Sharding | Rows and QPS per shard, hot-shard ratio |
| Saga | Completion rate, compensation rate, time per step |
| CQRS | Projection lag, read-after-write misses |
| Strangler fig | Share of traffic on the new path, legacy decommission date |
| Event sourcing | Replay duration, projection rebuild success, event schema versions live |

Record the metric alongside the pattern in the ADR. When the metric moves the wrong way, the pattern's cost line is the first thing to re-read, not the pattern's description.
