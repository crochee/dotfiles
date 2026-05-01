# Skill Creator

A comprehensive guide for creating effective Agent Skills following the emerging industry standard.

## What is an Agent Skill?

An Agent Skill is a lightweight, open-ended directory format that extends AI coding assistants with specialized knowledge, workflows, and tools. The standard is supported by major platforms including Claude Code, GitHub Copilot, Cursor, and others.

## What Does This Skill Do?

This `skill-creator` skill provides:

- **Best practices** for designing effective, maintainable skills
- **Step-by-step workflow** for creating skills from scratch
- **Helper scripts** for initialization and packaging
- **Design patterns** for progressive disclosure, workflows, and output quality

## Quick Start

### Create a New Skill

```bash
scripts/init_skill.py my-new-skill --path /path/to/skills/
```

This creates a new skill directory with:
- `SKILL.md` template with proper frontmatter
- `scripts/`, `references/`, and `assets/` directories
- Example files you can customize or delete

### Package a Skill

```bash
scripts/package_skill.py /path/to/my-skill-folder
```

This validates the skill structure and creates a distributable `.skill` file (zip format).

### Validate a Skill

```bash
scripts/quick_validate.py /path/to/my-skill-folder
```

This checks for common issues before packaging.

## Skill Directory Structure

```
skill-name/               # Root directory (kebab-case naming)
├── SKILL.md              # [Required] Core file with metadata and instructions
├── README.md             # [Recommended] Human-friendly usage guide
├── scripts/              # [Optional] Executable scripts (Python/Bash)
├── references/           # [Optional] Documentation loaded on-demand
└── assets/               # [Optional] Static files used in output
```

See `SKILL.md` for detailed guidance on creating and structuring your skills.

## Key Principles

1. **Concise is key** - Minimize context window usage
2. **Progressive disclosure** - Load details only when needed
3. **Single responsibility** - One skill, one purpose
4. **Clear naming** - Use kebab-case, match `name` field exactly

## Platform Support

Skills following this standard work across:
- Claude Code (`.claude/skills/`)
- GitHub Copilot (`.github/skills/`)
- Cursor (`.cursor/skills/`)
- Codex CLI (`.codex/skills/`)
- And more...

## License

See [LICENSE.txt](LICENSE.txt) for complete terms.
