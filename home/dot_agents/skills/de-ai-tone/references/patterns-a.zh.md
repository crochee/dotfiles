# A 组模式：铺陈代替陈述

A1 否定式对比 · A2 一句总结与碎片行 · A3 深刻金句 · A4 报幕式开场 · A5 与无人辩论 · A6 假问题自问自答 · A7 假坦诚假中立 · A8 模板转折与阶段口号 · A9 固定关注句式

**何时加载本文件：** 扫描命中了 A 组的任一类别 token，需要判断被标记的句子是在陈述事实，还是只在预告事实要来。

九种句式共用一个成因：文本用掉一整句来说「接下来的内容很重要」。对比加重量，收尾句重复，金句显得深刻，铺垫先报幕，辩解回应了没人提出的反对意见，问题由下一句自己回答，坦诚被宣布而非展示，转折被宣布为转折，公式告诉读者该看哪里。这一组的每一条都能凭一次命中就动手，通常的修法是删掉整句，或者直接陈述。

### A1. Not X but Y / 否定式对比

**强度：** 出现一次即可动手。
**观察：** not just X but Y; not only X but Y; it's not X, it's Y; more than just a/an/the; this is not just about; 不是…而是; 不仅…更是; 不仅仅…而是; 不只是…更是
**问题：** 否定的一半说出了没人提出过的说法，于是肯定的一半显得比事实更大。整句只增加重量，没有增加主张。
**改写前：**
> 这不仅是一次研发范式的变革，更是企业构建核心技术护城河的关键一步。
**改写后：**
> 这次升级改变了研发范式，也让企业逐步建起了自己的技术壁垒。
**动作：** playbook 动作 7 — 三项收两项
**探测器：** `not-just-x` (regex)

### A2. One-line closers and dramatic fragments / 一句总结与碎片行

**强度：** 出现一次即可动手。
**观察：** That is the real win; That distinction matters; Let that sink in; This shows the importance of; The message was clear; In summary,; In conclusion,; To sum up,; All in all,; In short,; Key takeaways; Bottom line; This underscores the importance of; 这才是重点; 真正的意义在于; 总而言之; 综上所述; 由此可见; 总之
**问题：** 这一行要求读者为某个结论停下来，而不是给结论增加内容；一串碎片句承载的强调，句子本身并没有承载。重复上一段内容的收尾句只是脚手架。
**改写前：**
> 重构后，发布流程从 40 分钟缩短到 6 分钟。这才是重点。
**改写后：**
> 重构后，发布流程从 40 分钟缩短到 6 分钟。
**动作：** playbook 动作 1 — 删掉整句
**探测器：** `one-line-closer`, `empty-summary` (regex)

### A3. Sayings that sound deep / 深刻金句

**强度：** 出现一次即可动手。
**观察：** the real question is; in reality; what really matters; fundamentally; the deeper issue; the heart of the matter; the language of; the currency of; the architecture of; becomes a trap; is not a tool but a mirror; 真正的问题在于; 本质上; 说到底; 归根到底; 真正的本质; 最深层的意义; 表面上…实际上
**问题：** 平常的观点被包装成隐藏的真相或一句格言，而包装本身没有增加任何细节；用它所代替的具体结论替掉它。探测器只覆盖英文形式（「At its core」归 A4），中文对应说法靠阅读判断。
**改写前：**
> 本质上，这不是技术选型的问题，而是组织能力的问题。
**改写后：**
> 问题不只在技术选型，还在团队能不能自己维护这套系统。
**动作：** playbook 动作 4 — 用具体名词换掉抽象词
**探测器：** `deep-saying` (regex)

### A4. Staged run-up before the point / 报幕式开场

**强度：** 出现一次即可动手。
**观察：** Let's dive in; let's break this down; here's what you need to know; without further ado; heads up; quick note; Here's the thing; The thing is; In this section, we will…; before we dive in; by the end of this article; Moreover,; Furthermore,; At its core; When it comes to; 值得注意的是; 值得一提的是; 需要注意的是; 总的来说; 综上所述; 不仅如此; 除此之外; 换言之; 众所周知; 毫无疑问; 总而言之; 一言以蔽之; 由此可见; 总之; 此外，; 与此同时，; 归根结底; 悄然改变; 下面让我们一探究竟; 话不多说，直接上干货; 接下来看重点; 在当今…时代; 在…背景下
**问题：** 作者先报幕，或者先摆出一个坦诚的瞬间，然后才进入内容。铺垫句描述的是文档本身或者要讲的主题，于是第一个事实总是晚到一句。
**改写前：**
> 下面让我们一探究竟，看看缓存到底是怎么工作的。
**改写后：**
> Next.js 的缓存分三层：请求 memoization、数据缓存、路由缓存。
**动作：** playbook 动作 8 — 用逻辑关系换掉连接词
**探测器：** `meta-narration`, `empty-transition`, `zh-translated-connective`, `zh-empty-opening` (regex)

