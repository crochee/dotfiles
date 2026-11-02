# 改写前后对照 — README.md 与 docs/*.md

来源：`README.md`、`docs/AGENT-SKILLS.md`、`docs/KEYMAP.md`、`docs/OPENSPEC-BRIDGE.md` ·
复核人：omp（de-ai-tone 改写模式） · 日期：2026-11-05 · 交付语言：zh

登记：体裁是仓库自述型技术文档（README、安装手册、键位说明、接入说明）；读者是仓库作者本人，
用来照着跑命令、照着查冲突。骨架句：README 交代仓库怎么装、三类技能分别去哪装；
AGENT-SKILLS 交代技能的安装、更新与回滚；KEYMAP 交代键位冲突与裁决顺序；
OPENSPEC-BRIDGE 交代 OpenSpec + superpowers-bridge 的项目接入步骤。
不动的段落：全部围栏代码块、命令、路径、标识符、行内代码、版本号与日期、表格里的键名与「裁定」列；
正文语言各自保持原样（README 的英文条目仍是英文）。

恢复原文：`git diff -- README.md docs/`，或 `git checkout -- README.md docs/`（改动未提交）。

## 改写明细

| 位置 | 改写前 | 改写后 | 类别 | 原因 | 精度是否保留 |
|---|---|---|---|---|---|
| `README.md:3` | chezmoi-managed dotfiles. Bootstrap: `bash install/install.sh`. | Managed by chezmoi. Bootstrap: `bash install/install.sh`. | `E3 heading-repeat` | 标题已写 dotfiles，首句又念一遍标题词；改成主谓句，只说谁在管 | 是——「chezmoi 管理」和 bootstrap 命令都在 |
| `README.md:11` | (源 `home/dot_local/bin/` → `~/.local/bin/`) | （源 `home/dot_local/bin/`，部署到 `~/.local/bin/`） | `D3 decorative-heading` | 箭头只是装饰性的路径映射，同句前半段已经用「源码…，部署到…」说同一件事，改用同一说法 | 是——两个路径都保留 |
| `README.md:11-13` | `superpowers-bridge`:源码 | `superpowers-bridge`：源码 | `D5 punctuation-spacing` | 中文正文里的半角 , ; : ( ) 换成全角（本文件共 29 处）；仓库另一篇 AGENT-SKILLS.md 本来就是这么写的 | 是——只换标点字符 |
| `README.md:18` | - **WSL ↔ Windows**: | - WSL ↔ Windows: | `D2 labelled-list` | 三条 Hosts 是逐项对照的清单，标签已经在一行开头，加粗只是喊话；同文件其余条目本来就不加粗 | 是——标签文字和条目顺序不变 |
| `README.md:19` | - **Native Linux**: | - Native Linux: | `D2 labelled-list` | 同上 | 是 |
| `README.md:20` | - **macOS**: | - macOS: | `D2 labelled-list` | 同上 | 是 |
| `docs/AGENT-SKILLS.md:69` | 只有“起后台 agent + 一手源 + 落一个 MD”， | 只有「起后台 agent + 一手源 + 落一个 MD」， | `D4 curly-quotes` | 弯引号换直角引号；本仓中文引号以「」为主，全文 12 处一起换 | 是——引号内文字未动 |
| `docs/AGENT-SKILLS.md:81` | ### 3.1 自建 skill | ### 3.1 自建技能 | `D2 labelled-list` + `E3 heading-repeat` | 章节标题里的 skill 与首句的 `SKILL.md` 只是撞词；标题改成本文通篇在用的「自建技能」后，撞词消失 | 是——章节内容未动 |
| `docs/AGENT-SKILLS.md:269` | 不是“装插件声明的 27 个”， | 不是「装插件声明的 27 个」， | `D4 curly-quotes` | 同上 | 是 |
| `docs/AGENT-SKILLS.md:272` | 上游有一批“空壳别名”技能 | 上游有一批「空壳别名」技能 | `D4 curly-quotes` | 同上 | 是 |
| `docs/AGENT-SKILLS.md:274` | 故意留着当“一键拷问 + 出文档”入口 | 故意留着当「一键拷问 + 出文档」入口 | `D4 curly-quotes` | 同上 | 是 |
| `docs/AGENT-SKILLS.md:287` | 10. **自建技能的 frontmatter 只有六个键**： | 10. **自建技能的 frontmatter 只有六个键。** | `D2 labelled-list` | 加粗小标题加冒号是提纲腔；改成加粗断句，和本文第 1、9 条（「**裸 `add` 在 agent 里会全装到当前项目。**」）同款 | 是——六个键名一个没少 |
| `docs/AGENT-SKILLS.md:305` | 若要改回“superpowers 用 `~/.agents` 副本” | 若要改回「superpowers 用 `~/.agents` 副本」 | `D4 curly-quotes` | 同上 | 是 |
| `docs/AGENT-SKILLS.md:414-422` | 6.4.1 → **7.0.1** | 6.4.1→**7.0.1** | `D3 decorative-heading` | 更新记录表里的 13 处带空格箭头收紧成紧排箭头，跟同表下一行的 `213→142` 同一写法（本文 18 处一起改） | 是——箭头两端的版本号、数量都没动 |
| `docs/AGENT-SKILLS.md:420` | 一键“拷问 + 出 ADR/glossary” | 一键「拷问 + 出 ADR/glossary」 | `D4 curly-quotes` | 同上 | 是 |
| `docs/AGENT-SKILLS.md:422` | 加载总数仍 **41**（同名替换，不增不减） | 加载总数仍 41（同名替换，不增不减） | `D1 over-bold` | 一行里三处加粗在喊话；这一处是「仍」和「不增不减」已经说过一遍的旧值，去掉加粗 | 是——数值 41 保留 |
| `docs/AGENT-SKILLS.md:423` | 也命中——上游那种 | 也命中：上游那种 | `B3 emdash-chain` | 一行四个「——」是破折号串；按行内关系拆成冒号或分号（另两处：误读技能；已改成自包含 / 9 次测 33%；默认 run 数与告警写进 harness / 真被调用）：录屏证明） | 是——四处「——」只是连接符，句子内容未变 |
| `docs/AGENT-SKILLS.md:423` | 并修掉：(1) 3 条反例 … ；(2) 3 次采样 | 并修掉：（1）3 条反例 … ；（2）3 次采样 | `D5 punctuation-spacing` | 中文句子里的半角括号换全角 | 是 |
| `docs/KEYMAP.md:1` | # KEYMAP.md — 统一键位方案 (wezterm + Wox + nvim + omp + shell) | # KEYMAP.md — 统一键位方案 | `E3 heading-repeat` | 标题后面紧跟的第一行就是这五件套的清单，标题等于把首行又说一遍；标题去掉重复枚举，五件套由紧随其后的导语给出 | 是——五个组件一个没少，导语仍在 |
| `docs/KEYMAP.md:3-5` | > 五方协同: **wezterm 终端** + **Wox 全局启动器** + **nvim 编辑器** + **omp AI TUI** + | > 五方协同：wezterm 终端、Wox 全局启动器、nvim 编辑器、omp AI TUI、shell (readline)。 | `D1 over-bold` + `D5 punctuation-spacing` | 一行四处加粗等于没有加粗；改成不带标记的顿号枚举，标点换成全角 | 是——五个组件、mod/re_mod 定义、优先级声明都在 |
| `docs/KEYMAP.md:14,16,37,39,42,44,48,50,56,60,78,106` | `ShowLauncher` (终端内命令面板) | `ShowLauncher`（终端内命令面板） | `D5 punctuation-spacing` | 中文正文里的半角标点换全角（本文件共 30 处，含表格单元格里中文说明的括号） | 是——只换标点字符 |
| `docs/KEYMAP.md:70` | 值定义在 `home/dot_wox/wox-user/settings/wox.json`; 本表是文档, 改值改 wox.json: | 值定义在 `home/dot_wox/wox-user/settings/wox.json`；本表是文档，改值改 wox.json： | `D5 punctuation-spacing` | 半角逗号、冒号换全角 | 是 |
| `docs/KEYMAP.md:84-95` | \| `mod+Space` \| ShowLauncher \| — \| `<leader>`=Space \| — \| — \| **wezterm** \| | \| `mod+Space` \| ShowLauncher \|  \| `<leader>`=Space \|  \|  \| **wezterm** \| | `B3 emdash-chain` | 矩阵每行用三到五个「—」当「该 app 不绑这个 chord」的记号，破折号串正是本模式要压的密度；改成空单元格，和仓库另一篇 api-design 的宽表一致。裁定列始终写明谁赢，语义不丢 | 是——44 个 N/A 记号全部改成空位，「裁定」列一字未改 |
| `docs/KEYMAP.md:97` | **Ctrl 单键与上下键**: | **Ctrl 单键与上下键**： | `D5 punctuation-spacing` | 半角冒号换全角 | 是 |
| `docs/KEYMAP.md:98` | 上一条历史), omp TUI 内 omp 赢（`C-p` = 模型选择） —— | 上一条历史），omp TUI 内 omp 赢（`C-p` = 模型选择）—— | `D5 punctuation-spacing` | 半角逗号、括号换全角，破折号前不留空格 | 是——单条破折号留着（本仓正文一贯用法） |
| `docs/KEYMAP.md:103` | 冲突时按使用频率让位 (高→低): | 冲突时按使用频率让位（高→低）： | `D5 punctuation-spacing` | 半角括号、冒号换全角 | 是 |
| `docs/KEYMAP.md:108-117` | 1. **shell prompt**: … 7. **不冲突验证**: | 1. shell prompt：… 7. 不冲突验证： | `D2 labelled-list` | 七条验证清单里六条是「加粗小标题加冒号」；标签已经在一行开头，加粗只是喊话，第六条同理一起去掉以免同节两种写法。清单形态保留（改键后要照着跑，列表最清楚） | 是——七条的内容、顺序、命令都在 |
| `docs/KEYMAP.md:121-128` | 1. **macOS Spotlight vs Wox**: … 4. **Wox 与 dotfiles**: | 1. macOS Spotlight vs Wox：… 4. Wox 与 dotfiles： | `D2 labelled-list` | 同上，四条 trade-off 标签去加粗，半角括号、逗号、句号换全角 | 是 |
| `docs/OPENSPEC-BRIDGE.md:3` | 每个项目只写**一个文件** `openspec/config.yaml`,三件事各一条命令: | 每个项目只写**一个文件** `openspec/config.yaml`，三件事各一条命令： | `D5 punctuation-spacing` | 半角逗号、冒号换全角 | 是 |
| `docs/OPENSPEC-BRIDGE.md:7,11-18,21,25,32,43-52,56,64,67-84,86,90,92,98,109-116,124-125,129-133` | 项目接入(写 `config.yaml` + 追加 `AGENTS.md`) | 项目接入（写 `config.yaml` + 追加 `AGENTS.md`） | `D5 punctuation-spacing` | 中文正文里的半角标点换全角（本文件共 55 处）；列表续行缩进按同文件其余条目统一成 2 空格 | 是——只换标点字符 |
| `docs/OPENSPEC-BRIDGE.md:46` | 但缺 `schema:` 行 → 脚本把 `schema: superpowers-bridge` 插到首行 | 但缺 `schema:` 行时，脚本把 `schema: superpowers-bridge` 插到首行 | `D3 decorative-heading` | 箭头在这里是装饰性的，改成「行时」把条件和动作连起来 | 是 |
| `docs/OPENSPEC-BRIDGE.md:47` | （如 `spec-driven`）→ 脚本报错退出 | （如 `spec-driven`）时，脚本报错退出 | `D3 decorative-heading` | 同上 | 是 |
| `docs/OPENSPEC-BRIDGE.md:129` | `superpowers-bridge/` → `chezmoi apply` → | `superpowers-bridge/`，然后 `chezmoi apply`、 | `D3 decorative-heading` | 两个箭头串起的是三步流程，改成「然后」加顿号，顺序不变 | 是——三个路径都在 |

