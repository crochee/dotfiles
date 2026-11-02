# E 组模式：聊天与草稿残留

E1 聊天残留 · E2 知识截止与免责套话 · E3 标题复读 · E4 写作元叙述 · E5 刻意拟人口吻

**何时加载本文件：** 扫描报告出现 `chatbot-residue`、`knowledge-limit`、`heading-repeat`、`document-meta` 或 `staged-persona`，需要判断被标记的文字是该删掉的残留，还是读者仍然需要的正文。

这五条是聊天和草稿阶段留下来的东西：包着真实答案的客套、标注模型自己知识边界的免责、重复上面标题的那一句、
描述文档而不是描述对象的说明，以及被表演出来而不是被说出来的口吻。这一组没有需要重写的，修法就是删除，
所以出现一次即可动手；删完再确认留下的句子还带着事实。

### E1. Chatbot residue / 聊天残留

**强度：** 出现一次即可动手——直接删掉，不要改写。
**观察：** I hope this helps; Of course!; Certainly!; Great question!; You're absolutely right; Would you like...; Want me to...?; Should I continue?; let me know; here is a...; 好的，没问题！; 这是一个非常深刻且具有前瞻性的问题……; 希望以上内容对您有所帮助！如果您有任何其他疑问，欢迎随时提问。; 接下来我将从以下几个维度为您深度剖析：
**问题：** 聊天机器人的问候、奉承、邀约和收尾还留在文里；这是清单里最确定的一个特征，因为那层包装读起来像是服务，
而不像噪音。它也是最容易漏掉的一个：包装里面往往裹着真正有价值的内容，值得留的是里面那层，不是外面那层。删掉包装，
留下内容。
**改写前：**
> Great question! Here is an overview of the French Revolution. It began in 1789 when a financial crisis and food shortages led to widespread unrest. I hope this helps! Let me know if you'd like me to expand on any section.
**改写后：**
> The French Revolution began in 1789 when a financial crisis and food shortages led to widespread unrest.
**改写前（一段中文回复）：**
> 好的，没问题！接下来我将从以下几个维度为您深度剖析：背景是请求量在半年内从 300 万涨到 1200 万；当前做法是每次查询都全表扫描；可以改成按天预聚合，代价是数据延迟一天。希望以上内容对您有所帮助！如果您有任何其他疑问，欢迎随时提问。
**改写后：**
> 请求量在半年内从 300 万涨到 1200 万。现在每次查询都全表扫描，可以改成按天预聚合，代价是数据延迟一天。
**改写前（一条聊天答复）：**
> Of course! Here is a summary of the incident. The 14:02 deploy pushed a build with a stale migration, the schema check failed, and the queue backed up until the rollback finished at 14:19. Would you like me to break down the timeline in more detail?
**改写后：**
> The 14:02 deploy pushed a build with a stale migration. The schema check failed, and the queue backed up until the rollback finished at 14:19.
**动作：** playbook 动作 1 — 删掉整句
**探测器：** `chatbot-residue` (regex)

删掉问候、奉承、邀约和收尾，留下中间那段：答案、数字、例子。「下面是大革命的一个概述」不等于概述本身，
「如果需要我再多展开某一部分，随时告诉我」也不是关于主题的事实。当整段里只有包装没有内容时，整段一起删。

### E2. Knowledge-limit disclaimers / 知识截止与免责套话

**强度：** 出现一次即可动手——直接删掉，不要改写。
**观察：** as of [date]; up to my last training update; while specific details are limited; based on available information; not publicly available; not widely documented or disclosed; in the provided or available sources; maintains a low profile; keeps personal details private; likely [grew up, studied, began]; it is believed that; 截至我的知识库更新时间; 由于公开信息有限，推测可能……
**问题：** 文本要么标出模型自己知识到哪儿为止，要么承认没找到出处，然后用一句听起来合理的猜测把窟窿填上。两者里
猜测更糟：它把「没有证据」变成读者会当成事实的断言。要么写明来源没有覆盖什么，要么把这句话删掉。扫描器匹配的是
字面短语；「as of [date]」「keeps personal details private」这类更宽的说法要靠阅读判断。
**改写前（截止声明）：**
> While specific details about the company's founding are not extensively documented in readily available sources, it appears to have been established sometime in the 1990s.
**改写后：**
> The company's founding date is not documented in the available sources.
**改写前（听起来合理的猜测）：**
> Information about her early life is not publicly available, suggesting she maintains a low profile. She likely grew up in a middle-class household, which shaped her later interest in education reform.
**改写后：**
> Her early life is not documented in the available sources.
**改写前（一段中文免责）：**
> 截至我的知识库更新时间，该产品的定价策略没有公开说明。由于公开信息有限，推测可能是在 2023 年第二季度改成了按席位计费。
**改写后：**
> 公开资料未说明该产品何时改为按席位计费。
**动作：** playbook 动作 1 — 删掉整句
**探测器：** `knowledge-limit` (regex)

关于模型自身局限的免责对读者不是信息，删掉即可；披着发现外衣的猜测也跟着删，「it is believed that」本身就是特征，
它没有指名任何来源。如果这个缺口对读者重要，就用一个分句写明——「创立时间在现有资料中没有记载」——把判断留给读者；
如果缺口不重要，删掉整句，并检查后文有没有依赖它。

### E3. A heading repeated in the first sentence / 标题复读

