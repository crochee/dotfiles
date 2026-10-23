#!/usr/bin/env python3
"""Validate the python-dev skill: frontmatter, links, budgets, snippets, runs, templates.

Usage:
    python3 scripts/check.py [--build] [--verbose] [ROOT]

ROOT is the skill directory; it defaults to the parent of this script's directory.

Modes, all run unless stated:
    frontmatter  name/description/version/compatibility, and the 1024-character budget
    links        every relative link resolves, every fragment exists, no orphan reference
    budget       SKILL.md word count, per-reference line caps, seven reference targets
    snippets     every ```python fence parses as a module and binds every name it loads
    runs         every ```python run fence executes and exits 0 without output
    templates    TOML parses and asserts the floors; YAML parses if PyYAML is present;
                 the Dockerfile asserts base image, non-root user and no `latest`

--build generates a project from assets/pyproject.toml.template in a temporary directory,
runs `uv lock` and `uv build`, and asserts the wheel ships py.typed. When uv is missing or
the resolver is offline, it prints `SKIPPED build` with the reason and exits 0.

Exit codes:
    0  every mode passed, or was skipped with an explicit line
    1  at least one finding
    2  usage or input error: ROOT missing, SKILL.md unreadable, references/ absent
"""

from __future__ import annotations

import argparse
import ast
import builtins
import json
import re
import shutil
import subprocess
import sys
import tempfile
import tomllib
import zipfile
from pathlib import Path
from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    from collections.abc import Callable, Iterator

SKILL_WORDS = 950
SKILL_REFERENCE_LINKS = 7
FRONTMATTER_CHARS = 1024
DESCRIPTION_CHARS = 500
SNIPPET_TIMEOUT_S = 20
BUILD_TIMEOUT_S = 600

BUDGETS = {
    "patterns.md": 360,
    "architecture-and-errors.md": 290,
    "async-and-concurrency.md": 240,
    "testing.md": 300,
    "tooling.md": 220,
    "data-and-resilience.md": 240,
    "delivery.md": 300,
}

NAME = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
VERSION = re.compile(r"^\d+\.\d+\.\d+$")
FENCE = re.compile(r"^```([^\n]*)\n(.*?)^```[ \t]*$", re.MULTILINE | re.DOTALL)
LINK = re.compile(r"\[[^\]]*\]\(([^)\s]+)\)")
HEADING = re.compile(r"^#{1,6} +(.+?)\s*$", re.MULTILINE)
PLACEHOLDER = re.compile(r"REPLACE-ME-(?:PKG|DESC|OWNER)")
OFFLINE = (
    "temporary failure",
    "network",
    "offline",
    "failed to fetch",
    "dns error",
    "connect",
)

BUILTIN_NAMES = set(dir(builtins)) | {
    "__name__",
    "__file__",
    "__doc__",
    "__all__",
    "__builtins__",
    "__spec__",
    "__package__",
}
FUNCTION_NODES = (ast.FunctionDef, ast.AsyncFunctionDef)


class Report:
    """Collects findings per mode and decides the exit status."""

    def __init__(self, verbose: bool) -> None:
        self.verbose = verbose
        self.findings: list[str] = []

    def fail(self, where: str, message: str) -> None:
        self.findings.append(f"{where}: {message}")

    def note(self, message: str) -> None:
        if self.verbose:
            print(f"  {message}")

    @property
    def count(self) -> int:
        return len(self.findings)


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


# --- frontmatter ------------------------------------------------------------


def split_frontmatter(text: str) -> tuple[str | None, str]:
    """The YAML frontmatter block and the body, without a YAML parser."""
    if not text.startswith("---\n"):
        return None, text
    end = text.find("\n---\n", 3)
    if end == -1:
        return None, text
    return text[4:end], text[end + 5 :]


def parse_frontmatter(block: str) -> dict[str, str]:
    """Top-level keys, plus one nested level flattened as `parent.child`."""
    found: dict[str, str] = {}
    parent: str | None = None
    for raw in block.splitlines():
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        indented = raw.startswith((" ", "\t"))
        key, _, value = raw.partition(":")
        key, value = key.strip(), value.strip()
        if indented and parent:
            found[f"{parent}.{key}"] = unquote(value)
        elif not indented:
            parent = key if not value else None
            found[key] = unquote(value)
    return found


def unquote(value: str) -> str:
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        return value[1:-1]
    return value


