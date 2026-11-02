<!--
产物语言由项目 openspec/config.yaml 决定(默认简体中文);
本模板的说明是中英双语的,两种语言的约束完全一致。
The artifact language follows the project's openspec/config.yaml (Simplified Chinese by default);
this template's guidance is bilingual and both versions carry the same constraints.
-->

## Why

<!--
说明本次变更的动机:要解决什么问题?为什么现在做?

硬限制:50 ≤ 字元數 ≤ 1000(OpenSpec zod schema 会 validate)
- 太短:会收到 `Why section must be at least 50 characters` error
- 太长:会收到 `Why section should not exceed 1000 characters` error

建议结构:现状痛点 → 为什么现在处理 → 预期收益(各 1-2 句)
-->

<!--
Explain the motivation for this change: what problem does it solve? Why now?

Hard limit: 50 ≤ 字元數 ≤ 1000(the OpenSpec zod schema validates this)
- Too short: you get the `Why section must be at least 50 characters` error
- Too long: you get the `Why section should not exceed 1000 characters` error

Suggested structure: current pain points → why handle it now → expected benefit(1-2 sentences each)
-->

## What Changes

<!--
描述将要发生的变化。具体说明新增能力、修改或移除的内容。

对于有明确前后对比的行为变更,使用 From/To 格式(markdown 没有 inline diff):

**<Section or Behavior Name>**
- From: <当前状态 / 既有需求>
- To: <目标状态 / 新需求>
- Reason: <为什么需要这个变更>
- Impact: <是否破坏性变更 / 影响谁>

多个变更可重复此 block;纯新增或纯删除可用简单列表描述。
-->

<!--
Describe the changes that will happen. Specify what is added, modified, or removed.

For behavior changes with a clear before/after, use the From/To format (markdown has no inline diff):

**<Section or Behavior Name>**
- From: <current state / existing requirement>
- To: <target state / new requirement>
- Reason: <why this change is needed>
- Impact: <whether it is a breaking change / who it affects>

Repeat this block for multiple changes; pure additions or pure removals can be described with a simple list.
-->

## Capabilities

### New Capabilities
<!--
本次引入的能力。把 <name> 换成 kebab-case 标识符。
命名规则见 openspec/specs/README.md:使用复合名词(至少 2 个 word),
例如 `user-auth`、`data-export`、`api-rate-limiting`,不用纯单词。
每个能力会生成 specs/<name>/spec.md
-->

<!--
The capabilities introduced by this change. Replace <name> with a kebab-case identifier.
Naming rules are in openspec/specs/README.md: use a compound noun (at least 2 words),
for example `user-auth`, `data-export`, `api-rate-limiting`, not a single word.
Each capability generates specs/<name>/spec.md
-->
- `<name>`: <这个能力覆盖什么,一句话>

### Modified Capabilities
<!--
既有能力中 REQUIREMENTS 发生变化的部分(不只是实现变化)。
只有 spec 级行为变化才列在这里。每个都要有对应的 delta spec 文件。
用 openspec/specs/ 里的既有 spec 名。没有需求变化就留空。
-->

<!--
The parts of existing capabilities whose REQUIREMENTS change (not just implementation changes).
Only spec-level behavior changes are listed here. Each one needs a matching delta spec file.
Use the existing spec names from openspec/specs/. Leave empty if no requirements change.
-->
- `<existing-name>`: <哪个需求在变化>

## Impact

<!-- 受影响的代码、API、依赖、系统 -->
