**Load this reference when:** the repository is Go with `controller-runtime` — scaffolding, wiring `main.go`, writing the controller, patches, watches, events, or reviewing an operator-sdk layout.

# Go: kubebuilder and controller-runtime

`controller-runtime` is the library; kubebuilder is the scaffold that wires it. Everything in this reference is the library's API surface, so it applies to any Go project that imports it, with or without the scaffold.

## Scaffold layout

```text
PROJECT                          scaffold metadata, read by `kubebuilder edit`
Makefile                         install / run / manifests / generate / test / deploy
cmd/main.go                      manager construction and wiring
api/v1alpha1/thing_types.go      types, deepcopy, markers
api/v1alpha1/zz_generated.*.go   generated — never edit
internal/controller/thing_controller.go
internal/controller/suite_test.go        envtest harness
config/crd/bases/                generated CRDs
config/rbac/role.yaml            generated from markers
config/manager/, config/default/, config/samples/
```

`go/v3` scaffolds use `apis/` and `controllers/` instead of `api/` and `internal/controller/`, and `main.go` at the root. The library API is identical; only the paths move.

`PROJECT` is not decoration — `kubebuilder create api` and `edit` rewrite it as they add resources. A hand-written `PROJECT` that disagrees with the tree makes the next scaffold command produce files in the wrong place.

```yaml
domain: example.com
layout:
- go.kubebuilder.io/v4
projectName: thing-operator
repo: example.com/thing-operator
resources:
- api:
    crdVersion: v1
    namespaced: true
  controller: true
  group: infra
  kind: Thing
  version: v1alpha1
version: "3"
```

## main.go

```go
var (
    scheme   = runtime.NewScheme()
    setupLog = ctrl.Log.WithName("setup")
)

func init() {
    utilruntime.Must(clientgoscheme.AddToScheme(scheme))
    utilruntime.Must(v1alpha1.AddToScheme(scheme))       // the CR's own types
}

func main() {
    var metricsAddr, probeAddr string
    var enableLeaderElection bool
    flag.StringVar(&metricsAddr, "metrics-bind-address", "0", "metrics endpoint")
    flag.StringVar(&probeAddr, "health-probe-bind-address", ":8081", "probe endpoint")
    flag.BoolVar(&enableLeaderElection, "leader-elect", false, "enable leader election")
    opts := zap.Options{Development: false}
    opts.BindFlags(flag.CommandLine)
    flag.Parse()

    ctrl.SetLogger(zap.New(zap.UseFlagOptions(&opts)))

    mgr, err := ctrl.NewManager(ctrl.GetConfigOrDie(), ctrl.Options{
        Scheme:                 scheme,
        Metrics:                metricsserver.Options{BindAddress: metricsAddr},
        HealthProbeBindAddress: probeAddr,
        LeaderElection:         enableLeaderElection,
        LeaderElectionID:       "thing-operator.example.com",
    })
    if err != nil { setupLog.Error(err, "unable to start manager"); os.Exit(1) }

    if err := (&controller.ThingReconciler{
        Client:   mgr.GetClient(),
        Scheme:   mgr.GetScheme(),
        Recorder: mgr.GetEventRecorderFor("thing-controller"),
    }).SetupWithManager(mgr); err != nil { setupLog.Error(err, "controller"); os.Exit(1) }

    _ = mgr.AddHealthzCheck("healthz", healthz.Ping)
    _ = mgr.AddReadyzCheck("readyz", healthz.Ping)
    if err := mgr.Start(ctrl.SetupSignalHandler()); err != nil { os.Exit(1) }
}
```

Leader election gates only the runnables that opt in: controllers stop on a standby replica, webhooks and probe endpoints keep serving — a standby that fails `/readyz` gets restarted in a loop and can never take over.

## Controller shape

