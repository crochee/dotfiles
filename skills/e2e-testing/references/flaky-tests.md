# E2E Test Flakiness Guide

**Load this reference when:** fixing flaky Playwright tests.

## Flaky Test Patterns

### Race Conditions

```typescript
// Flaky: Arbitrary timeout
test('loads data', async ({ page }) => {
  await page.goto('/data');
  await page.waitForTimeout(1000); // Arbitrary
  await expect(page.locator('.data')).toBeVisible();
});

// Stable: Wait for condition
test('loads data', async ({ page }) => {
  await page.goto('/data');
  await expect(page.locator('.data')).toBeVisible();
});
```

### Network Timing

```typescript
// Flaky: Fixed wait
await page.waitForTimeout(2000);

// Stable: Wait for response
await page.waitForResponse('**/api/data');
```

## Flaky Detection

```bash
# Run 10 times
npx playwright test --repeat-each=10
```

## Quarantine Pattern

```typescript
test.fixme(true, 'Flaky - Issue #123');

test.skip(process.env.CI, 'Flaky in CI - Issue #123');
```

## Common Causes

| Cause | Fix |
|-------|-----|
| Arbitrary timeouts | Use auto-waiting |
| Network timing | Wait for responses |
| Animation timing | Wait for networkidle |
| Shared state | Test isolation |