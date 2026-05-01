---
name: skill-creator
description: Create, edit, and package Agent Skills following industry standards. Use when building new skills, modifying existing ones, or when user mentions skill creation, SKILL.md, or Agent Skills development.
---

# Skill Creator

This skill provides guidance for creating effective Agent Skills.

## About Skills

Skills are modular packages that extend AI capabilities with specialized knowledge, workflows, and tools. They transform general-purpose agents into specialized agents equipped with procedural knowledge.

## Core Principles

### Concise is Key

The context window is a shared resource. Only add context the AI doesn't already have. Challenge each addition: "Does the AI really need this?"

### Set Appropriate Degrees of Freedom

- **High freedom** (text instructions): When multiple approaches are valid
- **Medium freedom** (pseudocode/scripts): When a preferred pattern exists
- **Low freedom** (specific scripts): When consistency is critical

## Skill Creation Workflow

Follow these steps in order:

### 1. Understand the Skill

Gather concrete examples of how the skill will be used. Ask users for specific scenarios or propose examples for validation.

### 2. Plan Reusable Contents

Analyze each example to identify what scripts, references, or assets would be helpful for repeated execution.

### 3. Initialize the Skill

Run the initialization script to create a new skill directory with template files:

```bash
scripts/init_skill.py <skill-name> --path <output-directory>
```

The script creates:
- `SKILL.md` template with proper frontmatter
- `scripts/`, `references/`, and `assets/` directories with example files

### 4. Edit the Skill

Customize the generated files:
- Write clear, actionable instructions in SKILL.md
- Add tested scripts for deterministic operations
- Include reference material for domain-specific knowledge
- Delete any unneeded example files

See references for detailed design guidance:
- For skill anatomy and resource organization: `references/skill-structure.md`
- For progressive disclosure patterns: `references/design-principles.md`
- For workflow design patterns: `references/workflows.md`
- For output quality patterns: `references/output-patterns.md`

### 5. Package the Skill

Validate and create a distributable `.skill` file (zip format):

```bash
scripts/package_skill.py <path/to/skill-folder> [output-directory]
```

The script validates:
- YAML frontmatter format and required fields
- Skill naming conventions and directory structure
- Description completeness and quality
- File organization

### 6. Iterate

Test the skill on real tasks, notice issues, and refine based on actual usage.

## Quick Reference

### SKILL.md Frontmatter

```yaml
---
name: skill-name          # Must match directory name exactly
description: Clear explanation with triggers   # What + when to use
license: MIT               # Optional but recommended
compatibility: Claude Code # Optional, specify compatible tools
metadata:                  # Optional, additional information
  author: Your Name
  version: 1.0.0
---
```

**Required fields:**
- `name` - Must match directory name exactly (kebab-case)
- `description` - What the skill does + when to use it

**Optional but recommended:**
- `license` - License type (MIT, Apache-2.0, GPL, etc.)
- `compatibility` - Compatible tools or versions
- `metadata` - Author, version, and other custom information

### Directory Structure

```
skill-name/
├── SKILL.md              # [Required] Core file
├── README.md             # [Recommended] Human-friendly guide
├── scripts/              # [Optional] Executable code
├── references/           # [Optional] Documentation on-demand
└── assets/               # [Optional] Output files (templates, etc.)
```

### Naming Convention

- Use kebab-case (all lowercase, hyphen-separated)
- Directory name must match `name` field in SKILL.md exactly
