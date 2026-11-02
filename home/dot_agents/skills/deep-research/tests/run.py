#!/usr/bin/env python3
"""Prove each ledger rule with a deliberately broken copy of a known-good run.

    python3 tests/run.py

Each case mutates a copy of a known-good run and asserts that the script exits
1 (findings) or 2 (a refused operation) and names the rule. A rule that stops
firing fails the run, so the gate cannot rot when the prose changes.

The last block checks the skill's own structure against the open Agent Skills
specification, so a frontmatter change that breaks the release gate fails here
first.

Standard library only.
"""

from __future__ import annotations

import csv
import importlib.util
import json
import re
import shutil
import subprocess
import sys
import tempfile
import tomllib
from pathlib import Path

# Importing the ledger script below must not leave a __pycache__ in the
# skill directory: the deployed tree is what other machines read.
sys.dont_write_bytecode = True

ROOT = Path(__file__).resolve().parent.parent
LEDGER = ROOT / "scripts" / "research_ledger.py"
PROTOCOL = ROOT / "references" / "research-protocol.md"
SKILL_MD = ROOT / "SKILL.md"

ALLOWED_FRONTMATTER = {"name", "description", "license", "allowed-tools", "metadata", "compatibility"}
NAME_PATTERN = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
LINK_TARGET = re.compile(r"\]\(([^)\s]+)")
CODE_SPAN = re.compile(r"`([^`\n]+)`")

SECRET = "sk-abcdefghijklmnopqrstuvwxyz"


# --------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------


def ledger(*args: str) -> subprocess.CompletedProcess[str]:
    """Run the ledger script."""
    return subprocess.run(
        [sys.executable, str(LEDGER), *args], capture_output=True, text=True, check=False
    )


def read_rows(path: Path) -> tuple[list[str], list[dict[str, str]]]:
    """Read a ledger CSV into its header and its rows."""
    with path.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        fields = list(reader.fieldnames or [])
        rows = [
            {key: (value if value is not None else "") for key, value in row.items() if key is not None}
            for row in reader
        ]
    return fields, rows


def write_rows(path: Path, fields: list[str], rows: list[dict[str, str]]) -> None:
    """Write a ledger CSV back with its header."""
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in fields})


def build_reference_run(root: Path) -> Path:
    """A run that lints clean: two hops, three evidence rows, one citation."""
    out = root / "runs"
    out.mkdir(parents=True, exist_ok=True)
    created = ledger(
        "init",
        "--question",
        "Is the reference project production-ready?",
        "--out-dir",
        str(out),
        "--name",
        "reference",
        "--effort",
        "standard",
    )
    if created.returncode != 0:
        raise RuntimeError(f"init failed: {created.stderr}")
    run_dir = out / "reference"

    hops = [
        ("web", "search: reference project production readiness", "found the official docs"),
        ("github", "open the releases page", "releases stop six months ago"),
    ]
    for number, (tool, action, summary) in enumerate(hops, start=1):
        result = ledger(
            "add-hop",
            "--run-dir",
            str(run_dir),
            "--hop",
            str(number),
            "--mode",
            "seed" if number == 1 else "expand",
            "--tool-or-source",
            tool,
            "--query-or-action",
            action,
            "--result-summary",
            summary,
            "--status",
            "done",
        )
        if result.returncode != 0:
            raise RuntimeError(f"add-hop failed: {result.stderr}")

    rows = [
        {
            "source-id": "S001",
            "claim-id": "C001",
            "claim-importance": "central",
            "title": "The reference architecture paper",
            "url": "https://example.org/paper.pdf",
            "family": "authors",
            "date": "2026-02",
            "type": "paper",
            "quality": "5",
            "stance": "supports",
            "independence": "independent",
            "freshness": "current",
            "claim": "The architecture supports concurrent execution",
            "locator": "section 4, table 2",
        },
        {
            "source-id": "S002",
            "claim-id": "C001",
            "claim-importance": "central",
            "title": "The official deployment guide",
            "url": "https://example.com/guide",
            "family": "vendor",
            "date": "2026-03",
            "type": "official-doc",
            "quality": "4",
            "stance": "supports",
            "independence": "independent",
            "freshness": "current",
            "claim": "The vendor documents running the system in production",
            "locator": "Deployment, paragraph 3",
        },
        {
            "source-id": "S003",
            "claim-id": "C001",
            "claim-importance": "central",
            "title": "The scheduler source file",
            "url": "https://github.com/example/reference/blob/main/scheduler.py",
            "family": "maintainers",
            "date": "commit 9f1c2ab",
            "type": "source-code",
            "quality": "4",
            "stance": "contradicts",
            "independence": "independent",
            "freshness": "current",
            "claim": "The scheduler serialises concurrent jobs",
            "locator": "scheduler.py, lines 40-58",
        },
    ]
    for row in rows:
        result = ledger(
            "add-evidence",
            "--run-dir",
            str(run_dir),
            "--hop",
            "1",
            "--source-id",
            row["source-id"],
            "--claim-id",
            row["claim-id"],
            "--claim-importance",
            row["claim-importance"],
            "--title",
            row["title"],
            "--url-or-path",
            row["url"],
            "--source-family",
            row["family"],
            "--date-or-version",
            row["date"],
            "--source-type",
            row["type"],
            "--quality-score",
            row["quality"],
            "--stance",
            row["stance"],
            "--independence-status",
            row["independence"],
            "--freshness-status",
            row["freshness"],
            "--claim",
            row["claim"],
            "--quote-or-locator",
            row["locator"],
        )
        if result.returncode != 0:
            raise RuntimeError(f"add-evidence failed: {result.stderr}")

    rendered = ledger("render", "--run-dir", str(run_dir))
    if rendered.returncode != 0:
        raise RuntimeError(f"render failed: {rendered.stderr}")

    report = run_dir / "final_report.md"
    text = report.read_text(encoding="utf-8")
    report.write_text(
        text.replace(
            "_Pending agent content._",
            "The reference project is deployed in production [E0001].",
            1,
        ),
        encoding="utf-8",
    )
    return run_dir


