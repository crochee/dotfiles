**Load this reference when:** the repository is Rust with kube-rs — the `CustomResource` derive, `Controller`, `Action`, `Api`/`ApiExt`, status patches, the finalizer helper, conditions, stores, or leader election.

# Rust: kube-rs

kube-rs is a library, not a manager: there is no scaffold, no `main.go` to edit, and no leader election built in. You compose the runtime yourself, which means the invariants from the reconcile reference are your responsibility rather than a framework default.

## Crates

|Crate |Role |
|---|---|
|`kube` (features `runtime`, `derive`, `client`) |client, watcher, `Controller`, `Api`, finalizer helper |
|`k8s-openapi` (one `v1_3x` feature) |generated types; the feature must match the cluster's minor or newer |
|`schemars` |`JsonSchema` derive that produces the CRD's structural schema |
|`serde`, `tokio`, `thiserror`, `tracing` |the rest |

Two version constraints bite: exactly one `k8s-openapi` feature may be enabled, and `kube`'s minor decides the runtime API shape (`Controller::new` takes `ListParams` before roughly 0.90 and `watcher::Config` after). Read `Cargo.lock`, not the docs site.

## The custom resource

```rust
#[derive(CustomResource, Serialize, Deserialize, Clone, Debug, JsonSchema)]
#[kube(
    group = "example.com",
    version = "v1alpha1",
    kind = "Thing",
    plural = "things",
    shortname = "th",
    namespaced,
    status = "ThingStatus",
    printcolumn = r#"{"name":"Ready","type":"boolean","jsonPath":".status.conditions[?(@.type=='Ready')].status"}"#
)]
#[serde(rename_all = "camelCase")]
pub struct ThingSpec {
    pub replicas: i32,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub image: Option<String>,
}
```

- `Option<T>` plus `#[serde(default)]` is what makes a field optional in the generated schema. A bare `String` is required, and a required field added to a served version breaks every stored object.
- `#[kube(validation = "cel")]` turns `#[x_kube(validation = "self.min <= self.max")]` attributes into `x-kubernetes-validations`. This is the only way to get CEL from a derive; anything the derive cannot express goes into the YAML by hand or a webhook.
- `#[kube(schema = "disabled")]` omits the structural schema — a non-structural CRD the API server will reject unless you replace it. Do not use it to silence a `JsonSchema` derive failure; fix the type.
- `#[kube(scale = r#"{"specReplicasPath":".spec.replicas","statusReplicasPath":".status.replicas"}"#)]` adds the `/scale` subresource.
- The CRD itself comes from `Thing::crd()` (`kube::CustomResourceExt`); a small `crdgen` binary that serialises it to YAML is the usual way to keep `config/crd/bases` in step with the code.
- Types nested in the spec still need `JsonSchema`; `HashMap<String, String>` is fine, `serde_json::Value` is not structural.

Status is a separate struct, stored under `status`, never mixed into the spec.

## Controller and Action

```rust
use kube::runtime::{
    controller::{Action, Config, Controller},
    watcher,
};

async fn reconcile(thing: Arc<Thing>, ctx: Arc<Context>) -> Result<Action, Error> {
    // converge...
    Ok(Action::requeue_after(Duration::from_secs(300)))
}

fn error_policy(thing: Arc<Thing>, err: &Error, ctx: Arc<Context>) -> Action {
    Action::requeue(Duration::from_secs(30))
}

Controller::new(api_things, watcher::Config::default())
    .owns(api_deployments, watcher::Config::default())
    .watches(api_secrets, watcher::Config::default(), |secret| {
        // return ObjectRef<Thing>s this Secret affects
    })
    .with_config(Config::default().concurrency(4))
    .run(reconcile, error_policy, Context::new(client.clone()))
    .for_each(|res| async move { /* log the outcome */ })
    .await;
```

