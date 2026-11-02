# Patterns D — Formatting by rule

D1 Bold as decoration · D2 Labelled-list template · D3 Decorative headings and emoji · D4 Curly quotation marks · D5 Mixed punctuation and CJK spacing

**Load this reference when:** a scan reports `over-bold`, `labelled-list`, `decorative-heading`, `emoji-bullet`, `curly-quotes` or `punctuation-spacing`, and you have to decide whether the markup is structure or decoration.

Group D covers the marks a template or a visual editor leaves behind, not the marks a writer chooses. Every pattern in the group is weak on its own, because clean formatting is what most editors produce by default. Judge them against the prose patterns in the other groups: markup that decorates a thin sentence is part of the same problem, while markup on a document that carries real facts may be structure the reader needs.

### D1. Bold as decoration / 装饰性加粗

**Strength:** *weak alone* — needs company.

**Watch for:** three or more bold spans on one line; `**OKRs (Objectives and Key Results)**`; `**KPIs (Key Performance Indicators)**`; `**Business Model Canvas (BMC)**`; `**Balanced Scorecard (BSC)**`; 一句话里连着加粗 3–4 个专有名词或黑话

**Problem:** Bold is used as a shout instead of as a label for something the reader will meet again, so the emphasis carries nothing the sentence does not already carry. The scanner fires when one line holds three or more bold spans, which is the shape a generated paragraph takes when every term is emphasised.

**Before:**
> It blends **OKRs (Objectives and Key Results)**, **KPIs (Key Performance Indicators)**, and visual strategy tools such as the **Business Model Canvas (BMC)** and **Balanced Scorecard (BSC)**.

**After:**
> It blends OKRs, KPIs, and visual strategy tools like the Business Model Canvas and Balanced Scorecard.

**Action:** playbook move 1 — Delete the sentence

**Detector:** `over-bold` (regex)

Keep bold for a term that is defined here and used later in the document, for a warning the reader must not miss, and for a number the reader has to recall. Everything else can lose its markers without losing the claim, because the words carry the meaning and the asterisks only carry the volume. One bold span per line is the practical bar.

### D2. Labelled-list template / 加粗小标题清单体

**Strength:** *weak alone* — needs company.

**Watch for:** `- **Label:** text`; `- **Label：** text`; `- **User Experience:**`; `- **Performance:**`; `- **Security:**`; `- **技术优势：**`; `- **成本考量：**`; `- **用户体验：**`

**Problem:** Every item opens with a bold label and a colon, which turns a narrative into a slide outline, and the labels often repeat the first word of the item they introduce. The scanner matches a list item that starts with a bold label followed by a colon, with the colon inside the bold or directly after it.

**Before:**
> - **技术优势：** 采用了先进的架构设计。
> - **成本考量：** 大幅降低了部署门槛。
> - **用户体验：** 提供了丝滑的操作流程。

**After:**
> 架构设计更先进，部署门槛大幅降低，操作流程也更顺畅。

**Action:** playbook move 3 — Split the long sentence

**Detector:** `labelled-list` (regex)

Turn the list back into prose when the labels carry no information of their own and the items are short enough to read as sentences. The English shape of the same template is `- **User Experience:** The user experience has been significantly improved with a new interface.`, which becomes a clause. Keep the list when it is the clearest form for the content: API parameters, action items, a checklist, a comparison whose columns really differ. A pull-request or issue template's bold labels are structure, not emphasis, and must not be rewritten.

### D3. Decorative headings and emoji / 装饰性标题与 emoji

**Strength:** *weak alone* — needs company.

**Watch for:** `## Strategic Negotiations And Global Partnerships`; `→`; `🚀`; `💡`; `🔥`; `📌`; `✨`; `🎯`; `👉`; `- 🚀 **Launch Phase:**`; 标题里每个实词都大写；列表项以 emoji 开头

**Problem:** Title-case headings and emoji bullets decorate the page instead of naming what is in it, and the decoration is identical on every item, which is what a template produces. The scanner has two rules here: `decorative-heading` catches a heading whose main words are all capitalised and an arrow used as decoration, `emoji-bullet` catches a list item whose first character is an emoji.

**Before:**
> ## Strategic Negotiations And Global Partnerships
>
> 🚀 **Launch Phase:** The product launches in Q3
> 💡 **Key Insight:** Users prefer simplicity

**After:**
> ## Strategic negotiations and global partnerships
>
> The product launches in Q3. User research showed a preference for simplicity.

**Action:** playbook move 1 — Delete the sentence

**Detector:** `decorative-heading` (regex), `emoji-bullet` (regex)

Use sentence case for headings and let the title stand once. Remove the emoji unless the author asked for them or the document is a social post whose house style is emoji. A heading written for effect ("The decision, on one screen") should name what the section holds ("How the six options compare"), and a horizontal rule between every section is decoration too.

### D4. Curly quotation marks / 弯引号

**Strength:** *weak alone* — needs company.

**Watch for:** `“`; `”`; `‘`; `’`; `“the project is on track”`; `“设计”`; `‘quote’`

**Problem:** Curly quotes appear where the writer or the target format uses straight quotes, so the text will not match the file or template it is pasted into. The scanner matches the four curly characters wherever they appear, which is why this pattern is weak on its own: most editors auto-curl, so a human-written file is full of them too.

**Before:**
> He said “the project is on track” but others disagreed.

**After:**
> He said "the project is on track" but others disagreed.

**Action:** playbook move 3 — Split the long sentence

**Detector:** `curly-quotes` (regex)

Check the target format before changing anything: Markdown source, a JSON field, a plain-text log and a code comment each have their own convention, and text pasted into an issue tracker may need straight quotes. Leave quotes inside a quotation, a title or a proper name alone. Chinese text keeps its own full-width quotes, `“”` and `‘’`.

### D5. Mixed punctuation and CJK spacing / 标点与中英混排规范

**Strength:** *weak alone* — needs company.

**Watch for:** `你好 , 我是 .`; `优化了3个SQL查询`; 中文旁边的半角 `,`; 中文旁边的半角 `.`; `，`; `。`; `！`; `？`; `；`; `：`; `「」`; `《》`; `优化了 3 个 SQL 查询`

**Problem:** Half-width punctuation next to Chinese characters, and Latin words welded to Chinese ones, are the seam left by typing an English template and swapping the words inside it. The scanner flags half-width punctuation adjacent to a Chinese character and a missing space between a Chinese character and a Latin letter or digit.

**Before:**
> 你好 , 我是 . 这个工具优化了3个SQL查询。

**After:**
> 你好，我是。这个工具优化了 3 个 SQL 查询。

**Action:** playbook move 3 — Split the long sentence

**Detector:** `punctuation-spacing` (regex)

Use full-width punctuation in Chinese prose — `，。！？；：「」《》` — and keep one space between Chinese and a Latin word or number. Code, URLs, identifiers and quoted text keep whatever they have; the rule applies to the prose around them, not to the strings inside it.

## When not to act

- A pull-request or issue template's bold labels are structure, not emphasis. Leave them alone.
- Curly quotes are what most editors produce, so a document full of them may be entirely human-written. Check the target format first.
- A list is the clearest form for API parameters, action items and checklists. Converting it to prose costs the reader their scannability.
- Code, URLs, identifiers and quoted text keep their own punctuation and spacing.
- Emoji and title case are decoration only when the author did not ask for them. A social post or a documentation set with its own house style keeps them.
- Text written before November 30, 2022 is not AI-written. Decoration alone is not evidence.
