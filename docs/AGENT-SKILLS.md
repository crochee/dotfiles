# AGENT-SKILLS.md — 技能安装、版本更新与回滚

> 本机只有 omp 消费 skills。第三方技能**不要手改** `~/.agents/skills/` 里的文件；
> 更新走各自安装器。自建技能改 `~/.dotfiles/home/dot_agents/skills/`，再 `da` 部署。
> 全局调用约定在 `~/.agents/AGENTS.md`（chezmoi 源 `home/dot_agents/AGENTS.md`）。
> `docs/` 只存在于本仓，不部署到 `$HOME`。
>
> 当前台账日期：2026-11-11。

## 0. 一张表

| 目标 | 命令 |
|---|---|
| 看装了哪些 | `npx skills@latest ls -g` / `omp skills list` |
| 看 mattpocock 现状 | `npx skills@latest ls -g` |
| 更新 mattpocock | `npx skills@latest update -g <name>...` |
| 更新 deep-research | `da`（自建技能，走 chezmoi） |
| 看 omp 实际解析到哪个文件 | `omp read skill://<name> \| head -1` |
| 看插件（应为空） | `omp plugin list` |

## 1. 两类来源

| 来源 | 安装器 | 源 | 落点 | 状态 |
|---|---|---|---|---|
| 自建 skills | chezmoi | `home/dot_agents/skills/` | `~/.agents/skills/<name>/` | git |
| `mattpocock/skills` | `npx skills`（vercel-labs） | GitHub `mattpocock/skills` | `~/.agents/skills/<name>/` | `~/.local/state/skills/.skill-lock.json` |

`deep-research` 2026-11-02 由第三方 npx 安装迁入自建（chezmoi）一类，见 §7。
**自建技能与第三方技能不能同名**：两者都写 `~/.agents/skills/<name>/`，最后写的赢。

2026-11-11 起本机没有第三方插件技能：omp 插件栈为空，spec 驱动的那套 CLI（用户级 schema 桥接 +
桥接脚本 + 6 个生成的技能）连同原插件栈一起移除。调用约定（技能怎么调、流程先后、相似技能分工）
写在 `~/.agents/AGENTS.md`，它替代了原来由插件提供的会话启动 bootstrap。

旧根 `~/.omp/plugins` 已在 2026-11-01 清理；本机只认 XDG 根。
如果它再次出现，先跑 `omp plugin list` 确认生效根，不要按旧路径排查或直接复制。

## 2. 当前台账（2026-11-11）

| 组件 | 数量 | 说明 |
|---|---|---|
| 自建 | 13 个 | 见 `home/dot_agents/skills/`，由 chezmoi 部署；含 `deep-research` |
| mattpocock | 27 个 | 上游 promoted：engineering 20 + productivity 7，见下表 |
| omp 插件 | 0 个 | `omp plugin list` 为空 |

实际加载 40 个 = `~/.agents/skills/` 40 个目录（自建 13 + mattpocock 27），omp 插件 0 个。

进系统提示的是 24 个（自建 13 + 上游 AUTO 11），另外 16 个上游技能**不在**系统提示里：
上游在 SKILL.md frontmatter 标了 `disable-model-invocation: true`，omp 据此把它们排除在
技能清单之外（实测：新会话里问「系统提示的 <skills> 块有哪些」，只回得出 24 个；
另外 16 个仍能用 `read skill://<name>` / `/skill:<name>` 取到）。
所以上游的 AUTO / user-invoked 划分**在本机是生效的**：那 16 个不抢自动触发位。
它们唯一的发现路径是 `~/.agents/AGENTS.md` §2 的名字列表——那份清单是每个会话都加载的
user 级 context 文件，也是自建技能 `Not for` 段与上游技能分工的落点。

自建 13 个：`agent-engineering`、`api-design`、`architecture-design`、`de-ai-tone`、
`deep-research`、`frontend-design`、`golang-dev`、`k8s-operator`、`legal-risk-auditor`、
`python-dev`、`repo-wiki`、`rust-dev`、`technical-writing`。

