# Guide for agents

This file explains how to change `de-ai-tone` without breaking its package, its prompt, or its
scanner.

## What this package contains

`de-ai-tone` is an agent skill written in Markdown plus two Python scripts. `SKILL.md` is the
prompt agents read. There is no build step.

- `SKILL.md` — the English entry point and the source of truth for the workflow, the decision
  tables and the verification checklist. Keep it under 150 body lines.
- `references/patterns-index.md` — the 44-pattern table: id, name, detector, category token.
- `references/skill.zh.md` — the Chinese entry point. It is a translation of `SKILL.md`, not a
  separate design.
- `references/patterns-[a-f].md` and `references/patterns-[a-f].zh.md` — one file per cause group per
  language. Each entry carries the pattern number, both names, the watch-for phrases, a
  before/after pair, the playbook move and the detector.
- `references/rewrite-playbook.md`, `references/measurement.md` and their `.zh.md` twins — the eight
  moves, and the score semantics.
- `assets/before-after.template.md` and `assets/before-after.zh.template.md` — the change log.
- `scripts/scan.py` — the scanner. **Standard library only.**
- `scripts/validate-package.py` — the package self-check.
- `evals/` — trigger queries, rewrite cases and the scoring rubric.
- `tests/` — `run.py` (unit and drift tests), `rewrite_eval.py`, and the fixtures.

## Rules for changes

**Pattern numbers are a contract.** The 44 numbers `A1`–`F1` are fixed. A new pattern takes the
next free number in its group; inserting a pattern renumbers only the rest of that group, and every
place that mentions a number must be updated in the same change: `references/patterns-index.md`,
the `README.md` table, the `references/patterns-*.md` headings, and the scanner's `pattern_id` fields.
Never leave a gap and never reuse a number.

**Keep four things in step.** A pattern's number, English name, Chinese name and category token
appear in four places: `references/patterns-index.md`, the `README.md` table, the twelve reference
files, and `scripts/scan.py`. `tests/run.py` compares all four and fails when they drift. When you
change one, change all four.

**English is the source of truth.** `references/patterns-*.md`, `references/rewrite-playbook.md`
and `references/measurement.md` come first; the `.zh.md` files are translations that follow
them. The Chinese pattern names must be identical in both language files, and the threshold
numbers in the two measurement files must match character for character. Two drift tests enforce
this.

**The scanner stays standard-library.** `tests/run.py` checks the import list. Adding a dependency
breaks the package on every machine that has Python and nothing else.

**A rule needs a literal phrase.** Chinese rules only cover wordings that are fixed on the page.
Adjectives that need context, four-character idiom density and vague praise stay `manual` patterns
that a reader judges. If you want to automate one of those, change the pattern table first and say
so in the changelog.

**Version and history.** Keep `metadata.version` in `SKILL.md`, the first `## x.y.z` heading in
`CHANGELOG.md`, and the version line in `scripts/validate-package.py`'s output in step. The
validator compares the first two. Add a changelog entry for any behaviour change.

**Keep the description short and specific.** The `SKILL.md` description is what an agent reads
before deciding to load the skill. Third person, what plus when, keyword-bearing, under 1,024
characters.

**Length is a budget.** Every word of `SKILL.md` is read on each use. The validator caps it at 220
lines. Detail belongs in `references/`.

## Before you hand the change back

```bash
python3 scripts/validate-package.py
python3 tests/run.py
```

Both must exit 0. `validate-package.py` checks the frontmatter, the pattern tables, the reference
files and the changelog version; `tests/run.py` checks the scanner's behaviour against the
fixtures and runs the three drift tests.

The eval runners need `omp` on `PATH`. Run the trigger eval from the repository root; the rewrite
eval runs in place:

```bash
python3 bin/skill-trigger-eval --skills de-ai-tone --runs 3
python3 tests/rewrite_eval.py
```

## Writing style

Use plain language in prompts, documentation, comments and commit messages. Lead with the point.
Keep sentences short. Use one term for one thing. Use `must` for requirements. Keep exact
identifiers, commands, paths, category tokens, watched phrases and examples exactly as they are.
