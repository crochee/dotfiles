---
name: repo-wiki
description: >
  Generate a complete, professional multi-page project wiki for the current repository. Output language matches the user's query, output goes to ./.open_docs. Use when documenting a new project, updating existing documentation, creating a comprehensive wiki from codebase analysis, or when user mentions wiki, project documentation, codebase docs, or generating docs.
license: MIT
metadata:
  author: skills-team
  version: "3.0"
  compatibility: Requires Python 3.10+ for scaffold script
---

# Repo Wiki

Generate a multi-page Markdown wiki for the **current repository**, grounded entirely in the actual codebase. The output is not a generic template — every page must reflect the real project.

## Core Rules

| Rule | Description |
|------|-------------|
| **Grounding** | All technical content — module names, CLI commands, config keys, file paths, env vars — must be found in the current repo. Do not invent them. |
| **Language** | Output language matches the user's query. Section headings, prose, and UI labels are in that language. Technical tokens (paths, commands, variable names) stay unchanged. |
| **No handoff** | Write every page completely in the target language. Never defer to another language's page with "see English version". |
| **Output** | Write to `./.open_docs` in the project root. Never write outside it. |
| **No hollow pages** | Every generated page must contain real content drawn from the repo. Do not leave scaffold placeholders or "Not found in repo" as the only content — either write a meaningful stub or omit the page entirely. |
| **No over-generation** | Do not generate pages that have no grounding in the repo. If a CLI does not exist, do not generate the CLI Commands page. |

## Codebase Analysis Workflow

Before generating any wiki page, perform a systematic analysis of the codebase. This mirrors a **FETCH → FILTER → SUMMARIZE** pipeline:

### Stage 1: FETCH — Repository Discovery

Gather all structural and metadata signals from the repository:

1. **Metadata sources**: `README.md`, `pyproject.toml` / `package.json` / `Cargo.toml` / `go.mod` — extract project name, description, version, keywords, dependencies.
2. **Directory structure**: Run `ls -R` or equivalent to map the full tree. Prune noise (`__pycache__`, `.git`, `node_modules`, `dist`, `build`).
3. **Entry points**: Identify execution entry points by language:
   - Python: `pyproject.toml` `[project.scripts]`, `setup.py` `entry_points`, `main.py`, `__main__.py`
   - Node.js: `package.json` `bin`, `main`, `scripts.start`
   - Go: `main.go` in `cmd/` or root, `go.mod` module name
   - Rust: `src/main.rs`, `Cargo.toml` `[[bin]]`
   - Multi-language: Identify which language owns the primary entry point
4. **Configuration sources**: Search for `os.environ.get` / `os.getenv` / `process.env` / `std::env::var`, config files (`.env*`, `config.*`, `settings.*`, `*.toml`, `*.yaml`, `*.yml`, `*.json`), CLI argument parsers (`argparse`, `click`, `cobra`, `clap`), and hardcoded defaults.
5. **Data models**: Identify model/entity/schema definitions — `models/`, `schemas/`, `dataclasses`, ORM models, proto files, GraphQL schemas. Understand the data layer before summarizing business logic.

### Stage 2: FILTER — Signal Extraction

Remove noise and identify the high-value analysis targets:

1. **Exclude binary/generated files**: `*.min.js`, `*.lock`, `*.png`, `*.ico`, `*.woff`, `dist/`, `build/`, generated protobuf/grpc code.
2. **Identify code vs. config vs. docs**: Separate files into categories for different analysis strategies.
3. **Prioritize core logic**: Focus on `src/`, `lib/`, `internal/`, `cmd/`, `app/` — not test fixtures or CI configs (unless analyzing the Testing or Deployment page).

### Stage 3: SUMMARIZE — Bottom-Up Content Generation

Process the repository tree in this order:

