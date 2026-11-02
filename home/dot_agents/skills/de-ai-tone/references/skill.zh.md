# De-AI Tone：英文版为准，本文件是对照翻译

> 英文版为准，本文件是对照翻译。规则、编号与阈值以 `SKILL.md` 为准；发现不一致时，改英文版并同步本文件。

改写读起来像机器生成的中英文文本，直到一次固定、可重跑的扫描结果干净，同时原文里的每一处论断、数字和限定词都留在。

## 何时使用

三种模式：

- **Rewrite（改写）** — 草稿已经存在，读着像生成物。交付一份干净的稿子加一张变更表。
- **Gate（把关）** — 只审不改：跑扫描，逐条判断命中，出报告。
- **Calibrate（校准）** — 某个模板或固定文风一直在产出 slop。改掉它招来的那些句式。

常见触发语："this reads like AI"、"humanise this"、"de-slop the README"、"去掉 AI 味"、
"润色得自然一点"，或者发布前检查一份没人校过的文档。

它改的是表层，不是实质——事实、论证顺序、篇幅和作者归属不在范围内，结构性编辑归
`technical-writing`：这是最后一遍。

## 工作流

1. **确定文类、读者和交付语言。** 整篇通读一遍。说出语域（发布说明、设计文档、README、
   事故报告、营销页面）、读者，以及承载论点的那三到五句话。标出不能动的片段：代码块、
   错误字符串、标识符、引文、法务文本，以及模板要求的标题和字段名——PR 或 issue 模板里的
   粗体标签属于结构，不属于强调。然后决定**交付语言**：跟随输入文档的语言；中英混排的草稿
   跟随本次对话的语言。中文交付改用 `references/skill.zh.md` 与
   `assets/before-after.zh.template.md`，不用英文版的 `SKILL.md` 与
   `assets/before-after.template.md`。
   *完成标准：* 你能用一句话说出语域、读者和交付语言，指出主干句，并列出排除的片段。
2. **扫描并存下基线。** 跑扫描器，把输出原样存下来。每条命中都带模式编号和类别名，例如
   `draft.md:12: A1 not-just-x: …`。分数行的第一个数字——被标记的不同行数——是头条指标；
   比率用来比较长度不同的文档。草稿还没存盘时，用 `-` 或不给参数扫标准输入。
   ```console
   python3 scripts/scan.py draft.md; echo exit=$?
   ```
   *完成标准：* 基线分数行、命中清单和退出码都记下来了，被标记的行号也写下来了。
3. **只加载需要的成因组。** 44 条模式按「读起来像机器写的」的原因分组。打开命中落在的那
   几组的 `references/patterns-<group>.md`（中文交付用 `.zh.md`）
   ——不要把六组全打开。每条给出要盯的措辞、问题所在、一组改写前后对照，以及对应的手册动作。
   *完成标准：* 每个被标记的模式编号都对应到你加载的组，且条目已经打开。
4. **按手册逐条改写命中。** 按收益顺序走 `references/rewrite-playbook.md` 里的八个动作
   ——先删，再砍限定词，再拆句，再换成具体名词。每条模式条目都会点名自己的动作。凡不是
   一眼该删的命中，都查下面的保留/删除表。
   *完成标准：* 每条被标记的行都有一个决定，每次改写都点名了具体的替换物——换个同义词
   不算改写，把 `delve into` 换成 `explore` 也不是改写。
5. **重扫，压到零或说明留下的理由，然后记录。** 用同一条命令再跑一遍。每条存活的命中配
   一句话：属于哪一类误报，或者删掉会丢掉哪个事实。必须留下的行内联写
   `scan: ignore <number or category> <reason>`——这个标记接受类别名（`not-just-x`）或
   模式编号（`A1`），v2 之前写的标记继续有效。用模板填变更表：每次改动一行，位置、
   改写前、改写后、类别（`A1 not-just-x`）、原因、精度是否保留。然后比对数字 token，
   并核对限定词——`may`、`must`、`only`、`up to`、`at least`、`不超过`——在原文和改写稿
   之间是否一致。
   *完成标准：* 最终扫描结果已记录，每条存活的命中都有一个审阅者能查的理由，论断核对显示
   没有新引入，也没有无解释地丢失。

## 44 条模式