def lint_output(run_dir: Path) -> tuple[int, str, dict]:
    """Run lint on a run directory and return its exit code, output, and report."""
    result = ledger("lint", "--run-dir", str(run_dir))
    payload: dict = {}
    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError:
        payload = {}
    return result.returncode, result.stdout + result.stderr, payload


def copy_run(source: Path, workdir: Path, name: str) -> Path:
    """A fresh copy of the reference run."""
    target = workdir / name
    shutil.copytree(source, target)
    return target


# --------------------------------------------------------------------------
# Lint: structural errors
# --------------------------------------------------------------------------


def check_invalid_hop_number(workdir: Path, source: Path) -> str | None:
    """A hop that is not a number is an error, not a traceback."""
    run_dir = copy_run(source, workdir, "invalid-hop")
    fields, rows = read_rows(run_dir / "hop_ledger.csv")
    rows[0]["hop"] = "not-a-number"
    write_rows(run_dir / "hop_ledger.csv", fields, rows)
    code, output, _ = lint_output(run_dir)
    if code != 1:
        return f"expected exit 1, got {code}"
    if "invalid hop number" not in output:
        return f"expected the invalid hop number rule, got: {output}"
    return None


def check_hop_below_one(workdir: Path, source: Path) -> str | None:
    """A hop number below one is an error."""
    run_dir = copy_run(source, workdir, "hop-zero")
    fields, rows = read_rows(run_dir / "hop_ledger.csv")
    rows[0]["hop"] = "0"
    write_rows(run_dir / "hop_ledger.csv", fields, rows)
    code, output, _ = lint_output(run_dir)
    if code != 1 or "hop must be >= 1" not in output:
        return f"expected exit 1 naming the hop floor, got {code}: {output}"
    return None


def check_hop_over_hard_max(workdir: Path, source: Path) -> str | None:
    """A hop number past the hard maximum is an error."""
    run_dir = copy_run(source, workdir, "hop-over-max")
    metadata_path = run_dir / "metadata.json"
    metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
    metadata["hard_max_hops"] = 1
    metadata_path.write_text(json.dumps(metadata), encoding="utf-8")
    code, output, _ = lint_output(run_dir)
    if code != 1 or "exceeds hard_max_hops" not in output:
        return f"expected exit 1 naming the hard maximum, got {code}: {output}"
    return None


def check_duplicate_hop(workdir: Path, source: Path) -> str | None:
    """Two rows with the same hop number is an error."""
    run_dir = copy_run(source, workdir, "duplicate-hop")
    fields, rows = read_rows(run_dir / "hop_ledger.csv")
    rows.append(dict(rows[0]))
    write_rows(run_dir / "hop_ledger.csv", fields, rows)
    code, output, _ = lint_output(run_dir)
    if code != 1 or "duplicate hop number" not in output:
        return f"expected exit 1 naming the duplicate hop, got {code}: {output}"
    return None


def check_missing_parent(workdir: Path, source: Path) -> str | None:
    """A hop whose parent does not exist is an error."""
    run_dir = copy_run(source, workdir, "missing-parent")
    fields, rows = read_rows(run_dir / "hop_ledger.csv")
    rows[1]["parent_hop"] = "9"
    write_rows(run_dir / "hop_ledger.csv", fields, rows)
    code, output, _ = lint_output(run_dir)
    if code != 1 or "references missing parent_hop" not in output:
        return f"expected exit 1 naming the missing parent, got {code}: {output}"
    return None


