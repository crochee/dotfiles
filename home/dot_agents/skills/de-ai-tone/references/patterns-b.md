# Patterns B — Rhythm by rule

B1 Forced triads · B2 Repeated sentence openings · B3 Dashes as the universal connector · B4 Stacked qualifiers · B5 Hyphenated pairs everywhere · B6 Passive voice and missing subjects · B7 Preposition-led sentence openings · B8 Chained 的 and over-long modifiers · B9 Over-nominalisation · B10 Rhythm-even sentences · B11 Stacked colloquial questions · B12 Over-balanced pairs · B13 Dense feature triads · B14 Fake spans

**Load this reference when:** the prose reads evenly but unnaturally, because the shapes were applied by rule instead of by meaning; every pattern in this group is weak on its own.

Group B collects the mechanical habits: triads, repeated openings, dashes, stacked hedges, hyphenated compounds, passive voice, prepositional sentence starts, chained modifiers, nominalisations. None of them proves anything by itself, so act on a cluster rather than on a single sighting.

### B1. Forced triads / 三件套与排比

**Strength:** *weak alone* — needs company.
**Watch for:** innovation, inspiration, and insights; powerful, seamless, and robust; three parallel examples; three short facts followed by a lesson; 可靠、安全、灵活; 既要…又要…还要; 不仅…而且…更是
**Problem:** Ideas arrive in threes to sound complete, whether the meaning has three parts or not. Check that each item adds a distinct idea; merge examples, develop the strongest one, or vary the structure when they do not. The detector catches lexical triples such as powerful, seamless, and robust; a semantic triad it cannot see still needs reading.
**Before:**
> The event features keynote sessions, panel discussions, and networking opportunities. Attendees can expect innovation, inspiration, and industry insights.
**After:**
> The event includes talks and panels. There's also time for informal networking between sessions.
**Action:** playbook move 7 — Collapse a three-item list to the two that mean something
**Detector:** `triadic-padding`, `zh-parallelism` (regex)

### B2. Repeated sentence openings / 重复句首

**Strength:** *weak alone* — needs company.
**Watch for:** the same first word on three or more consecutive sentences in one paragraph (English: the first word; Chinese: the first four characters); 该产品 / 此工具 / 该平台 / 该软件; five consecutive sentences opening with 他
**Problem:** Repetition is handled by rule instead of by ear, so the paragraph turns into a treadmill. The scanner rebuilds each paragraph and flags the paragraph's first line when three or more consecutive sentences open with the same word, unless the three sentences are identical; merge the sentences, change the subject, or begin with the action. Do not ban the word — a remaining sentence may still start with "She."
**Before:**
> She noted the door. She noted the lock on it. She filed both away.
**After:**
> She noted the door and its lock, then filed both away.
**Action:** playbook move 3 — Split the long sentence
**Detector:** `repeated-openings` (metric)

### B3. Dashes as the universal connector / 破折号泛滥

**Strength:** *weak alone* — needs company.
**Watch for:** —; –; ` -- ` used as a dash; 中文里的「——」
**Problem:** A dash lets the writer skip choosing how two clauses relate, so the model reaches for it everywhere. Hard rule: the final rewrite must not contain em dashes or en dashes unless the writer's own sample uses them; then match the sample's rate. Replace each dash with a period, comma, colon, or parentheses, or rewrite the sentence, and leave dashes inside code blocks, inline code, commands, paths, and URLs alone. The scanner flags a line that carries three or more em dashes.
**Before:**
> The new policy — announced without warning — affects thousands of workers. The changes -- long overdue according to critics -- will take effect immediately.
**After:**
> The new policy, announced without warning, affects thousands of workers. The changes, long overdue according to critics, will take effect immediately.
**Action:** playbook move 3 — Split the long sentence
**Detector:** `emdash-chain` (regex)

### B4. Stacked qualifiers / 叠词限定

**Strength:** *weak alone* — needs company.
**Watch for:** to be fair; it's also possible; could potentially; might arguably; in some cases it may; this is an inference; 可能也许; 在一定程度上; 通常来说
**Problem:** Repeated editing adds one qualifier after another until every claim sounds uncertain, usually to repair an earlier overstatement rather than to report real doubt. Keep one qualifier, and only where the source supports it.
**Before:**
> It could potentially possibly be argued that the policy might have some effect on outcomes.
**After:**
> The policy may affect outcomes.
**Action:** playbook move 2 — Cut the hedge to the one real uncertainty
**Detector:** `hedge-stacking`, `zh-hedge-stacking` (regex)

