# de-ai-tone

Rewrites English or Chinese prose that reads as machine-generated, until a fixed and rerunnable scan
is clean — while every claim, number and qualifier in the source survives.

The skill is built around **44 numbered patterns** in six cause groups. A pure-standard-library
scanner detects 42 of them (40 phrase rules and 2 structural rules); two are judged by reading.
The scanner prints the pattern number next to the category token, so a finding can be looked up,
argued with and logged:

```console
$ python3 scripts/scan.py draft.md; echo exit=$?
score: 9 distinct lines flagged; 21 occurrences; 612 units (410 words + 202 CJK characters); rate 34.3 per 1000 units
draft.md:12: A1 not-just-x: not just a product, but
draft.md:19: B4 hedge-stacking: It is important to note that
exit=1
```

## Installation

The skill is deployed by [chezmoi](https://www.chezmoi.io/) from this repository. The source of
truth lives at `home/dot_agents/skills/de-ai-tone/`, and chezmoi writes it to
`~/.agents/skills/de-ai-tone/`.

```bash
cd ~/.dotfiles
chezmoi diff ~/.agents/skills/de-ai-tone     # see what would change
chezmoi apply ~/.agents/skills/de-ai-tone    # deploy it
```

There is no `.claude-plugin/` manifest and no marketplace entry: this package is deployed by chezmoi
onto one machine, not published to a plugin market. `agents/openai.yaml` carries the display name
and short description for OpenAI-compatible agents.

## Usage

Ask for the work in plain language — "this reads like AI, clean it up", "去掉 AI 味", "润色得自然
一点" — or point the agent at a file. The skill works in three modes:

| Mode | What it delivers |
|---|---|
| Rewrite | The rewritten document, a before/after change log, and the final scan output |
| Gate | A verdict against the threshold in `references/measurement.md`, the scan output, and a judged-hit table — no edits |
| Calibrate | The patched template, the phrases removed, and the guidance a future writer should follow |

The agent loads `SKILL.md` first, then only the cause groups the scan actually flags:
`references/patterns-<group>.md` for English, `references/patterns-<group>.zh.md` for Chinese.

## The 44 patterns

Patterns in groups **A** and **E** justify an edit on one sighting. The rest are *weak alone*: they
count only when several tells share a passage.

| # | Pattern | 中文名 | Detector | Category token |
|---|---|---|---|---|
| A1 | Not X but Y | 否定式对比 | regex | `not-just-x` |
| A2 | One-line closers and dramatic fragments | 一句总结与碎片行 | regex | `one-line-closer, empty-summary` |
| A3 | Sayings that sound deep | 深刻金句 | regex | `deep-saying` |
| A4 | Staged run-up before the point | 报幕式开场 | regex | `meta-narration, empty-transition, zh-translated-connective, zh-empty-opening` |
| A5 | Arguing with no one | 与无人辩论 | regex | `arguing-with-nobody` |
| A6 | Rhetorical question theatre | 假问题自问自答 | regex | `rhetorical-question` |
| A7 | False candour, false neutrality | 假坦诚假中立 | regex | `false-candour` |
| A8 | Staged contrast and stage slogans | 模板转折与阶段口号 | regex | `staged-contrast` |
| A9 | Fixed attention formulas | 固定关注句式 | regex | `attention-formula` |
| B1 | Forced triads | 三件套与排比 | regex | `triadic-padding, zh-parallelism` |
| B2 | Repeated sentence openings | 重复句首 | metric | `repeated-openings` |
| B3 | Dashes as the universal connector | 破折号泛滥 | regex | `emdash-chain` |
| B4 | Stacked qualifiers | 叠词限定 | regex | `hedge-stacking, zh-hedge-stacking` |
| B5 | Hyphenated pairs everywhere | 连字符复合修饰 | regex | `hyphen-pairs` |
| B6 | Passive voice and missing subjects | 被动语态与无主句 | regex | `passive-voice` |
| B7 | Preposition-led sentence openings | 句首介词短语泛滥 | regex | `preposition-opening` |
| B8 | Chained 的 and over-long modifiers | 连环定语 | regex | `chained-de` |
| B9 | Over-nominalisation | 过度名词化与动词虚化 | regex | `nominalisation` |
| B10 | Rhythm-even sentences | 句长齐一 | manual | — |
| B11 | Stacked colloquial questions | 人工感叠词 | regex | `colloquial-stack` |
| B12 | Over-balanced pairs | 过度平衡 | regex | `over-balanced` |
| B13 | Dense feature triads | 密集排比 | regex | `feature-triad` |
| B14 | Fake spans | 虚假跨度 | regex | `fake-span` |
| C1 | Overused AI words | AI 高频词 | regex | `translated-diction` |
| C2 | Inflated significance | 空泛与句尾强行升华 | regex | `inflated-significance` |
| C3 | Vague connection or association | 模糊关联 | regex | `vague-connection` |
| C4 | Shallow -ing riders | -ing 挂件 | regex | `ing-rider` |
| C5 | Sales language | 宣传腔 | regex | `sales-language` |
| C6 | Borrowed authority | 模糊归因与虚假权威 | regex | `borrowed-authority` |
| C7 | Avoiding is, are, and has | 回避简单动词 | regex | `avoiding-copula` |
| C8 | Stock challenges-and-outlook | 套路化挑战与展望 | regex | `challenges-outlook` |
| C9 | Hype vocabulary | 职场黑话与空洞大词 | regex | `corporate-jargon` |
| C10 | Generic positive conclusion | 通用积极结论 | regex | `generic-positive` |
| D1 | Bold as decoration | 装饰性加粗 | regex | `over-bold` |
| D2 | Labelled-list template | 加粗小标题清单体 | regex | `labelled-list` |
| D3 | Decorative headings and emoji | 装饰性标题与 emoji | regex | `decorative-heading, emoji-bullet` |
| D4 | Curly quotation marks | 弯引号 | regex | `curly-quotes` |
| D5 | Mixed punctuation and CJK spacing | 标点与中英混排规范 | regex | `punctuation-spacing` |
| E1 | Chatbot residue | 聊天残留 | regex | `chatbot-residue` |
| E2 | Knowledge-limit disclaimers | 知识截止与免责套话 | regex | `knowledge-limit` |
| E3 | A heading repeated in the first sentence | 标题复读 | regex | `heading-repeat` |
| E4 | Writing about the document instead of its subject | 写作元叙述 | regex | `document-meta` |
| E5 | Staged persona voice | 刻意拟人口吻 | regex | `staged-persona` |
| F1 | Re-explaining what the reader knows | 重复读者已知 | manual | — |

## Layout

```
SKILL.md                     English entry point: workflow, decision tables, checklist
references/patterns-index.md   the 44-pattern table: id, name, detector, category token
references/skill.zh.md        Chinese entry point (the English one is the source of truth)
references/patterns-[a-f].md  one file per cause group, per language
references/rewrite-playbook.md  the eight moves, per language
references/measurement.md       score semantics, thresholds, false positives, per language
assets/before-after.template.md the change log, per language
scripts/scan.py               the scanner: standard library only
scripts/validate-package.py   package self-check
evals/                        trigger queries, rewrite cases, scoring rubric
tests/                        unit tests, drift tests, and the two eval runners
```

## Tests and evaluations

```bash
python3 scripts/validate-package.py     # package self-check: frontmatter, tables, drift
python3 tests/run.py                    # unit tests, fixture coverage, three drift tests
python3 bin/skill-trigger-eval --skills de-ai-tone --runs 3  # does the skill fire when it should? (needs omp)
python3 tests/rewrite_eval.py           # does the rewrite hold the numbers? (needs omp)
```

`tests/run.py` fails the build when the pattern numbers drift apart between the scanner, the
pattern index, the README table and the twelve reference files, when the English and Chinese
threshold tables disagree, or when a Chinese pattern name differs between the two language files.

The eval runners need the `omp` binary on `PATH`; they report the missing prerequisite instead of
silently passing.

## Sources and licences

The pattern table absorbs two MIT-licensed projects:

- [`blader/humanizer`](https://github.com/blader/humanizer) v3.1.0 — MIT, © 2025 Siqi Chen
- [`nothing0here/humanizer-zh`](https://github.com/nothing0here/humanizer-zh) v3.0.0-cn — MIT, © 2026 nothing0here

Their upstream source is Wikipedia
["Signs of AI writing"](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing)
(CC BY-SA 4.0), maintained by WikiProject AI Cleanup. This package links it; it does not copy it.

The idea of a numbered, cause-grouped pattern list was also informed by
`wwenj/zu-article-polisher-skill`, which carries no licence: no wording or regular expression from
it is reproduced here.

This package is MIT licensed.

## Version history

See [CHANGELOG.md](CHANGELOG.md).
