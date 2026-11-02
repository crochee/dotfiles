# F 组模式：写错了读者

F1 重复读者已知

**何时加载本文件：** 改写一段回复、一条评审意见或一条消息，而读者已经掌握了上下文时。

模型写作时假定的读者不掌握任何上下文，因为这样能覆盖最多的情况。线程里的回复面对的是已经知道背景的读者，
这两种读者之间的差就是本组要处理的东西。别的组处理句子本身的形状，本组处理句子与读者的关系，所以这里没有
词表可以扫。本组只有一条模式，也是整个技能里唯一没有探测器的：证据在文本周围的对话里，不在字面里。

上游那一对例子是英文的聊天回复，本文件按上游原文保留；其余示例按中文回复的形状写。

### F1. Re-explaining what the reader knows / 重复读者已知

**强度：** 出现一次即可动手——但前提是看得到读者的上下文。
**观察：** 先把问题再说一遍（a short reply that restates the problem, walks through the diagnosis, and
lays out the evidence before it reaches the decision）; 再走一遍诊断; 把证据摊开来说; 用一条查询、一段命令
或一组数字来证明方案可行（a query, command, or set of numbers included to prove a plan will work）;
把对方写过或已经同意的背景重讲一遍（background the other person wrote or already agreed to）;
结论放在最后一句（the answer itself sitting in the last line）。

**问题：** 回复里的读者已经有上下文，把背景重讲一遍不会增加任何信息，只会把结论埋掉。每一句单独看都通顺，
所以这个模式能躲过句子层面的清理，也没有扫描器能标出来；只有周围的对话能暴露它。看得见那段对话、或者文本
明显是一段回复时再动手；判断不了就问一句，或者放着不动。中文回复里是同一个形状：先把背景复述一遍，再讲诊断，
最后才给结论。

**改写前：**
> Yeah, you're right, this works around the issue rather than fixing it. The real fix is in
> `MergeService`: when we move a child under a new parent, it should update `pipeline_id` along with
> `parent_id`. We can backfill the bad rows from the audit log with
> `Change.where(field: "pipeline_id", source: "merge")`. I checked QA: 123 past merges, only 6 rows
> wrong now, so the cleanup is small.
>
> Since `MergeService` is shared and not specific to this account, I'd rather open a separate ticket
> than widen this PR. The fallback here is fine to keep until then.

**改写后：**
> Agreed, this is a workaround. Fixing it properly in `MergeService` would widen this ticket well past
> its scope: it is shared code, so it means checking the merge flow for every account, plus a backfill
> for the rows that are already wrong.
>
> I'd rather keep this PR account specific and open a separate ticket for the `MergeService` fix and
> the backfill. Let me know if that works.

**改写前（用查询证明方案）：**
> 缓存重写应该是安全的。我跑了 `ab -n 2000 -c 50 http://localhost:8080/cache`，改动前 p99 是 240 毫秒，
> 改动后是 80 毫秒，回放 30 分钟真实流量之后命中率从 0.41 升到 0.93。旧的 key 路径保留一个版本，
> 两条路径可以并行跑一段时间。

**改写后：**
> 缓存重写可以上线：同一份回放下 p99 从 240 毫秒降到 80 毫秒，命中率从 0.41 升到 0.93。旧的 key 路径
> 保留一个版本，两条路径并行跑。

**改写前（读者已经有的背景）：**
> 周二讨论过的：认证服务每 24 小时原地轮换会话令牌，客户端会透明刷新。我们当时同意不用定时任务重启
> 服务，因为那会把所有在线会话踢掉。计费服务也是每晚轮换凭据，理由一样，所以我建议它的现有实现先不动。

**改写后：**
> 认证服务是原地轮换会话令牌的，用定时任务重启会把所有在线会话踢掉。计费服务每晚轮换凭据，模型相同，
> 它的实现也先不动。

