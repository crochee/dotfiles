---
name: repo-wiki
description: Use when documenting a new project, updating existing documentation, creating a comprehensive wiki from codebase analysis. Generates complete multi-page project wiki from actual codebase.
---

# Repo Wiki

Generates complete multi-page Markdown wiki for the current repository. Output language matches query. Content must be based on actual code.

**Core rules:**

- All technical content (module names, CLI commands, paths) must exist in repo
- No fabricated content
- Output to `./.open_docs`
- No empty pages

**See** **[references/workflow.md](references/workflow.md)** **for detailed 3-phase workflow.**

## Three-Phase Process

```
Phase 1: Scaffold  →  Phase 2: Analyze  →  Phase 3: Fill
```

### Phase 1: Scaffold

Run `scaffold_open_docs.py` to create `.open_docs/` directory structure.

### Phase 2: Analyze

**FETCH → FILTER → SUMMARIZE** pipeline:

1. **FETCH:** Collect repo metadata (README, package files), directory tree, entry points, config sources, data models
2. **FILTER:** Exclude binaries/generated files, prioritize core logic (`src/`, `lib/`, `cmd/`)
3. **SUMMARIZE:** Bottom-up from files to folders to root

### Phase 3: Fill

Write analysis results into scaffold files. Ensure navigation and details blocks are correct.

**See** **[references/page-types.md](references/page-types.md)** **for adaptive page selection rules.**

## Page Categories

| Category                                | Pages                                                                                  |
| --------------------------------------- | -------------------------------------------------------------------------------------- |
| **Mandatory (always)**                  | Overview, Quick Start, Project Structure, Configuration, Usage, Development            |
| **Optional (when detected)**            | CLI Commands, API Reference, Installation, Troubleshooting, FAQ, Testing, Contributing |
| **Conditional (when components exist)** | Deployment, Architecture, Performance, Advanced Topics                                 |

**See** **[references/wiki-template.md](references/wiki-template.md)** **for full page structure and content guidance.**

## Quality Checklist

- [ ] All paths/commands/env vars exist in repo
- [ ] All content in target language
- [ ] Navigation links correct
- [ ] Details blocks list real file paths
- [ ] No placeholder text
- [ ] Mermaid diagrams valid

## Output Structure

```
.open_docs/
  index.md                     # Wiki index with ordered page list
  01-overview.md
  01-01-quick-start.md
  02-project-structure.md
  ...
```

## References

- [references/workflow.md](references/workflow.md) - Complete 3-phase workflow
- [references/page-types.md](references/page-types.md) - Page selection rules
- [references/wiki-template.md](references/wiki-template.md) - Page structure and examples
- [scripts/scaffold_open_docs.py](scripts/scaffold_open_docs.py) - Scaffold wiki directory structure