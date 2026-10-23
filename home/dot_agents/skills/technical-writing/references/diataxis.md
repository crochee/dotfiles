**Load this reference when:** choosing between the four documentation modes, deciding
whether a page has mixed them, or splitting an existing page that tries to be several at
once.

# Diátaxis in practice

Four modes, two axes. A page belongs to exactly one mode; the mode is determined by the
reader's need, not by the page's subject or title.

## The two axes

Diátaxis separates documentation by what the reader is doing when they consult it.

|  | **Practical** — the reader wants to act | **Theoretical** — the reader wants to understand |
|---|---|---|
| **Learning** — competence is not yet acquired | **Tutorial**: a lesson that takes the reader from no working knowledge to a working result | **Explanation**: discussion of why the thing is the way it is |
| **Working** — competence is assumed | **How-to**: the steps for a goal the reader already understands | **Reference**: the complete, factual description of the machinery |

The axes are independent. A reader who is learning needs a path that holds their hand; a
reader who is working needs a lookup that does not. A reader who is learning needs the ideas
connected; a reader who is working needs the facts accurate. Collapsing any two of these
creates a page that serves neither reader, which is covered below.

## The four modes

### Tutorial

The reader arrives with no working knowledge and leaves with a result they made themselves.

- **Job:** build confidence through success. The reader's competence is not the input; it is
  the output.
- **Shape:** one linear path, no choices, every step produces a visible result. Start from a
  clean environment and say what that means. Show the expected output for each step,
  including the failure output of the step that is meant to fail.
- **Failure mode:** branching. "Choose one of three installation methods" hands the reader a
  decision they cannot yet make; the tutorial becomes a how-to with a lesson bolted on.
- **Second failure mode:** teaching after the fact. A five-paragraph aside on architecture
  in the middle of step 3 costs the reader the thread they were holding.

### How-to

The reader has a goal and the competence to pursue it; what they lack is the local knowledge
of this system.

- **Job:** get the reader from goal to done with the fewest decisions.
- **Shape:** the title is the goal ("Rotate a signing key without downtime"), not the
  subject ("Signing keys"). One path per task; options are mentioned only where the choice
  is unavoidable, and then with the default named.
- **Failure mode:** opening with prerequisites-and-concepts instead of the goal. The reader
  did not come to be taught; three screens before the first action reads as a paywall.
- **Second failure mode:** completeness. A how-to that lists every flag of every tool in the
  task has become a reference and lost the path.

### Reference

The reader is working, knows what they are looking for, and wants the exact fact.

- **Job:** be accurate, complete and scannable — in that order of priority when they
  conflict with readability.
- **Shape:** uniform structure. Every entry has the same fields in the same order, so the
  reader's eye knows where the answer will be. Alphabetical or logical order, never
  narrative order. Terse sentences, no connective tissue.
- **Failure mode:** tutorial leakage — "first, install…" inside a reference entry. The
  reader looking up one field must now skip a procedure to find it.
- **Second failure mode:** omission. A reference that documents the common parameters and
  says "and more" is not a reference; it is a how-to that lost its path.

### Explanation

The reader wants the reasoning: why this design, why this constraint, what the trade-off
was.

- **Job:** connect facts into a mental model, in the reader's terms.
- **Shape:** argumentative prose. It may be read out of order, so it links to other material
  instead of restating it. It is allowed to be long and allowed to have an opinion, as long
  as the opinion is labelled as one.
- **Failure mode:** procedure. A numbered list inside an explanation turns it into an
  incomplete how-to, and the reader who follows it gets lost at the first omitted step.
- **Second failure mode:** restating reference material. If a sentence could be copied into
  the reference unchanged, it belongs in the reference.

## Why mixing modes fails

Each mode makes a promise to its reader, and the promises are incompatible.

| Promise | Broken by |
|---|---|
| Tutorial: "follow this and you will have a result" | Any branch the reader is not equipped to choose |
| How-to: "this gets you to the goal" | Any explanation the reader must absorb before acting |
| Reference: "the answer is here, exactly" | Any narrative the reader must skip to reach the answer |
| Explanation: "you will understand why" | Any procedure the reader tries to follow |

The common failing page is **"Getting started"**: it installs the tool (tutorial), lists
every configuration key (reference), explains the architecture (explanation) and ends with a
migration recipe (how-to). Each of the four readers finds their material, and each pays for
the other three: the learner hits a table of keys, the reference user scrolls past
anecdotes, and the migration user is one bad copy-paste away from a wrong command because
the surrounding prose changed the meaning of the step.

The cost is not length. It is that a reader cannot tell, from any given paragraph, which
promise is in force — so they cannot tell whether a numeral is a step to execute or a value
to look up.

## Classifying a page

Read the first screen and answer these; the first answer that fits decides the mode.

| Signal | Mode |
|---|---|
| Title is a task the reader performs, steps are imperative, output shown after each | Tutorial, if the reader must make no choices; how-to if they must choose within a known goal |
| Title is a noun or a field name, entries are uniform, sentences are fragments | Reference |
| Opens with "why", "the reason", "compared with", no numbered steps | Explanation |
| Title is a goal, prerequisites are assumed, one path, no expected output per step | How-to |
| Imperative steps and undecided branches coexist | Mixed — split it |

A second test, cheaper than reading: count the connectives. Reference has almost none;
explanation is dense with them; a tutorial has "now", "you should see"; a how-to has "if".

## Splitting an existing page

1. **Tag every block.** Mark each paragraph, list and table with the question its reader
  brings: *do* (tutorial or how-to), *look up* (reference), *understand* (explanation).
2. **Group by tag, not by order.** Blocks of one tag that are scattered through the page
  belong together.
3. **Name each group by its question.** "Build a local cluster", "Configuration keys", "Why
  reconciliation is level-triggered". A group you cannot name by a question is a group that
  has not been classified yet.
4. **Split the do-blocks.** Imperative blocks that start from nothing are a tutorial; blocks
  that start from a stated goal and assume the reader are how-tos. If one page yields both,
  keep the tutorial and send the goal-oriented material to its own pages.
5. **Preserve every fact.** Move reference material verbatim before rewriting — a split that
  silently drops a parameter is worse than the mixed page it replaced.
6. **Add the entry point.** One index with a row per page: page, mode, reader, question
  answered. Readers navigate by their own need; the index is what makes the modes usable.
7. **Delete the old page.** Leave a redirect only where external links exist, and make the
  redirect name the destination page, not the site root.

## Review test per mode

Apply exactly one test to each page. Applying a second mode's test to a page is how mixed
pages get created in the first place.

| Mode | The question | What a pass looks like |
|---|---|---|
| Tutorial | Does it work from a clean environment? | Someone with none of the prerequisites installed reaches the stated result by following it top to bottom, with no external knowledge |
| How-to | Does it start from a goal? | The first screen states the outcome and the first action; the reader who has that goal needs no other page |
| Reference | Is it complete and scannable? | Every parameter, field or error is present, and any entry can be found by scanning the same position in each block |
| Explanation | Does it answer *why*? | After reading, the reader can predict a case the page does not mention — the constraint generalises |

The tutorial test is the expensive one: actually run it in a clean container. A tutorial
reviewed by reading is a tutorial whose step 4 fails on a missing dependency, a version skew
or an unstated prerequisite.
