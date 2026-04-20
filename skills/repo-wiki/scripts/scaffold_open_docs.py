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


@dataclass(slots=True)
class PagePlan:
    page_id: str
    title: str


REQUIRED_PAGE_IDS = (
    "1", "1.1",
    "2", "2.1", "2.2",
    "3", "3.1",
    "4", "4.1", "4.2",
    "5", "5.1", "5.2",
)

CONDITIONAL_PAGE_IDS = frozenset(("3.2", "5.3", "6", "6.1"))

TEMPLATE_PAGE_IDS = REQUIRED_PAGE_IDS + tuple(CONDITIONAL_PAGE_IDS)

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

_LANG_RANGES = (
    (0x3040, 0x30FF, "ja"),
    (0xAC00, 0xD7AF, "ko"),
    (0x4E00, 0x9FFF, "zh"),
    (0x0400, 0x04FF, "ru"),
)


def detect_language_from_query(query: str) -> str:
    if not query:
        return "en"
    for ch in query:
        cp = ord(ch)
        for start, end, lang in _LANG_RANGES:
            if start <= cp <= end:
                return lang
    return "en"


def parse_page_id(page_id: str) -> tuple[int, ...]:
    parts = page_id.strip().split(".")
    return tuple(int(p) if p.isdigit() else 10**9 for p in parts)


def safe_filename(name: str, max_len: int = 120) -> str:
    name = name.strip()
    name = _INVALID_FILENAME_RE.sub("-", name)
    name = _WHITESPACE_RE.sub(" ", name).strip()
    name = name.replace(" ", "-")
    name = _MULTI_DASH_RE.sub("-", name).strip("-")
    return name[:max_len] if name else "page"


def _select_wiki_bundle(wikis: dict, lang: str) -> tuple[str, dict]:
    if lang in wikis:
        return lang, wikis[lang]
    base = lang.split("-")[0]
    if base in wikis:
        return base, wikis[base]
    first = next(iter(wikis.keys()))
    return first, wikis[first]


def _get_localized_titles(lang: str) -> dict[str, str]:
    base = lang.split("-")[0]
    return PAGE_TITLES.get(lang) or PAGE_TITLES.get(base) or PAGE_TITLES["en"]


def _get_ui_text(lang: str) -> dict[str, str]:
    base = lang.split("-")[0]
    return UI_TEXT.get(lang) or UI_TEXT.get(base) or UI_TEXT["en"]


def load_page_plans(input_path: Path, lang: str) -> tuple[str, list[PagePlan]]:
    data = json.loads(input_path.read_text(encoding="utf-8"))
    wiki = data.get("wiki") or {}
    wikis = wiki.get("wikis") or {}
    if not isinstance(wikis, dict) or not wikis:
        raise ValueError("Invalid JSON: missing wiki.wikis")

    chosen_lang, bundle = _select_wiki_bundle(wikis, lang=lang)
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
        plans = [PagePlan(pid, titles.get(pid, PAGE_TITLES["en"].get(pid, pid))) for pid in TEMPLATE_PAGE_IDS]
    elif plans[0].page_id not in TEMPLATE_PAGE_IDS:
        plans = [PagePlan(pid, titles.get(pid, PAGE_TITLES["en"].get(pid, pid))) for pid in TEMPLATE_PAGE_IDS]
    else:
        plans = [
            PagePlan(p.page_id, titles.get(p.page_id) or p.title or PAGE_TITLES["en"].get(p.page_id, p.page_id))
            for p in plans
        ]

    plans.sort(key=lambda p: parse_page_id(p.page_id))
    return chosen_lang, plans


def default_page_plans(lang: str) -> tuple[str, list[PagePlan]]:
    titles = _get_localized_titles(lang)
    plans = [PagePlan(pid, titles.get(pid, PAGE_TITLES["en"].get(pid, pid))) for pid in REQUIRED_PAGE_IDS]
    return lang, plans


def plan_to_filename(plan: PagePlan) -> str:
    prefix = safe_filename(plan.page_id.replace(".", "-"))
    title = safe_filename(plan.title or plan.page_id or "Untitled")
    return f"{prefix}-{title}.md"


def build_nav_line(plans: list[PagePlan], index: int, ui: dict[str, str]) -> str:
    parts = [f"[{ui['nav_index']}](index.md)"]

    if index > 0:
        prev = plans[index - 1]
        parts.append(f"{ui['nav_prev']}: [{prev.title or prev.page_id}]({plan_to_filename(prev)})")

    if index + 1 < len(plans):
        nxt = plans[index + 1]
        parts.append(f"{ui['nav_next']}: [{nxt.title or nxt.page_id}]({plan_to_filename(nxt)})")

    return f"**{ui['nav_label']}**: " + " | ".join(parts)


def write_scaffold(output_dir: Path, plans: list[PagePlan], force: bool, lang: str) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    ui = _get_ui_text(lang)

    index_lines = [f"# {ui['index_title']}", ""]
    for plan in plans:
        filename = plan_to_filename(plan)
        index_lines.append(f"- [{plan.title or plan.page_id}]({filename})")

        out_path = output_dir / filename
        if out_path.exists() and not force:
            continue

        nav_line = build_nav_line(plans=plans, index=plans.index(plan), ui=ui)
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

    lang = args.lang if args.lang != "auto" else detect_language_from_query(args.query)

    if args.input and Path(args.input).exists():
        _, plans = load_page_plans(input_path=Path(args.input), lang=lang)
    else:
        _, plans = default_page_plans(lang=lang)
        if args.input:
            sys.stderr.write(f"Input JSON not found, using bundled template: {args.input}\n")

    write_scaffold(output_dir=Path(args.output).resolve(), plans=plans, force=bool(args.force), lang=lang)

    out_path = Path(args.output).resolve()
    sys.stderr.write(f"Scaffolded {len(plans)} pages in {out_path} (lang: {lang})\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