1. **Files first** — read content, produce summaries for all files. For each file:
   - **Usage**: < 10 words, what the file is used for
   - **Summary**: 2-3 paragraphs describing its purpose and role in the project
   - **Code references**: Notable blocks as relative links from project root, e.g. [`src/main.py:L10-L50`](src/main.py#L10-L50)
2. **Folders deepest-first** — sort by depth descending, process leaves to root. For each folder:
   - **Usage**: < 10 words, folder purpose
   - **Summary**: Folder's main purpose and role, using child summaries as context
   - **Dependency graph**: Mermaid `graph TD` of file relationships (if non-trivial). Use safe node IDs (`filename["filename"]`) and short labeled arrows (`A -->|provides config to| B`). Good labels: "uses", "extends", "implements", "fetches from", "stores in", "validates"
3. **Root summary last** — aggregate all top-level item summaries into the Overview page.

This bottom-up approach ensures each folder summary has access to its children's summaries as context, producing a coherent dependency graph.

### Content Size Management

- Limit analysis context to ~60,000 characters per file
- For files > 50 lines, analyze in overlapping segments (50 lines per segment, 10 lines overlap) to preserve context
- Keep summaries concise: files get 2-3 paragraphs, folders get 3-4 paragraphs

## Content Grounding Sources

For each wiki page, draw content from these specific sources:

| Page Type | Primary Sources |
|-----------|----------------|
| Overview | `README.md`, package metadata (`pyproject.toml`/`package.json`/`Cargo.toml`), entry point docstrings |
| Quick Start | Installation scripts, `Makefile` targets, existing setup docs, `Dockerfile` |
| Project Structure | `ls -R` output, package layout in `src/`/`lib/`, `go.mod`/`Cargo.toml` module definitions |
| Configuration | Env var usages in code, config file schemas, CLI argument definitions |
| Usage | `README.md` examples, `examples/` directory, test files with realistic usage patterns |
| Development | `Makefile` dev targets, test runner configs, linting configs, `CONTRIBUTING.md` |

## Adaptive Page Selection

Pages are classified as **required**, **optional**, or **conditional**. Follow the detection criteria strictly.

### Required (always generate)

`Overview` · `Quick Start` · `Project Structure` · `Configuration` · `Usage` · `Development`

These six pages form the minimum viable wiki for any project.

### Optional (generate if the corresponding indicator exists)

| Page | Indicator in repo |
|------|-------------------|
| CLI Commands | `pyproject.toml` with `[project.scripts]` / `setup.py` with `entry_points` / `package.json` with `bin` / `Makefile` with top-level targets / any executable in `bin/` or `cmd/` |
| API Reference | Public modules with `__all__` exports / `api.py` / `api/` package / OpenAPI spec file / route definitions in web frameworks |
| Installation | No native package (pip/npm not applicable) / platform-specific install steps / build-from-source required |
| Troubleshooting | Any `KNOWN_ISSUES`, `FAQ`, or troubleshooting section in existing docs / complex multi-step setup |
| FAQ | Any existing Q&A content in README or docs |
| Testing | `test_*.py` / `*_test.go` / `*.spec.ts` / `tests/` directory / `pytest.ini` / `vitest.config` |
| Contributing | `CONTRIBUTING` file / `CODE_OF_CONDUCT` / open issues or PRs |

### Conditional (generate only if the component exists)

| Page | Indicator |
|------|-----------|
| Deployment | `Dockerfile` / `docker-compose.yml` / `.github/workflows/deploy*` / `k8s/` / `helm/` / deployment scripts in `scripts/` |
| Architecture | Multiple packages/modules (3+) with non-trivial interdependencies / explicit architecture docs / `ARCHITECTURE.*` file |
| Performance | Benchmark files (`bench_*`) / profiling config / performance-related `env` vars or flags / `performance.md` |
| Advanced Topics | Plugins/extension system / hooking mechanism / custom DSL / advanced config that warrants deep-dive |

### When content is sparse

If a required page has very little real content to show, write a **concise but meaningful** stub (2-3 paragraphs) rather than a skeleton. If you genuinely cannot write at least one substantive paragraph for a required page, note this in your internal review and flag it.

## Output Structure

```
.open_docs/
  index.md                     # Wiki home — ordered list of all pages
  01-overview.md               # Filename: <zero-padded-id>-<slug>.md
  01-01-quick-start.md
  02-project-structure.md
  ...
```

- `index.md` has an H1 and an ordered numbered list (`1.` `2.` `3.`) of all pages.
- Each page file has a **navigation line** at the top (prev / next / index links) and a **`<details>` block** at the bottom listing relevant source files.
- No page should have residual scaffold markers like `> Fill this page with...` or `- \`path/to/file\`` as the only content.

## Error Handling

| Situation | Action |
|-----------|--------|
| No `README.md` found | Still generate all required pages; draw Overview content from `pyproject.toml`, `package.json`, `Cargo.toml`, or code comments |
| No config files found | Configuration page should state "This project uses default configuration with no custom files" and list actual defaults found in code |
| `--input` JSON is malformed | Script prints warning to stderr, falls back to bundled template silently |
| `--input` JSON is valid but has no `page_plan` entries | Script prints warning to stderr, uses bundled template |
| Language cannot be detected | Defaults to English |
| File already exists (scaffold script) | Skips by default; use `--force` to overwrite |

## Quality Checklist

Before finishing the wiki, verify every page:

- [ ] All module names, file paths, commands, and env vars actually exist in the repo
- [ ] Every page is written entirely in the target language (no mixed-language handoffs)
- [ ] Navigation lines on each page correctly point to adjacent pages
- [ ] `<details>` block lists real file paths from the repo, not generic placeholders
- [ ] No page is left as only scaffold text (`> Fill this page...` or single-line stubs)
- [ ] `index.md` contains all generated pages in correct order
- [ ] Mermaid diagrams (if any) use valid syntax with `flowchart`, `sequenceDiagram`, or `classDiagram` keywords

## Helper Script

The `scaffold_open_docs.py` script generates the directory structure and skeleton files from the bundled template:

```bash
# Auto-detect language from query
python3 <skill_dir>/scripts/scaffold_open_docs.py --query "中文项目"
python3 <skill_dir>/scripts/scaffold_open_docs.py --query "Python CLI tool"

# Explicit language
python3 <skill_dir>/scripts/scaffold_open_docs.py --lang zh --output .open_docs

# Use with external scraped data
python3 <skill_dir>/scripts/scaffold_open_docs.py --input ./scraped_wiki.json --query "..."

# Force overwrite existing pages
python3 <skill_dir>/scripts/scaffold_open_docs.py --query "..." --force
```

The script scaffolds filenames, `index.md`, and per-page nav + details blocks. **Content must still be filled in manually** by grounding in the actual repo.

## References

- Full page structure, per-page content guidance, and Mermaid diagram examples: `references/wiki-template.md`

## Usage Examples

### English CLI tool (minimal)

Query: `"generate a wiki for my Python CLI tool"`

Generates required 6 pages + CLI Commands (since `pyproject.toml` with `[project.scripts]` exists).

### Chinese web project (medium)

Query: `"为我的 Node.js Web 项目生成 wiki"`

Generates required 6 pages + CLI Commands (package.json bin) + API Reference (express routes) + Deployment (Dockerfile) + Testing.

### Large multi-language project

Query: `"document this Go microservices repo"`

Generates all required + all optional + all conditional pages + Advanced Topics (if plugin system exists).

### Tiny single-file script

Query: `"为这个脚本项目写 wiki"`

Generates only the 6 required pages with concise, grounded stubs. Does not generate CLI Commands, API Reference, etc.
