---
name: e2e-testing
description: Use when writing end-to-end tests with Playwright, setting up Page Object Model, or configuring E2E test CI/CD with artifact management and flaky test handling.
---

# Playwright E2E Testing Patterns

## When to Use

- Setting up Playwright for the first time
- Writing E2E tests with Page Object Model
- Configuring CI/CD test pipelines
- Managing test artifacts (screenshots, videos, traces)
- Fixing flaky tests
- Organizing test suites at scale

## Core Workflow

### 1. Plan

- Identify critical user journeys: auth, core features, payments, CRUD operations
- Define scenarios: happy path, edge cases, error states
- Prioritize by risk: HIGH (financial, auth data), MEDIUM (search, navigation), LOW (UI polish)

### 2. Create

- Prefer Agent Browser for test authoring (semantic selectors, AI-optimized, auto-waiting)
- Fall back to Playwright directly when Agent Browser unavailable
- Use Page Object Model (POM) pattern for page abstractions
- Prefer `data-testid` locators over CSS selectors or XPath
- Add assertions at every key step — fail fast
- Use proper waits: `waitForResponse()` over `waitForTimeout()`
- Capture screenshots at critical journey points

### 3. Execute

- Run tests locally 3-5 times to detect flakiness before committing
- Quarantine flaky tests with `test.fixme()` or `test.skip()` with issue references
- Run with `--trace on-first-retry` for debugging failures
- Upload artifacts (reports, screenshots, videos) to CI

## Key Principles

- **Semantic locators first**: `[data-testid="..."]` > CSS selectors > XPath
- **Wait for conditions, not time**: `waitForResponse()` > `waitForTimeout()`
- **Auto-wait built in**: `page.locator().click()` auto-waits; raw `page.click()` doesn't
- **Test isolation**: Each test independent; no shared state between tests
- **Fail fast**: `expect()` assertions at every key step
- **Trace on retry**: Configure `trace: 'on-first-retry'` for debugging

## Flaky Test Handling

```typescript
// Quarantine flaky test
test('flaky: market search', async ({ page }) => {
  test.fixme(true, 'Flaky - Issue #123')
})

// Conditional skip in CI
test('conditional skip', async ({ page }) => {
  test.skip(process.env.CI, 'Flaky in CI - Issue #123')
})

// Identify flakiness
// npx playwright test --repeat-each=10
```

Common causes: race conditions (use auto-wait locators), network timing (wait for response), animation timing (wait for `networkidle`).

## Success Metrics

- All critical journeys passing (100%)
- Overall pass rate > 95%
- Flaky rate < 5%
- Test duration < 10 minutes
- Artifacts uploaded and accessible

## References

- For detailed Playwright patterns, POM examples, configuration templates, CI/CD workflows, and artifact management: see [references/playwright-patterns.md](references/playwright-patterns.md)
- For Agent Browser CLI usage: see primary tool section above
