#!/usr/bin/env python3
"""Manage the deep-research hop and evidence ledger.

    python3 scripts/research_ledger.py init --question "..." [--out-dir DIR] [--effort TIER]
    python3 scripts/research_ledger.py add-hop --run-dir DIR --hop N \
        --tool-or-source X --query-or-action Y
    python3 scripts/research_ledger.py add-evidence --run-dir DIR --hop N --source-id S1 \
        --title T --url-or-path U --source-type paper --quality-score 5 --stance supports \
        --claim "..."
    python3 scripts/research_ledger.py render --run-dir DIR [--out PATH]
    python3 scripts/research_ledger.py lint --run-dir DIR
    python3 scripts/research_ledger.py status --run-dir DIR

The script never searches the web. It creates and checks the audit artefacts while
the agent browses, reads files, and queries APIs. The effort ladder is read from
the ``toml effort-ladder`` block in ``references/research-protocol.md`` at run
time, so the prose and the script cannot drift apart.

Exit status: 0 clean, 1 findings, 2 usage error or unreadable input.
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path

try:  # Python 3.11+; the fallback keeps the script usable on 3.10.
    import tomllib
except ImportError:  # pragma: no cover - exercised only on old interpreters
    tomllib = None  # type: ignore[assignment]

SKILL_ROOT = Path(__file__).resolve().parent.parent
REFERENCES = SKILL_ROOT / "references"
EFFORT_REFERENCE = REFERENCES / "research-protocol.md"

HOP_FIELDS = [
    "hop",
    "timestamp_utc",
    "parent_hop",
    "mode",
    "tool_or_source",
    "query_or_action",
    "target_url_or_path",
    "result_summary",
    "new_entities",
    "evidence_ids",
    "next_questions",
    "status",
]

EVIDENCE_FIELDS = [
    "evidence_id",
    "timestamp_utc",
    "hop",
    "source_id",
    "claim_id",
    "claim_importance",
    "title",
    "url_or_path",
    "publisher_or_owner",
    "source_family",
    "date_or_version",
    "accessed_utc",
    "source_type",
    "source_subtype",
    "quality_score",
    "stance",
    "independence_status",
    "freshness_status",
    "uncertainty_label",
    "claim",
    "quote_or_locator",
    "notes",
]

# The built-in ladder is the fallback for an unreadable reference file. The
# reference prose is the source of truth; tests/run.py fails when the two drift.
EFFORT_DEFAULTS: dict[str, dict[str, int]] = {
    "quick": {"hop_target": 4, "source_diversity_target": 2, "min_independent_sources": 2},
    "standard": {"hop_target": 8, "source_diversity_target": 3, "min_independent_sources": 2},
    "deep": {"hop_target": 14, "source_diversity_target": 4, "min_independent_sources": 2},
    "exhaustive": {"hop_target": 24, "source_diversity_target": 5, "min_independent_sources": 3},
}
EFFORT_TIERS = ("quick", "standard", "deep", "exhaustive")

SOURCE_TYPES = [
    "paper",
    "preprint",
    "official-doc",
    "vendor-doc",
    "github",
    "source-code",
    "release-note",
    "changelog",
    "benchmark",
    "dataset",
    "dataset-card",
    "data",
    "security-advisory",
    "standard",
    "filing",
    "local-file",
    "blog",
    "news",
    "forum",
    "social",
]

# A repository, a leaderboard and a blog post are not primary evidence on their
# own: the artefact behind them is.
PRIMARY_TYPES = {
    "paper",
    "preprint",
    "official-doc",
    "source-code",
    "release-note",
    "changelog",
    "standard",
    "filing",
    "security-advisory",
    "dataset",
}

# One definition of counterevidence, used by the global check and the per-claim
# check alike. A `context` row supports neither.
COUNTER_STANCES = {"contradicts", "unclear"}
HIGH_IMPORTANCE = {"high", "central"}
CLAIM_IMPORTANCE = ["low", "medium", "high", "central"]
INDEPENDENCE_STATUS = [
    "independent",
    "same-family",
    "derivative",
    "single-source",
    "unknown",
    "not-applicable",
]
FRESHNESS_STATUS = ["current", "stale", "versioned", "undated", "unknown", "not-applicable"]
UNCERTAINTY_LABELS = [
    "none",
    "single-source",
    "weak",
    "stale",
    "contested",
    "unknown",
    "not-applicable",
]

# Weakest first: the claim's freshness is the weakest status among its rows.
FRESHNESS_RANK = {
    "stale": 0,
    "undated": 1,
    "unknown": 2,
    "versioned": 3,
    "current": 4,
    "not-applicable": 5,
}

SECRET_PATTERNS = [
    re.compile(r"(?i)(api[_-]?key|secret|token|password|passwd|private[_-]?key)\s*[:=]\s*['\"]?[A-Za-z0-9_./+=-]{12,}"),
    re.compile(r"sk-[A-Za-z0-9]{20,}"),
    re.compile(r"gh[pousr]_[A-Za-z0-9_]{20,}"),
    re.compile(r"AKIA[0-9A-Z]{16}"),
    re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----"),
]

REDACTION = "[REDACTED]"

# The fenced block in the reference file that carries the ladder.
EFFORT_FENCE = re.compile(r"^```toml[ \t]+effort-ladder[ \t]*\n(.*?)^```[ \t]*$", re.M | re.S)

# The report sections the agent writes, and the ones the script generates.
AGENT_SECTIONS = (
    "Executive summary",
    "Direct answer",
    "Key findings",
    "Contradictions and uncertainty",
    "Source-quality notes",
)
GENERATED_SECTIONS = (
    "Claim verification matrix",
    "Evidence table",
    "Method appendix",
)
# The order of the report, matching the output contract in references/report-template.md.
REPORT_SECTIONS = (
    "Executive summary",
    "Direct answer",
    "Key findings",
    "Claim verification matrix",
    "Evidence table",
    "Contradictions and uncertainty",
    "Source-quality notes",
    "Method appendix",
)
PLACEHOLDER = "_Pending agent content._"

_EFFORT_LADDER: dict[str, dict[str, int]] | None = None


class UsageError(Exception):
    """The command was asked to do something it must not do. Exit 2."""


class ContentFinding(Exception):
    """The content carries a problem worth failing on. Exit 1."""


# --------------------------------------------------------------------------
# Effort ladder
# --------------------------------------------------------------------------


def _load_effort_ladder() -> dict[str, dict[str, int]]:
    """Read the ladder from the reference prose, falling back to the built-ins."""
    try:
        text = EFFORT_REFERENCE.read_text(encoding="utf-8")
    except OSError:
        return {tier: dict(values) for tier, values in EFFORT_DEFAULTS.items()}
    match = EFFORT_FENCE.search(text)
    if not match or tomllib is None:
        return {tier: dict(values) for tier, values in EFFORT_DEFAULTS.items()}
    try:
        document = tomllib.loads(match.group(1))
    except (tomllib.TOMLDecodeError, ValueError):
        return {tier: dict(values) for tier, values in EFFORT_DEFAULTS.items()}
    tiers = document.get("effort")
    if not isinstance(tiers, dict):
        return {tier: dict(values) for tier, values in EFFORT_DEFAULTS.items()}
    ladder: dict[str, dict[str, int]] = {}
    for tier, values in tiers.items():
        if not isinstance(values, dict):
            continue
        try:
            ladder[tier] = {key: int(value) for key, value in values.items()}
        except (TypeError, ValueError):
            continue
    return ladder or {tier: dict(values) for tier, values in EFFORT_DEFAULTS.items()}


def effort_ladder() -> dict[str, dict[str, int]]:
    """The effort ladder, read once per process."""
    global _EFFORT_LADDER
    if _EFFORT_LADDER is None:
        _EFFORT_LADDER = _load_effort_ladder()
    return _EFFORT_LADDER


def effort_defaults(effort: str) -> dict[str, int]:
    """The three targets for one effort tier."""
    ladder = effort_ladder()
    if effort in ladder:
        return dict(ladder[effort])
    return dict(EFFORT_DEFAULTS.get(effort, EFFORT_DEFAULTS["standard"]))


def checkpoint_text(target: int) -> str:
    """When to pause and summarise, for a hop target."""
    if target <= 4:
        return "after the first useful source and again before finalizing"
    first = max(2, round(target / 3))
    second = max(first + 1, round(2 * target / 3))
    return f"around hops {first} and {second}, then again before finalizing"


# --------------------------------------------------------------------------
# Small helpers
# --------------------------------------------------------------------------


def now_utc() -> str:
    """The current time, second resolution, UTC."""
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def slugify(text: str, limit: int = 60) -> str:
    """A filesystem-safe slug from arbitrary text."""
    slug = re.sub(r"[^a-zA-Z0-9]+", "-", text.lower()).strip("-")
    return (slug or "research-run")[:limit].strip("-") or "research-run"


def ensure_dir(path: Path) -> None:
    """Create a directory and its parents."""
    path.mkdir(parents=True, exist_ok=True)


def read_json(path: Path, default: object) -> object:
    """Read JSON, or return the default when the file is absent."""
    if not path.exists():
        return default
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise UsageError(f"cannot read {path}: {exc}") from exc


def write_json(path: Path, payload: object) -> None:
    """Write JSON with a trailing newline."""
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def read_csv(path: Path) -> list[dict[str, str]]:
    """Read a CSV into dicts whose every cell is a string.

    A hand-edited or truncated row must lint as a clean error, not crash the
    reader: ``csv.DictReader`` leaves missing trailing columns as ``None`` and
    overflow columns under a ``None`` key, so every cell is normalised here.
    """
    if not path.exists():
        return []
    try:
        with path.open("r", encoding="utf-8", newline="") as handle:
            reader = csv.DictReader(handle)
            rows: list[dict[str, str]] = []
            for raw in reader:
                row = {
                    key: ("" if value is None else str(value))
                    for key, value in raw.items()
                    if key is not None
                }
                rows.append(row)
    except (OSError, UnicodeDecodeError, csv.Error) as exc:
        raise UsageError(f"cannot read {path}: {exc}") from exc
    return rows


def write_csv(path: Path, fields: list[str], rows: list[dict[str, str]]) -> None:
    """Write a CSV with the given column order."""
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in fields})


def append_csv(path: Path, fields: list[str], row: dict[str, str]) -> None:
    """Append one row, writing the header when the file is new or empty."""
    exists = path.exists() and path.stat().st_size > 0
    with path.open("a", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        if not exists:
            writer.writeheader()
        writer.writerow({field: row.get(field, "") for field in fields})


def positive_int(value: int | str | None, name: str) -> int | None:
    """Parse a positive integer argument, or fail."""
    if value is None:
        return None
    try:
        number = int(value)
    except (TypeError, ValueError):
        raise UsageError(f"{name} must be a positive integer") from None
    if number < 1:
        raise UsageError(f"{name} must be >= 1")
    return number


def parse_hop_set(rows: list[dict[str, str]]) -> set[int]:
    """The hop numbers that exist in a hop ledger."""
    hops: set[int] = set()
    for row in rows:
        try:
            hop = int(row.get("hop", "") or "")
        except (TypeError, ValueError):
            continue
        if hop >= 1:
            hops.add(hop)
    return hops


def domain_of(url_or_path: str) -> str:
    """The host or root of a path, for the status summary only."""
    if not url_or_path:
        return ""
    match = re.match(r"^https?://([^/:?#]+)", url_or_path)
    if match:
        return match.group(1).lower().removeprefix("www.")
    if url_or_path.startswith("/") or re.match(r"^[A-Za-z]:", url_or_path):
        return "local-file"
    return url_or_path.split("/")[0].lower()


def source_family_of(row: dict[str, str]) -> str:
    """The recorded source family, or nothing.

    There is no domain fallback: two papers on the same preprint server are two
    families, and a missing family is reported rather than guessed.
    """
    return (row.get("source_family") or "").strip()


def quality_int(row: dict[str, str]) -> int:
    """The quality score as an integer, or zero when it is unusable."""
    try:
        return int(row.get("quality_score") or "0")
    except (TypeError, ValueError):
        return 0


def looks_like_secret(value: str) -> bool:
    """Whether one field carries something that looks like a credential."""
    if not value:
        return False
    return any(pattern.search(value) for pattern in SECRET_PATTERNS)


def next_evidence_id(rows: list[dict[str, str]]) -> str:
    """The next free id in the ``E0001``, ``E0002``, ... sequence.

    The smallest unused id, so auto-assignment never reuses an id and never
    leaves a gap in the sequence.
    """
    used = {(row.get("evidence_id") or "").strip() for row in rows}
    number = 1
    while f"E{number:04d}" in used:
        number += 1
    return f"E{number:04d}"


def load_metadata(run_dir: Path) -> dict:
    """The run metadata, or a usage error when the run was never initialised."""
    metadata_path = run_dir / "metadata.json"
    if not metadata_path.exists():
        raise UsageError(f"missing metadata.json in {run_dir}; run init first")
    metadata = read_json(metadata_path, {})
    if not isinstance(metadata, dict):
        raise UsageError(f"metadata.json in {run_dir} is not a JSON object")
    return metadata


def resolve_run_dir(run_dir: str) -> Path:
    """The absolute path of a run directory."""
    path = Path(run_dir).expanduser()
    try:
        return path.resolve()
    except OSError as exc:
        raise UsageError(f"cannot resolve run directory {run_dir}: {exc}") from exc


def resolve_new_run_dir(out_dir: str, name: str | None, question: str) -> Path:
    """The absolute path of a new run directory, inside ``--out-dir``.

    The containment rule is checked before anything is created or removed, so a
    name that points outside the output directory cannot delete or overwrite a
    directory the caller did not name.
    """
    base = Path(out_dir).expanduser()
    try:
        base = base.resolve()
    except OSError as exc:
        raise UsageError(f"cannot resolve --out-dir {out_dir}: {exc}") from exc
    if name is not None:
        if not name.strip() or name in {".", ".."}:
            raise UsageError(f"--name must be a plain directory name, got {name!r} (containment rule)")
        parts = Path(name).parts
        if len(parts) != 1 or ".." in parts or "/" in name or "\\" in name:
            raise UsageError(
                f"--name must not contain a path separator or '..', got {name!r} (containment rule)"
            )
        candidate = base / name
    else:
        stamp = datetime.now(timezone.utc).strftime("%Y%m%d-%H%M%S")
        candidate = base / f"{stamp}-{slugify(question)}"
    try:
        run_dir = candidate.resolve()
    except OSError as exc:
        raise UsageError(f"cannot resolve run directory {candidate}: {exc}") from exc
    if run_dir == base or base not in run_dir.parents:
        raise UsageError(
            f"run directory must stay inside --out-dir {base} (containment rule); refused {run_dir}"
        )
    return run_dir


def update_graph(run_dir: Path, node: dict, edges: list[dict]) -> None:
    """Add a node and its edges to the run's source graph."""
    graph_path = run_dir / "source_graph.json"
    graph = read_json(graph_path, {"nodes": [], "edges": []})
    if not isinstance(graph, dict):
        graph = {"nodes": [], "edges": []}
    nodes = graph.setdefault("nodes", [])
    known = {item.get("id") for item in nodes if isinstance(item, dict)}
    if node.get("id") not in known:
        nodes.append(node)
    graph.setdefault("edges", []).extend(edges)
    write_json(graph_path, graph)


