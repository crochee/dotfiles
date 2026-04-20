---

name: repo-wiki
description: Generate a complete, professional multi-page project wiki for the current repository. Output language matches the user's query. Output goes to ./.open_docs.
inputs:
  - name: query
    type: string
    description: User's query string. Determines output language and page focus. Write in the language you want the wiki to be generated in.
  - name: repo_context
    type: directory
    description: The current repository root. All technical content (module names, file paths, commands, config keys) must be sourced from here.
outputs:
  - name: wiki_pages
    type: directory
    description: Generated wiki under ./.open_docs/ — includes index.md and one .md file per page, fully written in the target language.
  - name: scaffold
    type: directory
    description: When using the helper script only, produces skeleton files with nav lines and details blocks awaiting content.

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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

## Adaptive Page Selection

Pages are classified as **required**, **optional**, or **conditional**. Follow the detection criteria strictly.

### Required (always generate)

`Overview` · `Quick Start` · `Project Structure` · `Configuration` · `Usage` · `Development`

These six pages form the minimum viable wiki for any project.

### Optional (generate if the corresponding indicator exists)

| Page | Indicator in repo |
|------|-------------------|
| CLI Commands | `pyproject.toml` with `[project.scripts]` / `setup.py` with `entry_points` / `package.json` with `bin` / `Makefile` with top-level targets / any executable in `bin/` or `cmd/` |
| API Reference | Public modules with `__all__` exports / `api.py` / `api/` package / OpenAPI spec file |
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
  1-overview.md                # Filename: <id>-<slug>.md
  1-1-quick-start.md
  2-project-structure.md
  ...
```

- `index.md` has an H1 and an ordered bullet list of all pages.
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

## Template

Full page structure, per-page content guidance, and Mermaid diagram examples: `references/wiki-template.md`

---

## Usage Examples

### English CLI tool (minimal)

Query: `"generate a wiki for my Python CLI tool"`

→ Generates required 6 pages + CLI Commands (since `pyproject.toml` with `[project.scripts]` exists).

### Chinese web project (medium)

Query: `"为我的 Node.js Web 项目生成 wiki"`

→ Generates required 6 pages + CLI Commands (package.json bin) + API Reference (express routes) + Deployment (Dockerfile) + Testing.

### Large multi-language project

Query: `"document this Go microservices repo"`

→ Generates all required + all optional + all conditional pages + Advanced Topics (if plugin system exists).

### Tiny single-file script

Query: `"为这个脚本项目写 wiki"`

→ Generates only the 6 required pages with concise, grounded stubs. Does not generate CLI Commands, API Reference, etc.
