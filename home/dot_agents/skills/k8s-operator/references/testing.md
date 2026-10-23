**Load this reference when:** choosing a test layer, scaffolding envtest or kind, writing the reconcile table test, or building the upgrade test.

# Testing

Three layers, chosen by what they can prove. A test that asserts the wrong layer's property is worse than no test: it passes while the API server rejects every write.

|Layer |Runs |Proves |Cannot prove |
|---|---|---|---|
|Unit with a fake client |in-process |branching, idempotency, requeue decisions, error paths |defaulting, CEL, pruning, conversion, RBAC, subresource semantics |
|envtest |real `kube-apiserver` + `etcd` |schema, defaults, CEL, immutability, conversion, status subresource, `generation` |anything a controller does — there is no controller-manager, scheduler, kubelet or garbage collector |
|kind |real cluster |the real image, watches, owner-reference cascade, finalizers against a real GC, upgrades |nothing about your code's internals — failures here are slow to localise |

## Unit tests with a fake client

The fake client implements `client.Client` in memory. It is the right tool for "does the function decide correctly", and the wrong tool for "is the API valid".

```go
c := fake.NewClientBuilder().
    WithScheme(scheme).
    WithObjects(cr, existingChild).
    WithStatusSubresource(&v1alpha1.Thing{}).   // status writes then go through /status, as on a real cluster
    WithIndex(&v1alpha1.Thing{}, ".spec.configRef", indexFn).
    Build()
r := &ThingReconciler{Client: c, Scheme: scheme, Recorder: record.NewFakeRecorder(64)}
```

- `WithStatusSubresource` is required for any CRD with a status subresource, otherwise test behaviour diverges from the cluster.
- `WithIndex` mirrors the manager's field indexers; a test that lists without it fails at runtime with "no index with name".
- `interceptor.Funcs` (from `pkg/client/interceptor`) injects failures — a `Conflict` on update, a `Forbidden`, a timeout — which is the only practical way to test retry loops.
- The fake client does not default, prune, run CEL, convert, or increment `generation` the way the API server does. Anything that depends on those belongs in envtest.

## envtest

envtest downloads the API server and etcd binaries; it does not need a cluster.

```console
go install sigs.k8s.io/controller-runtime/tools/setup-envtest@latest
setup-envtest use 1.31.x -p path          # prints the assets dir
export KUBEBUILDER_ASSETS="$(setup-envtest use 1.31.x -p path)"
go test ./... -count=1
# kubebuilder scaffold equivalent, which also runs manifests/vet:
make test
```

The suite installs your CRDs from disk, so schema and CEL failures surface here:

```go
testEnv := &envtest.Environment{
    CRDDirectoryPaths:     []string{filepath.Join("..", "..", "config", "crd", "bases")},
    ErrorIfCRDPathMissing: true,
}
cfg, err := testEnv.Start()
```

With a conversion or validating webhook, envtest must host it: `WebhookInstallOptions` writes certs and rewrites the CRD's `caBundle` and `conversion.webhook.clientConfig`. Without that, applying a second served version fails at the first read.

What envtest still does not do: run garbage collection. An owned child is **not** deleted when the CR goes away, so a test that depends on cascade deletion must delete the child itself. `deletionTimestamp` and finalizer blocking are real — the API server enforces those.

## Table-driven reconcile tests

Shape the test around the reconcile contract, not around the code:

```go
for _, tc := range []struct{
    name    string
    objects []client.Object
    req     ctrl.Request
    want    []client.Object          // full expected child set
    wantRes ctrl.Result
    wantErr bool
}{ ... } { ... }
```

Assertions worth making every time:

- **Idempotency** — call `Reconcile` twice; the second call must return the same result and produce no writes. Count writes with an interceptor rather than diffing afterwards, because a needless write still returns the same end state.
- **Requeue decision** — compare `ctrl.Result` exactly; a missing `RequeueAfter` where the design expects polling is invisible in the object graph.
- **Deletion path** — set `deletionTimestamp` with the finalizer present and assert the external cleanup was requested and the finalizer is removed only once the cleanup reports done.
- **Condition text** — assert `reason`, not prose; prose changes break tests for no reason.