# --------------------------------------------------------------------------
# init
# --------------------------------------------------------------------------


PLAN_TEMPLATE = """# Research plan

## Question
{question}

## Deliverable
{deliverable}

## Budget
- Effort: {effort}
- Hop target: about {hop_target} meaningful retrieval or inspection steps. A planning
  target, not a quota.
- Hard maximum: {hard_max}
- Source diversity target: at least {source_diversity_target} source classes where available.
- Independent support target: at least {min_independent_sources} independent source
  families for high-impact claims, or an explicit uncertainty label.
- Checkpoint {checkpoint}.

## Aspect map

Fill one row per aspect, then delete the rows that do not apply.

| aspect | why it could change the answer | source route | status |
|---|---|---|---|
| scope and definitions | wrong entity, false premise, moving target | official docs, standards | todo |
| official anchors | version, scope, authoritative wording | official domains, filings, standards bodies | todo |
| academic evidence | what has been tested, and by whom | arXiv, venue pages, proceedings | todo |
| implementation reality | what the code actually does | repository, tests, releases, issues | todo |
| empirical evidence | measured result and its setup | benchmarks, datasets, replications | todo |
| counterevidence and risks | what would falsify the answer | issues, advisories, critiques, errata | todo |
| local-file evidence | the user's own material | exact path, page, line, table, cell | todo |
| final verification | dates, versions, independence, gaps | the ledger | todo |

## Candidate source classes
- primary documents: official docs, standards, filings, papers, datasets
- implementation: source files, tests, examples, releases, changelogs, issues
- measurement: benchmarks, evaluations, replications
- secondary: news, analysis, community discussion, used as context only
- local: user-provided files, cited with exact locators

## Open subquestions
1. What must be true for the answer to be usable?
2. Which claims are stale, contested, or version-dependent?
3. Which primary source can anchor each high-impact claim?
4. What evidence would most likely disprove the current conclusion?
"""

