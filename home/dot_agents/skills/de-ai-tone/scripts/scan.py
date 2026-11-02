#!/usr/bin/env python3
"""Scan prose for LLM tells, by pattern number.

Usage
-----
    python3 scan.py path/to/file.md
    python3 scan.py -                 # explicit stdin
    cat draft.md | python3 scan.py    # implicit stdin

Output: one `score:` line, then one line per hit in the form
`path:line: PATTERN_ID category: matched text`, for example
`draft.md:12: A1 not-just-x: not just a product, but`. Exit 0 when nothing
matched, 1 when at least one line matched, 2 when the input could not be read.

The 44 patterns
----------------
A1  not-just-x            "not just X but Y"; "不是…而是"; "不仅…更是"
A2  one-line-closer       "That is the real win."; "Let that sink in."
A2  empty-summary         "In summary,"; "this underscores the importance of"
A3  deep-saying           "the real question is"; "what really matters"
A4  meta-narration        "In this section we will"; "let's dive in"
A4  empty-transition      "Moreover,"; "At its core"; "When it comes to"
A4  zh-translated-connective  "值得注意的是"; "总之"; "此外，"
A4  zh-empty-opening      "在当今…时代"; "在…背景下"
A5  arguing-with-nobody   "I'm not saying"; "A tempting approach would be"
A6  rhetorical-question   "那么…究竟…？"; "so what does this really mean"
A7  false-candour         "To be honest,"; "说实话"; "客观来讲"
A8  staged-contrast       "然而，事实并非如此"; "开启新篇章"
A9  attention-formula     "相比较…我更关心"; "大家最容易盯着"
B1  triadic-padding       "powerful, seamless, and robust"; "强大、优雅、易用"
B1  zh-parallelism        "既要…又要…还要"; "…而且…还…"
B2  repeated-openings     metric: three sentences in a row open the same way
B3  emdash-chain          three or more em dashes on one line
B4  hedge-stacking        "could potentially possibly"; "it is important to note"
B4  zh-hedge-stacking     "可能也许"; "在一定程度上"; "通常来说"
B5  hyphen-pairs          "the report is high-quality" (hyphen after the noun)
B6  passive-voice         "is preserved automatically"; "被广泛认为"
B7  preposition-opening   "随着…的不断发展"; "对于…来说"; "在…下"
B8  chained-de            three or more "的" in one clause
B9  nominalisation        "进行优化"; "实现提升"; "具有…可行性"
B11 colloquial-stack      "稳不稳…能不能"; "好不好…行不行"
B12 over-balanced         "一方面…另一方面"; "on the one hand…on the other hand"
B13 feature-triad         "可接入…可上线…可控成本"
B14 fake-span             "从A到B再到C"; "从X走向Y"; "from A to B to C"
C1  translated-diction    "delve into"; "tapestry"; "seamless"; "pivotal"
C2  inflated-significance "a pivotal moment"; "plays a key role"; "标志着…重要"
C3  vague-connection      "associated with"; "linked to"
C4  ing-rider             "symbolizing"; "showcasing"; "reflecting"
C5  sales-language        "nestled within"; "breathtaking"; "美不胜收"
C6  borrowed-authority    "Experts believe"; "业内专家普遍认为"
C7  avoiding-copula       "serves as"; "boasts"; "作为…角色"; "具备…能力"
C8  challenges-outlook    "机遇与挑战并存"; "在未来的征途上"
C9  corporate-jargon      "synergy"; "赋能"; "闭环"; "护城河"
C10 generic-positive      "未来可期"; "迈出重要一步"
D1  over-bold             three or more bold spans on one line
D2  labelled-list         "- **Label:** text"; "加粗小标题 + 冒号"
D3  decorative-heading    Title Case headings; "→" as decoration
D3  emoji-bullet          a list item whose first character is an emoji
D4  curly-quotes          " " and ' ' where the format uses straight quotes
D5  punctuation-spacing   half-width punctuation next to Chinese; missing
                           space between Chinese and Latin
E1  chatbot-residue       "I hope this helps!"; "希望以上内容对您有所帮助"
E2  knowledge-limit       "up to my last training update"; "截至我的知识库"
E3  heading-repeat        a heading followed by a line that restates it
E4  document-meta         "was added to replace"; "本文将介绍"; "如下所示"
E5  staged-persona        "我的判断很直接"; "说点扎心的"
B10 and F1 have no detector; they are judged by reading.

Lines inside fenced code blocks are skipped, inline code spans are ignored,
and a line carrying `scan: ignore` is exempt. The exemption accepts either
the category token or the pattern number, so `scan: ignore not-just-x`,
`scan: ignore A1` and `scan: ignore A1 not-just-x` all work, and markers
written before v2 keep working unchanged. The score line counts distinct
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
HEADING = re.compile(r"^\s{0,3}(#{1,6})\s+(.+?)\s*$")
SENTENCE_SPLIT = re.compile(r"(?<=[.!?。！？])\s+")
WORD = re.compile(r"[A-Za-z][A-Za-z'-]*")
STOPWORDS = {
    "the", "a", "an", "of", "to", "is", "are", "in", "on", "for", "and",
    "it", "this", "that", "these", "those", "be", "by", "as", "at", "or",
}
RESTATE_EN = re.compile(
    r"^[A-Za-z][\w\s'-]{0,40}?"
    r"\s(?:matters|counts|is\s+(?:key|important|critical|essential))\s*\.?$",
    re.IGNORECASE,
)
RESTATE_ZH = re.compile(
    r"^[一-鿿]{2,12}(?:很重要|很关键|至关重要|才是关键|是关键|不容忽视)[。！？]?$"
)


@dataclass(frozen=True)
class Rule:
    category: str
    pattern: re.Pattern
    threshold: int = 1
    pattern_id: str = ""
    kind: str = "regex"


VALUE = (
    r"(?:powerful|seamless|scalable|secure|reliable|flexible|intuitive|elegant"
    r"|modern|innovative|comprehensive|dynamic|impactful|actionable|delightful"
    r"|effortless|holistic|streamlined|world-class|cutting-edge|best-in-class"
    r"|state-of-the-art|user-friendly|high-quality|next-generation|robust"
    r"|fast|quick|simple|easy|efficient|modular|clean|safe|stable)"
)
ADVERB = (
    r"(?:efficiently|seamlessly|reliably|quickly|easily|effortlessly|robustly"
    r"|securely|intuitively)"
)
ZH_VALUE = (
    r"(?:强大|高效|可靠|安全|灵活|便捷|智能|精准|优雅|易用|清晰|流畅"
    r"|专业|先进|成熟|实用|简洁|美观|丰富|贴心)"
)
ZH_JARGON = (
    r"(?:赋能|闭环|抓手|生态位|方法论沉淀|顶层设计|组合拳|护城河|降本增效"
    r"|提质增效|全链路|颗粒度|底层逻辑|数字化转型|认知升级|价值共生|维度"
    r"|行稳致远|久久为功|守正创新|深度融合|全面升级|协同共赢|互利共赢"
    r"|共创未来|高质量发展|全面推进|生态链路|协同效应|战略布局|全方位发力"
    r"|打通[^。！？\n]{0,10}闭环|谱写[^。！？\n]{0,10}篇章|助力[^。！？\n]{0,6}腾飞)"
)

RULES: list[Rule] = [
    Rule(
        "not-just-x",
        re.compile(
            r"\bnot (?:just|only|merely|simply) [^.!?:\n]{1,60}? but (?:also )?"
            r"|\b(?:it'?s not|isn'?t) (?:just|only|merely|simply) [^.!?:\n]{1,60}?"
            r"\b(?:it'?s|that'?s)\b"
            r"|\bis not (?:just|only|merely|simply) [^.!?:\n]{1,60}?"
            r"\b(?:it'?s|that'?s)\b"
            r"|\bmore than just (?:a|an|the)\b"
            r"|\bthis is not (?:just|only) about\b"
            r"|不是[^。！？\n]{1,30}而是"
            r"|不仅[^。！？\n]{1,30}更是"
            r"|不仅仅[^。！？\n]{1,30}而是"
            r"|不只是[^。！？\n]{1,30}更是",
            re.IGNORECASE,
        ),
        pattern_id="A1",
    ),
    Rule(
        "one-line-closer",
        re.compile(
            r"\bthat(?:'s| is) the real win\b"
            r"|\bthat distinction matters\b"
            r"|\bread that again\b"
            r"|\blet that sink in\b"
            r"|\bthis shows the importance of\b"
            r"|\bthe message was clear\b"
            r"|\bit was a lesson in\b"
            r"|\bno (?:aesthetic|emotional|historical) (?:prior|novelty)\b"
            r"|(?:^|[.!?]\s)(?:[a-z]+\.\s+){2,}[a-z]+\."
            r"|(?:^|[.!?]\s)(?-i:[A-Z]{4,})[.!?](?:\s|$)"
            r"|这才是重点|真正的意义在于",
            re.IGNORECASE,
        ),
        pattern_id="A2",
    ),
    Rule(
        "empty-summary",
        re.compile(
            r"(?:^|[.!?]\s+)(?:In summary|In conclusion|To sum up|All in all"
            r"|All told|In short)\s*,"
            r"|^\s*(?:Key takeaways?|Bottom line|The bottom line|The takeaway)\b"
            r"|\b(?:what this means is that|the key takeaway is|at the end of the day)\b"
            r"|\bthis underscores the importance of\b"
            r"|\b(?:this|that) (?:really )?matters\b",
            re.IGNORECASE,
        ),
        pattern_id="A2",
    ),
    Rule(
        "deep-saying",
        re.compile(
            r"\bthe real question is\b"
            r"|\bin reality\b"
            r"|\bwhat really matters\b"
            r"|\bfundamentally\b"
            r"|\bthe deeper issue\b"
            r"|\bthe heart of the matter\b"
            r"|\bthe (?:language|currency|architecture) of\b"
            r"|\bbecomes? a trap\b"
            r"|\bis not a tool but a mirror\b",
            re.IGNORECASE,
        ),
        pattern_id="A3",
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
            r"|\bby the end of this (?:article|post|guide|section)\b"
            r"|\bhere'?s what you need to know\b"
            r"|\bnow let'?s look at\b"
            r"|\bwithout further ado\b"
            r"|\bthe thing is\b"
            r"|\bhere'?s the thing\b"
            r"|\bquick note\b"
            r"|\bheads up\b"
            r"|\bhonestly\?",
            re.IGNORECASE,
        ),
        pattern_id="A4",
    ),
    Rule(
        "empty-transition",
        re.compile(
            r"(?:^|[.!?]\s+)(?:Moreover|Furthermore|Additionally|In addition"
            r"|That said|On the other hand|Consequently)\s*,"
            r"|(?:^|[.!?]\s+)(?:At its core|When it comes to)\b",
            re.IGNORECASE,
        ),
        pattern_id="A4",
    ),
    Rule(
        "zh-translated-connective",
        re.compile(
            r"值得注意的是|值得一提的是|需要注意的是|总的来说|综上所述"
            r"|不仅如此|除此之外|换言之|众所周知|毫无疑问"
            r"|总而言之|一言以蔽之|由此可见|总之"
            r"|(?:此外|与此同时)[，,]"
            r"|不可否认的是|毋庸置疑的是|显而易见|不难发现|正如前文所述"
            r"|在此背景下|从某种意义上说|归根结底"
            r"|悄然(?:改变|拉开序幕|发生|出现|演变)"
        ),
        pattern_id="A4",
    ),
    Rule(
        "zh-empty-opening",
        re.compile(
            r"(?:在|随着)[^。！？\n]{0,24}(?:时代|浪潮|大潮|洪流)(?:下|里|中|之下)?[，,]"
            r"|(?:在|处于)[^。！？\n]{0,10}(?:的)?(?:背景下|大环境下|的时代)"
            r"|在(?:当今|当前|如今|这个)[^。！？\n]{0,20}(?:时代|背景|浪潮)"
        ),
        pattern_id="A4",
    ),
    Rule(
        "arguing-with-nobody",
        re.compile(
            r"\bthis isn'?t (?:mainly |just |really |only )?about\b"
            r"|\bi'?m not saying\b"
            r"|\bto be clear\b"
            r"|\bdon'?t get me wrong\b"
            r"|\bthis is not to say\b"
            r"|\bsome might say\b"
            r"|\ba tempting approach would be\b"
            r"|\bone might be tempted to\b"
            r"|\ban obvious approach would be\b"
            r"|\byou might think\b"
            r"|\bit would be easy to just\b"
            r"|我并不是说|并不是(?:要|在)?(?:否定|否认)"
            r"|诚然[，,][^。！？\n]{0,30}但(?:是|实际上)",
            re.IGNORECASE,
        ),
        pattern_id="A5",
    ),
    Rule(
        "rhetorical-question",
        re.compile(
            r"(?:那么|问题来了|那么问题来了)[，,]?[^。！？\n]{0,25}[?？]"
            r"|(?:究竟|到底)(?:是什么|意味着什么|意味着|该如何|如何|该怎么做)"
            r"[^。！？\n]{0,10}[?？]"
            r"|答案(?:其实)?(?:不言自明|显而易见|呼之欲出)"
            r"|\bso what does this really mean\b"
            r"|\bwhat really lies behind\b"
            r"|\bthe answer is (?:obvious|clear)\b",
            re.IGNORECASE,
        ),
        pattern_id="A6",
    ),
    Rule(
        "false-candour",
        re.compile(
            r"\bto be honest\b"
            r"|\bhonestly[，,]"
            r"|\bi (?:have to|must) admit\b"
            r"|\btruth be told\b"
            r"|\blet'?s be (?:real|honest)\b"
            r"|\bwe have to be honest\b"
            r"|说实话|老实说|不得不承认(?:的是)?|不可否认(?:的是)?|客观(?:来讲|而言)"
            r"|其实吧|说真的",
            re.IGNORECASE,
        ),
        pattern_id="A7",
    ),
    Rule(
        "staged-contrast",
        re.compile(
            r"(?:然而|不过|但是)[，,]?(?:事实并非如此|事情并非如此|问题并非如此|现实并非如此)"
            r"|(?:故事|一切|我们的工作|这个项目)[^。！？\n]{0,6}并未就此结束"
            r"|(?:开启|迈入|迈向)[^。！？\n]{0,12}(?:新篇章|新征程|新阶段)"
            r"|(?:让我们(?:一起)?|我们一起)(?:共同)?(?:开启|迈入|迈向)"
            r"[^。！？\n]{0,12}(?:新篇章|新征程|新阶段)"
            r"|but the story doesn'?t end (?:here|there)"
            r"|(?:embark|begin|start) (?:a|the) new (?:chapter|era|journey)"
            r"|the next chapter",
            re.IGNORECASE,
        ),
        pattern_id="A8",
    ),
    Rule(
        "attention-formula",
        re.compile(
            r"相比(?:较)?[^，。！？\n]{1,25}我(?:更|最)关心"
            r"|(?:大家|人们|我们)(?:最)?(?:容易|常常|往往|往往会)(?:关注|盯着|注意到|留意)"
            r"|(?:最|更)值得(?:我们|你)?(?:关注|留意|重视)的(?:是|在于)"
            r"|(?:让我|我们)(?:更)?(?:感兴趣|好奇)的是"
            r"|值得关注(?:的)?是"
            r"|\bwhat (?:interests|excites) me (?:most )?is\b"
            r"|\bthe most (?:overlooked|important) (?:aspect|thing) (?:here )?is\b"
            r"|\blet'?s focus on what (?:really )?matters\b",
            re.IGNORECASE,
        ),
        pattern_id="A9",
    ),
    Rule(
        "triadic-padding",
        re.compile(
            rf"\b(?:{VALUE}|{ADVERB})\b,\s*(?:{VALUE}|{ADVERB})\b,?\s*"
            rf"(?:and|or)\s*(?:{VALUE}|{ADVERB})\b"
            rf"|(?:{ZH_VALUE})[、,，](?:{ZH_VALUE})[、,，](?:{ZH_VALUE})",
            re.IGNORECASE,
        ),
        pattern_id="B1",
    ),
    Rule(
        "zh-parallelism",
        re.compile(
            r"既要[^。！？\n]{0,30}又要[^。！？\n]{0,30}(?:还要|还得|也要)"
            r"|而且[^。！？\n]{0,20}还(?:要|是|能|有|得)"
            r"|不仅[^。！？\n]{0,40}而且[^。！？\n]{0,40}还"
            r"|是[^。！？\n]{1,10}[，,]?是[^。！？\n]{1,10}[，,]?也是"
        ),
        pattern_id="B1",
    ),
    Rule(
        "repeated-openings",
        re.compile(r"(?!)"),
        pattern_id="B2",
        kind="metric",
    ),
    Rule(
        "emdash-chain",
        re.compile(r"\u2014+"),
        threshold=3,
        pattern_id="B3",
    ),
    Rule(
        "hedge-stacking",
        re.compile(
            r"\b(?:it is|it's) (?:important|worth|crucial|essential) to"
            r" (?:note|mention|remember|highlight) that\b"
            r"|\bit should be (?:noted|mentioned|emphasi[sz]ed) that\b"
            r"|\bplease note that\b"
            r"|\b(?:may|might|could|can) (?:potentially|possibly|conceivably)\b"
            r"|\bpotentially (?:may|might|could)\b"
            r"|\bto be fair\b"
            r"|\bit'?s also possible\b"
            r"|\bmight arguably\b"
            r"|\bin some cases it may\b"
            r"|\bthis is an inference\b",
            re.IGNORECASE,
        ),
        pattern_id="B4",
    ),
    Rule(
        "zh-hedge-stacking",
        re.compile(
            r"(?:可能|也许|或许|大概|恐怕)[^。！？\n]{0,6}?"
            r"(?:可能|也许|或许|大概|恐怕|在(?:一定|某)(?:种)?(?:程度|意义)上|(?:通常|一般)(?:来说|情况下))"
            r"|在(?:一定|某)(?:种)?(?:程度|意义)上"
            r"|(?:通常|一般)(?:来说|情况下)"
        ),
        pattern_id="B4",
    ),
    Rule(
        "hyphen-pairs",
        re.compile(
            r"\b(?:is|are|was|were|be|been|being|look|looks|looked|feel|feels|felt"
            r"|seems|seemed|remains|remained|stays|stayed)\s+(?:very |quite |really |truly |so |too |rather )?"
            r"(?:[a-z]+-)?(?:high-quality|well-known|well-documented|long-term|real-time"
            r"|client-facing|state-of-the-art|cost-effective|world-class|off-the-shelf"
            r"|next-generation|end-to-end|first-class|user-facing|mission-critical)\b",
            re.IGNORECASE,
        ),
        pattern_id="B5",
    ),
    Rule(
        "passive-voice",
        re.compile(
            r"\b(?:is|are|was|were|be|been|being)\s+(?:\w+ly\s+)?(?:preserved"
            r"|determined|designed|implemented|achieved|generated|conducted"
            r"|performed|obtained|required|expected|considered|provided"
            r"|supported|monitored|enforced|optimised|optimized|analysed"
            r"|analyzed|evaluated|reported|handled|executed|processed|stored"
            r"|written|developed|delivered|managed|governed|orchestrated"
            r"|centralized|standardized|validated|verified|calibrated)\b"
            r"|\b(?:gets|got)\s+(?:\w+ed|written|done|made|built|held|given|known|shown)\b"
            r"|^\s*(?:No|There (?:is|are))\s+[a-z][^.!?\n]{0,40}?"
            r"\b(?:needed|required|possible|available|done|used)\b"
            r"|被(?:广泛|充分|成功|正式|共同|普遍|积极|主动|彻底|统一|深入)[^。！？\n]{0,8}"
            r"|被(?:视为|作为|称为|叫做|当作)[^。！？\n]{0,10}(?:使用|看待|处理|实现)"
            r"|被[^。！？\n]{1,8}(?:所|予以)",
            re.IGNORECASE | re.MULTILINE,
        ),
        pattern_id="B6",
    ),
    Rule(
        "preposition-opening",
        re.compile(
            r"^\s*(?:随着|对于|通过|基于|按照)[^。！？\n]{1,30}?"
            r"(?:的(?:不断|持续|日益|迅猛|蓬勃|空前)(?:发展|推进|提升|演进)"
            r"|来说|而言|的(?:引入|实施|采用|应用|落地))[，,]?"
            r"|^\s*在[^。！？\n]{1,25}?下[，,]"
        ),
        pattern_id="B7",
    ),
    Rule(
        "chained-de",
        re.compile(r"(?:[^。！？\n，、]{1,12}的){3,4}"),
        pattern_id="B8",
    ),
    Rule(
        "nominalisation",
        re.compile(
            r"进行[^。！？\n]{1,6}(?:优化|调整|提升|改进|重构|分析|讨论|评估|探讨|整合|部署|测试|验证|设计|实施)"
            r"|实现[^。！？\n]{1,6}(?:提升|增长|优化|改进|提高)"
            r"|具有[^。！？\n]{1,10}(?:可行性|必要性|重要性|价值|意义)"
            r"|展开[^。！？\n]{0,4}探讨"
            r"|(?:做出了?|进行了?)[^。！？\n]{1,8}(?:操作|工作)"
        ),
        pattern_id="B9",
    ),
    Rule(
        "colloquial-stack",
        re.compile(
            r"(?:稳不稳|能不能|会不会|好不好|行不行|是不是|对不对|有没有)"
            r"[^。！？\n]{0,12}"
            r"(?:稳不稳|能不能|会不会|好不好|行不行|是不是|对不对|有没有)"
        ),
        pattern_id="B11",
    ),
    Rule(
        "over-balanced",
        re.compile(
            r"一方面[^。！？\n]{1,50}另一方面"
            r"|\bon the one hand\b[^.\n]{0,100}\bon the other hand\b",
            re.IGNORECASE,
        ),
        pattern_id="B12",
    ),
    Rule(
        "feature-triad",
        re.compile(
            r"可(?:接入|上线|扩展|复用|观测|治理|编排|集成|迁移|控)[^。！？\n]{1,15}"
            r"可(?:接入|上线|扩展|复用|观测|治理|编排|集成|迁移|控)[^。！？\n]{1,15}"
            r"可(?:接入|上线|扩展|复用|观测|治理|编排|集成|迁移|控)"
        ),
        pattern_id="B13",
    ),
    Rule(
        "fake-span",
        re.compile(
            r"从[^。，！？\n]{1,12}到[^。，！？\n]{1,12}(?:再到|走向|迈向)"
            r"|从[^。，！？\n]{1,12}(?:走向|迈向|迈入)[^。，！？\n]{1,12}"
            r"|已经[^。，！？\n]{1,8}进入[^。，！？\n]{1,8}(?:阶段|时代|新阶段)"
            r"|\bfrom\b[^.\n]{1,40}\bto\b[^.\n]{1,40}\bto\b",
            re.IGNORECASE,
        ),
        pattern_id="B14",
    ),
    Rule(
        "translated-diction",
        re.compile(
            r"\bdelve[sd]? into\b"
            r"|\bdive deep into\b"
            r"|\bdeep dive\b"
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
            r"|\bin the realm of\b"
            r"|\bgarner(?:s|ed|ing)? (?:attention|interest)\b"
            r"|\binterplay\b"
            r"|\bintricate(?:s)?\b|\bintricacies\b"
            r"|\bmeticulous(?:ly)?\b"
            r"|\bpivotal\b"
            r"|\bshowcas(?:e|es)\b"
            r"|\bvibrant\b"
            r"|\bbolster(?:s|ed|ing)?\b"
            r"|\benduring\b"
            r"|\balign(?:s|ed|ing)? with\b",
            re.IGNORECASE,
        ),
        pattern_id="C1",
    ),
    Rule(
        "inflated-significance",
        re.compile(
            r"\bstands as a testament\b"
            r"|\ba (?:pivotal|crucial) moment\b"
            r"|\bplays a key role\b"
            r"|\bmarking (?:a|the) (?:pivotal|turning|watershed)\b"
            r"|\bunderscores its importance\b"
            r"|\breflects a broader\b"
            r"|\bsetting the stage for\b"
            r"|\b(?:the )?evolving landscape\b"
            r"|\bindelible mark\b"
            r"|\bdespite these challenges\b"
            r"|\bcontinues to thrive\b"
            r"|\bchallenges and legacy\b"
            r"|\bfuture outlook\b"
            r"|\bawards and recognition\b"
            r"|\bthe future looks bright\b"
            r"|\bexciting times ahead\b"
            r"|\ba step in the right direction\b"
            r"|标志着[^。！？\n]{0,20}(?:重要|里程碑|转折点|关键)"
            r"|具有里程碑意义|留下了不可磨灭的印记|生动诠释了"
            r"|(?:这|它|此)[^。！？\n]{0,12}并非[^。！？\n]{0,12}而是[^。！？\n]{0,12}(?:更|的)",
            re.IGNORECASE,
        ),
        pattern_id="C2",
    ),
    Rule(
        "vague-connection",
        re.compile(
            r"\b(?:associated with|in association with|connected to"
            r"|in connection with|linked to|tied to)\b",
            re.IGNORECASE,
        ),
        pattern_id="C3",
    ),
    Rule(
        "ing-rider",
        re.compile(
            r"\b(?:highlighting|underscoring|emphasizing|ensuring|reflecting"
            r"|symbolizing|contributing to|cultivating|fostering|encompassing|showcasing)\b",
            re.IGNORECASE,
        ),
        pattern_id="C4",
    ),
    Rule(
        "sales-language",
        re.compile(
            r"\b(?:profound|exemplifies|nestled|renowned|featuring|breathtaking"
            r"|must-visit|stunning|groundbreaking|iconic)\b"
            r"|\bin the heart of\b"
            r"|\bcommitment to\b"
            r"|\bnatural beauty\b"
            r"|\bdiverse array\b"
            r"|(?:坐落于|位于)[^。！？\n]{0,20}(?:的)?(?:心脏|中心)地带"
            r"|美不胜收|令人神往",
            re.IGNORECASE,
        ),
        pattern_id="C5",
    ),
    Rule(
        "borrowed-authority",
        re.compile(
            r"\b(?:experts (?:argue|believe|say|claim|note)"
            r"|observers have cited|industry reports|certain reports|some critics"
            r"|several publications|it is believed that|widely (?:regarded|believed"
            r"|recognised|recognized)|trade publications|active social media presence"
            r"|according to (?:experts|analysts))\b"
            r"|(?:业内)?专家(?:们)?(?:普遍)?(?:认为|表示|指出|断言)"
            r"|(?:相关)?(?:行业)?报告(?:指出|显示|表明|称)"
            r"|许多观察家(?:表示|认为)|不难看出|普遍认为",
            re.IGNORECASE,
        ),
        pattern_id="C6",
    ),
    Rule(
        "avoiding-copula",
        re.compile(
            r"\b(?:serves as|stands as|functions as|operates as|marks a"
            r"|represents a|boasts|features|offers|maintains|refers to)\b"
            r"|作为[^。！？\n]{1,15}(?:的)?(?:角色|基础|载体|工具|平台|手段|前提|保证|标志)"
            r"|充当[^。！？\n]{1,15}(?:的)?(?:角色|枢纽|基础|工具|平台|手段)"
            r"|具备[^。！？\n]{0,6}(?:能力|水平|优势|价值|条件)"
            r"|展现[^。！？\n]{0,8}(?:了)?(?:价值|能力|水平|魅力|实力|潜力)",
            re.IGNORECASE,
        ),
        pattern_id="C7",
    ),
    Rule(
        "challenges-outlook",
        re.compile(
            r"尽管[^。！？\n]{0,25}挑战[^。！？\n]{0,30}(?:依然|仍然|但)[^。！？\n]{0,20}(?:韧性|活力|生机|生命力)"
            r"|(?:机遇与挑战并存|挑战与机遇并存)"
            r"|在未来的征途上"
            r"|然而[，,]?前方的道路并非坦途"
            r"|尽管面临[^。！？\n]{0,20}挑战[^。！？\n]{0,25}(?:但|然而)",
        ),
        pattern_id="C8",
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
        pattern_id="C9",
    ),
    Rule(
        "generic-positive",
        re.compile(
            r"未来可期|未来(?:将|会)?(?:更加|更)(?:美好|光明|精彩)"
            r"|迈出(?:了)?(?:重要|关键)(?:的)?(?:一)?步"
            r"|持续(?:追求|致力于|专注于)(?:卓越|创新|进步)"
            r"|(?:朝着|向着)[^。！？\n]{0,15}(?:更(?:好|高|快|优)的)?(?:目标|方向|未来)(?:迈进|出发|前进)"
            r"|\bthe future is (?:bright|promising)\b",
            re.IGNORECASE,
        ),
        pattern_id="C10",
    ),
    Rule(
        "over-bold",
        re.compile(r"\*\*[^*\n]{1,60}\*\*|__[^_\n]{1,60}__"),
        threshold=3,
        pattern_id="D1",
    ),
    Rule(
        "labelled-list",
        re.compile(
            r"^\s*(?:[-*+]|\d{1,2}[.)])\s+\*\*[^*\n]{1,40}\*\*\s*[:：]"
            r"|^\s*(?:[-*+]|\d{1,2}[.)])\s+\*\*[^*\n]{1,40}[:：]\*\*",
            re.MULTILINE,
        ),
        pattern_id="D2",
    ),
    Rule(
        "decorative-heading",
        re.compile(
            r"^#{1,6}\s+[A-Z][a-z]+(?:\s+[A-Z][a-z]+){2,}\s*$"
            r"|(?:^|\s)[→←⇒➜](?:\s|$)",
            re.MULTILINE,
        ),
        pattern_id="D3",
    ),
    Rule(
        "emoji-bullet",
        re.compile(
            r"^\s*(?:[-*+]|\d{1,2}[.)])\s+"
            r"(?:[\U0001F000-\U0001FAFF\u2600-\u27BF\u2B00-\u2BFF])"
        ),
        pattern_id="D3",
    ),
    Rule(
        "curly-quotes",
        re.compile(r"[\u201c\u201d\u2018\u2019]"),
        pattern_id="D4",
    ),
    Rule(
        "punctuation-spacing",
        re.compile(
            r"(?<=[\u4e00-\u9fff])[,.;:!?]"
            r"|(?<=[,.;:!?])[\u4e00-\u9fff]"
            r"|(?<=[\u4e00-\u9fff])[A-Za-z0-9]"
            r"|(?<=[A-Za-z0-9])[\u4e00-\u9fff]"
        ),
        pattern_id="D5",
    ),
    Rule(
        "chatbot-residue",
        re.compile(
            r"\b(?:i hope this helps|of course|certainly|great question"
            r"|you'?re absolutely right|would you like|want me to|should i continue"
            r"|let me know|here is a)\b"
            r"|好的[，,]?没问题|希望(?:以上)?(?:内容)?(?:对您|对你)?(?:有所)?帮助"
            r"|接下来我将从|为您深度剖析|这是一个非常[^。！？\n]{0,10}的问题",
            re.IGNORECASE,
        ),
        pattern_id="E1",
    ),
    Rule(
        "knowledge-limit",
        re.compile(
            r"\bup to my last (?:training|knowledge) update\b"
            r"|\bwhile specific details are (?:limited|unclear)\b"
            r"|\bbased on available information\b"
            r"|\bnot publicly available\b"
            r"|\bnot widely documented\b"
            r"|\bin the (?:provided|available) sources\b"
            r"|\bit is believed that\b"
            r"|\bmaintains a low profile\b"
            r"|截至(?:我的|本人)?知识库(?:更新|截止)时间"
            r"|由于(?:公开)?信息有限[，,]?(?:推测|预计|推断)?可能",
            re.IGNORECASE,
        ),
        pattern_id="E2",
    ),
    Rule(
        "heading-repeat",
        re.compile(r"(?!)"),
        pattern_id="E3",
        kind="pair",
    ),
    Rule(
        "document-meta",
        re.compile(
            r"\b(?:was added to replace|generated from|compiled from"
            r"|the table below compares|the figure below|the chart below"
            r"|the list below shows|this section is organized by)\b"
            r"|本文(?:将|会|旨在|主要)?(?:介绍|讲述|探讨|分析|阐述)"
            r"|这篇文章(?:想|要|将)?(?:回答|介绍|探讨)"
            r"|本节(?:将|会)(?:介绍|讨论)"
            r"|如下(?:所示|将)|详见下表",
            re.IGNORECASE,
        ),
        pattern_id="E4",
    ),
    Rule(
        "staged-persona",
        re.compile(
            r"我的判断(?:很|非常)?(?:直接|干脆)"
            r"|说点(?:扎心|大实话|实在的)"
            r"|扎心(?:的)?(?:一句|真相|现实)"
            r"|不吐不快"
            r"|\bmy (?:honest|take|real) (?:take|answer|opinion)\b"
            r"|\bhere'?s the (?:honest )?truth\b"
            r"|\bwithout (?:the )?(?:sugar coating|bullshit)\b",
            re.IGNORECASE,
        ),
        pattern_id="E5",
    ),
]


def ignore_marker(line: str) -> set[str] | None:
    """Return the exempt tokens for a line, or None when unmarked.

    An empty set means the whole line is exempt. Tokens are matched against
    both the category and the pattern number of a rule, so old markers that
    name a category keep working.
    """
    match = IGNORE_MARKER.search(line)
    if not match:
        return None
    rest = re.sub(r"-{1,2}>\s*$", "", match.group(1) or "").strip()
    if not rest:
        return set()
    return {item for item in re.split(r"[,\s]+", rest) if item}


def exempt_rule(rule: Rule, exempt: set[str] | None) -> bool:
    """True when the line's marker excuses this rule."""
    if not exempt:
        return False
    return rule.category in exempt or rule.pattern_id in exempt


