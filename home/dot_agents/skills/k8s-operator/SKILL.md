---
name: k8s-operator
description: "Delivers a Kubernetes operator whose CRD is structural, whose reconcile converges on every run, and whose finalizers, RBAC and upgrade path are proven by commands. Use when writing, reviewing, or debugging a controller."
metadata:
  version: "1.0.0"
---

# Kubernetes Operator

Deliver an operator whose CRD is structural and convertible, whose reconcile function converges to the same state on every invocation, and whose cleanup, permissions and upgrade path are each backed by a command you actually ran.

## When to Use

Three modes:

- **Author** — a new CRD and controller, or a new kind added to an existing operator.
- **Review** — read an existing controller for correctness: reconcile semantics, finalizer ordering, RBAC breadth, upgrade safety.
- **Debug** — chase one symptom: a hot reconcile loop, a deletion that never finishes, flapping conditions, a CRD the API server rejects.

The toolchain comes from the repository, not from preference. Both stacks share the same invariants; only the code shapes differ. A hand-written `client-go` informer loop without `controller-runtime` gets the shared invariants (step 2 onward) and nothing from the two scaffold references.

Not for: cluster administration, Helm-only chart work, or RBAC escalation auditing — who may bind or escalate is a cluster-security question, not an operator question.

## Toolchain Selection

Read the dependency file before the source. The signal is a line in `go.mod` or `Cargo.toml`, not the directory tree.

|Repository signal|Toolchain|Read|
|---|---|---|
|`go.mod` contains `sigs.k8s.io/controller-runtime`|Go + kubebuilder|`references/go-kubebuilder.md`|
|`go.mod` contains `operator-sdk`|Go + operator-sdk|`references/go-kubebuilder.md`, SDK-differences section|
|`Cargo.toml` contains `kube` / `kube-rs`|Rust + kube-rs|`references/rust-kube-rs.md`|
|anything else|review against the shared invariants only|`references/reconcile.md`|

Record the decision and its evidence (`go.mod:12`, `Cargo.toml:34`) in the deliverable. A reviewer who cannot point at the line that chose the stack is guessing.

## Workflow

The six steps are ordered because each one constrains the next: the state machine fixes the schema, the schema fixes what reconcile may write, and the write paths fix the RBAC. Skipping ahead produces code that has to be rewritten.

1. **Model the API and its state machine.** Classify every field: `spec` is what the user asks for, `status` is what the controller observed, never both. Name the states, the legal transitions, and which transition needs a subresource write. Choose the version now — `v1alpha1` while the schema still moves, `v1` once you accept additive-only changes — and decide namespaced or cluster scope, because scope decides RBAC and owner references. → `references/crd.md`
   *Exit criterion:* every field is classified, every state and transition is named in the deliverable, and scope plus served/storage versions are written down.
2. **Write the failing test, then the reconcile as convergence, not as an event handler.** Start with one behaviour against a fake client and quote its failure. Treat the request as a hint: re-read the object, compute the desired child set as a pure function of the CR, and apply the difference with create-or-patch. Return a requeue decision instead of sleeping. Watch the children you own, filter with a generation predicate so status-only writes do not re-enter, and elect a leader when replicas exceed one so exactly one writer exists. → `references/reconcile.md`
   *Exit criterion:* the first test failed before the reconcile existed; reconciling the same CR twice from a settled state performs no writes and returns the same result; every return path explains the next check without a sleep.
3. **Place the finalizer before anything external exists.** Add it on the first reconcile, before creating a resource you cannot find again by name; remove it only after cleanup has reached a terminal state, in one patch against the object's current resource version. → `references/finalizers.md`
   *Exit criterion:* a test that interrupts between the external delete and the finalizer removal re-runs and removes the finalizer exactly once; no finalizer waits on a human.
4. **Derive RBAC from call sites, then read the generated diff.** Each verb in the generated role maps to a code path; each cluster-scoped rule has one sentence of justification. → `references/rbac.md`
   *Exit criterion:* the generated role contains no verb without a call site, no `*`, and no `secrets` read that the controller does not use.
5. **Prove it at the remaining layers.** The fake-client unit tests came first; extend them as the branches grow, then add envtest for API-server semantics and kind for the real binary and the real image. State what each layer cannot prove next to its output. → `references/testing.md`
   *Exit criterion:* the unit, envtest and kind commands are recorded with their output, and each has a sentence naming its blind spot.
6. **Prove the upgrade path.** One storage version, a conversion webhook (or `strategy: None` with genuinely identical schemas) that is lossless in the hub, a migration for `status.storedVersions`, and an e2e that starts on the old version and ends on the new one. → `references/crd.md`
   *Exit criterion:* an object created under the previous served version reads correctly under the new one, and the storage-version migration is written down as a step, not as an intention.

## Quick Decisions

The signal to toolchain table lives under `## Toolchain Selection`. Resolve an unclear signal with the rows below, then pick the scope, then match the symptom.

When the repository does not match a row cleanly:

| Repository state | Decision |
|---|---|
|`go.mod` has both `controller-runtime` and `operator-sdk`|Go + kubebuilder; read the SDK section only where `bundle/`, `config/scorecard/` or a `go/v3` layout exists|
|`kube` appears only as a transitive version pin|not a kube-rs operator; review against the shared invariants|
|both `go.mod` and `Cargo.toml` at the root|two codebases; pick the module that declares the reconciler or `Controller`, review each on its own terms|
|`controller-runtime` vendored, no `PROJECT` file|Go + controller-runtime with hand-written wiring; the scaffold reference applies minus `PROJECT` and Makefile targets|
|`kube` locked to an older minor|check `Cargo.lock` first — `Controller::new` takes `ListParams` before ~0.90 and `watcher::Config` after; write for the locked API, not the docs|

