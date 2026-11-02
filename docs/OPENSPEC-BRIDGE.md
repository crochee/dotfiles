# OpenSpec + superpowers-bridge 接入

每个项目只写**一个文件** `openspec/config.yaml`，三件事各一条命令： <!-- scan: ignore E3 标题给的是接入对象，首行给的是要写的文件和三条命令 -->

| 动作 | 命令 |
|---|---|
| 项目接入（写 `config.yaml` + 追加 `AGENTS.md`） | `openspec-bridge init [目录]` |
| 装用户级 skill | `openspec-bridge skills [--with-verify\|--core]` |
| 验收 | `openspec-bridge check [目录]` |

脚本在 `~/.local/bin/openspec-bridge`（源 `home/dot_local/bin/executable_openspec-bridge`，
`chezmoi apply` 部署；`openspec-bridge --help` 看全部参数）。它只往项目里写
`openspec/config.yaml` 与 `AGENTS.md`，项目内不生成 `.agents/skills/`、不生成斜杠命令文件、
不拷贝 schema。

- schema 本体是用户级安装：`~/.local/share/openspec/schemas/superpowers-bridge/`
  （由 dotfiles `chezmoi apply` 部署，所有项目共用）。
- openspec 与 superpowers 的 skill 全部放用户级 `~/.agents/skills/`，所有项目共用。

`openspec new change` 会自动创建 `openspec/changes/`、`openspec/changes/archive/` 与
`openspec/specs/`，所以不需要 `openspec init` 的骨架。

---

## 1. 项目内唯一文件：`openspec/config.yaml`

```bash
openspec-bridge init              # 当前目录
openspec-bridge init ~/work/foo   # 指定目录(须已存在)
```

脚本写进去的就是下面 5 行：

```yaml
schema: superpowers-bridge

context: |
  Language: Chinese (Simplified)
  All artifacts must be written in Chinese (Simplified).
  Keep OpenSpec structural headings and SHALL/MUST keywords in English.
```

- `schema:` 决定 `openspec new change` 走的流程；**只有这一行是必须的**，
  `context:` 是产物语言，不写就没有语言约束。
- 该行之后就是项目默认 schema，`new change` 不必再带 `--schema`。
- 已有 `config.yaml` 但缺 `schema:` 行时，脚本把 `schema: superpowers-bridge` 插到首行，其余内容不动。
- 已声明别的 schema（如 `spec-driven`）时，脚本报错退出，**不改文件**；手工改成
  `superpowers-bridge` 或删掉该行后重跑。
- `--no-agents` 跳过 §3 的 `AGENTS.md` 追加。
- `.openspec.yaml` 里固化的 `schema:` 优先于这里：既有 change 不会被改写。
- 项目内不要放 `openspec/schemas/`，否则会覆盖用户级 schema（project > user > package）：
  `init` 会 warning，`check` 会 ✗。

## 2. 用户级 skill:`~/.agents/skills/`

### openspec 系（脚本生成）

```bash
openspec-bridge skills                # 按当前全局 profile 装
openspec-bridge skills --with-verify  # 切 profile=custom + 加上 verify 工作流后装(7 个)
openspec-bridge skills --core         # 切回 profile=core 后装(6 个)
```

`profile: core` 生成 6 个：`openspec-propose`、`openspec-explore`、`openspec-apply-change`、
`openspec-update-change`、`openspec-sync-specs`、`openspec-archive-change`。

脚本在临时目录跑 `openspec init --tools agents --no-animation`，再对 `~/.agents/skills/` 先
`rm -rf openspec-*` 后 `cp -r` —— **先删后拷，重复执行安全**，不会套出
`openspec-propose/openspec-propose/`。`openspec init` 顺手写的 `.agents/skills/.openspec-target`
是项目级投递标记，复制时被 `openspec-*` 通配符排除，用户级目录不需要它。
装完需**重开 agent 会话**才生效。

`profile: core` **不含** `openspec-verify-change`。schema 已授权这一项降级：verify 阶段改为
按 schema 的 7 项手工检查执行并写入 `verify.md`。若要真正的 verify skill，用 `--with-verify`：
它执行 `openspec config set profile custom` 与
`openspec config set workflows '["propose","explore","apply","update","sync","archive","verify"]'`。
这是**全局设置，会影响之后所有 `openspec init`**（`--core` 是它的逆操作）。生成的 `SKILL.md` 带
`name` + `description`（omp 加载 skill 的硬要求），复制后不必改。

### superpowers 系（插件提供，不要复制）

`brainstorming`、`writing-plans`、`using-git-worktrees`、`subagent-driven-development`、
`test-driven-development`、`requesting-code-review`、`finishing-a-development-branch`。
来源与本机位置见 `docs/AGENT-SKILLS.md`；缺失时 schema 设计上立即报错中止。

## 3. 项目根 `AGENTS.md` 路由（可选但建议）

`openspec-bridge init` 会把
`~/.local/share/openspec/schemas/superpowers-bridge/adopters/AGENTS.md.fragment.md`
整段追加到项目根 `AGENTS.md`（目标文件已有内容时先补一个空行）。

幂等判定用片段首行 marker：

```
<!-- 来源:superpowers-bridge/adopters/AGENTS.md.fragment.md -->
```

已含即跳过，重复 `init` 不会叠加。片段内容：8 个产物流程、依赖 skill 清单、
「skill 缺失立即停止、不得降级」的判读规则、何时不该开 change（直接开 PR）、
口头讨论升级成 change 的 5 条门槛与前门反模式。用 `--no-agents` 时手工按上面路径整段追加。

## 4. 验收

```bash
openspec-bridge check              # 用户层:CLI、schema 解析、结构、模板、skill、端到端
openspec-bridge check ~/work/foo   # 另加:该项目的 config.yaml 是否声明 superpowers-bridge
```

任意目录可跑，端到端流程在 `mktemp -d` 里执行，不碰任何项目。全 `✓` 退出 0，
有 `✗` 退出 1（`!` 只是提示，例如缺 verify skill）。三项关键期望：

- 端到端 `schemaName` 为 `superpowers-bridge`
- `brainstorm` 为 `ready`
- `applyRequires` 含 `plan`

手工复现同一组断言：

```bash
openspec new change demo
openspec status --change demo --json
```

`openspec/changes/demo/.openspec.yaml` 里也有 `schema: superpowers-bridge`。
`schemaName` 若是 `spec-driven`，说明 `config.yaml` 的 `schema:` 没生效
（拼写错误，或该 change 创建时用了 `--schema`）。

## 5. 维护

- schema 改动：`home/dot_local/share/openspec/schemas/superpowers-bridge/`，然后 `chezmoi apply`、
  `openspec-bridge check`（结构校验、用户层解析、8 个模板、端到端 change 流程一次过）。
- openspec CLI 升级后同样一遍：`chezmoi apply && openspec-bridge check`。
  本机实测版本 `1.15.0`。
- 脚本本体 `home/dot_local/bin/executable_openspec-bridge`；改完 `bash -n` 加 `check` 即可回归。
