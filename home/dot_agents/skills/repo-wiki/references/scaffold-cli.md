# Scaffold CLI Contract

**Load this reference when:** running `scripts/scaffold_open_docs.py`, choosing pages, or wiring an external page plan into the scaffold.

`scripts/scaffold_open_docs.py` creates the `docs/openrepowiki/` page tree. It only creates files — it never reads the repository it scaffolds for, so the page selection has to come from the detection step (see the workflow reference).

## Contents

- [Invocation](#invocation)
- [Options](#options)
- [Page id and filename rules](#page-id-and-filename-rules)
- [Pruning](#pruning)
- [`--input` JSON schema](#--input-json-schema)
- [Language detection](#language-detection)

## Invocation

```bash
# run from the directory containing SKILL.md
python3 scripts/scaffold_open_docs.py \
  --query "Python CLI tool" \
  --output docs/openrepowiki
```

Requires Python 3.10 or newer (`dataclass(slots=True)` and PEP 604 annotations). The script also carries a PEP-723 header, so `uv run scripts/scaffold_open_docs.py ...` works without a virtualenv.

## Options

| Option | Type | Default | Effect |
|--------|------|---------|--------|
| `--query` | string | `""` | Free-text description of the project. Used for language auto-detection only; it does not change the page set. |
| `--lang` | string | `"auto"` | Output language. `auto` resolves from `--query`. Any other value is used verbatim. |
| `--pages` | string | `""` (every page) | Comma-separated page ids to scaffold, e.g. `1,1.1,2,3`. Unknown ids are reported on stderr and skipped. |
| `--output` | path | `docs/openrepowiki` | Directory the wiki is written to. Created if missing. |
| `--input` | path | `""` | Optional JSON file describing an externally produced page plan. |
| `--force` | flag | off | Overwrite existing page files and prune pages that left the plan. |

Exit code `0` on success, `2` on a hard error (no page templates, unknown `--pages` selection, missing template file).

## Page id and filename rules

Page ids are the dotted numbers in the template headings: `1`, `1.1`, `2`, `2.1`, `2.2`, `3`, `3.1`, `3.2`, `4`, `4.1`, `4.2`, `5`, `5.1`, `5.2`, `5.3`, `6`, `6.1`.

A filename is the zero-padded id (two digits per part, joined with `-`) followed by the **English** page title, slugified and lower-cased:

```
<id>                      1.1
<zero-padded id>          01-01
<english title>           Quick Start
<slug>                    quick-start
<file name>               01-01-quick-start.md
```

The slug comes from the English title even when `--lang zh` is used, because a filename that changes with the output language breaks every link to it. The localised title lives in the page's H1 and in `index.md` instead.

The full set of generated names:

```
01-overview.md            02-01-cli-commands.md     03-01-installation.md
01-01-quick-start.md      02-02-api-reference.md    03-02-deployment.md
02-project-structure.md   03-configuration.md        04-usage.md
                                                      04-01-troubleshooting.md
                                                      04-02-faq.md
                                                      05-development.md
                                                      05-01-testing.md
                                                      05-02-contributing.md
                                                      05-03-architecture.md
                                                      06-advanced-topics.md
                                                      06-01-performance.md
```

`index.md` is the index page and is always written.

## Pruning

`--force` deletes page files in the output directory that the script itself could have generated but that are no longer in the plan. A file is only deleted when its name is in the generated-name set, so a hand-written page or a note file in `docs/openrepowiki/` is never removed. Without `--force` nothing is deleted.

## `--input` JSON schema

The scaffold script accepts an optional `--input` JSON file for external wiki data integration (e.g. scraped from an existing documentation system).

```json
{
  "wiki": {
    "wikis": {
      "en": {
        "pages": [
          { "page_plan": { "id": "1", "title": "Overview" } },
          { "page_plan": { "id": "1.1", "title": "Quick Start" } }
        ]
      },
      "zh": {
        "pages": [
          { "page_plan": { "id": "1", "title": "概述" } },
          { "page_plan": { "id": "1.1", "title": "快速开始" } }
        ]
      }
    }
  }
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `wiki.wikis` | object | yes | Language-keyed dictionary. Keys: `"en"`, `"zh"`, or any locale code. |
| `wikis.<lang>.pages` | array | yes | Ordered list of page entries for this language. |
| `pages[].page_plan` | object | yes | Page definition wrapper. |
| `page_plan.id` | string | yes | Page id matching a `### <id>` heading in the page-template reference, e.g. `"1"`, `"2.1"`. |
| `page_plan.title` | string | yes | Human-readable page title, used in the navigation line and in `index.md`. |

The language bundle is selected by `--lang`; when `--lang` names a bundle that is absent, the first bundle in the file is used, and the resolved language drives the page titles, the navigation labels and the UI strings. The filenames do not change with the language.

If the file is missing, unreadable, malformed, or contains no recognisable page ids, the script prints a warning on stderr and falls back to the bundled template. It does not abort.

```bash
python3 scripts/scaffold_open_docs.py \
  --input ./scraped_wiki.json --query "Chinese project" --output docs/openrepowiki
```

## Language detection

The script detects **Chinese (`zh`)** and **English (`en`)** only. Detection uses the Unicode range `0x4E00-0x9FFF` (CJK Unified Ideographs).

- A query containing CJK ideographs is detected as `zh`.
- Every other query defaults to `en`.
- For other languages (Japanese, Korean, Russian, …) pass `--lang` explicitly. UI strings and page titles fall back to English when no translation exists.

Only `en` and `zh` have localised page titles and UI strings; adding another language means adding entries to `PAGE_TITLES` and `UI_TEXT` in the script.