**改写前（结论落在最后一句）：**
> 发布失败在迁移这一步。`accounts` 表有 420 万行，迁移要加一个没有默认值的非空 `pipeline_id` 列。
> 迁移在只有 1.2 万行的预发副本上跑了 90 秒。Postgres 14 对常量默认值的加列可以避免全表重写，但子查询
> 默认值不是常量。改法是先把列加成可空，分批回填，再设为 `NOT NULL`。

**改写后：**
> 发布失败在迁移：加一个没有默认值的非空 `pipeline_id` 列会重写 420 万行，而 Postgres 14 只对常量默认值
> 免掉这次重写。先把列加成可空，分批回填，再设为 `NOT NULL`。

**改写前（一条评审意见）：**
> 评审的人提到新接口应该校验租户 id。租户 id 由网关设置、存在 `Account` 行上，所以放在 handler 里校验
> 意味着每个请求都多一次数据库查询。校验应该放在网关，因为那里已经解析出了租户 id，handler 只需要断言
> id 存在。另一个还没定的问题是完全没有租户 id 的请求怎么处理，目前会落到默认租户上。

**改写后：**
> 租户 id 的校验放在网关，网关那里已经解析出这个 id 了，handler 只需要断言它存在。没有租户 id 的请求
> 目前会落到默认租户，这个还得定一个处理方式。

**改写前（回复重复了它指向的那份文档）：**
> 事故复盘在 `docs/incident-2026-03-11.md`。这份文档写了时间线、根因和后续动作，也解释了为什么发布时
> 跳过了缓存失效。既然文档里已经列了全部动作项，我们直接拿它当跟踪表，不用再开一张工单。

**改写后：**
> 事故复盘在 `docs/incident-2026-03-11.md`。后续动作已经在文档里列全了，直接拿它当跟踪表就行，
> 不用再开一张工单。

**改写前（一条简短的聊天回复）：**
> 确认一下我们刚才说的：发布时应该先跑迁移再部署，我们把它拆成两步，因为这个迁移跟旧代码不向后兼容。
> 第一步把列加成可空，第二步在所有读这列的代码都上线之后把它设成 `NOT NULL`。

**改写后：**
> 拆成两步，和刚才说的一样：先加可空列，等读这列的代码都上线之后，再在下一个版本里设成 `NOT NULL`。

**改写前（回复重复了读者刚读过的发布说明）：**
> 上一个版本（v2.3.0）的发布说明里写了缓存键格式的调整，新增了 `v2:` 前缀，并且说明了旧键在 30 天内
> 仍然有效。这个改动是为了配合 `CacheReader` 的新版本，README 里也已经同步更新过了。所以升级文档里
> 不需要再重复一遍。

**改写后：**
> v2.3.0 的发布说明写了缓存键加 `v2:` 前缀、旧键 30 天内仍然有效这两件事，README 也已同步，升级文档里
> 就不用再重复。

**改写前（先复述问题再回答）：**
> 收到，我理解你问的是灰度发布能不能在中途回滚。灰度发布是先放一部分流量、观察指标、再决定扩大还是收窄。
> 中途回滚在这个方案里是支持的，因为每一步都记录了批次号，回滚就是停掉当前批次、重新放上一批。

**改写后：**
> 可以回滚：每一步都记了批次号，回滚就是停掉当前批次、重新放上一批。

**动作：** playbook 动作 1 — 删掉整句
**探测器：** 无探测器——靠阅读判断。

## 什么时候不要动

- 只在看得见读者上下文时动手：线程、工单，或者前面那条消息。判断不了这是不是一段回复，就问一句，或者
  放着不动。
- 不要把背景从一份会被「冷读」的人读到的文档里删掉：独立文档仍然需要自己的上下文，F1 针对的是回复。
- 对长消息回一封长回复，不等于命中这个模式。长度跟着线程走，真正的信号只有读者已经有的那部分复述。
- 读者没有的事实不算复述。留下那个会改变读者是否同意的事实，以及读者行动需要的链接。
- 评审者提出一个话题，不等于要求一份完整说明。诊断和证据应该写进随后那份工单或文档。
- 引文保留原来的上下文。不要改引文，把这个决定记进变更表。