### B5. Hyphenated pairs everywhere / 连字符复合修饰

**Strength:** *weak alone* — needs company.
**Watch for:** high-quality; well-known; well-documented; long-term; real-time; client-facing after the noun they describe; 高质量的; 长期的
**Problem:** Compound modifiers keep their hyphen in every position. Keep the hyphen before a noun, as in `a high-quality report`, and drop it after the noun, as in `the report is high quality`; words the dictionary always spells with a hyphen, such as third-party and cross-functional, keep it everywhere.
**Before:**
> The report is high-quality, the process is well-documented, and the plan is long-term.
**After:**
> The report is high quality, the process is well documented, and the plan is long term.
**Action:** playbook move 3 — Split the long sentence
**Detector:** `hyphen-pairs` (regex)

### B6. Passive voice and missing subjects / 被动语态与无主句

**Strength:** *weak alone* — needs company.
**Watch for:** is preserved automatically; No configuration file needed; 被广泛认为; 被成功实现; 被作为…使用
**Problem:** The text hides who acts or drops the subject. Use active voice when naming the actor makes the sentence clearer; passive voice stays when the actor is unknown or irrelevant, as in "the table is truncated nightly".
**Before:**
> No configuration file needed. The results are preserved automatically.
**After:**
> You do not need a configuration file. The system preserves the results automatically.
**Action:** playbook move 5 — Convert passive to the actor
**Detector:** `passive-voice` (regex)

### B7. Preposition-led sentence openings / 句首介词短语泛滥

**Strength:** *weak alone* — needs company.
**Watch for:** With the rise of; Through the introduction of; In the context of; 随着…的不断推进; 对于…来说; 通过…的引入; 在…下
**Problem:** Every paragraph opens with a prepositional phrase, so the paragraphs share one rhythm and the reader gets no information until the third clause. Put the subject first and let the preposition follow the verb. The scanner matches the Chinese openings (随着…, 对于…, 通过…, 在…下); the English forms are the same habit and need reading.
**Before:**
> With the rise of microservices, service governance has become critical for backend teams. Through the introduction of tracing tools, the team achieved fast location of anomalous requests.
**After:**
> Microservices made service governance a backend problem. Tracing tools locate anomalous requests quickly.
**Action:** playbook move 3 — Split the long sentence
**Detector:** `preposition-opening` (regex)

### B8. Chained 的 and over-long modifiers / 连环定语

**Strength:** *weak alone* — needs company.
**Watch for:** 关于通过优化…来实现…的非常实用的解决方案; three or more 的 in one clause; a noun phrase with three stacked pre-modifiers
**Problem:** The modifiers stack until the head noun is out of sight, and the reader has to hold the whole phrase before learning what is being described. Cut the pre-modifiers that repeat, and let the sentence say who does what. The scanner counts three or more 的 in one Chinese clause; two 的, like the example below, is the same habit and needs reading. The English shape is a noun phrase with three stacked modifiers and needs reading.
**Before:**
> This is a very practical solution for significantly improving overall system response performance by optimizing the underlying core database query logic.
**After:**
> This solution improves response time by optimizing the database query logic.
**Action:** playbook move 3 — Split the long sentence
**Detector:** `chained-de` (regex)

### B9. Over-nominalisation / 过度名词化与动词虚化

**Strength:** *weak alone* — needs company.
**Watch for:** perform the optimization; achieve an improvement; conduct a discussion; 进行优化; 实现提升; 具有极高的可行性; 展开深入探讨
**Problem:** The action is packed into a noun and the verb disappears, so the sentence describes the operation instead of performing it. Use the verb. The scanner matches the Chinese forms (进行优化、实现提升); the English version is the same habit in other words.
**Before:**
> The team performed a refactoring operation on the legacy interfaces, achieving an enhancement of system stability.
**After:**
> The team refactored the legacy interfaces, and the system became more stable.
**Action:** playbook move 4 — Replace the abstraction with the concrete noun
**Detector:** `nominalisation` (regex)

