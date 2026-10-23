#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "python-docx>=1.1.0",
# ]
# ///
"""docx <-> markdown conversion tool.

Both directions are supported:

    uv run scripts/docx_convert.py input.docx                # docx -> md
    uv run scripts/docx_convert.py input.docx -o output.md   # docx -> md (custom output)
    uv run scripts/docx_convert.py input.md                  # md -> docx
    uv run scripts/docx_convert.py input.md -o output.docx   # md -> docx (custom output)

Overwrite semantics: an existing output file is replaced without confirmation.
The tool refuses to write the converted file over its own input file, because
that would destroy the source (a .docx binary written over the .md source, or
the reverse).

Lossy by design: images, signatures and scanned pages have no markdown
equivalent and are dropped. The tool reports how many images were dropped so
the caller can decide whether the document can be reviewed at all.
"""

import argparse
import re
import sys
import zipfile
from pathlib import Path

try:
    from docx import Document
    from docx.opc.constants import RELATIONSHIP_TYPE as RT
    from docx.opc.exceptions import PackageNotFoundError
    from docx.oxml import OxmlElement
    from docx.oxml.ns import qn
    from docx.text.run import Run

    DOCX_IMPORT_ERROR: Exception | None = None
except ModuleNotFoundError as exc:  # python-docx missing (no `uv run`)
    Document = None  # type: ignore[assignment]
    RT = None  # type: ignore[assignment]
    PackageNotFoundError = Exception  # type: ignore[assignment,misc]
    OxmlElement = None  # type: ignore[assignment]
    qn = None  # type: ignore[assignment]
    Run = None  # type: ignore[assignment]
    DOCX_IMPORT_ERROR = exc


MISSING_DOCX_MESSAGE = (
    "Error: python-docx not installed. Run this script with: "
    "uv run scripts/docx_convert.py ..."
)

MAX_HEADING_LEVEL = 9


class ConversionError(Exception):
    """A user-facing failure that should be reported without a traceback."""


def _require_docx() -> None:
    """Abort with an actionable message when python-docx is not importable."""
    if DOCX_IMPORT_ERROR is not None:
        print(MISSING_DOCX_MESSAGE, file=sys.stderr)
        raise SystemExit(1)


def _open_document(docx_path: Path):
    """Open a .docx, converting corrupt/encrypted files into a clear error."""
    try:
        return Document(str(docx_path))
    except PackageNotFoundError as exc:
        raise ConversionError(
            f"Error: cannot open '{docx_path}' as a .docx file: {exc}. "
            "The file is not a Word document, or it is corrupted or encrypted."
        ) from exc
    except (zipfile.BadZipFile, KeyError, ValueError) as exc:
        raise ConversionError(
            f"Error: cannot open '{docx_path}' as a .docx file: {exc}. "
            "The file is corrupted, encrypted, or password protected."
        ) from exc


# --------------------------------------------------------------------------
# docx -> markdown
# --------------------------------------------------------------------------


def _parse_numbering(doc) -> dict[int, dict[int, str]]:
    """Map numId -> {ilvl: numFmt} from the document's numbering part."""
    result: dict[int, dict[int, str]] = {}
    try:
        numbering = doc.part.numbering_part.element
    except KeyError:  # no numbering relationship in the package
        return result

    abstract: dict[str, dict[int, str]] = {}
    for abs_num in numbering.findall(qn("w:abstractNum")):
        abs_id = abs_num.get(qn("w:abstractNumId"))
        if abs_id is None:
            continue
        levels: dict[int, str] = {}
        for lvl in abs_num.findall(qn("w:lvl")):
            try:
                ilvl = int(lvl.get(qn("w:ilvl")) or 0)
            except ValueError:
                ilvl = 0
            fmt_el = lvl.find(qn("w:numFmt"))
            levels[ilvl] = fmt_el.get(qn("w:val")) if fmt_el is not None else "decimal"
        abstract[abs_id] = levels

    for num in numbering.findall(qn("w:num")):
        num_id = num.get(qn("w:numId"))
        if num_id is None:
            continue
        abs_ref = num.find(qn("w:abstractNumId"))
        abs_id = abs_ref.get(qn("w:val")) if abs_ref is not None else None
        result[int(num_id)] = abstract.get(abs_id or "", {})
    return result


