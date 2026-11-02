# C 组模式：膨胀与借来的权威

C1 AI 高频词 · C2 空泛与句尾强行升华 · C3 模糊关联 · C4 -ing 挂件 · C5 宣传腔 · C6 模糊归因与虚假权威 · C7 回避简单动词 · C8 套路化挑战与展望 · C9 职场黑话与空洞大词 · C10 通用积极结论

**何时加载本文件：** 稿子的主张本身站得住，措辞却比事实更重；或者某句话靠一个没具名的权威替自己背书。

C 组的问题多半出在包装上，底下的事实通常没问题：一个平常事件被说成转折，一个地方被夸成风景，一个不需要专家的结论被挂在专家名下。读这一组时，把每一条当成对句子分量的追问，而不是作者身份的铁证；每一条单独出现都不算数，习惯只有成堆出现才是证据。

### C1. Overused AI words / AI 高频词

**强度：** 单独出现不算数——需要同段其他信号配合。
**观察：** Actually; additionally; align with; bolstered; crucial; deep dive; delve; enduring; enhance; garner; gate/gated/gating（比喻义，技术用法保留）; highlight（动词）; interplay; intricate/intricacies; key（形容词）; landscape（抽象名词）; meticulous/meticulously; pivotal; quietly; robust（比喻义，技术用法保留）; showcase; tapestry（抽象名词）; testament; underscore（动词）; valuable; vibrant; 实际上; 不可否认; 至关重要; 深入探讨; 以无缝的方式; 在这个快节奏的时代; 不断演变的; delve; tapestry; landscape; vibrant; pivotal; underscore; foster; testament; interplay; intricate; unlock the power of; harness the power of; leveraging; seamlessly; embark on a journey; in today's fast-paced landscape; ever-evolving; at the forefront of; game-changer; revolutionize; elevate your/the/our; in the realm of; navigate the landscape

**问题：** 模型用这些词的频率远高于人，尤其成串出现时。这一份清单里的词出现在哪里都是 tell；C2 到 C7 的清单里是短语，是「怎么用」让它们成了 tell。清单之外的正式用词本身不构成 tell，所以不要去替换没人标记过的那些「重要」的同义词。扫描器的 `translated-diction` 规则管的是这份清单里的英文说法；中文直译高频词靠人工读，其中一部分由 A4 和 A7 的探测器负责。

**改写前：**
> 不可否认的是，在这个快节奏的时代，深入探讨这类问题至关重要。它在不断演变的行业格局中起到了至关重要的作用。

**改写后：**
> 这类问题需要专门讨论。它在不断演变的行业格局中起了重要作用。

**动作：** playbook 动作 4 — 用具体名词换掉抽象词
**探测器：** `translated-diction` (regex)

### C2. Inflated significance / 空泛与句尾强行升华

**强度：** 单独出现不算数——需要同段其他信号配合。
**观察：** 短语级：stands as a testament; a pivotal or crucial moment; plays a key role; marking or shaping the; underscores its importance; reflects a broader; an enduring or lasting legacy; setting the stage for; the evolving landscape; an indelible mark; 固定小节级：Despite these challenges; continues to thrive; Challenges and Legacy; Future Outlook; Awards and recognition; 收尾段级：the future looks bright; exciting times ahead; a step in the right direction; 标志着…的重要转折点; 具有里程碑意义; 生动诠释了; 留下了不可磨灭的印记

**问题：** 一个平常的细节被说成转折、证明或承诺。这个动作有三个尺度——一个短语、一段套路的「挑战与展望」、一段收尾——底下的事实通常都没问题。留下事实，去掉分量，收尾停在最后一个具体事实上，而不是停在一句预测上。

**改写前（短语级）：**
> 公司于 2021 年成立了华南研发中心，这一战略举措标志着公司在区域技术布局上迈出了里程碑式的一步，为后续的高质量发展奠定了坚实基石。

