---
name: repo-wiki
description: "Produces a multi-page Markdown wiki under docs/openrepowiki/ with every claim traced to a source file. Use when documenting an unfamiliar repository, onboarding onto a codebase, or refreshing a project wiki."
metadata:
  version: "1.0.0"
compatibility: "Requires Python 3.10+."
---

# Repo Wiki

Produces a multi-page Markdown wiki for a repository under `docs/openrepowiki/`, with every technical claim
traced back to a file in the source. The output language follows the request; identifiers, paths and
commands stay exactly as the code has them.

## When to Use

- Documenting an unfamiliar repository for a reader who has never seen the code.
- Onboarding onto a codebase that has no prose documentation, or documentation that has drifted.
- Producing a reference for a CLI, service or library whose behaviour lives in the source rather
  than in a README.
- Refreshing an existing `docs/openrepowiki/` wiki after the code changed.

Not for: writing marketing copy, summarising a repository in one page, generating documentation
for code that is not in the repository, or a single cited note answering one question — that is
`research`; every page here is part of the multi-page inventory. Every page must be fillable from
real files — if the source does not contain the information, the page says what is missing instead
of inventing it.

## Workflow

1. **Detect the repository and select the pages.** Map the manifests, entry points, configuration
   sources, data models, test layout and deployment files. Read `references/page-types.md` and
   decide the page set: mandatory pages always exist, optional pages exist only when their
   detection signal is present, conditional pages only when the component exists.
   *Exit criterion:* a page-id list exists, and every optional or conditional page in it has a named
   signal in the repository. A page with no signal is not created.

2. **Scaffold exactly those pages.** Run
   [`scripts/scaffold_open_docs.py`](scripts/scaffold_open_docs.py) with the detected page ids.
   The path below is relative to this skill's directory (`~/.agents/skills/repo-wiki/`):

   ```bash
   # python3 3.10+ required
   python3 scripts/scaffold_open_docs.py \
     --query "Python CLI tool" \
     --pages 1,1.1,2,3,4,5 \
     --output docs/openrepowiki
   ```

   Omit `--pages` only when every page in the template genuinely applies. Pass `--lang` explicitly
   for a language other than English or Chinese. See `references/scaffold-cli.md` for the full
   option list and the filename rule.
   *Exit criterion:* `docs/openrepowiki/` contains `index.md` plus one file per selected page, and each
   page's navigation line points at its true neighbours.

   `--input` takes a JSON file when the page plan comes from an external documentation system
   instead of the bundled template. Each entry carries a `page_plan` object with an `id` (a page id
   such as `"1"` or `"2.1"`) and a `title`:

   ```json
   {
     "wiki": {
       "wikis": {
         "en": {
           "pages": [
             { "page_plan": { "id": "1", "title": "Overview" } },
             { "page_plan": { "id": "1.1", "title": "Quick Start" } }
           ]
         }
       }
     }
   }
   ```

   The language bundle is selected by `--lang`. A missing, malformed or unrecognised file falls back
   to the bundled template with a warning on stderr. The full field table is in
   `references/scaffold-cli.md`.

3. **Analyse the code.** Collect the metadata, directory structure, entry points, configuration
   sources and data models; filter out binaries, generated files and secrets; summarise bottom-up
   from files to folders to the repository root.
   *Exit criterion:* every selected page has at least one real source file assigned to it, and every
   file read passed the exclusion filter.

4. **Fill the pages.** Write each page from its template: the required sections, the navigation
   line, and the `<details>` block listing the real files the page came from. Follow
   `references/wiki-template.md` for the section checklist of each page.
   *Exit criterion:* no scaffold placeholder text remains anywhere, and every `<details>` block
   lists paths that exist in the repository.

5. **Deliver and report.** Report the pages produced, the pages omitted by the conditional rules
   and why, and every claim that could not be verified against the source.
   *Exit criterion:* the report names the pages, the omissions and the unverified claims.

The phase-by-phase detail, including the file budget and the escape hatch for an oversized
repository, is in `references/workflow.md`.

## Detection and Page Selection

Detection comes first. Scaffolding every page and deleting the unwanted ones afterwards produces
exactly the empty pages the skill forbids, so the selection is made before the scaffold runs.

| Category | Pages | Rule |
|----------|-------|------|
| Mandatory | Overview, Quick Start, Project Structure, Configuration, Usage, Development | Always created |
| Optional | CLI Commands, API Reference, Installation, Troubleshooting, FAQ, Testing, Contributing | Created only when the detection signal is present |
| Conditional | Deployment, Architecture, Performance, Advanced Topics | Created only when the component exists |

The detection signals, the mandatory-page content sources and the monorepo rules are tabulated in
`references/page-types.md`.

The scaffold's `--pages` option takes the selected page ids as a comma-separated list, so the page
set that was detected is the page set that gets written. `--force` additionally prunes page files
the script previously generated that are no longer in the plan; it never touches a file the script
did not create.

## Analysis and Filtering

**Read in full**: entry points, the package manifests, configuration sources, the public API
surface, the main data models.

**Sample**: test files (read the configuration plus one representative test per suite), example
scripts, documentation files, and any directory holding more than 50 files.