def check_self_parent(workdir: Path, source: Path) -> str | None:
    """A hop that is its own parent is an error."""
    run_dir = copy_run(source, workdir, "self-parent")
    fields, rows = read_rows(run_dir / "hop_ledger.csv")
    rows[1]["parent_hop"] = rows[1]["hop"]
    write_rows(run_dir / "hop_ledger.csv", fields, rows)
    code, output, _ = lint_output(run_dir)
    if code != 1 or "cannot be its own parent" not in output:
        return f"expected exit 1 naming the self parent, got {code}: {output}"
    return None


def check_invalid_parent(workdir: Path, source: Path) -> str | None:
    """A parent hop that is not a number is an error."""
    run_dir = copy_run(source, workdir, "invalid-parent")
    fields, rows = read_rows(run_dir / "hop_ledger.csv")
    rows[1]["parent_hop"] = "parent"
    write_rows(run_dir / "hop_ledger.csv", fields, rows)
    code, output, _ = lint_output(run_dir)
    if code != 1 or "invalid parent_hop" not in output:
        return f"expected exit 1 naming the invalid parent, got {code}: {output}"
    return None


def check_missing_evidence_id(workdir: Path, source: Path) -> str | None:
    """An evidence row with no id is an error."""
    run_dir = copy_run(source, workdir, "missing-evidence-id")
    fields, rows = read_rows(run_dir / "evidence_ledger.csv")
    rows[0]["evidence_id"] = ""
    write_rows(run_dir / "evidence_ledger.csv", fields, rows)
    code, output, _ = lint_output(run_dir)
    if code != 1 or "missing evidence_id" not in output:
        return f"expected exit 1 naming the missing id, got {code}: {output}"
    return None


def check_duplicate_evidence_id(workdir: Path, source: Path) -> str | None:
    """Two evidence rows with one id is an error."""
    run_dir = copy_run(source, workdir, "duplicate-evidence-id")
    fields, rows = read_rows(run_dir / "evidence_ledger.csv")
    rows[1]["evidence_id"] = rows[0]["evidence_id"]
    write_rows(run_dir / "evidence_ledger.csv", fields, rows)
    code, output, _ = lint_output(run_dir)
    if code != 1 or "duplicate evidence_id" not in output:
        return f"expected exit 1 naming the duplicate id, got {code}: {output}"
    return None


def check_missing_required_field(workdir: Path, source: Path) -> str | None:
    """An evidence row missing a required field is an error."""
    run_dir = copy_run(source, workdir, "missing-field")
    fields, rows = read_rows(run_dir / "evidence_ledger.csv")
    rows[0]["title"] = ""
    write_rows(run_dir / "evidence_ledger.csv", fields, rows)
    code, output, _ = lint_output(run_dir)
    if code != 1 or "missing title" not in output:
        return f"expected exit 1 naming the missing field, got {code}: {output}"
    return None


def check_invalid_quality_score(workdir: Path, source: Path) -> str | None:
    """A quality score outside one to five is an error."""
    run_dir = copy_run(source, workdir, "bad-quality")
    fields, rows = read_rows(run_dir / "evidence_ledger.csv")
    rows[0]["quality_score"] = "9"
    write_rows(run_dir / "evidence_ledger.csv", fields, rows)
    code, output, _ = lint_output(run_dir)
    if code != 1 or "invalid quality_score" not in output:
        return f"expected exit 1 naming the quality score, got {code}: {output}"
    return None


def check_unknown_citation(workdir: Path, source: Path) -> str | None:
    """A citation that resolves to no row is an error, at any id width."""
    run_dir = copy_run(source, workdir, "unknown-citation")
    report = run_dir / "final_report.md"
    report.write_text(
        report.read_text(encoding="utf-8") + "\nA wide citation [E10000] and a narrow one [E1].\n",
        encoding="utf-8",
    )
    code, output, _ = lint_output(run_dir)
    if code != 1 or "cites unknown evidence ids" not in output:
        return f"expected exit 1 naming the unknown citation, got {code}: {output}"
    if "E10000" not in output or "E1" not in output:
        return f"expected both citation widths named, got: {output}"
    return None


def check_truncated_csv(workdir: Path, source: Path) -> str | None:
    """A truncated row is a clean error, not a traceback."""
    run_dir = copy_run(source, workdir, "truncated")
    with (run_dir / "evidence_ledger.csv").open("a", encoding="utf-8") as handle:
        handle.write("E0009,2026-01-01T00:00:00+00:00,1\n")
    code, output, _ = lint_output(run_dir)
    if "Traceback" in output:
        return f"a truncated row must not traceback, got: {output}"
    if code != 1 or "E0009 missing source_id" not in output:
        return f"expected exit 1 naming the incomplete row, got {code}: {output}"
    return None