def _list_kind(para, num_formats: dict[int, dict[int, str]]) -> str | None:
    """Return 'ordered', 'bullet' or None for a paragraph.

    Numbering is read from the paragraph properties (w:numPr), so real Word
    numbered lists are not mistaken for bullets; the style name is only a
    fallback for documents that carry no numbering definition.
    """
    p_pr = para._p.pPr
    if p_pr is not None:
        num_pr = p_pr.find(qn("w:numPr"))
        if num_pr is not None:
            num_id_el = num_pr.find(qn("w:numId"))
            ilvl_el = num_pr.find(qn("w:ilvl"))
            try:
                num_id = int(num_id_el.get(qn("w:val"))) if num_id_el is not None else 0
            except (TypeError, ValueError):
                num_id = 0
            try:
                ilvl = int(ilvl_el.get(qn("w:val"))) if ilvl_el is not None else 0
            except (TypeError, ValueError):
                ilvl = 0
            fmt = num_formats.get(num_id, {}).get(ilvl, "decimal")
            return "bullet" if fmt == "bullet" else "ordered"

    style_name = ""
    try:
        if para.style is not None:
            style_name = para.style.name or ""
    except (AttributeError, KeyError):
        style_name = ""
    style_name = style_name.lower()
    if "list number" in style_name or "numbered" in style_name:
        return "ordered"
    if "list bullet" in style_name or "bullet" in style_name:
        return "bullet"
    return None


def _run_is_struck(run) -> bool:
    """Detect strikethrough. Font.strike is the supported API; fall back to rPr."""
    try:
        strike = run.font.strike
    except (AttributeError, KeyError, ValueError):
        strike = None
    if strike is not None:
        return bool(strike)
    r_pr = getattr(run._element, "rPr", None)
    if r_pr is None:
        return False
    strike_el = r_pr.find(qn("w:strike"))
    return strike_el is not None and strike_el.get(qn("w:val")) not in ("0", "false")


def _run_to_md(run) -> str:
    """Render a single run as markdown inline text."""
    text = run.text or ""
    if not text:
        return ""
    if _run_is_struck(run):
        text = f"~~{text}~~"
    if run.bold:
        text = f"**{text}**"
    if run.italic:
        text = f"*{text}*"
    return text


def _para_to_md(para) -> str:
    """Convert a paragraph's content to markdown, hyperlinks included."""
    parts: list[str] = []
    for child in para._p:
        tag = child.tag.split("}")[-1] if "}" in child.tag else child.tag
        if tag == "r":
            parts.append(_run_to_md(Run(child, para)))
        elif tag == "hyperlink":
            text = "".join(node.text or "" for node in child.iter(qn("w:t")))
            url = ""
            rel_id = child.get(qn("r:id"))
            if rel_id:
                rel = para.part.rels.get(rel_id)
                if rel is not None and getattr(rel, "is_external", False):
                    url = rel.target_ref
            parts.append(f"[{text}]({url})" if url else text)
    if not parts:
        return para.text
    return "".join(parts)


def _count_images(doc) -> int:
    """Count images (drawings and legacy pictures) in the document body."""
    body = doc.element.body
    drawings = body.findall(".//" + qn("w:drawing"))
    pictures = body.findall(".//" + qn("w:pict"))
    return len(drawings) + len(pictures)


def docx_to_md(docx_path: Path) -> tuple[str, int]:
    """Convert a .docx file to markdown text.

    Returns the markdown text and the number of dropped images.
    """
    doc = _open_document(docx_path)
    dropped_images = _count_images(doc)
    num_formats = _parse_numbering(doc)

    # One pass to index paragraphs by their XML element: a linear scan per
    # paragraph is quadratic on long documents.
    para_by_element = {para._p: para for para in doc.paragraphs}

    lines: list[str] = []
    ordered_counter = 0
    previous_kind: str | None = None

    body = doc.element.body
    table_index = 0
    for child in body:
        tag = child.tag.split("}")[-1] if "}" in child.tag else child.tag

        if tag == "p":
            para = para_by_element.get(child)
            if para is None:
                continue

            if not para.text.strip():
                lines.append("")
                continue

            style_name = ""
            try:
                if para.style is not None:
                    style_name = para.style.name or ""
            except (AttributeError, KeyError):
                style_name = ""

            if style_name.lower().startswith("heading"):
                level = max(1, min(MAX_HEADING_LEVEL, _heading_level(style_name)))
                lines.append(f"{'#' * level} {_para_to_md(para)}")
                ordered_counter = 0
                previous_kind = None
                continue

            kind = _list_kind(para, num_formats)
            content = _para_to_md(para)
            if kind == "ordered":
                ordered_counter = ordered_counter + 1 if previous_kind == "ordered" else 1
                lines.append(f"{ordered_counter}. {content}")
            elif kind == "bullet":
                ordered_counter = 0
                lines.append(f"- {content}")
            else:
                ordered_counter = 0
                lines.append(content)
            previous_kind = kind

        elif tag == "tbl":
            tables = doc.tables
            if table_index < len(tables):
                lines.append("")
                lines.append(_table_to_md(tables[table_index]))
                lines.append("")
            table_index += 1

    while len(lines) > 1 and lines[-1] == "":
        lines.pop()

    result = "\n".join(lines)
    result = re.sub(r"\n{3,}", "\n\n", result)
    return result, dropped_images


