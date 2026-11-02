#!/usr/bin/env python3
"""Check the de-ai-tone package without external dependencies.

Run it from anywhere:

    python3 scripts/validate-package.py

It checks the frontmatter, the pattern tables, the reference files, the scanner's rule set and the
changelog version against each other. It exits 0 and prints one line when the package is
consistent, and exits 1 with the reason on stderr when it is not.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKILL_PATH = ROOT / "SKILL.md"
PATTERN_INDEX_PATH = ROOT / "references" / "patterns-index.md"
ALLOWED_KEYS = {"name", "description", "license", "compatibility", "metadata", "allowed-tools"}
MAX_SKILL_LINES = 157  # 150 body lines plus the seven-line frontmatter block
MAX_DESCRIPTION = 1024
GROUPS = ("a", "b", "c", "d", "e", "f")
TABLE_ROW = re.compile(r"^\|\s*([A-F]\d+)\s*\|(.+)$")
HEADING = re.compile(r"^###\s+([A-F]\d+)\.\s+(.+?)\s*$")
VERSION_HEADING = re.compile(r"^##\s+(\d+\.\d+\.\d+)\s*$", re.MULTILINE)
SECTION_REF = re.compile(r"§([A-F]\d+)")
LINK_REF = re.compile(r"\((references/[^)]+)\)")
RULE_ID = re.compile(r'pattern_id="([A-F]\d+)"')
RULE_CATEGORY = re.compile(r'Rule\(\s*\n?\s*"([a-z0-9-]+)"', re.MULTILINE)

failures: list[str] = []


def fail(message: str) -> None:
    failures.append(message)


def read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except OSError as error:
        raise SystemExit(f"validate-package.py: cannot read {path}: {error}")


def frontmatter(text: str) -> tuple[dict[str, str], list[str]]:
    """Return the top-level frontmatter keys and the raw frontmatter lines.

    A small hand-rolled parser: the package has one known shape, and the script must stay free of
    third-party dependencies.
    """
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        raise SystemExit("validate-package.py: SKILL.md must start with a YAML frontmatter block")
    try:
        end = lines.index("---", 1)
    except ValueError:
        raise SystemExit("validate-package.py: SKILL.md frontmatter is not closed")
    block = lines[1:end]
    keys: dict[str, str] = {}
    current: str | None = None
    for line in block:
        if not line.strip():
            continue
        if line.startswith((" ", "\t")):
            if current:
                keys[current] += " " + line.strip()
            continue
        match = re.match(r"^([A-Za-z][A-Za-z0-9_-]*):\s*(.*)$", line)
        if not match:
            raise SystemExit(f"validate-package.py: unreadable frontmatter line: {line!r}")
        current = match.group(1)
        keys[current] = match.group(2).strip()
    return keys, block


def table_rows(text: str, start_marker: str) -> list[tuple[str, list[str]]]:
    """Rows of the first Markdown table that follows start_marker.

    Only rows whose first cell is a pattern number are returned, so the
    header row and the separator never count as patterns.
    """
    lines = text.splitlines()
    for index, line in enumerate(lines):
        if start_marker in line:
            break
    else:
        return []
    rows: list[tuple[str, list[str]]] = []
    for line in lines[index + 1 :]:
        if not line.startswith("|"):
            if rows:
                break
            continue
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if not cells or not re.fullmatch(r"[A-F]\d+", cells[0]):
            continue
        rows.append((cells[0], cells))
    return rows


def load_rules() -> list:
    """The scanner's rule objects, read by importing the scanner.

    The scanner is safe to import: it only defines rules and functions until
    it is run as a script.
    """
    import importlib.util

    sys.dont_write_bytecode = True
    spec = importlib.util.spec_from_file_location("de_ai_tone_scan", ROOT / "scripts" / "scan.py")
    if spec is None or spec.loader is None:
        raise SystemExit("validate-package.py: cannot load scripts/scan.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return list(module.RULES)


def main() -> int:
    skill = read(SKILL_PATH)
    pattern_index = read(PATTERN_INDEX_PATH)
    readme = read(ROOT / "README.md")
    changelog = read(ROOT / "CHANGELOG.md")
    scanner = read(ROOT / "scripts" / "scan.py")

    # --- frontmatter -----------------------------------------------------
    keys, block = frontmatter(skill)
    extra = set(keys) - ALLOWED_KEYS
    if extra:
        fail(f"frontmatter has unsupported keys: {sorted(extra)}")
    missing = {"name", "description", "metadata"} - set(keys)
    if missing:
        fail(f"frontmatter is missing required keys: {sorted(missing)}")

    name = keys.get("name", "")
    if name != ROOT.name:
        fail(f"frontmatter name {name!r} does not match the directory name {ROOT.name!r}")
    if not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", name):
        fail(f"frontmatter name {name!r} is not lowercase letters, digits and single hyphens")

    description = keys.get("description", "")
    if not description:
        fail("frontmatter description is empty")
    if len(description) > MAX_DESCRIPTION:
        fail(f"frontmatter description is {len(description)} characters, over {MAX_DESCRIPTION}")

    version = ""
    in_metadata = False
    for line in block:
        if re.match(r"^metadata:\s*$", line):
            in_metadata = True
            continue
        if in_metadata and re.match(r"^\s+version:\s*(.+)$", line):
            version = line.split(":", 1)[1].strip().strip('"\'')
            break
        if in_metadata and line and not line.startswith((" ", "\t")):
            break
    if not version:
        fail("frontmatter has no metadata.version")
    elif not re.fullmatch(r"\d+\.\d+\.\d+", version):
        fail(f"metadata.version {version!r} is not a three-part version")

    changelog_versions = VERSION_HEADING.findall(changelog)
    if not changelog_versions:
        fail("CHANGELOG.md has no '## x.y.z' heading")
    elif changelog_versions[0] != version:
        fail(
            f"metadata.version {version!r} does not match the first CHANGELOG heading "
            f"{changelog_versions[0]!r}"
        )

    # --- SKILL.md size ---------------------------------------------------
    body_lines = skill.splitlines()
    if len(body_lines) > MAX_SKILL_LINES:
        fail(f"SKILL.md is {len(body_lines)} lines, over the {MAX_SKILL_LINES}-line budget")

    # --- the pattern tables ----------------------------------------------
    skill_rows = table_rows(pattern_index, "| ID | Pattern | Detector |")
    readme_rows = table_rows(readme, "## The 44 patterns")
    if not skill_rows:
        fail("references/patterns-index.md has no pattern table")
    if not readme_rows:
        fail("README.md has no '## The 44 patterns' table")

    skill_ids = [row[0] for row in skill_rows]
    readme_ids = [row[0] for row in readme_rows]
    if len(skill_ids) != 44:
        fail(f"references/patterns-index.md lists {len(skill_ids)} patterns, expected 44")
    if len(readme_ids) != 44:
        fail(f"README.md lists {len(readme_ids)} patterns, expected 44")
    if skill_ids != readme_ids:
        fail("references/patterns-index.md and README.md list different pattern numbers")
    expected_ids = [f"{group}{index}" for group, size in (("A", 9), ("B", 14), ("C", 10), ("D", 5), ("E", 5), ("F", 1)) for index in range(1, size + 1)]
    if skill_ids != expected_ids:
        fail(f"pattern numbers are not A1-F1 without gaps: {skill_ids}")
    known = set(skill_ids)

    names: dict[str, str] = {}
    tokens: dict[str, list[str]] = {}
    detectors: dict[str, str] = {}
    for identifier, cells in skill_rows:
        names[identifier] = cells[1].strip()
        detectors[identifier] = cells[2].strip()
        tokens[identifier] = [
            token.strip()
            for token in cells[3].replace("`", "").split(",")
            if token.strip() and token.strip() != "—"
        ]
    readme_names = {row[0]: row[1][1].strip() for row in readme_rows}
    for identifier, name in names.items():
        if readme_names.get(identifier) != name:
            fail(f"{identifier} is named {name!r} in references/patterns-index.md and {readme_names.get(identifier)!r} in README.md")

    # --- reference files --------------------------------------------------
    for group in GROUPS:
        for suffix in ("", ".zh"):
            path = ROOT / "references" / f"patterns-{group}{suffix}.md"
            if not path.is_file():
                fail(f"missing reference file: references/patterns-{group}{suffix}.md")
                continue
            lines = path.read_text(encoding="utf-8").splitlines()
            if len(lines) > 100:
                wanted = [
                    identifier
                    for identifier in expected_ids
                    if identifier.startswith(group.upper())
                ]
                toc_lines = [
                    line
                    for line in lines[:15]
                    if all(re.search(rf"\b{identifier}\b", line) for identifier in wanted)
                    and (
                        " · " in line
                        or (len(wanted) == 1 and line.lstrip().startswith(wanted[0] + " "))
                    )
                ]
                if not toc_lines:
                    fail(
                        f"references/patterns-{group}{suffix}.md is {len(lines)} lines and has no "
                        "table of contents in its first 15 lines"
                    )
                    continue
                listed = re.findall(rf"\b{group.upper()}\d+\b", toc_lines[0])
                if listed != wanted:
                    fail(
                        f"references/patterns-{group}{suffix}.md table of contents does not list "
                        f"{wanted} in order: {listed}"
                    )

    heading_ids: list[str] = []
    for group in GROUPS:
        path = ROOT / "references" / f"patterns-{group}.md"
        if not path.is_file():
            continue
        for line in path.read_text(encoding="utf-8").splitlines():
            match = HEADING.match(line)
            if match:
                heading_ids.append(match.group(1))
                english = match.group(2).split(" / ")[0].strip()
                identifier = match.group(1)
                if identifier in names and names[identifier] != english:
                    fail(
                        f"{identifier} is named {english!r} in the reference files and "
                        f"{names[identifier]!r} in SKILL.md"
                    )
    if len(heading_ids) != len(set(heading_ids)):
        fail("a pattern heading appears more than once across the English reference files")
    if set(heading_ids) != known:
        missing_ids = sorted(known - set(heading_ids))
        extra_ids = sorted(set(heading_ids) - known)
        fail(f"reference headings do not cover the table: missing {missing_ids}, extra {extra_ids}")

    for group in GROUPS:
        path = ROOT / "references" / f"patterns-{group}.zh.md"
        if not path.is_file():
            continue
        for line in path.read_text(encoding="utf-8").splitlines():
            match = HEADING.match(line)
            if not match:
                continue
            identifier = match.group(1)
            parts = match.group(2).split(" / ")
            if len(parts) != 2:
                fail(f"Chinese heading for {identifier} does not carry both names: {match.group(2)!r}")
                continue
            english, chinese = parts[0].strip(), parts[1].strip()
            if names.get(identifier) != english:
                fail(f"{identifier} English name differs in the Chinese reference file")
            english_path = ROOT / "references" / f"patterns-{group}.md"
            english_line = None
            for candidate in english_path.read_text(encoding="utf-8").splitlines():
                candidate_match = HEADING.match(candidate)
                if candidate_match and candidate_match.group(1) == identifier:
                    english_line = candidate_match.group(2)
                    break
            if english_line:
                english_chinese = english_line.split(" / ")
                if len(english_chinese) == 2 and english_chinese[1].strip() != chinese:
                    fail(f"{identifier} Chinese name differs between the two reference files")

    # --- the scanner ------------------------------------------------------
    rules = load_rules()
    scanner_ids = {rule.pattern_id for rule in rules if rule.pattern_id}
    unknown = sorted(scanner_ids - known)
    if unknown:
        fail(f"scan.py carries pattern numbers that are not in the table: {unknown}")
    manual = {identifier for identifier, detector in detectors.items() if detector == "manual"}
    for identifier in sorted(manual):
        if identifier in scanner_ids:
            fail(f"{identifier} is manual but scan.py has a rule for it")
    for identifier in sorted(known - manual):
        if identifier not in scanner_ids:
            fail(f"{identifier} has a detector but scan.py has no rule for it")
    for identifier, wanted in tokens.items():
        found = sorted({rule.category for rule in rules if rule.pattern_id == identifier})
        if sorted(wanted) != found:
            fail(
                f"{identifier} uses category tokens {found} in scan.py, but the table lists "
                f"{sorted(wanted)}"
            )

    # --- links and section references --------------------------------------
    for identifier in sorted(set(SECTION_REF.findall(skill))):
        if identifier not in known:
            fail(f"SKILL.md refers to §{identifier}, which is not a pattern number")
    for text, label in ((skill, "SKILL.md"), (readme, "README.md")):
        for link in sorted(set(LINK_REF.findall(text))):
            if "/" in link[len("references/") :]:
                fail(f"{label} links to {link}, which is more than one level deep")
            if not (ROOT / link).is_file():
                fail(f"{label} links to {link}, which does not exist")

    if failures:
        for message in failures:
            print(f"validate-package.py: {message}", file=sys.stderr)
        print(f"validate-package.py: {len(failures)} problem(s) found", file=sys.stderr)
        return 1
    print(f"de-ai-tone package v{version} is valid")
    return 0


if __name__ == "__main__":
    sys.exit(main())
