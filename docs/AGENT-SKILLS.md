# AGENT-SKILLS.md — 技能安装、版本更新与回滚

> 本机只有 omp 消费 skills。第三方技能**不要手改** `~/.agents/skills/` 里的文件；
> 更新走各自安装器。`docs/` 只存在于本仓，不部署到 `$HOME`。
>
> 当前台账日期：2026-11-01。

## 0. 一张表

| 目标 | 命令 |
|---|---|
| 看装了哪些 | `npx skills@latest ls -g` / `omp plugin list` |
| 看 mattpocock 现状 | `npx skills@latest ls -g` |
| 更新 mattpocock | `npx skills@latest update -g <name>...` |
| 更新 superpowers | `omp plugin upgrade superpowers` |
| 体检插件 | `omp plugin doctor` |
| 看 omp 实际解析到哪个文件 | `omp read skill://<name> \| head -1` |

## 1. 三类来源

| 来源 | 安装器 | 源 | 落点 | 状态 |
|---|---|---|---|---|
| 自建 skills | chezmoi | `home/dot_agents/skills/` | `~/.agents/skills/<name>/` | git |
| `mattpocock/skills` | `npx skills`（vercel-labs） | GitHub `mattpocock/skills` | `~/.agents/skills/<name>/` | `~/.local/state/skills/.skill-lock.json` |
| `superpowers` | omp plugin | GitHub `obra/superpowers` | `~/.local/share/omp/plugins/node_modules/superpowers/skills/` | `~/.local/share/omp/plugins/omp-plugins.lock.json` |

**不要在 `~/.agents/skills/` 里再放一份 superpowers。** 名字会与插件重复，omp 需要命名空间消歧，
自动选择变得不可预测。两种来源只能留一种；本机当前选插件。

旧根 `~/.omp/plugins` 已在 2026-11-01 清理；本机只认 XDG 根。
如果它再次出现，先跑 `omp plugin list` 确认生效根，不要按旧路径排查或直接复制。

## 2. 当前台账（2026-11-01）

| 组件 | 版本 | 说明 |
|---|---|---|
| superpowers | **7.0.1** | omp 插件，15 个 skill + 启动 extension |
| mattpocock | 9 个 | 见下表 |
| 自建 | 见 `home/dot_agents/skills/` | 由 chezmoi 部署 |

实际加载 42 个 = `~/.agents/skills/` 27 个（自建 12 + mattpocock 9 + `openspec-*` 6）+ 插件 15 个（2026-11-01）。
`openspec-*` 由 `openspec-bridge skills` 生成，见 `docs/OPENSPEC-BRIDGE.md`；不在 chezmoi 源里，别手工改。
mattpocock 这 9 个里 4 个 hidden（`grill-me`、`grill-with-docs`、`teach`、`to-questionnaire`）只走
`/skill:<name>`；进系统提示的是 38 个。

mattpocock 只装这 9 个（AUTO = 非 hidden，进系统提示、可被模型自动触发）：

| Skill | 模式 | 用途 |
|---|---|---|
| `grill-me` | hidden | `grilling` 的薄别名；正文只有一行 `Call the Skill tool`，见 §5.4 |
| `grilling` | AUTO | 按设计树逐轮拷问计划/决策，frontier 清空才停 |
| `grill-with-docs` | hidden | `grilling` + `domain-modeling`：拷问的同时产出 ADR/glossary |
| `teach` | hidden | `/skill:teach <主题>`：多会话教学工作区（`lessons/` + 4 个 `*-FORMAT.md`） |
| `domain-modeling` | AUTO | glossary / ADR 的术语与决策落地；`grill-with-docs` 的依赖 |
| `research` | AUTO | 后台 agent 查一手来源并落盘 |
| `prototype` | AUTO | 一次性逻辑/UI 原型 |
| `wizard` | AUTO | 交互式 bash 向导（WSL URL、gh secret、.env） |
| `to-questionnaire` | hidden | 向他人收集决策；只能 `/skill:to-questionnaire` 触发 |