## 扫描日志

改写前（原文取自 `HEAD`，命令可复现）：

```console
$ git show HEAD:README.md > /tmp/base/README.md && python3 ~/.agents/skills/de-ai-tone/scripts/scan.py /tmp/base/README.md; echo exit=$?
score: 8 distinct lines flagged; 35 occurrences; 511 units (308 words + 203 CJK characters); rate 68.5 per 1000 units
/tmp/base/README.md:3: E3 heading-repeat: chezmoi-managed dotfiles. Bootstrap: `bash install/install.sh`.
/tmp/base/README.md:11: D3 decorative-heading: →
/tmp/base/README.md:11: D5 punctuation-spacing: 源
/tmp/base/README.md:11: D5 punctuation-spacing: 部
/tmp/base/README.md:11: D5 punctuation-spacing: ,
/tmp/base/README.md:11: D5 punctuation-spacing: 所
/tmp/base/README.md:11: D5 punctuation-spacing: ;
/tmp/base/README.md:11: D5 punctuation-spacing: 引
/tmp/base/README.md:11: D5 punctuation-spacing: ,
/tmp/base/README.md:11: D5 punctuation-spacing: 缺
/tmp/base/README.md:11: D5 punctuation-spacing: 每
/tmp/base/README.md:11: D5 punctuation-spacing: 不
/tmp/base/README.md:11: D5 punctuation-spacing: :
/tmp/base/README.md:12: D5 punctuation-spacing: 部
/tmp/base/README.md:12: D5 punctuation-spacing: ;
/tmp/base/README.md:12: D5 punctuation-spacing: 故
/tmp/base/README.md:12: D5 punctuation-spacing: :
/tmp/base/README.md:12: D5 punctuation-spacing: ,
/tmp/base/README.md:12: D5 punctuation-spacing: 纯
/tmp/base/README.md:12: D5 punctuation-spacing: ,
/tmp/base/README.md:12: D5 punctuation-spacing: 正
/tmp/base/README.md:12: D5 punctuation-spacing: 各
/tmp/base/README.md:12: D5 punctuation-spacing: ,
/tmp/base/README.md:12: D5 punctuation-spacing: 用
/tmp/base/README.md:12: D5 punctuation-spacing: :
/tmp/base/README.md:12: D5 punctuation-spacing: 正
/tmp/base/README.md:12: D5 punctuation-spacing: 通
/tmp/base/README.md:12: D5 punctuation-spacing: 反
/tmp/base/README.md:12: D5 punctuation-spacing: ;
/tmp/base/README.md:12: D5 punctuation-spacing: 写
/tmp/base/README.md:13: D5 punctuation-spacing: :
/tmp/base/README.md:18: D2 labelled-list: - **WSL ↔ Windows**:
/tmp/base/README.md:19: D2 labelled-list: - **Native Linux**:
/tmp/base/README.md:20: D2 labelled-list: - **macOS**:
/tmp/base/README.md:24: E3 heading-repeat: User-facing 搜索 / 文件列举一律用 rg; 例外见 `note.txt`.
exit=1
```

