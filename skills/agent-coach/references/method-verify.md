# Verification Methodology

## Test Suite Execution

Use case: After code changes

```bash
# Run related tests
pytest tests/path/to/test.py -v

# Run all tests
pytest -v
```

## Build Verification

Use case: Compilation projects

```bash
# Build
make build
# or
npm run build
```

## Endpoint curl Testing

Use case: After API changes

```bash
# Health check
curl -s http://localhost:3000/health

# Business endpoint
curl -X POST http://localhost:3000/api/endpoint \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

## Output Diff Comparison

Use case: After config changes

```bash
# Compare changes
git diff
# or
diff old.config new.config
```

## Verification Loop Principles

1. **Output counts as completion** - Paste actual command output
2. **Compare counts as verification** - Expected vs actual
3. **Complete counts as pass** - Main flow + edge cases