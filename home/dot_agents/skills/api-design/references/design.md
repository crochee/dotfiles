# Design

**Load this reference when:** the resource model, a vocabulary or naming question, resource
granularity, the contract document's shape, or a design review scorecard.

## One vocabulary

An API speaks one language: the domain's. Each concept gets one word, spelled the same way in the
path segment, the field names, the error catalogue, and the prose. A small transport vocabulary
(`id`, `type`, `status`, `created_at`) sits on top; everything else belongs to the domain.

**Rule:** one term per concept, one concept per term. The first half forbids synonyms; the second
forbids one word doing two jobs.

**Test:** pick any domain noun and search the whole contract — paths, schemas, examples,
catalogue, prose. It must appear under exactly one spelling. `role_policy_bindings` in one path
and `rolePolicyBindings` in another fails even though both spellings are valid: the API now has
two words for one thing.

Two failures:

- **Two words for one concept.** `/invoices` and `/bills` for the same relation force every client
  to learn which one is real; a client that guesses wrong gets a `404` on an endpoint that exists.
- **One word for two concepts.** `policy` for the permissions document and for the rule that
  grants it; a client holding `{"policy_id": 7}` cannot tell which one it has.

Both say the same thing: the reader's map of the domain no longer matches the server's. Fix it
with one word per concept, or a second, distinct word for the second concept.

## Resource granularity

Everything an API exposes is a resource, a field, a sub-resource, or an action. Apply the ladder
in order; the first rung that matches decides:

1. **Independent lifecycle** — created, changed, and retired on its own schedule → its own
   resource.
2. **Independent authorization decision** — access is granted by a different rule than its
   parent's → its own resource.
3. **Independently queryable** — a client lists or filters it without its parent → its own
   resource.
4. **Own identifier** — referenced by id from somewhere else → its own resource.
5. **Otherwise** — a field of its parent, or a sub-resource reached only through it.

The rungs are ordered because the first is strongest: a thing with its own lifecycle usually has
its own identifier, but the reverse is false — a `user_id` column is still a field. Rung 2 is the
one teams skip: a permission check that can differ from the parent's is enough to make something a
resource.

**Collection or singleton.** A resource is a collection when a client may hold more than one and
the API must list them; it is a singleton when there is exactly one per parent, addressed by a
fixed name (`/v1/users/me`). A singleton is a member of its parent's collection, spelled as a
reserved name, and never takes an identifier of its own.

**Relation resources.** A binding, a membership, or a grant is a resource whose fields are all
references to other resources. Expose `GET`, `POST`, and `DELETE`, deliberately not `PUT`:
replacing a relation's body would let a caller graft one side onto another. The relation is
created with its two references and deleted; it is never rewritten. A duplicate relation is
`409`.

**Sub-resource or top-level collection.** Model a relation as a sub-resource of one side when it
only makes sense with that side present and is queried through it
(`/v1/users/{user_id}/memberships`). Model it as a top-level collection when it is queried across
parents — it appears in its own list, carries its own pagination, or is deleted by its own
identifier. A top-level collection needs a filter that names the parent.

## Naming

Casing and private request-header fields are recorded conventions — see
[conventions](conventions.md). The remaining rules make the vocabulary mechanical:

1. **Collections are plural nouns; members are singular.** `/v1/users` and
   `/v1/users/{user_id}` — the identifier repeats the singular noun, not `{id}`.
2. **One collection noun per resource, everywhere.** The same resource is not `/users` in one
   endpoint and `/accounts` in another.
3. **Parameters, fields, and error codes come from the same vocabulary.**
4. **Verbs appear only for non-CRUD state transitions.** `POST /v1/users/{user_id}/suspend`
   carries a verb because suspension is a transition; a CRUD action gets a method, never a verb in
   the path.
5. **Extending the vocabulary means adding a word, not a synonym.** `audit_events` is a new word
   for a new thing; `user_audit_events` splits the vocabulary.
6. **No abbreviations unless they are already universal in the domain.** `id` is universal; `usr`
   is not.
7. **Check a new field name against the existing field vocabulary.** The failure this catches is
   `email` and `email_address` in the same response, silently doubling the client's mapping code.

## The document's own shape

The contract is a document a human reads before writing code, read as a whole. Its shape is part
of the contract.

- **One endpoint table, ordered by resource and then by verb.** The table is the API's index.
- **One worked example per endpoint, reusing the same fictitious data.** The same user id, role
  name, and timestamp in every example, so the document reads as one system.
- **The Purpose column says why, in one line, not what.** "What" is the method and path, already
  in the row.
- **Parameter tables are sorted the same way everywhere** — path parameters, then query
  parameters, then body fields, alphabetical within each group.
- **Section names are identical across endpoints** (Parameters, Request body, Success response,
  Error responses, Auth requirement, Idempotency), so a reader's eye knows where to look.
- **A `Conventions` section comes before the endpoint table.**
- **No endpoint is described in two places.** A rule that applies to every endpoint goes in a
  shared section.

## Design quality scorecard

A reviewer fills this in rather than only listing defects. It scores the design — vocabulary,
taxonomy, granularity, naming, document shape — and does not re-check the Output Contract, which
is checked there.

| Item | Criterion | Yes | No |
|---|---|---|---|
| 1. One vocabulary | One spelling per domain concept across paths, fields, codes, prose | | |
| 2. One error taxonomy | Catalogue grouped by cause, reads as prose, one meaning per code | | |
| 3. Right granularity | The ladder here was applied to every exposed thing, not skipped | | |
| 4. Naming extends | No synonym stands in for an existing term | | |
| 5. One document shape | One table, one conventions block, one section order | | |

Review mode also produces a findings table: `Severity | Location | Rule broken | Evidence | Fix`.