OPEN_QUESTIONS_TEMPLATE = """# Open questions

- [ ] What must be true for the final answer to be reliable?
- [ ] Which high-impact claims still need an independent second source?
- [ ] Which sources may be stale, biased, incomplete, or primary for one side only?
- [ ] Which source would most likely disprove the current conclusion?
- [ ] Which aspects of the aspect map are still untouched?
"""


def initialize(args: argparse.Namespace) -> int:
    """Create a run directory with its metadata, plan, and empty ledgers."""
    run_dir = resolve_new_run_dir(args.out_dir, args.name, args.question)
    base = Path(args.out_dir).expanduser().resolve()

    if run_dir.exists():
        if not run_dir.is_dir():
            raise UsageError(f"run path exists and is not a directory: {run_dir}")
        if any(run_dir.iterdir()):
            if not args.force:
                raise UsageError(
                    f"run directory already exists and is not empty: {run_dir}; use --force to reset it"
                )
            shutil.rmtree(run_dir)
    ensure_dir(run_dir)

    defaults = effort_defaults(args.effort)
    hop_target = positive_int(
        args.hop_target if args.hop_target is not None else defaults["hop_target"], "hop_target"
    )
    source_diversity_target = positive_int(
        args.source_diversity_target
        if args.source_diversity_target is not None
        else defaults["source_diversity_target"],
        "source_diversity_target",
    )
    min_sources = positive_int(
        args.min_independent_sources
        if args.min_independent_sources is not None
        else defaults["min_independent_sources"],
        "min_independent_sources",
    )
    hard_max_hops = positive_int(args.hard_max_hops, "hard_max_hops")
    if hard_max_hops is not None and hard_max_hops < (hop_target or 0):
        raise UsageError(
            f"hard_max_hops ({hard_max_hops}) must be greater than or equal to hop_target ({hop_target})"
        )

    metadata = {
        "question": args.question,
        "created_utc": now_utc(),
        "effort": args.effort,
        "hop_target": hop_target,
        "hard_max_hops": hard_max_hops,
        "source_diversity_target": source_diversity_target,
        "min_independent_sources": min_sources,
        "freshness_requirement": args.freshness or "infer from the request; browse when facts may have changed",
        "deliverable": args.deliverable or "evidence-backed research report",
        "stop_rule": (
            "stop when the high-impact claims are supported and the remaining gaps are explicit; "
            "extend past the target only when new evidence can change the answer"
        ),
        "status": "initialized",
    }
    write_json(run_dir / "metadata.json", metadata)

    write_csv(run_dir / "hop_ledger.csv", HOP_FIELDS, [])
    write_csv(run_dir / "evidence_ledger.csv", EVIDENCE_FIELDS, [])
    write_json(run_dir / "source_graph.json", {"nodes": [], "edges": []})

    plan = PLAN_TEMPLATE.format(
        question=args.question,
        deliverable=metadata["deliverable"],
        effort=args.effort,
        hop_target=hop_target,
        hard_max=hard_max_hops if hard_max_hops is not None else "none",
        source_diversity_target=source_diversity_target,
        min_independent_sources=min_sources,
        checkpoint=checkpoint_text(hop_target or 0),
    )
    (run_dir / "plan.md").write_text(plan, encoding="utf-8")
    (run_dir / "open_questions.md").write_text(OPEN_QUESTIONS_TEMPLATE, encoding="utf-8")
    (run_dir / "final_report.md").write_text("", encoding="utf-8")

    print(str(run_dir))
    return 0


