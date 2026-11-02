# Patterns C — Inflation and borrowed authority

C1 Overused AI words · C2 Inflated significance · C3 Vague connection or association · C4 Shallow -ing riders · C5 Sales language · C6 Borrowed authority · C7 Avoiding is, are, and has · C8 Stock challenges-and-outlook · C9 Hype vocabulary · C10 Generic positive conclusion

**Load this reference when:** a draft's claims are sound but the wording around them is heavier than the fact, or a sentence leans on unnamed authorities to make a point it could make on its own.

The fact underneath is usually sound in this group; what is machine-written is the dressing. Significance gets added to an ordinary event, flattery to a place, an unnamed expert to a claim that needs no expert. Read every entry here as a question about the sentence's weight rather than as proof of authorship, and treat each one as *weak alone*: one formal word is a habit, and the habit only becomes a tell when it turns up in company.

### C1. Overused AI words / AI 高频词

**Strength:** *weak alone* — needs company.
**Watch for:** Actually; additionally; align with; bolstered; crucial; deep dive; delve; enduring; enhance; garner; gate/gated/gating (figurative; keep technical uses); highlight (verb); interplay; intricate/intricacies; key (adjective); landscape (abstract noun); meticulous/meticulously; pivotal; quietly; robust (figurative; keep technical uses); showcase; tapestry (abstract noun); testament; underscore (verb); valuable; vibrant; 实际上; 不可否认; 至关重要; 深入探讨; 以无缝的方式; 在这个快节奏的时代; 不断演变的; delve; tapestry; landscape; vibrant; pivotal; underscore; foster; testament; interplay; intricate; unlock the power of; harness the power of; leveraging; seamlessly; embark on a journey; in today's fast-paced landscape; ever-evolving; at the forefront of; game-changer; revolutionize; elevate your/the/our; in the realm of; navigate the landscape.

**Problem:** Models reach for these words far more often than people do, especially in groups. This list holds words that are tells wherever they appear; the phrase lists in C2 to C7 (upstream §13 to §18) hold phrases that are tells because of how they are used. A formal word outside these lists is not a tell by itself, so do not hunt for synonyms of "important" that no one flagged. The scanner's `translated-diction` rule covers the English phrases on this list; the Chinese loan phrases are for the reader's eye, and some of them are caught by the A4 and A7 detectors instead.

**Before:**
> Additionally, a distinctive feature of Somali cuisine is the incorporation of camel meat. An enduring testament to Italian colonial influence is the widespread adoption of pasta in the local culinary landscape, showcasing how these dishes have integrated into the traditional diet.

**After:**
> Somali cuisine also includes camel meat, which is considered a delicacy. Pasta dishes, introduced during Italian colonization, remain common, especially in the south.

**Action:** playbook move 4 — Replace the abstraction with the concrete noun
**Detector:** `translated-diction` (regex)

### C2. Inflated significance / 空泛与句尾强行升华

**Strength:** *weak alone* — needs company.
**Watch for:** a phrase: stands as a testament; a pivotal or crucial moment; plays a key role; marking or shaping the; underscores its importance; reflects a broader; an enduring or lasting legacy; setting the stage for; the evolving landscape; an indelible mark; a stock section: Despite these challenges; continues to thrive; Challenges and Legacy; Future Outlook; Awards and recognition; a send-off paragraph: the future looks bright; exciting times ahead; a step in the right direction; 标志着…的重要转折点; 具有里程碑意义; 生动诠释了; 留下了不可磨灭的印记.

**Problem:** An ordinary detail is said to mark a change, prove a legacy, or promise a future. The move shows up at three scales — a phrase, a stock "challenges and outlook" section, and a send-off paragraph — and the fact underneath is usually sound. Keep the fact, drop the significance, and end on the last concrete fact rather than on a forecast.

**Before (a phrase):**
> The Statistical Institute of Catalonia was officially established in 1989, marking a pivotal moment in the evolution of regional statistics in Spain. This initiative was part of a broader movement across Spain to decentralize administrative functions and enhance regional governance.

**After:**
> The Statistical Institute of Catalonia was established in 1989, part of a wider decentralization of administrative functions in Spain.

**Before (a stock section):**
> Despite its industrial prosperity, Korattur faces challenges typical of urban areas, including traffic congestion and water scarcity. Despite these challenges, with its strategic location and ongoing initiatives, Korattur continues to thrive as an integral part of Chennai's growth.

**After:**
> Korattur has recurring traffic congestion and water shortages.

**Before (a send-off paragraph):**
> The future looks bright for the company. Exciting times lie ahead as they continue their journey toward excellence.

**After:**
> (Cut the paragraph. End on the last concrete fact.)

**Action:** playbook move 6 — Move the number next to the claim
**Detector:** `inflated-significance` (regex)

### C3. Vague connection or association / 模糊关联

