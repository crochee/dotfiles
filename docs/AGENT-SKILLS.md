# AGENT-SKILLS.md — 技能安装、版本更新与回滚

> 本机只有 omp 消费 skills。第三方技能**不要手改** `~/.agents/skills/` 里的文件；
> 更新走各自安装器。自建技能改 `~/.dotfiles/home/dot_agents/skills/`，再 `da` 部署。
> `docs/` 只存在于本仓，不部署到 `$HOME`。
>
> 当前台账日期：2026-11-02。

## 0. 一张表

| 目标 | 命令 |
|---|---|
| 看装了哪些 | `npx skills@latest ls -g` / `omp plugin list` |
| 看 mattpocock 现状 | `npx skills@latest ls -g` |
| 更新 mattpocock | `npx skills@latest update -g <name>...` |
| 更新 deep-research | `da`（自建技能，走 chezmoi） |
| 更新 superpowers | `omp plugin upgrade superpowers` |
| 体检插件 | `omp plugin doctor` |
| 看 omp 实际解析到哪个文件 | `omp read skill://<name> \| head -1` |

## 1. 三类来源

| 来源 | 安装器 | 源 | 落点 | 状态 |
|---|---|---|---|---|
| 自建 skills | chezmoi | `home/dot_agents/skills/` | `~/.agents/skills/<name>/` | git |
| `mattpocock/skills` | `npx skills`（vercel-labs） | GitHub `mattpocock/skills` | `~/.agents/skills/<name>/` | `~/.local/state/skills/.skill-lock.json` |
| `superpowers` | omp plugin | GitHub `obra/superpowers` | `~/.local/share/omp/plugins/node_modules/superpowers/skills/` | `~/.local/share/omp/plugins/omp-plugins.lock.json` |

`deep-research` 2026-11-02 由第三方 npx 安装迁入自建（chezmoi）一类，见 §7。
**自建技能与第三方技能不能同名**：两者都写 `~/.agents/skills/<name>/`，最后写的赢。

**不要在 `~/.agents/skills/` 里再放一份 superpowers。** 名字会与插件重复，omp 需要命名空间消歧，
自动选择变得不可预测。两种来源只能留一种；本机当前选插件。

旧根 `~/.omp/plugins` 已在 2026-11-01 清理；本机只认 XDG 根。
如果它再次出现，先跑 `omp plugin list` 确认生效根，不要按旧路径排查或直接复制。

## 2. 当前台账（2026-11-02）

| 组件 | 版本 | 说明 |
|---|---|---|
| superpowers | **7.0.1** | omp 插件，15 个 skill + 启动 extension |
| mattpocock | 7 个 | 见下表 |
| 自建 | 13 个 | 见 `home/dot_agents/skills/`，由 chezmoi 部署；含 `deep-research` |

实际加载 41 个 = `~/.agents/skills/` 26 个（自建 13 + mattpocock 7 + `openspec-*` 6）+ 插件 15 个（2026-11-02）。
`openspec-*` 由 `openspec-bridge skills` 生成，见 `docs/OPENSPEC-BRIDGE.md`；不在 chezmoi 源里，别手工改。
mattpocock 这 7 个里 3 个 hidden（`grill-with-docs`、`teach`、`to-questionnaire`）只走 `/skill:<name>`；
进系统提示的是 38 个。

mattpocock 只装这 7 个（AUTO = 非 hidden，进系统提示、可被模型自动触发）：

| Skill | 模式 | 用途 |
|---|---|---|
| `grilling` | AUTO | 按设计树逐轮拷问计划/决策，frontier 清空才停（30 行，唯一的拷问实现） |
| `grill-with-docs` | hidden | 一键入口：拷问 + 同步产出 ADR/glossary（= `grilling` + `domain-modeling`） |
| `domain-modeling` | AUTO | glossary / ADR 的术语与决策落地；`grill-with-docs` 的依赖，单独也能用（74 行） |
| `prototype` | AUTO | 一次性逻辑/UI 原型 |
| `wizard` | AUTO | 交互式 bash 向导（WSL URL、gh secret、.env） |
| `teach` | hidden | `/skill:teach <主题>`：多会话教学工作区（`lessons/` + 4 个 `*-FORMAT.md`） |
| `to-questionnaire` | hidden | 向他人收集决策；只能 `/skill:to-questionnaire` 触发 |