# --------------------------------------------------------------------------
# add-hop
# --------------------------------------------------------------------------


def add_hop(args: argparse.Namespace) -> int:
    """Append one retrieval or inspection hop."""
    run_dir = resolve_run_dir(args.run_dir)
    metadata = load_metadata(run_dir)
    hop = positive_int(args.hop, "hop")

    hard_max = metadata.get("hard_max_hops")
    if hard_max is not None and hop > int(hard_max):
        raise UsageError(f"hop {hop} exceeds hard_max_hops={hard_max}")

    hop_rows = read_csv(run_dir / "hop_ledger.csv")
    existing_hops = parse_hop_set(hop_rows)
    if hop in existing_hops:
        raise UsageError(f"hop already exists: {hop}")

    parent_hop = positive_int(args.parent_hop, "parent_hop")
    if parent_hop is not None:
        if parent_hop == hop:
            raise UsageError("parent_hop cannot be the same as hop")
        if parent_hop not in existing_hops:
            raise UsageError(f"parent_hop does not exist: {parent_hop}")

    row = {
        "hop": str(hop),
        "timestamp_utc": now_utc(),
        "parent_hop": str(parent_hop) if parent_hop is not None else "",
        "mode": args.mode,
        "tool_or_source": args.tool_or_source,
        "query_or_action": args.query_or_action,
        "target_url_or_path": args.target or "",
        "result_summary": args.result_summary or "",
        "new_entities": args.new_entities or "",
        "evidence_ids": args.evidence_ids or "",
        "next_questions": args.next_questions or "",
        "status": args.status,
    }
    append_csv(run_dir / "hop_ledger.csv", HOP_FIELDS, row)

    edges: list[dict] = []
    if parent_hop is not None:
        edges.append({"from": f"H{parent_hop:03d}", "to": f"H{hop:03d}", "type": "leads_to"})
    update_graph(
        run_dir,
        {
            "id": f"H{hop:03d}",
            "type": "hop",
            "label": args.query_or_action[:120],
            "mode": args.mode,
            "status": args.status,
        },
        edges,
    )

    hop_target = int(metadata.get("hop_target") or 0)
    count = len(hop_rows) + 1
    if hop_target and count > hop_target:
        print(
            f"warning: hop count {count} exceeds the target {hop_target}; "
            "the target is a planning guide, so keep going only while new evidence can change the answer",
            file=sys.stderr,
        )

    print(f"recorded hop H{hop:03d}")
    return 0


# --------------------------------------------------------------------------
# add-evidence
# --------------------------------------------------------------------------


def add_evidence(args: argparse.Namespace) -> int:
    """Append one evidence item."""
    run_dir = resolve_run_dir(args.run_dir)
    load_metadata(run_dir)
    hop = positive_int(args.hop, "hop")

    hop_rows = read_csv(run_dir / "hop_ledger.csv")
    if hop not in parse_hop_set(hop_rows):
        raise UsageError(f"evidence references missing hop: {hop}; record the hop before adding evidence")

    rows = read_csv(run_dir / "evidence_ledger.csv")
    evidence_id = (args.evidence_id or "").strip() or next_evidence_id(rows)
    if any((row.get("evidence_id") or "").strip() == evidence_id for row in rows):
        raise UsageError(f"evidence_id already exists: {evidence_id}")

    quality = str(args.quality_score)
    if quality not in {"1", "2", "3", "4", "5"}:
        raise UsageError("quality_score must be an integer 1-5")

    candidate = {
        "title": args.title,
        "url_or_path": args.url_or_path,
        "publisher_or_owner": args.publisher_or_owner or "",
        "source_family": args.source_family or "",
        "source_subtype": args.source_subtype or "",
        "date_or_version": args.date_or_version or "",
        "source_id": args.source_id,
        "claim_id": args.claim_id or "",
        "claim": args.claim,
        "quote_or_locator": args.quote_or_locator or "",
        "notes": args.notes or "",
    }
    for field, value in candidate.items():
        if looks_like_secret(value):
            raise ContentFinding(
                f"{field} looks like a secret or credential; replace the value with {REDACTION} "
                "before logging evidence (nothing was written)"
            )

    row = {
        "evidence_id": evidence_id,
        "timestamp_utc": now_utc(),
        "hop": str(hop),
        "source_id": args.source_id,
        "claim_id": args.claim_id or "",
        "claim_importance": args.claim_importance,
        "title": args.title,
        "url_or_path": args.url_or_path,
        "publisher_or_owner": args.publisher_or_owner or "",
        "source_family": (args.source_family or "").strip(),
        "date_or_version": args.date_or_version or "",
        "accessed_utc": args.accessed_utc or now_utc(),
        "source_type": args.source_type,
        "source_subtype": args.source_subtype or "",
        "quality_score": quality,
        "stance": args.stance,
        "independence_status": args.independence_status,
        "freshness_status": args.freshness_status,
        "uncertainty_label": args.uncertainty_label or "none",
        "claim": args.claim,
        "quote_or_locator": args.quote_or_locator or "",
        "notes": args.notes or "",
    }
    append_csv(run_dir / "evidence_ledger.csv", EVIDENCE_FIELDS, row)

    update_graph(
        run_dir,
        {
            "id": args.source_id,
            "type": "source",
            "label": args.title[:120],
            "url_or_path": args.url_or_path,
            "source_type": args.source_type,
            "source_subtype": args.source_subtype or "",
            "source_family": row["source_family"],
            "quality_score": quality,
        },
        [
            {"from": f"H{hop:03d}", "to": evidence_id, "type": "found"},
            {"from": evidence_id, "to": args.source_id, "type": "supported_by"},
        ],
    )
    update_graph(
        run_dir,
        {
            "id": evidence_id,
            "type": "evidence",
            "label": args.claim[:120],
            "claim_id": args.claim_id or "",
            "claim_importance": args.claim_importance,
            "stance": args.stance,
        },
        [],
    )
    print(f"recorded evidence {evidence_id}")
    return 0


