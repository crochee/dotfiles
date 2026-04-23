# Repo Wiki

Generate a complete, professional multi-page project wiki grounded entirely in the actual codebase.

## What It Does

- Creates comprehensive documentation from your codebase
- Output language matches your query
- Writes to `./.open_docs/` directory
- No generic templates - all content reflects your actual project

## Pages Generated

### Required (always created)
- Overview
- Quick Start
- Project Structure
- Configuration
- Usage
- Development

### Optional (if detected in repo)
- CLI Commands
- API Reference
- Installation
- Troubleshooting
- FAQ
- Testing
- Contributing
- Deployment
- Architecture
- Performance
- Advanced Topics

## Helper Script

A Python script is included to scaffold wiki structure:

```bash
python3 scripts/scaffold_open_docs.py --query "Your query here"
```

## Core Rules

- **Grounding**: All technical content from current repo - no invention
- **Language**: Output matches user query language
- **No handoff**: Complete pages, no "see English version"
- **No hollow pages**: Meaningful content, not just stubs
- **No over-generation**: Only create pages that have grounding