分组：A 铺陈（§A1–§A9）· B 节奏（§B1–§B14）· C 膨胀（§C1–§C10）· D 格式（§D1–§D5）·
E 残留（§E1–§E5）· F 读者（§F1）。A 组与 E 组见到一处就可以动手，其余是 *weak alone*，
需要别的线索作伴。

| ID | 模式 | 检测方式 | 类别 token |
|---|---|---|---|
| A1 | Not X but Y / 否定式对比 | regex | `not-just-x` |
| A2 | One-line closers and dramatic fragments / 一句总结与碎片行 | regex | `one-line-closer, empty-summary` |
| A3 | Sayings that sound deep / 深刻金句 | regex | `deep-saying` |
| A4 | Staged run-up before the point / 报幕式开场 | regex | `meta-narration, empty-transition, zh-translated-connective, zh-empty-opening` |
| A5 | Arguing with no one / 与无人辩论 | regex | `arguing-with-nobody` |
| A6 | Rhetorical question theatre / 假问题自问自答 | regex | `rhetorical-question` |
| A7 | False candour, false neutrality / 假坦诚假中立 | regex | `false-candour` |
| A8 | Staged contrast and stage slogans / 模板转折与阶段口号 | regex | `staged-contrast` |
| A9 | Fixed attention formulas / 固定关注句式 | regex | `attention-formula` |
| B1 | Forced triads / 三件套与排比 | regex | `triadic-padding, zh-parallelism` |
| B2 | Repeated sentence openings / 重复句首 | metric | `repeated-openings` |
| B3 | Dashes as the universal connector / 破折号泛滥 | regex | `emdash-chain` |
| B4 | Stacked qualifiers / 叠词限定 | regex | `hedge-stacking, zh-hedge-stacking` |
| B5 | Hyphenated pairs everywhere / 连字符复合修饰 | regex | `hyphen-pairs` |
| B6 | Passive voice and missing subjects / 被动语态与无主句 | regex | `passive-voice` |
| B7 | Preposition-led sentence openings / 句首介词短语泛滥 | regex | `preposition-opening` |
| B8 | Chained 的 and over-long modifiers / 连环定语 | regex | `chained-de` |
| B9 | Over-nominalisation / 过度名词化与动词虚化 | regex | `nominalisation` |
| B10 | Rhythm-even sentences / 句长齐一 | manual | — |
| B11 | Stacked colloquial questions / 人工感叠词 | regex | `colloquial-stack` |
| B12 | Over-balanced pairs / 过度平衡 | regex | `over-balanced` |
| B13 | Dense feature triads / 密集排比 | regex | `feature-triad` |
| B14 | Fake spans / 虚假跨度 | regex | `fake-span` |
| C1 | Overused AI words / AI 高频词 | regex | `translated-diction` |
| C2 | Inflated significance / 空泛与句尾强行升华 | regex | `inflated-significance` |
| C3 | Vague connection or association / 模糊关联 | regex | `vague-connection` |
| C4 | Shallow -ing riders / -ing 挂件 | regex | `ing-rider` |
| C5 | Sales language / 宣传腔 | regex | `sales-language` |
| C6 | Borrowed authority / 模糊归因与虚假权威 | regex | `borrowed-authority` |
| C7 | Avoiding is, are, and has / 回避简单动词 | regex | `avoiding-copula` |
| C8 | Stock challenges-and-outlook / 套路化挑战与展望 | regex | `challenges-outlook` |
| C9 | Hype vocabulary / 职场黑话与空洞大词 | regex | `corporate-jargon` |
| C10 | Generic positive conclusion / 通用积极结论 | regex | `generic-positive` |
| D1 | Bold as decoration / 装饰性加粗 | regex | `over-bold` |
| D2 | Labelled-list template / 加粗小标题清单体 | regex | `labelled-list` |
| D3 | Decorative headings and emoji / 装饰性标题与 emoji | regex | `decorative-heading, emoji-bullet` |
| D4 | Curly quotation marks / 弯引号 | regex | `curly-quotes` |
| D5 | Mixed punctuation and CJK spacing / 标点与中英混排规范 | regex | `punctuation-spacing` |
| E1 | Chatbot residue / 聊天残留 | regex | `chatbot-residue` |
| E2 | Knowledge-limit disclaimers / 知识截止与免责套话 | regex | `knowledge-limit` |
| E3 | A heading repeated in the first sentence / 标题复读 | regex | `heading-repeat` |
| E4 | Writing about the document instead of its subject / 写作元叙述 | regex | `document-meta` |
| E5 | Staged persona voice / 刻意拟人口吻 | regex | `staged-persona` |
| F1 | Re-explaining what the reader knows / 重复读者已知 | manual | — |

