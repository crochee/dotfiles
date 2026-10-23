**Load this reference when:** writing, reviewing or debugging the reconcile loop — idempotency, cache reads, requeue policy, conflict retries, write storms, rate limiting, leader election, or testability.

# Reconcile

A reconcile function takes a name and converges the world toward what the object says it wants. It is called again on any event, in any order, possibly twice in a row, possibly on an object that was deleted between the event and the call. Every rule here follows from those facts.

## Level-triggered

The request is a hint, not a delta. Three consequences, in order of how often they are violated:

1. **Re-read the object inside the reconcile.** Never trust an object captured by a handler or passed from an earlier call. If it is gone, return success — a delete is a valid end state.
2. **Compute the whole desired state each time**, from the CR plus what exists, not from "what changed since last time". Any diff you cache is wrong the moment the cache expires.
3. **Converge, do not replay.** If the CR says three replicas and the child has two, set three — regardless of who asked for two or why.

## Idempotency

The test is mechanical: run reconcile twice from a settled state and assert zero writes on the second run.

|Operation |Idempotent form |Not |
|---|---|---|
|Create a child |get, then create only on `NotFound`; or create and treat `AlreadyExists` as success; or name it deterministically and server-side apply |`Create` and hope |
|Update a child |patch the difference, or SSA with a stable field owner |`Update` with a freshly built object (drops fields other owners set) |
|Append to a list |keyed merge list, or compare before appending |append unconditionally |
|Delete |treat `NotFound` as success |error on `NotFound` |
|Add a finalizer |check membership, then patch |append to the slice |

Idempotency is also what makes the loop safe to retry: an error return re-enqueues, and the second attempt must not double-create.

## The read path

- **No writes from an event handler.** A lister, watch callback or predicate that writes turns an observe into a cause and produces loops that are hard to see in logs.
- **Never mutate a cached object.** In Go the manager's cache hands out shared pointers: mutating one corrupts the cache for every other reconciler and for the next read. `DeepCopy` before mutation (`obj.DeepCopy()`, or clone in Rust — the reflector store hands out `Arc<T>`).
- **Cached reads are stale by design.** A cache read after a write may return the pre-write object, sometimes for hundreds of milliseconds. It is not a bug; it is the trade for not calling the API server on every branch.

|Need |Read from |Cost |
|---|---|---|
|Branch on the CR's spec |cache |no API call, may be stale |
|Branch on a child the controller just wrote |API reader / direct client, or re-read with a fresh `Get` |one API call |
|List across the cluster |cache with an index |memory, no API call |
|Decision that must be linearizable (e.g. "does the lease exist") |direct read |one API call per reconcile |

A direct read inside a hot loop is how an operator becomes an API-server load problem. Restrict it to the paths that genuinely need it, and name the reason in a comment.

## Requeue policy

|Return |Means |Use for |
|---|---|---|
|`Result{}`, `nil` / `Action::await_change()` |done; wait for the next event |the steady state — this is the normal path |
|`RequeueAfter: d` / `Action::requeue(d)` |re-check after `d` |polling an external system, a backoff you control, a certificate that expires |
|`Requeue: true` |retry immediately, rate limited |almost never; it hides a missing watch |
|error / `Err` |transient failure; exponential backoff |network blips, conflicts, a not-yet-ready dependency |
|`nil` + a condition set |permanent failure; stop retrying |a spec that cannot be satisfied — retrying will not change it |

Backoff is item-scoped and exponential by default (milliseconds doubling to a maximum measured in minutes), so a permanently failing object settles into an occasional retry without a hot loop.

Requeue durations want jitter and a ceiling. A fixed `RequeueAfter: 10s` on a thousand objects synchronises a thousand wake-ups; a jittered value between two bounds spreads them, and a ceiling keeps a slow external system from being polled forever.

**Permanent failures are not errors.** Returning an error for a misconfigured spec burns the backoff, floods events and logs, and tells the user nothing. Set a `Ready=False` condition with a stable `reason` and return success.

## Conflict retry

Status and finalizer writes are the contested paths: the user edits the spec, another controller writes status, and both are full-object writes against one `resourceVersion`. The losing write returns `Conflict`.