# --------------------------------------------------------------------------
# Lint: research-quality warnings
# --------------------------------------------------------------------------


def check_missing_source_family(workdir: Path, source: Path) -> str | None:
    """A supporting row with no source family is a warning that names the row."""
    run_dir = copy_run(source, workdir, "missing-family")
    fields, rows = read_rows(run_dir / "evidence_ledger.csv")
    rows[0]["source_family"] = ""
    write_rows(run_dir / "evidence_ledger.csv", fields, rows)
    code, output, _ = lint_output(run_dir)
    if code != 0:
        return f"a missing family is a warning, not an error; got exit {code}"
    if "E0001" not in output or "missing source_family" not in output:
        return f"expected the warning to name the row, got: {output}"
    return None


def check_context_is_not_counterevidence(workdir: Path, source: Path) -> str | None:
    """A context row satisfies neither counterevidence check."""
    run_dir = copy_run(source, workdir, "context-only")
    fields, rows = read_rows(run_dir / "evidence_ledger.csv")
    rows[2]["stance"] = "context"
    write_rows(run_dir / "evidence_ledger.csv", fields, rows)
    code, output, _ = lint_output(run_dir)
    if code != 0:
        return f"expected exit 0, got {code}: {output}"
    if "no contradictory/unclear evidence recorded" not in output:
        return f"expected the global counterevidence warning, got: {output}"
    if "has no contradictory or unclear evidence row" not in output:
        return f"expected the per-claim counterevidence warning, got: {output}"
    return None


def check_github_only_is_not_primary(workdir: Path, source: Path) -> str | None:
    """A repository row is not primary evidence on its own."""
    run_dir = copy_run(source, workdir, "github-only")
    fields, rows = read_rows(run_dir / "evidence_ledger.csv")
    for row in rows:
        row["source_type"] = "github"
    write_rows(run_dir / "evidence_ledger.csv", fields, rows)
    code, output, _ = lint_output(run_dir)
    if code != 0:
        return f"expected exit 0, got {code}: {output}"
    if "no primary or near-primary evidence recorded" not in output:
        return f"expected the primary evidence warning, got: {output}"
    return None


def check_too_few_source_classes(workdir: Path, source: Path) -> str | None:
    """Too few source classes for the effort tier is a warning."""
    run_dir = copy_run(source, workdir, "few-classes")
    fields, rows = read_rows(run_dir / "evidence_ledger.csv")
    for row in rows:
        row["source_type"] = "paper"
    write_rows(run_dir / "evidence_ledger.csv", fields, rows)
    code, output, _ = lint_output(run_dir)
    if code != 0 or "source classes recorded" not in output:
        return f"expected the source class warning, got {code}: {output}"
    return None


def check_too_few_support_families(workdir: Path, source: Path) -> str | None:
    """Too few independent support families is a warning."""
    run_dir = copy_run(source, workdir, "few-families")
    fields, rows = read_rows(run_dir / "evidence_ledger.csv")
    rows[1]["source_family"] = ""
    write_rows(run_dir / "evidence_ledger.csv", fields, rows)
    code, output, _ = lint_output(run_dir)
    if code != 0 or "independent support source families" not in output:
        return f"expected the support family warning, got {code}: {output}"
    return None


def check_report_without_citation(workdir: Path, source: Path) -> str | None:
    """A report whose tables carry the ids but whose prose does not is a warning."""
    run_dir = copy_run(source, workdir, "no-citation")
    report = run_dir / "final_report.md"
    report.write_text(
        report.read_text(encoding="utf-8").replace("[E0001]", "the first row"), encoding="utf-8"
    )
    code, output, _ = lint_output(run_dir)
    if code != 0 or "does not cite evidence ids like [E0001]" not in output:
        return f"expected the citation warning, got {code}: {output}"
    return None


def check_empty_hop_field(workdir: Path, source: Path) -> str | None:
    """A hop with an empty field is a warning."""
    run_dir = copy_run(source, workdir, "empty-hop-field")
    fields, rows = read_rows(run_dir / "hop_ledger.csv")
    rows[0]["result_summary"] = ""
    write_rows(run_dir / "hop_ledger.csv", fields, rows)
    code, output, _ = lint_output(run_dir)
    if code != 0 or "hop 1 missing result_summary" not in output:
        return f"expected the hop field warning, got {code}: {output}"
    return None


def check_high_impact_missing_locator(workdir: Path, source: Path) -> str | None:
    """A high-impact row without a locator is a warning."""
    run_dir = copy_run(source, workdir, "no-locator")
    fields, rows = read_rows(run_dir / "evidence_ledger.csv")
    rows[0]["quote_or_locator"] = ""
    write_rows(run_dir / "evidence_ledger.csv", fields, rows)
    code, output, _ = lint_output(run_dir)
    if code != 0 or "is high-impact but missing quote_or_locator" not in output:
        return f"expected the locator warning, got {code}: {output}"
    return None