```console
$ git show HEAD:docs/AGENT-SKILLS.md > /tmp/base/AGENT-SKILLS.md && python3 ~/.agents/skills/de-ai-tone/scripts/scan.py /tmp/base/AGENT-SKILLS.md; echo exit=$?
score: 19 distinct lines flagged; 37 occurrences; 3847 units (874 words + 2973 CJK characters); rate 9.6 per 1000 units
/tmp/base/AGENT-SKILLS.md:69: D4 curly-quotes: “
/tmp/base/AGENT-SKILLS.md:69: D4 curly-quotes: ”
/tmp/base/AGENT-SKILLS.md:90: E3 heading-repeat: `SKILL.md` 必须有一层目录：`~/.agents/skills/<name>/SKILL.md`，omp 不递归发现。
/tmp/base/AGENT-SKILLS.md:124: E3 heading-repeat: **自建**，不走 npx。源码在 `home/dot_agents/skills/deep-research/`，由 chezmoi 部署到
/tmp/base/AGENT-SKILLS.md:175: E3 heading-repeat: `github:obra/superpowers` 跟踪默认分支，每次 upgrade 取最新。要钉死版本用
/tmp/base/AGENT-SKILLS.md:269: D4 curly-quotes: “
/tmp/base/AGENT-SKILLS.md:269: D4 curly-quotes: ”
/tmp/base/AGENT-SKILLS.md:272: D4 curly-quotes: “
/tmp/base/AGENT-SKILLS.md:272: D4 curly-quotes: ”
/tmp/base/AGENT-SKILLS.md:274: D4 curly-quotes: “
/tmp/base/AGENT-SKILLS.md:274: D4 curly-quotes: ”
/tmp/base/AGENT-SKILLS.md:287: D2 labelled-list: 10. **自建技能的 frontmatter 只有六个键**：
/tmp/base/AGENT-SKILLS.md:305: D4 curly-quotes: “
/tmp/base/AGENT-SKILLS.md:305: D4 curly-quotes: ”
/tmp/base/AGENT-SKILLS.md:368: E3 heading-repeat: `references/` 一层深，正文用相对路径 `references/<file>.md`；每个 reference 开头一句
/tmp/base/AGENT-SKILLS.md:414: D3 decorative-heading: →
/tmp/base/AGENT-SKILLS.md:416: D3 decorative-heading: →
/tmp/base/AGENT-SKILLS.md:417: D3 decorative-heading: →
/tmp/base/AGENT-SKILLS.md:417: D3 decorative-heading: →
/tmp/base/AGENT-SKILLS.md:418: D3 decorative-heading: →
/tmp/base/AGENT-SKILLS.md:418: D3 decorative-heading: →
/tmp/base/AGENT-SKILLS.md:419: D3 decorative-heading: →
/tmp/base/AGENT-SKILLS.md:419: D3 decorative-heading: →
/tmp/base/AGENT-SKILLS.md:420: D3 decorative-heading: →
/tmp/base/AGENT-SKILLS.md:420: D3 decorative-heading: →
/tmp/base/AGENT-SKILLS.md:420: D4 curly-quotes: “
/tmp/base/AGENT-SKILLS.md:420: D4 curly-quotes: ”
/tmp/base/AGENT-SKILLS.md:421: D3 decorative-heading: →
/tmp/base/AGENT-SKILLS.md:421: D3 decorative-heading: →
/tmp/base/AGENT-SKILLS.md:422: D1 over-bold: **自建（chezmoi）** (x3)
/tmp/base/AGENT-SKILLS.md:422: D3 decorative-heading: →
/tmp/base/AGENT-SKILLS.md:422: D3 decorative-heading: →
/tmp/base/AGENT-SKILLS.md:422: D3 decorative-heading: →
/tmp/base/AGENT-SKILLS.md:423: B3 emdash-chain: —— (x4)
/tmp/base/AGENT-SKILLS.md:423: D3 decorative-heading: →
/tmp/base/AGENT-SKILLS.md:423: D3 decorative-heading: →
/tmp/base/AGENT-SKILLS.md:423: D3 decorative-heading: →
exit=1
```

