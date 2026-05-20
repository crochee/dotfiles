# E2E Testing Skill

End-to-end testing skill for critical user journeys using Playwright (with Agent Browser preferred).

## What This Skill Does

This skill helps AI agents create, maintain, and execute E2E tests for web applications. It covers:

- **Test authoring**: Page Object Model patterns, semantic locators, proper assertions
- **Flaky test management**: Identify, quarantine, and debug unstable tests
- **Artifact collection**: Screenshots, videos, traces for debugging and reporting
- **CI/CD integration**: GitHub Actions pipelines, artifact uploads, parallel execution
- **Specialized testing**: Financial flows, wallet/web3 connections, high-risk operations

## When to Invoke

Ask the AI to use this skill when you need to:

- Write new E2E tests for user flows (login, search, checkout, etc.)
- Set up Playwright configuration from scratch
- Debug tests that pass locally but fail in CI
- Implement Page Object Model for better test maintainability
- Configure test reporting and artifact collection
- Add tests for payment or other critical flows

## Key Principles

1. **Semantic locators first**: `data-testid` attributes over CSS selectors
2. **Wait for conditions**: Response-based waits over arbitrary timeouts
3. **Fail fast**: Assertions at every key step in the user journey
4. **Test isolation**: No shared state between tests
5. **Agent Browser preferred**: Semantic selectors, AI-optimized, built on Playwright

## Structure

```
e2e-testing/
├── SKILL.md                 # Core instructions for AI agents
├── README.md                # This file - human-readable guide
└── references/
    └── playwright-patterns.md  # Detailed code examples and templates
```

## Quick Start

```bash
# Run all E2E tests
npx playwright test

# Run specific test file
npx playwright test tests/auth/login.spec.ts

# Run with trace for debugging
npx playwright test --trace on

# View HTML report
npx playwright show-report
```