def check_frontmatter(root: Path, report: Report) -> bool:
    skill = root / "SKILL.md"
    text = read(skill)
    block, _ = split_frontmatter(text)
    if block is None:
        report.fail(
            "frontmatter", "SKILL.md does not open with a `---` frontmatter block"
        )
        return False
    if len(block) > FRONTMATTER_CHARS:
        report.fail(
            "frontmatter", f"{len(block)} characters exceeds {FRONTMATTER_CHARS}"
        )
    fields = parse_frontmatter(block)
    name = fields.get("name", "")
    if not NAME.match(name):
        report.fail("frontmatter", f"name {name!r} is not lowercase-hyphenated")
    description = fields.get("description", "")
    if "Use when" not in description:
        report.fail(
            "frontmatter",
            "description names no situation: expected a 'Use when ...' clause",
        )
    if len(description) > DESCRIPTION_CHARS:
        report.fail(
            "frontmatter",
            f"description is {len(description)} characters, limit {DESCRIPTION_CHARS}",
        )
    version = fields.get("metadata.version", "")
    if not VERSION.match(version):
        report.fail(
            "frontmatter", f"metadata.version {version!r} is not MAJOR.MINOR.PATCH"
        )
    if not fields.get("compatibility"):
        report.fail("frontmatter", "compatibility is missing")
    report.note(f"name={name} version={version} description={len(description)} chars")
    return True


# --- links ------------------------------------------------------------------


def slug(heading: str) -> str:
    text = heading.strip().lower()
    text = re.sub(r"`|\*|_|\[|\]|\(|\)|\.|,|:|;|!|\?|\"'", "", text)
    return re.sub(r"\s+", "-", text).strip("-")


def anchors(path: Path) -> set[str]:
    return {slug(m) for m in HEADING.findall(read(path))}


def markdown_files(root: Path) -> list[Path]:
    return [root / "SKILL.md", *sorted((root / "references").glob("*.md"))]


def prose(text: str) -> str:
    """Markdown with fenced blocks and inline code spans removed."""
    without_fences = FENCE.sub("", text)
    return re.sub(r"`[^`\n]*`", "", without_fences)


def check_links(root: Path, report: Report) -> None:
    for source in markdown_files(root):
        for target in LINK.findall(prose(read(source))):
            if target.startswith(("http://", "https://", "mailto:")):
                continue
            path_part, _, fragment = target.partition("#")
            resolved = (source.parent / path_part).resolve() if path_part else source
            if not resolved.exists():
                report.fail("links", f"{source.name}: {target!r} does not resolve")
                continue
            if (
                fragment
                and resolved.suffix == ".md"
                and slug(fragment) not in anchors(resolved)
            ):
                report.fail(
                    "links", f"{source.name}: {target!r} has no matching heading"
                )
    check_reference_index(root, report)


def check_reference_index(root: Path, report: Report) -> None:
    references = sorted((root / "references").glob("*.md"))
    names = {p.name for p in references}
    if not names:
        report.fail("links", "references/ contains no markdown file")
        return
    missing_cap = names - set(BUDGETS)
    if missing_cap:
        report.fail("links", f"no line budget for {sorted(missing_cap)}")
    section = (
        read(root / "SKILL.md").partition("## References")[2].partition("\n## ")[0]
    )
    rows = [
        line
        for line in section.splitlines()
        if line.startswith("|") and "references/" in line
    ]
    listed = {
        m
        for line in rows
        for m in re.findall(r"references/([A-Za-z0-9._-]+\.md)", line)
    }
    for orphan in sorted(names - listed):
        report.fail(
            "links", f"references/{orphan} is not in the SKILL.md References table"
        )
    if len(rows) != len(names):
        report.fail(
            "links", f"References table has {len(rows)} rows for {len(names)} files"
        )
    report.note(f"{len(rows)} reference rows, {len(names)} files")


# --- budget -----------------------------------------------------------------


def check_budget(root: Path, report: Report) -> None:
    skill = root / "SKILL.md"
    words = len(read(skill).split())
    if words > SKILL_WORDS:
        report.fail("budget", f"SKILL.md is {words} words, limit {SKILL_WORDS}")
    report.note(f"SKILL.md {words} words")
    targets = set(re.findall(r"references/([A-Za-z0-9._-]+\.md)", read(skill)))
    if len(targets) != SKILL_REFERENCE_LINKS:
        report.fail(
            "budget",
            f"SKILL.md links {len(targets)} distinct references, expected {SKILL_REFERENCE_LINKS}",
        )
    for name, cap in sorted(BUDGETS.items()):
        path = root / "references" / name
        if not path.exists():
            report.fail("budget", f"references/{name} is missing")
            continue
        lines = len(read(path).splitlines())
        if lines > cap:
            report.fail("budget", f"references/{name} is {lines} lines, limit {cap}")
        report.note(f"references/{name} {lines}/{cap} lines")