mattpocock 27 个（上游路径 `skills/engineering/<name>` 或 `skills/productivity/<name>`；
AUTO = 上游未标 `disable-model-invocation: true`，进系统提示、可被模型自动触发；
user-invoked = 上游标了它，不进系统提示，只能点名调用）：

| Skill | 上游目录 | 模式 | 用途 |
|---|---|---|---|
| `ask-matt` | engineering | user-invoked | 问上游作者本人的工程实践问答 |
| `code-review` | engineering | AUTO | 对 `HEAD` 与用户指定基准点之间的 diff 做双轴评审 |
| `codebase-design` | engineering | AUTO | 深模块 / 接缝的接口设计 |
| `diagnosing-bugs` | engineering | AUTO | bug 诊断循环（复现 → 定位 → 验证） |
| `domain-modeling` | engineering | AUTO | glossary / ADR 的术语与决策落地 |
| `grill-with-docs` | engineering | user-invoked | 别名入口：拷问 + 同步产出 ADR/glossary（= `grilling` + `domain-modeling`） |
| `implement` | engineering | user-invoked | 按 spec 或 tickets 实施 |
| `implement-spec` | engineering | user-invoked | 按已有 spec 实施 |
| `improve-codebase-architecture` | engineering | user-invoked | 架构改进建议 |
| `pr` | engineering | AUTO | PR 正文模板 |
| `prototype` | engineering | AUTO | 一次性逻辑/UI 原型 |
| `research` | engineering | AUTO | 快查：起后台 agent + 一手源 + 落一份 MD |
| `retro` | engineering | user-invoked | 复盘：给编码过程提改进建议 |
| `setup-matt-pocock-skills` | engineering | user-invoked | 上游脚手架：本地 issue-tracker 模板等 |
| `tdd` | engineering | AUTO | 红-绿-重构循环 |
| `to-spec` | engineering | user-invoked | 把当前对话与代码库理解转成 spec |
| `to-tickets` | engineering | user-invoked | 把 spec 拆成带验收标准的 tickets |
| `triage` | engineering | user-invoked | 问题分诊 |
| `wayfinder` | engineering | user-invoked | 需求太大、路径不清时定位下一步 |
| `wizard` | engineering | AUTO | 交互式 bash 向导（WSL URL、gh secret、.env） |
| `grill-me` | productivity | user-invoked | 别名入口：等价 `grilling` |
| `grilling` | productivity | AUTO | 按设计树逐轮拷问计划/决策，frontier 清空才停 |
| `handoff` | productivity | user-invoked | 写交接文档，让新 agent 接手当前会话 |
| `teach` | productivity | user-invoked | 多会话教学工作区（`lessons/` + 格式文件） |
| `to-questionnaire` | productivity | user-invoked | 向他人收集决策 |
| `wait-what` | productivity | user-invoked | 对方没听懂时重讲一遍 |
| `writing-for-agents` | productivity | AUTO | 写给 agent 消费的文档（skill / AGENTS.md / CLAUDE.md） |

研究技能并存（本机两个 AUTO 研究技能）：

| Skill | 来源 | 模式 | 用途 |
|---|---|---|---|
| `deep-research` | 自建 | AUTO | 证据优先的深度研究：自适应 effort（quick→exhaustive）+ 证据台账 + 反证检索 + 每条结论打标签（`single-source`/`contested`/`stale`）；纯标准库脚本。源码 `home/dot_agents/skills/deep-research/` |
| `research` | 上游 | AUTO | 快查：后台 agent 读一手源，落一份 MD，无台账与不确定性标签 |

两者分工写在 `~/.agents/AGENTS.md` §3：结论要经得起推敲用 `deep-research`，查资料用 `research`。

