# Changelog

## 2.1.0

The 44-pattern table moves out of `SKILL.md` so the entry point stays under the 150-line budget, and
the trigger eval moves to the repository runner.

**Changed**

- The `## The 44 patterns` table and the cause-group table now live in
  `references/patterns-index.md` and `references/rewrite-playbook.md`; `SKILL.md` keeps a summary and
  a pointer. The drift tests read the index file instead of `SKILL.md`.
- The document-type thresholds table moves to `references/measurement.md`.
- Frontmatter gains `license: MIT`.
- Trigger evaluation runs through the repository's `bin/skill-trigger-eval`; `tests/trigger_eval.py`
  is removed. The query file gains a `workflow_marker` field and 24 queries.

## 2.0.0

A breaking release. The classification system, the scanner's output contract and the package
layout all changed.

**Breaking**

- The taxonomy moves from 13 flat categories to **44 numbered patterns** in six cause groups
  (A staging, B rhythm, C inflation, D formatting, E leftovers, F wrong reader). Every category
  token from v1 is kept and now carries a pattern number, so old change logs still line up.
- The scanner's output carries both identifiers: `path:line: A1 not-just-x: <matched text>`.
  The old single-token form is gone; scripts that parsed the output must be updated.
- `scan: ignore` now accepts either the category token (`not-just-x`) or the pattern number
  (`A1`). Markers written for v1 keep working unchanged.
- `references/english-tells.md` and `references/chinese-tells.md` are gone. Their content is split
  by cause group into `references/patterns-[a-f].md` and `references/patterns-[a-f].zh.md`.

**Added**

- 34 new detection rules and 2 new structural rules, covering the patterns that v1 could not see:
  the staged run-up (§A4), the rhetorical question and false candour of Chinese prose (§A6, §A7),
  the Chinese preposition opener, the chained `的`, the over-nominalisation, the stock challenges
  and outlook ending, the Chinese hype vocabulary, the Chinese punctuation rules, the chatbot
  residue, the knowledge-limit disclaimer, the repeated heading, and the document narration.
- Chinese detection for the patterns v1 only caught in English: the not-X-but-Y contrast, the
  adjective triad, the hedge stack, the translated connective, and the hollow opening.
- The `B2 repeated-openings` metric rule, which rebuilds each paragraph and flags three or more
  consecutive sentences that open the same way.
- Twelve reference files, one per cause group per language, each with a table of contents, a
  before/after pair per pattern and a "when not to act" section.
- The bilingual rewrite playbook and measurement documents, with a shared threshold table that a
  drift test compares between the two languages.
- Package files: `README.md`, `CHANGELOG.md`, `AGENTS.md`, `agents/openai.yaml`,
  `scripts/validate-package.py`.
- Evaluations: `evals/trigger_queries.json`, `evals/rewrite_cases.json`, `evals/rubric.md`, and the
  runners `tests/trigger_eval.py` and `tests/rewrite_eval.py`.
- `tests/run.py` grew three drift tests — pattern numbers, threshold numbers, and Chinese pattern
  names — and now checks that every regex category fires in the fixtures.

**Changed**

- The frontmatter description was rewritten to the community format: third person, what plus when,
  keyword-bearing, under 1,024 characters.
- `metadata.version` moved from `1.0.0` to `2.0.0`, and the skill now declares `license: MIT`.
- The scanner's module docstring lists every pattern number, category token and matched phrase: it
  is the human-readable contract for the rule set.

## 1.0.0

The first release. A standard-library scanner with 13 categories, an English and a Chinese tell
list, an eight-move rewrite playbook, a measurement document with thresholds, a change-log
template, and a self-check test suite.