```console
$ git show HEAD:docs/KEYMAP.md > /tmp/base/KEYMAP.md && python3 ~/.agents/skills/de-ai-tone/scripts/scan.py /tmp/base/KEYMAP.md; echo exit=$?
score: 34 distinct lines flagged; 57 occurrences; 1233 units (646 words + 587 CJK characters); rate 46.2 per 1000 units
/tmp/base/KEYMAP.md:3: D1 over-bold: **wezterm 终端** (x4)
/tmp/base/KEYMAP.md:3: D5 punctuation-spacing: :
/tmp/base/KEYMAP.md:3: E3 heading-repeat: > 五方协同: **wezterm 终端** + **Wox 全局启动器** + **nvim 编辑器** + **omp AI TUI** +
/tmp/base/KEYMAP.md:5: D5 punctuation-spacing: ,
/tmp/base/KEYMAP.md:5: D5 punctuation-spacing: .
/tmp/base/KEYMAP.md:39: D5 punctuation-spacing: ,
/tmp/base/KEYMAP.md:42: D5 punctuation-spacing: :
/tmp/base/KEYMAP.md:44: D5 punctuation-spacing: ,
/tmp/base/KEYMAP.md:44: D5 punctuation-spacing: ,
/tmp/base/KEYMAP.md:48: D5 punctuation-spacing: ,
/tmp/base/KEYMAP.md:48: D5 punctuation-spacing: ,
/tmp/base/KEYMAP.md:48: D5 punctuation-spacing: .
/tmp/base/KEYMAP.md:70: D5 punctuation-spacing: ,
/tmp/base/KEYMAP.md:70: E3 heading-repeat: 值定义在 `home/dot_wox/wox-user/settings/wox.json`; 本表是文档, 改值改 wox.json:
/tmp/base/KEYMAP.md:78: D5 punctuation-spacing: ;
/tmp/base/KEYMAP.md:78: D5 punctuation-spacing: .
/tmp/base/KEYMAP.md:84: B3 emdash-chain: — (x3)
/tmp/base/KEYMAP.md:86: B3 emdash-chain: — (x3)
/tmp/base/KEYMAP.md:87: B3 emdash-chain: — (x4)
/tmp/base/KEYMAP.md:87: D5 punctuation-spacing: ;
/tmp/base/KEYMAP.md:88: B3 emdash-chain: — (x3)
/tmp/base/KEYMAP.md:88: D5 punctuation-spacing: ,
/tmp/base/KEYMAP.md:89: B3 emdash-chain: — (x4)
/tmp/base/KEYMAP.md:90: B3 emdash-chain: — (x4)
/tmp/base/KEYMAP.md:91: B3 emdash-chain: — (x4)
/tmp/base/KEYMAP.md:92: B3 emdash-chain: — (x4)
/tmp/base/KEYMAP.md:93: B3 emdash-chain: — (x4)
/tmp/base/KEYMAP.md:94: B3 emdash-chain: — (x4)
/tmp/base/KEYMAP.md:94: D5 punctuation-spacing: ,
/tmp/base/KEYMAP.md:95: B3 emdash-chain: — (x3)
/tmp/base/KEYMAP.md:99: D5 punctuation-spacing: ,
/tmp/base/KEYMAP.md:99: D5 punctuation-spacing: .
/tmp/base/KEYMAP.md:108: D2 labelled-list: 1. **shell prompt**:
/tmp/base/KEYMAP.md:108: D5 punctuation-spacing: .
/tmp/base/KEYMAP.md:109: D2 labelled-list: 2. **omp TUI**:
/tmp/base/KEYMAP.md:109: D5 punctuation-spacing: ;
/tmp/base/KEYMAP.md:109: D5 punctuation-spacing: .
/tmp/base/KEYMAP.md:110: D2 labelled-list: 3. **wezterm**:
/tmp/base/KEYMAP.md:110: D5 punctuation-spacing: ;
/tmp/base/KEYMAP.md:110: D5 punctuation-spacing: .
/tmp/base/KEYMAP.md:111: D2 labelled-list: 4. **nvim**:
/tmp/base/KEYMAP.md:111: D5 punctuation-spacing: ;
/tmp/base/KEYMAP.md:112: D2 labelled-list: 5. **Wox**:
/tmp/base/KEYMAP.md:112: D5 punctuation-spacing: ;
/tmp/base/KEYMAP.md:116: D5 punctuation-spacing: .
/tmp/base/KEYMAP.md:117: D2 labelled-list: 7. **不冲突验证**:
/tmp/base/KEYMAP.md:121: D2 labelled-list: 1. **macOS Spotlight vs Wox**:
/tmp/base/KEYMAP.md:121: D5 punctuation-spacing: .
/tmp/base/KEYMAP.md:122: D3 decorative-heading: →
/tmp/base/KEYMAP.md:122: D3 decorative-heading: →
/tmp/base/KEYMAP.md:122: D3 decorative-heading: →
/tmp/base/KEYMAP.md:123: D2 labelled-list: 2. **omp followUp 的 Ctrl+Enter**:
/tmp/base/KEYMAP.md:124: D2 labelled-list: 3. **Alt+H/J/K/L**:
/tmp/base/KEYMAP.md:124: D5 punctuation-spacing: .
/tmp/base/KEYMAP.md:125: D2 labelled-list: 4. **Wox 与 dotfiles**:
/tmp/base/KEYMAP.md:126: D5 punctuation-spacing: ,
/tmp/base/KEYMAP.md:127: D5 punctuation-spacing: ,
exit=1
```