**改写后：**
> 公司在 2021 年成立了华南研发中心，负责华南区域的技术支持与产品研发。

**改写前（固定小节级）：**
> 尽管该地区工业繁荣，但城市问题依然突出，交通拥堵与水资源短缺屡见不鲜。尽管面临诸多挑战，凭借区位优势与持续推进的举措，该市仍在城市扩张中蓬勃发展。

**改写后：**
> 该市面临的主要问题是交通拥堵与水资源短缺。

**改写前（收尾段级）：**
> 公司的未来一片光明。激动人心的时代即将到来，他们将继续踏上追求卓越的旅程。

**改写后：**
> （删掉整段。以最后一个具体事实收尾。）

**动作：** playbook 动作 6 — 把数字挪到结论旁边
**探测器：** `inflated-significance` (regex)

### C3. Vague connection or association / 模糊关联

**强度：** 单独出现不算数——需要同段其他信号配合。
**观察：** associated with; in association with; connected to; in connection with; linked to; tied to; 与…有关联; 与…相关联; 隶属于; 挂靠

**问题：** 文本只说两件事有关联，不说怎么关联。「他与 ExampleCorp 的管理层有关联」掩盖了他到底是 CEO、董事还是顾问。原文给了关系就写明关系；原文没给，就保留模糊的说法，不要替他安一个身份。

**改写前：**
> 他与 Rajhans 乐团有关联，该乐团由他创办并指挥。这些音乐会是与巴基斯坦独立 50 周年庆典有关的活动。

**改写后：**
> 他创办并指挥 Rajhans 乐团。这些音乐会是巴基斯坦独立 50 周年庆典的一部分。

**动作：** playbook 动作 4 — 用具体名词换掉抽象词
**探测器：** `vague-connection` (regex)

### C4. Shallow -ing riders / -ing 挂件

**强度：** 单独出现不算数——需要同段其他信号配合。
**观察：** highlighting; underscoring; emphasizing; ensuring; reflecting; symbolizing; contributing to; cultivating; fostering; encompassing; showcasing; 彰显; 凸显; 体现了; 助力于; 进一步提升

**问题：** 一个 -ing 短语被挂在简单事实上，让它听起来更深。挂到具名来源上（「Roger Ebert 强调了其持久的影响」）并不会让它为真。留下事实；只有原文支持的说法才留下挂件。

**改写前：**
> 神庙以蓝、绿、金为主的配色与当地的自然之美相呼应，象征着得克萨斯蓝帽、墨西哥湾和多样的得州风景，体现出社区与土地之间的深厚联结。

**改写后：**
> 神庙被漆成蓝、绿、金三色，这些颜色意在唤起得克萨斯蓝帽与墨西哥湾的形象。

**动作：** playbook 动作 1 — 删掉整句
**探测器：** `ing-rider` (regex)

### C5. Sales language / 宣传腔

**强度：** 单独出现不算数——需要同段其他信号配合。
**观察：** rich（比喻义）; profound; exemplifies; commitment to; natural beauty; nestled; in the heart of; groundbreaking（比喻义）; renowned; featuring; a diverse array; breathtaking; must-visit; stunning; iconic; 美不胜收; 令人神往; 位于心脏地带

**问题：** 文本读起来像广告，尤其是写地方、文化、产品或机构的时候。这里的每个形容词都许诺了一种品质，却没有点名任何一种；许诺堆多了，就把描述挤掉了。说明它是什么，品质交给读者判断。

**改写前：**
> 阿拉玛塔拉亚科博坐落于埃塞俄比亚令人叹为观止的贡德尔地区，是一座充满活力的城镇，拥有丰富的文化遗产和迷人的自然风光。

**改写后：**
> 阿拉玛塔拉亚科博是埃塞俄比亚贡德尔地区的一个城镇。

**动作：** playbook 动作 4 — 用具体名词换掉抽象词
**探测器：** `sales-language` (regex)