**故意不装**：上游非 promoted 目录。`in-progress/` 8 个（`chief-of-staff`、`claude-handoff`、
`loop-me`、`setup-ts-deep-modules`、`software-factory`、`writing-beats`、`writing-fragments`、
`writing-shape`）、`misc/` 4 个（`git-guardrails-claude-code`、`migrate-to-shoehorn`、
`scaffold-exercises`、`setup-pre-commit`）。上游 `deprecated/` 只剩一个 README，没有技能。
`-s '*'` 会把这 12 个也装进来，别用（见 §5）。

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
`agentskills validate` 判不合格（见 §4.4）。

### 3.2 mattpocock

上游 39 个目录 = promoted 27（`skills/engineering/` 20 + `skills/productivity/` 7）
+ `in-progress/` 8 + `misc/` 4。先看清单：

```bash
npx skills@latest add mattpocock/skills --list
```

按名字装，**必须同时带 `-g`、`-a pi` 和 `-s`**：`-g` 是全局 scope，`-a pi` 指定落点
`~/.agents/skills/`（不带 `-a pi` 时 CLI 会挑别的 target，并给 Claude Code 建
`~/.claude/skills/` 软链目录，见 §5），`-s` 显式列名字（`-s '*'` 会把 `in-progress/` 与
`misc/` 那 12 个也装进来）。

```bash
npx skills@latest add mattpocock/skills -g -y -a pi \
  -s ask-matt -s code-review -s codebase-design -s diagnosing-bugs -s domain-modeling \
  -s grill-with-docs -s implement -s implement-spec -s improve-codebase-architecture -s pr \
  -s prototype -s research -s retro -s setup-matt-pocock-skills -s tdd -s to-spec \
  -s to-tickets -s triage -s wayfinder -s wizard \
  -s grill-me -s grilling -s handoff -s teach -s to-questionnaire -s wait-what -s writing-for-agents
```

装完必须确认 `~/.claude/skills` 不存在（有就 `rm -rf`，真身仍在 `~/.agents/skills/`），
并核对 `ls ~/.agents/skills | wc -l` 为 40。

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

## 4. 更新

### 4.1 检查

```bash
npx skills@latest ls -g
omp skills list
omp read skill://no-such-skill 2>&1 | head -2   # 列出实际加载的 skill 名
```

**不要用 `npx skills@latest check`。** 2026-11-01 实测：本机在 agent 内运行时，它不只是检查，
而是直接更新了 lock 里全部 18 个陈旧条目、把它们装回 `~/.agents/skills/`。要看版本用 `ls -g`。

### 4.2 mattpocock

只更新已装的名字，不要裸 `update -g`（lock 里还有已删技能的陈旧记录）：

```bash
npx skills@latest update -g ask-matt code-review codebase-design diagnosing-bugs domain-modeling \
  grill-with-docs implement implement-spec improve-codebase-architecture pr \
  prototype research retro setup-matt-pocock-skills tdd to-spec \
  to-tickets triage wayfinder wizard \
  grill-me grilling handoff teach to-questionnaire wait-what writing-for-agents
```

### 4.3 deep-research

自建技能，更新走 chezmoi，没有独立安装器：

```bash
git -C ~/.dotfiles pull && da       # 取上游改动并 diff-then-apply
```

要回退某个版本：`git -C ~/.dotfiles revert <commit> && da`（见 §6）。

### 4.4 更新后验收

```bash
npx skills@latest ls -g                    # 期望：mattpocock 组 27 行、General 组 13 行
ls ~/.agents/skills | wc -l                # 期望：40
omp skills list | wc -l                    # 期望：40
omp plugin list                            # 期望：空（本机不再有插件技能）

omp read skill://to-spec | head -1         # 期望：[Skill file: …/.agents/skills/to-spec/SKILL.md]
omp read skill://tdd | head -1              # 同理指向 ~/.agents/skills/tdd
omp read skill://research | head -1        # 同理指向 ~/.agents/skills/research
omp read skill://grill-with-docs | head -1  # user-invoked 也能解析
omp read skill://deep-research | head -1    # 期望指向 ~/.agents/skills/deep-research

ls ~/.agents/skills/deep-research/         # 期望：SKILL.md agents evals references scripts tests
```