**Never read or quote**: `.env*`, `*.pem`, `*.key`, `*.keystore`, `*.p12`, `*.pfx`, `id_rsa*`,
`id_ed25519*`, `id_ecdsa*`, `credentials*.json`, `*.secret*`, `*.secrets`, `.npmrc`, `.netrc`,
`.pypirc`, and anything under `secrets/`, `credentials/`, `.aws/`, `.ssh/`, `.gnupg/`. Also excluded:
binaries, archives, lockfiles, minified bundles, vendored trees and `dist/`, `build/`, `target/`,
`vendor/`.

A configuration page names the option and describes its effect. The value stays in the repository.

When the repository is too large to read in full, narrow the scope explicitly instead of truncating
silently: analyse the "read in full" set, sample the remainder by directory, and record in the
delivery report which directories were sampled and which claims rest on that sample.

## Localisation

The prose, the page titles and the navigation labels follow the requested language. Identifiers,
paths, commands, environment variables and flag names are never translated — they are copied from
the code exactly.

The scaffold detects `zh` when the query contains CJK ideographs (U+4E00–U+9FFF) and `en`
otherwise. Japanese, Korean, Cyrillic and every other script fall back to `en` — pass `--lang`
explicitly for them. Only `en` and `zh` have localised page titles and UI strings; any other
language gets the English titles and UI.

Page filenames never change with the language. The filename is the zero-padded page id plus the
English title slug — `01-overview.md`, `01-01-quick-start.md`, `02-project-structure.md` — so a
link to a page keeps working in every output language. The localised title lives in the page's H1
and in `index.md`.

## Repository Boundaries

**Read-only repository.** The only directory this skill writes is `docs/openrepowiki/`. Source files,
manifests, CI configuration and lockfiles are inputs, never outputs. Do not commit the wiki; if
the repository does not ignore `docs/openrepowiki/`, say so in the report and let the user decide.

**Conflicts with existing documentation.** When `docs/` or a README contradicts the wiki, record the
contradiction in the report with both locations and cite the source file that settles it. Do not
edit the older document from this skill — hand the correction to `architecture-design` for an ADR
or to `technical-writing` for a design doc, so the repository keeps one authoritative text. When
the entry point is ambiguous, list the candidate files instead of guessing
which one runs.

**Existing `docs/openrepowiki/`.** Existing content is preserved unless `--force` is passed. The report
states what was overwritten.

## Output Contract

The deliverable is a `docs/openrepowiki/` directory containing `index.md` plus one file per selected
page, named exactly as the slug rule above. Each page contains:

- an H1 with the localised title,
- the navigation line linking to the index, the previous page and the next page,
- the page content, following that page's template,
- a `<details>` block listing the real files the page was derived from.

No page is left with a placeholder. Alongside the wiki, the report to the user lists the pages
produced, the pages omitted by the conditional rules and the reason for each omission, and every
claim that could not be verified against the source.

## Guardrails

- Never state a path, command, environment variable or flag that does not exist in the repository —
  every technical claim must be traceable to a file.
- Never quote a secret, a credential or the value of an excluded file; name the option, describe
  the effect.
- Never write outside `docs/openrepowiki/`; never modify a source file; never commit the wiki.
- Never leave a page empty or with scaffold placeholder text.
- Never translate identifiers, paths, commands, environment variables or flag names.
- Never invent a Mermaid diagram — draw one only for a flow read from the code.
- Never claim a fact you did not verify; list it in the report as unverified instead.

## References

| File | Load when |
|------|-----------|
| [references/workflow.md](references/workflow.md) | Running the four phases end to end — detection, scaffolding, analysis, filling, and the delivery report |
| [references/page-types.md](references/page-types.md) | Deciding which pages exist — the detection signals and the mandatory/optional/conditional rules |
| [references/wiki-template.md](references/wiki-template.md) | Writing a page — the section checklist, minimum thresholds and Mermaid rules for each page id |
| [references/scaffold-cli.md](references/scaffold-cli.md) | Running the scaffold — the options, the filename rule, the pruning behaviour and the `--input` JSON schema |

## Verification Checklist

- [ ] Every page in `docs/openrepowiki/` came from a detection signal, and the omitted pages are listed in the report with their reason.
- [ ] `ls docs/openrepowiki/` shows `index.md` and the expected page files, named `01-overview.md`, `01-01-quick-start.md`, `02-project-structure.md`, … — not `1-Overview.md`.
- [ ] The first page's navigation line has no previous, the last page's has no next, and every page between them links to its true neighbours.
- [ ] `grep -r "Scaffold generated from\|path/to/file" docs/openrepowiki/` returns nothing — no placeholder survives.
- [ ] Every path in every `<details>` block exists in the repository (`test -e` each one).
- [ ] No excluded file was read or quoted: no secret values, no `.env` contents, no private key material.
- [ ] Every command, environment variable and flag named on a page appears verbatim in the source.
- [ ] The prose is in one language throughout and technical tokens are untranslated.
- [ ] The report lists the pages produced, the pages omitted with reasons, and the unverified claims.
- [ ] `git status` shows no change to any file outside `docs/openrepowiki/`.