### C6. Borrowed authority / 模糊归因与虚假权威

**强度：** 单独出现不算数——需要同段其他信号配合。
**观察：** experts argue; experts believe; observers have cited; industry reports; certain reports; some critics; several publications; it is believed that; widely regarded; widely believed; according to experts; according to analysts; cited, featured, or profiled in a list of outlets; trade publications; independent coverage; an active social media presence; over N followers; 业内专家普遍认为; 相关行业报告指出; 许多观察家表示; 不难看出; 普遍认为

**问题：** 一个名字或一个没具名的权威，顶替了「谁说了什么」。没具名的专家撑起一个论断，一串有分量的媒体名单撑起一个人。规则只有一条：原文写明了真实来源和它说了什么，就用那个；否则删掉无依据的论断或那份名单。仅仅缺少引文不算 tell，因为多数写作本来就没有引文。

**改写前（没具名的权威）：**
> 业内专家普遍认为，随着大模型技术的不断演进，算力基础设施将成为决定未来竞争格局的关键胜负手。

**改写后：**
> 大模型训练与推理对算力基础设施的要求越来越高。

**改写前（一串有分量的名单）：**
> 她的观点被《纽约时报》、BBC、《金融时报》和《印度教徒报》引用。她在社交媒体上十分活跃，拥有超过 50 万粉丝。

**改写后：**
> 她的观点被《纽约时报》和 BBC 引用。

**动作：** playbook 动作 1 — 删掉整句
**探测器：** `borrowed-authority` (regex)

### C7. Avoiding is, are, and has / 回避简单动词

**强度：** 单独出现不算数——需要同段其他信号配合。
**观察：** serves as; stands as; functions as; operates as; marks; represents [a]; boasts; features; offers; maintains [a]; refers to; 作为…的角色; 充当…的角色; 具备…的能力; 展现…的价值; 承担着…的职能

**问题：** 简单的动词被更长的短语替换，句子显得正式，却并没有更精确。「boasts over 3,000 square feet」比「has 3,000 square feet」信息更少；中文里的「作为」「充当」「具备」「展现」对「是」「有」「做」也是同样的关系。用 *is*、*are*、*has*；中文用「是」「有」「做」。

**改写前：**
> 该系统充当着各业务模块之间信息流转枢纽的角色，具备极高的数据吞吐能力。

**改写后：**
> 该系统是各业务模块的数据枢纽，吞吐量很高。

**动作：** playbook 动作 5 — 被动改主动
**探测器：** `avoiding-copula` (regex)

### C8. Stock challenges-and-outlook / 套路化挑战与展望

**强度：** 单独出现不算数——需要同段其他信号配合。
**观察：** 尽管面临诸多挑战; 但…依然展现出强劲韧性; 机遇与挑战并存; 挑战与机遇并存; 在未来的征途上; 然而前方的道路并非坦途; despite these challenges; continues to thrive; on the journey ahead; the road ahead is not smooth

**问题：** 结尾那段是固定形状：先说困难，再无论如何承认主体的韧性，最后承诺前方的路。它能套在任何主题上，正因为它对眼前这个主题什么都没说。探测器抓的是中文形式；英文的同一形状没有探测器，靠阅读判断。

**改写前：**
> 尽管目前面临着用户增长放缓与供应链成本上升的双重挑战，但只要持续深耕核心技术，团队依然能在时代的浪潮中破浪前行，迎来更加辉煌的明天。

**改写后：**
> 目前面临的主要问题是获客成本上升与供应链交付延期。

**改写前（同一形状的英文形式）：**
> Despite the user growth slowdown and rising supply-chain costs, as long as the team keeps refining the core technology, it will ride the wave of the times and welcome a brighter tomorrow.

**改写后：**
> The main problems right now are user growth slowing and supply-chain costs rising.

**动作：** playbook 动作 8 — 用逻辑关系换掉连接词
**探测器：** `challenges-outlook` (regex)