def check_hop_count_over_target(workdir: Path, source: Path) -> str | None:
    """More hops than the target is a warning about the count."""
    run_dir = copy_run(source, workdir, "over-target")
    fields, rows = read_rows(run_dir / "hop_ledger.csv")
    for number in range(3, 11):
        rows.append(
            {
                "hop": str(number),
                "timestamp_utc": "2026-01-01T00:00:00+00:00",
                "parent_hop": "",
                "mode": "expand",
                "tool_or_source": "web",
                "query_or_action": f"search {number}",
                "target_url_or_path": "",
                "result_summary": "found something",
                "new_entities": "",
                "evidence_ids": "",
                "next_questions": "",
                "status": "done",
            }
        )
    write_rows(run_dir / "hop_ledger.csv", fields, rows)
    code, output, _ = lint_output(run_dir)
    if code != 0 or "exceeds target" not in output:
        return f"expected the hop count warning, got {code}: {output}"
    return None


# --------------------------------------------------------------------------
# Commands
# --------------------------------------------------------------------------


def check_init_rejects_traversal(workdir: Path, source: Path) -> str | None:
    """A name that points outside the output directory is refused."""
    victim = workdir / "victim"
    victim.mkdir(parents=True, exist_ok=True)
    keeper = victim / "keep.txt"
    keeper.write_text("important\n", encoding="utf-8")
    out_dir = workdir / "out"
    out_dir.mkdir(parents=True, exist_ok=True)

    result = ledger(
        "init",
        "--question",
        "q",
        "--out-dir",
        str(out_dir),
        "--name",
        "../victim",
        "--force",
    )
    if result.returncode != 2:
        return f"expected exit 2, got {result.returncode}: {result.stderr}"
    if "containment rule" not in result.stderr:
        return f"expected the containment rule named, got: {result.stderr}"
    if not keeper.exists() or keeper.read_text(encoding="utf-8") != "important\n":
        return "the directory outside --out-dir was touched"
    return None


def check_init_rejects_hard_max_below_target(workdir: Path, source: Path) -> str | None:
    """A hard maximum below the hop target is refused."""
    out_dir = workdir / "out-hard-max"
    out_dir.mkdir(parents=True, exist_ok=True)
    result = ledger(
        "init",
        "--question",
        "q",
        "--out-dir",
        str(out_dir),
        "--name",
        "run",
        "--effort",
        "deep",
        "--hard-max-hops",
        "2",
    )
    if result.returncode != 2 or "hard_max_hops" not in result.stderr:
        return f"expected exit 2 naming hard_max_hops, got {result.returncode}: {result.stderr}"
    return None


def check_lint_and_status_do_not_mutate(workdir: Path, source: Path) -> str | None:
    """lint and status read the ledgers; they never rewrite them."""
    run_dir = copy_run(source, workdir, "read-only")
    ledgers = [run_dir / "hop_ledger.csv", run_dir / "evidence_ledger.csv"]
    before = [path.read_bytes() for path in ledgers]
    lint_output(run_dir)
    status_result = ledger("status", "--run-dir", str(run_dir))
    if status_result.returncode != 0:
        return f"status failed: {status_result.stderr}"
    after = [path.read_bytes() for path in ledgers]
    if before != after:
        return "lint or status rewrote a ledger CSV"
    return None


def check_secrets_are_rejected(workdir: Path, source: Path) -> str | None:
    """A credential in any field is refused, with the field named."""
    run_dir = copy_run(source, workdir, "secrets")
    cases = {
        "title": f"the key {SECRET}",
        "claim": f"the key {SECRET}",
        "quote_or_locator": f"the key {SECRET}",
        "notes": f"the key {SECRET}",
        "url_or_path": f"https://example.com/?token={SECRET}",
    }
    for field, value in cases.items():
        arguments = [
            "add-evidence",
            "--run-dir",
            str(run_dir),
            "--hop",
            "1",
            "--source-id",
            "S999",
            "--title",
            "a title",
            "--url-or-path",
            "https://example.com/x",
            "--source-type",
            "blog",
            "--quality-score",
            "3",
            "--stance",
            "supports",
            "--claim",
            "a claim",
        ]
        arguments += [f"--{field.replace('_', '-')}", value]
        result = ledger(*arguments)
        if result.returncode != 1:
            return f"{field}: expected exit 1, got {result.returncode}: {result.stderr}"
        if field not in result.stderr:
            return f"{field}: expected the field named, got: {result.stderr}"
        if "[REDACTED]" not in result.stderr:
            return f"{field}: expected the redaction marker named, got: {result.stderr}"
    ledger_text = (run_dir / "evidence_ledger.csv").read_text(encoding="utf-8")
    if SECRET in ledger_text:
        return "a secret reached the evidence ledger"
    return None