```go
type ThingReconciler struct {
    client.Client
    Scheme   *runtime.Scheme
    Recorder record.EventRecorder
}

func (r *ThingReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
    log := logf.FromContext(ctx)

    var thing v1alpha1.Thing
    if err := r.Get(ctx, req.NamespacedName, &thing); err != nil {
        return ctrl.Result{}, client.IgnoreNotFound(err)   // a deleted CR is a success
    }
    // ... converge, then set status once
    return ctrl.Result{}, nil
}

func (r *ThingReconciler) SetupWithManager(mgr ctrl.Manager) error {
    return ctrl.NewControllerManagedBy(mgr).
        For(&v1alpha1.Thing{}).
        Owns(&appsv1.Deployment{}).
        WithEventFilter(predicate.GenerationChangedPredicate{}).
        WithOptions(controller.Options{MaxConcurrentReconciles: 4}).
        Complete(r)
}
```

`logf.FromContext(ctx)` carries the request's logger; a `logr.Logger` stored on the struct loses the reconcile identity that makes logs searchable.

## Client semantics

|Accessor |Reads |Writes |
|---|---|---|
|`mgr.GetClient()` |cache, except unstructured and objects excluded by `Cache.Options` |direct to the API server |
|`mgr.GetAPIReader()` |direct, every call |n/a — reader only |
|`client.New(cfg, opts)` |direct unless a cache is configured |direct |

Consequences worth knowing before debugging a stale read:

- Everything the manager caches is held in full for every type you `For`, `Owns` or `Watches`. A watch on Pods is a Pod informer.
- Reads are served by the cache and are not linearizable. After a write, `Get` may return the old object. Use `mgr.GetAPIReader()` for the few paths that need the current state, and keep those paths out of hot loops.
- `client.Options{Cache: &client.CacheOptions{DisableFor: []client.Object{&corev1.Secret{}}}}` opts one type out of the cache instead of bypassing it call by call.
- Cached objects are shared pointers. Mutating one and passing it back to a write corrupts the cache — always `DeepCopy()` first.

## Writing

|Need |Call |
|---|---|
|Create if absent |`Get` → `Create` on `apierrors.IsNotFound`; or `CreateOrUpdate` |
|Own a field set, tolerate others |server-side apply: `Patch(ctx, obj, client.Apply, client.FieldOwner("thing-operator"), client.ForceOwnership)` |
|Change a few fields |`base := obj.DeepCopy()`, mutate, `Patch(ctx, obj, client.MergeFrom(base))` |
|Conditional on `resourceVersion` |`client.MergeFromWithOptions(base, client.MergeFromWithOptimisticLock{})` |
|Status |`r.Status().Update(ctx, &thing)` or `r.Status().Patch(...)` |
|Owner reference |`controllerutil.SetControllerReference(&thing, child, r.Scheme)` |

`controllerutil.CreateOrUpdate(ctx, r.Client, obj, mutateFn)` returns `OperationResult` (`Created`, `Updated`, `Unchanged`) — use the last one to skip a status write when nothing moved. It does a `Get` inside, so it is safe to call every reconcile.

`Owns(&appsv1.Deployment{})` does **not** create the owner reference; it watches children whose controller owner reference points at the CR. Forgetting `SetControllerReference` gives a controller that never reacts to its own children and a GC that never deletes them.

## Watches and indexers

```go
ctrl.NewControllerManagedBy(mgr).
    For(&v1alpha1.Thing{}).
    Owns(&appsv1.Deployment{}).
    Watches(&corev1.Secret{}, handler.EnqueueRequestsFromMapFunc(r.mapSecretToThings)).
    Complete(r)
```

- `For` is the primary type: one update event per change, mapped to that name.
- `Owns` enqueues the owner for each child event and requires the controller owner reference.
- `Watches` for shared objects, with a map function that returns every CR the object affects. A map function that returns all CRs turns one Secret edit into N reconciles — index the reverse lookup instead.
- `EnqueueRequestsFromMapFunc` returning an empty slice is a no-op, which is how you filter.

Field indexers make the reverse lookup cheap:

```go
if err := mgr.GetFieldIndexer().IndexField(ctx, &v1alpha1.Thing{}, ".spec.configRef",
    func(o client.Object) []string { return []string{o.(*v1alpha1.Thing).Spec.ConfigRef} },
); err != nil { return err }
```

