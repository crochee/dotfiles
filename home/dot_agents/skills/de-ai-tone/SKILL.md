---
name: de-ai-tone
description: "Rewrites English or Chinese prose that reads as machine-generated until a rerunnable scan is clean: hedge stacking, list-itis, triadic padding, empty summaries. Use when a draft sounds like AI. Edits prose, not interfaces."
metadata:
  version: "1.0.0"
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
structural editing belongs to `technical-writing`; this is the last pass once the structure is
settled.

## Workflow

1. **Identify the text type and the reader.** Read the whole document once. Name the register
   (release note, design doc, README, incident report, marketing page), the reader, and the three
   to five sentences that carry the argument. Mark the segments that must not be touched: fenced
   code, error strings, identifiers, quotations, legal text, and a template's required headings and
   field labels — a PR or issue template's bold labels are structure, not emphasis.
   *Exit criterion:* you can state the register and the reader in one sentence, point at the spine
   sentences, and list the excluded segments.
2. **Scan and keep the baseline.** Run the scanner and save its output verbatim. The score line's
   first number — distinct flagged lines — is the headline; the rate compares documents of
   different length. Use `-` or no argument to scan stdin when the draft is unsaved.
   ```console
   python3 scripts/scan.py draft.md; echo exit=$?
   ```
   *Exit criterion:* the baseline score line, the hit list and the exit code are recorded, and the
   flagged line numbers are written down.
3. **Rewrite each hit with the playbook.** Work the eight moves in order of payoff — delete first,
   then cut hedges, split, concretise. Use the two decision tables below for every hit that is not an
   obvious deletion. English hits map to `references/english-tells.md`, Chinese hits to
   `references/chinese-tells.md`.
   *Exit criterion:* every flagged line has a decision, and every rewrite names the concrete
   replacement — no synonym swap ("delve into" → "explore" is not a rewrite).
4. **Rescan and drive to zero, or justify what stays.** Rerun the same command. Each surviving hit
   gets one sentence: which false-positive class it belongs to, or which fact would be lost by
   removing it. A line that must stay — a quotation, an identifier, a domain term — carries
   `scan: ignore <category>` inline so the next scan shows the exemption and the reason next to it.
   *Exit criterion:* the final scan is recorded, and every surviving hit has a reason that a
   reviewer could check against the source.
5. **Record the change log and the claims check.** Fill the before/after table with one row per
   change: location, before, after, category, reason, precision kept. Then diff the numeric tokens
   and audit the qualifiers — `may`, `must`, `only`, `up to`, `at least`, `不超过` — between original
   and rewrite.
   *Exit criterion:* every change has a row, every surviving hit appears under *Surviving hits*, and
   the claims check shows nothing introduced and nothing lost without explanation.

## Quick Decisions

Which rewrite move a category implies:

| Scan category | Move | What changes |
|---|---|---|
| `hedge-stacking` | Cut to the one real uncertainty | Delete the frame clause; if the limit is untested, say so instead of hedging |
| `empty-transition` | Name the relation, or delete | Cause, contrast, sequence or exception replaces the connector |
| `triadic-padding` | Keep the two that differ | The third item is a synonym or a feeling; drop it |
| `not-just-x` | State X, then what Y buys | If Y is praise, delete it; if it is the design decision, keep the contrast flat |
| `meta-narration` | Delete, open with the first fact | The section starts one paragraph earlier |
| `empty-summary` | Delete, or add a decision | A summary earns its place by naming a next action or a measurement |
| `translated-diction` | Concrete verb or noun | "leverage" → "use" / "call"; "seamless" → the latency or the step count |
| `corporate-jargon` | Who did what, with a number | "赋能团队" → the table the on-call can now query |
| `zh-translated-connective` | Replace with 因果 / 转折 / 顺序 | "值得注意的是" → the fact itself |
| `zh-parallelism` | One clause plus a number | "既要…又要…还要" → the constraint that binds and the measurement |
| `over-bold` | One bold per section at most | Bold marks a term the reader will meet again, not emphasis |
| `emoji-bullet` | Plain bullet or sentence | Emoji carries no information in a technical document |
| `emdash-chain` | Split the sentence | One dash is punctuation; three are a rhythm tic |

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

How much to accept, by document type:

| Text type | Bar |
|---|---|
| README, release note, runbook | Zero hits; flat prose; every number next to the claim it supports |
| Design doc, RFC, incident report | Zero hits; a hedge survives only as a named gap ("not measured above 5,000 rps") |
| Marketing or brand copy | Rewrite only the tells that carry no brand meaning; voice is the owner's call |
| Legal, quoted or third-party text | Never edit; report the score and stop |

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

## References

| File | Load when |
|---|---|
| [references/english-tells.md](references/english-tells.md) | Rewriting an English hit, or judging whether an English tell is load-bearing. |
| [references/chinese-tells.md](references/chinese-tells.md) | Rewriting a Chinese hit, or judging 空洞开场、企业黑话、排比 and the rest. |
| [references/rewrite-playbook.md](references/rewrite-playbook.md) | Turning hits into edits — the eight moves in payoff order and the technical-precision rule. |
| [references/measurement.md](references/measurement.md) | Reporting a score, setting a threshold, or deciding whether a hit is a false positive. |
| [assets/before-after.template.md](assets/before-after.template.md) | Filling the change log for a rewrite or a gate report. |

## Verification Checklist

- [ ] The scanner was run on the final text and its output is pasted with the exit code, not summarised.
- [ ] Distinct flagged lines fell against the baseline, and the result meets the threshold for the document type in `references/measurement.md`.
- [ ] Every surviving hit has a row under *Surviving hits* naming a false-positive class or the fact it protects.
- [ ] Every before/after row names a scan category (or `judgement`) and a reason; no row says only "reworded".
- [ ] Numeric token diff is empty in both directions: no figure, date, identifier or proper noun was introduced or silently dropped.
- [ ] Every modal in the original (`may`, `must`, `only`, `up to`, `at least`, `不超过`) is either still present or its removal is justified in the log.
- [ ] No fenced code, error string, API name or quotation was edited.
- [ ] Every `scan: ignore` marker names specific categories and sits on a line with a stating reason.
- [ ] Every sentence of the rewrite maps to a sentence in the original or is a split of one; no new claim appears.
- [ ] The scan was rerun after the last edit, so the reported score describes the delivered text.