def first_words(sentence: str) -> str:
    """The opening key of a sentence: its first Latin word, or its first four
    Chinese characters."""
    stripped = sentence.strip()
    if not stripped:
        return ""
    if CJK.match(stripped):
        return stripped[:4]
    match = WORD.match(stripped)
    return match.group(0).lower() if match else ""


def repeated_openings(prose: list[tuple[int, str]]) -> list[tuple[int, str, str, str]]:
    """B2: three or more sentences in a row opening the same way."""
    hits: list[tuple[int, str, str, str]] = []
    paragraph: list[tuple[int, str]] = []

    def flush() -> None:
        if not paragraph:
            return
        text = " ".join(line for _, line in paragraph)
        sentences = [s.strip() for s in SENTENCE_SPLIT.split(text) if s.strip()]
        keys = [first_words(sentence) for sentence in sentences]
        for index in range(len(sentences) - 2):
            trio = keys[index : index + 3]
            if not trio[0] or len(set(trio)) != 1:
                continue
            bodies = {re.sub(r"\s+", " ", s.lower()) for s in sentences[index : index + 3]}
            if len(bodies) == 1:
                continue
            lineno = paragraph[0][0]
            exempt = ignore_marker(paragraph[0][1])
            if exempt is not None and (
                not exempt
                or "repeated-openings" in exempt
                or "B2" in exempt
            ):
                paragraph.clear()
                return
            hits.append((lineno, "B2", "repeated-openings", f"{trio[0]} x3"))
            break
        paragraph.clear()

    for lineno, line in prose:
        if not line.strip():
            flush()
            continue
        paragraph.append((lineno, line))
    flush()
    return hits


