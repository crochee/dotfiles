#!/usr/bin/env python3
"""Prove each gate rule with a deliberately broken copy of the worked contract.

    python3 tests/run.py

Each case mutates a deep copy of `examples/identity-openapi.yaml` in one way and
asserts that `scripts/validate.py` exits 1 and names the rule. A rule that stops
firing fails the run, so the gate cannot silently rot when the prose changes.

Requires PyYAML, the same dependency the gate has.
"""

from __future__ import annotations

import copy
import subprocess
import sys
import tempfile
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
CONTRACT = ROOT / "examples" / "identity-openapi.yaml"
GATE = ROOT / "scripts" / "validate.py"
BASE = yaml.safe_load(CONTRACT.read_text(encoding="utf-8"))

CASES: list[tuple[str, str, dict]] = []


def case(expect: str):
    """Register a mutation and the finding its contract must produce."""
    def register(mutate):
        doc = copy.deepcopy(BASE)
        mutate(doc)
        CASES.append((mutate.__name__, expect, doc))
        return mutate
    return register


@case("does not match x-conventions.page_size_max")
def limit_schema_disagrees(doc):
    doc["components"]["parameters"]["Limit"]["schema"]["maximum"] = 100


@case("below the recommended 500")
def page_size_max_below_recommended(doc):
    doc["x-conventions"]["page_size_max"] = 100
    doc["components"]["parameters"]["Limit"]["schema"]["maximum"] = 100


@case("must be an integer")
def page_size_not_integer(doc):
    doc["x-conventions"]["page_size_default"] = "50"


@case("default is above its maximum")
def limit_default_above_maximum(doc):
    doc["components"]["parameters"]["Limit"]["schema"]["maximum"] = 10


@case("error flag 'success'")
def error_flag_in_success_body(doc):
    doc["components"]["examples"]["UserExample"]["value"]["success"] = False


@case("declares no preflight")
def cors_without_preflight(doc):
    doc["x-conventions"]["cors"] = "enabled"


@case("is recorded but no query parameter filters")
def filter_axis_without_filter(doc):
    del doc["components"]["parameters"]["UserStatus"]
    for param in doc["paths"]["/v1/users"]["get"]["parameters"]:
        if param.get("$ref") == "#/components/parameters/UserStatus":
            doc["paths"]["/v1/users"]["get"]["parameters"].remove(param)


@case("is an error response but error_format is 'not_used'")
def error_format_not_used(doc):
    doc["x-conventions"]["error_format"] = "not_used"


@case("external $ref")
def external_reference(doc):
    doc["components"]["schemas"]["User"]["properties"]["avatar"] = {"$ref": "other.yaml#/Avatar"}


@case("cursor collection has total without include_total")
def total_without_include_total(doc):
    params = doc["paths"]["/v1/users"]["get"]["parameters"]
    doc["paths"]["/v1/users"]["get"]["parameters"] = [
        p for p in params if p.get("$ref") != "#/components/parameters/IncludeTotal"]


@case("cursor collection has no next_cursor")
def cursor_collection_without_next_cursor(doc):
    del doc["components"]["schemas"]["UserCollection"]["properties"]["next_cursor"]


@case("429 is missing Retry-After")
def required_header_missing(doc):
    del doc["components"]["responses"]["TooManyRequests"]["headers"]["Retry-After"]


@case("invalid token 'sometimes'")
def unknown_axis_token(doc):
    doc["x-conventions"]["cors"] = "sometimes"


@case("unknown axis 'colour'")
def unknown_note_axis(doc):
    doc["x-conventions"]["notes"].append({"axis": "colour", "reason": "It is not an axis."})


def run_gate(doc: dict) -> subprocess.CompletedProcess[str]:
    with tempfile.NamedTemporaryFile("w", suffix=".yaml", delete=False) as handle:
        yaml.safe_dump(doc, handle, sort_keys=False)
        path = handle.name
    try:
        return subprocess.run(
            [sys.executable, str(GATE), "--contract", path],
            capture_output=True, text=True, check=False,
        )
    finally:
        Path(path).unlink(missing_ok=True)


def main() -> int:
    failures: list[str] = []

    valid = run_gate(copy.deepcopy(BASE))
    if valid.returncode != 0:
        failures.append(f"the worked contract must pass, but the gate said:\n{valid.stderr}")

    for name, expect, doc in CASES:
        result = run_gate(doc)
        if result.returncode != 1:
            failures.append(f"{name}: expected exit 1, got {result.returncode}: {result.stderr}")
        elif expect not in result.stderr:
            failures.append(f"{name}: expected a finding containing {expect!r}, got: {result.stderr}")

    if failures:
        for failure in failures:
            print(f"FAIL: {failure}", file=sys.stderr)
        return 1
    print(f"OK: {len(CASES)} rules fire, and the worked contract passes")
    return 0


if __name__ == "__main__":
    sys.exit(main())