def _heading_level(style_name: str) -> int:
    m = re.search(r"(\d)", style_name)
    return int(m.group(1)) if m else 1


def _escape_cell(text: str) -> str:
    """Escape pipes so a literal '|' inside a cell survives the roundtrip."""
    return text.replace("|", "\\|")


def _table_to_md(table) -> str:
    rows = table.rows
    if not rows:
        return ""

    header = [_escape_cell(cell.text) for cell in rows[0].cells]
    sep = ["---"] * len(header)
    data = [[_escape_cell(cell.text) for cell in row.cells] for row in rows[1:]]

    lines = []
    lines.append("| " + " | ".join(header) + " |")
    lines.append("| " + " | ".join(sep) + " |")
    for row in data:
        lines.append("| " + " | ".join(row) + " |")

    return "\n".join(lines)


# --------------------------------------------------------------------------
# markdown -> docx
# --------------------------------------------------------------------------


def _split_table_row(line: str) -> list[str]:
    """Split a markdown table row on unescaped pipes."""
    stripped = line.strip()
    stripped = stripped.removeprefix("|")
    if stripped.endswith("|") and not stripped.endswith("\\|"):
        stripped = stripped[:-1]

    cells: list[str] = []
    current: list[str] = []
    i = 0
    while i < len(stripped):
        char = stripped[i]
        if char == "\\" and i + 1 < len(stripped) and stripped[i + 1] == "|":
            current.append("|")
            i += 2
            continue
        if char == "|":
            cells.append("".join(current).strip())
            current = []
            i += 1
            continue
        current.append(char)
        i += 1
    cells.append("".join(current).strip())
    return cells


def _is_table_separator(line: str) -> bool:
    return bool(re.match(r"^\|[\s\-:|]+\|$", line.strip()))


def _count_heading(line: str) -> int:
    m = re.match(r"^(#+)", line)
    return len(m.group(1)) if m else 1


def _write_table(doc, rows: list[list[str]]) -> None:
    """Write a markdown table, padding or truncating ragged rows."""
    if not rows:
        return
    column_count = max(1, len(rows[0]))
    t = doc.add_table(rows=len(rows), cols=column_count)
    t.style = "Table Grid"
    for i, row_data in enumerate(rows):
        for j in range(column_count):
            cell_text = row_data[j] if j < len(row_data) else ""
            t.cell(i, j).text = cell_text


def _add_hyperlink(paragraph, url: str, text: str) -> None:
    """Append a real Word hyperlink (external relationship) to a paragraph."""
    rel_id = paragraph.part.relate_to(url, RT.HYPERLINK, is_external=True)
    hyperlink = OxmlElement("w:hyperlink")
    hyperlink.set(qn("r:id"), rel_id)

    run = OxmlElement("w:r")
    r_pr = OxmlElement("w:rPr")
    color = OxmlElement("w:color")
    color.set(qn("w:val"), "0563C1")
    r_pr.append(color)
    underline = OxmlElement("w:u")
    underline.set(qn("w:val"), "single")
    r_pr.append(underline)
    run.append(r_pr)

    text_el = OxmlElement("w:t")
    text_el.text = text
    text_el.set(qn("xml:space"), "preserve")
    run.append(text_el)
    hyperlink.append(run)
    paragraph._p.append(hyperlink)


def _add_inline_md_to_paragraph(paragraph, text: str) -> None:
    """Parse markdown inline formatting and add it to a paragraph."""
    pattern = r"(\*\*.*?\*\*|~~.*?~~|`.*?`|\*.*?\*|\[.*?\]\([^)]*\))"
    parts = re.split(pattern, text)

    for part in parts:
        if not part:
            continue

        if part.startswith("**") and part.endswith("**") and len(part) > 4:
            run = paragraph.add_run(part[2:-2])
            run.bold = True
        elif part.startswith("~~") and part.endswith("~~") and len(part) > 4:
            run = paragraph.add_run(part[2:-2])
            run.font.strike = True
        elif part.startswith("`") and part.endswith("`") and len(part) > 2:
            run = paragraph.add_run(part[1:-1])
            run.font.name = "Courier New"
        elif part.startswith("[") and "](" in part and part.endswith(")"):
            bracket_end = part.index("](")
            link_text = part[1:bracket_end]
            url = part[bracket_end + 2:-1]
            if url:
                _add_hyperlink(paragraph, url, link_text)
            else:
                paragraph.add_run(link_text)
        elif part.startswith("*") and part.endswith("*") and len(part) > 2:
            run = paragraph.add_run(part[1:-1])
            run.italic = True
        else:
            paragraph.add_run(part)


