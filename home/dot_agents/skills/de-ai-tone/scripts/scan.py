#!/usr/bin/env python3
"""Scan prose for LLM tells.

Usage
-----
    python3 scan.py path/to/file.md
    python3 scan.py -                 # explicit stdin
    cat draft.md | python3 scan.py    # implicit stdin

Output: one `score:` line, then one line per hit in the form
`path:line: category: matched text`. Exit 0 when nothing matched, 1 when at
least one line matched, 2 when the input could not be read.

Category patterns
-----------------
hedge-stacking
    Multi-word hedges and stacked modals. "it is important|worth|crucial|
    essential to note|mention|remember|highlight that", "it should be noted
    that", "please note that", "may|might|could|can potentially|possibly|
    conceivably", "potentially may|might|could".
empty-transition
    Paragraph- or sentence-initial "Moreover,", "Furthermore,", "Additionally,",
    "In addition,", "That said,", "On the other hand,", "Consequently,".
triadic-padding
    Three joined value adjectives or manner adverbs drawn from a closed
    marketing lexicon: "powerful, seamless, and robust", "quickly, easily, and
    reliably". Ordinary technical enumerations do not use that lexicon.
not-just-x
    "not just|only|merely|simply X but (also) Y", "isn't just X, it's Y",
    "more than just a", "this is not just about".
meta-narration
    "in this section/article we will", "this article will explore", "let's
    dive|delve|explore|unpack", "we'll explore", "before we dive in", "by the
    end of this article".
empty-summary
    Sentence-initial "In summary," "In conclusion," "To sum up," "All in all,"
    "In short,", a "Key takeaways"/"Bottom line" label, and "what this means is
    that"/"at the end of the day".
translated-diction
    Calques and prestige verbs: "delve into", "dive deep into", "unlock the
    power|potential|value of", "harness the power of", "leverag*", "seamless*",
    "robust solution", "a testament to", "tapestry", "embark on a journey",
    "navigate the complexity|landscape", "in today's fast-paced|digital",
    "ever-evolving|changing|growing", "at the forefront of", "game-changer",
    "revolutioni*", "elevate your|the", "in the realm of".
corporate-jargon
    English management tokens ("synergy", "paradigm shift", "move the needle",
    "low-hanging fruit", "best-in-class", "world-class", "cutting-edge",
    "holistic", "value-add", "circle back", "core competency", "thought
    leadership", "next-generation", "turnkey solution", "end-to-end solution",
    "actionable insight", "operationalise") plus Chinese ones ("赋能", "闭环",
    "抓手", "生态位", "方法论沉淀", "顶层设计", "组合拳", "护城河", "降本增效",
    "全链路", "颗粒度", "底层逻辑", "数字化转型", "维度", and a short list of
    four-character slogans). Some of these are legitimate in context; the hit is
    a prompt to judge, not a verdict.
zh-translated-connective
    "值得注意的是", "值得一提的是", "需要注意的是", "总的来说", "综上所述",
    "不仅如此", "除此之外", "换言之", "众所周知", "毫无疑问".
zh-parallelism
    Repeated-clause padding: "既要…又要", "不仅…更是", "不只是…更是",
    "从…到…再到", "是…是…也是".
over-bold
    Three or more bold spans on one line (`**x**` or `__x__`).
emoji-bullet
    A list item whose first character is an emoji.
emdash-chain
    Three or more dashes on one line, counting a doubled "——" as one dash.

Lines inside fenced code blocks are skipped, inline code spans are ignored,
and a line carrying `scan: ignore` (optionally `scan: ignore over-bold,
emoji-bullet`) is exempt from that category. The score line counts distinct
flagged lines, never raw occurrences, so one sentence stuffed with hedges
counts once.
"""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path

CJK = re.compile(r"[\u4e00-\u9fff]")
LATIN_WORD = re.compile(r"[A-Za-z][A-Za-z'\u2019-]*")
FENCE = re.compile(r"^\s*(?:```|~~~)")
INLINE_CODE = re.compile(r"`[^`\n]*`")
IGNORE_MARKER = re.compile(r"scan:\s*ignore\b(.*)", re.IGNORECASE)


@dataclass(frozen=True)
class Rule:
    category: str
    pattern: re.Pattern
    threshold: int = 1


VALUE = (
    r"(?:powerful|seamless|scalable|secure|reliable|flexible|intuitive|elegant"
    r"|modern|innovative|comprehensive|dynamic|impactful|actionable|delightful"
    r"|effortless|holistic|streamlined|world-class|cutting-edge|best-in-class"
    r"|state-of-the-art|user-friendly|high-quality|next-generation|robust)"
)
ADVERB = (
    r"(?:efficiently|seamlessly|reliably|quickly|easily|effortlessly|robustly"
    r"|securely|intuitively)"
)

