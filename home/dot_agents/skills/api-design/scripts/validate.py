#!/usr/bin/env python3
"""Check one OpenAPI 3.1 contract against the api-design skill's absolutes.

    python3 scripts/validate.py --contract FILE

The vocabulary it enforces is read from the reference markdown beside this script:
`references/conventions.md` carries the axes and the page-size integers,
`references/http-semantics.md` carries the required headers. Edit the prose and the
gate follows; there is no second copy to drift.

Exit status: 0 the contract conforms, 1 findings, 2 usage error or unreadable input.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:  # reported in main()
    yaml = None

REFERENCES = Path(__file__).resolve().parent.parent / "references"

# A fenced block whose info string names a marker, e.g. ```yaml conventions-vocabulary
FENCE = re.compile(r"^```yaml[ \t]+(\S+)[ \t]*\n(.*?)^```[ \t]*$", re.M | re.S)

# Members that report an outcome rather than carry a result; illegal at the top of a 2xx body.
ERROR_FLAGS = ("error", "errors", "success")

REGISTERED = set("""
accept accept-ch accept-encoding accept-language accept-patch accept-ranges age
allow authorization cache-control content-disposition content-encoding
content-language content-length content-range content-type cookie deprecation
dpop dpop-nonce etag expires forwarded from idempotency-key if-match
if-modified-since if-none-match if-range if-unmodified-since link location
max-forwards origin prefer preference-applied priority proxy-authenticate
proxy-authorization range ratelimit ratelimit-policy referer retry-after
sec-fetch-dest sec-fetch-mode sec-fetch-site sec-fetch-user server-timing
set-cookie signature signature-input sunset te traceparent tracestate trailer
transfer-encoding upgrade user-agent vary via warning www-authenticate
""".split())
IANA_STATUS = {str(n) for n in (
    100, 101, 102, 103, 200, 201, 202, 203, 204, 205, 206, 207, 208, 226,
    300, 301, 302, 303, 304, 305, 307, 308, 400, 401, 402, 403, 404, 405,
    406, 407, 408, 409, 410, 411, 412, 413, 414, 415, 416, 417, 418, 421,
    422, 423, 424, 425, 426, 428, 429, 431, 451, 500, 501, 502, 503, 504,
    505, 506, 507, 508, 510, 511,
)}
INTERNAL = re.compile(
    r"Traceback \(most recent"
    r"|\bFile \"[^\"]+\", line \d+"
    r"|\bat [\w$.<>]+ \([\w./-]+:\d+\)"
    r"|\b(?:SELECT|INSERT|UPDATE|DELETE)\b[^\n]{0,80}\b(?:FROM|INTO|SET)\b"
    r"|(?:^|\s)(?:~|/)[\w.-]+(?:/[\w.-]+)*\.(?:py|go|java|ts|js|rb|rs|php|cs)\b"
)


if yaml is None:
    StrictLoader = None
else:
    class StrictLoader(yaml.SafeLoader):
        """Refuse a duplicate mapping key: two values for one key cannot be represented."""

        def construct_mapping(self, node, deep=False):
            self.flatten_mapping(node)
            seen = set()
            for key_node, _ in node.value:
                key = self.construct_object(key_node, deep=deep)
                try:
                    duplicate = key in seen
                except TypeError:
                    continue
                if duplicate:
                    raise yaml.constructor.ConstructorError(
                        "while constructing a mapping", node.start_mark,
                        f"found duplicate key {key!r}", key_node.start_mark,
                    )
                seen.add(key)
            return super().construct_mapping(node, deep=deep)


class Report:
    def __init__(self) -> None:
        self.failures: list[str] = []

    def fail(self, where: str, message: str) -> None:
        self.failures.append(f"{where}: {message}")


def load_blocks(path: Path) -> dict[str, object]:
    """The `yaml <marker>` fenced blocks in one reference file, by marker."""
    blocks: dict[str, object] = {}
    for marker, body in FENCE.findall(path.read_text(encoding="utf-8")):
        blocks[marker] = yaml.safe_load(body)
    return blocks


def load_vocabulary(references: Path) -> tuple[dict, dict, dict]:
    """Read the axes, the page-size integers and the required headers from the prose."""
    conventions = load_blocks(references / "conventions.md").get("conventions-vocabulary")
    headers = load_blocks(references / "http-semantics.md").get("required-headers-vocabulary")
    if not isinstance(conventions, dict):
        raise ValueError(f"{references / 'conventions.md'} has no conventions-vocabulary block")
    axes, integers = conventions.get("axes"), conventions.get("integers")
    if not isinstance(axes, dict) or not axes:
        raise ValueError("conventions-vocabulary.axes is missing or empty")
    if not isinstance(integers, dict) or not integers:
        raise ValueError("conventions-vocabulary.integers is missing or empty")
    if not isinstance(headers, dict) or not headers:
        raise ValueError(
            f"{references / 'http-semantics.md'} has no required-headers-vocabulary block")
    return axes, integers, {str(k): tuple(v or ()) for k, v in headers.items()}


def resolve_pointer(doc: dict, ref: object) -> tuple[bool, object]:
    """Resolve a local JSON pointer; external references are not followed."""
    if not isinstance(ref, str) or not ref.startswith("#"):
        return False, {}
    obj: object = doc
    for part in ref[1:].split("/"):
        if not part:
            continue
        part = part.replace("~1", "/").replace("~0", "~")
        if isinstance(obj, dict) and part in obj:
            obj = obj[part]
        elif isinstance(obj, list) and part.isdigit() and int(part) < len(obj):
            obj = obj[int(part)]
        else:
            return False, {}
    return True, obj


def resolve(doc: dict, obj: object) -> dict:
    """Follow a chain of local `$ref` pointers anywhere in the document."""
    for _ in range(16):
        if not isinstance(obj, dict) or not isinstance(obj.get("$ref"), str):
            break
        found, target = resolve_pointer(doc, obj["$ref"])
        if not found:
            return {}
        obj = target
    return obj if isinstance(obj, dict) else {}


def operations(doc: dict):
    paths = doc.get("paths")
    if not isinstance(paths, dict):
        return
    for path, item in paths.items():
        if not isinstance(item, dict):
            continue
        shared = item.get("parameters") or []
        for method in ("get", "put", "post", "delete", "patch", "options", "head", "trace"):
            op = item.get(method)
            if isinstance(op, dict):
                params = [resolve(doc, p) for p in [*shared, *(op.get("parameters") or [])]]
                yield path, method, op, params


def payloads(doc: dict, response: dict) -> list[object]:
    out: list[object] = []
    content = response.get("content")
    if not isinstance(content, dict):
        return out
    for body in content.values():
        if not isinstance(body, dict):
            continue
        if "example" in body:
            out.append(body["example"])
        examples = body.get("examples")
        if isinstance(examples, dict):
            for example in examples.values():
                example = resolve(doc, example)
                if "value" in example:
                    out.append(example["value"])
    return out


def check_axes(doc: dict, axes: dict, integers: dict, report: Report) -> dict:
    conv = doc.get("x-conventions")
    if not isinstance(conv, dict):
        report.fail("x-conventions", "missing")
        return {}
    notes = conv.get("notes") if isinstance(conv.get("notes"), list) else []
    noted: set[str] = set()
    for index, note in enumerate(notes):
        if not isinstance(note, dict):
            report.fail(f"notes[{index}]", "must be an object")
            continue
        if not note.get("reason"):
            report.fail(f"notes[{index}]", "missing reason")
        if "axis" in note:
            axis = note["axis"]
            if isinstance(axis, str):
                noted.add(axis)
                if axis not in axes and axis not in integers:
                    report.fail(f"notes[{index}].axis", f"unknown axis {axis!r}")
            else:
                report.fail(f"notes[{index}].axis", "must be a string")
        elif not note.get("subject"):
            report.fail(f"notes[{index}]", "needs axis or subject")
    for axis, spec in axes.items():
        default = spec.get("default")
        allowed = set(spec.get("tokens") or ())
        value = conv.get(axis)
        if value is None:
            report.fail(f"x-conventions.{axis}", "missing")
        elif not isinstance(value, str):
            report.fail(f"x-conventions.{axis}", "must be a string")
        elif value != "not_used" and value not in allowed:
            report.fail(f"x-conventions.{axis}", f"invalid token {value!r}")
        elif value not in ("not_used", default) and axis not in noted:
            report.fail(f"x-conventions.{axis}", f"departure from {default!r} has no notes entry")
    for key, spec in integers.items():
        recommended = spec.get("recommended")
        floor = spec.get("minimum", 1)
        value = conv.get(key)
        if value is None:
            report.fail(f"x-conventions.{key}", "missing")
        elif not isinstance(value, int) or isinstance(value, bool):
            report.fail(f"x-conventions.{key}", "must be an integer")
        elif value < floor:
            report.fail(f"x-conventions.{key}", f"must be at least {floor}")
        elif (key == "page_size_max" and isinstance(recommended, int)
                and value < recommended and key not in noted):
            report.fail(f"x-conventions.{key}",
                        f"below the recommended {recommended} and needs a notes entry")
    low, high = conv.get("page_size_default"), conv.get("page_size_max")
    if isinstance(low, int) and isinstance(high, int) and low > high:
        report.fail("x-conventions.page_size_default", "is above page_size_max")
    fields = conv.get("header_fields")
    if not isinstance(fields, list):
        report.fail("x-conventions.header_fields", "must be a list")
        return conv
    for index, field in enumerate(fields):
        if not isinstance(field, dict) or not field.get("name") or not field.get("reason"):
            report.fail(f"header_fields[{index}]", "needs name and reason")
        elif str(field["name"]).lower() in REGISTERED:
            report.fail(f"header_fields[{index}]", f"{field['name']} is a registered field")
    return conv


def check_catalogue(doc: dict, report: Report) -> dict[str, str]:
    entries = doc.get("x-error-catalogue")
    if not isinstance(entries, list) or not entries:
        report.fail("x-error-catalogue", "missing or empty")
        return {}
    catalogue: dict[str, str] = {}
    for index, entry in enumerate(entries):
        if not isinstance(entry, dict):
            report.fail(f"catalogue[{index}]", "must be an object")
            continue
        kind = entry.get("type")
        code = kind.rstrip("/").rsplit("/", 1)[-1] if isinstance(kind, str) and kind else ""
        status = str(entry.get("status", ""))
        if not code:
            report.fail(f"catalogue[{index}]", "missing type")
            continue
        if not entry.get("meaning"):
            report.fail(f"catalogue[{index}]", "missing meaning")
        if status not in IANA_STATUS:
            report.fail(f"catalogue[{index}]", f"status {status!r} is not IANA")
        if code in catalogue:
            report.fail(f"catalogue[{index}]", f"duplicate code {code!r}")
        catalogue[code] = status
    return catalogue


def check_collection(doc: dict, where: str, op: dict, params: list[dict], conv: dict,
                     report: Report) -> None:
    page = conv.get("page_size_param", "limit")
    strategy = conv.get("pagination", "cursor")
    limit = next((p for p in params if isinstance(p, dict) and p.get("name") == page), None)
    if limit is None:
        report.fail(where, f"collection has no {page!r} parameter")
        return
    schema = limit.get("schema")
    schema = schema if isinstance(schema, dict) else {}
    if schema.get("type") != "integer":
        report.fail(where, f"{page} must be an integer")
    for key in ("default", "maximum"):
        if key not in schema:
            report.fail(where, f"{page} has no {key}")
    for key, recorded_key in (("default", "page_size_default"),
                              ("maximum", "page_size_max")):
        recorded = conv.get(recorded_key)
        if key in schema and isinstance(recorded, int) and schema.get(key) != recorded:
            report.fail(where, f"{page} {key} {schema.get(key)!r} does not match "
                               f"x-conventions.{recorded_key} ({recorded!r})")
    minimum = schema.get("minimum")
    if isinstance(minimum, int) and minimum < 1:
        report.fail(where, f"{page} minimum must be at least 1")
    low, high = schema.get("default"), schema.get("maximum")
    if isinstance(low, int) and isinstance(high, int) and low > high:
        report.fail(where, f"{page} default is above its maximum")
    if limit.get("required"):
        report.fail(where, f"{page} must be optional")
    names = {p.get("name") for p in params if isinstance(p, dict)}
    if strategy == "cursor" and "cursor" not in names:
        report.fail(where, "cursor strategy has no cursor parameter")
    if strategy == "offset" and "offset" not in names:
        report.fail(where, "offset strategy has no offset parameter")
    responses = op.get("responses")
    if not isinstance(responses, dict):
        return
    success = next((resolve(doc, r) for s, r in responses.items()
                    if str(s).startswith("2")), None)
    if success is None:
        return
    content = success.get("content")
    body = next((b for b in content.values() if isinstance(b, dict)), {}) \
        if isinstance(content, dict) else {}
    props = resolve(doc, body.get("schema")).get("properties")
    props = props if isinstance(props, dict) else {}
    data = resolve(doc, props.get("data"))
    if data.get("type") != "array":
        report.fail(where, "collection success schema has no array under data")
    if page not in props:
        report.fail(where, f"collection success schema has no {page!r}")
    for forbidden in ("has_more", "prev_cursor"):
        if forbidden in props:
            report.fail(where, f"collection schema has {forbidden}")
    if strategy == "cursor" and "next_cursor" not in props:
        report.fail(where, "cursor collection has no next_cursor")
    if strategy == "offset" and not {"offset", "total"} <= set(props):
        report.fail(where, "offset collection has no offset and total")
    include_total = "include_total" in names
    if strategy == "cursor" and "total" in props and not include_total:
        report.fail(where, "cursor collection has total without include_total")
    for example in payloads(doc, success):
        if not isinstance(example, dict) or not isinstance(example.get("data"), list):
            report.fail(where, "collection example has no data array")
            continue
        if page not in example:
            report.fail(where, f"collection example has no {page!r}")
        for forbidden in ("has_more", "prev_cursor"):
            if forbidden in example:
                report.fail(where, f"collection example has {forbidden}")
        if strategy == "cursor" and "total" in example and not include_total:
            report.fail(where, "collection example has total without include_total")


def check_error(where: str, status: str, example: object, fmt: str,
                catalogue: dict[str, str], report: Report) -> None:
    if not isinstance(example, dict):
        report.fail(where, f"{status} example is not an object")
        return
    if fmt == "problem_json":
        kind = example.get("type")
        code = kind.rstrip("/").rsplit("/", 1)[-1] if isinstance(kind, str) else ""
        if not code:
            report.fail(where, f"{status} example has no problem type")
        elif code not in catalogue:
            report.fail(where, f"{status} type {code!r} is not catalogued")
        elif catalogue[code] != status:
            report.fail(where, f"{status} type {code!r} is catalogued at {catalogue[code]}")
        if str(example.get("status")) != status:
            report.fail(where, f"{status} example status does not match")
        errors = example.get("errors")
        if isinstance(errors, list):
            for field in errors:
                code = field.get("code") if isinstance(field, dict) else None
                if isinstance(code, str) and (code not in catalogue or catalogue[code] != status):
                    report.fail(where, f"{status} field code {code!r} is not catalogued at {status}")
    elif fmt == "wrapped":
        error = example.get("error")
        code = error.get("code") if isinstance(error, dict) else None
        if not isinstance(code, str) or not code:
            report.fail(where, f"{status} example has no error.code")
        elif code not in catalogue or catalogue[code] != status:
            report.fail(where, f"{status} code {code!r} is not catalogued at {status}")


def success_media_type(doc: dict, op: dict) -> str | None:
    """The first media type of the operation's first success response."""
    responses = op.get("responses")
    if not isinstance(responses, dict):
        return None
    for status in sorted(str(s) for s in responses if str(s).startswith("2")):
        content = resolve(doc, responses[status]).get("content")
        if isinstance(content, dict):
            for media in content:
                if isinstance(media, str):
                    return media
    return None


