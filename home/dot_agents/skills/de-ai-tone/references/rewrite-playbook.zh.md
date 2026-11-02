# 改写手册

**加载时机：** 把扫描命中变成改写，或判断一个被标记的句子该删、该改还是该留。

八个动作，按收益排序。逐个往下走：动作 1 在所有能用的地方先做完，再做动作 2，依次类推。顺序有讲究——删句比任何改写都清得多，而且删句不会引入错误，后面的动作要改动句子，就可能引入错误。

每个动作都标注它服务的模式编号。某个命中不在这个动作的编号里，也可能仍然该用这个动作；编号告诉你该去 `references/patterns-*.md` 的哪一节，取该模式的「盯住这些说法」清单。

目录：1 删掉整句 · 2 砍掉多余的限定 · 3 拆开长句 · 4 用具体名词换掉抽象词 · 5 被动改主动 ·
6 把数字挪到结论旁边 · 7 三项收两项 · 8 用逻辑关系换掉连接词 · 技术精度优先于风格 · 实操示例 ·
操作顺序 · 什么时候不要动

## 1. 删掉整句

**Serves:** A2, A4, A5, A6, A7, A8, A9, D1, D3, E1, E2, E3, E4, E5, F1

同样覆盖机械式删除：D1（把加粗当装饰）、D3（emoji 与装饰性标题）。

多数命中是这样的句子。它存在的目的只是把别的句子连起来。删掉它，重读整段，再看论证还成不成立。成立的话，这句就是脚手架。

该删的例子："In this section we will…"、"It is important to note that…"、"In conclusion, …"、把标题再讲一遍的那一段、"让我们一起……"。

不要删掉唯一交代了某个事实、约束或决定的句子。拿不准就先删掉，把它贴进变更表，需要时再带理由放回去。

## 2. 砍掉多余的限定

**Serves:** B4

一串叠加的限定里，最多只有一处是真不确定。找到它，留下它，其余删掉。如果一处不确定都不剩，这句话就是在断言，那就该写成断言的样子。

| 改写前 | 改写后 |
|---|---|
| The migration may potentially take longer than expected. | The migration takes 12 minutes on the staging dataset; we have not timed production. |
| This could possibly affect latency under some conditions. | Above 2,000 concurrent connections, p99 rises to 300 ms. |

不确定是真的、却说不出在哪一处时，点名这个缺口，不要含糊："We have not tested this above 5,000 rps." 这一句告诉读者的东西，比四个限定多。

## 3. 拆开长句

**Serves:** B2, B3, B5, B7, B8, B10, D2, D4, D5

同样覆盖机械式排版修正：D2（把加粗小标题清单还原成段落）、D4（弯引号改直引号）、D5（中文标点与中英混排空格）。

句子超过大约 35 个词，读者就不再解析它，而是开始略读。在主语发生变化的那个从句边界拆开，然后判断哪一半承载结论，把那一半改短。

| 改写前 | 改写后 |
|---|---|
| The worker reads each batch from the queue and writes it to the warehouse while retrying transient failures with exponential backoff and recording the final error in a dead-letter table for later inspection. | The worker reads a batch, writes it to the warehouse and retries transient failures with exponential backoff. A batch that fails three times goes to the dead-letter table. |

拆开之后，后半句才有资格被删——动作 1 和动作 3 就是这样配合的。

## 4. 用具体名词换掉抽象词

**Serves:** A3, B9, B13, C1, C3, C5, C9

"Solution"、"platform"、"capability"、"approach"、"生态"、"体系"都是容器。换成容器里的那个东西：那个二进制文件、那张表、那个 cron 任务、那个函数。想不出具体名词，说明写的人自己也不知道这句话在讲什么。

| 改写前 | 改写后 |
|---|---|
| The platform delivers a robust solution for data movement. | `sync` copies changed rows every 5 minutes; it reads `updated_at` and writes in 1,000-row batches. |
| 这套体系支撑了业务的快速发展。 | 这套调度器每周跑 4,200 个任务，失败率 0.3%。 |

## 5. 被动改主动

**Serves:** B6, C7

施动者不知道或不重要时，被动是对的（"the table is truncated nightly"）。施动者正是重点、却为了显得中立而被拿掉时，被动就是 AI 腔。

| 改写前 | 改写后 |
|---|---|
| It was decided that retries would be capped at three. | We capped retries at three because the upstream clears transient faults in 30 s. |
| 相关配置已被调整。 | 我们把 `max_conn` 从 10 调到 40。 |

问一句是谁做的。答案是「没人知道」时，就如实写出来："Something lowers the cap; the cause is unknown."

## 6. 把数字挪到结论旁边

**Serves:** B1, C2, C10

形容词要证据。文档里已经有这个测量值时，把它放进支撑该结论的同一句话里。这是搬，不是加——数字必须原文就有。

| 改写前 | 改写后 |
|---|---|
| The service is highly available. | The service has been up 99.98% over 90 days (12 minutes down in March). |
| 性能提升明显。 | p99 从 240 毫秒降到 80 毫秒。 |

绝不能自己编数字。原文只有结论、没有测量值时，改写就如实说明："Availability is 99.98% (measured; see `ops/status.md`)" 或 "we have not measured availability"。

## 7. 三项收两项

**Serves:** A1, B1, B11, B12, B14

给这三项排序。如果两项携带的信息不同、第三项在重复，删掉第三项。如果三项确实各自不同，就三项都留，并在变更表里写明理由——真正的三项列举不是注水。

