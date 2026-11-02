# Patterns A — Staging instead of stating

A1 Not X but Y · A2 One-line closers and dramatic fragments · A3 Sayings that sound deep · A4 Staged run-up before the point · A5 Arguing with no one · A6 Rhetorical question theatre · A7 False candour, false neutrality · A8 Staged contrast and stage slogans · A9 Fixed attention formulas

**Load this reference when:** a scan reports a hit under a group A category token and you need to decide whether the flagged sentence states a fact or only signals that a fact is coming.

Nine shapes share one cause: the text spends a sentence on the importance of what it is about to say. A contrast adds weight, a closer repeats, a saying sounds deep, a run-up stages the point, a defence answers an objection nobody raised, a question is answered by the line after it, candour is declared instead of shown, a turn announces itself as a turn, and a formula says where to look. Every pattern here justifies an edit on a single sighting, and the usual fix is deletion or a direct statement.

### A1. Not X but Y / 否定式对比

**Strength:** act on one sighting.
**Watch for:** not just X but Y; not only X but Y; not merely X but Y; it's not X, it's Y; more than just a/an/the; this is not just about; 不是…而是; 不仅…更是; 不仅仅…而是; 不只是…更是
**Problem:** The negative half names something no one claimed, so the positive half sounds larger than the facts support. The sentence adds weight without adding a claim.
**Before:**
> It's not just about the beat riding under the vocals; it's part of the aggression and atmosphere.
**After:**
> The heavy beat adds to the aggressive tone.
**Action:** playbook move 7 — Collapse a three-item list to the two that mean something
**Detector:** `not-just-x` (regex)

### A2. One-line closers and dramatic fragments / 一句总结与碎片行

**Strength:** act on one sighting.
**Watch for:** That is the real win; That distinction matters; Read that again; Let that sink in; This shows the importance of; The message was clear; It was a lesson in; No aesthetic prior; No nostalgia; In summary,; In conclusion,; To sum up,; All in all,; All told,; In short,; Key takeaways; Bottom line; What this means is that; The key takeaway is; At the end of the day; This underscores the importance of; 这才是重点; 真正的意义在于
**Problem:** The line asks the reader to pause on a claim instead of adding to it, and a row of fragments carries emphasis the sentence itself does not. A closer that repeats the paragraph before it is scaffolding.
**Before:**
> The queue retries failed jobs, so brief outages stop reaching users. This shows the importance of retries.
**After:**
> The queue retries failed jobs, so brief outages stop reaching users.
**Action:** playbook move 1 — Delete the sentence
**Detector:** `one-line-closer`, `empty-summary` (regex)

### A3. Sayings that sound deep / 深刻金句

**Strength:** act on one sighting.
**Watch for:** the real question is; in reality; what really matters; fundamentally; the deeper issue; the heart of the matter; the language of; the currency of; the architecture of; X is the Y of Z; becomes a trap; is not a tool but a mirror; 真正的问题在于; 本质上; 说到底; 归根到底; 真正的本质; 最深层的意义; 表面上…实际上
**Problem:** An ordinary point is dressed as a hidden truth or an aphorism, and the dressing adds no detail; replace the saying with the specific claim it stands for. The scanner files "At its core" under A4 (`empty-transition`), not under this pattern.
**Before:**
> The real question is whether teams can adapt. What really matters is organizational readiness.
**After:**
> The question is whether teams can adapt. That mostly depends on whether the organization is ready to change its habits.
**Action:** playbook move 4 — Replace the abstraction with the concrete noun
**Detector:** `deep-saying` (regex)

### A4. Staged run-up before the point / 报幕式开场

**Strength:** act on one sighting.
**Watch for:** Let's dive in; let's explore; let's break this down; here's what you need to know; now let's look at; without further ado; heads up; quick note; Honestly?; Look; Here's the thing; The thing is; Let's be honest; Real talk; In this section, we will…; before we dive in; by the end of this article; Moreover,; Furthermore,; Additionally,; In addition,; That said,; On the other hand,; At its core; When it comes to; 值得注意的是; 值得一提的是; 需要注意的是; 总的来说; 综上所述; 不仅如此; 除此之外; 换言之; 众所周知; 毫无疑问; 总而言之; 一言以蔽之; 由此可见; 总之; 此外，; 与此同时，; 归根结底; 悄然改变; 下面让我们一探究竟; 话不多说，直接上干货; 接下来看重点; 在当今…时代; 在…背景下
**Problem:** The writer announces the point, or stages a moment of candour, instead of making it. The run-up describes the document or announces the topic, so the first fact arrives a sentence late.
**Before:**
> Let's dive into how caching works in Next.js. Here's what you need to know.
**After:**
> Next.js caches data at several layers, including request memoization, the data cache, and the router cache.
**Action:** playbook move 8 — Replace the connective with the logical relation
**Detector:** `meta-narration`, `empty-transition`, `zh-translated-connective`, `zh-empty-opening` (regex)

