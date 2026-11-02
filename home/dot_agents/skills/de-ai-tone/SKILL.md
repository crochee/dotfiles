---
name: de-ai-tone
description: "Rewrites English or Chinese prose that reads as machine-generated, then proves the result with a rerunnable scan. Detects 44 numbered AI-writing patterns across six cause groups: not-X-but-Y contrasts, one-line closers, staged openers, forced triads, dash chains, hedge stacking, inflated significance, borrowed authority, decorative bold and emoji, chatbot residue, and the rest. Use when a draft, README, release note, report or article sounds like AI, when asked to remove AI flavour, de-slop, humanise, when a Chinese draft needs its AI flavour removed（去掉 AI 味、润色）, or when gating a document before publication. It edits prose only: facts, numbers, qualifiers, code and quotations survive. It is not for refactoring code, translating, answering questions, or reformatting data."
license: MIT
metadata:
  version: "2.1.0"
---

# De-AI Tone

Rewrites prose that reads as machine-generated, in English or Chinese, until a fixed and rerunnable
scan is clean — while every claim, number and qualifier in the source survives.

## When to Use

Three modes:

- **Rewrite** — a draft exists and sounds generated. Deliver a clean copy plus a change log.
- **Gate** — approve or reject without editing: run the scan, judge each hit, report.
- **Calibrate** — a template or house voice keeps producing slop. Patch the phrases it invites.

Typical triggers: "this reads like AI", "humanise this", "de-slop the README", "去掉 AI 味",
"润色得自然一点", or a pre-publish check on a document nobody has proofread.

It edits surface, not substance — facts, argument order, length and authorship are out of scope, and
structural editing belongs to `technical-writing`: this is the last pass.

## Workflow

1. **Identify the text type, the reader, and the delivery language.** Read the whole document once.
   Name the register (release note, design doc, README, incident report, marketing page), the reader,
   and the three to five sentences that carry the argument. Mark the segments that must not be
   touched: fenced code, error strings, identifiers, quotations, legal text, and a template's
   required headings and field labels — a PR or issue template's bold labels are structure, not
   emphasis. Then decide the **delivery language**: the input document's language; for a mixed
   Chinese–English draft, the conversation's language. A Chinese delivery loads
   `references/skill.zh.md` and `assets/before-after.zh.template.md` instead of the English pair.
   *Exit criterion:* you can state the register, the reader and the delivery language in one
   sentence, point at the spine sentences, and list the excluded segments.
2. **Scan and keep the baseline.** Run the scanner and save its output verbatim. Every hit carries a
   pattern number and a category token, for example `draft.md:12: A1 not-just-x: …`. The score
   line's first number — distinct flagged lines — is the headline; the rate compares documents of
   different length. Use `-` or no argument to scan stdin when the draft is unsaved.
   ```console
   python3 scripts/scan.py draft.md; echo exit=$?
   ```
   *Exit criterion:* the baseline score line, the hit list and the exit code are recorded, and you
   have written down the flagged line numbers.
3. **Load only the cause groups you need.** The 44 patterns are grouped by why a passage reads as
   machine-written. Open `references/patterns-<group>.md` for the groups the hits fall into (`.zh.md`
   for a Chinese delivery) — do not load all six. Each entry gives the watch-for phrases, the
   problem, a before/after pair and the playbook move that fixes it.
   *Exit criterion:* every flagged pattern number maps to a group you loaded, and its entry is open.
4. **Rewrite each hit with the playbook.** Work the eight moves in `references/rewrite-playbook.md`
   in order of payoff — delete first, then cut hedges, split, concretise. Each pattern entry names
   its move. Use the keep/kill table below for every hit that is not an obvious deletion.
   *Exit criterion:* every flagged line has a decision, and every rewrite names the concrete
   replacement — no synonym swap, and swapping `delve into` for `explore` is not a rewrite.
5. **Rescan, drive to zero or justify what stays, then log it.** Rerun the same command. Each
   surviving hit gets one sentence: which false-positive class it belongs to, or which fact would
   be lost by removing it. A line that must stay carries `scan: ignore <number or category> <reason>`
   inline — the marker accepts the category token (`not-just-x`) or the pattern number (`A1`), and
   markers written before v2 keep working. Fill the change log from the template: one row per
   change, location, before, after, category (`A1 not-just-x`), reason, precision kept. Then diff
   the numeric tokens and audit the qualifiers — `may`, `must`, `only`, `up to`, `at least`,
   `不超过` — between original and rewrite.
   *Exit criterion:* the final scan is recorded, every surviving hit has a reason a reviewer could
   check, and the claims check shows nothing introduced and nothing lost without explanation.

## The 44 patterns

44 numbered patterns in six cause groups: A staging (§A1–§A9) · B rhythm (§B1–§B14) · C inflation
(§C1–§C10) · D formatting (§D1–§D5) · E leftovers (§E1–§E5) · F wrong reader (§F1). Groups A and E
justify an edit on one sighting; the rest are *weak alone* and need company from other tells.