**故意不装**：`pr`（PR 正文模板，2026-11-01 移出指定集合，需要时按 §3.2 装回）；`tdd`、`code-review`、
`diagnosing-bugs`、`writing-for-agents`（与 superpowers 同功能，会抢触发）；`to-spec` / `to-tickets` /
`implement*` / `triage` / `wayfinder` / `setup-matt-pocock-skills`（整套 issue-tracker SDLC，与 openspec +
superpowers 流程冲突）。
可选未装：`codebase-design`（与 `architecture-design` 中等重叠）。

## 3. 安装

### 3.1 自建 skill

```bash
# 新 skill：直接写进 chezmoi 源，避免 ~/.agents 成为第二个真身
mkdir -p ~/.dotfiles/home/dot_agents/skills/<name>
$EDITOR ~/.dotfiles/home/dot_agents/skills/<name>/SKILL.md
da            # diff-then-apply
```

`SKILL.md` 必须有一层目录：`~/.agents/skills/<name>/SKILL.md`，omp 不递归发现。

### 3.2 mattpocock

先看清单（2026-11-01 上游 39 个，`software-factory` 因 YAML 错误被 CLI 跳过，实际 38）：

```bash
npx skills@latest add mattpocock/skills --list
```

按名字装，**必须同时带 `-g` 和 `-s`**：

```bash
npx skills@latest add mattpocock/skills -g \
  -s grill-me -s grilling -s grill-with-docs -s teach -s domain-modeling \
  -s research -s prototype -s wizard -s to-questionnaire
```

全装（不推荐：会引入 4 个与 superpowers 抢触发的技能，外加大量低相关技能）：

```bash
npx skills@latest add mattpocock/skills -g -s '*'
```

### 3.3 superpowers

```bash
omp plugin install github:obra/superpowers
omp plugin list                  # 期望：superpowers@<version>
omp plugin doctor                # 期望：0 errors
```

`github:obra/superpowers` 跟踪默认分支，每次 upgrade 取最新。要钉死版本用
`github:obra/superpowers#v7.0.1`，但之后 `upgrade` 不会移动，需重新 install。

## 4. 更新

### 4.1 检查

```bash
npx skills@latest ls -g
omp plugin list
omp read skill://no-such-skill 2>&1 | head -2   # 列出实际加载的 skill 名
```

**不要用 `npx skills@latest check`。** 2026-11-01 实测：本机在 agent 内运行时，它不只是检查，
而是直接更新了 lock 里全部 18 个陈旧条目、把它们装回 `~/.agents/skills/`。要看版本用 `ls -g`。

### 4.2 mattpocock

只更新已装的名字，不要裸 `update -g`（lock 里还有已删技能的陈旧记录）：

```bash
npx skills@latest update -g grill-me grilling grill-with-docs teach domain-modeling \
  research prototype wizard to-questionnaire
```

### 4.3 superpowers

```bash
omp plugin upgrade superpowers
```

omp 不会热更新当前会话的技能列表：重开会话，或在 TUI 里 `/reload-plugins`。

### 4.4 更新后验收

```bash
omp plugin list
omp plugin doctor
npx skills@latest ls -g

jq -r '.skills | to_entries[]
  | select(.key|IN("grill-me","grilling","grill-with-docs","teach","domain-modeling",
                   "research","prototype","wizard","to-questionnaire"))
  | "\(.key) \(.value.updatedAt)"' \
  ~/.local/state/skills/.skill-lock.json

omp read skill://brainstorming | head -1   # 应指向 ~/.local/share/omp/plugins/…/superpowers/
omp read skill://grilling | head -1        # 应指向 ~/.agents/skills/grilling
omp read skill://grill-with-docs | head -1 # hidden 别名也应指向 ~/.agents/skills/
omp read skill://teach | head -1
omp read skill://domain-modeling | head -1
```

证明 mattpocock 文件与上游一致（blob SHA 与 GitHub API 的 `.sha` 相同）：

```bash
git hash-object -t blob ~/.agents/skills/grilling/SKILL.md
curl -fsSL https://api.github.com/repos/mattpocock/skills/contents/skills/productivity/grilling/SKILL.md | jq -r .sha
```

superpowers 版本以 `omp plugin list` 为准；目录版本身份：

```bash
grep -m1 '"version"' ~/.local/share/omp/plugins/node_modules/superpowers/package.json
```

## 5. 坑