def api_success_media_type(doc: dict) -> str:
    """The success media type the API uses for its bodies."""
    for _, _, op, _ in operations(doc):
        media = success_media_type(doc, op)
        if media is not None:
            return media
    return "application/json"


def is_collection_response(doc: dict, op: dict) -> bool:
    """A success schema whose top-level `data` member is an array."""
    responses = op.get("responses")
    if not isinstance(responses, dict):
        return False
    for status, raw in responses.items():
        if not str(status).startswith("2"):
            continue
        content = resolve(doc, raw).get("content")
        if not isinstance(content, dict):
            continue
        for body in content.values():
            if not isinstance(body, dict):
                continue
            props = resolve(doc, body.get("schema")).get("properties")
            if not isinstance(props, dict):
                continue
            if resolve(doc, props.get("data")).get("type") == "array":
                return True
    return False


def has_filter_parameter(doc: dict, conv: dict) -> bool:
    """A query parameter that is not one of the pagination controls."""
    page = conv.get("page_size_param", "limit")
    controls = {page, "cursor", "offset", "include_total", "sort"}
    for _, _, _, params in operations(doc):
        for param in params:
            if (isinstance(param, dict) and param.get("in") == "query"
                    and param.get("name") not in controls):
                return True
    return False


def check_cors(doc: dict, conv: dict, report: Report) -> None:
    """Only a browser-facing API owes a preflight; the axis says which it is."""
    if conv.get("cors") != "enabled":
        return
    paths = doc.get("paths")
    for path, item in (paths or {}).items():
        if isinstance(item, dict) and "options" not in item:
            report.fail(f"OPTIONS {path}", "cors is enabled but the path declares no preflight")
    for path, method, op, _ in operations(doc):
        where = f"{method.upper()} {path}"
        responses = op.get("responses")
        if not isinstance(responses, dict):
            continue
        for key, raw in responses.items():
            headers = resolve(doc, raw).get("headers")
            if not isinstance(headers, dict):
                continue
            names = {str(h).lower() for h in headers}
            origin = "access-control-allow-origin" in names
            if origin and "vary" not in names:
                report.fail(where, f"{key} sets Access-Control-Allow-Origin without Vary")
            if origin and "access-control-allow-credentials" in names:
                report.fail(where, f"{key} allows credentials with a reflected origin")