研究技能（本机唯一的 AUTO 研究技能，自建）：

| Skill | 模式 | 用途 |
|---|---|---|
| `deep-research` | AUTO | 证据优先的深度研究：自适应 effort（quick→exhaustive）+ 证据台账 + 反证检索 + 每条结论打标签（`single-source`/`contested`/`stale`）；纯标准库脚本。**自建**，源码 `home/dot_agents/skills/deep-research/` |

**故意不装**：`research`（mattpocock 版只有「起后台 agent + 一手源 + 落一个 MD」，无台账/反证/不确定性标签，
2026-11-02 由 `deep-research` 取代，需要时按 §3.2 装回）；`last30days`（另一个轴：近 30 天社区舆情，
本机缺 `yt-dlp` 与全部 API key，只剩 HN/Polymarket 免费源；而且它是 AUTO，会再占一个研究类触发位）；
`grill-me`（上游只有一行 `Call the Skill tool with "grilling".`，与 `grilling` 完全重复，
且 omp 没有 `Skill` 工具）；`pr`（PR 正文模板，2026-11-01 移出指定集合，需要时按 §3.2 装回）；`tdd`、
`code-review`、`diagnosing-bugs`、`writing-for-agents`（与 superpowers 同功能，会抢触发）；`to-spec` /
`to-tickets` / `implement*` / `triage` / `wayfinder` / `setup-matt-pocock-skills`（整套 issue-tracker SDLC，
与 openspec + superpowers 流程冲突）。
可选未装：`codebase-design`（与 `architecture-design` 中等重叠）。

## 3. 安装

### 3.1 自建技能

```bash
# 新 skill：直接写进 chezmoi 源，避免 ~/.agents 成为第二个真身
mkdir -p ~/.dotfiles/home/dot_agents/skills/<name>
$EDITOR ~/.dotfiles/home/dot_agents/skills/<name>/SKILL.md
da            # diff-then-apply
```

`SKILL.md` 必须有一层目录：`~/.agents/skills/<name>/SKILL.md`，omp 不递归发现。

本仓自建 13 个：`agent-engineering`、`api-design`、`architecture-design`、`de-ai-tone`、
`deep-research`、`frontend-design`、`golang-dev`、`k8s-operator`、`legal-risk-auditor`、
`python-dev`、`repo-wiki`、`rust-dev`、`technical-writing`。

自建技能的前置检查：frontmatter 只允许 `name`、`description`、`license`、`compatibility`、
`metadata`、`allowed-tools` 六个键。`version` 放 `metadata` 里；顶层写 `version` 会被
`agentskills validate` 判不合格（见 §4.5）。

### 3.2 mattpocock

先看清单（2026-11-01 上游 39 个，`software-factory` 因 YAML 错误被 CLI 跳过，实际 38）：

```bash
npx skills@latest add mattpocock/skills --list
```

按名字装，**必须同时带 `-g` 和 `-s`**：

```bash
npx skills@latest add mattpocock/skills -g \
  -s grilling -s grill-with-docs -s domain-modeling -s prototype \
  -s wizard -s teach -s to-questionnaire
```

全装（不推荐：会引入 4 个与 superpowers 抢触发的技能，外加大量低相关技能）：

```bash
npx skills@latest add mattpocock/skills -g -s '*'
```

### 3.3 deep-research

**自建**，不走 npx。源码在 `home/dot_agents/skills/deep-research/`，由 chezmoi 部署到 <!-- scan: ignore E3 标题是章节名，首行给的是安装方式和源码位置 -->
`~/.agents/skills/deep-research/`。它原本是第三方安装（`B143KC47/deep-research-skill` v1.0.3，MIT），
2026-11-02 迁入本仓重写，见 §7。