The ID → pattern → detector → category-token table is in `references/patterns-index.md`; the
per-pattern entries are in `references/patterns-<group>.md`.

## Quick Decisions

Which group the hits fall into — staging, rhythm, inflation, formatting, leftovers, wrong reader —
and the first move for each, is the table at the top of `references/rewrite-playbook.md`. The two
decisions below stay here, because they are made per hit, not per group.

Whether a hit stays:

| Hit | Keep when | Kill when |
|---|---|---|
| Any hedge | It names an untested range or an unknown condition | It decorates a fact you can state flatly |
| `not just X but Y` | X is the rejected alternative and Y the decision | Y restates X with more volume |
| `维度` / "dimension" | It is a measured axis with a scale | It is a synonym for "aspect" |
| `leverage` | Finance noun | Verb where "use", "call" or "run" is exact |
| Three-item list | Three items with different consequences | Three adjectives of the same family |
| Connective | A real relation follows it | It only marks the start of a paragraph |
| Bold | The term is defined here and used later | The word is merely important to the author |
| Quoted or domain-specific phrasing | It is a quotation, an identifier, or a term of art | It is the author's own praise |

## Output

**Rewrite mode** delivers:

- The rewritten document — state its path, and how the original can be recovered (`git diff`, or a
  `.orig` copy you created before editing).
- `before-after.md`, filled from `assets/before-after.template.md`: one row per change, the baseline
  and final scan blocks, the surviving-hits table, the claims check.
- The final scan output pasted verbatim with its exit code.

**Gate mode** delivers a verdict — pass or fail against the threshold in
`references/measurement.md` — the scan output, and a table of judged hits with the keep/kill reason.
No rewritten file.

**Calibrate mode** delivers the patched template plus two lists: the phrases removed, and the
replacement guidance a future writer should follow instead.

Every mode states the command that produced the score, the input path, and the date.

## Sources and licences

The pattern table absorbs two MIT-licensed projects: [`blader/humanizer`](https://github.com/blader/humanizer)
(MIT, © 2025 Siqi Chen) and [`nothing0here/humanizer-zh`](https://github.com/nothing0here/humanizer-zh)
(MIT, © 2026 nothing0here). Their upstream source is Wikipedia ["Signs of AI writing"](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing)
(CC BY-SA 4.0), linked here and not copied. The scanner and these documents are MIT licensed.

## References

| File | Load when |
|---|---|
| [references/patterns-index.md](references/patterns-index.md) | Placing a pattern number — the ID → pattern → detector → category-token table, and which groups act on one sighting. |
| [references/patterns-a.md](references/patterns-a.md) … [references/patterns-f.md](references/patterns-f.md), each with a `.zh.md` twin | A group's hits — A staging §A1–§A9, B rhythm §B1–§B14, C inflation §C1–§C10, D formatting §D1–§D5, E leftovers §E1–§E5, F wrong reader §F1. Load only the groups the hits fall into. |
| [references/rewrite-playbook.md](references/rewrite-playbook.md) / [references/rewrite-playbook.zh.md](references/rewrite-playbook.zh.md) | Turning hits into edits — the eight moves in payoff order and the technical-precision rule. |
| [references/measurement.md](references/measurement.md) / [references/measurement.zh.md](references/measurement.zh.md) | Reporting a score, setting a threshold, or deciding whether a hit is a false positive. |
| [references/skill.zh.md](references/skill.zh.md) | The delivery is in Chinese: this file is the Chinese entry point. |
| [assets/before-after.template.md](assets/before-after.template.md) / [assets/before-after.zh.template.md](assets/before-after.zh.template.md) | Filling the change log for a rewrite or a gate report. |
| [README.md](README.md) | Installing the skill, and the full 44-pattern table with Chinese names. |
| [AGENTS.md](AGENTS.md) | Changing the skill itself without breaking the package. |

## Verification Checklist

- [ ] The scanner was run on the final text and its output is pasted with the exit code, not summarised.
- [ ] The delivery language matches step 1, and a Chinese delivery loaded `references/skill.zh.md`.
- [ ] Distinct flagged lines fell against the baseline, and the result meets the threshold for the document type in `references/measurement.md`.
- [ ] Every surviving hit has a row under *Surviving hits* naming a false-positive class or the fact it protects.
- [ ] Every before/after row names the pattern number and category token (for example `A1 not-just-x`) or `judgement`, and a reason; no row says only "reworded".
- [ ] Numeric token diff is empty in both directions: no figure, date, identifier or proper noun was introduced or silently dropped.
- [ ] Every modal in the original (`may`, `must`, `only`, `up to`, `at least`, `不超过`) is either still present or its removal is justified in the log.
- [ ] No fenced code, error string, API name or quotation was edited.
- [ ] Every `scan: ignore` marker names a pattern number or a category token and sits on a line with a stating reason.
- [ ] Every sentence of the rewrite maps to a sentence in the original or is a split of one; no new claim appears.
- [ ] The scan was rerun after the last edit, so the reported score describes the delivered text.