# --- snippets ---------------------------------------------------------------


def bound_names(node: ast.AST) -> set[str]:
    """Every name a node introduces into its own scope."""
    out: set[str] = set()
    for sub in ast.walk(node):
        if isinstance(sub, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
            out.add(sub.name)
        elif isinstance(sub, (ast.Import, ast.ImportFrom)):
            out.update(
                (alias.asname or alias.name).split(".")[0] for alias in sub.names
            )
        elif isinstance(sub, ast.Name) and isinstance(sub.ctx, (ast.Store, ast.Del)):
            out.add(sub.id)
        elif isinstance(sub, ast.arg):
            out.add(sub.arg)
        elif isinstance(sub, ast.ExceptHandler) and sub.name:
            out.add(sub.name)
        elif isinstance(sub, (ast.Global, ast.Nonlocal)):
            out.update(sub.names)
        elif isinstance(sub, (ast.MatchAs, ast.MatchStar)) and sub.name:
            out.add(sub.name)
        elif isinstance(sub, ast.MatchMapping) and sub.rest:
            out.add(sub.rest)
        elif isinstance(sub, ast.TypeAlias):
            out.add(sub.name.id)
        for param in getattr(sub, "type_params", None) or []:
            out.add(param.name)
    return out


def module_level(tree: ast.Module) -> Iterator[str]:
    """Nodes that cannot appear at module level: await, return, yield."""

    def walk(node: ast.AST, inside: bool) -> Iterator[str]:
        for child in ast.iter_child_nodes(node):
            if (
                isinstance(child, (ast.Await, ast.Return, ast.Yield, ast.YieldFrom))
                and not inside
            ):
                yield f"{type(child).__name__} at module level (line {child.lineno})"
            if isinstance(child, FUNCTION_NODES):
                yield from walk(child, True)
            else:
                yield from walk(child, inside)

    yield from walk(tree, False)


def undefined_names(tree: ast.Module) -> list[str]:
    """Loads with no binding in any enclosing scope and no builtin."""
    problems: list[str] = []

    def visit(node: ast.AST, scope: set[str]) -> None:
        scope = scope | bound_names(node)
        problems.extend(
            f"undefined name {sub.id!r} (line {sub.lineno})"
            for sub in ast.walk(node)
            if isinstance(sub, ast.Name)
            and isinstance(sub.ctx, ast.Load)
            and sub.id not in scope
            and sub.id not in BUILTIN_NAMES
        )
        for child in ast.iter_child_nodes(node):
            visit(child, scope)

    visit(tree, set())
    return sorted(
        set(problems), key=lambda item: int(re.search(r"line (\d+)", item).group(1))
    )


def fences(text: str) -> Iterator[tuple[str, str]]:
    for match in FENCE.finditer(text):
        yield match.group(1).strip(), match.group(2)


def python_fences(root: Path) -> Iterator[tuple[str, str, str]]:
    for source in markdown_files(root):
        for info, body in fences(read(source)):
            if info.split(" ")[0] == "python":
                yield source.name, info, body


def check_snippets(root: Path, report: Report) -> None:
    count = 0
    for name, info, body in python_fences(root):
        count += 1
        try:
            tree = ast.parse(body)
        except SyntaxError as error:
            report.fail(
                "snippets",
                f"{name} [{info}]: SyntaxError {error.msg} (line {error.lineno})",
            )
            continue
        for problem in module_level(tree):
            report.fail("snippets", f"{name} [{info}]: {problem}")
        for problem in undefined_names(tree):
            report.fail("snippets", f"{name} [{info}]: {problem}")
    report.note(f"{count} python fences parsed")


# --- runs -------------------------------------------------------------------


def check_runs(root: Path, report: Report) -> None:
    executed = 0
    for name, info, body in python_fences(root):
        if info != "python run":
            continue
        executed += 1
        environment = {
            "PATH": "/usr/bin:/bin:/usr/local/bin",
            "LANG": "C.UTF-8",
            "LC_ALL": "C.UTF-8",
            "HOME": tempfile.gettempdir(),
        }
        with tempfile.TemporaryDirectory() as workdir:
            completed = subprocess.run(  # noqa: S603 - fixed argv, no shell, sandboxed cwd
                [sys.executable, "-c", body],
                capture_output=True,
                text=True,
                timeout=SNIPPET_TIMEOUT_S,
                cwd=workdir,
                env=environment,
                check=False,
            )
        if completed.returncode != 0:
            tail = (completed.stderr or completed.stdout).strip().splitlines()[-3:]
            report.fail(
                "runs", f"{name}: exit {completed.returncode}: {' | '.join(tail)}"
            )
            continue
        unsolicited = completed.stdout.strip()
        if unsolicited:
            report.fail(
                "runs", f"{name}: stdout is not empty: {unsolicited.splitlines()[0]!r}"
            )
        report.note(f"{name}: ran clean")
    if executed == 0:
        report.fail("runs", "no ```python run fence found")
    report.note(f"{executed} runnable fences")


# --- templates --------------------------------------------------------------


def filled(text: str) -> str:
    values = {"PKG": "pkg", "DESC": "demo", "OWNER": "demo"}
    return PLACEHOLDER.sub(
        lambda match: values[match.group(0).removeprefix("REPLACE-ME-")], text
    )


def check_pyproject_template(root: Path, report: Report) -> None:
    path = root / "assets" / "pyproject.toml.template"
    if not path.exists():
        report.fail("templates", "assets/pyproject.toml.template is missing")
        return
    try:
        data = tomllib.loads(filled(read(path)))
    except tomllib.TOMLDecodeError as error:
        report.fail("templates", f"pyproject.toml.template: {error}")
        return
    check_manifest_floors(data, report)


def check_manifest_floors(data: dict, report: Report) -> None:
    """The manifest must carry the documented floors and the three gate configurations."""
    if data.get("project", {}).get("requires-python") != ">=3.15":
        report.fail("templates", "pyproject requires-python is not '>=3.15'")
    select = data.get("tool", {}).get("ruff", {}).get("lint", {}).get("select", [])
    if not select:
        report.fail("templates", "[tool.ruff.lint] select is empty")
    if data.get("tool", {}).get("pyright", {}).get("typeCheckingMode") != "strict":
        report.fail("templates", "[tool.pyright] typeCheckingMode is not strict")
    dev = " ".join(data.get("dependency-groups", {}).get("dev", []))
    for package in ("pytest", "ruff", "pyright"):
        if package not in dev:
            report.fail("templates", f"dev group does not include {package}")
    if "scripts" not in data.get("project", {}):
        report.fail("templates", "[project.scripts] is missing")
    report.note(f"pyproject template parsed, {len(select)} rule families")


def optional_yaml() -> Any:
    """PyYAML when it is installed; the checker degrades to a structural test."""
    try:
        import yaml  # noqa: PLC0415 - optional dependency, announced when absent
    except ImportError:
        return None
    return yaml


def yaml_documents(root: Path, report: Report) -> None:
    yaml = optional_yaml()
    for path in sorted((root / "assets").glob("*.y*ml*")):
        text = read(path)
        if "\t" in text:
            report.fail("templates", f"{path.name}: indented with a tab")
        if yaml is None:
            if "jobs:" in text and "runs-on:" not in text:
                report.fail("templates", f"{path.name}: jobs without runs-on")
            print(f"SKIPPED yaml-parse {path.name}")
            continue
        try:
            document = yaml.safe_load(text)
        except yaml.YAMLError as error:
            report.fail("templates", f"{path.name}: {error}")
            continue
        check_yaml_document(path.name, document or {}, report)
        report.note(f"{path.name} parsed")


def check_yaml_document(name: str, document: dict, report: Report) -> None:
    if name.startswith("ci.yml"):
        check_ci_jobs(name, document, report)
    elif name.startswith("pre-commit"):
        check_pre_commit_revs(name, document, report)


def check_ci_jobs(name: str, document: dict, report: Report) -> None:
    jobs = document.get("jobs", {})
    if not jobs:
        report.fail("templates", f"{name}: no jobs")
        return
    for job, spec in jobs.items():
        if "runs-on" not in (spec or {}):
            report.fail("templates", f"{name}: job {job} has no runs-on")


def check_pre_commit_revs(name: str, document: dict, report: Report) -> None:
    for repo in document.get("repos", []):
        if not VERSION.match(str(repo.get("rev", "")).lstrip("v")):
            report.fail(
                "templates", f"{name}: rev {repo.get('rev')!r} is not a release tag"
            )


def check_dockerfile_template(root: Path, report: Report) -> None:
    path = root / "assets" / "Dockerfile.template"
    if not path.exists():
        report.fail("templates", "assets/Dockerfile.template is missing")
        return
    text = read(path)
    for needle in ("FROM python:3.15", "USER ", "PYTHONUNBUFFERED=1", "uv sync"):
        if needle not in text:
            report.fail("templates", f"Dockerfile.template lacks {needle!r}")
    if ":latest" in text:
        report.fail("templates", "Dockerfile.template pins a :latest tag")


def check_templates(root: Path, report: Report) -> None:
    check_pyproject_template(root, report)
    for name in (
        "ci.yml.template",
        "pre-commit-config.yaml.template",
        "gitignore.template",
    ):
        if not (root / "assets" / name).exists():
            report.fail("templates", f"assets/{name} is missing")
    yaml_documents(root, report)
    check_dockerfile_template(root, report)


# --- build ------------------------------------------------------------------


def check_build(root: Path, report: Report) -> None:
    uv = shutil.which("uv")
    if uv is None:
        print("SKIPPED build: uv is not on PATH")
        return
    with tempfile.TemporaryDirectory() as workdir:
        project = Path(workdir)
        write_project(root, project, report)
        if report.count:
            return
        for command in (["lock"], ["build"]):
            completed = subprocess.run(  # noqa: S603 - fixed argv, no shell
                [uv, *command],
                capture_output=True,
                text=True,
                cwd=project,
                timeout=BUILD_TIMEOUT_S,
                check=False,
            )
            if completed.returncode != 0:
                output = (completed.stderr or completed.stdout).lower()
                if any(word in output for word in OFFLINE):
                    print(f"SKIPPED build: `uv {command[0]}` could not reach the index")
                    return
                report.fail(
                    "build",
                    f"`uv {command[0]}` failed: {completed.stderr.strip()[-400:]}",
                )
                return
        wheels = sorted(project.glob("dist/*.whl"))
        if not wheels:
            report.fail("build", "uv build produced no wheel")
            return
        names = zipfile.ZipFile(wheels[0]).namelist()
        if not any(name.endswith("py.typed") for name in names):
            report.fail("build", f"{wheels[0].name} does not ship py.typed")
            return
        print(f"OK build {wheels[0].name}")
        report.note(f"wheel members: {json.dumps(names)[:200]}")


def write_project(root: Path, project: Path, report: Report) -> None:
    template = root / "assets" / "pyproject.toml.template"
    if not template.exists():
        report.fail("build", "assets/pyproject.toml.template is missing")
        return
    (project / "src" / "pkg").mkdir(parents=True)
    (project / "pyproject.toml").write_text(filled(read(template)), encoding="utf-8")
    (project / "src" / "pkg" / "__init__.py").write_text(
        '"""Generated by check.py --build."""\n\n__all__: list[str] = []\n',
        encoding="utf-8",
    )
    (project / "src" / "pkg" / "py.typed").write_text("", encoding="utf-8")
    (project / "README.md").write_text("# demo\n", encoding="utf-8")
    (project / "LICENSE").write_text("MIT\n", encoding="utf-8")


# --- entry point ------------------------------------------------------------


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Validate the python-dev skill.")
    parser.add_argument(
        "root", nargs="?", help="skill directory; defaults to this script's parent"
    )
    parser.add_argument(
        "--build", action="store_true", help="build a project from the template with uv"
    )
    parser.add_argument(
        "--verbose", "-v", action="store_true", help="print per-check detail"
    )
    arguments = parser.parse_args(argv)

    root = (
        Path(arguments.root).resolve()
        if arguments.root
        else Path(__file__).resolve().parent.parent
    )
    if not (root / "SKILL.md").is_file():
        print(f"error: {root}/SKILL.md is not readable", file=sys.stderr)
        return 2
    if not (root / "references").is_dir():
        print(f"error: {root}/references does not exist", file=sys.stderr)
        return 2

    report = Report(arguments.verbose)
    modes: list[tuple[str, Callable[[], None]]] = [
        ("frontmatter", lambda: check_frontmatter(root, report)),
        ("links", lambda: check_links(root, report)),
        ("budget", lambda: check_budget(root, report)),
        ("snippets", lambda: check_snippets(root, report)),
        ("runs", lambda: check_runs(root, report)),
        ("templates", lambda: check_templates(root, report)),
    ]
    for name, run in modes:
        before = report.count
        run()
        failures = report.count - before
        print(
            f"{'FAIL' if failures else 'OK'} {name}"
            + (f" ({failures})" if failures else "")
        )

    if arguments.build:
        before = report.count
        check_build(root, report)
        failures = report.count - before
        if failures:
            print(f"FAIL build ({failures})")

    for finding in report.findings:
        print(f"  {finding}")
    if report.count:
        print(f"\n{report.count} finding(s)", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