`regex` 规则匹配字面短语，`metric` 规则衡量整段的形状，`manual` 模式（§B10、§F1）没有
探测器，靠阅读判断。

## 快速决策

命中落在哪个成因组、该怎么处理：

| 组 | 命中长什么样 | 先做什么 |
|---|---|---|
| A 组：铺陈代替陈述 | 句子在宣告重要，而不是给出一个事实：对比式、收尾句、报幕、自问自答 | 删掉（§A2、§A4、§A5、§A6、§A7、§A8）；把要点说出来（§A1、§A3、§A9） |
| B 组：按规则套节奏 | 形状按规则重复：三件套、破折号、限定词、叠加修饰、并列的句首 | 换形状：两项而不是三项（§B1）、一个限定词而不是四个（§B4）、拆句（§B2、§B7、§B8）、点名动作方（§B6） |
| C 组：膨胀与借来的权威 | 普通事实被说成关键转折、专家背书或普遍意义 | 留事实，去掉包装（§C1–§C5）；点名来源或删掉（§C6）；用「是」「有」（§C7）；收在最后一个具体事实上（§C8、§C10） |
| D 组：按规则套格式 | 每条都带装饰：粗体标签、emoji、标题式大写、弯引号、中文里的半角标点 | 去掉装饰；每节最多一处粗体（§D1–§D5） |
| E 组：聊天与草稿残留 | 聊天外壳、知识截止声明、标题复述、关于文档本身的旁白 | 删掉外壳，留内容（§E1–§E5） |
| F 组：写错了读者 | 回复把读者已经掌握的背景又讲一遍 | 直接给结论（§F1） |

一条命中留还是删：

| 命中 | 什么时候留 | 什么时候删 |
|---|---|---|
| 任何限定词 | 它标出一个没测过的范围或一个未知条件 | 它只是给一个本可以直接说出的事实加装饰 |
| `not just X but Y` | X 是被否掉的备选，Y 是决定 | Y 只是把 X 说得更响 |
| `维度` / "dimension" | 它是带刻度的可测量轴 | 它只是「方面」的同义词 |
| `leverage` | 金融名词 | 当动词用时，use、call、run 才是准确说法 |
| 三项清单 | 三项的后果不同 | 三个同族形容词 |
| 连接词 | 后面跟着真实的关系 | 它只标出一段的开头 |
| 粗体 | 术语在这里被定义、后面还会再出现 | 这个词只是作者觉得重要 |
| 引文或领域说法 | 它是引文、标识符或行话 | 它是作者自己的恭维 |

按文类放行到哪一档：

| 文类 | 放行标准 |
|---|---|
| README、发布说明、运维手册 | 零命中；平实的行文；每个数字都挨着它支撑的那句结论 |
| 设计文档、RFC、事故报告 | 零命中；限定词只能以写明的缺口形式留下（"未在 5,000 rps 以上测过"） |
| 营销文案或品牌文案 | 只改不带品牌含义的 tell；文风由所有者定 |
| 中文自媒体/公众号 | 零命中；保留作者的观点和题外话；不要口号式收尾 |
| 职场公文/汇报/PRD | 零命中；结论先行；不要黑话；不要口号式收尾 |
| 技术博客/开发文档 | 零命中；准确、简短；代码块、YAML 和链接不动 |
| 日常沟通/邮件 | 结论写在第一句；不要客服腔 |
| 法务、引文或第三方文本 | 一律不改；报出分数就停 |

## 输出

**改写模式**交付：

- 改写后的文档——写清路径，以及原文怎么还原（`git diff`，或动手前留的 `.orig` 副本）。
- `before-after.md`，按 `assets/before-after.zh.template.md` 填：每次改动一行、基线与最终
  扫描块、存活命中表、论断核对。
- 最终扫描输出原样贴出，带退出码。

**把关模式**交付一个结论——对照 `references/measurement.zh.md` 里的阈值给通过或不通过
——外加扫描输出，以及一张逐条判定命中的表，附保留/删除的理由。不产出改写稿。

