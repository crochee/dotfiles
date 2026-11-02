**Load this reference when:** a scan hit carries a pattern number you need to place, or you need the detector kind and category token for that number.

# Pattern index

Groups: A staging (§A1–§A9) · B rhythm (§B1–§B14) · C inflation (§C1–§C10) · D formatting (§D1–§D5) ·
E leftovers (§E1–§E5) · F wrong reader (§F1). Groups A and E justify an edit on one sighting; the
rest are *weak alone* and need company from other tells.

| ID | Pattern | Detector | Category token |
|---|---|---|---|
| A1 | Not X but Y | regex | `not-just-x` |
| A2 | One-line closers and dramatic fragments | regex | `one-line-closer, empty-summary` |
| A3 | Sayings that sound deep | regex | `deep-saying` |
| A4 | Staged run-up before the point | regex | `meta-narration, empty-transition, zh-translated-connective, zh-empty-opening` |
| A5 | Arguing with no one | regex | `arguing-with-nobody` |
| A6 | Rhetorical question theatre | regex | `rhetorical-question` |
| A7 | False candour, false neutrality | regex | `false-candour` |
| A8 | Staged contrast and stage slogans | regex | `staged-contrast` |
| A9 | Fixed attention formulas | regex | `attention-formula` |
| B1 | Forced triads | regex | `triadic-padding, zh-parallelism` |
| B2 | Repeated sentence openings | metric | `repeated-openings` |
| B3 | Dashes as the universal connector | regex | `emdash-chain` |
| B4 | Stacked qualifiers | regex | `hedge-stacking, zh-hedge-stacking` |
| B5 | Hyphenated pairs everywhere | regex | `hyphen-pairs` |
| B6 | Passive voice and missing subjects | regex | `passive-voice` |
| B7 | Preposition-led sentence openings | regex | `preposition-opening` |
| B8 | Chained 的 and over-long modifiers | regex | `chained-de` |
| B9 | Over-nominalisation | regex | `nominalisation` |
| B10 | Rhythm-even sentences | manual | — |
| B11 | Stacked colloquial questions | regex | `colloquial-stack` |
| B12 | Over-balanced pairs | regex | `over-balanced` |
| B13 | Dense feature triads | regex | `feature-triad` |
| B14 | Fake spans | regex | `fake-span` |
| C1 | Overused AI words | regex | `translated-diction` |
| C2 | Inflated significance | regex | `inflated-significance` |
| C3 | Vague connection or association | regex | `vague-connection` |
| C4 | Shallow -ing riders | regex | `ing-rider` |
| C5 | Sales language | regex | `sales-language` |
| C6 | Borrowed authority | regex | `borrowed-authority` |
| C7 | Avoiding is, are, and has | regex | `avoiding-copula` |
| C8 | Stock challenges-and-outlook | regex | `challenges-outlook` |
| C9 | Hype vocabulary | regex | `corporate-jargon` |
| C10 | Generic positive conclusion | regex | `generic-positive` |
| D1 | Bold as decoration | regex | `over-bold` |
| D2 | Labelled-list template | regex | `labelled-list` |
| D3 | Decorative headings and emoji | regex | `decorative-heading, emoji-bullet` |
| D4 | Curly quotation marks | regex | `curly-quotes` |
| D5 | Mixed punctuation and CJK spacing | regex | `punctuation-spacing` |
| E1 | Chatbot residue | regex | `chatbot-residue` |
| E2 | Knowledge-limit disclaimers | regex | `knowledge-limit` |
| E3 | A heading repeated in the first sentence | regex | `heading-repeat` |
| E4 | Writing about the document instead of its subject | regex | `document-meta` |
| E5 | Staged persona voice | regex | `staged-persona` |
| F1 | Re-explaining what the reader knows | manual | — |

`regex` rules match literal phrases, `metric` rules measure a shape across a paragraph, `manual`
patterns (§B10, §F1) have no detector and are judged by reading.

The per-pattern entries — watch-for list, before/after pair, and the playbook move that fixes it —
live in `references/patterns-a.md` … `references/patterns-f.md` (`.zh.md` twins for a Chinese
delivery).