**Strength:** *weak alone* — needs company.
**Watch for:** associated with; in association with; connected to; in connection with; linked to; tied to; 与…有关联; 与…相关联; 隶属于; 挂靠.

**Problem:** The text says two things are connected without saying how. "He was associated with the leadership of ExampleCorp" hides whether he was the CEO, a board member, or a consultant. Name the relationship the source gives; when the source does not say, keep the vague wording rather than inventing a role.

**Before:**
> He is associated with the Rajhans Orchestra, which he founded and conducts. The concerts were organised in connection with the celebrations of Pakistan's 50th anniversary.

**After:**
> He founded and conducts the Rajhans Orchestra. The concerts were part of the celebrations of Pakistan's 50th anniversary.

**Action:** playbook move 4 — Replace the abstraction with the concrete noun
**Detector:** `vague-connection` (regex)

### C4. Shallow -ing riders / -ing 挂件

**Strength:** *weak alone* — needs company.
**Watch for:** highlighting; underscoring; emphasizing; ensuring; reflecting; symbolizing; contributing to; cultivating; fostering; encompassing; showcasing; 彰显; 凸显; 体现了; 助力于; 进一步提升.

**Problem:** An -ing phrase is bolted onto a simple fact to make it sound deeper. Attaching it to a named source ("Roger Ebert highlighted the lasting influence") does not make it true. Keep the fact; keep the rider only where the source supports what it claims.

**Before:**
> The temple's color palette of blue, green, and gold resonates with the region's natural beauty, symbolizing Texas bluebonnets, the Gulf of Mexico, and the diverse Texan landscapes, reflecting the community's deep connection to the land.

**After:**
> The temple is painted blue, green, and gold, colors meant to evoke Texas bluebonnets and the Gulf of Mexico.

**Action:** playbook move 1 — Delete the sentence
**Detector:** `ing-rider` (regex)

### C5. Sales language / 宣传腔

**Strength:** *weak alone* — needs company.
**Watch for:** rich (figurative); profound; exemplifies; commitment to; natural beauty; nestled; in the heart of; groundbreaking (figurative); renowned; featuring; a diverse array; breathtaking; must-visit; stunning; iconic; 美不胜收; 令人神往; 位于心脏地带.

**Problem:** The text reads like an advertisement, especially for places, culture, products, or organizations. Every adjective here promises a quality without naming one, and the accumulation of them replaces description. State what the thing is and let the reader judge the quality.

**Before:**
> Nestled within the breathtaking region of Gonder in Ethiopia, Alamata Raya Kobo stands as a vibrant town with a rich cultural heritage and stunning natural beauty.

**After:**
> Alamata Raya Kobo is a town in the Gonder region of Ethiopia.

**Action:** playbook move 4 — Replace the abstraction with the concrete noun
**Detector:** `sales-language` (regex)

### C6. Borrowed authority / 模糊归因与虚假权威

**Strength:** *weak alone* — needs company.
**Watch for:** experts argue; experts believe; observers have cited; industry reports; certain reports; some critics; several publications; it is believed that; widely regarded; widely believed; according to experts; according to analysts; cited, featured, or profiled in a list of outlets; trade publications; independent coverage; an active social media presence; over N followers; 业内专家普遍认为; 相关行业报告指出; 许多观察家表示; 不难看出; 普遍认为.

**Problem:** A name or an unnamed authority stands in for what was said. Unnamed experts prop up a claim; a list of prestige outlets props up a person. The rule is plain: if the source names the real source and what it said, use that; otherwise cut the unsupported claim or the list. A missing citation alone is not a tell, because most writing is unsourced.

**Before (an unnamed authority):**
> Due to its unique characteristics, the Haolai River is of interest to researchers and conservationists. Experts believe it plays a crucial role in the regional ecosystem.

**After:**
> Researchers and conservationists study the Haolai River for its unusual characteristics.

**Before (a prestige list):**
> Her views have been cited in The New York Times, BBC, Financial Times, and The Hindu. She maintains an active social media presence with over 500,000 followers.

**After:**
> Her views have been cited in The New York Times and the BBC.

**Action:** playbook move 1 — Delete the sentence
**Detector:** `borrowed-authority` (regex)

### C7. Avoiding is, are, and has / 回避简单动词

**Strength:** *weak alone* — needs company.
**Watch for:** serves as; stands as; functions as; operates as; marks; represents [a]; boasts; features; offers; maintains [a]; refers to; 作为…的角色; 充当…的角色; 具备…的能力; 展现…的价值; 承担着…的职能.

**Problem:** Simple verbs are replaced with longer phrases, so the sentence sounds formal without becoming more precise. "Boasts over 3,000 square feet" says less than "has 3,000 square feet", and the Chinese equivalents (作为, 充当, 具备, 展现) work the same way against 是, 有, 做. Use *is*, *are*, and *has*.

**Before:**
> Gallery 825 serves as LAAA's exhibition space for contemporary art. The gallery features four separate spaces and boasts over 3,000 square feet.