迁入前必须先腾出路径，否则 npx 安装器与 chezmoi 会抢同一个目录：

```bash
npx skills@latest remove -g deep-research -y
npx skills@latest ls -g | grep deep-research    # 期望：无输出
jq -r '.skills | keys[]' ~/.local/state/skills/.skill-lock.json | grep deep-research  # 期望：无输出
```

本机 `npx skills@latest remove` 会把目录和 lock 记录一起清干净，没有残留。

源码树（`references/` 6 篇，`scripts/` 纯标准库，`evals/` + `tests/` 不部署到别处）：

```
home/dot_agents/skills/deep-research/
├── SKILL.md
├── agents/openai.yaml
├── references/{research-protocol,source-quality,query-playbook,academic-sources,report-template,evaluation}.md
├── scripts/research_ledger.py
├── evals/{evals.json,trigger_queries.json}
└── tests/{run.py}
```

实测产物（`evals/*_results.json`）不入库，由 `.gitignore` 与 `home/.chezmoiignore.tmpl` 拦住。

部署与自检：

```bash
da                                     # diff-then-apply
python3 ~/.agents/skills/deep-research/tests/run.py                    # 期望：OK
uvx --from skills-ref agentskills validate ~/.agents/skills/deep-research  # 期望：Valid skill
```

台账 run 目录统一用 `~/.local/state/research_runs`（技能默认值已改，不写 `/mnt/data`）：

```bash
python3 ~/.agents/skills/deep-research/scripts/research_ledger.py init \
  --question "<问题>" --out-dir ~/.local/state/research_runs --effort standard
```

### 3.4 superpowers

```bash
omp plugin install github:obra/superpowers
omp plugin list                  # 期望：superpowers@<version>
omp plugin doctor                # 期望：0 errors
```

`github:obra/superpowers` 跟踪默认分支，每次 upgrade 取最新。要钉死版本用 <!-- scan: ignore E3 标题是章节名，首行给的是上游仓库和升级策略 -->
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
npx skills@latest update -g grilling grill-with-docs domain-modeling prototype wizard teach to-questionnaire
```

### 4.3 deep-research

自建技能，更新走 chezmoi，没有独立安装器：

```bash
git -C ~/.dotfiles pull && da       # 取上游改动并 diff-then-apply
```

要回退某个版本：`git -C ~/.dotfiles revert <commit> && da`（见 §6）。

### 4.4 superpowers

```bash
omp plugin upgrade superpowers
```

omp 不会热更新当前会话的技能列表：重开会话，或在 TUI 里 `/reload-plugins`。

### 4.5 更新后验收

```bash
omp plugin list
omp plugin doctor
npx skills@latest ls -g

jq -r '.skills | to_entries[]
  | select(.key|IN("grilling","grill-with-docs","domain-modeling","prototype",
                   "wizard","teach","to-questionnaire"))
  | "\(.key) \(.value.updatedAt)"' \
  ~/.local/state/skills/.skill-lock.json

jq -r '.skills | has("deep-research")' ~/.local/state/skills/.skill-lock.json   # 期望：false

omp read skill://brainstorming | head -1   # 应指向 ~/.local/share/omp/plugins/…/superpowers/
omp read skill://grilling | head -1        # 应指向 ~/.agents/skills/grilling
omp read skill://grill-with-docs | head -1 # hidden 一键入口，同样在 ~/.agents/skills/
omp read skill://domain-modeling | head -1 # 应指向 ~/.agents/skills/domain-modeling
omp read skill://teach | head -1
omp read skill://deep-research | head -1   # 应指向 ~/.agents/skills/deep-research

