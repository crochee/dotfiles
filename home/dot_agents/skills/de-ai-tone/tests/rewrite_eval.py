#!/usr/bin/env python3
"""Run the rewrite scenarios and score them mechanically.

    python3 tests/rewrite_eval.py

Each scenario from `evals/rewrite_cases.json` is copied into a scratch
directory, handed to a clean `omp` session, and then scored with checks that
have a right answer: the scan has to be clean, the numbers have to survive,
the modals have to survive, the delivery language has to be right, and the
change log has to name a pattern number with its category.

One criterion in `evals/rubric.md` — reads like a person wrote it — has no
mechanical answer. It is reported as `manual` and left to a reader.
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCAN = ROOT / "scripts" / "scan.py"
DEFAULT_CASES = ROOT / "evals" / "rewrite_cases.json"
DEFAULT_RESULTS = ROOT / "evals" / "rewrite_results.json"

NUMBER = re.compile(r"\d+(?:[.,]\d+)*")
MODALS = (
    "may",
    "might",
    "must",
    "should",
    "only",
    "up to",
    "at least",
    "不超过",
    "至少",
    "仅",
)
CJK = re.compile(r"[\u4e00-\u9fff]")
LATIN_WORD = re.compile(r"[A-Za-z][A-Za-z'-]*")
CATEGORY_CELL = re.compile(
    r"^\s*`?(?P<id>[A-F]\d+)`?\s*[-—–:：()（）·,，]*\s*`?(?P<cat>[a-z0-9-]+)`?\s*$"
)
CATEGORY_CELL_REVERSED = re.compile(
    r"^\s*`?(?P<cat>[a-z0-9-]+)`?\s*[-—–:：()（）·,，]*\s*`?(?P<id>[A-F]\d+)`?\s*$"
)


def run_scan(path: Path) -> list[tuple[int, str, str, str]]:
    """The scanner's hits as (line, pattern id, category, matched text)."""
    process = subprocess.run(
        [sys.executable, str(SCAN), str(path)],
        capture_output=True,
        text=True,
        check=False,
    )
    hits = []
    for line in process.stdout.splitlines():
        match = re.match(r"^.+?:(\d+): ([A-F]\d+) ([a-z0-9-]+): (.*)$", line)
        if match:
            hits.append(
                (int(match.group(1)), match.group(2), match.group(3), match.group(4))
            )
    return hits


def residual(text: str, hits: list[tuple[int, str, str, str]]) -> str:
    """The text with every flagged sentence removed.

    A qualifier that lives inside a flagged sentence belongs to the tell the
    rewrite is supposed to remove, so it does not have to survive.
    """
    by_line: dict[int, list[str]] = {}
    for lineno, _, _, found in hits:
        by_line.setdefault(lineno, []).append(found.split(" (x")[0])
    out = []
    for index, line in enumerate(text.splitlines(), 1):
        found_here = by_line.get(index, [])
        if found_here:
            kept = []
            for sentence in re.split(r"(?<=[.!?。！？])\s*", line):
                if any(mark and mark in sentence for mark in found_here):
                    continue
                kept.append(sentence)
            line = " ".join(part for part in kept if part)
        out.append(line)
    return "\n".join(out)


def dominant_script(text: str) -> str:
    cjk, latin = language_ratio(text)
    return "zh" if cjk > latin else "en"


def numbers(text: str) -> set[str]:
    return {token.replace(",", "") for token in NUMBER.findall(text)}


def modals(text: str) -> set[str]:
    lowered = text.lower()
    # 不仅 and 仅仅 are the not-X-but-Y construction the rewrite is supposed to
    # remove, so they do not count as a lost qualifier.
    lowered = lowered.replace("不仅", "").replace("仅仅", "")
    found = set()
    for modal in MODALS:
        if re.search(rf"(?<![a-z]){re.escape(modal.lower())}(?![a-z])", lowered):
            found.add(modal)
    return found


def category_cells(text: str) -> list[str]:
    """The category cells of the change log's data rows."""
    cells: list[str] = []
    for line in text.splitlines():
        if not line.startswith("|") or set(line) <= set("|-: "):
            continue
        parts = [part.strip() for part in line.strip().strip("|").split("|")]
        if not parts:
            continue
        for part in parts:
            if CATEGORY_CELL.match(part) or CATEGORY_CELL_REVERSED.match(part):
                cells.append(part)
                break
    return cells


def language_ratio(text: str) -> tuple[int, int]:
    return len(CJK.findall(text)), len(LATIN_WORD.findall(text))


def run_session(prompt: str, cwd: Path, max_time: int) -> dict:
    """One clean session that rewrites the draft in the scratch directory."""
    command = [
        "omp",
        "-p",
        "--mode=json",
        "--no-session",
        "--cwd",
        str(cwd),
        f"--max-time={max_time}",
        prompt,
    ]
    try:
        process = subprocess.run(
            command,
            capture_output=True,
            text=True,
            check=False,
            timeout=max_time + 60,
        )
    except FileNotFoundError:
        return {"ok": False, "error": "the omp binary was not found", "output": ""}
    except subprocess.TimeoutExpired:
        return {"ok": False, "error": "the session timed out", "output": ""}
    return {
        "ok": process.returncode == 0,
        "error": "" if process.returncode == 0 else f"exit {process.returncode}",
        "output": process.stdout[-4000:],
    }


