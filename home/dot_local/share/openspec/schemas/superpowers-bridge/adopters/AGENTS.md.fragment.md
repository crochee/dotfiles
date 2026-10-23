<!-- 来源:superpowers-bridge/adopters/AGENTS.md.fragment.md -->
<!-- 把本段追加到项目根目录的 AGENTS.md,让 agent 正确路由后续工作。 -->

## 工作流路由(会话开始时读)

本项目使用 `superpowers-bridge` schema(用户级安装,无需在项目内拷贝 schema 目录)。
集成规则(语言、产物路径、PRECHECK)以该 schema 自带的 README 为准;本节是给 Claude 的路由指引。

### 产物与依赖 skill

8 个产物:`brainstorm` → `proposal` / `design` → `specs` → `tasks` → `plan` → `verify` → `retrospective`。

依赖的 superpowers skill(裸名):`brainstorming`、`writing-plans`、`using-git-worktrees`、
`subagent-driven-development`、`finishing-a-development-branch`
(传递激活 `test-driven-development`、`requesting-code-review`),
外加 OpenSpec 侧的 `openspec-verify-change`。

### skill 缺失时的判读规则(硬性)

- 上述 superpowers 系 skill **缺失即立即停止**,列出缺失的 skill 名并告知用户安装位置
  (`~/.agents/skills/<name>/SKILL.md`,或 superpowers 插件提供的同名 skill)。
- **不得**自行降级、不得改用其他 skill、不得手写产物绕过。
- `openspec-verify-change` 缺失时是唯一例外:改为手工完成 verify 的 7 项检查并写入 `verify.md`。
- 平台不支持 subagent 时不要退到 `executing-plans`(它不会传递激活 TDD 与 code-review),
  请改用内置 `spec-driven` schema。

### 何时不要开 change(直接开 PR)

| 场景 | 直接 PR? |
|---|---|
| 新功能 / 新能力 / 架构变更 / 破坏性变更 | ❌ 走 opsx |
| bug 修复(无契约变化)/ 补测试 / linter 微调 / 非破坏性升级 / 错字 / 文档 / 配置值微调 | ✅ 直接 PR |

原则:**流程仪式要与风险成比例**。对外契约 / schema / 跨系统集成 / 合规边界 → 走 opsx;其余 → 直接 PR。

### 口头讨论要不要升级成 change

若 brainstorming 是用叙述方式触发的("我们聊聊架构"),产出**不得**落到
`docs/superpowers/specs/` —— 那会绕过 schema 的输出重定向,产生孤儿产物。
先口头收敛,满足下面 5 条后再升级成 `/opsx:propose`:

1. **范围已锁定** —— 一句话说清做什么 / 不做什么
2. **主要设计岔路已解决** —— 替代方案已权衡并选定;剩余 TBD 有 owner 与影响面说明
3. **跨系统依赖已盘清** —— 每个依赖标明就绪 / 可 mock / 真未知
4. **验收标准说得出来** —— 具体通过条件(如 `./mvnw clean verify` 通过 + N 项交付物)
5. **讨论在收敛** —— 最近 1-2 轮是确认,不是新的岔路

5 条全满足时,主动提示"可以升级成 `/opsx:propose` 了,要开吗?" —— 等用户确认,
**绝不自动触发**。

### 前门反模式(不要做)

- 让 brainstorming 的产出写进 `docs/superpowers/specs/`
- 让 writing-plans 的产出写进 `docs/superpowers/plans/`
- 带着未解决的阻塞级 TBD 升级成 opsx change
- 为 bug 修复 / 错字 / 配置微调开 change