1. **裸 `add` 在 agent 里会全装到当前项目。** `npx skills` 检测到 `CLAUDECODE=1` 等标记后自动
   设 `-y`，跳过选择与 scope 询问，默认 **project**（`./.agents/skills/`），38 个全下。
   永远显式 `-g -s`。
2. `-s '*'` 不是“装插件声明的 27 个”，CLI 按目录递归发现 38 个（含 `in-progress/`、`misc/`）。
3. `disable-model-invocation: true` = hidden：不进系统提示、不自动触发，仍可 `/skill:<name>`。
   本机 hidden 有 4 个：`grill-me`、`grill-with-docs`、`teach`、`to-questionnaire`。
4. 部分 mattpocock 技能正文写 “Call the Skill tool with X”，omp 没有 `Skill` 工具。读到就换成
   `read skill://X`。本机已装的 `grill-me`（→`grilling`）、`grill-with-docs`（→`grilling` +
   `domain-modeling`）都是这种一行的别名；未装的 `retro`、`improve-codebase-architecture` 同理。
5. `npx skills` 检测到 Claude Code 时会建 `~/.claude/skills/<name>` 符号链接，每次 `add` 都会重建。
   omp 会**优先**解析 `~/.claude/skills/`，留着会让 `omp read skill://X` 指向那里；本机一律删掉
   该目录（真身仍在 `~/.agents/skills/`），删后 omp 回到 `~/.agents/skills/`。
6. `.skill-lock.json` 会保留已删除技能的记录；判断实际安装看 `ls -g`，不要只看 jq。
7. 本机 omp 走 XDG 根 `~/.local/share/omp/plugins`；旧 `~/.omp/plugins` 已清理。
   换机器时先 `omp plugin list` 确认生效根，别按旧路径排查。
8. 安装摘要里的 `Failed to install N` 不等于失败：那是 PromptScript 目标不支持 `-g` 的逐目标报错，
   universal/agents 目标已经写进 `~/.agents/skills/`。判定用目录内容或 `npx skills ls -g`。

## 6. 回滚 / 卸载

```bash
# superpowers：卸载插件
omp plugin uninstall superpowers

# mattpocock：按名字移除（同时清 lock 与 Claude 链接）
npx skills@latest remove -g grill-me grilling grill-with-docs teach domain-modeling \
  research prototype wizard to-questionnaire

# 自建：回退 dotfiles
git -C ~/.dotfiles revert <commit>
da
```

若要改回“superpowers 用 `~/.agents` 副本”而不是插件：先卸插件，再按 tag 取文件到
`~/.agents/skills/`，不要两边并存。

Trae CN 旧副本已清理；需要时从备份恢复：

```bash
tar -C ~/.trae-cn -xzf ~/.local/share/skill-cleanup-backups/trae-skills-2026-11-01.tgz
```

## 7. 更新记录

升级后同步改第 2 节的版本号/数量，并在下表追加一行。

| 日期 | 组件 | 版本/变更 | 备注 |
|---|---|---|---|
| 2026-11-01 | superpowers | 6.4.1 → **7.0.1** | 改为 omp 插件；移除 `~/.agents` 下 15 个旧副本 |
| 2026-11-01 | mattpocock | 5 个（pr/research/prototype/wizard/to-questionnaire） | 首次纳入台账 |
| 2026-11-01 | 清理 | 删 `~/.omp/plugins`、`~/.claude/skills`、`grill-me`、失效 lock、`~/.trae-cn/skills`、`~/superpowers`、`~/workspace/superpowers` | Trae 备份 `~/.local/share/skill-cleanup-backups/trae-skills-2026-11-01.tgz`；加载 34 → 33 |
| 2026-11-01 | 台账修正 | mattpocock 5 → **6**（补 `grilling`）；加载 33 → **39** | `grilling` 一直在 `~/.agents/skills/`（lock 源 mattpocock），安装/更新/卸载命令漏了它；`openspec-*` 6 个也漏记 |
| 2026-11-01 | mattpocock | 6 → **9**（+`grill-me`、`grill-with-docs`、`teach`、`domain-modeling`；−`pr`） | 指定集合定为这 9 个；`domain-modeling` 是 `grill-with-docs` 的依赖（后者正文只有一行别名）；加载 39 → 42；删掉重建的 `~/.claude/skills` |
