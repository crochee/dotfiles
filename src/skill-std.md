# Agent Skills 标准规范

目前，业界在AI Skill的目录结构上，正从各家自定义的阶段，走向一个统一、开放的标准。这个标准被称为 **Agent Skills**，它定义了一种轻量、开放，且被主流AI编码工具（如Claude Code、GitHub Copilot、Cursor等）广泛支持的目录格式。

一个Skill的本质是一个包含特定文件的文件夹，其核心思想是 **“渐进式披露” (Progressive Disclosure)**。AI并不会在启动时加载所有细节，而是先读取一个包含元数据（名称、描述）的“摘要”。只有当AI判断当前任务与某个Skill相关时，才会进一步加载完整的指令和所需资源。这使得上下文管理非常高效。

## 📁 标准的 Skill 目录结构

根据 `agentskills.io` 规范和多个主流工具的实践，一个标准的Skill目录结构通常如下：

```plaintext
skill-name/               # 技能包根目录，名称应与 SKILL.md 中的 name 字段一致
├── SKILL.md              # [必需] 核心文件，包含元数据和执行指令
├── README.md             # [推荐] 对人友好的使用说明
├── scripts/              # [可选] 存放可执行脚本 (Python/Bash 等)
│   └── main.py
├── references/           # [可选] 存放供 AI 按需加载的参考文档
│   └── api-docs.md
└── assets/               # [可选] 存放 AI 输出时使用的静态资源，如模板、图片
    └── template.html
```

需要注意的是，Skill 内部的 SKILL.md 文件通常有“一文件夹一技能”和文件名大写的约定。

## 🌐 各主流平台的存放位置

虽然目录内部结构趋同，但为了让不同 AI 工具发现这些 Skill，你需要将它们放在各工具约定的特定路径下。Skill 可分为两类：

- **项目级技能 (Project Skills)**：仅对当前项目生效，通常存放在项目的隐藏文件夹中。
- **个人/全局技能 (User/Personal Skills)**：对你所有的项目都生效，存放在用户家目录（`~`）下。

以下是主流平台的具体存放位置：

| AI 工具 / 平台             | 项目级路径                | 个人/全局级路径             |
| :--------------------- | :------------------- | :------------------- |
| **Agent Skills 通用标准**  | `.agents/skills/`    | (尚未严格规定，由各工具自行定义)    |
| **GitHub Copilot**     | `.github/skills/`    | `~/.copilot/skills/` |
| **Claude Code**        | `.claude/skills/`    | `~/.claude/skills/`  |
| **Codex CLI (OpenAI)** | `.codex/skills/`     | `~/.codex/skills/`   |
| **Cursor**             | `.cursor/skills/`    | (可能使用用户级配置)          |
| **CodeBuddy**          | `.codebuddy/skills/` | (可能使用用户级配置)          |

## 📝 核心配置：SKILL.md 文件详解

`SKILL.md` 文件由 **YAML 前置元数据 (Frontmatter)** 和 **Markdown 正文指令** 两部分组成。

### 标准 SKILL.md 示例

```markdown
---
name: pdf-processing
description: Extract PDF text, fill forms, and merge files. Use when handling PDFs or when user mentions PDFs, forms, or document extraction.
---

# PDF Processing

## When to Use This Skill
This skill should be used when the user asks to modify, rotate, or extract text from PDF files.

## Core Workflow
To process a PDF, follow these steps:
1.  **Analyze**: Use `scripts/analyze_pdf.py` to check the file structure.
2.  **Execute**: Run the appropriate action based on the user's request.
3.  **Verify**: Ensure the output is a valid PDF.

## Output Specification
- Always provide a summary of actions taken.
- If an action fails, explain why and suggest next steps.

## References
- For detailed API documentation, see `references/api-docs.md`.
```

### YAML Frontmatter 字段说明

| 字段              | 类型  | 必需/可选  | 说明                           |
| --------------- | --- | ------ | ---------------------------- |
| `name`          | 字符串 | **必需** | 技能名称，必须与父目录名完全一致             |
| `description`   | 字符串 | **必需** | 技能描述，需包含"做什么"和"何时用"          |
| `license`       | 字符串 | 可选     | 许可证类型，如 MIT、Apache-2.0、GPL 等 |
| `compatibility` | 字符串 | 可选     | 兼容性说明，如依赖的工具或版本              |
| `metadata`      | 对象  | 可选     | 元数据，如 author、version 等       |
| `allowed-tools` | 字符串 | 可选     | 声明可用的工具（实验性字段）               |

### Description 字段的重要性

`description` 字段是 AI 决定何时触发 Skill 的唯一依据，必须包含具体的**功能关键词**和**场景关键词**。

\*\*❌ 不好的示例：

```yaml
description: "处理 PDF 文件"
```

**✅ 好的示例：**

```yaml
description: "Extract PDF text, fill forms, and merge files. Use when handling PDFs or when user mentions PDFs, forms, or document extraction."
```

## ✨ 最佳实践

为了让你的 Skill 更高效、更易维护、更具可移植性，这里总结了业界普遍推荐的最佳实践：

1. \*\*编写出色的 `description` 字段：这是 AI 决定何时触发 Skill 的唯一依据，必须包含具体的功能关键词和场景关键词。避免模糊的表述，简洁有力token占用少。
2. **利用“渐进式披露”原则**：将长篇大论的参考资料、API 文档等内容放入 `references/` 目录，只在主 `SKILL.md` 文件中通过链接引用。
3. **清晰的命名与一致性**：Skill 的目录名应采用 **kebab-case**（全小写、单词间用连字符）命名。同时，目录名必须与 `SKILL.md` 内的 `name` 字段完全一致。
4. **职责单一**：一个 Skill 应只解决一个具体问题，避免创建“万能 Skill”。
5. **为人类也提供文档**：始终提供 `README.md` 对人友好的说明，不仅是 AI 的指令。
6. **参考官方模板**：GitHub 上已有许多遵循此标准的 Skill 仓库，是很好的参考范例。

## 🎯 快速检查清单

创建或优化 Skill 时，使用以下检查清单：

- [ ] 目录名使用 kebab-case 命名
- [ ] `SKILL.md` 中的 `name` 字段与目录名完全一致
- [ ] `description` 字段包含"做什么" + "何时用"
- [ ] 包含必要的元数据（license、compatibility、metadata）
- [ ] 提供对人友好的 `README.md`
- [ ] 参考资料放入 `references/` 目录（如有）
- [ ] 脚本放入 `scripts/` 目录（如有）
- [ ] 资源放入 `assets/` 目录（如有）

## 🌟 为什么采用这个标准

这个统一的标准正在被主流 AI 编码工具快速采纳，基于它来构建和分享技能，可以确保你的工作流在不同工具和团队之间具有更好的可移植性。