def _create_ordered_abstract(doc) -> str | None:
    """Create a decimal numbering definition; return its abstractNumId."""
    try:
        numbering = doc.part.numbering_part.element
    except KeyError:  # no numbering relationship in the package
        return None

    ids = []
    for abs_num in numbering.findall(qn("w:abstractNum")):
        raw = abs_num.get(qn("w:abstractNumId"))
        if raw is not None and raw.isdigit():
            ids.append(int(raw))
    abstract_id = str(max(ids) + 1 if ids else 0)

    abstract = OxmlElement("w:abstractNum")
    abstract.set(qn("w:abstractNumId"), abstract_id)
    multi = OxmlElement("w:multiLevelType")
    multi.set(qn("w:val"), "singleLevel")
    abstract.append(multi)

    lvl = OxmlElement("w:lvl")
    lvl.set(qn("w:ilvl"), "0")
    start = OxmlElement("w:start")
    start.set(qn("w:val"), "1")
    lvl.append(start)
    num_fmt = OxmlElement("w:numFmt")
    num_fmt.set(qn("w:val"), "decimal")
    lvl.append(num_fmt)
    lvl_text = OxmlElement("w:lvlText")
    lvl_text.set(qn("w:val"), "%1.")
    lvl.append(lvl_text)
    lvl_jc = OxmlElement("w:lvlJc")
    lvl_jc.set(qn("w:val"), "left")
    lvl.append(lvl_jc)
    lvl_p_pr = OxmlElement("w:pPr")
    ind = OxmlElement("w:ind")
    ind.set(qn("w:left"), "720")
    ind.set(qn("w:hanging"), "360")
    lvl_p_pr.append(ind)
    lvl.append(lvl_p_pr)
    abstract.append(lvl)

    # w:abstractNum elements must precede the w:num elements in numbering.xml.
    insert_at = len(numbering)
    for index, child in enumerate(numbering):
        if child.tag == qn("w:num"):
            insert_at = index
            break
    numbering.insert(insert_at, abstract)
    return abstract_id


def _new_numbering_instance(doc, abstract_id: str) -> int | None:
    """Create a fresh numbering instance so each list restarts at 1."""
    try:
        numbering = doc.part.numbering_part.element
    except KeyError:  # no numbering relationship in the package
        return None

    ids = []
    for num in numbering.findall(qn("w:num")):
        raw = num.get(qn("w:numId"))
        if raw is not None and raw.isdigit():
            ids.append(int(raw))
    num_id = (max(ids) + 1) if ids else 1

    num = OxmlElement("w:num")
    num.set(qn("w:numId"), str(num_id))
    abs_ref = OxmlElement("w:abstractNumId")
    abs_ref.set(qn("w:val"), abstract_id)
    num.append(abs_ref)
    numbering.append(num)
    return num_id


def _apply_numbering(paragraph, num_id: int) -> None:
    """Attach a numbering definition to a paragraph."""
    p_pr = paragraph._p.get_or_add_pPr()
    num_pr = OxmlElement("w:numPr")
    ilvl = OxmlElement("w:ilvl")
    ilvl.set(qn("w:val"), "0")
    num_pr.append(ilvl)
    num_id_el = OxmlElement("w:numId")
    num_id_el.set(qn("w:val"), str(num_id))
    num_pr.append(num_id_el)
    p_pr.append(num_pr)


