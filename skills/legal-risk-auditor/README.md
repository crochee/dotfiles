# Legal Risk Auditor - 法律风险审查官

## 简介

Legal Risk Auditor 是一个专注于中国大陆法律框架的 AI 技能，用于审查合同和协议中的法律风险。它能够识别高危条款，提供合规建议，并给出替代方案。

## 功能特性

- **合同类型识别**: 自动识别买卖、租赁、服务、劳动、借款等合同类型
- **风险等级评估**: 三级风险评估体系（高危/中危/优化）+ 发生概率 + 可修复性
- **法条锚定**: 精准引用《民法典》等法律法规的具体条款
- **结构化报告**: 包含总体评估、效力评估、详细风险表、谈判策略和证据保全建议
- **隐私保护**: 不存储或复用用户提供的合同内容

## 使用场景

| 场景 | 示例输入 |
|:-----|:---------|
| 合同风险审查 | "帮我看看这份租赁合同有什么风险" |
| 条款解读 | "这份合同里的管辖条款合理吗？" |
| 谈判策略 | "对方要求我承担无限连带责任，我该怎么应对？" |
| 合规检查 | "我们的服务协议是否符合劳动法要求？" |

## 使用方法

直接将合同文本或具体条款粘贴到对话中即可。如需更详细的参考，可以：

1. 查看本技能目录下的 `references/` 目录，获取各类合同的详细审查清单
2. 查看 `assets/` 目录下的报告模板，了解输出格式

## 输出示例

技能会生成结构化的法律风险审查报告，包含：

- **综合评分**: XX/100
- **合同效力评估**: 主体适格、意思表示真实、内容合法性、形式要件
- **详细风险表**: 风险等级、涉及条款、法条依据、举证责任、修改建议
- **谈判策略**: 底线条款、可让步条款、建议增加条款、替代方案
- **证据保全建议**: 各类证据的保全方式

## 注意事项

- 本技能专注于中国大陆法律框架，跨境事务需另行咨询
- 分析结果不构成正式法律意见，涉及重大权益建议咨询执业律师
- 法律法规可能更新，重要条款建议核实最新版本

## 实用工具

本技能附带 `docx <-> markdown` 格式转换脚本，方便处理 Word 格式的合同文档。

### 前置条件

确保已安装 [uv](https://github.com/astral-sh/uv)，首次运行会自动安装依赖：

```bash
cd skills/legal-risk-auditor

# docx -> markdown
uv run scripts/docx_convert.py contract.docx

# markdown -> docx
uv run scripts/docx_convert.py contract.md

# 指定输出路径
uv run scripts/docx_convert.py contract.docx -o output.md
uv run scripts/docx_convert.py contract.md -o output.docx
```

## 目录结构

```
legal-risk-auditor/
├── SKILL.md                    # 核心技能文件（AI指令）
├── README.md                   # 本文件（使用说明）
├── references/                 # 参考文档
│   ├── legal-references.md     # 各类型合同法条速查表
│   ├── contract-checklists.md  # 5类常见合同审查清单
│   └── risk-scoring.md         # 风险评分算法详解
├── assets/                     # 静态资源
│   └── review-report-template.md  # 审查报告标准模板
└── scripts/                    # 实用脚本（内嵌 uv 依赖声明）
    └── docx_convert.py         # docx <-> md 格式转换
```
