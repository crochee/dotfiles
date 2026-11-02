#!/usr/bin/env python3
"""Self-check for the de-ai-tone scanner and package.

Runs the scanner against its fixtures through the same process boundary a user
would use, and fails loudly if the gate stops discriminating slop from prose.
Also compares the pattern numbers, the threshold numbers and the Chinese pattern
names across the files that carry them, so a change to one cannot drift away
from the others.
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCAN = ROOT / "scripts" / "scan.py"
FIXTURES = ROOT / "tests" / "fixtures"
SLOP = FIXTURES / "ai-slop.md"
SLOP_ZH = FIXTURES / "ai-slop.zh.md"
HUMAN = FIXTURES / "human.md"
HUMAN_ZH = FIXTURES / "human-zh.md"

HIT = re.compile(r"^(.+?):(\d+): ([A-F]\d+) ([a-z0-9-]+): (.*)$")
CATEGORY = re.compile(r'^\s*"([a-z0-9-]+)",\s*$')
RULE_ID = re.compile(r'pattern_id="([A-F]\d+)"')
TABLE_ROW = re.compile(r"^\|\s*([A-F]\d+)\s*\|", re.MULTILINE)
HEADING = re.compile(r"^###\s+([A-F]\d+)\.\s+(.+?)\s*$", re.MULTILINE)

# Every category token the scanner can print from a line hit. The metric rule
# (`repeated-openings`) is not here: it reports a paragraph, not a line, and
# never appears in a line hit.
REQUIRED = {
    "not-just-x",
    "one-line-closer",
    "empty-summary",
    "deep-saying",
    "meta-narration",
    "empty-transition",
    "zh-translated-connective",
    "zh-empty-opening",
    "arguing-with-nobody",
    "rhetorical-question",
    "false-candour",
    "staged-contrast",
    "attention-formula",
    "triadic-padding",
    "zh-parallelism",
    "emdash-chain",
    "hedge-stacking",
    "zh-hedge-stacking",
    "hyphen-pairs",
    "passive-voice",
    "preposition-opening",
    "chained-de",
    "nominalisation",
    "colloquial-stack",
    "over-balanced",
    "feature-triad",
    "fake-span",
    "translated-diction",
    "inflated-significance",
    "vague-connection",
    "ing-rider",
    "sales-language",
    "borrowed-authority",
    "avoiding-copula",
    "challenges-outlook",
    "corporate-jargon",
    "generic-positive",
    "over-bold",
    "labelled-list",
    "decorative-heading",
    "emoji-bullet",
    "curly-quotes",
    "punctuation-spacing",
    "chatbot-residue",
    "knowledge-limit",
    "heading-repeat",
    "document-meta",
    "staged-persona",
}

# Categories only the Chinese rules can produce. They must fire in the Chinese
# fixture; every other category must fire in the English one.
CHINESE_ONLY = {
    "zh-translated-connective",
    "zh-empty-opening",
    "zh-parallelism",
    "zh-hedge-stacking",
    "challenges-outlook",
    "punctuation-spacing",
    "preposition-opening",
    "chained-de",
    "nominalisation",
    "colloquial-stack",
    "feature-triad",
}

GROUPS = ("a", "b", "c", "d", "e", "f")

result = {"failed": 0}


def run(*args: str, stdin: str | None = None) -> subprocess.CompletedProcess:
    return subprocess.run(
        [sys.executable, str(SCAN), *args],
        input=stdin,
        capture_output=True,
        text=True,
        check=False,
    )


def hits(stdout: str) -> list[tuple[int, str, str, str]]:
    found = []
    for line in stdout.splitlines():
        match = HIT.match(line)
        if match:
            found.append(
                (int(match.group(2)), match.group(3), match.group(4), match.group(5))
            )
    return found


def categories(stdout: str) -> set[str]:
    return {hit[2] for hit in hits(stdout)}


def check(name: str, ok: bool, detail: str = "") -> None:
    print(f"{'ok' if ok else 'FAIL'} - {name}{'' if ok else ': ' + detail}")
    if not ok:
        result["failed"] += 1


def read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except OSError as error:
        print(f"FAIL - read {path.name}: {error}")
        result["failed"] += 1
        return ""


def scanner_categories() -> set[str]:
    """The category tokens the scanner's rules carry."""
    source = read(SCAN)
    return set(re.findall(r'Rule\(\s*\n?\s*"([a-z0-9-]+)"', source))