def md_to_docx(md_path: Path, out_path: Path) -> None:
    """Convert a markdown file to .docx."""
    text = md_path.read_text(encoding="utf-8")
    doc = Document()

    abstract_id = _create_ordered_abstract(doc)
    current_num_id: int | None = None
    previous_was_ordered = False

    lines = text.split("\n")
    i = 0
    while i < len(lines):
        line = lines[i].rstrip()

        if line.startswith("|"):
            table_rows: list[list[str]] = []
            while i < len(lines) and lines[i].strip().startswith("|"):
                row_line = lines[i].strip()
                if _is_table_separator(row_line):
                    i += 1
                    continue
                table_rows.append(_split_table_row(row_line))
                i += 1
            if table_rows:
                _write_table(doc, table_rows)
            previous_was_ordered = False
            current_num_id = None
            continue

        if not line:
            i += 1
            continue

        if line.startswith("#"):
            level = max(1, min(MAX_HEADING_LEVEL, _count_heading(line)))
            content = line.lstrip("#").strip()
            p = doc.add_heading(level=level)
            _add_inline_md_to_paragraph(p, content)
            previous_was_ordered = False
            current_num_id = None
        elif line.startswith(("- ", "* ")):
            content = line[2:]
            p = doc.add_paragraph(style="List Bullet")
            _add_inline_md_to_paragraph(p, content)
            previous_was_ordered = False
            current_num_id = None
        elif re.match(r"^\d+\.\s", line):
            content = re.sub(r"^\d+\.\s", "", line)
            p = doc.add_paragraph(style="List Paragraph")
            if abstract_id is not None:
                if not previous_was_ordered or current_num_id is None:
                    current_num_id = _new_numbering_instance(doc, abstract_id)
                if current_num_id is not None:
                    _apply_numbering(p, current_num_id)
            _add_inline_md_to_paragraph(p, content)
            previous_was_ordered = True
        elif line.startswith("> "):
            content = line[2:]
            p = doc.add_paragraph(style="Normal")
            run = p.add_run(content)
            run.italic = True
            previous_was_ordered = False
            current_num_id = None
        else:
            p = doc.add_paragraph()
            _add_inline_md_to_paragraph(p, line)
            previous_was_ordered = False
            current_num_id = None

        i += 1

    try:
        doc.save(str(out_path))
    except FileNotFoundError as exc:
        raise ConversionError(
            f"Error: cannot write '{out_path}': output directory does not exist."
        ) from exc


# --------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------


EPILOG = """\
directions:
  .docx -> .md   the input is converted to markdown; the default output is the
                 input path with a .md suffix.
  .md -> .docx   the input is converted to a Word document; the default output
                 is the input path with a .docx suffix.

overwrite semantics:
  An existing output file is replaced without confirmation.
  The tool refuses to write the output over its own input file, because that
  would destroy the source document.

lossy conversions:
  Images, signatures and scanned pages have no markdown equivalent and are
  dropped. The number of dropped images is reported on stderr.
"""


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Convert between docx and markdown formats.",
        epilog=EPILOG,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("input", type=Path, help="Input file (.docx or .md)")
    parser.add_argument(
        "-o", "--output", type=Path, default=None, help="Output file path"
    )
    args = parser.parse_args(argv)

    inp: Path = args.input
    if not inp.exists():
        print(f"Error: file not found: {inp}", file=sys.stderr)
        return 1

    suffix = inp.suffix.lower()

    if suffix == ".docx":
        out = args.output or inp.with_suffix(".md")
    elif suffix in (".md", ".markdown"):
        out = args.output or inp.with_suffix(".docx")
    else:
        print(
            f"Error: unsupported file type '{suffix}'. Use .docx or .md",
            file=sys.stderr,
        )
        return 1

    try:
        if out.resolve() == inp.resolve():
            print(
                f"Error: refusing to overwrite the input file: the output path "
                f"'{out}' resolves to the same file as the input. "
                "Choose a different output path.",
                file=sys.stderr,
            )
            return 1

        _require_docx()

        if suffix == ".docx":
            md_text, dropped_images = docx_to_md(inp)
            try:
                out.write_text(md_text, encoding="utf-8")
            except FileNotFoundError:
                print(
                    f"Error: cannot write '{out}': output directory does not exist.",
                    file=sys.stderr,
                )
                return 1
            extracted_chars = len(md_text.strip())
            source_bytes = inp.stat().st_size
            print(f"Converted: {inp} -> {out}")
            print(
                f"Extracted {extracted_chars} characters "
                f"(source file {source_bytes} bytes, {dropped_images} image(s) dropped)."
            )
            if dropped_images:
                print(
                    "Warning: images, signatures and scanned pages have no "
                    "markdown equivalent and were dropped. They are not "
                    "represented in the converted text.",
                    file=sys.stderr,
                )
            if extracted_chars == 0:
                print(
                    "Warning: no text could be extracted. The document is "
                    "probably a scan without a text layer; review the original "
                    "file directly.",
                    file=sys.stderr,
                )
            elif source_bytes > 200_000 and extracted_chars < source_bytes // 50:
                print(
                    "Warning: the extracted text is implausibly short for the "
                    "size of the source document. Much of it may be images; "
                    "check the original before relying on this conversion.",
                    file=sys.stderr,
                )
        else:
            md_to_docx(inp, out)
            print(f"Converted: {inp} -> {out}")
    except ConversionError as exc:
        print(str(exc), file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