进系统提示的技能数（user-invoked 的 16 个不在其中）：

```bash
cd /tmp && omp -p --mode=text --no-session --cwd /tmp \
  "List every skill name that appears in the <skills> block of your system prompt, one per line." \
  | grep -c '^[a-z]'        # 期望：24
```

上游 27 个的 lock 记录（`.skill-lock.json` 里应正好 27 条 mattpocock 条目）：

```bash
jq -r '.skills | keys[]' ~/.local/state/skills/.skill-lock.json | sort
```

自建技能过一遍规格闸门（frontmatter 只允许六个键；`version` 必须在 `metadata` 里）：

```bash
uvx --from skills-ref agentskills validate ~/.agents/skills/deep-research   # 期望：Valid skill
python3 ~/.agents/skills/deep-research/tests/run.py                       # 期望：OK
python3 bin/skill-trigger-eval --skills all                            # 期望：13 行全 PASS
chezmoi diff ~/.agents/skills/deep-research                                # 期望：无输出
```

上游文件与上游一致（blob SHA 与 GitHub API 的 `.sha` 相同）：

```bash
git hash-object -t blob ~/.agents/skills/grilling/SKILL.md
curl -fsSL https://api.github.com/repos/mattpocock/skills/contents/skills/productivity/grilling/SKILL.md | jq -r .sha
```

改了 `~/.agents/AGENTS.md` 或换了技能清单后要**重开会话**才生效：omp 在 session 启动时装载
context 文件与技能列表，热会话里读到的还是旧清单。

## 5. 坑

1. **裸 `add` 在 agent 里会全装到当前项目。** `npx skills` 检测到 `CLAUDECODE=1` 等标记后自动
   设 `-y`，跳过选择与 scope 询问，默认 **project**（`./.agents/skills/`），38 个全下。
   永远显式 `-g -s`。
2. `-s '*'` 不是「装上游 promoted 的 27 个」，CLI 按目录递归发现 38 个（含 `in-progress/` 8 个、
   `misc/` 4 个）。要 promoted 就把 27 个名字逐个列出来。
3. **`disable-model-invocation: true` 在本 harness 真的会隐藏技能。** 上游用它表示「只能人手动触发」，
   omp 据此把技能排除在系统提示的技能清单之外。上游 27 个里有 16 个是 user-invoked
   （见 §2 表的「模式」列）；它们仍能用 `read skill://<name>` / `/skill:<name>` 取到，
   但模型不会自己想到它们——唯一的名字清单在 `~/.agents/AGENTS.md` §2。
   对照实验：在临时项目里放四个技能，只有带 `disable-model-invocation: true` 的两个不出现在系统提示里；
   `agents/openai.yaml` 里的 `policy.allow_implicit_invocation: false` 不起作用。
4. **上游技能正文写 `Call the Skill tool with "X"`，本 harness 没有 `Skill` 工具。** 等价写法是
   `read skill://X`。两个纯别名技能正文只有这一行：`grill-me`（等价 `grilling`）、
   `grill-with-docs`（等价依次 `grilling` + `domain-modeling`）。读到它们时按别名展开即可。
5. **不带 `-a pi` 时 npx 会建 `~/.claude/skills/` 软链目录。** 只选中 claude-code 目标才会建，
   但 omp 优先解析 `~/.claude/skills/`（`~/.omp/agent/config.yml` 的 `skills.enableClaudeUser: true`），
   留着会让 `omp read skill://X` 指向那里。装完一律 `rm -rf ~/.claude/skills`（真身仍在
   `~/.agents/skills/`），删后 omp 回到 `~/.agents/skills/`。
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
11. **改了 `~/.agents/AGENTS.md` 要重开会话。** omp 在 session 启动时装载 context 文件，
    热会话里读到的还是旧版本。同理，技能列表变化（增删技能、装卸插件）也要重开会话才反映到
    system prompt。

## 6. 回滚 / 卸载

