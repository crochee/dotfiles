#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# ///
"""Scaffold the repo-wiki page tree into an output directory.

Requires Python 3.10+ (`dataclass(slots=True)`, PEP 604 runtime annotations).

    python3 scaffold_open_docs.py --query "Python CLI tool" --output docs/openrepowiki
    python3 scaffold_open_docs.py --pages 1,1.1,2,3 --lang zh --force

Page filenames are language independent: the numeric page id is zero padded to
two digits and joined with "-", followed by the lower-cased English page title
(`01-overview.md`, `01-01-quick-start.md`, ...). The localised title lives in the
page H1 and in `index.md`, so a link to a page keeps working in every language.
"""

import argparse
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path

TEMPLATE_RELATIVE_PATH = "references/wiki-template.md"

_INVALID_FILENAME_RE = re.compile(r"[<>:\"/\\|?*\x00-\x1f]")
_MULTI_DASH_RE = re.compile(r"-+")
_WHITESPACE_RE = re.compile(r"\s+")
_PAGE_ID_RE = re.compile(r"^\d+(\.\d+)*$")
# Names this script generates: two-digit id parts, lower-case slug. A file that
# does not match this shape is never pruned, so hand-written files survive.
_GENERATED_NAME_RE = re.compile(r"^\d{2}(?:-\d{2})*-[a-z0-9]+(?:-[a-z0-9]+)*\.md$")

_LANG_RANGES = (
    (0x4E00, 0x9FFF, "zh"),
)


class ScaffoldError(RuntimeError):
    """Unrecoverable scaffold failure; reported on stderr with a non-zero exit."""


@dataclass(slots=True)
class PagePlan:
    page_id: str
    title: str


PAGE_TITLES: dict[str, dict[str, str]] = {
    "en": {
        "1": "Overview",
        "1.1": "Quick Start",
        "2": "Project Structure",
        "2.1": "CLI Commands",
        "2.2": "API Reference",
        "3": "Configuration",
        "3.1": "Installation",
        "3.2": "Deployment",
        "4": "Usage",
        "4.1": "Troubleshooting",
        "4.2": "FAQ",
        "5": "Development",
        "5.1": "Testing",
        "5.2": "Contributing",
        "5.3": "Architecture",
        "6": "Advanced Topics",
        "6.1": "Performance",
    },
    "zh": {
        "1": "概述",
        "1.1": "快速开始",
        "2": "项目结构",
        "2.1": "命令行接口",
        "2.2": "API 参考",
        "3": "配置",
        "3.1": "安装",
        "3.2": "部署",
        "4": "使用指南",
        "4.1": "故障排查",
        "4.2": "常见问题",
        "5": "开发指南",
        "5.1": "测试",
        "5.2": "贡献指南",
        "5.3": "架构设计",
        "6": "高级主题",
        "6.1": "性能优化",
    },
}

UI_TEXT: dict[str, dict[str, str]] = {
    "en": {
        "index_title": "Wiki Index",
        "nav_label": "Navigation",
        "nav_index": "Wiki Index",
        "nav_prev": "Previous",
        "nav_next": "Next",
        "relevant_files_summary": "Relevant source files",
        "scaffold_note_1": "Scaffold generated from the bundled wiki template.",
        "scaffold_note_2": "Fill this page with content grounded in the current repository.",
        "relevant_files_placeholder": "- `path/to/file`",
    },
    "zh": {
        "index_title": "Wiki 目录",
        "nav_label": "导航",
        "nav_index": "Wiki 目录",
        "nav_prev": "上一页",
        "nav_next": "下一页",
        "relevant_files_summary": "相关源码文件",
        "scaffold_note_1": "此页为模板脚手架自动生成。",
        "scaffold_note_2": "请基于当前仓库的代码/配置/文档补全内容。",
        "relevant_files_placeholder": "- `path/to/file`",
    },
}

FALLBACK_TITLES = PAGE_TITLES["en"]
FALLBACK_UI = UI_TEXT["en"]


def detect_language_from_query(query: str) -> str:
    """Return "zh" when the query contains CJK ideographs, otherwise "en".

    Only the CJK Unified Ideographs block (U+4E00-U+9FFF) is detected. Kana,
    Hangul and Cyrillic fall back to "en"; pass --lang explicitly for those.
    """
    if not query:
        return "en"
    for ch in query:
        cp = ord(ch)
        for start, end, lang in _LANG_RANGES:
            if start <= cp <= end:
                return lang
    return "en"


