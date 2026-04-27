#!/usr/bin/env python3
import argparse
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path

_INVALID_FILENAME_RE = re.compile(r"[<>:\"'/\\|?*\x00-\x1f]")
_MULTI_DASH_RE = re.compile(r"-+")
_WHITESPACE_RE = re.compile(r"\s+")
_PAGE_ID_RE = re.compile(r"^\d+(\.\d+)*$")

_LANG_RANGES = (
    (0x4E00, 0x9FFF, "zh"),
)


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
    if not query:
        return "en"
    for ch in query:
        cp = ord(ch)
        for start, end, lang in _LANG_RANGES:
            if start <= cp <= end:
                return lang
    return "en"


def load_page_ids_from_template(skill_dir: Path) -> list[str]:
    template_path = skill_dir / "references" / "wiki-template.md"
    if not template_path.exists():
        return []
    text = template_path.read_text(encoding="utf-8")
    ids = set()
    for m in re.finditer(r"^###\s+(\d(?:\.\d+)*)\.?\s", text, re.MULTILINE):
        candidate = m.group(1)
        if _PAGE_ID_RE.match(candidate):
            ids.add(candidate)
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
    result = primary.get(lang_key) or primary.get(base)
    if not result:
        return fallback
    return result


def _get_localized_titles(lang: str) -> dict[str, str]:
    return _resolve_dict(lang, PAGE_TITLES, FALLBACK_TITLES)


def _get_ui_text(lang: str) -> dict[str, str]:
    return _resolve_dict(lang, UI_TEXT, FALLBACK_UI)


def _load_page_plans_from_json(input_path: Path, lang: str, skill_dir: Path) -> tuple[str, list[PagePlan]]:
    valid_ids = set(load_page_ids_from_template(skill_dir))
    data = json.loads(input_path.read_text(encoding="utf-8"))
    wiki = data.get("wiki") or {}
    wikis = wiki.get("wikis") or {}
    if not isinstance(wikis, dict) or not wikis:
        raise ValueError("Invalid JSON: missing wiki.wikis")

    bundle = wikis.get(lang) or wikis.get(lang.split("-")[0]) or next(iter(wikis.values()))
    chosen_lang = lang if lang in wikis else (lang.split("-")[0] if lang.split("-")[0] in wikis else next(iter(wikis.keys())))

    pages_raw = bundle.get("pages") or []
    titles = _get_localized_titles(lang)

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
        return _make_fallback_plans(lang, valid_ids)

    valid_plans = [p for p in plans if p.page_id in valid_ids]
    invalid = [p.page_id for p in plans if not p.page_id or p.page_id not in valid_ids]
    if invalid:
        sys.stderr.write(f"Warning: unrecognized page IDs skipped: {invalid}\n")

    if not valid_plans:
        sys.stderr.write("Warning: no valid page IDs remain, using bundled template\n")
        return _make_fallback_plans(lang, valid_ids)

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
    max_val = 0
    for plan in plans:
        for part in plan.page_id.split("."):
            if part.isdigit():
                max_val = max(max_val, int(part))
    return max(1, len(str(max_val)))


def _zero_padded_id(page_id: str, width: int) -> str:
    parts = page_id.split(".")
    return "-".join(p.zfill(width) for p in parts)


def plan_to_filename(plan: PagePlan, width: int) -> str:
    prefix = _zero_padded_id(plan.page_id, width)
    title = safe_filename(plan.title or plan.page_id or "Untitled")
    return f"{prefix}-{title}.md"


def build_nav_line(plans: list[PagePlan], index: int, ui: dict[str, str], width: int) -> str:
    parts = [f"[{ui['nav_index']}](index.md)"]

    if index > 0:
        prev = plans[index - 1]
        parts.append(f"{ui['nav_prev']}: [{prev.title or prev.page_id}]({plan_to_filename(prev, width)})")

    if index + 1 < len(plans):
        nxt = plans[index + 1]
        parts.append(f"{ui['nav_next']}: [{nxt.title or nxt.page_id}]({plan_to_filename(nxt, width)})")

    return f"**{ui['nav_label']}**: " + " | ".join(parts)


def write_scaffold(output_dir: Path, plans: list[PagePlan], force: bool, lang: str) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    ui = _get_ui_text(lang)
    width = _compute_id_width(plans)

    index_lines = [f"# {ui['index_title']}", ""]
    for idx, plan in enumerate(plans, start=1):
        filename = plan_to_filename(plan, width)
        index_lines.append(f"{idx}. [{plan.title or plan.page_id}]({filename})")

        out_path = output_dir / filename
        if out_path.exists() and not force:
            continue

        nav_line = build_nav_line(plans=plans, index=idx, ui=ui, width=width)
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


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Scaffold .open_docs using the repo-wiki template."
    )
    parser.add_argument("--input", default="", help="Optional path to scraped wiki JSON.")
    parser.add_argument("--output", default=".open_docs", help="Output directory (default: ./.open_docs)")
    parser.add_argument("--lang", default="auto", help="Language code (e.g. en, zh). Use 'auto' to detect from --query.")
    parser.add_argument("--query", default="", help="User query for language auto-detection.")
    parser.add_argument("--force", action="store_true", help="Overwrite existing page files.")

    args = parser.parse_args(argv)

    skill_dir = Path(__file__).resolve().parent.parent

    lang = args.lang if args.lang != "auto" else detect_language_from_query(args.query)

    if args.input and Path(args.input).exists():
        _, plans = _load_page_plans_from_json(input_path=Path(args.input), lang=lang, skill_dir=skill_dir)
    else:
        _, plans = default_page_plans(lang=lang, skill_dir=skill_dir)
        if args.input:
            sys.stderr.write(f"Input JSON not found, using bundled template: {args.input}\n")

    write_scaffold(output_dir=Path(args.output).resolve(), plans=plans, force=bool(args.force), lang=lang)

    out_path = Path(args.output).resolve()
    sys.stderr.write(f"Scaffolded {len(plans)} pages in {out_path} (lang: {lang})\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