```console
$ git show HEAD:docs/OPENSPEC-BRIDGE.md > /tmp/base/OPENSPEC-BRIDGE.md && python3 ~/.agents/skills/de-ai-tone/scripts/scan.py /tmp/base/OPENSPEC-BRIDGE.md; echo exit=$?
score: 34 distinct lines flagged; 59 occurrences; 950 units (258 words + 692 CJK characters); rate 62.1 per 1000 units
/tmp/base/OPENSPEC-BRIDGE.md:3: D5 punctuation-spacing: 三
/tmp/base/OPENSPEC-BRIDGE.md:3: D5 punctuation-spacing: :
/tmp/base/OPENSPEC-BRIDGE.md:3: E3 heading-repeat: 每个项目只写**一个文件** `openspec/config.yaml`,三件事各一条命令:
/tmp/base/OPENSPEC-BRIDGE.md:12: D5 punctuation-spacing: ;
/tmp/base/OPENSPEC-BRIDGE.md:13: D5 punctuation-spacing: 项
/tmp/base/OPENSPEC-BRIDGE.md:16: D5 punctuation-spacing: :
/tmp/base/OPENSPEC-BRIDGE.md:17: D5 punctuation-spacing: ,
/tmp/base/OPENSPEC-BRIDGE.md:17: D5 punctuation-spacing: 所
/tmp/base/OPENSPEC-BRIDGE.md:18: D5 punctuation-spacing: 所
/tmp/base/OPENSPEC-BRIDGE.md:21: D5 punctuation-spacing: 所
/tmp/base/OPENSPEC-BRIDGE.md:25: D5 punctuation-spacing: :
/tmp/base/OPENSPEC-BRIDGE.md:32: D5 punctuation-spacing: :
/tmp/base/OPENSPEC-BRIDGE.md:43: D5 punctuation-spacing: ;
/tmp/base/OPENSPEC-BRIDGE.md:44: D5 punctuation-spacing: ,
/tmp/base/OPENSPEC-BRIDGE.md:44: D5 punctuation-spacing: 不
/tmp/base/OPENSPEC-BRIDGE.md:46: D3 decorative-heading: →
/tmp/base/OPENSPEC-BRIDGE.md:46: D5 punctuation-spacing: ,
/tmp/base/OPENSPEC-BRIDGE.md:46: D5 punctuation-spacing: 其
/tmp/base/OPENSPEC-BRIDGE.md:47: D5 punctuation-spacing: ,
/tmp/base/OPENSPEC-BRIDGE.md:47: D5 punctuation-spacing: 手
/tmp/base/OPENSPEC-BRIDGE.md:50: D5 punctuation-spacing: :
/tmp/base/OPENSPEC-BRIDGE.md:50: D5 punctuation-spacing: 既
/tmp/base/OPENSPEC-BRIDGE.md:51: D5 punctuation-spacing: 否
/tmp/base/OPENSPEC-BRIDGE.md:64: D5 punctuation-spacing: :
/tmp/base/OPENSPEC-BRIDGE.md:67: D5 punctuation-spacing: 再
/tmp/base/OPENSPEC-BRIDGE.md:68: D5 punctuation-spacing: ,
/tmp/base/OPENSPEC-BRIDGE.md:68: D5 punctuation-spacing: 重
/tmp/base/OPENSPEC-BRIDGE.md:68: D5 punctuation-spacing: 不
/tmp/base/OPENSPEC-BRIDGE.md:70: D5 punctuation-spacing: ,
/tmp/base/OPENSPEC-BRIDGE.md:70: D5 punctuation-spacing: 复
/tmp/base/OPENSPEC-BRIDGE.md:70: D5 punctuation-spacing: ,
/tmp/base/OPENSPEC-BRIDGE.md:73: D5 punctuation-spacing: :
/tmp/base/OPENSPEC-BRIDGE.md:74: D5 punctuation-spacing: 用
/tmp/base/OPENSPEC-BRIDGE.md:77: D5 punctuation-spacing: ,
/tmp/base/OPENSPEC-BRIDGE.md:77: D5 punctuation-spacing: 会
/tmp/base/OPENSPEC-BRIDGE.md:78: D5 punctuation-spacing: 复
/tmp/base/OPENSPEC-BRIDGE.md:80: D5 punctuation-spacing: ,
/tmp/base/OPENSPEC-BRIDGE.md:80: D5 punctuation-spacing: 不
/tmp/base/OPENSPEC-BRIDGE.md:84: D5 punctuation-spacing: 缺
/tmp/base/OPENSPEC-BRIDGE.md:98: D5 punctuation-spacing: ,
/tmp/base/OPENSPEC-BRIDGE.md:98: D5 punctuation-spacing: 重
/tmp/base/OPENSPEC-BRIDGE.md:98: D5 punctuation-spacing: :
/tmp/base/OPENSPEC-BRIDGE.md:109: D5 punctuation-spacing: ,
/tmp/base/OPENSPEC-BRIDGE.md:109: D5 punctuation-spacing: 端
/tmp/base/OPENSPEC-BRIDGE.md:109: D5 punctuation-spacing: ,
/tmp/base/OPENSPEC-BRIDGE.md:109: D5 punctuation-spacing: 不
/tmp/base/OPENSPEC-BRIDGE.md:110: D5 punctuation-spacing: ,
/tmp/base/OPENSPEC-BRIDGE.md:110: D5 punctuation-spacing: 例
/tmp/base/OPENSPEC-BRIDGE.md:110: D5 punctuation-spacing: :
/tmp/base/OPENSPEC-BRIDGE.md:116: D5 punctuation-spacing: :
/tmp/base/OPENSPEC-BRIDGE.md:124: D5 punctuation-spacing: 说
/tmp/base/OPENSPEC-BRIDGE.md:125: D5 punctuation-spacing: ,
/tmp/base/OPENSPEC-BRIDGE.md:125: D5 punctuation-spacing: 或
/tmp/base/OPENSPEC-BRIDGE.md:129: D3 decorative-heading: →
/tmp/base/OPENSPEC-BRIDGE.md:129: D3 decorative-heading: →
/tmp/base/OPENSPEC-BRIDGE.md:129: D5 punctuation-spacing: :
/tmp/base/OPENSPEC-BRIDGE.md:131: D5 punctuation-spacing: :
/tmp/base/OPENSPEC-BRIDGE.md:133: D5 punctuation-spacing: 改
exit=1
```