`Controller::new` watches the primary type; `.owns()` adds a watch on children whose `ownerReferences` point at the CR (and, unlike controller-runtime, does **not** create the reference — you copy `thing.controller_owner_ref(&())` from `ResourceExt` into the child's `owner_references`); `.watches()` maps an unrelated object back to CRs.

The snippet needs `futures::StreamExt` (or `TryStreamExt`) in scope for `.for_each`, and the error policy is a plain `fn` returning `Action` — not a future, because the controller must decide the delay synchronously.

| Action | Meaning |
|---|---|
|`await_change()` |finished; wake on the next event — the normal steady state |
|`requeue(d)` / `requeue_after(d)` |wake again in `d`; the two names are historical aliases, use one consistently |
|`delete()` |drop this object from the controller's store (the CR is gone) |

The error policy is where requeue-on-failure lives. kube-rs applies **no** exponential backoff of its own in the default setup, so a fixed `requeue(30s)` on every error is a permanent 30-second retry storm for a permanently failing object. Either keep a per-object failure counter in the `Context` and double the delay, or distinguish permanent errors and return `await_change()` with a `Ready=False` condition set.

## Context and Api

`Context` is a plain struct wrapped in `Arc`, passed to every reconcile. Put the client, the recorder and configuration in it; do not reach for globals, which is what makes the reconcile testable.

`Api<T>` is the typed handle: `Api::all(client)`, `Api::namespaced(client, ns)`, `Api::default_namespaced(client)`. Reads go through the client's internal cache only if you built one; by default `Api::get` is a direct call, so a `Store` (below) is how you avoid API traffic in a loop.

Writes:

```rust
use kube::api::{Patch, PatchParams, PostParams};

api.patch("name", &PatchParams::default(), &Patch::Merge(&json!({
    "status": { "conditions": conditions }
}))).await?;

// status subresource, last-writer-wins on the fields you send
api.patch_status("name", &PatchParams::default(), &Patch::Merge(&json!({"status": status}))).await?;

// status subresource, optimistic concurrency: 409 Conflict when resourceVersion moved
if let Err(e) = api.try_update_status("name", &PostParams::default(), &status).await { /* retry */ }
```

`patch_status` with `PatchParams::apply("field-manager")` (server-side apply) avoids the conflict loop entirely when you own the whole status object; `try_update_status` gives you real optimistic concurrency and must be retried **after re-fetching the object** — retrying the same `resourceVersion` fails identically.

## Finalizer helper

```rust
use kube::runtime::finalizer::{finalizer, Event};

let api: Api<Thing> = Api::all(ctx.client.clone());
finalizer(&api, "example.com/thing-cleanup", thing, |event| async {
    match event {
        Event::Apply(thing) => apply(thing, &ctx).await,
        Event::Cleanup(thing) => cleanup(thing, &ctx).await,
    }
})
.await
```

The helper implements the ordering the finalizer reference describes: it patches the finalizer in before calling `Apply`, and removes it only after `Cleanup` returns `Ok`. That is why `Apply` must be safe when the finalizer was just added, and why `Cleanup` must return `Err` whenever work remains — an early `Ok` on the cleanup path removes the finalizer and leaks the resource. `Cleanup` runs only when `deletionTimestamp` is set; `Apply` never runs on a terminating object.

## Conditions

kube-rs ships a condition type and helpers for the standard shape (`type`, `status`, `reason`, `message`, `last_transition_time`, `observed_generation`). The module path moved between minors — `kube::core::conditions` in older releases, `kube::runtime::conditions` in current ones — so confirm against `cargo doc` for the locked version rather than against a blog post.

What matters regardless of path:

- Store `Vec<Condition>` under `status.conditions`, not a bespoke enum.
- Use the provided constructor so `last_transition_time` changes only when `status` does; hand-rolling it produces a timestamp that flaps on every reconcile.
- Set `observed_generation` from `thing.metadata.generation` after the work for that generation is done.
- Compute `Ready` as the conjunction and write it last.
- `k8s_openapi::apimachinery::pkg::apis::meta::v1::Condition` exists and serialises correctly, but has no transition-time maintenance — prefer the runtime type for anything you construct.

## Store and watcher

```rust
use kube::runtime::{reflector, watcher, Store};

let store: Store<Thing> = Store::new(&api);
let stream = reflector(store.clone(), watcher(api.clone(), watcher::Config::default()));
tokio::spawn(async move { while stream.next().await.is_some() {} });

if let Some(thing) = store.get(&ObjectRef::new("sample").within("default")) { /* Arc<Thing>, with the store read trait in scope */ }
```

`Store` is the equivalent of an informer cache: `get_state()` for everything, `get(&ObjectRef)` for one object. It is stale exactly like the Go cache — a read immediately after a write can return the previous object — and it hands out `Arc<T>`, so mutating through it is a shared-state bug. The `Controller` keeps its own internal store; a second `Store` is only for other consumers (an aggregated API, a scheduler, an HTTP server exposing the CRs). The snippet also needs `futures::StreamExt` for `.next()` and `ObjectRef` imported from whichever module the locked minor exports it from.

## Leader election

kube-rs provides none, so pick one deliberately:

- **One replica**, with `replicas: 1` in the Deployment and a note in the deliverable. Honest, and correct for small clusters.
- **Lease-based lock**: a `coordination.k8s.io/v1` `Lease` with `holder_identity` (pod name), `lease_duration_seconds`, `renew_time`. Acquire or renew, run the `Controller` future only while holding it, and drop the future when a renewal fails so the standby stops writing. The `kube-leader-election` crate implements the loop; the details that matter are the same as in Go — renew well inside the duration (a third), one lease name per operator, and an identity that differs per replica.

Note what dropping the future does and does not do: it stops new events, and an in-flight reconcile is cancelled at its next `.await`, which may be mid-write. A lease has a drain window for that reason — stop accepting, let the in-flight reconcile finish, then release.

## Testing

There is no fake client and no envtest binding, so the split is different from Go:

- **Pure functions** for desired state, naming, and condition computation: `#[test]`, no cluster.
- **`#[tokio::test]` with a mock `Api`** where the type permits, or a thin trait around the operations the reconcile needs (create/patch/delete child) that a test implementation records.
- **A kind cluster** for everything real: `kubectl apply` the generated CRD, `cargo run --bin controller`, apply a sample, `kubectl wait --for=condition=Ready`. Mark these `#[ignore]` and gate them on an env var.
- Assertions on the cluster use `kube::runtime::wait::{await_condition, conditions::is_cr_ready}` inside `tokio::time::timeout`.

`cargo clippy --all-targets -- -D warnings` before a review: most kube-rs mistakes (holding a `TempDir` guard across an await, unbounded channels, `unwrap` on API errors) are lints rather than runtime surprises.

## Pitfalls

- `k8s-openapi` feature and cluster minor disagree: deserialisation drops fields silently or fails on unknown ones.
- CEL written by hand in the YAML while the derive regenerates the CRD: `crdgen` overwrites it. Express it with `x_kube` or keep the CRD out of generation.
- `owns()` without `owner_ref`: no child events, no cascade.
- Error policy returning `requeue` unconditionally: a hot loop for a permanently invalid spec.
- `try_update_status` retried without re-fetching: a guaranteed second conflict.
- Cloning the client per reconcile is cheap (it is an `Arc` inside); cloning the `Api` per call is also fine — recreating the `Client` per reconcile is not.
- Mutating an `Arc<Thing>` obtained from a store.