```bash
# 上游 mattpocock：按名字移除（同时清 lock 记录与目录）
npx skills@latest remove -g to-spec tdd research

# 自建技能：回退 dotfiles 即可
git -C ~/.dotfiles revert <commit> && da
```

整栈回滚（回到 2026-11-11 之前的技能栈）：`git -C ~/.dotfiles revert <commit> && da` 恢复
仓库侧（`~/.agents/AGENTS.md`、本文档、README），再按 §3.2 重跑一次 `npx skills add` 把
27 个上游技能装回来，最后 `rm -rf ~/.claude/skills`（如果被建出来）。

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
rg -n --no-heading '(skill://|xd://|agent://|\bomp\b|~/\.agents|/home/crochee|Claude Code|\bCodex\b|\bGemini\b|`grilling`|`prototype`|`research`|`ask-matt`|`code-review`|`codebase-design`|`diagnosing-bugs`|`domain-modeling`|`grill-me`|`grill-with-docs`|`handoff`|`improve-codebase-architecture`|`setup-matt-pocock-skills`|`tdd`|`to-spec`|`to-tickets`|`triage`|`wayfinder`|`writing-for-agents`)' \
  home/dot_agents/skills --glob 'SKILL.md' --glob 'references/**'
```

自建技能不引用第三方技能名：上游技能可能不在别的机器上装，`Not for` 段只点名**自建**的邻接技能。
黑名单只收上游技能名，且都用反引号包住，避免命中正文里的普通词；`implement`、`pr`、`retro`、
`teach`、`to-questionnaire`、`wait-what`、`wizard` 是常用词，不进黑名单。

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
| 2026-11-01 | 上游插件栈 | 6.4.1→**7.0.1** | 改为 omp 插件；移除 `~/.agents` 下 15 个旧副本 |
| 2026-11-01 | mattpocock | 5 个（pr/research/prototype/wizard/to-questionnaire） | 首次纳入台账 |
| 2026-11-01 | 清理 | 删 `~/.omp/plugins`、`~/.claude/skills`、`grill-me`、失效 lock、`~/.trae-cn/skills`、插件栈在 `~/` 与 `~/workspace/` 下的两处工作副本 | Trae 备份 `~/.local/share/skill-cleanup-backups/trae-skills-2026-11-01.tgz`；加载 34→33 |
| 2026-11-01 | 台账修正 | mattpocock 5→**6**（补 `grilling`）；加载 33→**39** | `grilling` 一直在 `~/.agents/skills/`（lock 源 mattpocock），安装/更新/卸载命令漏了它；桥接脚本生成的 6 个技能也漏记 |
| 2026-11-01 | mattpocock | 6→**9**（+`grill-me`、`grill-with-docs`、`teach`、`domain-modeling`；−`pr`） | 指定集合定为这 9 个；`domain-modeling` 是 `grill-with-docs` 的依赖（后者正文只有一行别名）；加载 39→42；删掉重建的 `~/.claude/skills` |
| 2026-11-01 | mattpocock | 9→**7**（−`grill-me`、`grill-with-docs`） | 这两个是上游一行别名（`Call the Skill tool with …`），omp 无 `Skill` 工具，别名不成立；真身 `grilling` + `domain-modeling` 已单独装。加载 42→40 |
| 2026-11-01 | mattpocock | 7→**8**（+`grill-with-docs`） | `grill-with-docs` 有独立价值：一键「拷问 + 出 ADR/glossary」，等价于 `grilling` + `domain-modeling` 连调；只删 `grill-me`。加载 40→41 |
| 2026-11-02 | 研究技能 | `research`→**`deep-research`**（`B143KC47/deep-research-skill` v1.0.3，MIT） | mattpocock 版只有 prompt（后台 agent + 一手源 + 一个 MD）；deep-research 有自适应 effort、证据台账、反证检索、结论打标签，纯标准库脚本本机实测可跑。`last30days` 评估后不装（缺 yt-dlp 与全部 key）。加载数不变（41），mattpocock 8→7，新增第三类 npx 来源（**同日又迁入自建，见下行**） |
| 2026-11-02 | deep-research | 第三方 npx→**自建（chezmoi）** | 源码迁入 `home/dot_agents/skills/deep-research/`，从 `B143KC47/deep-research-skill` v1.0.3（MIT，tree `a2f7003b71eb98177712ab13de9fbe3ee6acf2a9`）clean-room 重写：保留 CSV schema、effort 阶梯、lint 检查，修掉 22 处缺陷（`--name ../victim` 越界删除、lint/status 改写 CSV、截断 CSV 崩溃、source_family 回落 domain、effort 阶梯三处漂移、无 report renderer、secret 写盘后才扫描、引用正则 `E\d{4}` 漏检、反证两套定义、PRIMARY_TYPES 过宽等），并吸收 `mattpocock/skills` `engineering/research` 的 planner/retriever/verifier/synthesizer 分工（父 agent 是唯一写台账的人）与 hermes `arxiv` 的 arXiv/Semantic Scholar 配方。来源类别 4→3；自建 12→**13**；`~/.agents/skills/` 仍 26 个、加载总数仍 41（同名替换，不增不减）。新增 `agentskills validate` 规格闸门与 `tests/run.py`（37 项）、`tests/trigger_eval.py` |
| 2026-11-02 | deep-research | description 收紧 + 触发闸门改为双信号（实测） | 首轮触发实测：10 条正例全部 100% 命中，但 10 条反例里有 7 条也命中：上游那种「触发名词清单」式 description 会把「什么是文献综述」「列一下 RAG 论文标题」「随便聊聊研究为什么难」都吸进来。description 改了四版（以交付物为触发条件→去掉领域名词→去掉来源清单→加 "a single-source answer"），正例保持 67–100%。同时发现两个测量问题并修掉：（1）3 条反例引用了不存在的附件，agent 会去找文件、误读技能；已改成自包含；（2）3 次采样噪声大到一条查询 3 次测 100%、9 次测 33%；默认 run 数与告警写进 harness。闸门改为双信号：正例看 **consult**（skill 的 SKILL.md 被读），反例看 **workflow**（台账脚本真被调用）：录屏证明反例里模型是中途查一下技能、活照干、交付物不变，所以「被读」不等于「被用」。实测：26/26 通过（tuning 20/20、holdout 6/6），退出码 0；残余风险也照实报：13 条反例里 7 条仍会被 consult（名字带 research，查文献类问题就会被看一眼），其中 2 条各有 1/3 的 run 真把流程接了过去 |
| 2026-11-02 | 13 个自建技能 | 标准化：`license: MIT` + `metadata.version` bump、描述三段式、body ≤150 行、零 harness 依赖、单一 eval runner | 描述统一成「产出物 / Use when / Not for / 中文」，无中文触发行的 11 个补齐；5 个超长 body 下沉到 `references/`（`de-ai-tone` 213→142、`repo-wiki` 208→148、`frontend-design` 181→144、`technical-writing` 173→131、`agent-engineering` 159→142），`de-ai-tone` 的 44 模式表移到 `references/patterns-index.md` 并同步两个 drift 门禁；清掉 11 处宿主耦合（`subagent-driven-development`、`grilling`、`prototype`、`brainstorming`、`research`、`skill://`、`~/.agents/skills/…`、`omp`）；13 个 `evals/trigger_queries.json` 迁到 v2 形状（`skill` + `workflow_marker` + `queries`，每技能 24 条、正反各 12、各 3 条 holdout），触发实测统一走 `bin/skill-trigger-eval`（4 路并发、正例 consult ≥0.8、反例 workflow ≤0.2），删掉两份 omp 专用 runner；规格闸门 `uvx --from skills-ref agentskills validate` 13/13 通过，写作标准写进 §7 |
| 2026-11-04 | 13 个自建技能 | 触发实测全量通过（13/13 PASS，退出码 0）+ runner 两个 bug 修复 | 实测参数 `--runs 3 --jobs 8 --max-time 120 --session-timeout 150`，936 次真实会话，墙钟 2.9h；`deep-research` 改了 3 轮描述（把「核对结论/指标」写进 Use when，把「按来源核对的摘要」从 Not for 里放出去）才过，`python-dev` 改了 1 轮（Use when 重排成 4 组动宾结构）；runner 修了两个真 bug：超时只在读到输出时才检查（安静会话永远等不到超时）→ 改成后台线程读流 + 队列轮询 deadline；杀进程只杀直接子进程（孙进程留着 stdout 句柄把会话吊住）→ 改成杀整个进程组 |
| 2026-11-06 | golang-dev | 内容刷新 v1.1.0→**1.2.0** | 版本口径保持 1.24 底线、逐特性标注到 1.27；新增 `references/http-services.md`（Server 四个超时、优雅关闭、crypto/rand token）；补 `go fix` modernizers、`go vet` 的 waitgroup/hostport/stdversion、1.27 goroutine leak profile、容器 GOMAXPROCS/GOMEMLIMIT、命名与错误串契约；description 加 "modernizing" 并点名 k8s-operator；触发集换成 modernize 一对（仍 24/正 12/反 12/holdout 3+3）；触发实测 `--skills golang-dev` pos 12/12、neg 10/12、holdout ok、PASS（退出码 0；均值 neg rate 0.111 ≤ 0.2）。两条反例逐条越线：「Makefile 串联构建测试打包」workflow 1.00、「JSON 配置改端口」workflow 0.33——前者用 v1.1.0 旧 description 复测同样 1.00，是既有问题不是本次回归；后者在两个新 description 全量轮次间在 0.00 与 0.33 之间跳，属采样噪声 |
| 2026-11-11 | 技能栈替换 | mattpocock 7→**27**（新增 20 个：`ask-matt`、`code-review`、`codebase-design`、`diagnosing-bugs`、`implement`、`implement-spec`、`improve-codebase-architecture`、`pr`、`research`、`retro`、`setup-matt-pocock-skills`、`tdd`、`to-spec`、`to-tickets`、`triage`、`wayfinder`、`grill-me`、`handoff`、`wait-what`、`writing-for-agents`）；**上游 15 技能插件栈 + spec 驱动 CLI 栈全部移除**；加载 41→**40** | 上游 promoted 全装（engineering 20 + productivity 7），装法 `npx skills@latest add mattpocock/skills -g -y -a pi -s <27 个名字>`，落点仍是 `~/.agents/skills/`；`omp plugin uninstall <插件栈>` 卸掉 15 个插件技能与 session bootstrap，新增的 `~/.agents/AGENTS.md`（chezmoi 源 `home/dot_agents/AGENTS.md`）接替它写全局调用约定；CLI 栈（mise 纳管的 npm 包 `@fission-ai/*`、用户级 schema 桥接层 `~/.local/share/*/schemas/*`、桥接脚本 `~/.local/bin/*-bridge`、脚本生成的 6 个技能、仓库里的接入文档、`~/workspace/elysper/` 下的规格目录）全删；Trae CN 里同一插件栈的副本与两个登记文件里的条目一并清掉；上游 `research` 与自建 `deep-research` 并存，分工写进 `~/.agents/AGENTS.md`；加载数 41→40（`~/.agents/skills/` 26→40，插件 15→0）。实测进系统提示的是 24 个（自建 13 + 上游 AUTO 11）：上游 16 个 user-invoked 技能因 frontmatter 标了 `disable-model-invocation: true` 被 omp 排除在系统提示之外（仍可用 `skill://<name>` 调用，唯一发现路径是 `~/.agents/AGENTS.md` §2 的名字列表）。**触发闸门未在本次替换后重跑**：本机 WSL 频繁重启（一次全量 360 次会话跑不完），本次改动未碰任何自建技能的 description，旧的自建触发率仍作参考；上游新装带来的实际增量是 11 个 AUTO 技能进同一 system prompt |
