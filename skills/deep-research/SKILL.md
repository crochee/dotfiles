---
name: deep-research
description: Use when conducting multi-source research on a topic, synthesizing findings from web searches, or producing cited reports with source attribution.
metadata:
  author: skills-team
---

# Deep Research

Produce thorough, cited research reports from multiple web sources.

## When to Use

- Research any topic in depth
- Competitive analysis, technology evaluation
- Due diligence on companies, technologies
- Questions requiring synthesis from multiple sources

**Requires:** firecrawl or exa MCP tools.

## Workflow

```
1. Understand goal → 2. Plan research (3-5 sub-questions) → 3. Execute search
4. Deep-read key sources → 5. Synthesize and write → 6. Deliver
```

**See [references/research-workflow.md](references/research-workflow.md) for detailed workflow.**

## Research Process

**Plan:** Break topic into 3-5 sub-questions

**Search:** 2-3 keyword variations per sub-question, 15-30 sources total

**Deep-read:** 3-5 promising URLs in full (not just snippets)

**Report structure:**
```markdown
# [Topic]: Research Report
*Generated: [date] | Sources: [N] | Confidence: [High/Medium/Low]*

## Executive Summary
[3-5 sentence overview]

## 1. [First Major Theme]
[Findings with inline citations]

## Key Takeaways
- [Actionable insight 1]
- [Actionable insight 2]

## Sources
1. [Title](url) — [one-line summary]
```

## Quality Rules

| Rule | Description |
|------|-------------|
| Every claim needs source | No unsourced assertions |
| Cross-reference | One source = unverified |
| Recency matters | Prefer last 12 months |
| Acknowledge gaps | Say if no good info found |
| No hallucination | Say "insufficient data" |
| Fact vs inference | Label estimates clearly |

## Parallel Research

For broad topics, use Task tool:
```
Agent 1: Research sub-questions 1-2
Agent 2: Research sub-questions 3-4
Agent 3: Research sub-question 5 + cross-cutting
```

Main session synthesizes final report.

## References

- [references/research-workflow.md](references/research-workflow.md) - 6-step workflow
- [references/report-template.md](references/report-template.md) - Report structure
- [references/quality-rules.md](references/quality-rules.md) - Quality guidelines