**After:**
> Gallery 825 is LAAA's exhibition space for contemporary art. The gallery has four rooms totaling 3,000 square feet.

**Action:** playbook move 5 — Convert passive to the actor
**Detector:** `avoiding-copula` (regex)

### C8. Stock challenges-and-outlook / 套路化挑战与展望

**Strength:** *weak alone* — needs company.
**Watch for:** 尽管面临诸多挑战; 但…依然展现出强劲韧性; 机遇与挑战并存; 挑战与机遇并存; 在未来的征途上; 然而前方的道路并非坦途; despite these challenges; continues to thrive; on the journey ahead; the road ahead is not smooth.

**Problem:** The closing paragraph is a fixed shape: name the difficulty, grant the subject resilience anyway, then promise the road ahead. It fits any subject because it says nothing about this one. The detector catches the Chinese forms; the English shape has no detector and is judged by reading.

**Before (the Chinese form):**
> 尽管目前面临着用户增长放缓与供应链成本上升的双重挑战，但只要持续深耕核心技术，团队依然能在时代的浪潮中破浪前行，迎来更加辉煌的明天。

**After:**
> 目前面临的主要问题是获客成本上升与供应链交付延期。

**Before (the same shape in English):**
> Despite the user growth slowdown and rising supply-chain costs, as long as the team keeps refining the core technology, it will ride the wave of the times and welcome a brighter tomorrow.

**After:**
> The main problems right now are user growth slowing and supply-chain costs rising.

**Action:** playbook move 8 — Replace the connective with the logical relation
**Detector:** `challenges-outlook` (regex)

### C9. Hype vocabulary / 职场黑话与空洞大词

**Strength:** *weak alone* — needs company.
**Watch for:** 赋能; 打通…闭环; 底层逻辑; 抓手; 协同效应; 多维度; 全面推进; 矩阵; 护城河; 生态链路; 助力…腾飞; 谱写新篇章; 战略布局; 顶层设计; synergy; paradigm shift; move the needle; low-hanging fruit; best-in-class; world-class; cutting-edge; holistic; value-add; core competency; thought leadership; turnkey solution; end-to-end solution; actionable insight; circle back; next-generation; operationalize.

**Problem:** Corporate jargon and empty macro-vocabulary cover the absence of specific information: the words sound senior while saying nothing about what was actually done. Some of them are legitimate in context — a real synergy, a genuine paradigm shift, a turnkey product that is sold that way — so a hit is a prompt to judge, not a verdict. Replace the phrase with the concrete action it stands for, or cut it.

**Before:**
> This release rolls out a new checkout flow, cuts the number of steps from five to two, and brings the median response time down from 400 ms to 120 ms — a cutting-edge upgrade that empowers the funnel end to end and builds a solid moat for the platform.

**After:**
> This release rolls out a new checkout flow, cuts the number of steps from five to two, and brings the median response time down from 400 ms to 120 ms.

**Action:** playbook move 4 — Replace the abstraction with the concrete noun
**Detector:** `corporate-jargon` (regex)

### C10. Generic positive conclusion / 通用积极结论

**Strength:** *weak alone* — needs company.
**Watch for:** 未来可期; 迈出重要一步; 持续追求卓越; 未来将更加美好; 迈向更美好的明天; the future looks bright; the future is promising; a step in the right direction; exciting times ahead.

**Problem:** The closing paragraph says the future is bright without naming what happens next, and the same sentence would fit any document. It carries no decision and no next action, so the reader stops without knowing where to look. Cut it and end on the last concrete fact, or on the next action with an owner and a date.

**Before (the Chinese form):**
> 改版将于周二上线。未来可期。随着这次改版上线，团队将在持续追求卓越的道路上迈出重要一步。

**After:**
> 改版将于周二上线。

**Before (the same shape in English):**
> The upgrade rolls out on Tuesday. The future looks bright. As this upgrade rolls out, the team will keep pursuing excellence and take another important step forward.

**After:**
> The upgrade rolls out on Tuesday.

**Action:** playbook move 6 — Move the number next to the claim
**Detector:** `generic-positive` (regex)

## When not to act

- Leave a watched phrase alone inside a quotation, a title, a proper name, or a passage that discusses the phrase rather than uses it.
- Do not hunt outside the C1 list. A formal word the scanner does not list is not a tell by itself, and rewriting it adds no value.
- "Robust", "key", "gate" and "landscape" often name real things in technical writing: a rate-limiting gate, a cache key, a deployment landscape. Keep the technical use.
- A vague connection is fine when the source is vague. Cut the claim only where the source says something more specific than the draft does.
- A missing citation alone is not a tell. Most writing is unsourced, and adding a source you do not have is worse than leaving the gap.
- Elevated Chinese is register, not AI vocabulary. 事半功倍 and 未雨绸缪 are idioms; a real anniversary, a real award, and a real funding round are facts, and calling them milestones is honest when the milestone is real.