then `r.List(ctx, &list, client.MatchingFields{".spec.configRef": name})`. A test using the fake client needs the same index registered with `WithIndex`.

## Predicates

|Predicate |Filters |
|---|---|
|`GenerationChangedPredicate` |updates where only status/metadata changed — the default reason the loop stops being hot |
|`ResourceVersionChangedPredicate` |updates with the same `resourceVersion` (no-op resyncs) |
|`LabelChangedPredicate` / `AnnotationChangedPredicate` |updates where the selector or annotation set changed |
|`predicate.And` / `predicate.Or` |composition |

Predicates filter events, they do not skip work: a reconcile triggered by something else still converges everything. Keep the filtered-away writes out of the reconcile in the first place — the predicate only stops the re-entry.

## Events

```go
r.Recorder.Eventf(&thing, corev1.EventTypeWarning, "InvalidSpec",
    "replicas must be greater than zero, got %d", thing.Spec.Replicas)
```

- Emit on **state transitions**, not every reconcile. Events are aggregated and rate-limited, and a warning repeated each loop buries the one that mattered.
- The message is user-facing and goes into `kubectl describe`. Put the value and the constraint in it.
- Never put secret material in an event; events are readable by anyone who can read the namespace.
- A warning event is not a substitute for a condition. The event is a moment; the condition is the state.

## Status and conditions

```go
meta.SetStatusCondition(&thing.Status.Conditions, metav1.Condition{
    Type:               "Ready",
    Status:             metav1.ConditionTrue,
    Reason:             "Reconciled",
    Message:            "Deployment is available",
    ObservedGeneration: thing.Generation,
})
if err := r.Status().Update(ctx, &thing); err != nil { return ctrl.Result{}, err }
```

`meta.SetStatusCondition` updates `lastTransitionTime` only when `Status` changes. One `Status().Update` at the end of the reconcile, and only after comparing against what is stored.

## Testing scaffold

`internal/controller/suite_test.go` runs envtest with `CRDDirectoryPaths` pointing at `config/crd/bases`; `make test` regenerates manifests first, so a marker or type error fails the suite rather than production. The details, and what envtest cannot prove, are in the testing reference.

## operator-sdk differences

An operator-sdk project is a kubebuilder project plus OLM packaging. The reconcile code is unchanged; read everything above, then adjust for:

|Area |operator-sdk |
|---|---|
|Init |`operator-sdk init --domain example.com --repo example.com/op --plugins go/v4`, then `operator-sdk create api --group infra --version v1alpha1 --kind Thing --resource --controller` |
|Layout |`go/v4` matches kubebuilder v4 (`api/`, `internal/controller/`); `go/v3` uses `apis/`, `controllers/` |
|Extra directories |`bundle/` (OLM manifests), `config/manifests/`, `config/scorecard/`, `bundle.Dockerfile` |
|Makefile targets |`make bundle`, `make bundle-build`, plus the kubebuilder targets |
|Release |`operator-sdk generate bundle --version 0.1.0`, `operator-sdk run bundle`, `operator-sdk scorecard`, `docker build -f bundle.Dockerfile` |
|`PROJECT` |adds a `plugins` entry for the operator-framework manifest plugin |

Reviewing one, check the `bundle/manifests` copy of the CRD against `config/crd/bases` — a bundle generated before the last `make manifests` ships an old schema, and OLM installs from the bundle.

## Pitfalls

- Markers edited, `make manifests` not run: RBAC and CRD changes exist only in the source tree. The local fake client does not care; the cluster does.
- A child type missing from `scheme` panics at startup with "no kind is registered", usually after adding a `Watches` for a new type.
- `Owns` without `SetControllerReference`: no events, no cascade.
- Reading from `mgr.GetClient()` immediately after a write and acting on the stale value.
- Mutating an object returned by `Get` — it is the cache's copy.
- Returning the raw error for a permanently invalid spec: exponential backoff, warning events forever, no condition for the user.
- `controller-gen` version drift between the Makefile and CI, which produces manifest diffs nobody ordered.
