# 复盘:<change-name>

> 写于:<YYYY-MM-DD>(verify 通过后)
> Commit 范围:`<base-sha>..<head-sha>`
> Worktree:<路径,或 "merged to main">

---

## 0. 证据

> 量化前置数据 —— 后面的 收获 / 失误 条目直接引用,避免每行重复 [evidence: ...]。
> 冷写场景(retro 写于 cycle 结束之后一段时间),只用 `git log` + `tasks.md` +
> commit messages 也应能重建本节。

- **Commit 范围**:`<base-sha>..<head-sha>`(<n> commits)
- **Diff 规模**:<+X / -Y lines,共 N 个文件>
- **任务完成率**:<x>/<y>(`grep -cE '^\s*- \[x\]' tasks.md` → x;regex 容许 sub-task 缩排)
- **活跃工时**:<估算>
- **Subagent 派发数**:<次数或 "n/a">
- **新增外部依赖**:<列表,附 license + 版本,或 "none">
- **合并后 bug**:<次数,每个一行,或 "none">
- **归档时 OpenSpec validate 状态**:<pass / fail / not-run>
- **测试覆盖信号**:<例如 jacoco %、pytest 用例数、vitest 用例数,或 "n/a">

Commit chain(时序):

```
<base-sha> <一句话摘要>
...
<head-sha> <archive commit 一句话>
```

---

## 1. 收获

- [evidence: <commit/文件/测试>] <描述>

## 2. 失误

- 🔴 [blocking | evidence: ...] <描述>
- 🟡 [painful  | evidence: ...] <描述>
- 📌 [nit      | evidence: ...] <描述>

## 3. 计划偏差

| Plan task | What changed | Why |
|-----------|--------------|-----|
| 1.2       | ...          | ... |

## 4. Skill / 工作流执行合规

| Skill                                    | Used |
|------------------------------------------|------|
| brainstorming                            |      |
| writing-plans                            |      |
| using-git-worktrees                      |      |
| subagent-driven-development              |      |
| (传递) test-driven-development           |      |
| (传递) requesting-code-review            |      |
| finishing-a-development-branch           |      |

> **默认预期**:全部 ✓。每个 skill 都是 schema 设计的一部分,
> 跳过属于异常情境。任一项 ✗ 都必须在下方
> `### 有意跳过的 Skill` subsection 提出原因与预防方案。

### 有意跳过的 Skill

> 跳过 skill 是设计好的 escape hatch,不是常规路径。每个 ✗ 必须回答以下三题;
> 整节留白(全绿)是预期状态。

- **`<skill name>`**
  - **跳过了什么**:<具体跳过了整个 skill,还是某个 sub-step>
  - **本轮为何跳过**:<具体 cycle 条件 —— 不可写「不需要」/「太小」/「没时间」/「被外部 dep 挡住」/「skill 输出看起来不对」之类含糊理由;要写实际 trigger(具体 commit / log line / 观察到的行为)>
  - **如何避免复发**:下一轮在同类条件下怎么不再跳?选一:
    - `schema graph fix` —— 写具体要改 schema.yaml 的哪一段
    - `skill description tightening` —— 写具体要改哪个 skill 的 frontmatter / instruction
    - `CLAUDE.md trigger` —— 写具体要在 adopter CLAUDE.md.fragment 加哪段判读规则
    - `scope-judgment rule` —— 写具体 cycle 的 scope 应该被怎么判读
    - `one-off — schema boundary case, no prevention possible` —— 但需明写为何是 boundary(不接受含糊保留)

> **与 §6 可沉淀候选的关系**:多个 cycle 同 skill 同 `如何避免复发`
> 答案 → 该模式应 promote 到 §6,直接触发 schema / skill PR,不可累积成「常态」。

## 5. 意外

- <哪个假设被证伪>

## 6. 可沉淀候选 → 长期学习

每条 candidate 用 `- [ ]` checklist:

- 标题:严重程度 emoji(🔴/🟡/📌)+ 一句话经验
- `→ **Promote to** <destination>`(memory / CLAUDE.md / schema / skill / one-off)
- 两行 body(对应 feedback memory body schema):
  - `> **Why**: <reason;often a past incident or strong preference>`
  - `> **How to apply**: <when/where this guidance kicks in>`

未勾选的 `- [ ]` 表示 candidate 尚未 promote —— 可带到下一轮 cycle 的 retro 重评估,
或保留作为跨 cycle 的观察点。

> **Carry-forward 机制**:下个 cycle 写 retro 时,可
> `grep -A 5 '^- \[ \]' openspec/changes/archive/*/retrospective.md` 取出
> 既往 unchecked candidates,逐笔判断要 carry-forward 到本 cycle §6、就地
> promote、或标 stale 不再追踪。

范例:

- [ ] 🔴 **<short rule>** → **Promote to memory** (type: feedback)
  > **Why**: <past incident or strong preference that motivated this rule>
  > **How to apply**: <which file / cycle phase / decision moment this kicks in>

- [ ] 🟡 **<another candidate>** → **Promote to project CLAUDE.md** (`<path/to/CLAUDE.md>` 段)
  > **Why**: ...
  > **How to apply**: ...

- [ ] 📌 **<third candidate>** → **One-off**(记录即可,不 promote)
  > **Why**: <why it doesn't generalize>
