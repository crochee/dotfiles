**Load this reference when:** designing or reviewing a CRD — choosing versions, making the schema structural, adding defaulting, CEL validation, subresources, printer columns, conditions, or a conversion path.

# CRD Design

The API is the contract users keep after the controller is deleted. Everything here is enforced by the API server on write, which is the only validation that cannot be bypassed.

## Versioning

|Version |Promise |Use when |
|---|---|---|
|`v1alpha1` |nothing stable; fields may be renamed or removed |active design, no external consumer |
|`v1beta1` |schema stabilising; breaking changes need a migration note |one or two pilot consumers |
|`v1` |additive only forever |any consumer outside the team |

The cost of promotion is the conversion webhook plus the tests for it, so promote when a consumer appears, not for tidiness. Stay on `v1alpha1` while the state machine is still changing: renaming a field later requires conversion, and conversion requires an argument that it is lossless.

Rules that hold in every version:

- **Additive only inside a served version.** Adding an optional field is safe. Removing a field, changing its type, or moving it between `spec` and `status` breaks stored objects and needs a new version.
- **Never add a required field** to a version that already has stored objects — every existing object immediately fails validation. Use `+optional` with a default, or a new version.
- **Exactly one `storage: true`.** Everything else is served and converted.
- **A deprecated version carries `deprecated: true`** plus `deprecationWarning`, so `kubectl` prints the warning at the moment someone uses it.
- **`status.storedVersions` is a migration obligation, not a report.** Objects stay persisted at the version they were last written at. Dropping a version from `spec.versions` while it is still listed there leaves those objects unreadable through the new API. Migrate — a rewrite pass over the CRs, or `StorageVersionMigration` on clusters that have it — then confirm `storedVersions` lists only the version you intend to keep.

### Conversion

`spec.conversion.strategy` is `None` (schemas must then be identical across served versions) or `Webhook`.

- **Hub and spoke.** One version is the hub and stores everything; each other version converts to it and back. The hub must be lossless: every field in the old version has a home in the hub, even if the newer version never reads it.
- **Conversion must not default.** Defaulting runs per-version after conversion; a webhook that fills defaults writes data the client did not send and makes round-trips asymmetric.
- **Round-trip test.** old → hub → old must be deep-equal for every field the old version can express. This is the only test that catches a dropped annotation or an off-by-one in a renamed field.
- **The webhook is a availability dependency.** While it is down, reads of every non-hub version fail. That is the reason to retire old versions rather than serve them forever, and the reason `failurePolicy` is a decision you write down, not a default.

## Structural schema

A schema is structural when the API server can prune it: every node declares a type, and no node both validates and accepts arbitrary content. Consequences you meet immediately:

- Inside a subtree marked `x-kubernetes-preserve-unknown-fields: true`, unknown fields are kept and **validation does not apply below that point**. Marking the root that way opts the entire CR out of server-side validation.
- `additionalProperties: true` at a level that also declares `properties` is rejected. To accept a map of typed values, use `additionalProperties: {type: string}` with `maxProperties`; to accept a free object, preserve unknown fields deliberately and document why.
- No `anyOf` / `oneOf` / `$ref` at the root. Union-shaped data goes in a struct with an explicit discriminant field plus a CEL rule tying the two together.
- `x-kubernetes-int-or-string: true` is how a field accepts both a number and a string, typically a quantity or a port name.
- Pruning happens before validation: a typo in a field name is silently dropped, not rejected. Do not use the CRD as a typo detector — that is what a webhook or a CEL rule on a `spec` wrapper can do, at the cost of a second component.

**Nullability.** `+optional` means the field may be absent. A pointer (Go) or `Option` (Rust) is what makes absence representable, and it is what produces `omitempty` in the generated schema. A value type without `omitempty` generates `required` — this is the single most common cause of "existing CRs rejected after a schema edit".

**Defaults.** Defaults belong to `spec` only — a defaulted status field means the controller's own writes get rewritten under it. A default is applied at admission and then persisted, so changing it does not retroactively change stored objects; new objects get the new value and old ones keep the old. The default must itself validate against the field's schema, and a default on a field with `nullable: true` needs an explicit `default: null` if absence and null must differ.

## Subresources

|Subresource |Enables |Effect |
|---|---|---|
|`status` |`/status` writes |separates spec and status writes, so a status update cannot clobber a spec edit; `metadata.generation` bumps only on spec changes |
|`scale` |`/scale` reads and writes |exposes `spec.replicas` / `status.replicas` / `status.selector` so `kubectl scale` and HPAs work |
|none |full-object writes |every status write races spec writes and bumps `generation`; reserved for CRs with no status |