| 改写前 | 改写后 |
|---|---|
| Fast, scalable, and reliable. | 40 ms p99; adding a node is a config change. |
| 高效、稳定、可靠。 | 构建 6 秒，连续 90 天没有失败。 |

同样的判断也适用于 "not just X but Y" 结构：如果 Y 只是在重述 X，就只留 X。

## 8. 用逻辑关系换掉连接词

**Serves:** A4, C8

"Moreover"、"总的来说"、"综上所述"只说了一句「后面这句跟着来」，没说怎么跟。换成读者真正需要的关系：因果、转折、顺序、例外。没有关系可写时，这句话是清单里的一项，不是论证里的一步。

| 改写前 | 改写后 |
|---|---|
| 总的来说，这个方案更适合小团队。 | 三个人以下的团队用这个方案，因为它不需要专职运维。 |
| Moreover, the cache is cleared on deploy. | The cache is cleared on deploy, so the first request after a release is slow. |

因果：because、so、which means。转折：but、unlike、where the old one。顺序：first、then、after。例外：unless、except when、except for。

## 技术精度优先于风格

压过上面每个动作的规则是：**改写一旦丢了事实，就保留原句并记进变更表。** 一份扫出零分、却描述了另一个系统的文档，比一份扫出三分、描述对了系统的文档更糟。

这些情况保留那句别扭的话：

- **数量未知。** "May fail under load" 含糊，但测试范围确实未知。改写成点名这个缺口，不要删掉那句限定。
- **带法律或安全分量的限定词。** "Must not be used above 85 °C" 保留它的情态动词。
- **错误串、日志行和 API 名称。** 逐字节照抄，它们是数据，不是散文。
- **引用材料。** 被引用的坏例子还是坏例子。给这一行加豁免标记，不要改引文。
- **确实是三项的列举。** 不收。

标记既可以写类别 token，也可以写模式编号；v2 之前写的标记继续有效：

```html
<!-- scan: ignore not-just-x the contrast is the design decision -->
<!-- scan: ignore A1 the contrast is the design decision -->
```

一条命中因为这条规则而留下时，把它记下来：变更表的 `Reason` 列写明为什么，`Precision kept?` 写 `yes — modal retained` 或类似的话。带理由的存活命中是正确的结果，不带理由的存活命中是没做完。

## 实操示例

中文版：

改写前：

> 在当今快速变化的环境中，团队必须借助可观测性释放数据价值。总的来说，需要指出的是，我们的平台可能也许能把诊断时间最多缩短 80%——而且可靠——在各种规模下——在每一种环境里。它不只是一个仪表盘，而是一种全新的工作方式。

改写后：

> 现在诊断一次要 40 分钟，因为没人能看到队列深度。我们的平台把这个指标和另外三个加进你已经在用的仪表盘，上两次事故因此缩短到 12 分钟。

用了哪些动作：1（删掉框架）、8（把「总的来说」换成因果）、2（砍掉「可能也许」，换成实测的 12 分钟）、7（删掉「而且可靠、在各种规模下、在每一种环境里」）、6（把 40 和 12 放到结论旁边）、4（「平台」只在它指读者真会安装的东西时保留）。

同一示例的英文原文：

> In today's fast-paced landscape, teams must leverage observability to unlock the power of their
> data. Moreover, it is important to note that our platform may potentially reduce diagnosis time by
> up to 80% — reliably — at scale — across every environment. It's not just a dashboard, it's a new
> way of working.

改写后：

> Diagnosis takes 40 minutes today because nobody can see queue depth. Our platform adds that metric
> and three others to the dashboard you already run, which cut the last two incidents to 12 minutes.

没有改动的是那个 80%。原文测的是两次事故，所以改写写成事故耗时，而不是把一个百分比泛化开——如果 80% 来自某次压测，改写就保留它，并说明它从哪来。

## 操作顺序

1. 扫描并存下基线输出。
2. 按顺序对全文施加动作 1–8。
3. 重扫。对每一条剩下的命中套用精度规则，把理由记下来。
4. 比对数字：改写里出现的每个数字、日期、标识符和专有名词都在原文里，反之亦然。

## 什么时候不要动

每条模式都是一个默认选择，人也可以故意这么写。

- 被盯住的说法出现在引文、标题、专有名词里，或者出现在一段讨论这个说法而不是使用它的文字里，都不要动。
- 信件或评论里的称呼与落款，比聊天机器人早得多。
- 2022 年 11 月 30 日之前写的文字不是 AI 写的。
- 凭感觉判断的人并不比随机猜好多少，而人类写作一直在吸收 AI 的习惯，所以真正起作用的保护是多个 tell 同时出现。
- 承载作者语气的细节要留下，除非它损害了意思：
  - 一个具体而少见的细节：一个真实地址、一句古怪的引用、「那位过去在我牙医楼上开业的律师」。
  - 混合的感受与未解的张力：「大体上是好事，但它让我不自在，而且我说不清为什么。」
  - 带年代印记的引用：和某一年、某个亚文化绑定的俚语、梗与圈内笑话。
  - 写的人能解释清楚的第一人称选择。
  - 真正的插入语或自我更正：「（我在这里总想写『差不多』，但当时确实是有数的。）」

最容易改过头的中文情形，按下面五条判断：

- 成语与文雅表达——「事半功倍」「未雨绸缪」「行云流水」——是语体，不是 AI 词汇。
- 孤立出现的过渡词只是连接词；每段开头机械重复才是 tell。
- 技术或学术场景里必要的被动与规范句式：「实验数据由传感器自动记录」。
- 必要的清单——API 参数表、待办事项清单——本身已经是最清楚的形态。
- 作者有意的修辞排比保留作者的语气。
