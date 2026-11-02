# D 组模式：按规则套格式

D1 装饰性加粗 · D2 加粗小标题清单体 · D3 装饰性标题与 emoji · D4 弯引号 · D5 标点与中英混排规范

**何时加载本文件：** 扫描报告出现 `over-bold`、`labelled-list`、`decorative-heading`、`emoji-bullet`、`curly-quotes` 或 `punctuation-spacing`，需要判断这些标记是结构还是装饰。

D 组处理的是模板和可视化编辑器留下的痕迹，不是写作者主动选择的写法。这一组的每一条单独出现都不算证据，因为多数编辑器默认就会产出干净的排版。要把它们和其他各组的行文模式放在一起判断：装饰出现在本来就空洞的句子上，是同一个问题的一部分；装饰出现在有实据的文档上，可能是读者需要的结构。

### D1. Bold as decoration / 装饰性加粗

**强度：** 单独出现不算数——需要同段其他信号配合。

**观察：** 同一行里出现三处以上加粗；`**OKRs (Objectives and Key Results)**`；`**KPIs (Key Performance Indicators)**`；`**Business Model Canvas (BMC)**`；`**Balanced Scorecard (BSC)**`；一句话里连着加粗 3–4 个专有名词或黑话

**问题：** 加粗被当成喊话，而不是给读者后面还会遇到的术语做标记，于是强调没有带来句子里没有的信息。扫描器在一行出现三处以上加粗时命中，这正是模型把每个词都强调一遍时的句形。

**改写前：**
> It blends **OKRs (Objectives and Key Results)**, **KPIs (Key Performance Indicators)**, and visual strategy tools such as the **Business Model Canvas (BMC)** and **Balanced Scorecard (BSC)**.

**改写后：**
> It blends OKRs, KPIs, and visual strategy tools like the Business Model Canvas and Balanced Scorecard.

**动作：** 改写手册动作 1 — 删掉整句

**探测器：** `over-bold` (regex)

只有这三种情况值得保留加粗：这里定义、后面还要再用的术语；读者绝不能错过的警告；读者需要记住的数字。其余的加粗去掉标记也不丢信息，因为意思在词里，星号只贡献音量。每行最多一处加粗是可行的判断线。

### D2. Labelled-list template / 加粗小标题清单体

**强度：** 单独出现不算数——需要同段其他信号配合。

**观察：** `- **Label:** text`；`- **Label：** text`；`- **User Experience:**`；`- **Performance:**`；`- **Security:**`；`- **技术优势：**`；`- **成本考量：**`；`- **用户体验：**`

**问题：** 每一项都以加粗小标题加冒号开头，把一段叙述压成提纲，而且小标题往往只是把这一项的第一个词重复一遍。扫描器匹配的是以加粗小标题开头、紧跟冒号的列表项，冒号可以落在加粗里面，也可以紧跟在加粗后面。

**改写前：**
> - **技术优势：** 采用了先进的架构设计。
> - **成本考量：** 大幅降低了部署门槛。
> - **用户体验：** 提供了丝滑的操作流程。

**改写后：**
> 架构设计更先进，部署门槛大幅降低，操作流程也更顺畅。

**动作：** 改写手册动作 3 — 拆开长句

**探测器：** `labelled-list` (regex)

当小标题本身不携带信息、每一项又短到可以读成一句话时，把清单还原成叙述。同一个模板的英文形态是 `- **User Experience:** The user experience has been significantly improved with a new interface.`，改写后是一个从句。清单本身就是最清晰形态的内容要保留：API 参数、Action Items、待办清单、各列确有差异的对照表。PR 与 issue 模板里的加粗小标题是结构，不是强调，不能改写。

### D3. Decorative headings and emoji / 装饰性标题与 emoji

**强度：** 单独出现不算数——需要同段其他信号配合。

**观察：** `## Strategic Negotiations And Global Partnerships`；`→`；`🚀`；`💡`；`🔥`；`📌`；`✨`；`🎯`；`👉`；`- 🚀 **Launch Phase:**`；标题里每个实词都大写；列表项以 emoji 开头

