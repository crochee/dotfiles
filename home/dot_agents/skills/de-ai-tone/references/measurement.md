**Load this reference when:** reporting a scan score, deciding whether a hit is a false positive, or agreeing a pass threshold with a reviewer.

# Measurement

`scripts/scan.py` is a phrase linter. It matches a fixed, documented list of tells, one category at a
time, and reports where they land. That is all it does, and all its numbers mean.

## What a scan proves, and what it does not

| The scan proves | The scan does not prove |
|---|---|
| These exact patterns appear on these lines, at this commit. | That a model wrote the text. A person can write "it is important to note that" all day. |
| The count fell between two runs on comparable text. | That the rewrite reads better. Only a reader can say that. |
| No quoted-from-the-source tell was missed by accident — the list is deterministic. | That the remaining prose is good, or that the rewritten claims are true. |
| A category is absent. | That a sentence in that category's spirit is absent: most tells have variants the lexicon does not carry. |

Two consequences. First, never present a clean scan as evidence of authorship or quality; present it
as evidence that a specific, rerunnable check passed. Second, a hit is a question, not a verdict —
the keep-or-kill tables in `SKILL.md` decide, and the decision is recorded.

## Units and rate

The score line reports:

```
score: <distinct lines flagged> distinct lines flagged; <hits> occurrences; <units> units (<words> words + <cjk> CJK characters); rate <n> per 1000 units
```

- **Distinct lines** is the headline number: one hedge-stuffed sentence counts once, however many
  patterns it trips. It is the number a threshold is set on.
- **Occurrences** counts every match, so it shows whether the remaining hits cluster.
- **Units** is Latin word tokens plus CJK characters. Chinese has no whitespace tokenisation that two
  tools agree on, so a character is the only stable unit; mixing scripts in one document is fine
  because both contribute one unit each.
- **Rate** is occurrences per 1,000 units. Use it to compare documents of different length, and only
  within the same language mix — 10 hits per 1,000 English words and 10 per 1,000 Chinese characters
  are not the same density.

Fenced code blocks are excluded from both scanning and units. Inline code is masked before matching
(so `not just X but Y` inside backticks does not fire) but still counts toward units, because it is
part of a prose sentence.

## Reporting a score

Report the command, the input and both runs. A single number with no baseline is not a measurement.

```console
$ python3 scripts/scan.py draft.md; echo exit=$?
score: 9 distinct lines flagged; 21 occurrences; 612 units (410 words + 202 CJK characters); rate 34.3 per 1000 units
draft.md:4: hedge-stacking: It is important to note that
...
exit=1

$ python3 scripts/scan.py draft.md; echo exit=$?
score: 1 distinct lines flagged; 1 occurrences; 648 units (430 words + 218 CJK characters); rate 1.5 per 1000 units
draft.md:57: not-just-x: not just faster, but
exit=1
```

Accepting a surviving hit needs a reason, not a shrug: "line 57 keeps the construction because the
sentence contrasts the old and new scheduler, and the contrast is the paragraph's argument." Put
that sentence in the before-after table's `Reason` column.

## False positive classes

The patterns are deliberately narrow — multi-word phrases and closed lexicons — but five classes of
false positive survive, and all five are legitimate keeps.

| Class | Example | Handling |
|---|---|---|
| Quoted text | A draft quoting "In today's fast-paced landscape" as a bad example | Keep; mark the line `scan: ignore` and say it is a quote. |
| Code and identifiers | A function named `unlock_potential`, a log line containing "leverage" | Keep; the line is data. Mark ignore if it is prose-adjacent. |
| Legitimate enumeration | "powerful, readable, and tested" in a review of a library | Judge: the lexicon only carries marketing adjectives, so this should not fire; if it does, say why the three items differ. |
| Load-bearing construction | "It's not just a cache but a write buffer" where the contrast is the design decision | Keep; record the contrast as the reason. |
| Domain meaning | "leverage" in a finance document, "维度" as a measured axis, "robust" in statistics | Keep; the word carries its technical sense. |

Suppression is per line and per category:

```markdown
The old copy read "unlock the power of your data". <!-- scan: ignore translated-diction -->
```

Never add a blanket ignore to a file, and never suppress a category for a whole document: a
document-level suppression turns the gate into a no-op and hides regressions behind it.

## Pass thresholds

| Situation | Threshold |
|---|---|
| New prose, before publishing | 0 hits. Any hit is either rewritten or explicitly justified. |
| Rewriting an existing document | Final distinct lines ≤ one third of the baseline, and no category repeated more than twice per section. |
| House documentation, ongoing | ≤ 1 occurrence per 1,000 units, no category above 0.3 per 1,000. |
| A document you did not write and cannot edit | Report the score and the top three categories; do not rewrite without the owner. |

The thresholds are about the document, not the author. A legal notice that scores high and must not
change is a report, not a failure.

## Acceptance rule

**Hits fall and no claim changes.** Both halves are required:

1. The final scan has fewer distinct flagged lines than the baseline, and the command output is
   attached.
2. Every number, date, identifier, proper noun and modal qualifier in the rewrite appears in the
   original, with the same meaning. Diff them mechanically — sort the numeric tokens of both
   versions and compare; read the qualifiers by hand.
3. Every surviving hit has a reason in the log, and every rewrite row records whether precision was
   kept.

A lower score with a lost figure fails the second test. Deleting a hedge that carried the only
statement of an untested limit is the most common way this happens; the rewrite-playbook's precision
rule exists to stop it.
