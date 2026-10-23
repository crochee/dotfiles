**Load this reference when:** deriving a role from the code, reviewing a generated ClusterRole, or deciding between namespaced and cluster scope.

# RBAC

The controller's role is the blast radius of a bug in the controller. Derive it from call sites, generate it from markers, and review the generated file — the marker is what you meant, the YAML is what the API server enforces.

## From markers to a role

Go/kubebuilder uses `+kubebuilder:rbac` markers next to the reconciler; `make manifests` (or `controller-gen rbac:roleName=...`) writes `config/rbac/role.yaml`.

```go
// +kubebuilder:rbac:groups=example.com,resources=things,verbs=get;list;watch
// +kubebuilder:rbac:groups=example.com,resources=things/status,verbs=get;update;patch
// +kubebuilder:rbac:groups=example.com,resources=things/finalizers,verbs=update
// +kubebuilder:rbac:groups=apps,resources=deployments,verbs=get;list;watch;create;delete
```

Facts that trip people up:

- **`resources` and `subresources` are separate rules.** A `.../status` rule grants nothing on the parent object, and `get` on the parent does not imply `update` on its status.
- **`.../finalizers` with `verbs=update` is the grant for setting a finalizer on that resource.** Without it, adding a finalizer fails with `forbidden` while everything else works.
- **A marker without a matching call is a lie the diff will not catch.** Read the generated YAML against the code, not against your intent.
- **`config/rbac/role.yaml` is generated, never hand-edited.** A hand edit is overwritten at the next `make manifests`, and the marker set is then the only truth — which is why the marker set must be complete.
- Marker changes without regenerating produce a cluster-only failure: local tests use the fake client, which ignores RBAC entirely. That is the most common "works here, forbidden there".

For Rust there is no marker mechanism: the role is a manifest you write. Keep it next to the controller source and review it with the same questions below.

## Which verbs a path needs

|Call |Needed |
|---|---|
|`Get` on the CR |`get` on the CR resource |
|`List` with a field index |`list`, `watch` on the CR; the index is local |
|`Patch`/`Update` the CR's status |`update`, `patch` on `<resource>/status` |
|Add or remove a finalizer |`update` on `<resource>/finalizers` |
|`Create` a child |`get`, `create` on the child |
|`CreateOrUpdate` / `Apply` a child |`get`, `create`, `patch` on the child |
|`Delete` a child |`delete` on the child, plus `get` to confirm |
|Watch a child to map it back to CRs |`list`, `watch` on the child |
|Read a referenced Secret or ConfigMap |`get` on that resource (use `resourceNames` where possible) |
|`deletecollection` |nothing, unless the code truly enumerates by label |

`list` and `watch` are what register an informer. Every type the controller watches is held in memory in full: cluster-wide `list/watch` on Pods in a large cluster is gigabytes of cache and a real API-server load, no matter how little the controller reads. Prefer a narrow scope, an index, or a `metadata`-only selection.

## Scope

|Situation |Role kind |Why |
|---|---|---|
|CR is namespaced and the operator runs per namespace |`Role` + `RoleBinding` |smallest possible; the controller can only exist there |
|CR is namespaced but the operator is installed once and reconciles all namespaces |`ClusterRole` + `ClusterRoleBinding` for reads; a namespaced `Role` for writes is not possible without a per-namespace bootstrap, so write verbs stay in the ClusterRole and the code confines itself to the CR's namespace |the controller must see events everywhere to do its job |
|CR is cluster-scoped |`ClusterRole` + `ClusterRoleBinding` for everything it touches |scope follows the resource |
|CRs can be namespaced or cluster-scoped via a shared parent |the union |the code must handle both paths |

A cluster role for reads is a normal cost, but a cluster role for writes on a namespaced operator means a bug can rewrite any namespace. If the CR's spec can express "only my namespace", enforce that in the controller and say so in the review.

## Escalation

The API server refuses to create a role that grants more than the creator has, unless the creator holds `escalate` (for rules) or `bind` (for role bindings). A controller that creates RBAC for other users is therefore limited by its own permissions — and it must also limit what it copies from user input. Copying a `ClusterRole` reference from a CR into a `RoleBinding` is privilege escalation handed to whoever can write the CR; validate an allow-list of role names instead.

Reviewers should be able to answer, for every rule:

- Which function calls this verb?
- Why is the scope cluster-wide — is the CR cluster-scoped, or is this convenience?
- Could `resourceNames` replace the broad rule? (Only for `get`/`update`/`delete` on named objects, and only when the names are known ahead of time.)
- Is `secrets` read? If so, which secret, and what stops a CR from naming another tenant's?
- Is there a rule with `*` in groups, resources or verbs? `*` in `verbs` survives review and then silently widens when a new verb is added to Kubernetes.
- Does the service account have `create` on `roles`/`clusterroles` or `patch` on `serviceaccounts`? Those are escalation paths.

## Checklist

- Every verb in the generated role maps to a call site; every call site is covered by a verb.
- Status and finalizer subresources have their own rules where they are written.
- The role was regenerated after the marker change, and the diff was reviewed.
- Cluster-scoped rules are justified by the CR's scope, not by convenience.
- No `*` verbs, no unused resources, no `secrets` access beyond a named need.
- A controller that mints RBAC uses an allow-list rather than copying user-provided rules.