def table_ids(text: str) -> list[str]:
    return [match.group(1) for match in TABLE_ROW.finditer(text)]


def heading_names(text: str) -> dict[str, str]:
    names: dict[str, str] = {}
    for line in text.splitlines():
        match = HEADING.match(line)
        if match:
            names[match.group(1)] = match.group(2)
    return names


def threshold_numbers(text: str) -> list[str]:
    """The numeric tokens of the threshold table, after the anchor."""
    if "<!-- thresholds -->" not in text:
        return []
    tail = text.split("<!-- thresholds -->", 1)[1]
    numbers: list[str] = []
    for line in tail.splitlines():
        if line.startswith("|"):
            numbers.extend(re.findall(r"[0-9]+(?:[.,][0-9]+)*", line))
        elif numbers:
            break
    return numbers


def main() -> int:
    slop = run(str(SLOP))
    slop_hits = hits(slop.stdout)
    slop_categories = categories(slop.stdout)
    check(
        "slop fixture exits 1",
        slop.returncode == 1,
        f"exit {slop.returncode}\n{slop.stderr}",
    )
    check(
        "slop fixture yields at least 20 hits",
        len(slop_hits) >= 20,
        f"{len(slop_hits)} hits\n{slop.stdout}",
    )
    check(
        "slop fixture covers every English category",
        (REQUIRED - CHINESE_ONLY) <= slop_categories,
        f"missing {sorted((REQUIRED - CHINESE_ONLY) - slop_categories)}",
    )
    check(
        "slop fixture reports a score line",
        any(line.startswith("score:") for line in slop.stdout.splitlines()),
        "no score line",
    )
    check(
        "every hit carries a pattern number and a category token",
        all(re.fullmatch(r"[A-F]\d+", hit[1]) for hit in slop_hits),
        f"{[hit for hit in slop_hits if not re.fullmatch(r'[A-F]\\d+', hit[1])][:5]}",
    )

    slop_zh = run(str(SLOP_ZH))
    slop_zh_categories = categories(slop_zh.stdout)
    check(
        "Chinese slop fixture exits 1",
        slop_zh.returncode == 1,
        f"exit {slop_zh.returncode}\n{slop_zh.stderr}",
    )
    check(
        "Chinese slop fixture covers every Chinese category",
        CHINESE_ONLY <= slop_zh_categories,
        f"missing {sorted(CHINESE_ONLY - slop_zh_categories)}",
    )

    check(
        "scanner exposes exactly the documented categories",
        scanner_categories() == REQUIRED | {"repeated-openings"},
        f"scanner has {sorted(scanner_categories() - REQUIRED - {chr(39)+chr(39)})} extra and "
        f"{sorted(REQUIRED - scanner_categories())} missing",
    )

    human = run(str(HUMAN))
    human_hits = hits(human.stdout)
    check(
        "human fixture exits 0",
        human.returncode == 0,
        f"exit {human.returncode}\n{human.stdout}",
    )
    check("human fixture yields 0 hits", not human_hits, f"{human_hits}")

    human_zh = run(str(HUMAN_ZH))
    human_zh_hits = hits(human_zh.stdout)
    check(
        "Chinese human fixture exits 0",
        human_zh.returncode == 0,
        f"exit {human_zh.returncode}\n{human_zh.stdout}",
    )
    check("Chinese human fixture yields 0 hits", not human_zh_hits, f"{human_zh_hits}")

    piped = run(stdin=HUMAN.read_text(encoding="utf-8"))
    check(
        "clean stdin exits 0 with 0 hits and the <stdin> label",
        piped.returncode == 0
        and not hits(piped.stdout)
        and "<stdin>:" not in piped.stdout
        and piped.stdout.startswith("score: 0 distinct lines"),
        f"exit {piped.returncode}\n{piped.stdout}",
    )

    slop_pipe = run("-", stdin=SLOP.read_text(encoding="utf-8"))
    check(
        "slop over stdin exits 1 and labels hits <stdin>",
        slop_pipe.returncode == 1 and "<stdin>:" in slop_pipe.stdout,
        f"exit {slop_pipe.returncode}",
    )

    missing = run(str(FIXTURES / "does-not-exist.md"))
    check(
        "unreadable input exits 2 and writes to stderr",
        missing.returncode == 2 and "cannot read" in missing.stderr,
        f"exit {missing.returncode}, stderr {missing.stderr!r}",
    )

    for marker, label in (
        ("not-just-x", "category token"),
        ("A1", "pattern number"),
        ("A1 not-just-x", "both"),
    ):
        ignored = run(
            "-",
            stdin=(
                "It's not just a cache, it's a write buffer. "
                f"<!-- scan: ignore {marker} -->\n"
            ),
        )
        check(
            f"scan: ignore accepts the {label}",
            ignored.returncode == 0,
            f"exit {ignored.returncode}\n{ignored.stdout}",
        )

    source = SCAN.read_text(encoding="utf-8")
    imports = set(re.findall(r"^(?:import|from)\s+([a-zA-Z_][\w.]*)", source, re.M))
    allowed = {"re", "sys", "dataclasses", "pathlib", "__future__"}
    check(
        "scanner imports only the standard library",
        imports <= allowed,
        f"unexpected {sorted(imports - allowed)}",
    )

    # --- drift test 1: the pattern numbers --------------------------------
    skill = read(ROOT / "references" / "patterns-index.md")
    readme = read(ROOT / "README.md")
    scanner_ids = sorted(set(RULE_ID.findall(source)))
    skill_ids = table_ids(skill)
    readme_ids = table_ids(readme)
    reference_ids: list[str] = []
    chinese_names: dict[str, str] = {}
    english_names: dict[str, str] = {}
    for group in GROUPS:
        english_path = ROOT / "references" / f"patterns-{group}.md"
        chinese_path = ROOT / "references" / f"patterns-{group}.zh.md"
        if english_path.is_file():
            english_names.update(heading_names(read(english_path)))
            reference_ids.extend(
                match.group(1)
                for match in HEADING.finditer(read(english_path))
            )
        if chinese_path.is_file():
            for identifier, heading in heading_names(read(chinese_path)).items():
                parts = heading.split(" / ")
                if len(parts) == 2:
                    chinese_names[identifier] = parts[1].strip()

    all_ids = sorted(set(skill_ids) | set(readme_ids) | set(reference_ids))
    expected = [
        f"{group}{index}"
        for group, size in (("A", 9), ("B", 14), ("C", 10), ("D", 5), ("E", 5), ("F", 1))
        for index in range(1, size + 1)
    ]
    check(
        "references/patterns-index.md lists the 44 pattern numbers without gaps",
        skill_ids == expected,
        f"{skill_ids}",
    )
    check(
        "README.md lists the same 44 pattern numbers",
        readme_ids == expected,
        f"{readme_ids}",
    )
    check(
        "the reference files cover the same 44 pattern numbers",
        sorted(reference_ids) == sorted(expected),
        f"{sorted(reference_ids)}",
    )
    check(
        "every pattern number has a scanner rule or is a manual pattern",
        set(scanner_ids) | {"B10", "F1"} == set(expected),
        f"scanner has {sorted(set(scanner_ids) - set(expected))}",
    )

    # --- drift test 2: the threshold numbers ------------------------------
    measurement = read(ROOT / "references" / "measurement.md")
    measurement_zh = read(ROOT / "references" / "measurement.zh.md")
    english_numbers = threshold_numbers(measurement)
    chinese_numbers = threshold_numbers(measurement_zh)
    check(
        "the English measurement file carries the thresholds anchor",
        "<!-- thresholds -->" in measurement,
        "no <!-- thresholds --> anchor",
    )
    check(
        "the Chinese measurement file carries the thresholds anchor",
        "<!-- thresholds -->" in measurement_zh,
        "no <!-- thresholds --> anchor",
    )
    check(
        "both measurement files list the same threshold numbers",
        bool(english_numbers) and english_numbers == chinese_numbers,
        f"English {english_numbers}, Chinese {chinese_numbers}",
    )

    # --- drift test 3: the Chinese pattern names --------------------------
    mismatched = []
    for identifier, heading in sorted(english_names.items()):
        parts = heading.split(" / ")
        if len(parts) != 2:
            mismatched.append((identifier, heading))
            continue
        english_chinese = parts[1].strip()
        if chinese_names.get(identifier) != english_chinese:
            mismatched.append((identifier, english_chinese, chinese_names.get(identifier)))
    check(
        "both languages give a pattern the same Chinese name",
        not mismatched,
        f"{mismatched}",
    )
    check(
        "every pattern has a Chinese name",
        len(chinese_names) == 44,
        f"{len(chinese_names)} names",
    )

    print(f"{'ok' if not result['failed'] else 'FAIL'} - {result['failed']} failure(s)")
    return 1 if result["failed"] else 0


if __name__ == "__main__":
    sys.exit(main())
