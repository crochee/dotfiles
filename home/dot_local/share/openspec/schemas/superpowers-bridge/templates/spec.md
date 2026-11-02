<!--
产物语言由项目 openspec/config.yaml 决定(默认简体中文);
本模板的说明是中英双语的,两种语言的约束完全一致。
The artifact language follows the project's openspec/config.yaml (Simplified Chinese by default);
this template's guidance is bilingual and both versions carry the same constraints.
-->

<!--
change 用的 delta spec 模板。

本模板示範 4 种 delta section,按实际需要取用:
- ADDED / MODIFIED / REMOVED / RENAMED
文件与位置:openspec/changes/<change-name>/specs/<capability>/spec.md
(`<capability>` 对齐 openspec/specs/<capability>/ 目錄名)

格式硬规则(OpenSpec 会 validate):
- Requirement 句子 MUST 含 `SHALL` 或 `MUST`
- 每个 Requirement MUST 至少有一个 `#### Scenario:`
- Scenario MUST 用 level-4 (`####`),level-3 或 bullet 会 silent fail

注意:本文件是 delta 形态,只写 delta 段。
归档后落到 openspec/specs/<capability>/spec.md 的主 spec 用 `## Purpose` 与
`## Requirements` 两个章节标题 —— 那是主 spec 的格式,不要在本模板里写。
-->

<!--
Delta spec template for a change.

This template demonstrates 4 delta sections; use only the ones you actually need:
- ADDED / MODIFIED / REMOVED / RENAMED
File and location: openspec/changes/<change-name>/specs/<capability>/spec.md
(`<capability>` aligns with the directory name under openspec/specs/<capability>/)

Format hard rules (OpenSpec will validate them):
- A Requirement sentence MUST contain `SHALL` or `MUST`
- Every Requirement MUST have at least one `#### Scenario:`
- A Scenario MUST use level-4 (`####`); level-3 or a bullet will silently fail

Note: this file is in delta form — write only the delta sections.
After archiving, the main spec at openspec/specs/<capability>/spec.md uses the two
section headings `## Purpose` and `## Requirements` — that is the main spec format,
do not write it in this template.
-->

## ADDED Requirements

<!-- 新增行为。列出本 change 要加到 capability 的新 Requirement。 -->
<!-- New behavior. List the new Requirements this change adds to the capability. -->

### Requirement: <!-- requirement name -->
<!-- requirement text — 须含 SHALL 或 MUST -->

#### Scenario: <!-- scenario name -->
- **WHEN** <!-- 条件 -->
- **THEN** <!-- 预期结果 -->

---

## MODIFIED Requirements

<!--
修改既有 Requirement。**MUST 使用与 openspec/specs/<capability>/spec.md
完全相同的 normalized header**(trim 后 case-sensitive 比对),否则 archive
时的 delta apply 会因找不到对应 requirement 而失败。

**MUST 贴出修改后的完整内容**(不是只写 diff),因为 OpenSpec archive
是用全文替换的方式 apply MODIFIED。
-->

<!--
Modify an existing Requirement. **MUST use exactly the same normalized header as
openspec/specs/<capability>/spec.md** (compared case-sensitively after trimming),
otherwise the delta apply during archive fails because it cannot find the
corresponding requirement.

**MUST paste the full modified content** (not just a diff), because OpenSpec archive
applies MODIFIED by replacing the whole text.
-->

### Requirement: <!-- 与既有 spec 中相同的 header -->
<!-- 修改后的完整 requirement text — 含 SHALL 或 MUST -->

#### Scenario: <!-- scenario name(可新增、可修改) -->
- **WHEN** <!-- 条件 -->
- **THEN** <!-- 预期结果 -->

---

## REMOVED Requirements

<!--
删除既有 Requirement。MUST 包含 Reason 与 Migration 说明,让 reviewer
理解为何废除以及既有引用方该怎么迁移。
-->

<!--
Remove an existing Requirement. MUST include a Reason and a Migration note so the
reviewer understands why it is being dropped and how existing callers should migrate.
-->

### Requirement: <!-- 要删除的 header,与既有 spec 完全相同 -->

**Reason**: <!-- 为何废除 -->

**Migration**: <!-- 既有调用方 / 依赖方应如何调整 -->

---

## RENAMED Requirements

<!--
重新命名 Requirement header。格式固定:FROM / TO 用 code-fence header。
若名称变更 + 内容变更,**同时**在 RENAMED 列出名字变更,并在 MODIFIED
用**新的** header 再写一份完整内容。

archive 时 apply 顺序:RENAMED → REMOVED → MODIFIED → ADDED
-->

<!--
Rename a Requirement header. The format is fixed: FROM / TO use code-fence headers.
If the name changes together with the content, **also** list the name change under
RENAMED, and write a full copy of the content under MODIFIED using the **new** header.

Apply order during archive: RENAMED → REMOVED → MODIFIED → ADDED
-->

- FROM: `### Requirement: <Old Name>`
- TO: `### Requirement: <New Name>`