改写后：

```console
$ python3 ~/.agents/skills/de-ai-tone/scripts/scan.py README.md; echo exit=$?
score: 0 distinct lines flagged; 0 occurrences; 537 units (312 words + 225 CJK characters); rate 0.0 per 1000 units
exit=0

$ python3 ~/.agents/skills/de-ai-tone/scripts/scan.py docs/AGENT-SKILLS.md; echo exit=$?
score: 0 distinct lines flagged; 0 occurrences; 3917 units (883 words + 3034 CJK characters); rate 0.0 per 1000 units
exit=0

$ python3 ~/.agents/skills/de-ai-tone/scripts/scan.py docs/KEYMAP.md; echo exit=$?
score: 0 distinct lines flagged; 0 occurrences; 1264 units (648 words + 616 CJK characters); rate 0.0 per 1000 units
exit=0

$ python3 ~/.agents/skills/de-ai-tone/scripts/scan.py docs/OPENSPEC-BRIDGE.md; echo exit=$?
score: 0 distinct lines flagged; 0 occurrences; 981 units (261 words + 720 CJK characters); rate 0.0 per 1000 units
exit=0
```

单位数比改写前多，是因为 7 行 `scan: ignore` 标记里的中文与英文也计入扫描单位。

## 存活命中

以下 7 处按行豁免，标记里写明理由；删掉任何一处都会损失事实或破坏引用。