- **Patch instead of update where possible.** A merge patch or a server-side apply carries only the fields you own and conflicts rarely. A JSON patch against the exact field is even narrower.
- **When you must update, retry the read-modify-write.** `RetryOnConflict`-style loops (Go: `retry.RetryOnConflict`, re-`Get` inside the closure; Rust: retry the `try_update_status` call after re-fetching) must re-read inside the loop. Retrying the same object with a stale `resourceVersion` fails identically forever.
- **Status has its own write path.** `Status().Update` / `Status().Patch` / `patch_status` only succeeds when the CRD has the status subresource. Without it, status rides on the main object and conflicts with every spec write.
- **One status write per reconcile.** Compute conditions in memory, compare with what is stored, and write once at the end. Two writes per reconcile double the conflict window and the event volume.

## Avoiding status write storms

A status write fires a watch event for every replica and every consumer. The cost is not the write; it is the fan-out.

- Diff before writing. If conditions, observed fields and `observedGeneration` are unchanged, write nothing. Comparing the serialised status is cheap and catches "same content, new resourceVersion".
- Do not bump `observedGeneration` until the work for that generation is done, and do not write it separately from the conditions it belongs with.
- Do not put timestamps that change every reconcile into status (`lastReconcileTime` and friends). They make every reconcile a write and every write an event.
- Batch child updates: patch the ones that changed, leave the rest.

## Rate limiting and concurrency

Two independent limits:

- **Per item** — exponential backoff on failure. Tune the base so a fast-failing dependency does not produce a thousand attempts per minute.
- **Global** — a token bucket over all items, plus `MaxConcurrentReconciles` / `controller::Config::concurrency`.

Concurrency raises throughput and API pressure together. Set it from the measured reconcile duration and the object count, not from a template: four workers that each list one namespace are cheap; thirty-two workers each doing a direct read are an outage. Each concurrent reconcile also holds a client set and its caches.

## Leader election

With more than one replica, every reconcile runs twice. Status flaps, and two writers race on the same children.

- Elect with a `Lease` in `coordination.k8s.io/v1`: `holderIdentity` (the pod name), `leaseDurationSeconds`, `renewTime`.
- Go: `LeaderElection: true` and a stable `LeaderElectionID`; the manager gates the runnables that declare they need leadership (controllers do, webhooks and health endpoints do not — a standby replica must still answer `/readyz` and serve admission).
- Rust: kube-rs has no manager, so gate the `Controller` yourself — a Lease lock around the `run` future — or pin the deployment to one replica and say so.
- **Split brain has three usual causes**: `leaseDurationSeconds` too close to the retry period, two deployments with different identities and the same lease name, and clock skew across nodes. Keep renew well inside the duration (a third is the conventional split) and give each operator its own lease name.
- Leader election does not protect against a `kubectl delete pod` during cleanup. That is why step 3 of the workflow puts the finalizer in place before anything external exists.

## Making a reconcile unit-testable

Testability is a design property, not a test-framework choice.

- Take the client, the clock and the recorder as fields or parameters. A reconcile that reaches for a package-level client cannot be run against a fake.
- No sleeps, no goroutines spawned and forgotten, no reads of the wall clock for duration decisions. Return a requeue duration instead; the test asserts on it.
- Side effects that leave the cluster (HTTP, cloud SDK) go behind an interface so the test can assert the call and inject its failure.
- Return errors instead of panicking. A panic in a reconcile is a process crash in production and an unusable test failure in CI.
- Keep the function shaped as read → decide → write → set status → return, so a table test can set up objects, call once, and compare.

The concrete test shapes are in the testing reference; the property to assert there is always the same: two calls, one set of writes.

## Checklist

- The object is re-read inside reconcile, and a missing object is a success.
- A second reconcile from a settled state writes nothing.
- No cached object is mutated in place.
- Every return path is `await_change`-equivalent, a requeue duration, or an error reserved for transient failures.
- Status is written at most once, and only when it differs.
- Conflict handling re-reads inside the retry loop.
- Concurrency and rate limits have a stated basis.
- Leader election is on, or the replica count is one and the reason is written down.
