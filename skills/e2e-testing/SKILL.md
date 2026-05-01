---
name: e2e-testing
description: Use when writing end-to-end tests with Playwright, setting up Page Object Model, or configuring E2E test CI/CD with artifact management.
metadata:
  author: skills-team
---

# Playwright E2E Testing

## When to Use

- Setting up Playwright
- Writing E2E tests with Page Object Model
- Configuring CI/CD test pipelines
- Managing test artifacts
- Fixing flaky tests

## Core Workflow

| Phase | Actions |
|-------|---------|
| **Plan** | Identify critical journeys, define scenarios, prioritize by risk |
| **Create** | POM pattern, `data-testid` locators, auto-waiting, assertions |
| **Execute** | Run 3-5x locally, quarantine flaky, upload artifacts |

## Key Principles

- **Semantic locators:** `[data-testid="..."]` > CSS > XPath
- **Wait for conditions:** `waitForResponse()` > `waitForTimeout()`
- **Auto-wait built in:** `page.locator().click()` waits; `page.click()` doesn't
- **Test isolation:** No shared state between tests
- **Fail fast:** `expect()` at every key step

## Flaky Test Handling

```typescript
// Quarantine
test.fixme(true, 'Flaky - Issue #123')

// Conditional skip in CI
test.skip(process.env.CI, 'Flaky - Issue #123')

// Identify flakiness
npx playwright test --repeat-each=10
```

**Common causes:** Race conditions, network timing, animation timing.

## Success Metrics

- Critical journeys: 100% passing
- Overall pass rate: > 95%
- Flaky rate: < 5%
- Duration: < 10 minutes

## References

- [references/playwright-patterns.md](references/playwright-patterns.md) - POM, configuration, CI/CD
- [references/flaky-tests.md](references/flaky-tests.md) - Detection and handling
- [references/artifact-management.md](references/artifact-management.md) - Screenshots, videos, traces