# --------------------------------------------------------------------------
# lint
# --------------------------------------------------------------------------


def lint(args: argparse.Namespace) -> int:
    """Check the run ledger and the report for structural and quality problems."""
    run_dir = resolve_run_dir(args.run_dir)
    metadata = load_metadata(run_dir)

    hard_max = metadata.get("hard_max_hops")
    hop_target = int(metadata.get("hop_target") or 0)
    source_diversity_target = int(metadata.get("source_diversity_target") or 0)
    min_sources = int(metadata.get("min_independent_sources") or 2)
    effort = metadata.get("effort", "standard")

    hop_rows = read_csv(run_dir / "hop_ledger.csv")
    evidence_rows = read_csv(run_dir / "evidence_ledger.csv")

    errors: list[str] = []
    warnings: list[str] = []

    seen_hops: set[int] = set()
    duplicate_hops: set[int] = set()
    all_hops = parse_hop_set(hop_rows)
    for row in hop_rows:
        raw_hop = row.get("hop", "")
        try:
            hop_num = int(raw_hop or "")
        except (TypeError, ValueError):
            errors.append(f"invalid hop number: {raw_hop}")
            continue
        if hop_num < 1:
            errors.append(f"hop must be >= 1: {hop_num}")
            continue
        if hard_max is not None and hop_num > int(hard_max):
            errors.append(f"hop {hop_num} exceeds hard_max_hops={hard_max}")
        if hop_num in seen_hops:
            duplicate_hops.add(hop_num)
        seen_hops.add(hop_num)

        parent_raw = (row.get("parent_hop") or "").strip()
        if parent_raw:
            try:
                parent = int(parent_raw)
            except ValueError:
                errors.append(f"hop {hop_num} has invalid parent_hop={parent_raw}")
            else:
                if parent < 1:
                    errors.append(f"hop {hop_num} has invalid parent_hop={parent}")
                elif parent == hop_num:
                    errors.append(f"hop {hop_num} cannot be its own parent")
                elif parent not in all_hops:
                    errors.append(f"hop {hop_num} references missing parent_hop={parent}")
        for field in ("tool_or_source", "query_or_action", "result_summary", "status"):
            if not (row.get(field) or "").strip():
                warnings.append(f"hop {hop_num} missing {field}")

    for hop_num in sorted(duplicate_hops):
        errors.append(f"duplicate hop number: {hop_num}")

    evidence_ids: set[str] = set()
    support_families: set[str] = set()
    source_types: set[str] = set()
    primary_count = 0
    counter_count = 0
    quality_counts = {str(i): 0 for i in range(1, 6)}
    claim_groups: dict[str, list[dict[str, str]]] = {}
    high_claim_rows: list[dict[str, str]] = []

    for row in evidence_rows:
        evidence_id = (row.get("evidence_id") or "").strip()
        label = evidence_id or "evidence row"
        if not evidence_id:
            errors.append("evidence row missing evidence_id")
        elif evidence_id in evidence_ids:
            errors.append(f"duplicate evidence_id: {evidence_id}")
        evidence_ids.add(evidence_id)

        raw_hop = row.get("hop", "")
        try:
            evidence_hop = int(raw_hop or "")
        except (TypeError, ValueError):
            errors.append(f"{label} has invalid hop={raw_hop}")
            evidence_hop = None
        if evidence_hop is not None:
            if evidence_hop < 1:
                errors.append(f"{label} references invalid hop={evidence_hop}")
            elif evidence_hop not in seen_hops:
                errors.append(f"{label} references missing hop={evidence_hop}")

        for field in (
            "hop",
            "source_id",
            "title",
            "url_or_path",
            "source_type",
            "quality_score",
            "stance",
            "claim",
        ):
            if not (row.get(field) or "").strip():
                errors.append(f"{label} missing {field}")

        quality = row.get("quality_score", "")
        if quality not in quality_counts:
            errors.append(f"{label} has invalid quality_score={quality}")
        else:
            quality_counts[quality] += 1

        source_type = (row.get("source_type") or "").strip()
        if source_type:
            source_types.add(source_type)
        if source_type in PRIMARY_TYPES:
            primary_count += 1
        if row.get("stance") in COUNTER_STANCES:
            counter_count += 1

        family = source_family_of(row)
        if row.get("stance") == "supports" and quality_int(row) >= 3:
            if family:
                support_families.add(family)
            else:
                warnings.append(
                    f"{label} is a supporting row with quality>=3 but missing source_family; "
                    "record the independent family explicitly"
                )

        claim_id = (row.get("claim_id") or "").strip()
        if claim_id:
            claim_groups.setdefault(claim_id, []).append(row)

        importance = (row.get("claim_importance") or "medium").strip()
        if importance not in CLAIM_IMPORTANCE:
            warnings.append(f"{label} has unknown claim_importance={importance}")
        if importance in HIGH_IMPORTANCE:
            high_claim_rows.append(row)
            if not claim_id:
                warnings.append(f"{label} is high-impact but missing claim_id")
            if not (row.get("quote_or_locator") or "").strip():
                warnings.append(f"{label} is high-impact but missing quote_or_locator")
            if not family:
                warnings.append(f"{label} is high-impact but missing source_family")
            if not (row.get("date_or_version") or "").strip() and row.get("freshness_status") not in {
                "not-applicable",
                "stale",
            }:
                warnings.append(f"{label} is high-impact but missing date_or_version")
            if row.get("freshness_status") in {"", "unknown", "undated"}:
                warnings.append(f"{label} is high-impact but has unresolved freshness_status")
            if row.get("independence_status") in {"", "unknown"}:
                warnings.append(f"{label} is high-impact but has unknown independence_status")

        if row.get("freshness_status") == "current" and not (row.get("date_or_version") or "").strip():
            warnings.append(f"{label} is marked current but missing date_or_version")
        if not (row.get("quote_or_locator") or "").strip():
            warnings.append(f"{label} missing quote_or_locator")

        combined = "\n".join(row.get(field, "") for field in EVIDENCE_FIELDS)
        if looks_like_secret(combined):
            warnings.append(f"{label} may contain a secret/token; redact it as {REDACTION} before sharing")

    for claim_id, rows in sorted(claim_groups.items()):
        if not any((row.get("claim_importance") or "medium") in HIGH_IMPORTANCE for row in rows):
            continue
        support_fams = {
            source_family_of(row)
            for row in rows
            if row.get("stance") == "supports" and quality_int(row) >= 3 and source_family_of(row)
        }
        if len(support_fams) < min_sources:
            warnings.append(
                f"claim {claim_id} has only {len(support_fams)} independent support source families "
                f"with quality>=3; target is {min_sources}"
            )
        if not any(row.get("stance") in COUNTER_STANCES for row in rows):
            warnings.append(
                f"claim {claim_id} has no contradictory or unclear evidence row; "
                "verify it or label the row not-applicable"
            )
        if not any(row.get("freshness_status") not in {"", "unknown", "undated"} for row in rows):
            warnings.append(f"claim {claim_id} has unresolved freshness across all evidence rows")

    if evidence_rows and len(support_families) < min_sources:
        warnings.append(
            f"only {len(support_families)} independent support source families with quality>=3; "
            f"target is {min_sources}"
        )
    if evidence_rows and len(source_types) < source_diversity_target:
        warnings.append(
            f"only {len(source_types)} source classes recorded; effort target is {source_diversity_target}"
        )
    if evidence_rows and primary_count == 0:
        warnings.append("no primary or near-primary evidence recorded")
    if evidence_rows and counter_count == 0 and effort in {"standard", "deep", "exhaustive"}:
        warnings.append(
            "no contradictory/unclear evidence recorded; run an adversarial search if the topic is debatable"
        )
    if high_claim_rows and not any(row.get("claim_id") for row in high_claim_rows):
        warnings.append("high-impact evidence exists but no high-impact row has a claim_id")
    if hop_target and len(hop_rows) > hop_target:
        warnings.append(
            f"hop count {len(hop_rows)} exceeds target {hop_target}; this is fine only if later hops "
            "filled material gaps"
        )

    report_path = run_dir / "final_report.md"
    if report_path.exists():
        text = report_path.read_text(encoding="utf-8")
        cited = set(re.findall(r"\[(E\d+)\]", text))
        unknown = cited - evidence_ids
        if unknown:
            errors.append("final_report.md cites unknown evidence ids: " + ", ".join(sorted(unknown)))
        if evidence_rows and not cited:
            warnings.append("final_report.md does not cite evidence ids like [E0001]")

    status = {
        "run_dir": str(run_dir),
        "question": metadata.get("question", ""),
        "effort": effort,
        "hop_count": len(hop_rows),
        "hop_target": hop_target,
        "evidence_count": len(evidence_rows),
        "source_types": sorted(source_types),
        "support_source_families_quality_ge_3": sorted(f for f in support_families if f),
        "high_impact_evidence_count": len(high_claim_rows),
        "quality_counts": quality_counts,
        "errors": errors,
        "warnings": warnings,
    }
    print(json.dumps(status, ensure_ascii=False, indent=2))
    return 1 if errors else 0


