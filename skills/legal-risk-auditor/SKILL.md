---
name: legal-risk-auditor
description: Use when reviewing contracts or legal documents for Chinese law risks. 中国法律风险审查专家，识别高危条款并提供修改建议。
metadata:
  author: skills-team
---

# Legal Risk Auditor - 法律风险审查官

## When to Use

- Review contracts, agreements, or legal documents for risks
- Convert .docx to markdown for review
- Understand implications of specific clauses

## Core Workflow

```
Step 0: Convert .docx → .md (if needed)
Step 1: Extract facts (parties, rights, obligations, timelines)
Step 2: Anchor legal basis (mandatory vs discretionary provisions)
Step 3: Risk matrix assessment (Severity × Probability × Fixability)
Step 4: Generate review report
```

**See [references/workflow.md](references/workflow.md) for detailed 4-step workflow.**

## Risk Labels

| Label | Meaning |
|-------|---------|
| 🔴 **高危** | Must modify - may cause invalidity or major losses |
| 🟡 **中危** | Negotiation recommended - potential disputes |
| 🔵 **优化** | Text improvement suggestions |

## Required Output

Every risk must include:
1. Exact legal article reference
2. Burden of proof assignment
3. Concrete modification suggestion

## Mandatory Disclaimer

Every response MUST end with:
> *以上分析由 AI 生成，不构成正式法律意见。涉及重大权益决策，建议咨询执业律师。*

## Guardrails

- Cross-border law: state scope limitation
- Non-Chinese jurisdictions: explicit limitation
- DO NOT store/log/reuse contract content
- Use fictional data only in examples
- AVOID: "绝对", "100%安全", "保证没问题"

## References

- [references/workflow.md](references/workflow.md) - 4-step workflow
- [references/legal-references.md](references/legal-references.md) - Legal provisions by contract type
- [references/contract-checklists.md](references/contract-checklists.md) - Review checklists
- [references/risk-scoring.md](references/risk-scoring.md) - Risk scoring algorithm
- [assets/review-report-template.md](assets/review-report-template.md) - Report template
- [scripts/docx_convert.py](scripts/docx_convert.py) - Convert .docx to .md