def load_page_ids_from_template(skill_dir: Path) -> list[str]:
    """Return the page ids declared as "### <id> <Title>" headings in the template."""
    template_path = skill_dir / TEMPLATE_RELATIVE_PATH
    if not template_path.exists():
        raise ScaffoldError(
            f"missing {TEMPLATE_RELATIVE_PATH} (looked in {template_path}); "
            "the repo-wiki skill installation is incomplete"
        )
    text = template_path.read_text(encoding="utf-8")
    ids = set()
    for m in re.finditer(r"^###\s+(\d(?:\.\d+)*)\.?\s", text, re.MULTILINE):
        candidate = m.group(1)
        if _PAGE_ID_RE.match(candidate):
            ids.add(candidate)
    if not ids:
        raise ScaffoldError(
            f"no page ids found in {TEMPLATE_RELATIVE_PATH} ({template_path}); "
            "the template must declare one '### <id> <Title>' heading per page"
        )
    return sorted(ids, key=parse_page_id)


def parse_page_id(page_id: str) -> tuple[int, ...]:
    if not _PAGE_ID_RE.match(page_id):
        raise ValueError(f"Invalid page ID: {page_id!r}")
    return tuple(int(p) for p in page_id.split("."))


def safe_filename(name: str, max_len: int = 120) -> str:
    name = name.strip()
    name = _INVALID_FILENAME_RE.sub("-", name)
    name = _WHITESPACE_RE.sub(" ", name).strip()
    name = name.replace(" ", "-")
    name = _MULTI_DASH_RE.sub("-", name).strip("-")
    return name[:max_len] if name else "page"


def _resolve_dict(lang_key: str, primary: dict[str, dict], fallback: dict[str, str]) -> dict[str, str]:
    base = lang_key.split("-")[0]
    result = primary.get(lang_key)
    if result is None:
        result = primary.get(base)
    if result is None:
        return fallback
    return result


def _get_localized_titles(lang: str) -> dict[str, str]:
    return _resolve_dict(lang, PAGE_TITLES, FALLBACK_TITLES)


def _get_ui_text(lang: str) -> dict[str, str]:
    return _resolve_dict(lang, UI_TEXT, FALLBACK_UI)


def _resolve_language_and_bundle(wikis: dict, lang: str) -> tuple[str, dict]:
    """Resolve language key and corresponding bundle from wikis dict.

    Returns (chosen_lang, bundle) where chosen_lang is the actual language
    key used and bundle is the wikis[lang] content dict.
    """
    if lang in wikis:
        return lang, wikis[lang]
    base = lang.split("-")[0]
    if base in wikis:
        return base, wikis[base]
    fallback_key = next(iter(wikis.keys()))
    return fallback_key, wikis[fallback_key]


def _load_page_plans_from_json(input_path: Path, lang: str, skill_dir: Path) -> tuple[str, list[PagePlan]]:
    valid_ids = set(load_page_ids_from_template(skill_dir))
    data = json.loads(input_path.read_text(encoding="utf-8"))
    wiki = data.get("wiki") or {}
    wikis = wiki.get("wikis") or {}
    if not isinstance(wikis, dict) or not wikis:
        raise ValueError("Invalid JSON: missing wiki.wikis")

    chosen_lang, bundle = _resolve_language_and_bundle(wikis, lang)

    pages_raw = bundle.get("pages") or []
    titles = _get_localized_titles(chosen_lang)

    plans = [
        PagePlan(
            page_id=str((item or {}).get("page_plan", {}).get("id") or "").strip(),
            title=str((item or {}).get("page_plan", {}).get("title") or "").strip(),
        )
        for item in pages_raw
        if (item or {}).get("page_plan")
    ]

    if not plans:
        sys.stderr.write(f"Warning: no page_plan entries found in {input_path}, using bundled template\n")
        return _make_fallback_plans(chosen_lang, valid_ids)

    valid_plans = [p for p in plans if p.page_id in valid_ids]
    invalid = [p.page_id for p in plans if not p.page_id or p.page_id not in valid_ids]
    if invalid:
        sys.stderr.write(f"Warning: unrecognized page IDs skipped: {invalid}\n")

    if not valid_plans:
        sys.stderr.write("Warning: no valid page IDs remain, using bundled template\n")
        return _make_fallback_plans(chosen_lang, valid_ids)

    plans = [
        PagePlan(p.page_id, titles.get(p.page_id) or p.title or FALLBACK_TITLES.get(p.page_id, p.page_id))
        for p in valid_plans
    ]
    plans.sort(key=lambda p: parse_page_id(p.page_id))
    return chosen_lang, plans