def check_render_lists_every_evidence_id(workdir: Path, source: Path) -> str | None:
    """The rendered evidence table carries every logged id."""
    run_dir = copy_run(source, workdir, "render")
    first = ledger("render", "--run-dir", str(run_dir))
    if first.returncode != 0:
        return f"render failed: {first.stderr}"
    report_path = run_dir / "final_report.md"
    report = report_path.read_text(encoding="utf-8")
    _, rows = read_rows(run_dir / "evidence_ledger.csv")
    for row in rows:
        if row["evidence_id"] not in report:
            return f"the report is missing evidence id {row['evidence_id']}"
    before = report_path.read_bytes()
    second = ledger("render", "--run-dir", str(run_dir))
    if second.returncode != 0:
        return f"the second render failed: {second.stderr}"
    if report_path.read_bytes() != before:
        return "two renders over the same ledger produced different bytes"
    return None


def check_evidence_id_assignment(workdir: Path, source: Path) -> str | None:
    """Auto-assignment fills the sequence and never reuses an id."""
    out_dir = workdir / "ids"
    out_dir.mkdir(parents=True, exist_ok=True)
    ledger("init", "--question", "q", "--out-dir", str(out_dir), "--name", "run")
    run_dir = out_dir / "run"
    ledger("add-hop", "--run-dir", str(run_dir), "--hop", "1", "--tool-or-source", "web",
           "--query-or-action", "search")
    first = ledger("add-evidence", "--run-dir", str(run_dir), "--hop", "1", "--source-id", "S1",
                   "--title", "t", "--url-or-path", "https://example.com", "--source-type", "paper",
                   "--quality-score", "3", "--stance", "supports", "--claim", "c")
    second = ledger("add-evidence", "--run-dir", str(run_dir), "--hop", "1", "--source-id", "S2",
                    "--title", "t", "--url-or-path", "https://example.com", "--source-type", "paper",
                    "--quality-score", "3", "--stance", "supports", "--claim", "c")
    if "E0001" not in first.stdout or "E0002" not in second.stdout:
        return f"expected E0001 then E0002, got {first.stdout!r} and {second.stdout!r}"
    taken = ledger("add-evidence", "--run-dir", str(run_dir), "--hop", "1", "--source-id", "S3",
                   "--evidence-id", "E0001", "--title", "t", "--url-or-path", "https://example.com",
                   "--source-type", "paper", "--quality-score", "3", "--stance", "supports",
                   "--claim", "c")
    if taken.returncode != 2:
        return f"expected a duplicate id to be refused, got {taken.returncode}"
    third = ledger("add-evidence", "--run-dir", str(run_dir), "--hop", "1", "--source-id", "S4",
                   "--title", "t", "--url-or-path", "https://example.com", "--source-type", "paper",
                   "--quality-score", "3", "--stance", "supports", "--claim", "c")
    if "E0003" not in third.stdout:
        return f"expected the sequence to continue at E0003, got {third.stdout!r}"
    return None


def check_reference_run_is_clean(workdir: Path, source: Path) -> str | None:
    """The known-good run must lint without an error and without a warning."""
    code, output, payload = lint_output(source)
    if code != 0:
        return f"the reference run must lint clean, got exit {code}: {output}"
    if payload.get("errors"):
        return f"the reference run must lint clean, got errors: {payload['errors']}"
    if payload.get("warnings"):
        return f"the reference run must lint clean, got warnings: {payload['warnings']}"
    return None


# --------------------------------------------------------------------------
# The effort ladder
# --------------------------------------------------------------------------


def load_ledger_module():
    """The ledger script, imported without running it."""
    spec = importlib.util.spec_from_file_location("research_ledger", LEDGER)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def read_effort_block() -> dict:
    """The effort ladder as the reference prose states it."""
    text = PROTOCOL.read_text(encoding="utf-8")
    match = re.search(r"^```toml[ \t]+effort-ladder[ \t]*\n(.*?)^```[ \t]*$", text, re.M | re.S)
    if not match:
        raise RuntimeError("references/research-protocol.md has no ```toml effort-ladder block")
    document = tomllib.loads(match.group(1))
    return {
        tier: {key: int(value) for key, value in values.items()}
        for tier, values in document.get("effort", {}).items()
    }


