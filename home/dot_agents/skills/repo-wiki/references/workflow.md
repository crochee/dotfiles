# Repository Wiki Workflow

**Load this reference when:** running the end-to-end wiki generation for a repository.

The workflow has four phases in a fixed order:

```
Phase 0: Detect → Phase 1: Scaffold → Phase 2: Analyse → Phase 3: Fill & Deliver
```

Detection comes first because the page set determines what the scaffold creates. Scaffolding all pages and deleting the unwanted ones afterwards produces exactly the empty pages the skill forbids.

## Contents

- [Phase 0: Detect](#phase-0-detect--decide-the-page-set)
- [Phase 1: Scaffold](#phase-1-scaffold--create-the-page-tree)
- [Phase 2: Analyse](#phase-2-analyse--read-the-code)
- [Phase 3: Fill & Deliver](#phase-3-fill--deliver--write-the-pages-and-report)
- [Page type and phase mapping](#page-type-and-phase-mapping)

---

## Phase 0: Detect — decide the page set

**Goal**: decide which pages exist, from evidence in the repository.

**Steps**:

1. Identify the project type from its manifests (`pyproject.toml`, `package.json`, `go.mod`, `Cargo.toml`, `pom.xml`, `build.gradle`) and its entry points (`main.py`, `index.ts`, `cmd/`, `bin/`, `main.go`, `src/main.rs`).
2. Read the detection signals for every optional and conditional page.
3. Apply the page-selection rules: mandatory pages always exist; optional pages exist only when their detection signal is present; conditional pages exist only when the component exists.
4. Record the decision as a page-id list.

**Exit condition**: a page-id list exists, and every optional or conditional page in it has a named signal in the repository — a file, a directory or a manifest key. A page with no signal is not created.

**Ambiguity**: if more than one file could be the entry point, list the candidates in the delivery report instead of picking one silently.

---

## Phase 1: Scaffold — create the page tree

**Goal**: create `docs/openrepowiki/` with exactly the detected pages.

**Steps**:

1. Run the scaffold script with the detected page ids:

   ```bash
   # run from the skill directory (~/.agents/skills/repo-wiki/)
   python3 scripts/scaffold_open_docs.py \
     --query "<the user's description of the project>" \
     --pages 1,1.1,2,3,4,5 \
     --output docs/openrepowiki
   ```

2. Leave out `--pages` only when every page in the template genuinely applies.
3. Pass `--lang` explicitly for a language other than English or Chinese.

**Exit condition**: `docs/openrepowiki/` contains `index.md` plus one file per detected page, and the navigation line on each page points at its true neighbours.

**Do not modify the repository.** The only thing this skill writes is `docs/openrepowiki/`. Source files, manifests, CI configuration and lockfiles are read-only inputs. Do not commit the wiki; if the repository does not already ignore `docs/openrepowiki/`, say so in the delivery report and let the user decide.

---

## Phase 2: Analyse — read the code

**Goal**: collect the facts the pages will state.

### 2.1 FETCH — repository discovery

Collect five categories:

1. **Metadata** — project name, description, version, dependencies, from the README and the package manifests.
2. **Directory structure** — the tree, pruned of noise (`.git`, `node_modules`, `__pycache__`, `dist`, `build`, `target`, `.venv`).
3. **Entry points** — what actually executes when the CLI runs or the server starts.
4. **Configuration sources** — environment variables (`os.environ.get`, `os.getenv`, `process.env`), config files, CLI flag parsers.
5. **Data models** — dataclasses, schemas, ORM models, structs, type definitions.

### 2.2 FILTER — what may be read and quoted

Exclude from the analysis:

- **Binary and generated files** — images, archives, compiled artefacts, lockfiles, minified bundles, `dist/`, `build/`, `target/`, `vendor/`.
- **Secrets and credentials** — never read the value, never quote it, never name the variable's real value in the wiki:
  - `.env`, `.env.*`, `.envrc`
  - `*.pem`, `*.key`, `*.keystore`, `*.p12`, `*.pfx`
  - `id_rsa*`, `id_ed25519*`, `id_ecdsa*`, `id_dsa*`, `*.pub` (private half only)
  - `credentials*.json`, `*.secret*`, `*.secrets`
  - `.npmrc`, `.netrc`, `.pypirc`, `.docker/config.json`
  - anything under `secrets/`, `credentials/`, `.aws/`, `.ssh/`, `.gnupg/`
- **Content that is not about the code** — vendored third-party trees, generated API clients, large fixture dumps.

A file matching the exclusion list is never quoted in the wiki, and neither is any line of it. If a page needs to talk about a configuration option, name the option and describe its effect — the secret value stays in the repository.

### 2.3 SUMMARIZE — bottom-up

1. **Files first** — for each file: purpose, 2–3 sentences, and the code references that back the summary.
2. **Folders deepest-first** — a folder summary uses its children's summaries as context.
3. **Root summary last** — the root summary aggregates the top-level folders and becomes the Overview content.

**File budget**: read every entry point, every configuration source and every public module in full. For the rest — tests, fixtures, scripts, docs — read enough to describe what they do, then stop; a sample is a legitimate result, an omission is not. Concretely:

- Analyse in full: entry points, the package/manifest files, configuration sources, the public API surface, the main data models.
- Sample: test files (read the configuration and one representative test per suite), example scripts, documentation files, and any directory holding more than 50 files.

**Escape hatch for an oversized repository**: when the repository is too large to read in full, do not silently truncate and do not skip a phase. Narrow the scope explicitly instead:

1. Analyse the entry points, the configuration sources and the public modules — the "always full" set above.
2. Sample the remainder by directory, taking the two most representative files per directory.
3. Record the directories that were sampled rather than read, and list the claims that rest on that sample, in the delivery report.

A claim derived from a sample is still a claim, and it is still marked as unverified in the report.

**Exit condition**: every detected page has at least one real source file assigned to it, and every file quoted in a summary passed the filter.

### Empty or near-empty repository

When the repository has no analysable source: skip the FETCH → FILTER → SUMMARIZE pipeline, use the README and the package metadata, and write at least two substantive paragraphs per page. Record in the report that the wiki is metadata-only.

---

## Phase 3: Fill & Deliver — write the pages and report

**Goal**: turn the analysis into finished pages and tell the user what is in them.

**Steps**:

1. **Fill page by page**, in page-id order, following the page-template reference for that page's required sections.
2. **Replace every placeholder** — the scaffold note and the `- \`path/to/file\`` line. A page that still carries scaffold text is not finished.
3. **Write the navigation line** so it points at the previous and next page in the *final* page set, in both directions, with the first page having no previous and the last no next.
4. **Write the `<details>` block** with the real files the page was derived from — the paths as they appear in the repository, relative to the repository root.
5. **Update `index.md`** so its ordered list matches the final page set.

**Per-page validation**:

- [ ] No scaffold placeholder text remains
- [ ] The navigation line points at the true neighbours
- [ ] Every path, command, environment variable and flag named on the page exists in the repository
- [ ] The `<details>` block lists real file paths
- [ ] Technical tokens (module names, paths, commands, env vars) are untranslated
- [ ] The prose is in one language throughout — no mixed-language page
- [ ] No Mermaid diagram unless the flow was read from the code

### Delivery report

Phase 3 ends with a report to the user, containing:

1. **Pages produced** — the list, with the location (`docs/openrepowiki/`) and the file names.
2. **Pages omitted** — every page that was not created, with the detection rule that excluded it and the signal that was absent. This is how the user checks the detection was right.
3. **Unverifiable claims** — every statement on a page that could not be confirmed against the source, including anything derived from a sample rather than a full read.
4. **Conflicts** — where the repository already has documentation that contradicts the wiki:

   | Situation | Rule |
   |-----------|------|
   | `docs/` or a README contradicts the wiki | Record the contradiction with both locations and cite the source file that settles it. The older document is not edited from this skill: the correction goes to `architecture-design` for an ADR or to `technical-writing` for a design doc. |
   | The entry point is ambiguous | List the candidate files in the report instead of guessing which one runs. |
   | The repository already contains `docs/openrepowiki/` | The existing content is preserved unless `--force` is passed; the report states what was overwritten. |

**Exit condition**: every detected page is filled and validated, and the report has been given.

---

## Page type and phase mapping

| Page type | Analysis depth | Content source |
|-----------|----------------|----------------|
| Overview | Root summary | Metadata, entry points, data models |
| Quick Start | Entry points, configuration sources | Install scripts, `Makefile`, `Dockerfile` |
| Project Structure | Full directory structure | Directory listing, package layout |
| Configuration | Configuration sources | Environment variable references, config files |
| Usage | Entry points, test files | README examples, `examples/` directory |
| Development | Test config, lint config | `Makefile`, `CONTRIBUTING.md` |
| CLI Commands | CLI entry points | `pyproject.toml` scripts, `Makefile` targets |
| API Reference | Public modules | `__all__`, route definitions |
| Installation | Install scripts | `Makefile`, `scripts/`, container files |
| Deployment | Deployment configuration | `Dockerfile`, CI/CD workflows, manifests |
| Architecture | Package dependencies | Source structure, interface definitions |
| Testing | Test files | Test configuration, test directories |
| Contributing | Contribution files | `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md` |
| Troubleshooting | Error paths in the code | Error messages, `FAQ`, `KNOWN_ISSUES` |
| FAQ | Existing Q&A | README, `FAQ.md`, docs |
| Advanced Topics | Extension points | `plugins/`, `ext/`, `hooks/`, config DSLs |
| Performance | Benchmarks and profiling | `bench_*` files, profiling configuration |