**问题：** 标题式大写和 emoji 列表项是在装饰页面，而不是在说明里面装了什么，而且每一项的装饰完全一样，这正是模板的产物。扫描器在这里有两条规则：`decorative-heading` 命中实词全部大写的标题，以及被当作装饰的箭头；`emoji-bullet` 命中首字符是 emoji 的列表项。

**改写前：**
> ## Strategic Negotiations And Global Partnerships
>
> 🚀 **Launch Phase:** The product launches in Q3
> 💡 **Key Insight:** Users prefer simplicity

**改写后：**
> ## Strategic negotiations and global partnerships
>
> The product launches in Q3. User research showed a preference for simplicity.

**动作：** 改写手册动作 1 — 删掉整句

**探测器：** `decorative-heading` (regex), `emoji-bullet` (regex)

标题改用句首大写，标题只出现一次。除非作者明确要求，或者这是一篇本来就以 emoji 为风格的小红书体文章，否则删掉 emoji。为效果写的标题（"The decision, on one screen"）应该写清楚这一节装了什么（"How the six options compare"）；每节之间都插一条分隔线同样是装饰。

### D4. Curly quotation marks / 弯引号

**强度：** 单独出现不算数——需要同段其他信号配合。

**观察：** `“`；`”`；`‘`；`’`；`“the project is on track”`；`“设计”`；`‘quote’`

**问题：** 弯引号出现在写作者或目标格式本该用直引号的地方，于是文本和它要粘贴进去的文件、模板对不上。扫描器会命中这四个弯引号字符出现在任何位置，这也是这条模式单独出现时不成立的原因：多数编辑器会自动把引号变弯，人写的文件里同样满是弯引号。

**改写前：**
> He said “the project is on track” but others disagreed.

**改写后：**
> He said "the project is on track" but others disagreed.

**动作：** 改写手册动作 3 — 拆开长句

**探测器：** `curly-quotes` (regex)

动手之前先确认目标格式：Markdown 源码、JSON 字段、纯文本日志、代码注释各有各的约定，粘进 issue 的正文可能需要直引号。引用内部、标题内部、专有名词内部的引号不要动。中文用自己的全角引号 `“”` 和 `‘’`。

### D5. Mixed punctuation and CJK spacing / 标点与中英混排规范

**强度：** 单独出现不算数——需要同段其他信号配合。

**观察：** `你好 , 我是 .`；`优化了3个SQL查询`；中文旁边的半角 `,`；中文旁边的半角 `.`；`，`；`。`；`！`；`？`；`；`；`：`；`「」`；`《》`；`优化了 3 个 SQL 查询`

**问题：** 中文旁边的半角标点，以及和汉字贴在一起的英文词，是先按英文模板打完再把词换进去留下的接缝。扫描器会标记与汉字相邻的半角标点，以及汉字与拉丁字母或数字之间缺少的空格。

**改写前：**
> 你好 , 我是 . 这个工具优化了3个SQL查询。

**改写后：**
> 你好，我是。这个工具优化了 3 个 SQL 查询。

**动作：** 改写手册动作 3 — 拆开长句

**探测器：** `punctuation-spacing` (regex)

中文正文用全角标点——`，。！？；：「」《》`——中文与英文单词或数字之间留一个空格。代码、URL、标识符和引用文本保留原样，这条规则管的是它们周围的正文，不是字符串内部。

## 什么时候不要动

- PR 与 issue 模板里的加粗小标题是结构，不是强调，不要动。
- 弯引号是多数编辑器的默认产物，整篇都是弯引号完全可能出自人手。先看目标格式。
- API 参数、Action Items、待办清单这类清单本身就是最清晰的形态，改成散文会牺牲读者的扫读效率。
- 代码、URL、标识符和引用文本保留自己的标点与空格。
- 只有作者没有要求时，emoji 和标题大写才算装饰。社交媒体文案或自带规范的文档集保留原样。
- 2022 年 11 月 30 日之前写的文档不是 AI 写的。单凭装饰不构成证据。