def check_operations(doc: dict, conv: dict, catalogue: dict[str, str], headers: dict,
                     report: Report) -> None:
    fmt = conv.get("error_format", "problem_json")
    page = conv.get("page_size_param", "limit")
    strategy = conv.get("pagination", "cursor")
    wrapped_media = api_success_media_type(doc) if fmt == "wrapped" else "application/problem+json"
    recorded = {str(f["name"]).lower() for f in (conv.get("header_fields") or [])
                if isinstance(f, dict) and f.get("name")}
    if conv.get("filter_syntax", "named") != "not_used" and not has_filter_parameter(doc, conv):
        report.fail("x-conventions.filter_syntax", "is recorded but no query parameter filters")
    for path, method, op, params in operations(doc):
        where = f"{method.upper()} {path}"
        label = op.get("x-auth")
        if not isinstance(label, str) or label not in {"public", "authenticated", "privileged"}:
            report.fail(where, "x-auth must be public, authenticated or privileged")
        if label == "privileged" and not op.get("x-privileged-check"):
            report.fail(where, "privileged endpoint has no x-privileged-check")
        if label == "public" and op.get("security") != []:
            report.fail(where, "public endpoint must set security: []")
        for param in params:
            if isinstance(param, dict) and param.get("in") == "header":
                name = str(param.get("name", "")).lower()
                if name and name not in REGISTERED and name not in recorded:
                    report.fail(where, f"private header {param.get('name')!r} is not recorded")
        responses = op.get("responses")
        if not isinstance(responses, dict) or not responses:
            report.fail(where, "no responses")
            continue
        is_collection = (
            any(isinstance(p, dict) and p.get("name") == page for p in params)
            or is_collection_response(doc, op)
        )
        if is_collection:
            if strategy == "not_used":
                report.fail(where, "collection cannot record pagination: not_used")
            else:
                check_collection(doc, where, op, params, conv, report)
        wanted = None
        if fmt == "problem_json":
            wanted = "application/problem+json"
        elif fmt == "wrapped":
            wanted = wrapped_media
        for key, response in responses.items():
            status = str(key)
            if status == "default" or status not in IANA_STATUS:
                report.fail(where, f"{status} is not an IANA status")
                continue
            response = resolve(doc, response)
            declared = response.get("headers")
            declared = declared if isinstance(declared, dict) else {}
            for header in headers.get(status, ()):
                if header not in declared:
                    report.fail(where, f"{status} is missing {header}")
            if method == "options" and status.startswith("2") and "Allow" not in declared:
                report.fail(where, f"{status} OPTIONS is missing Allow")
            if status.startswith("3") and status != "304" and "Location" not in declared:
                report.fail(where, f"{status} redirect is missing Location")
            if status in ("204", "304"):
                if response.get("content"):
                    report.fail(where, f"{status} must carry no body")
                continue
            if status.startswith("3") or method in ("head", "options"):
                continue
            content = response.get("content")
            if not isinstance(content, dict) or not content:
                report.fail(where, f"{status} has no body")
                continue
            examples = payloads(doc, response)
            if not examples:
                report.fail(where, f"{status} has no example")
            if status.startswith("2"):
                for example in examples:
                    if not isinstance(example, dict):
                        continue
                    for flag in ERROR_FLAGS:
                        if flag in example:
                            report.fail(where, f"{status} body carries the error flag {flag!r}")
                if not is_collection:
                    envelope = {"data", page, "next_cursor", "total", "offset"}
                    for example in examples:
                        if (isinstance(example, dict) and example
                                and set(example) <= envelope
                                and isinstance(example.get("data"), (dict, list))):
                            report.fail(where, "single-resource success body must be bare")
                continue
            if status.startswith(("4", "5")):
                if wanted is None:
                    report.fail(where, f"{status} is an error response but error_format "
                                       f"is {fmt!r}")
                    continue
                if wanted not in content:
                    report.fail(where, f"{status} must use {wanted}")
                for example in examples:
                    check_error(where, status, example, fmt, catalogue, report)