ls ~/.agents/skills/deep-research/          # 期望：SKILL.md agents evals references scripts tests
```

自建技能过一遍规格闸门（frontmatter 只允许六个键；`version` 必须在 `metadata` 里）：

```bash
uvx --from skills-ref agentskills validate ~/.agents/skills/deep-research   # 期望：Valid skill
python3 ~/.agents/skills/deep-research/tests/run.py                       # 期望：OK
python3 bin/skill-trigger-eval --skills all                            # 期望：13 行全 PASS
chezmoi diff ~/.agents/skills/deep-research                                # 期望：无输出
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
2. `-s '*'` 不是「装插件声明的 27 个」，CLI 按目录递归发现 38 个（含 `in-progress/`、`misc/`）。
3. `disable-model-invocation: true` = hidden：不进系统提示、不自动触发，仍可 `/skill:<name>`。
   本机 hidden 有 3 个：`grill-with-docs`、`teach`、`to-questionnaire`。
4. 上游有一批「空壳别名」技能，正文只有一行 `Call the Skill tool with "X"`。omp 没有 `Skill` 工具，
   这类别名不成立，**别装**：`grill-me`（与 `grilling` 重复）、`retro`、`improve-codebase-architecture`。
   `grill-with-docs` 是例外，故意留着当「一键拷问 + 出文档」入口：它在 omp 里等价于
   `read skill://grilling` + `read skill://domain-modeling` 依次执行。
5. `npx skills` 检测到 Claude Code 时会建 `~/.claude/skills/<name>` 符号链接，每次 `add` 都会重建。
   omp 会**优先**解析 `~/.claude/skills/`，留着会让 `omp read skill://X` 指向那里；本机一律删掉
   该目录（真身仍在 `~/.agents/skills/`），删后 omp 回到 `~/.agents/skills/`。
6. `.skill-lock.json` 会保留已删除技能的记录；判断实际安装看 `ls -g`，不要只看 jq。
7. 本机 omp 走 XDG 根 `~/.local/share/omp/plugins`；旧 `~/.omp/plugins` 已清理。
   换机器时先 `omp plugin list` 确认生效根，别按旧路径排查。
8. 安装摘要里的 `Failed to install N` 不等于失败：那是 PromptScript 目标不支持 `-g` 的逐目标报错，
   universal/agents 目标已经写进 `~/.agents/skills/`。判定用目录内容或 `npx skills ls -g`。
9. **自建技能与第三方技能不能同名。** `npx skills` 与 chezmoi 都写 `~/.agents/skills/<name>/`，
   谁后写谁赢，`chezmoi apply` 会把 npx 装的版本覆盖掉，npx 的 update 又会把 chezmoi 的版本盖掉。
   迁移一个技能到自建时，先 `npx skills@latest remove -g <name> -y` 腾出路径，再建 chezmoi 源。
10. **自建技能的 frontmatter 只有六个键。** `name`、`description`、`license`、`compatibility`、
    `metadata`、`allowed-tools`。顶层写 `version` 会被 `agentskills validate` 判不合格
    （`Unexpected fields in frontmatter: version`）；版本号放 `metadata.version`。
    规格闸门：`uvx --from skills-ref agentskills validate ~/.agents/skills/<name>`。

## 6. 回滚 / 卸载

```bash
# superpowers：卸载插件
omp plugin uninstall superpowers

# mattpocock：按名字移除（同时清 lock 与 Claude 链接）
npx skills@latest remove -g grilling grill-with-docs domain-modeling prototype wizard teach to-questionnaire

# deep-research：自建技能，回退 dotfiles 即可
git -C ~/.dotfiles revert <commit> && da
```

若要改回「superpowers 用 `~/.agents` 副本」而不是插件：先卸插件，再按 tag 取文件到
`~/.agents/skills/`，不要两边并存。

Trae CN 旧副本已清理；需要时从备份恢复：

```bash
tar -C ~/.trae-cn -xzf ~/.local/share/skill-cleanup-backups/trae-skills-2026-11-01.tgz
```

## 7. 自建技能写作标准

13 个自建技能（`home/dot_agents/skills/`）共同遵守下面六条。它们来自 Agent Skills 开放规格
（frontmatter 与目录结构）加本仓的两条额外约束（常驻 token 预算、零 harness 依赖）。

### 7.1 frontmatter