# --------------------------------------------------------------------------
# status
# --------------------------------------------------------------------------


def status(args: argparse.Namespace) -> int:
    """Print a concise view of the run and the next useful step."""
    run_dir = resolve_run_dir(args.run_dir)
    metadata = load_metadata(run_dir)
    hop_rows = read_csv(run_dir / "hop_ledger.csv")
    evidence_rows = read_csv(run_dir / "evidence_ledger.csv")

    hop_target = int(metadata.get("hop_target") or 0)
    target_remaining = max(0, hop_target - len(hop_rows)) if hop_target else None
    domains = sorted({domain_of(row.get("url_or_path", "")) for row in evidence_rows if row.get("url_or_path")})
    source_families = sorted({f for f in (source_family_of(row) for row in evidence_rows) if f})
    source_types = sorted({row.get("source_type", "") for row in evidence_rows if row.get("source_type")})
    claim_ids = sorted({row.get("claim_id", "") for row in evidence_rows if row.get("claim_id")})
    latest_hop = hop_rows[-1] if hop_rows else None

    suggested = "select the next frontier, or verify a high-impact claim"
    if hop_target and len(hop_rows) >= max(2, round(hop_target / 3)) and len(hop_rows) < round(2 * hop_target / 3):
        suggested = "checkpoint: summarise, prune, and add a counterevidence search"
    if hop_target and len(hop_rows) >= hop_target:
        suggested = "finalise, or justify why more searching can still change the answer"

    payload = {
        "question": metadata.get("question"),
        "effort": metadata.get("effort"),
        "hop_count": len(hop_rows),
        "hop_target_remaining": target_remaining,
        "evidence_count": len(evidence_rows),
        "claim_ids": claim_ids,
        "source_domains": domains,
        "source_families": source_families,
        "source_types": source_types,
        "latest_hop_summary": latest_hop.get("result_summary") if latest_hop else None,
        "suggested_next_step": suggested,
    }
    print(json.dumps(payload, ensure_ascii=False, indent=2))
    return 0


# --------------------------------------------------------------------------
# render
# --------------------------------------------------------------------------


def _cell(value: str) -> str:
    """A markdown table cell."""
    text = (value or "").replace("|", "\\|").replace("\r", " ").replace("\n", " ").strip()
    return text if text else "—"