def heading_repeats(prose: list[tuple[int, str]]) -> list[tuple[int, str, str, str]]:
    """E3: a heading whose next line only restates it."""
    hits: list[tuple[int, str, str, str]] = []
    for index, (lineno, line) in enumerate(prose):
        heading = HEADING.match(line)
        if not heading:
            continue
        for next_lineno, next_line in prose[index + 1 :]:
            if not next_line.strip():
                continue
            words = {
                word.lower()
                for word in WORD.findall(heading.group(2))
                if word.lower() not in STOPWORDS
            }
            other = {
                word.lower()
                for word in WORD.findall(next_line)
                if word.lower() not in STOPWORDS
            }
            restates = RESTATE_EN.match(next_line.strip()) or RESTATE_ZH.match(
                next_line.strip()
            )
            shares = bool(words) and len(words & other) / len(words) >= 0.5
            if not restates and not shares:
                break
            if len(next_line.strip()) > 80:
                break
            exempt = ignore_marker(next_line)
            if exempt is not None and (
                not exempt or "heading-repeat" in exempt or "E3" in exempt
            ):
                break
            hits.append((next_lineno, "E3", "heading-repeat", next_line.strip()[:80]))
            break
    return hits


def scan(text: str) -> tuple[list[tuple[int, str, str, str]], int, int]:
    """Return (hits, words, cjk). Each hit is (line, pattern_id, category, text)."""
    hits: list[tuple[int, str, str, str]] = []
    prose: list[tuple[int, str]] = []
    in_fence = False

    for lineno, raw in enumerate(text.splitlines(), 1):
        if FENCE.match(raw):
            in_fence = not in_fence
            prose.append((lineno, ""))
            continue
        if in_fence:
            prose.append((lineno, ""))
            continue
        prose.append((lineno, raw))
        if not raw.strip():
            continue
        exempt = ignore_marker(raw)
        if exempt is not None and not exempt:
            continue
        masked = INLINE_CODE.sub(lambda m: " " * len(m.group(0)), raw)
        for rule in RULES:
            if rule.kind != "regex":
                continue
            if exempt_rule(rule, exempt):
                continue
            matches = [m.group(0) for m in rule.pattern.finditer(masked)]
            if len(matches) < rule.threshold:
                continue
            if rule.threshold > 1:
                found = re.sub(r"\s+", " ", matches[0].strip())
                hits.append(
                    (lineno, rule.pattern_id, rule.category, f"{found} (x{len(matches)})"[:80])
                )
                continue
            for match in matches:
                found = re.sub(r"\s+", " ", match.strip())
                hits.append((lineno, rule.pattern_id, rule.category, found[:80]))

    hits.extend(repeated_openings(prose))
    hits.extend(heading_repeats(prose))
    hits.sort(key=lambda hit: (hit[0], hit[1]))

    body = "\n".join(line for _, line in prose)
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
    try:
        print(
            f"score: {len(lines)} distinct lines flagged; {len(hits)} occurrences;"
            f" {units} units ({words} words + {cjk} CJK characters);"
            f" rate {rate:.1f} per 1000 units"
        )
        for lineno, pattern_id, category, found in hits:
            label_text = f"{pattern_id} {category}" if pattern_id else category
            print(f"{label}:{lineno}: {label_text}: {found}")
    except BrokenPipeError:
        # The reader closed the pipe, for example `scan.py draft.md | head`.
        pass
    return 1 if hits else 0


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except BrokenPipeError:
        sys.exit(1)
