#!/usr/bin/env python3
"""Self-check for the de-ai-tone scanner.

Runs the scanner against its fixtures through the same process boundary a user
would use, and fails loudly if the gate stops discriminating slop from prose.
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCAN = ROOT / "scripts" / "scan.py"
SLOP = ROOT / "tests" / "fixtures" / "ai-slop.md"
HUMAN = ROOT / "tests" / "fixtures" / "human.md"

HIT = re.compile(r"^(.+?):(\d+): ([a-z-]+): (.*)$")
REQUIRED = {
    "hedge-stacking",
    "empty-transition",
    "triadic-padding",
    "not-just-x",
    "meta-narration",
    "empty-summary",
    "translated-diction",
    "corporate-jargon",
    "zh-translated-connective",
    "zh-parallelism",
    "over-bold",
    "emoji-bullet",
}

result = {"failed": 0}


def run(*args: str, stdin: str | None = None) -> subprocess.CompletedProcess:
    return subprocess.run(
        [sys.executable, str(SCAN), *args],
        input=stdin,
        capture_output=True,
        text=True,
        check=False,
    )


def hits(stdout: str) -> list[tuple[int, str, str]]:
    found = []
    for line in stdout.splitlines():
        match = HIT.match(line)
        if match:
            found.append((int(match.group(2)), match.group(3), match.group(4)))
    return found


def check(name: str, ok: bool, detail: str = "") -> None:
    print(f"{'ok' if ok else 'FAIL'} - {name}{'' if ok else ': ' + detail}")
    if not ok:
        result["failed"] += 1


def main() -> int:
    slop = run(str(SLOP))
    slop_hits = hits(slop.stdout)
    slop_categories = {hit[1] for hit in slop_hits}
    check(
        "slop fixture exits 1",
        slop.returncode == 1,
        f"exit {slop.returncode}\n{slop.stderr}",
    )
    check(
        "slop fixture yields at least 6 hits",
        len(slop_hits) >= 6,
        f"{len(slop_hits)} hits\n{slop.stdout}",
    )
    check(
        "slop fixture spans at least 4 categories",
        len(slop_categories) >= 4,
        f"{sorted(slop_categories)}",
    )
    check(
        "slop fixture covers every documented category",
        REQUIRED <= slop_categories,
        f"missing {sorted(REQUIRED - slop_categories)}",
    )
    check(
        "slop fixture reports a score line",
        any(line.startswith("score:") for line in slop.stdout.splitlines()),
        "no score line",
    )

    human = run(str(HUMAN))
    human_hits = hits(human.stdout)
    check(
        "human fixture exits 0",
        human.returncode == 0,
        f"exit {human.returncode}\n{human.stdout}",
    )
    check("human fixture yields 0 hits", not human_hits, f"{human_hits}")

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

    missing = run(str(ROOT / "tests" / "fixtures" / "does-not-exist.md"))
    check(
        "unreadable input exits 2 and writes to stderr",
        missing.returncode == 2 and "cannot read" in missing.stderr,
        f"exit {missing.returncode}, stderr {missing.stderr!r}",
    )

    source = SCAN.read_text(encoding="utf-8")
    imports = set(re.findall(r"^(?:import|from)\s+([a-zA-Z_][\w.]*)", source, re.M))
    allowed = {"re", "sys", "dataclasses", "pathlib", "__future__"}
    check(
        "scanner imports only the standard library",
        imports <= allowed,
        f"unexpected {sorted(imports - allowed)}",
    )

    print(f"{'ok' if not result['failed'] else 'FAIL'} - {result['failed']} failure(s)")
    return 1 if result["failed"] else 0


if __name__ == "__main__":
    sys.exit(main())