def _split_sections(text: str) -> dict[str, str]:
    """The body of every ``##`` section in a markdown file."""
    sections: dict[str, str] = {}
    heading = ""
    buffer: list[str] = []
    for line in text.splitlines():
        if line.startswith("## "):
            if heading:
                sections[heading] = "\n".join(buffer).strip("\n").strip()
            heading = line[3:].strip()
            buffer = []
        elif heading:
            buffer.append(line)
    if heading:
        sections[heading] = "\n".join(buffer).strip("\n").strip()
    return sections


def _claim_confidence(rows: list[dict[str, str]], min_sources: int) -> str:
    """A confidence label for one claim group."""
    support = [row for row in rows if row.get("stance") == "supports" and quality_int(row) >= 3]
    families = {source_family_of(row) for row in support if source_family_of(row)}
    contested = any(row.get("stance") in COUNTER_STANCES for row in rows)
    if not support:
        return "low"
    if contested:
        return "medium" if len(families) >= min_sources else "low"
    return "high" if len(families) >= min_sources else "medium"


def _claim_freshness(rows: list[dict[str, str]]) -> str:
    """The weakest freshness status among a claim's rows."""
    statuses = [
        (row.get("freshness_status") or "").strip()
        for row in rows
        if (row.get("freshness_status") or "").strip()
    ]
    if not statuses:
        return "unknown"
    return min(statuses, key=lambda status: FRESHNESS_RANK.get(status, 2))


def _claim_independence(rows: list[dict[str, str]], min_sources: int) -> str:
    """How independent the supporting evidence for a claim is."""
    families = {
        source_family_of(row)
        for row in rows
        if row.get("stance") == "supports" and quality_int(row) >= 3 and source_family_of(row)
    }
    if not families:
        return "unknown"
    if len(families) >= max(2, min_sources):
        return "independent"
    return "single-family"


def _claim_uncertainty(rows: list[dict[str, str]]) -> str:
    """The uncertainty labels carried by a claim's rows."""
    labels = {
        (row.get("uncertainty_label") or "").strip()
        for row in rows
        if (row.get("uncertainty_label") or "").strip() and row.get("uncertainty_label") != "none"
    }
    return ", ".join(sorted(labels)) if labels else "none"


def _claim_text(rows: list[dict[str, str]]) -> str:
    """The claim text for a claim group: the most important row's wording."""
    best = rows[0]
    for row in rows:
        if (row.get("claim_importance") or "medium") in HIGH_IMPORTANCE:
            best = row
            break
    return (best.get("claim") or "").strip()


def _render_claim_matrix(evidence_rows: list[dict[str, str]], min_sources: int) -> str:
    """The generated claim verification matrix."""
    groups: dict[str, list[dict[str, str]]] = {}
    for row in evidence_rows:
        claim_id = (row.get("claim_id") or "").strip()
        if claim_id:
            groups.setdefault(claim_id, []).append(row)

    lines = [
        "| claim ID | claim | evidence IDs | source independence | counterevidence | freshness | confidence | uncertainty |",
        "|---|---|---|---|---|---|---|---|",
    ]
    if not groups:
        lines.append("| — | no claim groups recorded | — | — | — | — | — | — |")
        return "\n".join(lines)

    for claim_id in sorted(groups):
        rows = groups[claim_id]
        ids = ", ".join((row.get("evidence_id") or "").strip() for row in rows)
        counter = "yes" if any(row.get("stance") in COUNTER_STANCES for row in rows) else "no"
        lines.append(
            "| "
            + " | ".join(
                [
                    _cell(claim_id),
                    _cell(_claim_text(rows)),
                    _cell(ids),
                    _cell(_claim_independence(rows, min_sources)),
                    _cell(counter),
                    _cell(_claim_freshness(rows)),
                    _cell(_claim_confidence(rows, min_sources)),
                    _cell(_claim_uncertainty(rows)),
                ]
            )
            + " |"
        )
    return "\n".join(lines)


def _render_evidence_table(evidence_rows: list[dict[str, str]]) -> str:
    """The generated evidence table."""
    lines = [
        "| id | source | url | type | quality | stance | date/version | locator | claim |",
        "|---|---|---|---|---|---|---|---|---|",
    ]
    if not evidence_rows:
        lines.append("| — | no evidence recorded | — | — | — | — | — | — | — |")
        return "\n".join(lines)
    for row in evidence_rows:
        lines.append(
            "| "
            + " | ".join(
                [
                    _cell(row.get("evidence_id", "")),
                    _cell(row.get("title", "")),
                    _cell(row.get("url_or_path", "")),
                    _cell(row.get("source_type", "")),
                    _cell(row.get("quality_score", "")),
                    _cell(row.get("stance", "")),
                    _cell(row.get("date_or_version", "")),
                    _cell(row.get("quote_or_locator", "")),
                    _cell(row.get("claim", "")),
                ]
            )
            + " |"
        )
    return "\n".join(lines)


def _render_method_appendix(
    metadata: dict,
    hop_rows: list[dict[str, str]],
    evidence_rows: list[dict[str, str]],
    run_dir: Path,
) -> str:
    """The generated method appendix."""
    hop_target = int(metadata.get("hop_target") or 0)
    diversity_target = int(metadata.get("source_diversity_target") or 0)
    min_sources = int(metadata.get("min_independent_sources") or 2)
    source_types = sorted({(row.get("source_type") or "").strip() for row in evidence_rows if row.get("source_type")})
    families = sorted(
        {
            source_family_of(row)
            for row in evidence_rows
            if row.get("stance") == "supports" and quality_int(row) >= 3 and source_family_of(row)
        }
    )
    counters = [row for row in evidence_rows if row.get("stance") in COUNTER_STANCES]
    counter_ids = ", ".join((row.get("evidence_id") or "").strip() for row in counters)
    lines = [
        f"- Question: {metadata.get('question', '')}",
        f"- Deliverable: {metadata.get('deliverable', '')}",
        f"- Effort level: {metadata.get('effort', '')} (hop target {hop_target})",
        f"- Hop count: {len(hop_rows)} (target {hop_target})",
        f"- Evidence rows: {len(evidence_rows)}",
        f"- Source classes searched: {', '.join(source_types) if source_types else 'none recorded'} "
        f"(target {diversity_target})",
        f"- Independent support families (quality>=3): {len(families)} "
        f"{', '.join(families) if families else ''} (target {min_sources})",
        f"- Counterevidence searched: {'yes' if counters else 'no'}"
        + (f" — {counter_ids}" if counter_ids else ""),
        f"- Freshness requirement: {metadata.get('freshness_requirement', '')}",
        f"- Run directory: {run_dir}",
        f"- Created (UTC): {metadata.get('created_utc', '')}",
        "- The ledger records what was checked; it cannot prove a source was read.",
    ]
    return "\n".join(lines)


