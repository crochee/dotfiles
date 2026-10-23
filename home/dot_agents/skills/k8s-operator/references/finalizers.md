**Load this reference when:** adding a finalizer, fixing a CR that will not delete, or deciding whether an owner reference replaces the finalizer entirely.

# Finalizers

A finalizer is a string in `metadata.finalizers` that defers deletion until someone removes it. It gives the controller a window in which the object still exists and can still be read — that window is the whole mechanism, and every rule here protects it.

## The ordering that makes it correct

Deletion is asynchronous and can start at any moment, so the finalizer must exist before anything the controller would need to clean up.

1. Read the CR.
2. **If `deletionTimestamp` is unset and the finalizer is missing, add it and return** (or continue, if the add succeeded — but return on failure). Do not create children in the same pass as the add unless the add succeeded and you have confirmed it.
3. If `deletionTimestamp` is unset: converge the children as usual.
4. If `deletionTimestamp` is set: request deletion of each external resource, check whether it is gone, and **only when all of them are gone** patch the finalizer out.
5. Return success. The API server removes the object once the list is empty.

Two failure modes make the ordering non-negotiable:

- **Create-then-add** loses orphans. If the process dies between creating a load balancer and adding the finalizer, the CR can be deleted with nothing pointing at the balancer.
- **Remove-then-delete** loses the record. If the finalizer is gone before the external resource is, the CR disappears and nothing will ever retry the deletion. The resource is still billed.

The add is a patch on the CR, not an `Update` of a stale copy: a full-object update on the add path rewrites spec fields the user just changed. See the reconcile reference for the conflict-retry shape.

## Re-entrant cleanup

Cleanup runs again after every failed attempt, on a new process, possibly after a partial success. Write it as a set of idempotent steps:

- **`NotFound` is success.** Deleting something already deleted is done.
- **Issued is not gone.** A `Delete` call returning success means the request was accepted. A cloud load balancer, a PVC, a namespace, or an object with its own finalizer may live for minutes afterwards. Re-read it and check for a terminal state; if the API has none, check a status field it exposes.
- **Second pass, same code path.** Do not add a separate "cleanup" branch reached only from an error. One path, run until it reports done, with the requeue doing the repeating.
- **Record progress in status only if a human needs it** — a `Terminating` condition with a reason. Progress bookkeeping inside the finalizer's own data is state you cannot trust after a restart.
- **Remove the finalizer with a targeted patch on the current resource version**, and tolerating a conflict by re-reading. Removing it twice is a `Conflict`, which the retry loop handles; adding it twice is harmless only if you checked membership.

## External resources

|Situation |Mechanism |
|---|---|
|Namespaced child, same cluster |owner reference with `controller: true`; garbage collection deletes it, no finalizer needed |
|Cluster-scoped child, same cluster |allowed when the owner is cluster-scoped too; a namespaced CR cannot own a cluster-scoped child |
|Resource outside the cluster (cloud, DNS, database, webhook registration) |finalizer on the CR; nothing else will ever delete it |
|Resource in the cluster that itself has a deletion barrier (load balancer service, PVC) |both: owner reference for the cascade, and the CR's finalizer only if the controller must wait for a terminal state before finishing |
|A child the controller does not own but created (e.g. in another namespace) |its own finalizer or a recorded name; owner references do not cross namespaces |

**Do not put your finalizer on other people's objects.** Adding one to a Deployment means a broken controller strands the Deployment. Own the object or do not block its deletion.

**Owner references beat finalizers** whenever the child is in the same cluster and garbage collection can express the relationship. They cost nothing, survive controller downtime, and cannot be forgotten. The finalizer is for what the cluster cannot delete.

## Never block on a human

A finalizer that waits for an approval, an email, or "the operator to notice" parks the CR forever when the human never acts. Kubernetes has no timeout for finalizers, and a CR stuck in `Terminating` blocks namespace deletion.

Instead:

- Approval belongs in a separate CR (a policy, a signed template) whose absence is a normal reconcile result, not a deletion barrier.
- If the object must be retained for audit, annotate it and let a policy controller decide — do not make retention a finalizer.
- Any "cleanup with a deadline" is a design smell: the deadline cannot be enforced by the API server, so the promise is unenforceable.

The one legitimate wait is on a system that will answer on its own, within a bounded time, and whose answer the reconcile can observe. Poll it with `RequeueAfter`, not with a sleep, and cap the retries with a condition that says cleanup is failing.

## Uninstalling without stranding objects

If the controller is removed while CRs exist, the finalizers remain and every CR is undeletable. That is a documented consequence, not an accident, so:

- Ship the removal command in the operator's README: patch the finalizer out of each CR after confirming the external resources are gone by hand.
- Do not add a finalizer to a CRD the operator can stop serving while its CRs remain.
- In an upgrade path that renames the finalizer string, handle both strings during one release. An old finalizer that no version knows about is a permanent lock.

## Diagnosis

```console
kubectl get <cr> <name> -o jsonpath='{.metadata.deletionTimestamp}{"\n"}{.metadata.finalizers}{"\n"}'
kubectl get <cr> <name> -o jsonpath='{.status.conditions}'
```

A set `deletionTimestamp` with a non-empty list and no recent events means the controller is not running, cannot reach the external system, or returned early on an error path. Check the controller's own logs before touching the finalizer; removing it by hand is a deliberate decision to leak the external resource, not a fix.

## Checklist

- The finalizer is added before the first external resource is created.
- The add and the removal are both patches against the object's current resource version, with conflict retry.
- Cleanup treats `NotFound` as success and confirms a terminal state before removing the finalizer.
- Every child inside the cluster uses an owner reference instead of the finalizer.
- No finalizer waits on a human or on a deadline it cannot enforce.
- The uninstall path is documented, and a renamed finalizer string is handled for one release.
