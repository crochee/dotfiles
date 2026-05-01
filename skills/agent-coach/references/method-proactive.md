# Proactiveness Methodology

## Upstream/Downstream Check

Use case: After bug fix

Principle: Fix one point, check the entire area

Check:
- Upstream: Data sources, config sources, callers
- Downstream: Storage, output, dependents
- Same level: Shared modules, common libraries

## Edge Case Verification

Use case: After feature implementation

Checklist:
- [ ] Empty values
- [ ] Boundary values
- [ ] Max/min values
- [ ] Special characters
- [ ] Concurrency scenarios

## Similar Problem Scan

Use case: Fixing pattern-based issues

Command:
```bash
# Search for similar patterns
grep -rn "similar_pattern" --include="*.py"
```

## Dependency/Config Review

Use case: Troubleshooting issues

Review points:
- [ ] Dependency conflicts
- [ ] Config inconsistencies
- [ ] Environment differences
- [ ] Permission issues