### C9. Hype vocabulary / 职场黑话与空洞大词

**强度：** 单独出现不算数——需要同段其他信号配合。
**观察：** 赋能; 打通…闭环; 底层逻辑; 抓手; 协同效应; 多维度; 全面推进; 矩阵; 护城河; 生态链路; 助力…腾飞; 谱写新篇章; 战略布局; 顶层设计; synergy; paradigm shift; move the needle; low-hanging fruit; best-in-class; world-class; cutting-edge; holistic; value-add; core competency; thought leadership; turnkey solution; end-to-end solution; actionable insight; circle back; next-generation; operationalize

**问题：** 职场黑话与空洞的大词，用来盖住具体信息的短缺：这些词听着高级，却说不出到底做了什么。其中有些在具体语境里是正当的——真正的协同效应、真正的范式转移、确实按交钥匙方式卖的产品——所以命中只是一个让你去判断的提示，不是判决。把它替换成它所代替的那个具体动作，或者删掉。

**改写前：**
> 本次产品升级通过深度融合前沿技术，全面赋能业务多维场景，打通用户从感知到转化的全链路闭环，构建了坚实的竞争护城河。

**改写后：**
> 这次升级优化了核心功能，缩短了用户的购买步骤，提升了转化率。

**改写前（同一形状的英文形式）：**
> This release rolls out a new checkout flow, cuts the number of steps from five to two, and brings the median response time down from 400 ms to 120 ms — a cutting-edge upgrade that empowers the funnel end to end and builds a solid moat for the platform.

**改写后：**
> This release rolls out a new checkout flow, cuts the number of steps from five to two, and brings the median response time down from 400 ms to 120 ms.

**动作：** playbook 动作 4 — 用具体名词换掉抽象词
**探测器：** `corporate-jargon` (regex)

### C10. Generic positive conclusion / 通用积极结论

**强度：** 单独出现不算数——需要同段其他信号配合。
**观察：** 未来可期; 迈出重要一步; 持续追求卓越; 未来将更加美好; 迈向更美好的明天; the future looks bright; the future is promising; a step in the right direction; exciting times ahead

**问题：** 结尾那段说未来一片光明，却不说明接下来会发生什么；同一句话可以安在任何一份文档后面。它不给出决定，也不给出下一步动作，读者读完不知道该看哪里。删掉它，以最后一个具体事实收尾，或者以一件有负责人、有时间的下一步动作收尾。

**改写前：**
> 改版将于周二上线。未来可期。随着这次改版上线，团队将在持续追求卓越的道路上迈出重要一步。

**改写后：**
> 改版将于周二上线。

**改写前（同一形状的英文形式）：**
> The upgrade rolls out on Tuesday. The future looks bright. As this upgrade rolls out, the team will keep pursuing excellence and take another important step forward.

**改写后：**
> The upgrade rolls out on Tuesday.

**动作：** playbook 动作 6 — 把数字挪到结论旁边
**探测器：** `generic-positive` (regex)

## 什么时候不要动

- 引用、标题、专有名词里出现的说法不要动；一段在讨论某个说法本身的文字，也不要动。
- 不要在 C1 词表之外找。词表外的正式用词本身不是 tell，改它没有收益。
- 技术文本里的 robust、key、gate、landscape 常常是实指（限流闸门、缓存键、部署环境），技术用法要保留；技术或学术场景里必要的被动与规范句式（例如「实验数据由传感器自动记录」）也不是 C7 的对象。
- 原文本身就模糊时，模糊关联不是问题；只有当原文比草稿说得更具体时才删。
- 只缺引文不算 tell。多数写作本来就没有引文，凭空补一个引文比留着缺口更糟。
- 中文里的文雅表达是语体，不是 AI 词汇：「事半功倍」「未雨绸缪」是成语；真实的周年、真实的奖项、真实的融资是事实，真的称为里程碑是诚实的。