### B10. Rhythm-even sentences / 句长齐一

**Strength:** *weak alone* — needs company.
**Watch for:** every sentence in a paragraph landing within a few words of the same length; 段内每句字数接近
**Problem:** The scanner deliberately does not automate this one, because sentence length is a judgment call: read the paragraph aloud and compare the sentences instead of trusting a count. The tell is the spread, not the average — a paragraph where every sentence lands within a few words of the same length has been levelled by rule, and the reader feels it as flatness.
**Before:**
> The service starts in under a second. It handles ten thousand requests per second. It recovers from failures automatically. It reports its own health.
**After:**
> The service starts in under a second and handles ten thousand requests per second. Failures recover automatically, and the service reports its own health.
**Action:** playbook move 3 — Split the long sentence
**Detector:** No detector — judge by reading.

### B11. Stacked colloquial questions / 人工感叠词

**Strength:** *weak alone* — needs company.
**Watch for:** 稳不稳…能不能; 会不会…好不好; 行不行…对不对; 有没有…是不是
**Problem:** Two colloquial questions crowd into one sentence to fake a chat tone. The second question carries no new information, so keep one question and let the sentence state the concern.
**Before:**
> 这个方案稳不稳，能不能真的撑住线上流量？
**After:**
> 这个方案能撑住线上流量吗？
**Action:** playbook move 7 — Collapse a three-item list to the two that mean something
**Detector:** `colloquial-stack` (regex)

### B12. Over-balanced pairs / 过度平衡

**Strength:** *weak alone* — needs company.
**Watch for:** 一方面…另一方面; 从正面来看…从反面来看; on the one hand…on the other hand
**Problem:** A pair of balanced clauses reads as fair-minded, but the balance is decorative when the two sides are not opposites. State the real relation instead of the frame.
**Before:**
> 一方面，这个方案部署简单；另一方面，它的迁移成本比原方案高。
**After:**
> 这个方案部署简单，但迁移成本比原方案高。
**Action:** playbook move 7 — Collapse a three-item list to the two that mean something
**Detector:** `over-balanced` (regex)

### B13. Dense feature triads / 密集排比

**Strength:** *weak alone* — needs company.
**Watch for:** 可接入…可上线…可控成本; 可观测…可治理…可扩展; three 可X capabilities in one sentence
**Problem:** A sentence that stacks three or four capabilities under the same opening reads as a feature list compressed into prose. Say what each one does, and split the list when the items need their own space. The scanner matches the Chinese 可X chain; the English version of the same shape needs reading.
**Before:**
> The platform can integrate multi-cloud resources, can ship canary releases, and can observe runtime status.
**After:**
> The platform connects to multiple clouds, ships canary releases, and shows runtime status.
**Action:** playbook move 4 — Replace the abstraction with the concrete noun
**Detector:** `feature-triad` (regex)

### B14. Fake spans / 虚假跨度

**Strength:** *weak alone* — needs company.
**Watch for:** 从A到B再到C; 从X走向Y; 已经进入…阶段; from A to B to C; from X to Y
**Problem:** The span syntax strings separate stages into one rising line, which reads as progress even when the stages are a plain list. List the stages instead, and keep any real chronology the source states.
**Before:**
> The platform has gone from single-node deployment to container orchestration and now to a service mesh.
**After:**
> The platform supports single-node deployment, container orchestration, and a service mesh.
**Action:** playbook move 7 — Collapse a three-item list to the two that mean something
**Detector:** `fake-span` (regex)

## When not to act

- Every pattern in this group is weak alone. Act when several of them cluster in the same passage, not on a single sighting.
- Leave a watched phrase alone inside a quotation, a title, a proper name, or a passage that discusses the phrase rather than uses it.
- Repeated openings and deliberate parallel structures are a writer's choice: "She came. She saw. She conquered." Keep the repetition when the author meant it.
- Dashes and hyphens inside code blocks, inline code, commands, paths, and URLs are data, not prose. Passive voice stays when the actor is unknown or irrelevant, and a hedge stays when the uncertainty is real.
- A triad that carries three distinct facts is not padding. Compound modifiers the dictionary spells with a hyphen, such as third-party and cross-functional, keep it everywhere.
