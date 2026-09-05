# 在 Skill 中嵌套官方 Skill

将 OpenSpec 官方 Skill 作为子模块嵌入大型 Skill，实现高级定制化。

## 原理

借鉴社区项目 `sdd-workflow` 的**"薄编排"**模式：`sdd-*` Skill 只做编排，核心工作委托给底层 Skill（OpenSpec / Superpowers）。

你的"大 Skill"只需做三件事：

- **前置逻辑**：定位变更目录、读取产物、检查条件
- **核心执行**：指引 AI 调用 `openspec-propose`、`openspec-apply-change` 等子技能
- **后置校验**：运行测试、验证规范，通过后触发自动提交

## SKILL.md 结构示例

```markdown
---
name: sdd-full-workflow
description: >
  OpenSpec 规范驱动开发全流程：提案 → AI实施 → 测试验证 → 归档 → 自动Git提交。
  Use when starting a new feature, refactor, or complex bug fix.
---

## 1. 提案阶段

执行前置检查后，委托给 `openspec-propose` Skill：
- 确保 `openspec/config.yaml` 中的 context 正确描述项目环境
- 调用 `openspec-propose`：AI 引导创建 `proposal.md`、`tasks.md` 和规范增量
- 完成后验证：`tasks.md` 必须包含"编写单测与E2E"任务

## 2. 实施阶段

前置条件：提案已审核通过。
- 调用 `openspec-apply-change`：AI 严格按 `tasks.md` 逐项实施
- 遵循 TDD 纪律：先写测试，再写代码

## 3. 验证与归档

- 手动运行：`npm test && npm run e2e`
- 全部通过后，调用 `openspec-archive-change` 归档

## 4. 自动 Git 提交

- 执行 `git add .`
- 执行 `git commit`，Husky + lint-staged 自动运行
- 提交信息遵循 conventional commits 格式
```