只允许六个键：`name`、`description`、`license`、`compatibility`、`metadata`、`allowed-tools`。
本仓 13 个统一 `license: MIT`，版本写在 `metadata.version`（加引号的 `"x.y.z"`），改内容就
bump 一个 minor。

```bash
uvx --from skills-ref agentskills validate ~/.agents/skills/<name>   # 期望：Valid skill
```

### 7.2 description

三段式，一行写完，≤1024 字符：

```
<产出物>。Use when <场景 + 可检索关键词>。Not for <排除项>。中文：<中文关键词>
```

- `Not for` 段点名邻接技能（`api-design`、`technical-writing` …），描述之间互相排斥，触发才分得开。
- 中文触发行让中文提问也能命中；已经用中文写的 description 不必再加。
- `name` 必须等于目录名，全小写、单词间单连字符。

### 7.3 body ≤150 行

计的是 frontmatter 之后的行：

```bash
for f in home/dot_agents/skills/*/SKILL.md; do
  printf '%4d %s\n' "$(awk '/^---$/{c++;next} c>=2' "$f" | wc -l)" "$f"
done | sort -rn | head -3        # 期望：最大 ≤150
```

body 只放「什么时候用、按什么顺序做、每步的退出标准、交付物、验收清单」。表格、对照表、长示例
下沉到 `references/`，body 里留一到三行指针。

### 7.4 零 harness 依赖

技能在任意 agent 下都要能读：不写宿主工具名、URI 协议、部署路径、插件名。

```bash
rg -n --no-heading '(skill://|xd://|agent://|\bomp\b|superpowers|~/\.agents|/home/crochee|Claude Code|\bCodex\b|\bGemini\b|`grilling`|`prototype`|`brainstorming`|`research`|subagent-driven-development|executing-plans|dispatching-parallel-agents)' \
  home/dot_agents/skills --glob 'SKILL.md' --glob 'references/**'
```

唯一的历史例外是 `api-design` 讲分页时用到的 `Cursor` 一词（泛指分页游标，不是编辑器），它不在
这个正则的命中范围里；加载技能一律写成「the way your agent loads it」。期望：无输出（`rg` 退出码 1）。

### 7.5 references 与链接

`references/` 一层深，正文用相对路径 `references/<file>.md`；每个 reference 开头一句 <!-- scan: ignore E3 标题里的 references 指章节主题，首行说的是目录层级 -->
「Load this reference when: …」，并在 `## References` 表里有一行。模板放 `assets/`。

### 7.6 触发实测

每个技能带 `evals/trigger_queries.json`：24 条查询（正例 12 = 中文 6 + 英文 6，反例 12 同），
其中正例 3 条、反例 3 条标 `holdout`。查询必须自包含——运行目录是空的临时目录，不能引用
「附件」「上面的文件」「这个仓库」。

```json
{"skill": "api-design", "workflow_marker": "x-conventions",
 "queries": [{"query": "帮我给订单接口设计游标分页", "should_trigger": true, "holdout": false}]}
```

```bash
python3 bin/skill-trigger-eval --skills all --runs 3 --jobs 8 \
  --max-time 120 --session-timeout 150                          # 13 行全 PASS，退出码 0
```

这组参数是本机实测通过的配置：13 个技能 × 24 条查询 × 3 轮 ≈ 936 次真实 agent 会话，墙钟约 2.9h。
`--jobs` 再往上加这台机器就扛不住了（13 路并发时 agent 启动被拖过 240s，正例根本读不到技能，
采样作废）；压 `--max-time` 同理会砍掉正例的采样窗口。

判定：正例看 consult（读到 `skill://<name>`）通过线 0.8；反例有 `workflow_marker` 时看
workflow ≤0.2，没有时看 consult ≤0.2；holdout 子集单独判一遍。反例的 consult 率只作诊断字段，
不进 gate——被读一次就污染上下文的技能是 description 问题，不是工作流接管。结果写进
`evals/trigger_results.json`，已 gitignore，不入库。