`Eventually`/`await_condition` semantics: use them only in envtest and kind tests, where a controller or the API server acts asynchronously. In a unit test, `Reconcile` is synchronous — an `Eventually` there hides a real ordering bug behind a timeout.

```go
Eventually(func(g Gomega) {
    g.Expect(k8sClient.Get(ctx, key, child)).To(Succeed())
    g.Expect(*child.Spec.Replicas).To(Equal(int32(3)))
}, 10*time.Second, 250*time.Millisecond).Should(Succeed())
```

Poll on a predicate with both a timeout and an interval; never `time.Sleep`.

## kind e2e

kind gives a real cluster on a real kernel with a real controller-manager and GC, which is where owner references, finalizers and watches actually get exercised.

```console
kind create cluster --name e2e --image kindest/node:v1.31.0
docker build -t example/thing-operator:dev .
kind load docker-image example/thing-operator:dev --name e2e
kubectl apply -f config/crd/bases/example.com_things.yaml
kubectl apply -k config/default                     # or: helm install
kubectl -n thing-system rollout status deploy/thing-controller --timeout=120s
kubectl apply -f config/samples/example_v1alpha1_thing.yaml
kubectl wait --for=condition=Ready thing/sample --timeout=120s
kubectl get deployments -n default -l app.kubernetes.io/managed-by=thing-operator
```

`kind load docker-image` matters: a locally built image is not in the registry the cluster pulls from, and a `latest` tag with `imagePullPolicy: Always` silently runs an old one.

The upgrade test is the one people skip:

```console
# 1. install the previous CRD + controller, create a CR
kubectl apply -f dist/v1alpha1/crd.yaml
kubectl apply -f config/samples/example_v1alpha1_thing.yaml
# 2. upgrade
kubectl apply -f dist/v2/crd.yaml
kubectl set image deploy/thing-controller manager=example/thing-operator:next -n thing-system
kubectl rollout status deploy/thing-controller -n thing-system
# 3. prove the object survived the storage version
kubectl get crd things.example.com -o jsonpath='{.status.storedVersions}{"\n"}'
kubectl get thing sample -o yaml | grep -E 'observedGeneration|status:'
kind delete cluster --name e2e
```

If `storedVersions` still lists the old version and you intend to drop it, the migration step runs here, before the version is removed.

## Rust / kube-rs

There is no envtest binding for kube-rs, so the layers collapse to unit tests with a mock `Api` (or a trait you define around the client) and a kind-based integration test.

```console
cargo test
cargo clippy --all-targets -- -D warnings
kubectl apply -f config/crd/bases/example.com_things.yaml
cargo run --bin controller &                 # or a container image loaded as above
kubectl apply -f config/samples/thing.yaml
kubectl wait --for=condition=Ready thing/sample --timeout=120s
```

For assertions on the cluster, `kube::runtime::wait::await_condition` plus `tokio::time::timeout` gives the same predicate-and-deadline shape as `Eventually`:

```rust
let ready = kube::runtime::wait::await_condition(api.clone(), "sample", conditions::is_cr_ready());
tokio::time::timeout(Duration::from_secs(120), ready).await??;
```

Mark cluster tests `#[ignore]` and run them behind an env var (`KUBE_INTEGRATION=1 cargo test -- --ignored`) so `cargo test` stays fast and hermetic.

If the CI has Docker but no kind, `kind` in CI is still the cheapest way to get real GC — an in-process fake cannot delete an owner-referenced child, so a finalizer test against a fake proves only that the code asked.

## Checklist

- A unit test asserts that a second reconcile performs zero writes.
- envtest installs the CRDs from disk with `ErrorIfCRDPathMissing`, so a broken schema fails the suite.
- Defaults, CEL and conversion are tested in envtest, never asserted against the fake client.
- The kind test builds and loads the image, then waits on a condition rather than sleeping.
- The upgrade test starts on the previous CRD version and checks `status.storedVersions` after the rollout.
- Every layer has a sentence naming what it cannot prove, next to its output.