**强度：** 出现一次即可动手——直接删掉，不要改写。
**观察：** 标题下面跟着一段只复述标题的单行段落; `Speed matters.`; `Performance matters.`; `Reliability is key.`; `速度很重要。`; `质量是关键。`; 标题后的第一个非空行，如果它重复的是标题里的词
**问题：** 标题后面跟一句把标题又说一遍的话，读者在读到新东西之前先遇到同一个说法两次。扫描器读标题和它下面的第一个
非空行，当这一行只是复述标题时标记该行——要么重复了标题里的实词，要么是一句光秃秃的复述，比如「Speed matters.」。
修法是删掉复述的那一句，不是改写标题。
**改写前：**
> ## Performance
>
> Speed matters.
>
> When users hit a slow page, they leave.
**改写后：**
> ## Performance
>
> When users hit a slow page, they leave.
**改写前（用词复述标题）：**
> ## Reliability
>
> Reliability is key for this service.
>
> The queue retries failed jobs three times before parking them.
**改写后：**
> ## Reliability
>
> The queue retries failed jobs three times before parking them.
**改写前（一个中文标题）：**
> ## 性能
>
> 性能很重要。
>
> 页面超过 2 秒时，用户就会离开。
**改写后：**
> ## 性能
>
> 页面超过 2 秒时，用户就会离开。
**动作：** playbook 动作 1 — 删掉整句
**探测器：** `heading-repeat` (regex)

删的是标题下面那一句，不是标题。标题写「Reliability」是这一节对读者的承诺，复述它的那一句既没有给出证据，
也没有给出数字和条件。如果标题下的第一行带着标题里没有的事实——一个测量值、一个条件、一个名字——那就是内容，要留。

### E4. Writing about the document instead of its subject / 写作元叙述

**强度：** 出现一次即可动手——直接删掉，不要改写。
**观察：** 文本替换掉了什么（`was added to replace`）; 文本是怎么组装或取材的（`generated from`, `compiled from`, `anything unconfirmed is flagged rather than guessed`）; 读者自己已经看得见的图例、布局或顺序（`the table below compares`, `this section is organized by owner`）; 本文将介绍; 这篇文章想回答; 本节将讨论; 如下所示; 详见下表
**问题：** 文本在描述自己而不是在描述对象：它替换了什么、怎么组装的、怎么排布的，读者都没有问过。上一版本只在变更日志、
发布说明和迁移指南里提；读者能顺着查到的来源署名要留；你自己怎么干活的交代要删；会改变读者行动的提醒要留。扫描器
匹配的是字面短语；交代文档是怎么编出来的这类说法要靠阅读判断。
**改写前：**
> This function was added to replace the previous approach of iterating through all items, which caused O(n²) performance.
**改写后：**
> This function uses a hash map for O(1) lookups, avoiding the O(n²) cost of naive iteration.
**改写前（一句交代方法）：**
> The figures below are drawn from each vendor's published pricing; anything we could not confirm is flagged rather than guessed.
**改写后：**
> Prices are each vendor's published rate. Two vendors publish nothing; call them.
**改写前（一处中文布局说明）：**
> 本节将讨论令牌类型，详见下表。下表列出了三种令牌类型及其有效期。
**改写后：**
> 令牌分三种类型，有效期各不相同。
**动作：** playbook 动作 1 — 删掉整句
**探测器：** `document-meta` (regex)

读者看得见表，所以那句宣布表格存在的句子是给不需要说明的东西加的说明。「this section is organized by owner」
和交代文档怎么编制的话同理。有两处例外是有分量的：读者能顺着查到的来源署名，以及会改变读者行动的提醒。
变更日志是唯一一篇主题真的是「上一个版本」的文档。

### E5. Staged persona voice / 刻意拟人口吻

**强度：** 出现一次即可动手——直接删掉，不要改写。
**观察：** my honest take; my real answer; my real opinion; here's the honest truth; here's the truth; without the sugar coating; without bullshit; 我的判断很直接; 说点扎心的; 说点实在的; 不吐不快; 扎心的真相; 扎心的一句话
**问题：** 人格包装顶替了一个真正的判断。文本不直接说出结论，而是先宣布自己接下来会有多直白，于是这声宣告干掉了
本该由结论干的活，读者拿到的是一场表演，不是一个发现。要说出判断，而不是表演判断；直白留着，表演的痕迹不留。
**改写前：**
> My honest take? Most "AI detection" tools are measuring token distribution, not authorship. Here's the honest truth: without the sugar coating, a good editor still catches a padded paragraph faster than any classifier.
**改写后：**
> Most AI-detection tools measure token distribution, not authorship. A good editor still catches a padded paragraph faster than any classifier.
**改写前（一段中文人格）：**
> 我的判断很直接：多数「AI 检测」工具测的是词元分布，不是作者身份。说点扎心的，一个好编辑判断一段话是不是注水，比任何分类器都快。
**改写后：**
> 多数「AI 检测」工具测的是词元分布，不是作者身份。一个好编辑判断一段话是不是注水，比任何分类器都快。
**动作：** playbook 动作 1 — 删掉整句
**探测器：** `staged-persona` (regex)

删掉那句定调，保留它引出的句子。「我的判断很直接」不是谦虚，「without the sugar coating」也不是坦率：两者都是先
承诺一个品质，再让读者自己去检验。如果作者本人的口吻本来就直，删掉宣告之后，结论照样是直的。

## 什么时候不要动

- 被观察到的短语出现在引文、标题、专有名词里，或者出现在讨论这个说法本身的段落里，不要动。
- 信件和评论里的称呼与落款早于聊天机器人。邮件里的「Hi Anna」和「Thanks」不是残留。
- 上一版本只在变更日志、发布说明和迁移指南里提。在这些文档里，「was added to replace」正是主题。
- 读者能顺着查到的来源署名要留，会改变读者行动的提醒也要留。两者都是内容；读者需要的清单也是内容，要删的只是介绍清单的那句话。
- 个人随笔里刻意经营的人格是作者的选择。这一条针对的是那句定调的话，不是直白本身。
- 2022 年 11 月 30 日之前写的文字不是 AI 写的。
