# Artifact Management Guide

**Load this reference when:** managing E2E test artifacts.

## Artifact Types

| Type | Retention | Use Case |
|------|------------|-----------|
| Screenshots | Debugging | On failure |
| Videos | Debugging | Flaky tests |
| Traces | Debugging | Timing issues |
| Reports | CI storage | Post-build analysis |

## Configuration

```typescript
// playwright.config.ts
export default defineConfig({
  reporter: [['html']],
  use: {
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    trace: 'on-first-retry',
  },
});
```

## Upload Strategy

```yaml
# CI configuration
- name: Upload artifacts
  uses: actions/upload-artifact@v4
  if: always()
  with:
    name: playwright-report
    path: playwright-report/
    retention-days: 30
```