### A5. Arguing with no one / 与无人辩论

**Strength:** act on one sighting.
**Watch for:** This isn't (mainly) about; I'm not saying; To be clear; Don't get me wrong; This is not to say; Some might say… but; A tempting approach would be; One might be tempted to; An obvious approach would be; You might think… but; It would be easy to just; 我并不是说; 并不是要否定; 诚然…但是
**Problem:** The text answers an objection or rejects an option that appears nowhere else, usually a leftover from an earlier draft. The defence costs a sentence and adds no claim.
**Before:**
> I'm not saying documentation doesn't matter; the issue is whether the agent can use the instruction when it acts.
**After:**
> The issue is whether the agent can use the instruction when it acts.
**Action:** playbook move 1 — Delete the sentence
**Detector:** `arguing-with-nobody` (regex)

### A6. Rhetorical question theatre / 假问题自问自答

**Strength:** act on one sighting.
**Watch for:** So what does this really mean?; What really lies behind?; The answer is obvious; The answer is clear; Here's the real question; But why does this matter?; What does it all mean?; 那么…究竟…？; 究竟意味着什么？; 究竟该如何破局？; 答案其实很简单; 答案不言自明; 答案显而易见; 答案呼之欲出
**Problem:** The paragraph asks a question it answers in the next clause, manufacturing suspense the facts do not need; the question carries nothing the answer does not. A question the text leaves open is not this pattern.
**Before:**
> So what does this really mean? The answer is obvious: nobody owns the retry budget.
**After:**
> Nobody owns the retry budget.
**Action:** playbook move 1 — Delete the sentence
**Detector:** `rhetorical-question` (regex)

### A7. False candour, false neutrality / 假坦诚假中立

**Strength:** act on one sighting.
**Watch for:** To be honest,; Honestly,; I have to admit; I must admit; Truth be told; Let's be real; We have to be honest; 说实话; 老实说; 不得不承认的是; 不可否认; 客观来讲
**Problem:** The text declares that it is being candid or objective and then says something ordinary. The framing borrows the authority of honesty without showing any.
**Before:**
> To be honest, most of the delay comes from the ingest step, not the query.
**After:**
> Most of the delay comes from the ingest step, not the query.
**Action:** playbook move 1 — Delete the sentence
**Detector:** `false-candour` (regex)

### A8. Staged contrast and stage slogans / 模板转折与阶段口号

**Strength:** act on one sighting.
**Watch for:** 然而，事实并非如此; 不过，事情并非如此; 故事并未就此结束; 开启新篇章; 迈向新征程; 这只是一个开始; 真正的转折点才刚刚开始; but the story doesn't end here; the next chapter; embark on a new journey; begin a new chapter; here is the turning point; and that changes everything
**Problem:** The paragraph turns itself into an event: the template contrast or the stage slogan announces that something is about to happen instead of saying it. A slogan repeated across sections becomes the document's only argument.
**Before:**
> The migration finished on time. But the story doesn't end here.
**After:**
> The migration finished on time.
**Action:** playbook move 1 — Delete the sentence
**Detector:** `staged-contrast` (regex)

### A9. Fixed attention formulas / 固定关注句式

**Strength:** act on one sighting.
**Watch for:** 相比较…我更关心; 大家最容易盯着; 值得关注的是; 让我更感兴趣的是; 最值得关注的是; what interests me most is; what excites me most is; the most overlooked aspect here is; let's focus on what really matters
**Problem:** The sentence tells the reader which thing matters before saying anything about it, a formula that survives any topic because it says nothing. The attention it directs is a stage direction, not a fact.
**Before:**
> If I had to pick one thing, what interests me most is the migration window.
**After:**
> The migration window is the part worth arguing about.
**Action:** playbook move 1 — Delete the sentence
**Detector:** `attention-formula` (regex)

## When not to act

- Leave a watched phrase alone inside a quotation, a title, a proper name, or a passage that discusses the phrase rather than uses it.
- Keep the contrast in A1 when the negative half corrects a belief the reader actually holds, or when both halves carry information.
- Keep a closer in A2 when it adds a fact or a consequence the example does not show. "Honestly" or "look" inside a casual sentence is ordinary; the tell is the standalone opener before a routine claim.
- Keep an objection in A5 that the text attributes or answers in full, and keep an option a reader would actually weigh.
- Keep the candour in A7 when a controversy exists and the writer is taking a side; the tell is candour declared where nobody disputed anything.
- Keep a stage slogan in A8 when it is the writer's deliberate choice for a campaign or a keynote; note it in the change log instead of deleting it.
