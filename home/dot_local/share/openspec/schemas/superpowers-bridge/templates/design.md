<!--
产物语言由项目 openspec/config.yaml 决定(默认简体中文);
本模板的说明是中英双语的,两种语言的约束完全一致。
The artifact language follows the project's openspec/config.yaml (Simplified Chinese by default);
this template's guidance is bilingual and both versions carry the same constraints.
-->

## 背景

<!--
背景、现状、约束、利益相关方。
brainstorm.md 记录了探索过程(替代方案 + 选定方向);
本文件承接选定方向,展开完整技术设计。
-->

<!--
Background, current state, constraints, and stakeholders.
brainstorm.md records the exploration process (alternatives + the chosen direction);
this file picks up the chosen direction and expands it into a full technical design.
-->

## 目标 / 非目标

**目标:**
<!-- 本设计要达成什么 -->

**非目标:**
<!-- 明确排除在范围外的内容 -->

## 决策

<!--
所有技术决策的唯一来源(single source of truth)。
brainstorm.md 的 Agreed Approach 记录了"选了哪条路",
本节记录"那条路上的每个岔口怎么选的"。

每个决策建议结构:
### D1:<决策标题>
- **选择**:<采用的做法>
- **理由**:<为什么这样选>
- **已考虑的替代方案**:<被否方案 + 否决原因>
-->

<!--
The single source of truth for all technical decisions.
brainstorm.md's Agreed Approach records "which path was taken";
this section records "how each fork along that path was decided".

Suggested structure for each decision:
### D1:<decision title>
- **Choice**:<the adopted approach>
- **Rationale**:<why it was chosen>
- **Alternatives considered**:<rejected options + reason for rejection>
-->

## 风险 / 取舍

<!--
已知风险与取舍。
格式:[Risk] <描述> → Mitigation: <缓解措施>
[Trade-off] <取舍描述> → 接受理由
-->

<!--
Known risks and trade-offs.
Format: [Risk] <description> → Mitigation: <mitigation>
[Trade-off] <trade-off description> → rationale for accepting
-->

## 迁移计划

<!--
部署顺序、回滚策略、验收条件。
若本次变更不涉及部署变更(纯加依赖、无 endpoint / DB 变更),
可写"N/A —— 本次变更不涉及部署变更"。
-->

<!--
Deployment order, rollback strategy, acceptance criteria.
If this change involves no deployment change (adding a dependency only, no endpoint / DB change),
you may write "N/A —— 本次变更不涉及部署变更".
-->

## 待定问题

<!-- 尚未决定或未知的点 -->
