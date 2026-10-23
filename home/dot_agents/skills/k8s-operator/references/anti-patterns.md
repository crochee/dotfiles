**Load this reference when:** a controller review has found a smell and you need the concrete replacement, or you suspect an operator was written by adapting an example without the invariants.

# Anti-patterns

Each row is a failure that compiles, passes a fake-client test, and then misbehaves in a cluster. The replacement is what to write instead; detection is how to find the ones already shipped.

|Anti-pattern |Looks like |Replace with |
|---|---|---|
|Sleeping in reconcile |`time.Sleep` / `tokio::sleep` / a retry loop inside the function |return `RequeueAfter` / `Action::requeue_after` and stop |
|Spec mutation |the controller writes `spec.replicas` from a policy it computed |a separate field the user or another controller owns; status reports the adjustment |
|Unbounded children |one child per item in a user-supplied list, no cap, no pruning |cap in the CRD (`maxItems` + CEL), name children deterministically, delete the orphans each pass |
|Status as a data bag |`status.raw`, `status.payload`, `serde_json::Value`, a full copy of the child |typed, small fields plus conditions; the child is the source of truth |
|Retry storm on permanent failure |`return err` for an invalid spec |`Ready=False` with a stable reason, `return nil` |
|Batch work in one reconcile |the CR lists 500 children and the loop creates them serially |one reconcile per owner (fan out into child CRs) or reconcile a work queue with bounded progress |
|`GenerateName` without adoption |`Create` with `GenerateName`, no label selector, every reconcile makes a new object |deterministic names, or list-by-label and adopt before creating |
|Secrets in status |token, kubeconfig, password, full Secret contents in `status` |reference the Secret by name; status holds a hash or a version, never the material |
|CRD churn |field renamed in place, type changed, `spec`↔`status` moves |new version + conversion, or an additive field with the old kept until the next version |
|Cache mutation |object from `Get` mutated then written |`DeepCopy` / clone first |
|Polling instead of watching |a timer that lists every child each pass |`Owns`/`owns()` watch plus a long `RequeueAfter` only for external state |
|Timestamp churn |`status.lastReconcileTime` written each pass |remove it; the resource's own metadata already carries when it changed |

## Sleeping in reconcile

The process has a work queue, a rate limiter and a backoff. A sleep inside reconcile holds a worker for the duration, hides the wait from the metrics that would show it, and is cancelled badly on shutdown.

```go
// wrong
time.Sleep(30 * time.Second)
return ctrl.Result{}, nil

// right
return ctrl.Result{RequeueAfter: 30 * time.Second}, nil
```

Same in Rust: `Ok(Action::requeue_after(Duration::from_secs(30)))`. If the wait is for an external system, make the wait *observable*: set a condition saying "waiting for the load balancer to become active", so a human reading `kubectl describe` knows why nothing is happening.

Detection: `grep -rn 'time.Sleep\|tokio::time::sleep' --include='*.go' --include='*.rs'`; any hit on the reconcile path is a defect.

## Mutating spec from the controller

A controller that writes to `spec` fights the user and every GitOps reconciler: the commit is authoritative, the controller rewrites it, the syncer rewrites it back, and the object oscillates. It also makes `spec` no longer a statement of intent, which breaks every read of the object, including your own.

Replace with one of:

- **A status field** when the controller observed or adjusted something: `status.effectiveReplicas`.
- **A separate CR** when the controller owns policy: the user creates `ThingPolicy`, the controller reads it.
- **A default in the CRD** when the value is a default and not a decision.

Detection: any `r.Update` / `api.patch` that touches `.spec`, or a mutating webhook on your own CRD.

## `GenerateName` without adoption

`GenerateName` makes the API server pick a name, so the controller cannot find its child again by name. The result is a new Deployment every reconcile until the quota is exhausted.

Pick one:

- **Deterministic name** — `fmt.Sprintf("%s-deploy", thing.Name)` — and patch it by name.
- **Label plus adoption** — list by the owner label, adopt the first match, delete the rest, and only create when the list is empty.

The second needs a label selector that cannot match another CR's children: owner name plus UID. A label of just `app: thing` matches the user's own Deployment and the controller adopts something it did not create.

## Status containing unstructured data

Copying a child into status looks convenient and fails in three ways: the CRD schema has to be structural (so the copy needs a full type or a `preserve-unknown-fields` hole that disables validation), the copy goes stale the moment the child changes, and every write is large enough to matter.

Replace with the observation the consumer actually needs: `availableReplicas`, `currentImage`, `endpoint`, plus a condition carrying the reason. If a consumer truly needs the child, it can read the child — that is what the API is for.

Detection: `preserve-unknown-fields` in the CRD, `runtime.RawExtension` / `serde_json::Value` / `DynamicObject` in the status struct.

## Retry storms from permanent failures

Returning an error for an unsatisfiable spec gives the user a controller that logs a traceback every few seconds, emits warning events until the event API throttles them, and never tells them what is wrong in a place they will look.

|Failure |Return |
|---|---|
|API server 5xx, timeout, `Conflict` after retries |error — backoff is correct |
|Missing dependency that will appear (a CR the other operator has not created yet) |`RequeueAfter` with a condition |
|Invalid spec, unsupported combination, immutable field changed |`Ready=False`, stable reason, `return nil` |

The distinction is "will retrying change anything". If not, retrying is noise. The condition is the channel for the user; the event is the notification that it changed.

## CRD churn

Renaming `spec.replicaCount` to `spec.replicas` in place deletes the user's intent from every stored object — the field is pruned on the next write, and nothing records what it was. Changing a field from integer to string breaks every client on the next read.

The only safe edit inside a served version is additive. Everything else is:

1. New version with the new shape; old version still served.
2. Conversion webhook (or identical schemas if the change is representational only).
3. Round-trip test: old → hub → old is deep-equal.
4. `storedVersions` migration once the old version stops being served.

A "temporary" conversion webhook that is never retired is its own anti-pattern: it is an availability dependency on the read path of version one.

## Detecting these in a review

|Question |Catches |
|---|---|
|What does reconcile do when the spec is invalid? |retry storm, missing condition |
|Is there a `Sleep` anywhere in the controller package? |blocking wait |
|Does any code path write `.spec`? |spec mutation |
|Where does each child name come from? |`GenerateName`, adoption |
|How large can status get, and what is in it? |data bag, secrets |
|Does the second reconcile write anything? |idempotency, status churn |
|Does the CRD have `preserve-unknown-fields`, `anyOf`, or an unbounded list? |non-structural schema, unbounded children |
|Has a field ever been renamed in a served version? |CRD churn without conversion |
