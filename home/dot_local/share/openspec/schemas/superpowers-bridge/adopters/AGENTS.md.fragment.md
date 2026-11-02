<!-- 来源:superpowers-bridge/adopters/AGENTS.md.fragment.md -->
<!-- 把本段追加到项目根目录的 AGENTS.md,让 agent 正确路由后续工作。 -->
<!-- Append this section to the project's root AGENTS.md so the agent routes follow-up work correctly. -->

## 工作流路由(会话开始时读) / Workflow routing (read at session start)

本项目使用 `superpowers-bridge` schema(用户级安装,无需在项目内拷贝 schema 目录)。
集成规则(语言、产物路径、PRECHECK)以该 schema 自带的 README 为准;本节是给 Claude 的路由指引。

**EN**

This project uses the `superpowers-bridge` schema (installed at the user level; there is no need to copy the schema directory into the project).
Integration rules (language, artifact paths, PRECHECK) are defined by the README that ships with that schema; this section is a routing guide for Claude.

### 产物与依赖 skill / Artifacts and dependent skills

8 个产物:`brainstorm` → `proposal` / `design` → `specs` → `tasks` → `plan` → `verify` → `retrospective`。

依赖的 superpowers skill(裸名):`brainstorming`、`writing-plans`、`using-git-worktrees`、
`subagent-driven-development`、`finishing-a-development-branch`
(传递激活 `test-driven-development`、`requesting-code-review`),
外加 OpenSpec 侧的 `openspec-verify-change`。

**EN**

8 artifacts: `brainstorm` → `proposal` / `design` → `specs` → `tasks` → `plan` → `verify` → `retrospective`.

Dependent superpowers skills (bare names): `brainstorming`, `writing-plans`, `using-git-worktrees`,
`subagent-driven-development`, `finishing-a-development-branch`
(which transitively activate `test-driven-development` and `requesting-code-review`),
plus `openspec-verify-change` on the OpenSpec side.

### skill 缺失时的判读规则(硬性) / Interpretation rules when a skill is missing (mandatory)

- 上述 superpowers 系 skill **缺失即立即停止**,列出缺失的 skill 名并告知用户安装位置
  (`~/.agents/skills/<name>/SKILL.md`,或 superpowers 插件提供的同名 skill)。
- **不得**自行降级、不得改用其他 skill、不得手写产物绕过。
- `openspec-verify-change` 缺失时是唯一例外:改为手工完成 verify 的 7 项检查并写入 `verify.md`。
- 平台不支持 subagent 时不要退到 `executing-plans`(它不会传递激活 TDD 与 code-review),
  请改用内置 `spec-driven` schema。

**EN**

- If any of the superpowers skills above is **missing, stop immediately**, list the missing skill names and tell the user where to install them
  (`~/.agents/skills/<name>/SKILL.md`, or the same-named skill provided by the superpowers plugin).
- **Do not** downgrade on your own, **do not** switch to another skill, **do not** hand-write artifacts to work around it.
- A missing `openspec-verify-change` is the only exception: complete the 7 verify checks by hand instead and write them to `verify.md`.
- When the platform does not support subagents, do not fall back to `executing-plans` (it does not transitively activate TDD and code review);
  use the built-in `spec-driven` schema instead.

### 何时不要开 change(直接开 PR) / When not to open a change (open a PR directly)

| 场景 | 直接 PR? |
|---|---|
| 新功能 / 新能力 / 架构变更 / 破坏性变更 | ❌ 走 opsx |
| bug 修复(无契约变化)/ 补测试 / linter 微调 / 非破坏性升级 / 错字 / 文档 / 配置值微调 | ✅ 直接 PR |

**EN**

| Scenario | Direct PR? |
|---|---|
| New feature / new capability / architecture change / breaking change | ❌ go through opsx |
| Bug fix (no contract change) / adding tests / linter tweak / non-breaking upgrade / typo / docs / config value tweak | ✅ direct PR |

原则:**流程仪式要与风险成比例**。对外契约 / schema / 跨系统集成 / 合规边界 → 走 opsx;其余 → 直接 PR。

**EN**

Principle: **process ceremony must be proportional to risk**. External contract / schema / cross-system integration / compliance boundary → go through opsx; everything else → direct PR.

### 口头讨论要不要升级成 change / Whether to escalate a conversational discussion into a change

若 brainstorming 是用叙述方式触发的("我们聊聊架构"),产出**不得**落到
`docs/superpowers/specs/` —— 那会绕过 schema 的输出重定向,产生孤儿产物。
先口头收敛,满足下面 5 条后再升级成 `/opsx:propose`:

**EN**

If brainstorming was triggered conversationally ("let's talk about the architecture"), the output **must not** land in
`docs/superpowers/specs/` — that would bypass the schema's output redirection and produce orphan artifacts.
First converge verbally; only after all 5 conditions below are met escalate to `/opsx:propose`:

1. **范围已锁定** —— 一句话说清做什么 / 不做什么
2. **主要设计岔路已解决** —— 替代方案已权衡并选定;剩余 TBD 有 owner 与影响面说明
3. **跨系统依赖已盘清** —— 每个依赖标明就绪 / 可 mock / 真未知
4. **验收标准说得出来** —— 具体通过条件(如 `./mvnw clean verify` 通过 + N 项交付物)
5. **讨论在收敛** —— 最近 1-2 轮是确认,不是新的岔路

**EN**

1. **Scope is locked** — one sentence states what to do / what not to do
2. **Main design forks are resolved** — alternatives have been weighed and one chosen; remaining TBDs have an owner and an impact note
3. **Cross-system dependencies are mapped** — each dependency is marked ready / mockable / genuinely unknown
4. **Acceptance criteria can be stated** — concrete pass conditions (e.g. `./mvnw clean verify` passes plus N deliverables)
5. **The discussion is converging** — the last 1-2 turns are confirmation, not new forks

5 条全满足时,主动提示"可以升级成 `/opsx:propose` 了,要开吗?" —— 等用户确认,
**绝不自动触发**。

**EN**

When all 5 are satisfied, proactively say "we can escalate to `/opsx:propose` now — want to open one?" — wait for the user to confirm,
and **never trigger it automatically**.

### 前门反模式(不要做) / Front-door anti-patterns (do not do)

- 让 brainstorming 的产出写进 `docs/superpowers/specs/`
- 让 writing-plans 的产出写进 `docs/superpowers/plans/`
- 带着未解决的阻塞级 TBD 升级成 opsx change
- 为 bug 修复 / 错字 / 配置微调开 change

**EN**

- Letting brainstorming output land in `docs/superpowers/specs/`
- Letting writing-plans output land in `docs/superpowers/plans/`
- Escalating to an opsx change while blocking-level TBDs remain unresolved
- Opening a change for a bug fix / typo / config tweak