ZH_JARGON = (
    r"(?:赋能|闭环|抓手|生态位|方法论沉淀|顶层设计|组合拳|护城河|降本增效"
    r"|提质增效|全链路|颗粒度|底层逻辑|数字化转型|认知升级|价值共生|维度"
    r"|行稳致远|久久为功|守正创新|深度融合|全面升级|协同共赢|互利共赢"
    r"|共创未来|高质量发展)"
)

RULES: list[Rule] = [
    Rule(
        "hedge-stacking",
        re.compile(
            r"\b(?:it is|it's) (?:important|worth|crucial|essential) to"
            r" (?:note|mention|remember|highlight) that\b"
            r"|\bit should be (?:noted|mentioned|emphasi[sz]ed) that\b"
            r"|\bplease note that\b"
            r"|\b(?:may|might|could|can) (?:potentially|possibly|conceivably)\b"
            r"|\bpotentially (?:may|might|could)\b",
            re.IGNORECASE,
        ),
    ),
    Rule(
        "empty-transition",
        re.compile(
            r"(?:^|[.!?]\s+)(?:Moreover|Furthermore|Additionally|In addition"
            r"|That said|On the other hand|Consequently)\s*,",
            re.IGNORECASE,
        ),
    ),
    Rule(
        "triadic-padding",
        re.compile(
            rf"\b(?:{VALUE}|{ADVERB})\b,\s*(?:{VALUE}|{ADVERB})\b,?\s*"
            rf"(?:and|or)\s*(?:{VALUE}|{ADVERB})\b",
            re.IGNORECASE,
        ),
    ),
    Rule(
        "not-just-x",
        re.compile(
            r"\bnot (?:just|only|merely|simply) [^.!?;:\n]{1,60}? but (?:also )?"
            r"|\bis(?:n'?t| not) (?:just|only|merely|simply) [^.!?;\n]{1,60}?"
            r"\b(?:it'?s|that'?s)\b"
            r"|\bmore than just (?:a|an|the)\b"
            r"|\bthis is not (?:just|only) about\b",
            re.IGNORECASE,
        ),
    ),
    Rule(
        "meta-narration",
        re.compile(
            r"\bin this (?:section|article|post|guide|chapter|document),?"
            r" (?:we|i) (?:will|'ll|are going to|want to)\b"
            r"|\bthis (?:article|post|guide|section) (?:will|aims to|is going to)"
            r" (?:explore|delve|examine|cover|walk|look)\b"
            r"|\blet'?s (?:dive|delve|explore|unpack|take a look)\b"
            r"|\blet us (?:dive|delve|explore|unpack)\b"
            r"|\bwe'?ll (?:dive|delve|explore|unpack|take a look)\b"
            r"|\bbefore we (?:dive|begin|get started)\b"
            r"|\bby the end of this (?:article|post|guide|section)\b",
            re.IGNORECASE,
        ),
    ),
    Rule(
        "empty-summary",
        re.compile(
            r"(?:^|[.!?]\s+)(?:In summary|In conclusion|To sum up|All in all"
            r"|All told|In short)\s*,"
            r"|^\s*(?:Key takeaways?|Bottom line|The bottom line|The takeaway)\b"
            r"|\b(?:what this means is that|the key takeaway is|at the end of"
            r" the day)\b",
            re.IGNORECASE,
        ),
    ),
    Rule(
        "translated-diction",
        re.compile(
            r"\bdelve[sd]? into\b"
            r"|\bdive deep into\b"
            r"|\bunlock(?:s|ed|ing)? the (?:power|potential|value) of\b"
            r"|\bharness(?:es|ed|ing)? the power of\b"
            r"|\bleverag(?:e|es|ed|ing)\b"
            r"|\bseamless(?:ly)?\b"
            r"|\brobust solutions?\b"
            r"|\b(?:a|the) testament to\b"
            r"|\btapestry\b"
            r"|\bembark(?:s|ed|ing)? on (?:a|the|this) journey\b"
            r"|\bnavigate (?:the )?(?:complexit|landscape|world)\w*\b"
            r"|\bin today'?s (?:fast-paced|ever-changing|digital|modern)\b"
            r"|\bever-(?:evolving|changing|growing)\b"
            r"|\bat the forefront of\b"
            r"|\bgame[- ]chang(?:er|ers|ing)\b"
            r"|\brevolutioni[sz](?:e|es|ed|ing)\b"
            r"|\belevate (?:your|the|our)\b"
            r"|\bin the realm of\b",
            re.IGNORECASE,
        ),
    ),
    Rule(
        "corporate-jargon",
        re.compile(
            r"\bsynerg(?:y|ies|istic)\b"
            r"|\bparadigm shift\b"
            r"|\bmove the needle\b"
            r"|\blow-hanging fruit\b"
            r"|\bbest-in-class\b|\bworld-class\b"
            r"|\bcutting[- ]edge\b"
            r"|\bholistic(?:ally)?\b"
            r"|\bvalue[- ]add(?:ed)?\b"
            r"|\bcircle back\b"
            r"|\bcore competenc(?:y|ies)\b"
            r"|\bthought leadership\b"
            r"|\bnext-gen(?:eration)?\b"
            r"|\bturnkey (?:solution|platform)\b"
            r"|\bend-to-end solution\b"
            r"|\bactionable insights?\b"
            r"|\boperationali[sz]e\b"
            rf"|{ZH_JARGON}",
            re.IGNORECASE,
        ),
    ),
    Rule(
        "zh-translated-connective",
        re.compile(
            r"值得注意的是|值得一提的是|需要注意的是|总的来说|综上所述"
            r"|不仅如此|除此之外|换言之|众所周知|毫无疑问"
        ),
    ),
    Rule(
        "zh-parallelism",
        re.compile(
            r"既要[^。！？\n]{0,30}又要"
            r"|不仅[^。！？\n]{0,40}更是"
            r"|不只是[^。！？\n]{0,40}更是"
            r"|从[^。，！？\n]{1,12}到[^。，！？\n]{1,12}再到"
            r"|是[^。！？\n]{1,10}，?是[^。！？\n]{1,10}，?也是"
        ),
    ),
    Rule(
        "over-bold",
        re.compile(r"\*\*[^*\n]{1,60}\*\*|__[^_\n]{1,60}__"),
        threshold=3,
    ),
    Rule(
        "emoji-bullet",
        re.compile(
            r"^\s*(?:[-*+]|\d{1,2}[.)])\s+"
            r"(?:[\U0001F000-\U0001FAFF\u2600-\u27BF\u2B00-\u2BFF])"
        ),
    ),
    Rule("emdash-chain", re.compile(r"\u2014+"), threshold=3),
]