def _make_fallback_plans(lang: str, valid_ids: set[str]) -> tuple[str, list[PagePlan]]:
    titles = _get_localized_titles(lang)
    ids = sorted(valid_ids, key=parse_page_id)
    plans = [PagePlan(pid, titles.get(pid, FALLBACK_TITLES.get(pid, pid))) for pid in ids]
    return lang, plans


def default_page_plans(lang: str, skill_dir: Path) -> tuple[str, list[PagePlan]]:
    valid_ids = load_page_ids_from_template(skill_dir)
    titles = _get_localized_titles(lang)
    ids = sorted(valid_ids, key=parse_page_id)
    plans = [PagePlan(pid, titles.get(pid, FALLBACK_TITLES.get(pid, pid))) for pid in ids]
    return lang, plans


def _compute_id_width(plans: list[PagePlan]) -> int:
    """Width of the zero-padded id parts. Never below two digits."""
    max_val = 0
    for plan in plans:
        for part in plan.page_id.split("."):
            if part.isdigit():
                max_val = max(max_val, int(part))
    return max(2, len(str(max_val)))


def _zero_padded_id(page_id: str, width: int) -> str:
    parts = page_id.split(".")
    return "-".join(p.zfill(width) for p in parts)


def page_slug(plan: PagePlan) -> str:
    """Language-independent file slug: the English page title, lower-cased.

    The English fallback title is used on purpose: a filename that changes with
    --lang breaks every link to it.
    """
    english_title = FALLBACK_TITLES.get(plan.page_id) or plan.title or plan.page_id or "Untitled"
    return safe_filename(english_title).lower()


def plan_to_filename(plan: PagePlan, width: int) -> str:
    prefix = _zero_padded_id(plan.page_id, width)
    return f"{prefix}-{page_slug(plan)}.md"


def build_nav_line(plans: list[PagePlan], index: int, ui: dict[str, str], width: int) -> str:
    """Navigation line for the page at 0-based `index` in `plans`."""
    parts = [f"[{ui['nav_index']}](index.md)"]

    if index > 0:
        prev = plans[index - 1]
        parts.append(f"{ui['nav_prev']}: [{prev.title or prev.page_id}]({plan_to_filename(prev, width)})")

    if index + 1 < len(plans):
        nxt = plans[index + 1]
        parts.append(f"{ui['nav_next']}: [{nxt.title or nxt.page_id}]({plan_to_filename(nxt, width)})")

    return f"**{ui['nav_label']}**: " + " | ".join(parts)


def prune_stale_pages(output_dir: Path, keep: set[str], universe: set[str]) -> list[str]:
    """Delete previously generated pages that are not in the current plan.

    Only files whose name is in `universe` -- the exact filenames this script
    can generate for the template's page ids -- are considered, so a file the
    user wrote by hand is never removed.
    """
    removed: list[str] = []
    for path in sorted(output_dir.iterdir()):
        if not path.is_file() or path.name == "index.md":
            continue
        if not _GENERATED_NAME_RE.match(path.name):
            continue
        if path.name not in universe or path.name in keep:
            continue
        path.unlink()
        removed.append(path.name)
    return removed


def write_scaffold(
    output_dir: Path,
    plans: list[PagePlan],
    force: bool,
    lang: str,
    width: int,
    universe: set[str],
) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    ui = _get_ui_text(lang)

    if force:
        removed = prune_stale_pages(output_dir, {plan_to_filename(p, width) for p in plans}, universe)
        if removed:
            sys.stderr.write(f"Pruned {len(removed)} previously generated page(s): {removed}\n")

    index_lines = [f"# {ui['index_title']}", ""]
    for idx, plan in enumerate(plans, start=1):
        filename = plan_to_filename(plan, width)
        index_lines.append(f"{idx}. [{plan.title or plan.page_id}]({filename})")

        out_path = output_dir / filename
        if out_path.exists() and not force:
            continue

        nav_line = build_nav_line(plans=plans, index=idx - 1, ui=ui, width=width)
        content = "\n".join([
            f"# {plan.title}",
            "",
            nav_line,
            "",
            f"> {ui['scaffold_note_1']}",
            f"> {ui['scaffold_note_2']}",
            "",
            "<details>",
            f"<summary>{ui['relevant_files_summary']}</summary>",
            "",
            ui["relevant_files_placeholder"],
            "",
            "</details>",
            "",
        ])
        out_path.write_text(content, encoding="utf-8")

    (output_dir / "index.md").write_text("\n".join(index_lines).rstrip() + "\n", encoding="utf-8")