def check_document(doc: dict, report: Report) -> None:
    openapi = doc.get("openapi")
    if not isinstance(openapi, str) or not openapi.startswith("3.1"):
        report.fail("openapi", "must be an OpenAPI 3.1 document")
    info = doc.get("info")
    if not isinstance(info, dict):
        report.fail("info", "missing")
    else:
        for key in ("title", "version"):
            if not isinstance(info.get(key), str) or not info[key]:
                report.fail(f"info.{key}", "missing")
    if not isinstance(doc.get("paths"), dict):
        report.fail("paths", "missing")


def check_refs(value: object, doc: dict, report: Report, pointer: str = "") -> None:
    if isinstance(value, dict):
        ref = value.get("$ref")
        if isinstance(ref, str):
            if not ref.startswith("#"):
                report.fail(pointer or "<root>", f"external $ref {ref!r} is not supported")
            elif not resolve_pointer(doc, ref)[0]:
                report.fail(pointer or "<root>", f"unresolved $ref {ref!r}")
        for key, child in value.items():
            check_refs(child, doc, report, f"{pointer}/{key}")
    elif isinstance(value, list):
        for index, child in enumerate(value):
            check_refs(child, doc, report, f"{pointer}/{index}")


def check_internal(value: object, report: Report, pointer: str = "") -> None:
    if isinstance(value, str):
        if INTERNAL.search(value):
            report.fail(pointer or "<root>", "internal detail in a client-visible string")
    elif isinstance(value, dict):
        for key, child in value.items():
            check_internal(child, report, f"{pointer}/{key}")
    elif isinstance(value, list):
        for index, child in enumerate(value):
            check_internal(child, report, f"{pointer}/{index}")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Check an OpenAPI 3.1 contract against the api-design skill's conventions.")
    parser.add_argument("--contract", type=Path, required=True,
                        help="the OpenAPI 3.1 document to check")
    args = parser.parse_args()
    if yaml is None:
        print("error: PyYAML is required (pip install pyyaml)", file=sys.stderr)
        return 2
    try:
        axes, integers, headers = load_vocabulary(REFERENCES)
    except (OSError, ValueError, yaml.YAMLError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    if not args.contract.is_file():
        print(f"error: {args.contract} is not a file", file=sys.stderr)
        return 2
    try:
        doc = yaml.load(args.contract.read_text(encoding="utf-8"), Loader=StrictLoader)
    except (OSError, UnicodeDecodeError, yaml.YAMLError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    if not isinstance(doc, dict):
        print("error: the contract is not a mapping", file=sys.stderr)
        return 2
    report = Report()
    check_document(doc, report)
    check_refs(doc, doc, report)
    conv = check_axes(doc, axes, integers, report)
    catalogue = check_catalogue(doc, report)
    check_cors(doc, conv, report)
    check_operations(doc, conv, catalogue, headers, report)
    check_internal(doc, report)
    if report.failures:
        for failure in report.failures:
            print(f"FAIL: {failure}", file=sys.stderr)
        return 1
    print(f"OK: {args.contract}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