def score_case(case: dict, scratch: Path, max_time: int) -> dict:
    """Run one scenario and score it."""
    source = ROOT / case["input"]
    draft = scratch / "draft.md"
    shutil.copyfile(source, draft)
    rewritten = scratch / case.get("output", "rewritten.md")
    change_log = scratch / case.get("change_log", "before-after.md")

    session = run_session(case["prompt"], scratch, max_time)
    original_text = source.read_text(encoding="utf-8")

    # The session's exit code is not the verdict: the score comes from the
    # files it left behind. A session that died after writing the rewrite
    # still produced a rewrite.
    candidates = [path for path in (rewritten, draft) if path.is_file()]
    rewritten_text = ""
    for path in candidates:
        text = path.read_text(encoding="utf-8")
        if text != original_text:
            rewritten = path
            rewritten_text = text
            break
    if not rewritten_text:
        return {
            "id": case["id"],
            "passed": False,
            "error": session["error"] or "the session left the draft unchanged",
            "criteria": {},
        }

    criteria: dict[str, dict] = {}

    hits = run_scan(rewritten)
    remaining = {identifier for _, identifier, _, _ in hits}
    expect_cleared = set(case.get("expect_cleared", []))
    expect_surviving = set(case.get("expect_surviving", []))
    uncleared = sorted(remaining & expect_cleared)
    unexpected = sorted(remaining - expect_surviving)
    criteria["scan clean"] = {
        "ok": not uncleared and not unexpected,
        "detail": (
            f"expected cleared but still flagged: {uncleared}; "
            f"flagged and not allowed: {unexpected}"
            if uncleared or unexpected
            else "no hits"
        ),
    }

    before_numbers = numbers(original_text)
    after_numbers = numbers(rewritten_text)
    lost = sorted(before_numbers - after_numbers)
    invented = sorted(after_numbers - before_numbers)
    criteria["numbers survive"] = {
        "ok": not lost and not invented,
        "detail": f"lost {lost}, invented {invented}" if lost or invented else "no change",
    }

    missing_terms = [
        term for term in case.get("must_keep_terms", []) if term not in rewritten_text
    ]
    criteria["proper nouns survive"] = {
        "ok": not missing_terms,
        "detail": f"missing {missing_terms}" if missing_terms else "no change",
    }

    baseline = run_scan(source)
    lost_modals = sorted(
        modals(residual(original_text, baseline)) - modals(rewritten_text)
    )
    criteria["modals survive"] = {
        "ok": not lost_modals,
        "detail": f"lost {lost_modals}" if lost_modals else "no change",
    }

    cjk, latin = language_ratio(rewritten_text)
    language = case.get("delivery_language", "en")
    source_language = dominant_script(original_text)
    ok = dominant_script(rewritten_text) == source_language == language
    criteria["delivery language"] = {
        "ok": ok,
        "detail": f"{cjk} Chinese characters, {latin} Latin words",
    }

    cells = category_cells(change_log.read_text(encoding="utf-8")) if change_log.is_file() else []
    criteria["change log format"] = {
        "ok": bool(cells),
        "detail": ", ".join(cells[:4]) if cells else "no row names a pattern number and a category",
    }

    criteria["reads like a person"] = {
        "ok": None,
        "detail": "manual — see evals/rubric.md",
    }

    mechanical = [item for item in criteria.values() if item["ok"] is not None]
    return {
        "id": case["id"],
        "passed": all(item["ok"] for item in mechanical),
        "error": "",
        "criteria": criteria,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Score the de-ai-tone rewrite scenarios")
    parser.add_argument("--cases", type=Path, default=DEFAULT_CASES)
    parser.add_argument("--out", type=Path, default=DEFAULT_RESULTS)
    parser.add_argument(
        "--max-time",
        type=int,
        default=600,
        help="omp's session cap, seconds. A full rewrite of the English fixture "
        "takes the model about six minutes",
    )
    parser.add_argument("--only", default="", help="run only the scenario with this id")
    args = parser.parse_args(argv)

    try:
        payload = json.loads(args.cases.read_text(encoding="utf-8"))
        cases = payload["scenarios"]
    except (OSError, json.JSONDecodeError, KeyError, TypeError) as exc:
        print(f"error: cannot read {args.cases}: {exc}", file=sys.stderr)
        return 2
    if args.only:
        cases = [case for case in cases if case["id"] == args.only]
    if not cases:
        print("error: no scenarios to run", file=sys.stderr)
        return 2

    results = []
    with tempfile.TemporaryDirectory(prefix="de-ai-tone-rewrite-") as tmp:
        for case in cases:
            scratch = Path(tmp) / case["id"]
            scratch.mkdir(parents=True, exist_ok=True)
            result = score_case(case, scratch, args.max_time)
            results.append(result)
            print(f"[{case['id']}]")
            for name, item in result["criteria"].items():
                if item["ok"] is None:
                    print(f"    manual  {name}: {item['detail']}")
                else:
                    print(
                        f"    {'pass' if item['ok'] else 'FAIL'}   {name}: {item['detail']}"
                    )
            if result["error"]:
                print(f"    error: {result['error']}")

    failed = [item for item in results if not item["passed"]]
    report = {
        "generated_utc": datetime.now(timezone.utc).replace(microsecond=0).isoformat(),
        "scenarios": results,
        "passed": not failed,
    }
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"\n{len(results) - len(failed)} of {len(results)} scenarios passed the mechanical checks")
    print(f"results written to {args.out}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