def check_effort_ladder_matches_the_script(workdir: Path, source: Path) -> str | None:
    """The ladder in the prose and the ladder in the script are one ladder."""
    prose = read_effort_block()
    module = load_ledger_module()
    builtin = module.EFFORT_DEFAULTS
    if prose != builtin:
        return (
            "the effort ladder drifted between references/research-protocol.md and the script\n"
            f"  prose:   {prose}\n"
            f"  builtin: {builtin}"
        )
    if module.effort_ladder() != prose:
        return "the script does not read the ladder from the reference prose"
    return None


def check_effort_ladder_is_used_at_runtime(workdir: Path, source: Path) -> str | None:
    """The script honours the ladder in the prose, not its own copy."""
    tree = workdir / "skill"
    shutil.copytree(ROOT, tree)
    protocol = tree / "references" / "research-protocol.md"
    text = protocol.read_text(encoding="utf-8")
    patched = re.sub(
        r"(\[effort\.deep\]\nhop_target = )\d+",
        r"\g<1>21",
        text,
    )
    if patched == text:
        return "could not patch the deep hop_target in the reference ladder"
    protocol.write_text(patched, encoding="utf-8")

    out_dir = workdir / "effort-out"
    out_dir.mkdir(parents=True, exist_ok=True)
    result = subprocess.run(
        [
            sys.executable,
            str(tree / "scripts" / "research_ledger.py"),
            "init",
            "--question",
            "q",
            "--out-dir",
            str(out_dir),
            "--name",
            "run",
            "--effort",
            "deep",
        ],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        return f"init failed: {result.stderr}"
    metadata = json.loads((out_dir / "run" / "metadata.json").read_text(encoding="utf-8"))
    if metadata["hop_target"] != 21:
        return f"expected the patched hop_target 21, got {metadata['hop_target']}"
    return None


# --------------------------------------------------------------------------
# The skill's own structure
# --------------------------------------------------------------------------


def parse_frontmatter(text: str) -> dict[str, str]:
    """The top-level frontmatter fields of a markdown file."""
    if not text.startswith("---\n"):
        return {}
    end = text.find("\n---", 3)
    if end == -1:
        return {}
    fields: dict[str, str] = {}
    for line in text[4:end].splitlines():
        if not line.strip() or line.startswith((" ", "\t")):
            continue
        key, _, value = line.partition(":")
        fields[key.strip()] = value.strip().strip('"')
    return fields


def check_spec_frontmatter(workdir: Path, source: Path) -> str | None:
    """The frontmatter carries only the fields the specification allows."""
    text = SKILL_MD.read_text(encoding="utf-8")
    fields = parse_frontmatter(text)
    if not fields:
        return "SKILL.md has no frontmatter"
    extra = set(fields) - ALLOWED_FRONTMATTER
    if extra:
        return f"frontmatter carries fields the specification does not allow: {sorted(extra)}"
    name = fields.get("name", "")
    if name != ROOT.name:
        return f"the name {name!r} does not match the directory {ROOT.name!r}"
    if not NAME_PATTERN.match(name):
        return f"the name {name!r} is not a lowercase hyphenated phrase"
    description = fields.get("description", "")
    if not 1 <= len(description) <= 1024:
        return f"the description is {len(description)} characters, outside 1-1024"
    compatibility = fields.get("compatibility", "")
    if len(compatibility) > 500:
        return f"the compatibility is {len(compatibility)} characters, over the 500 limit"
    return None


def check_spec_body_length(workdir: Path, source: Path) -> str | None:
    """The SKILL.md body stays under five hundred lines."""
    text = SKILL_MD.read_text(encoding="utf-8")
    end = text.find("\n---", 3)
    body = text[end + 4 :] if end != -1 else text
    lines = len(body.splitlines())
    if lines >= 500:
        return f"the SKILL.md body is {lines} lines, at or over the 500 limit"
    return None


def check_spec_reference_links(workdir: Path, source: Path) -> str | None:
    """Every reference file is linked from SKILL.md, and no reference links to another."""
    skill_text = SKILL_MD.read_text(encoding="utf-8")
    references = sorted((ROOT / "references").glob("*.md"))
    if not references:
        return "the skill ships no reference files"
    for reference in references:
        target = f"references/{reference.name}"
        if target not in skill_text:
            return f"{target} is not linked from SKILL.md"
    for reference in references:
        text = reference.read_text(encoding="utf-8")
        for link in LINK_TARGET.findall(text):
            if link.endswith(".md") or link.startswith("references/"):
                return f"{reference.name} links to another reference file: {link}"
    return None


def check_spec_forward_slashes(workdir: Path, source: Path) -> str | None:
    """Every path in the markdown uses forward slashes."""
    for markdown in sorted(ROOT.rglob("*.md")):
        text = markdown.read_text(encoding="utf-8")
        for link in LINK_TARGET.findall(text):
            if "\\" in link:
                return f"{markdown.name} links with a backslash: {link}"
        for span in CODE_SPAN.findall(text):
            if "/" in span and "\\" in span:
                return f"{markdown.name} writes a path with a backslash: {span}"
    return None


def check_spec_directory_layout(workdir: Path, source: Path) -> str | None:
    """The skill ships the files the layout promises."""
    required = [
        "SKILL.md",
        "agents/openai.yaml",
        "references/research-protocol.md",
        "references/source-quality.md",
        "references/query-playbook.md",
        "references/academic-sources.md",
        "references/report-template.md",
        "references/evaluation.md",
        "scripts/research_ledger.py",
        "evals/evals.json",
        "evals/trigger_queries.json",
        "tests/run.py",
    ]
    missing = [name for name in required if not (ROOT / name).exists()]
    if missing:
        return f"the skill is missing: {missing}"
    return None


def check_eval_suites_are_well_formed(workdir: Path, source: Path) -> str | None:
    """The two eval files carry the shape their harnesses read."""
    evals = json.loads((ROOT / "evals" / "evals.json").read_text(encoding="utf-8"))
    if evals.get("skill_name") != "deep-research":
        return "evals/evals.json must name the skill"
    cases = evals.get("evals")
    if not isinstance(cases, list) or not cases:
        return "evals/evals.json must carry a non-empty evals array"
    for case in cases:
        for key in ("id", "prompt", "expected_output"):
            if key not in case:
                return f"an eval case is missing {key}"
        if not case.get("assertions"):
            return f"eval case {case.get('id')} carries no assertions"

    triggers = json.loads((ROOT / "evals" / "trigger_queries.json").read_text(encoding="utf-8"))
    if not isinstance(triggers, dict):
        return "evals/trigger_queries.json must carry skill, workflow_marker and queries"
    if triggers.get("skill") != "deep-research":
        return "evals/trigger_queries.json must name the skill"
    if not triggers.get("workflow_marker"):
        return "evals/trigger_queries.json must name a workflow_marker"
    entries = triggers.get("queries")
    if not isinstance(entries, list) or not entries:
        return "evals/trigger_queries.json must carry a non-empty queries array"
    positives = 0
    negatives = 0
    for entry in entries:
        if "query" not in entry or "should_trigger" not in entry:
            return "a trigger query is missing query or should_trigger"
        if not isinstance(entry.get("holdout"), bool):
            return "a trigger query is missing the holdout flag"
        if entry["should_trigger"]:
            positives += 1
        else:
            negatives += 1
    if positives < 5 or negatives < 5:
        return f"the trigger suite needs at least five cases in each direction, got {positives}/{negatives}"
    return None


# --------------------------------------------------------------------------
# The run
# --------------------------------------------------------------------------


CHECKS: list = [
    check_reference_run_is_clean,
    check_invalid_hop_number,
    check_hop_below_one,
    check_hop_over_hard_max,
    check_duplicate_hop,
    check_missing_parent,
    check_self_parent,
    check_invalid_parent,
    check_missing_evidence_id,
    check_duplicate_evidence_id,
    check_missing_required_field,
    check_invalid_quality_score,
    check_unknown_citation,
    check_truncated_csv,
    check_missing_source_family,
    check_context_is_not_counterevidence,
    check_github_only_is_not_primary,
    check_too_few_source_classes,
    check_too_few_support_families,
    check_report_without_citation,
    check_empty_hop_field,
    check_high_impact_missing_locator,
    check_hop_count_over_target,
    check_init_rejects_traversal,
    check_init_rejects_hard_max_below_target,
    check_lint_and_status_do_not_mutate,
    check_secrets_are_rejected,
    check_render_lists_every_evidence_id,
    check_evidence_id_assignment,
    check_effort_ladder_matches_the_script,
    check_effort_ladder_is_used_at_runtime,
    check_spec_frontmatter,
    check_spec_body_length,
    check_spec_reference_links,
    check_spec_forward_slashes,
    check_spec_directory_layout,
    check_eval_suites_are_well_formed,
]


def main() -> int:
    """Run every check and report the ones that failed."""
    failures: list[str] = []
    with tempfile.TemporaryDirectory(prefix="deep-research-tests-") as tmp:
        workdir = Path(tmp)
        source = build_reference_run(workdir)
        for check in CHECKS:
            try:
                failure = check(workdir, source)
            except Exception as exc:  # a broken check is a failed check
                failure = f"raised {type(exc).__name__}: {exc}"
            if failure:
                failures.append(f"{check.__name__}: {failure}")

    if failures:
        for failure in failures:
            print(f"FAIL: {failure}", file=sys.stderr)
        print(f"{len(failures)} of {len(CHECKS)} checks failed", file=sys.stderr)
        return 1
    print(f"OK: {len(CHECKS)} checks pass")
    return 0


if __name__ == "__main__":
    sys.exit(main())
