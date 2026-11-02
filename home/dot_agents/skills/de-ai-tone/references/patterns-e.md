# Patterns E — Leftovers from the chat and the draft

E1 Chatbot residue · E2 Knowledge-limit disclaimers · E3 A heading repeated in the first sentence · E4 Writing about the document instead of its subject · E5 Staged persona voice

**Load this reference when:** a scan reports `chatbot-residue`, `knowledge-limit`, `heading-repeat`, `document-meta` or `staged-persona`, and you need to decide whether the flagged text is residue to delete or content the reader still needs.

These five patterns are what is left over from the conversation and the draft: a chat wrapper around a real answer, a disclaimer about the model's own knowledge limits, a sentence that repeats the heading above it, a description of the document instead of its subject, and a persona announced instead of a claim made. Nothing here needs rewriting. The fix is deletion, so act on one sighting and then check that the sentences you keep still carry the facts.

### E1. Chatbot residue / 聊天残留

**Strength:** act on one sighting — remove it, do not rewrite it.
**Watch for:** I hope this helps; Of course!; Certainly!; Great question!; You're absolutely right; Would you like...; Want me to...?; Should I continue?; let me know; here is a...; 好的，没问题！; 这是一个非常深刻且具有前瞻性的问题……; 希望以上内容对您有所帮助！如果您有任何其他疑问，欢迎随时提问。; 接下来我将从以下几个维度为您深度剖析：
**Problem:** A chatbot's greeting, praise, offer or closing is still in the text, and it is the most certain tell in this list, because the wrapper reads as service rather than as noise. It is also the easiest to miss when it wraps real content, since the content around it is worth keeping and the wrapper is not. Remove the wrapper and keep the content.
**Before:**
> Great question! Here is an overview of the French Revolution. It began in 1789 when a financial crisis and food shortages led to widespread unrest. I hope this helps! Let me know if you'd like me to expand on any section.
**After:**
> The French Revolution began in 1789 when a financial crisis and food shortages led to widespread unrest.
**Before (a Chinese reply):**
> 好的，没问题！接下来我将从以下几个维度为您深度剖析：背景是请求量在半年内从 300 万涨到 1200 万；当前做法是每次查询都全表扫描；可以改成按天预聚合，代价是数据延迟一天。希望以上内容对您有所帮助！如果您有任何其他疑问，欢迎随时提问。
**After:**
> 请求量在半年内从 300 万涨到 1200 万。现在每次查询都全表扫描，可以改成按天预聚合，代价是数据延迟一天。
**Before (a chat answer):**
> Of course! Here is a summary of the incident. The 14:02 deploy pushed a build with a stale migration, the schema check failed, and the queue backed up until the rollback finished at 14:19. Would you like me to break down the timeline in more detail?
**After:**
> The 14:02 deploy pushed a build with a stale migration. The schema check failed, and the queue backed up until the rollback finished at 14:19.
**Action:** playbook move 1 — Delete the sentence
**Detector:** `chatbot-residue` (regex)

Delete the greeting, the praise, the offer and the closing. Keep the middle: the answer, the figures, the example. "Here is an overview of" is not the same as the overview, and "Let me know if you'd like more" is not a fact about the subject. When the wrapper is the only sentence in a paragraph, the paragraph goes with it.

### E2. Knowledge-limit disclaimers / 知识截止与免责套话

**Strength:** act on one sighting — remove it, do not rewrite it.
**Watch for:** as of [date]; up to my last training update; while specific details are limited; based on available information; not publicly available; not widely documented or disclosed; in the provided or available sources; maintains a low profile; keeps personal details private; likely [grew up, studied, began]; it is believed that; 截至我的知识库更新时间; 由于公开信息有限，推测可能……
**Problem:** The text either marks the edge of the model's knowledge, or admits that no source was found and then fills the gap with a plausible guess. The guess is the worse of the two, because it turns an absence of evidence into an assertion the reader will treat as fact; state what the source does not show, or remove the sentence. The scanner matches the literal phrases; the wider ones, such as "as of [date]" and "keeps personal details private", need reading.
**Before (the cutoff disclaimer):**
> While specific details about the company's founding are not extensively documented in readily available sources, it appears to have been established sometime in the 1990s.
**After:**
> The company's founding date is not documented in the available sources.
**Before (the plausible guess):**
> Information about her early life is not publicly available, suggesting she maintains a low profile. She likely grew up in a middle-class household, which shaped her later interest in education reform.
**After:**
> Her early life is not documented in the available sources.
**Before (a Chinese disclaimer):**
> 截至我的知识库更新时间，该产品的定价策略没有公开说明。由于公开信息有限，推测可能是在 2023 年第二季度改成了按席位计费。
**After:**
> 公开资料未说明该产品何时改为按席位计费。
**Action:** playbook move 1 — Delete the sentence
**Detector:** `knowledge-limit` (regex)

A disclaimer about the model's own limits is not information for the reader, so it goes. A guess dressed as a finding goes with it, and "it is believed that" is a tell in itself: it names no one. If the gap matters to the reader, name it in one clause — "the founding date is not documented" — and let the reader decide what to do about it. If the gap does not matter, cut the sentence and check that nothing downstream depended on it.

### E3. A heading repeated in the first sentence / 标题复读