def ignore_marker(line: str) -> set[str] | None:
    """Return the exempt categories for a line, or None when unmarked.

    An empty set means the whole line is exempt.
    """
    match = IGNORE_MARKER.search(line)
    if not match:
        return None
    rest = re.sub(r"-{1,2}>\s*$", "", match.group(1) or "").strip()
    if not rest:
        return set()
    return {item for item in re.split(r"[,\s]+", rest) if item}


def scan(text: str) -> tuple[list[tuple[int, int, str, str]], int, int]:
    """Return (hits, words, cjk). Each hit is (line, rule index, category, text)."""
    hits: list[tuple[int, int, str, str]] = []
    prose: list[str] = []
    in_fence = False

    for lineno, raw in enumerate(text.splitlines(), 1):
        if FENCE.match(raw):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        prose.append(raw)
        if not raw.strip():
            continue
        exempt = ignore_marker(raw)
        if exempt is not None and not exempt:
            continue
        masked = INLINE_CODE.sub(lambda m: " " * len(m.group(0)), raw)
        for index, rule in enumerate(RULES):
            if exempt and rule.category in exempt:
                continue
            matches = [m.group(0) for m in rule.pattern.finditer(masked)]
            if len(matches) < rule.threshold:
                continue
            if rule.threshold > 1:
                found = re.sub(r"\s+", " ", matches[0].strip())
                hits.append(
                    (lineno, index, rule.category, f"{found} (x{len(matches)})"[:80])
                )
                continue
            for match in matches:
                found = re.sub(r"\s+", " ", match.strip())
                hits.append((lineno, index, rule.category, found[:80]))

    body = "\n".join(prose)
    words = len(LATIN_WORD.findall(body))
    cjk = len(CJK.findall(body))
    return hits, words, cjk


def read_input(source: str | None) -> tuple[str, str]:
    if source in (None, "-"):
        return sys.stdin.read(), "<stdin>"
    path = Path(source)
    return path.read_text(encoding="utf-8"), source


def main(argv: list[str]) -> int:
    if len(argv) > 1:
        print("scan.py: expected one file path or '-'", file=sys.stderr)
        return 2
    try:
        text, label = read_input(argv[0] if argv else None)
    except (OSError, UnicodeDecodeError) as error:
        print(f"scan.py: cannot read {argv[0]}: {error}", file=sys.stderr)
        return 2

    hits, words, cjk = scan(text)
    units = words + cjk
    lines = sorted({hit[0] for hit in hits})
    rate = (len(hits) / units * 1000) if units else 0.0
    print(
        f"score: {len(lines)} distinct lines flagged; {len(hits)} occurrences;"
        f" {units} units ({words} words + {cjk} CJK characters);"
        f" rate {rate:.1f} per 1000 units"
    )
    for lineno, _, category, found in hits:
        print(f"{label}:{lineno}: {category}: {found}")
    return 1 if hits else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