| What the CR manages | CR scope | RBAC consequence |
|---|---|---|
|Tenant instances in their own namespaces|Namespaced|cluster-wide `get/list/watch` on the CR, writes confined to the CR's namespace at runtime|
|Cluster add-ons (CNI, ingress, node agents)|Cluster|cluster role for everything touched; every rule needs its justification line|
|Children that always live beside the CR|Namespaced|a namespaced `Role` suffices when the operator only reconciles its own namespace|

Symptom to cause, for Debug mode:

| Symptom | Likely cause | Read |
|---|---|---|
|Reconcile runs hot with no spec change|watches an object it writes (its own status, its own child) with no generation predicate; each status patch bumps `resourceVersion` and re-enqueues|`references/reconcile.md`|
|Condition or status flaps|two replicas reconciling without leader election, or status computed from a cached read taken before the last write|`references/reconcile.md`|
|Finalizer never clears|cleanup issued but not awaited, or an early error return skips the removal, or the external delete needs a second pass|`references/finalizers.md`|
|Finalizer cleared, cloud resource survives|fire-and-forget delete; the external API needs polling to a terminal state|`references/finalizers.md`|
|CRD apply: `must be a valid structural schema`|free-form `additionalProperties: true`, an `anyOf` at the root, or `x-kubernetes-preserve-unknown-fields` beside validation keywords|`references/crd.md`|
|CRD apply: CEL rule rejected or over cost budget|`oldSelf` in a non-transition rule, or a rule iterating a collection the schema does not bound|`references/crd.md`|
|Existing CRs rejected: `spec.foo: Required value`|the field became required when the type lost `omitempty` or `Option`|`references/crd.md`|
|`forbidden` in the cluster, not locally|markers edited without regenerating manifests, or a namespaced `Role` where the controller lists across namespaces|`references/rbac.md`|
|Both replicas act|leader election off, or two deployments sharing one `LeaderElectionID`|`references/reconcile.md`|
|Passes with the fake client, fails in envtest|the fake client does not default, prune, run CEL, or convert|`references/testing.md`|

## Output

| Artefact | Required content |
|---|---|
| CRD manifest (`config/crd/bases/<group>_<plural>.yaml`) | structural schema; printer columns; `status` subresource; a CEL rule for every cross-field invariant; one `storage: true`; the conversion path stated |
| Controller | spec and status separated; exactly one finalizer; a requeue decision on every return path; owner references on every child; watches for the children it owns |
| RBAC | the generated role plus a verb-to-call-site mapping; cluster-scoped rules justified |
| Test evidence | unit, envtest and kind commands with their output, and one sentence per layer naming what it cannot prove |
| Upgrade note | storage version, conversion losslessness argument, `storedVersions` migration step, the old-version e2e result |
| Review report | the findings table below |

Review findings, one row per defect, ordered by what blocks a rollout first:

| Severity | Invariant | Location | Fix |
|---|---|---|---|

Severity is `blocks rollout` (data loss, finalizer trap, schema the API server rejects), `correctness` (non-idempotent write, unhandled conflict, missing condition), or `drift` (over-broad rule, unbounded list, missing predicate). Every row cites a file and line; a finding without a location is an opinion.

## References

| File | Load when |
|---|---|
| [references/crd.md](references/crd.md) | Designing or reviewing a CRD: versioning, structural schema, defaulting, CEL, subresources, conditions, conversion. |
| [references/reconcile.md](references/reconcile.md) | Writing or debugging the reconcile loop: idempotency, cache reads, requeue policy, conflict retry, rate limiting, leader election. |
| [references/finalizers.md](references/finalizers.md) | Adding a finalizer or fixing a deletion that never finishes. |
| [references/rbac.md](references/rbac.md) | Deriving or reviewing roles from markers, markers to manifest, scope and escalation. |
| [references/testing.md](references/testing.md) | Choosing a test layer, scaffolding envtest or kind, or writing the upgrade test. |
| [references/go-kubebuilder.md](references/go-kubebuilder.md) | The repository is Go: scaffold layout, wiring, watches, patches, events, operator-sdk differences. |
| [references/rust-kube-rs.md](references/rust-kube-rs.md) | The repository is Rust: `Controller`, `Action`, `Api`, finalizer helper, conditions, leader election. |
| [references/anti-patterns.md](references/anti-patterns.md) | A controller smells wrong and you need the concrete replacement rather than a principle. |

## Verification Checklist

- [ ] The toolchain selection is recorded with the `file:line` that justified it.
- [ ] `kubectl apply --dry-run=server -f config/crd/bases/<group>_<plural>.yaml` accepts every CRD, and the CRD has `spec.preserveUnknownFields: false`.
- [ ] Exactly one served version has `storage: true`; `kubectl get crd <plural>.<group> -o jsonpath='{.status.storedVersions}'` names only versions still served or explicitly migrated.
- [ ] No required field was added to a served version; every new spec field is optional or has a default.
- [ ] Reconciling twice from a settled state performs zero writes — asserted in a test, not argued.
- [ ] No `time.Sleep`, `tokio::time::sleep` or naked poll loop sits on the reconcile path.
- [ ] The finalizer test interrupts after the external delete, re-runs, and asserts removal exactly once.
- [ ] The generated role has no `*` verb, no unused verb, and every cluster-scoped rule carries a justification.
- [ ] Status is written only when it changed; conditions are standard-shaped (`metav1.Condition` in Go, the kube-rs condition type in Rust), positive-polarity, and carry `observedGeneration`.
- [ ] Only one replica writes: leader election is enabled or the deployment is pinned to one replica.
- [ ] The envtest and kind commands are in the evidence, each with its blind spot.
- [ ] The old-version e2e passed against the new CRD and image.
