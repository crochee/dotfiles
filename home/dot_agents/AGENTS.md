# Global skill conventions

## 1. How to invoke a skill

Skills live at `~/.agents/skills/<name>/SKILL.md`. Read one with `read skill://<name>`.

This harness has no `Skill` tool. When a skill body says `Call the Skill tool with "X"`,
that means: read `skill://X`, then follow that skill's instructions.

## 2. Routing discipline

- The skill list in your system prompt is authoritative. If any entry matches the task, read that
  `skill://<name>` before acting — do not improvise the workflow from memory.
- Process skills outrank domain skills. Default order:
  `grilling` → `to-spec` → `to-tickets` → `implement` → `code-review` → `retro`.
- 16 installed skills are **not** in your skill list: upstream marks them
  `disable-model-invocation: true`, so they are user-invoked only. This file is the only place
  that names them, so read them by name when the task calls for it:
  `ask-matt`, `grill-me`, `grill-with-docs`, `handoff`, `implement`, `implement-spec`,
  `improve-codebase-architecture`, `retro`, `setup-matt-pocock-skills`, `teach`,
  `to-questionnaire`, `to-spec`, `to-tickets`, `triage`, `wait-what`, `wayfinder`.
- Whether to use one of those is the human's call — never auto-trigger them.

## 3. Overlapping skills

| Skill | Use for | Not for |
|---|---|---|
| `deep-research` | Conclusions that must survive scrutiny: multiple sources, evidence ledger, inline citations, uncertainty labels | Quick lookups |
| `research` | Fast lookups, background agents, one markdown output | Anything that needs a ledger or stated uncertainty |
| `architecture-design` | Decision records: ADR, NFRs, candidates that lost, failure modes | Deep-module and seam vocabulary |
| `codebase-design` | Deep modules, seams, interface design | Producing decision documents |
| `python-dev` / `golang-dev` / `rust-dev` | Language-level review and idiom | The red-green-refactor loop itself |
| `tdd` | The red-green-refactor loop | Language idiom review |
| `diagnosing-bugs` | The bug diagnosis loop | Writing the fix's regression test |

`research` (upstream) and `deep-research` (self-built) coexist on purpose. Prefer `deep-research`
when the answer has to hold up under questioning; use `research` for lookups.

## 4. Removed stack

There is no OpenSpec CLI, no `openspec-*` skills, and no `brainstorming`, `writing-plans`, or
`subagent-driven-development` skills. The replacement flow is:

`grilling` → `to-spec` → `to-tickets` → `implement` → `code-review` → `retro`
