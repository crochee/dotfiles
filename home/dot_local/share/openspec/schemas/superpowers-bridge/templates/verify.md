# 验收报告

> 此文件由 `openspec-verify-change` skill 在 apply 完成后产生,用以确认实现
> 与 specs / design / tasks 的一致性。失败的检查须返回对应 artifact 修正后
> 再重跑 verify。

**Change**:`<change-name>`
**验收时间**:`YYYY-MM-DD HH:mm`
**验收者**:`<谁 / 哪个 agent>`

---

## 1. 结构校验(`openspec validate --all --json`)

- [ ] 全数 items `"valid": true`

**结果**:

```text
<贴上 openspec validate --all 的输出摘要>
```

若有失败项,列出 id + issues:

| Item | Type | Issues |
|---|---|---|
| — | — | — |

---

## 2. 任务完成度(`tasks.md`)

- [ ] 所有 `- [ ]` 已变为 `- [x]`

**未完成任务**(若有):

| Task | 未完成原因 | 是否阻塞 archive |
|---|---|---|
| — | — | — |

---

## 3. Delta Spec 同步状态

对每个 `openspec/changes/<name>/specs/` 下的 capability 目录,与
`openspec/specs/<capability>/spec.md` 比对:

| Capability | Sync 状态 | 备注 |
|---|---|---|
| — | ✓ 已同步 / ✗ 待同步 / N/A | — |

---

## 4. 设计 / 规格一致性抽查

抽样比对 `design.md` 的决策是否反映在 `specs/*.md` 的 Requirements 与
Scenarios 中:

| 抽样项 | design 描述 | specs 对应 | 差距 |
|---|---|---|---|
| — | — | — | — |

**漂移警告**(非阻塞):

- <若有,列出;无则填"无">

---

## 5. 落地信号

- [ ] Worktree 内无未 staged 的文件
- [ ] 所有相关 commit 已推送

**Commit 范围**(若知道):`<from-sha>..<to-sha>`

---

## 6. 前门路由泄漏检测(warning,非阻塞)

设计产出不应落在 `docs/superpowers/specs/`(brainstorm artifact 的
输出重定向会把它导到 `openspec/changes/<name>/brainstorm.md`)。

侦测:

```bash
ls docs/superpowers/specs/*.md 2>/dev/null
```

- [ ] 无文件,或存在的文件是 schema 安装前的合法存量

**泄漏清单**(若有):

| 文件 | 内容是否已 captured 进 change | 建议动作 |
|---|---|---|
| — | — | — |

> 不会挡住 archive。新的 schema-installed cycle 产生的泄漏,应搬进
> `openspec/changes/<name>/brainstorm.md` 或 `design.md` 后删原档。

---

## 7. 延后的人工验证与自动化测试等价性

对 plan.md 中标 `- [~]` deferred 的手动 dogfood / smoke task,逐项列出
等价的自动化测试覆盖。若没有等价自动化测试,该项应视为**真正的 gap**
而非合理 deferral,建议在 retrospective Misses 中记录。

| Deferred dogfood (plan §) | Equivalent automated test | Coverage assessment | 真正 gap? |
|---|---|---|---|
| 例:§11.3 `compose up + curl /actuator/health` | `LinebcIntegrationApplicationTests`(Testcontainers,24s) | Spring context boot + Flyway 跑完 + 主要 bean 注入 | ❌ 已等价覆盖 |
| — | — | — | — |

> **判读规则**:
> - 「等价」= 自动化测试的 assertion 集合是手动验证预期 assertion 的超集
> - 「Coverage assessment」= 列出实际被触及的 layer(context / DB schema / wiring / HTTP path 等)
> - 任何「真正 gap = ✅」的行,总体结论仍可 PASS,但须在 retrospective 留 follow-up 条目

> **何时可以整节留白**:plan.md 完全没有任何 `- [~]` 标记的行时,本节不需要填(留白即 PASS)。
> 只要 plan.md 出现任何 `- [~]`,本节必须逐项列出,否则总体结论应降为 FAIL。

---

## 总体结论

- [ ] ✅ PASS — 可进入 finishing-a-development-branch 与 archive
- [ ] ⚠️ PASS WITH WARNINGS — 可进入后续步骤但需注意:`<说明>`
- [ ] ❌ FAIL — 返回失败的 artifact 修正后重跑 verify

**下一步**:

<说明下一个动作>