With the `status` subresource enabled, a plain object update **silently drops status changes**. Enable it before the first release; retrofitting it changes which writes succeed and breaks every client that relied on a full-object update.

`generation` semantics follow from that: if status is not a subresource, `generation` increments on every status write, and any condition keyed on it becomes meaningless.

## Printer columns

Printer columns are `additionalPrinterColumns` entries with `name`, `type` (`string`, `integer`, `number`, `boolean`, `date`), `JSONPath`, and optional `priority` (higher priority is hidden from the default view) and `description`.

- The JSONPath must select a scalar. Filter syntax is supported and is how a condition becomes a column: `.status.conditions[?(@.type=="Ready")].status`.
- Quote the type string with single quotes inside the JSONPath. A double quote inside a JSON string needs escaping and is the usual cause of a CRD that fails to apply with a parse error.
- The most useful set is small: the observed state, the age, and one thing the user would otherwise `kubectl get -o yaml` to see.
- A column over a field that is usually absent prints empty and teaches users to distrust the output. Pair it with a condition or leave it out.

## CEL validation

`x-kubernetes-validations` is a list of `{rule, message, messageExpression, reason, fieldPath}` evaluated by the API server after defaulting and schema validation. It is generally available from 1.29 and is the right place for cross-field invariants that a structural schema cannot express.

Use CEL for:

- **Cross-field requirements** — `self.minReplicas <= self.replicas`, or "exactly one of `image` and `imageRef`".
- **Transition rules** — a field that may change only in a legal direction; `oldSelf` is available, and it is only available in transition rules.
- **Immutability** — a rule of `self == oldSelf` on the field you are freezing. This is stronger than a webhook because nothing can bypass it.

Do not use CEL for anything that needs another object, a network call, or the cluster state. Those are webhook or reconcile concerns, and a rule that pretends otherwise either cannot be written or lies.

Operational rules:

- **`oldSelf` in a non-transition rule is rejected.** A rule that reads `oldSelf` must be satisfiable both when the object exists (old present) and when it is created (old absent) — the standard form is `!has(oldSelf.field) || predicate`. Newer clusters allow `optionalOldSelf: true` on the rule, which makes the "old value may be missing" case explicit; use it where it is available and keep the `has()` guard for portability.
- **Cost.** The API server estimates a cost per rule before admission and rejects a CRD whose estimate exceeds the budget. The usual offender is a rule ranging over a map or array whose size the schema does not bound: add `maxItems` / `maxProperties` so the estimate is finite, and prefer a rule over a scalar over a rule over a collection.
- **Ratcheting.** To allow existing objects to stay valid while tightening a rule, write the rule so the old value is exempt — `!has(oldSelf.spec) || newRule(oldSelf.spec, self.spec)` — rather than loosening the rule for everyone.
- **`message` is user-facing.** It appears in `kubectl apply` output; name the field and the violated constraint, and put the values in via `messageExpression` when they help.

## Status conditions

Conditions are the API for "what is the controller thinking". Use the standard shape — `type`, `status`, `observedGeneration`, `lastTransitionTime`, `reason`, `message` — rather than inventing a `status.phase` string, because every tool (Argo, Flux, `kubectl wait`, the dashboard an operator team inherits) already reads it.

|Rule |Why |
|---|---|
|Positive polarity: `Ready=True` |a consumer checks one boolean; `NotReady=False` inverts the reading of every alert |
|`lastTransitionTime` changes only when `status` changes |a churning timestamp hides the moment something actually broke |
|`reason` is CamelCase and stable; `message` is prose |alerts and docs key off `reason`, humans read `message` |
|One condition per concern, `Ready` set last |`Ready` is the conjunction; computing it before the parts settle produces a lie for one reconcile |
|`observedGeneration` = the generation the controller acted on |a consumer can distinguish "not reconciled yet" from "reconciled and broken" |
|Do not remove a condition to mean "not applicable" |absent and `Unknown` say different things to a consumer |

Server-side helpers (`meta.SetStatusCondition`, or the kube-rs conditions pipeline) maintain `lastTransitionTime` for you; hand-rolling it is how the field starts flapping.

**When to use `observedGeneration`:** always, on every condition. It costs one assignment and it is the difference between a user waiting for a rollout and a user filing a bug about a controller that already ran. It must come from the object the controller read, and it must only be recorded after the work for that generation is done — recording it optimistically makes the field worse than absent.

## Review questions

- Is every field in `spec` or `status`, and is anything in `spec` controlled by the controller? That is a fight with the user.
- Does adding this field break a stored object?
- Is this invariant expressible as CEL? If yes, it belongs there, not in a webhook.
- Does the CRD have `status` before the first release?
- Is the hub lossless, and is there a round-trip test?
- Does `kubectl get <kind>` answer the question the user actually has?