def select_pages(plans: list[PagePlan], requested: str) -> list[PagePlan]:
    """Filter plans by a comma-separated list of page ids.

    The match is exact: "2" selects the Project Structure page and nothing else,
    so the caller stays in control of which pages exist.
    """
    wanted = [part.strip() for part in requested.split(",") if part.strip()]
    known = {p.page_id for p in plans}
    unknown = [pid for pid in wanted if pid not in known]
    if unknown:
        sys.stderr.write(f"Warning: unknown page IDs skipped: {unknown}\n")
    selected = {pid for pid in wanted if pid in known}
    return [p for p in plans if p.page_id in selected]


def template_filename_universe(skill_dir: Path) -> tuple[int, set[str]]:
    """Return (id width, every filename this script can generate).

    The width and the filename set are derived from the full template page list,
    not from the selected subset, so a page keeps the same filename when the
    selection changes and pruning can never touch a hand-written file.
    """
    ids = load_page_ids_from_template(skill_dir)
    all_plans = [PagePlan(pid, FALLBACK_TITLES.get(pid, pid)) for pid in ids]
    width = _compute_id_width(all_plans)
    universe = {plan_to_filename(plan, width) for plan in all_plans}
    return width, universe


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="scaffold_open_docs.py",
        description="Scaffold the docs/openrepowiki page tree for the repo-wiki skill.",
    )
    parser.add_argument("--input", default="", help="Optional path to an external wiki JSON file.")
    parser.add_argument("--output", default="docs/openrepowiki", help="Output directory (default: ./docs/openrepowiki)")
    parser.add_argument("--lang", default="auto", help="Language code (e.g. en, zh). Use 'auto' to detect from --query.")
    parser.add_argument("--query", default="", help="User query for language auto-detection.")
    parser.add_argument("--pages", default="", help="Comma-separated page ids to scaffold (default: every page).")
    parser.add_argument("--force", action="store_true", help="Overwrite existing page files and prune pages that left the plan.")

    args = parser.parse_args(argv)

    skill_dir = Path(__file__).resolve().parent.parent
    requested_lang = args.lang if args.lang != "auto" else detect_language_from_query(args.query)

    try:
        width, universe = template_filename_universe(skill_dir)

        if args.input and Path(args.input).exists():
            try:
                chosen_lang, plans = _load_page_plans_from_json(
                    input_path=Path(args.input), lang=requested_lang, skill_dir=skill_dir
                )
            except (json.JSONDecodeError, OSError, UnicodeDecodeError, ValueError) as exc:
                sys.stderr.write(
                    f"Warning: could not read {args.input} ({exc}); using the bundled template\n"
                )
                chosen_lang, plans = default_page_plans(lang=requested_lang, skill_dir=skill_dir)
        else:
            if args.input:
                sys.stderr.write(f"Warning: input JSON not found, using bundled template: {args.input}\n")
            chosen_lang, plans = default_page_plans(lang=requested_lang, skill_dir=skill_dir)

        if args.pages:
            plans = select_pages(plans, args.pages)
            if not plans:
                sys.stderr.write("Error: --pages selected no known page IDs\n")
                return 2

        if not plans:
            sys.stderr.write(
                f"Error: no page templates available in {TEMPLATE_RELATIVE_PATH}; "
                "cannot scaffold an empty wiki\n"
            )
            return 2
    except ScaffoldError as exc:
        sys.stderr.write(f"Error: {exc}\n")
        return 2

    out_path = Path(args.output).resolve()
    write_scaffold(
        output_dir=out_path,
        plans=plans,
        force=bool(args.force),
        lang=chosen_lang,
        width=width,
        universe=universe,
    )

    sys.stderr.write(f"Scaffolded {len(plans)} pages in {out_path} (lang: {chosen_lang})\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