**Strength:** act on one sighting — remove it, do not rewrite it.
**Watch for:** a one-line paragraph under a heading that only restates it; `Speed matters.`; `Performance matters.`; `Reliability is key.`; `速度很重要。`; `质量是关键。`; the next non-empty line after a heading, when it repeats the heading's words
**Problem:** A heading is followed by a one-line paragraph that says the heading again, so the reader meets the same claim twice before anything new arrives. The scanner reads a heading and the next non-empty line, and flags that line when it only restates the heading, either by repeating the heading's content words or by being a bare restatement such as "Speed matters." The fix is to delete the repeated sentence, not to rewrite the heading.
**Before:**
> ## Performance
>
> Speed matters.
>
> When users hit a slow page, they leave.
**After:**
> ## Performance
>
> When users hit a slow page, they leave.
**Before (a heading restated in words):**
> ## Reliability
>
> Reliability is key for this service.
>
> The queue retries failed jobs three times before parking them.
**After:**
> ## Reliability
>
> The queue retries failed jobs three times before parking them.
**Before (a Chinese heading):**
> ## 性能
>
> 性能很重要。
>
> 页面超过 2 秒时，用户就会离开。
**After:**
> ## 性能
>
> 页面超过 2 秒时，用户就会离开。
**Action:** playbook move 1 — Delete the sentence
**Detector:** `heading-repeat` (regex)

Delete the line under the heading, not the heading. A heading that says "Reliability" is a promise about the section, and the sentence that repeats it adds no evidence, no number and no condition. If the first line under the heading carries a fact the heading does not — a measurement, a condition, a name — it is content, and it stays.

### E4. Writing about the document instead of its subject / 写作元叙述

**Strength:** act on one sighting — remove it, do not rewrite it.
**Watch for:** what the text replaced (`was added to replace`); how it was assembled or sourced (`generated from`, `compiled from`, `anything unconfirmed is flagged rather than guessed`); a legend, layout or order the reader can already see (`the table below compares`, `this section is organized by owner`); 本文将介绍; 这篇文章想回答; 本节将讨论; 如下所示; 详见下表
**Problem:** The text describes itself instead of its subject: what it replaced, how it was assembled, or how it is laid out, none of which the reader asked for. Mention a previous version only in change logs, release notes and migration guides; keep a source credit the reader can follow; cut the account of how you worked, and keep a caveat that changes what the reader should do. The scanner matches the literal phrases; a description of how the document was assembled needs reading.
**Before:**
> This function was added to replace the previous approach of iterating through all items, which caused O(n²) performance.
**After:**
> This function uses a hash map for O(1) lookups, avoiding the O(n²) cost of naive iteration.
**Before (a note about the method):**
> The figures below are drawn from each vendor's published pricing; anything we could not confirm is flagged rather than guessed.
**After:**
> Prices are each vendor's published rate. Two vendors publish nothing; call them.
**Before (a Chinese layout note):**
> 本节将讨论令牌类型，详见下表。下表列出了三种令牌类型及其有效期。
**After:**
> 令牌分三种类型，有效期各不相同。
**Action:** playbook move 1 — Delete the sentence
**Detector:** `document-meta` (regex)

The reader can see the table, so a sentence announcing the table is a caption for something that does not need one. The same goes for "this section is organized by owner" and for a note about how the document was compiled. Two exceptions carry their weight: a source credit the reader can follow, and a caveat that changes what the reader should do. A change log is the one document whose subject really is the previous version.

### E5. Staged persona voice / 刻意拟人口吻

**Strength:** act on one sighting — remove it, do not rewrite it.
**Watch for:** my honest take; my real answer; my real opinion; here's the honest truth; here's the truth; without the sugar coating; without bullshit; 我的判断很直接; 说点扎心的; 说点实在的; 不吐不快; 扎心的真相; 扎心的一句话
**Problem:** The persona framing replaces an actual claim. Instead of stating the judgement, the text announces how blunt it is about to be, and the announcement does the work the claim should do, so the reader gets a performance and no finding. State the judgement instead of performing it; the bluntness survives, the stage direction does not.
**Before:**
> My honest take? Most "AI detection" tools are measuring token distribution, not authorship. Here's the honest truth: without the sugar coating, a good editor still catches a padded paragraph faster than any classifier.
**After:**
> Most AI-detection tools measure token distribution, not authorship. A good editor still catches a padded paragraph faster than any classifier.
**Before (a Chinese persona):**
> 我的判断很直接：多数「AI 检测」工具测的是词元分布，不是作者身份。说点扎心的，一个好编辑判断一段话是不是注水，比任何分类器都快。
**After:**
> 多数「AI 检测」工具测的是词元分布，不是作者身份。一个好编辑判断一段话是不是注水，比任何分类器都快。
**Action:** playbook move 1 — Delete the sentence
**Detector:** `staged-persona` (regex)

Delete the framing clause and keep the sentence it introduced. "My honest take" is not humility, and "without the sugar coating" is not candour: both promise a quality the reader then has to check for themselves. If the writer's own voice is blunt, the claims carry it once the announcement is gone.

## When not to act

- Leave a watched phrase alone inside a quotation, a title, a proper name, or a passage that discusses the phrase rather than uses it.
- Salutations and sign-offs on a letter or comment predate chatbots. "Hi Anna" and "Thanks" in an email are not residue.
- Mention a previous version only in change logs, release notes and migration guides. In those documents, "was added to replace" is the subject.
- Keep a source credit the reader can follow, and keep a caveat that changes what the reader should do. Both are content, and so is a list the reader needs: only the sentence announcing the list goes.
- A deliberate persona is a writer's choice in a personal essay. The pattern is the framing phrase, not the bluntness itself.
- Text written before November 30, 2022 is not AI-written.
