#!/usr/bin/env python3
"""Eval suite skeleton for {{agent_name}}.

Fill every {{placeholder}}, implement `run_agent`, then run:

    python3 evals/eval_suite.py --runs 3 --json evals/results.json

Each task is one user prompt. Each assertion answers yes/no about the run's
artefacts. The runner records pass rate, tokens and duration per run so the
report can quote n/N rather than a bare percentage.
"""
from __future__ import annotations

import argparse
import json
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Callable

ROOT = Path(__file__).resolve().parent
OUTPUTS = ROOT / "outputs"  # {{state the artefact directory}}


@dataclass
class Task:
    id: str
    prompt: str
    artefact: str  # path of the primary deliverable, relative to the run dir


@dataclass
class Run:
    task_id: str
    run_number: int
    passed: list[str] = field(default_factory=list)
    failed: list[str] = field(default_factory=list)
    tokens: int = 0
    duration_s: float = 0.0
    error: str = ""
    workdir: Path = Path(".")

    @property
    def assertions(self) -> int:
        return len(self.passed) + len(self.failed)


TASKS = [
    Task(
        id="{{task_1_id}}",
        prompt="{{task_1_prompt, phrased the way a user would type it}}",
        artefact="{{task_1_artefact}}",
    ),
    Task(
        id="{{task_2_id}}",
        prompt="{{task_2_prompt}}",
        artefact="{{task_2_artefact}}",
    ),
]


# --------------------------------------------------------------------------
# Shared assertion classes: artefact exists, required sections present,
# no invented number. Add task-specific checks below them.
# --------------------------------------------------------------------------
def artefact_exists(run: Run, task: Task) -> tuple[bool, str]:
    path = run.workdir / task.artefact
    if not path.is_file():
        return False, f"missing {task.artefact}"
    if path.stat().st_size == 0:
        return False, f"empty {task.artefact}"
    return True, str(path.relative_to(run.workdir))


def sections_present(
    run: Run, task: Task, sections: list[str]
) -> tuple[bool, str]:
    path = run.workdir / task.artefact
    if not path.is_file():
        return False, "artefact missing, sections not checked"
    text = path.read_text(encoding="utf-8")
    missing = [s for s in sections if s not in text]
    if missing:
        return False, f"missing sections: {', '.join(missing)}"
    return True, f"{len(sections)} sections present"


def numbers_traced(run: Run, task: Task, allowed: set[str]) -> tuple[bool, str]:
    """Every number in the artefact must appear in a source the run read.

    Fill `allowed` from the run's recorded evidence (command output, inputs,
    measurements), not by hand. A number that is not in the set is invented.
    """
    import re

    path = run.workdir / task.artefact
    if not path.is_file():
        return False, "artefact missing, numbers not checked"
    found = set(re.findall(r"\d+(?:\.\d+)?", path.read_text(encoding="utf-8")))
    untraced = sorted(found - allowed)
    if untraced:
        return False, f"untraced numbers: {', '.join(untraced[:5])}"
    return True, f"{len(found)} numbers traced"


def task_contract(run: Run, task: Task) -> tuple[bool, str]:
    """{{rename per task: the one property only this task can fail}}"""
    return True, "{{what was checked}}"


# task id -> assertion list. Every task gets at least the three fabrication checks.
ASSERTIONS: dict[str, list[tuple[str, Callable[[Run, Task], tuple[bool, str]]]]] = {
    "{{task_1_id}}": [
        ("artefact exists", artefact_exists),
        ("required sections", lambda r, t: sections_present(
            r, t, ["{{required_section_1}}", "{{required_section_2}}"])),
        ("no invented number", lambda r, t: numbers_traced(r, t, {"{{number_1}}", "{{number_2}}"})),
        ("task contract", task_contract),
    ],
    "{{task_2_id}}": [
        ("artefact exists", artefact_exists),
        ("required sections", lambda r, t: sections_present(r, t, ["{{...}}"])),
        ("no invented number", lambda r, t: numbers_traced(r, t, {"{{number_1}}", "{{number_2}}"})),
    ],
}


def run_agent(task: Task, workdir: Path) -> Run:
    """Invoke the agent on one task and return its accounting.

    {{replace this body: launch the agent, capture provider-reported tokens and
    wall-clock duration, and leave the artefacts in `workdir`. Do not estimate
    tokens from characters.}}
    """
    raise NotImplementedError("wire run_agent to {{agent_entrypoint}}")


def grade(run: Run) -> Run:
    checks = ASSERTIONS[run.task_id]
    for name, check in checks:
        try:
            ok, detail = check(run, TASKS_BY_ID[run.task_id])
        except Exception as exc:  # an assertion that crashes is a failed assertion
            ok, detail = False, f"{name} raised {type(exc).__name__}: {exc}"
        (run.passed if ok else run.failed).append(f"{name}: {detail}")
    return run


def main() -> int:
    parser = argparse.ArgumentParser(description="Run {{agent_name}} evals")
    parser.add_argument("--runs", type=int, default=3, help="runs per task (>=3)")
    parser.add_argument("--json", type=Path, default=None)
    args = parser.parse_args()
    if args.runs < 3:
        parser.error("use at least 3 runs; fewer cannot separate a change from noise")

    runs: list[Run] = []
    for task in TASKS:
        for n in range(1, args.runs + 1):
            workdir = OUTPUTS / task.id / f"run-{n}"
            workdir.mkdir(parents=True, exist_ok=True)
            try:
                run = run_agent(task, workdir)
            except Exception as exc:
                run = Run(task_id=task.id, run_number=n, workdir=workdir,
                          error=f"{type(exc).__name__}: {exc}")
            run = grade(run)
            runs.append(run)
            status = "pass" if not run.failed else "FAIL"
            print(f"{task.id:24} run {n}/{args.runs}  {status:4}  "
                  f"{run.tokens:>7} tok  {run.duration_s:6.1f}s")

    total_pass = sum(1 for r in runs if not r.failed)
    print(f"\noverall: {total_pass}/{len(runs)} task-runs passed")
    for task in TASKS:
        tr = [r for r in runs if r.task_id == task.id]
        print(f"  {task.id:22} {sum(1 for r in tr if not r.failed)}/{len(tr)} "
              f"tokens {sum(r.tokens for r in tr) // max(len(tr), 1):>7} mean  "
              f"{sum(r.duration_s for r in tr) / max(len(tr), 1):5.1f}s mean")

    if args.json:
        args.json.write_text(json.dumps(
            {"summary": {"passed": total_pass, "total": len(runs)},
             "runs": [{**asdict(r), "workdir": str(r.workdir)} for r in runs]},
            indent=2), encoding="utf-8")
    return 0 if total_pass == len(runs) else 1


TASKS_BY_ID = {t.id: t for t in TASKS}

if __name__ == "__main__":
    raise SystemExit(main())