**参数怎么选**（一次全量 ≈ 900 次真实会话，墙钟由反例决定：反例不会提前停）：

| 参数 | 默认 | 作用 |
|---|---|---|
| `--runs` | 3 | 每条查询的采样次数。3 是噪声下限；边界查询用 5+ |
| `--jobs` | 4 | 并发评估的技能数。技能内查询串行，加并发只加吞吐、不减单技能耗时 |
| `--max-time` | 120 | 传给 agent 的单场上限，秒。压它＝压反例时长，但晚于上限才出现的 workflow marker 会漏检 |
| `--session-timeout` | 240 | runner 的硬杀线，秒，要 ≥ `--max-time` |

反例跑满整场（agent 自己在把活干完）会记一条 `the session exceeded …s` 警告——那是期望行为，
gate 数值不受影响；正例若出现同类警告，说明采样被截断，该技能的通过率要打折看。

## 8. 更新记录

升级后同步改第 2 节的版本号/数量，并在下表追加一行。

| 日期 | 组件 | 版本/变更 | 备注 |
|---|---|---|---|
| 2026-11-01 | superpowers | 6.4.1→**7.0.1** | 改为 omp 插件；移除 `~/.agents` 下 15 个旧副本 |
| 2026-11-01 | mattpocock | 5 个（pr/research/prototype/wizard/to-questionnaire） | 首次纳入台账 |
| 2026-11-01 | 清理 | 删 `~/.omp/plugins`、`~/.claude/skills`、`grill-me`、失效 lock、`~/.trae-cn/skills`、`~/superpowers`、`~/workspace/superpowers` | Trae 备份 `~/.local/share/skill-cleanup-backups/trae-skills-2026-11-01.tgz`；加载 34→33 |
| 2026-11-01 | 台账修正 | mattpocock 5→**6**（补 `grilling`）；加载 33→**39** | `grilling` 一直在 `~/.agents/skills/`（lock 源 mattpocock），安装/更新/卸载命令漏了它；`openspec-*` 6 个也漏记 |
| 2026-11-01 | mattpocock | 6→**9**（+`grill-me`、`grill-with-docs`、`teach`、`domain-modeling`；−`pr`） | 指定集合定为这 9 个；`domain-modeling` 是 `grill-with-docs` 的依赖（后者正文只有一行别名）；加载 39→42；删掉重建的 `~/.claude/skills` |
| 2026-11-01 | mattpocock | 9→**7**（−`grill-me`、`grill-with-docs`） | 这两个是上游一行别名（`Call the Skill tool with …`），omp 无 `Skill` 工具，别名不成立；真身 `grilling` + `domain-modeling` 已单独装。加载 42→40 |
| 2026-11-01 | mattpocock | 7→**8**（+`grill-with-docs`） | `grill-with-docs` 有独立价值：一键「拷问 + 出 ADR/glossary」，等价于 `grilling` + `domain-modeling` 连调；只删 `grill-me`。加载 40→41 |
| 2026-11-02 | 研究技能 | `research`→**`deep-research`**（`B143KC47/deep-research-skill` v1.0.3，MIT） | mattpocock 版只有 prompt（后台 agent + 一手源 + 一个 MD）；deep-research 有自适应 effort、证据台账、反证检索、结论打标签，纯标准库脚本本机实测可跑。`last30days` 评估后不装（缺 yt-dlp 与全部 key）。加载数不变（41），mattpocock 8→7，新增第三类 npx 来源（**同日又迁入自建，见下行**） |
| 2026-11-02 | deep-research | 第三方 npx→**自建（chezmoi）** | 源码迁入 `home/dot_agents/skills/deep-research/`，从 `B143KC47/deep-research-skill` v1.0.3（MIT，tree `a2f7003b71eb98177712ab13de9fbe3ee6acf2a9`）clean-room 重写：保留 CSV schema、effort 阶梯、lint 检查，修掉 22 处缺陷（`--name ../victim` 越界删除、lint/status 改写 CSV、截断 CSV 崩溃、source_family 回落 domain、effort 阶梯三处漂移、无 report renderer、secret 写盘后才扫描、引用正则 `E\d{4}` 漏检、反证两套定义、PRIMARY_TYPES 过宽等），并吸收 `mattpocock/skills` `engineering/research` 的 planner/retriever/verifier/synthesizer 分工（父 agent 是唯一写台账的人）与 hermes `arxiv` 的 arXiv/Semantic Scholar 配方。来源类别 4→3；自建 12→**13**；`~/.agents/skills/` 仍 26 个、加载总数仍 41（同名替换，不增不减）。新增 `agentskills validate` 规格闸门与 `tests/run.py`（37 项）、`tests/trigger_eval.py` |
| 2026-11-02 | deep-research | description 收紧 + 触发闸门改为双信号（实测） | 首轮触发实测：10 条正例全部 100% 命中，但 10 条反例里有 7 条也命中：上游那种「触发名词清单」式 description 会把「什么是文献综述」「列一下 RAG 论文标题」「随便聊聊研究为什么难」都吸进来。description 改了四版（以交付物为触发条件→去掉领域名词→去掉来源清单→加 "a single-source answer"），正例保持 67–100%。同时发现两个测量问题并修掉：（1）3 条反例引用了不存在的附件，agent 会去找文件、误读技能；已改成自包含；（2）3 次采样噪声大到一条查询 3 次测 100%、9 次测 33%；默认 run 数与告警写进 harness。闸门改为双信号：正例看 **consult**（skill 的 SKILL.md 被读），反例看 **workflow**（台账脚本真被调用）：录屏证明反例里模型是中途查一下技能、活照干、交付物不变，所以「被读」不等于「被用」。实测：26/26 通过（tuning 20/20、holdout 6/6），退出码 0；残余风险也照实报：13 条反例里 7 条仍会被 consult（名字带 research，查文献类问题就会被看一眼），其中 2 条各有 1/3 的 run 真把流程接了过去 |
| 2026-11-02 | 13 个自建技能 | 标准化：`license: MIT` + `metadata.version` bump、描述三段式、body ≤150 行、零 harness 依赖、单一 eval runner | 描述统一成「产出物 / Use when / Not for / 中文」，无中文触发行的 11 个补齐；5 个超长 body 下沉到 `references/`（`de-ai-tone` 213→142、`repo-wiki` 208→148、`frontend-design` 181→144、`technical-writing` 173→131、`agent-engineering` 159→142），`de-ai-tone` 的 44 模式表移到 `references/patterns-index.md` 并同步两个 drift 门禁；清掉 11 处宿主耦合（`subagent-driven-development`、`grilling`、`prototype`、`brainstorming`、`research`、`skill://`、`~/.agents/skills/…`、`omp`）；13 个 `evals/trigger_queries.json` 迁到 v2 形状（`skill` + `workflow_marker` + `queries`，每技能 24 条、正反各 12、各 3 条 holdout），触发实测统一走 `bin/skill-trigger-eval`（4 路并发、正例 consult ≥0.8、反例 workflow ≤0.2），删掉两份 omp 专用 runner；规格闸门 `uvx --from skills-ref agentskills validate` 13/13 通过，写作标准写进 §7 |
| 2026-11-04 | 13 个自建技能 | 触发实测全量通过（13/13 PASS，退出码 0）+ runner 两个 bug 修复 | 实测参数 `--runs 3 --jobs 8 --max-time 120 --session-timeout 150`，936 次真实会话，墙钟 2.9h；`deep-research` 改了 3 轮描述（把「核对结论/指标」写进 Use when，把「按来源核对的摘要」从 Not for 里放出去）才过，`python-dev` 改了 1 轮（Use when 重排成 4 组动宾结构）；runner 修了两个真 bug：超时只在读到输出时才检查（安静会话永远等不到超时）→ 改成后台线程读流 + 队列轮询 deadline；杀进程只杀直接子进程（孙进程留着 stdout 句柄把会话吊住）→ 改成杀整个进程组 |