**校准模式**交付打过补丁的模板，外加两份清单：删掉的措辞，以及后来的作者该照着写的替换指引。

每种模式都要写明产出分数所用的命令、输入路径和日期。

## 出处与许可

模式表吸收了两个 MIT 许可的项目：[`blader/humanizer`](https://github.com/blader/humanizer)
（MIT，© 2025 Siqi Chen）与
[`nothing0here/humanizer-zh`](https://github.com/nothing0here/humanizer-zh)（MIT，© 2026
nothing0here）。上游来源是 Wikipedia 的
["Signs of AI writing"](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing)（CC
BY-SA 4.0），这里只做链接，不复制正文。扫描器与这些文档采用 MIT 许可。

## 参考文件

| 文件 | 什么时候加载 |
|---|---|
| [SKILL.md](../SKILL.md) | 英文真源：规则、编号与阈值以它为准；本文件是对照翻译。 |
| [references/patterns-a.zh.md](patterns-a.zh.md)（英文版 [references/patterns-a.md](patterns-a.md)） | A 组命中：铺陈代替陈述（§A1–§A9）。 |
| [references/patterns-b.zh.md](patterns-b.zh.md)（英文版 [references/patterns-b.md](patterns-b.md)） | B 组命中：按规则套节奏（§B1–§B14）。 |
| [references/patterns-c.zh.md](patterns-c.zh.md)（英文版 [references/patterns-c.md](patterns-c.md)） | C 组命中：膨胀与借来的权威（§C1–§C10）。 |
| [references/patterns-d.zh.md](patterns-d.zh.md)（英文版 [references/patterns-d.md](patterns-d.md)） | D 组命中：按规则套格式（§D1–§D5）。 |
| [references/patterns-e.zh.md](patterns-e.zh.md)（英文版 [references/patterns-e.md](patterns-e.md)） | E 组命中：聊天与草稿残留（§E1–§E5）。 |
| [references/patterns-f.zh.md](patterns-f.zh.md)（英文版 [references/patterns-f.md](patterns-f.md)） | F 组命中：写错了读者（§F1）。 |
| [references/rewrite-playbook.zh.md](rewrite-playbook.zh.md)（英文版 [references/rewrite-playbook.md](rewrite-playbook.md)） | 把命中变成改写：按收益排序的八个动作，以及技术精度优先的规则。 |
| [references/measurement.zh.md](measurement.zh.md)（英文版 [references/measurement.md](measurement.md)） | 报分数、定阈值，或判断某条命中是不是误报。 |
| [assets/before-after.zh.template.md](../assets/before-after.zh.template.md)（英文版 [assets/before-after.template.md](../assets/before-after.template.md)） | 填改写或把关报告用的变更表。 |
| [README.md](../README.md) | 安装方法，以及带中文名的 44 条模式总表。 |
| [AGENTS.md](../AGENTS.md) | 修改这个技能本身而不弄坏整包。 |

## 核对清单

- [ ] 扫描器在最终文本上跑过，输出连退出码一起贴出，而不是概括。
- [ ] 交付语言与第 1 步一致，中文交付加载了 `references/skill.zh.md`。
- [ ] 被标记的不同行数比基线少，结果达到 `references/measurement.zh.md` 里该文类的阈值。
- [ ] 每条存活的命中在 *存活命中* 下都有一行，写明它属于哪类误报，或它护住了哪个事实。
- [ ] 每行改写前后都点名模式编号和类别名（例如 `A1 not-just-x`）或写 `judgement`，并写明
      原因；没有哪一行只写"改写了"。
- [ ] 数字 token 的差集在两个方向上都为空：没有引入或悄悄丢掉任何数字、日期、标识符或
      专有名词。
- [ ] 原文里的每个情态词（`may`、`must`、`only`、`up to`、`at least`、`不超过`）要么还在，
      要么删掉的理由写进了日志。
- [ ] 没有改过代码块、错误字符串、API 名称或引文。
- [ ] 每条 `scan: ignore` 标记都点了模式编号或类别名，且所在行写明了保留理由。
- [ ] 改写稿的每一句都对应到原文的一句，或是某句拆开来的；没有出现新的论断。
- [ ] 最后一次改动之后重跑过扫描；分数描述的是最终交付的那份文本。