def render(args: argparse.Namespace) -> int:
    """Write the report skeleton and the generated tables from the ledger."""
    run_dir = resolve_run_dir(args.run_dir)
    metadata = load_metadata(run_dir)
    hop_rows = read_csv(run_dir / "hop_ledger.csv")
    evidence_rows = read_csv(run_dir / "evidence_ledger.csv")
    min_sources = int(metadata.get("min_independent_sources") or 2)

    report_path = Path(args.out).expanduser() if args.out else run_dir / "final_report.md"
    previous = report_path.read_text(encoding="utf-8") if report_path.exists() else ""
    existing = _split_sections(previous)

    title = f"Research report: {metadata.get('question', '')}"
    first_line = previous.splitlines()[0] if previous.splitlines() else ""
    if first_line.startswith("# ") and first_line.strip() != f"# {title}":
        title = first_line[2:].strip()

    generated = {
        "Claim verification matrix": _render_claim_matrix(evidence_rows, min_sources),
        "Evidence table": _render_evidence_table(evidence_rows),
        "Method appendix": _render_method_appendix(metadata, hop_rows, evidence_rows, run_dir),
    }

    parts = [f"# {title}", ""]
    for heading in REPORT_SECTIONS:
        if heading in generated:
            body = generated[heading]
        else:
            previous_body = (existing.get(heading) or "").strip()
            body = previous_body if previous_body and previous_body != PLACEHOLDER else PLACEHOLDER
        parts.append(f"## {heading}")
        parts.append("")
        parts.append(body)
        parts.append("")

    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text("\n".join(parts).rstrip("\n") + "\n", encoding="utf-8")
    print(str(report_path))
    return 0


# --------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------


def build_parser() -> argparse.ArgumentParser:
    """The command line."""
    parser = argparse.ArgumentParser(description="Manage an adaptive deep research hop/evidence ledger")
    sub = parser.add_subparsers(dest="command", required=True)

    init_p = sub.add_parser("init", help="create a research run directory")
    init_p.add_argument("--question", required=True)
    init_p.add_argument("--out-dir", default="research_runs")
    init_p.add_argument("--name")
    init_p.add_argument("--force", action="store_true", help="reset an existing non-empty run directory")
    init_p.add_argument("--effort", choices=list(EFFORT_TIERS), default="standard")
    init_p.add_argument("--hop-target", type=int)
    init_p.add_argument("--hard-max-hops", type=int)
    init_p.add_argument("--source-diversity-target", type=int)
    init_p.add_argument("--min-independent-sources", type=int)
    init_p.add_argument("--freshness")
    init_p.add_argument("--deliverable")
    init_p.set_defaults(func=initialize)

    hop_p = sub.add_parser("add-hop", help="append one retrieval/inspection hop")
    hop_p.add_argument("--run-dir", required=True)
    hop_p.add_argument("--hop", required=True, type=int)
    hop_p.add_argument("--parent-hop", type=int)
    hop_p.add_argument(
        "--mode",
        choices=["seed", "expand", "verify", "contradict", "synthesize", "checkpoint"],
        default="expand",
    )
    hop_p.add_argument("--tool-or-source", required=True)
    hop_p.add_argument("--query-or-action", required=True)
    hop_p.add_argument("--target")
    hop_p.add_argument("--result-summary")
    hop_p.add_argument("--new-entities")
    hop_p.add_argument("--evidence-ids")
    hop_p.add_argument("--next-questions")
    hop_p.add_argument("--status", choices=["done", "dead-end", "needs-followup", "blocked"], default="done")
    hop_p.set_defaults(func=add_hop)

    ev_p = sub.add_parser("add-evidence", help="append one evidence item")
    ev_p.add_argument("--run-dir", required=True)
    ev_p.add_argument("--evidence-id")
    ev_p.add_argument("--hop", required=True, type=int)
    ev_p.add_argument("--source-id", required=True)
    ev_p.add_argument("--claim-id")
    ev_p.add_argument("--claim-importance", choices=CLAIM_IMPORTANCE, default="medium")
    ev_p.add_argument("--title", required=True)
    ev_p.add_argument("--url-or-path", required=True)
    ev_p.add_argument("--publisher-or-owner")
    ev_p.add_argument("--source-family")
    ev_p.add_argument("--date-or-version")
    ev_p.add_argument("--accessed-utc")
    ev_p.add_argument("--source-type", choices=SOURCE_TYPES, required=True)
    ev_p.add_argument("--source-subtype")
    ev_p.add_argument("--quality-score", type=int, required=True)
    ev_p.add_argument("--stance", choices=["supports", "contradicts", "context", "unclear"], required=True)
    ev_p.add_argument("--independence-status", choices=INDEPENDENCE_STATUS, default="unknown")
    ev_p.add_argument("--freshness-status", choices=FRESHNESS_STATUS, default="unknown")
    ev_p.add_argument("--uncertainty-label", choices=UNCERTAINTY_LABELS)
    ev_p.add_argument("--claim", required=True)
    ev_p.add_argument("--quote-or-locator")
    ev_p.add_argument("--notes")
    ev_p.set_defaults(func=add_evidence)

    render_p = sub.add_parser("render", help="write the report from the ledger")
    render_p.add_argument("--run-dir", required=True)
    render_p.add_argument("--out", help="output path; defaults to <run-dir>/final_report.md")
    render_p.set_defaults(func=render)

    lint_p = sub.add_parser("lint", help="validate the run ledger")
    lint_p.add_argument("--run-dir", required=True)
    lint_p.set_defaults(func=lint)

    status_p = sub.add_parser("status", help="print concise run status")
    status_p.add_argument("--run-dir", required=True)
    status_p.set_defaults(func=status)

    return parser


def main(argv: list[str] | None = None) -> int:
    """Run one command and map its outcome onto the exit status."""
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        return int(args.func(args))
    except ContentFinding as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1
    except UsageError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    except BrokenPipeError:  # pragma: no cover - depends on the consumer
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