| 位置 | 类别 | 为什么保留 |
|---|---|---|
| `README.md:24` | `E3 heading-repeat` | 标题「rg 优先」被 note.txt 交叉引用，首行给的是适用范围和例外，不是重复标题 |
| `docs/AGENT-SKILLS.md:124` | `E3 heading-repeat` | 章节名 deep-research 与首行的源码路径是撞词，首行给的是安装方式和源码位置 |
| `docs/AGENT-SKILLS.md:175` | `E3 heading-repeat` | 章节名 superpowers 与首行的上游仓库 slug 是撞词，首行给的是升级策略 |
| `docs/AGENT-SKILLS.md:368` | `E3 heading-repeat` | 章节名里的 references 指章节主题，首行说的是 `references/` 的目录层级 |
| `docs/KEYMAP.md:70` | `E3 heading-repeat` | 章节名 Wox 与首行的 wox.json 路径是撞词，首行给的是取值文件位置 |
| `docs/KEYMAP.md:122` | `D3 decorative-heading` | 这是 macOS 菜单的逐级路径，箭头承担路径信息 |
| `docs/OPENSPEC-BRIDGE.md:3` | `E3 heading-repeat` | 标题给的是接入对象，首行给的是要写的文件和三条命令 |

本文件（对照表）自己跑扫描，会在「改写前」一列报出命中：那一列逐字引用改写前的原文，
里面本来就带着弯引号、半角标点、破折号串和加粗小标题，属于引用型误报；改掉就对不上原文了。
四篇交付文档的扫描结果是 0 命中（见上）。

## 声明核对

- 新增的数字 token：无。四个文件的数字集合与 `HEAD` 逐个相同（数字、日期、版本号、百分比）。
- 丢失的数字 token：无。
- 改动的限定词：无。`may/must/only/up to/at least/shall/should/could` 与
  `必须/只能/不得/至少/最多/一律/不超过` 的出现次数与 `HEAD` 相同。
- 行内代码（命令、路径、标识符）集合：四个文件与 `HEAD` 相同，一处未动。
- 围栏代码块：四个文件的代码块与 `HEAD` 逐字节相同。
- 英文专名：只少了两处重复——README 首行的 dotfiles（标题仍在）和 KEYMAP 标题里的
  wezterm/Wox/nvim/omp/shell（紧随其后的导语仍逐一列出）。