### A5. Arguing with no one / 与无人辩论

**强度：** 出现一次即可动手。
**观察：** This isn't (mainly) about; I'm not saying; To be clear; Don't get me wrong; This is not to say; Some might say… but; A tempting approach would be; One might be tempted to; An obvious approach would be; You might think… but; It would be easy to just; 我并不是说; 并不是要否定; 诚然…但是
**问题：** 句子在回应一个文本里根本不存在的反对意见，或者替一个没人提过的方案辩护，通常是早稿留下的残余。辩解花掉一句，却不增加任何主张。
**改写前：**
> 这并不是说文档不重要，我也不是在否定测试的价值；真正的问题是 Agent 在行动时能不能用上这条指令。
**改写后：**
> 真正的问题是 Agent 在行动时能不能用上这条指令。
**动作：** playbook 动作 1 — 删掉整句
**探测器：** `arguing-with-nobody` (regex)

### A6. Rhetorical question theatre / 假问题自问自答

**强度：** 出现一次即可动手。
**观察：** So what does this really mean?; What really lies behind?; The answer is obvious; The answer is clear; 那么…究竟…？; 究竟意味着什么？; 究竟该如何破局？; 答案其实很简单; 答案不言自明; 答案显而易见; 答案呼之欲出
**问题：** 段落先抛出问题，下一句就给出答案，用制造出来的悬念代替信息；问题本身没有带来答案之外的东西。文本真正悬而未决的问题不属于这一条。
**改写前：**
> 为什么这款工具能迅速风靡全网？答案其实很简单：因为它真正击中了用户的核心痛点。
**改写后：**
> 这款工具受欢迎，是因为它解决了格式导出的痛点。
**动作：** playbook 动作 1 — 删掉整句
**探测器：** `rhetorical-question` (regex)

### A7. False candour, false neutrality / 假坦诚假中立

**强度：** 出现一次即可动手。
**观察：** To be honest,; Honestly,; I have to admit; I must admit; Truth be told; Let's be real; 说实话; 老实说; 不得不承认的是; 不可否认; 客观来讲; 其实吧; 说真的
**问题：** 文本先声明自己坦诚或者中立，然后说出一句很普通的话。这种框架借用了诚实的权威，却没有展示任何东西。
**改写前：**
> 老实说，在这个快节奏的时代，想要保持专注并不是一件容易的事。
**改写后：**
> 现代人在工作中很难保持长时间专注。
**动作：** playbook 动作 1 — 删掉整句
**探测器：** `false-candour` (regex)

### A8. Staged contrast and stage slogans / 模板转折与阶段口号

**强度：** 出现一次即可动手。
**观察：** 然而，事实并非如此; 不过，事情并非如此; 故事并未就此结束; 开启新篇章; 迈向新征程; 这只是一个开始; 真正的转折点才刚刚开始; but the story doesn't end here; the next chapter; embark on a new journey; begin a new chapter; here is the turning point; and that changes everything
**问题：** 段落把转折写成模板，或者把阶段写成口号，宣布一件将要发生的事，而不是把它说出来。同一个口号在几节里重复，就会变成全文唯一的论点。
**改写前：**
> 上线之后，团队的排期依然紧张。然而，事实并非如此：真正的问题在于需求一直在变。
**改写后：**
> 上线之后，团队的排期依然紧张。真正的问题在于需求一直在变。
**动作：** playbook 动作 1 — 删掉整句
**探测器：** `staged-contrast` (regex)

### A9. Fixed attention formulas / 固定关注句式

**强度：** 出现一次即可动手。
**观察：** 相比较…我更关心; 大家最容易盯着; 值得关注的是; 让我更感兴趣的是; 最值得关注的是; what interests me most is; what excites me most is; the most overlooked aspect here is; let's focus on what really matters
**问题：** 句子先告诉读者哪件事重要，然后才说它是什么。这种公式换个话题照样成立，因为它什么也没说；注意力引导是舞台指示，不是事实。
**改写前：**
> 相比较报表的华丽程度，我更关心数据什么时候能到。
**改写后：**
> 报表好不好看是次要的，数据什么时候能到才是关键。
**动作：** playbook 动作 1 — 删掉整句
**探测器：** `attention-formula` (regex)

## 什么时候不要动

- 引用、标题、专有名词里出现的套话保持原样，用 `scan: ignore` 标注并写明理由。
- 单独出现的过渡词是正常连接；只有当每段开头都在机械重复同一个过渡词时才需要治理（A4）。
- 地道成语与文雅表达（例如「事实上」「说到底」）属于正常修辞；只有当它替代了本该写出的具体结论时才改（A3）。
- 作者有意的修辞排比和情感递进不要抹掉（A2、A8）。
- A7 只在没有人质疑、铺垫显得突兀时处理；确有争议、需要表明立场时保留。
- A5 只在没人提出该反对意见时删除；文本自己引用并完整回答的反对意见保留。
