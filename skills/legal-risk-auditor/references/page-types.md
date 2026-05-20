# Page Type Selection Rules

**Load this reference when:** selecting wiki pages to generate.

## Mandatory Pages (Always Generate)

| Page | Content Source |
|------|----------------|
| Overview | README.md, package files, entry point docs |
| Quick Start | Install scripts, Makefile targets |
| Project Structure | Directory tree, module layout |
| Configuration | Env vars, config files, CLI args |
| Usage | README examples, test files |
| Development | Makefile, test config, lint config |

## Optional Pages (When Detected)

| Page | Detection Signals |
|------|------------------|
| CLI Commands | pyproject.toml scripts, bin/, cmd/ |
| API Reference | __all__, api.py, OpenAPI spec |
| Installation | Non-pip dependencies |
| Troubleshooting | KNOWN_ISSUES, FAQ |
| Testing | test_*.py, *_test.go, tests/ |
| Contributing | CONTRIBUTING, CODE_OF_CONDUCT |

## Conditional Pages (Components Exist)

| Page | Detection |
|------|-----------|
| Deployment | Dockerfile, docker-compose.yml, workflows/deploy* |
| Architecture | Multiple packages with dependencies |
| Performance | bench_*, profiling config |
| Advanced Topics | Plugins, hooks, DSL |

## Monorepo Handling

When multiple packages detected:
- Overview lists all packages
- Project Structure shows monorepo layout
- Each package gets relevant pages