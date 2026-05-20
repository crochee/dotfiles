# Debug Methodology

## Log Tracing

Use case: Command failures, runtime errors

Steps:
1. `grep -r "ERROR" .` to locate error
2. Trace call stack upward
3. Check error context (variable values, config, environment)

Example:
```bash
# Locate error
grep -rn "ERROR" logs/
# Check context
cat logs/app.log | grep -A5 "ERROR"
```

## Variable Isolation

Use case: Complex problem elimination

Steps:
1. Minimize reproduction conditions
2. Add variables one by one
3. Locate trigger point

## 5-Why Interrogation

Use case: Deep root cause excavation

Example:
- Why did connection fail? → Service not running
- Why not running? → Port occupied
- Why port occupied? → Previous process not cleaned up
- Why not cleaned up? → Missing cleanup script
- Why missing? → Not in deployment process

Root cause: Need to add post-deployment cleanup step

## Version Compatibility Check

Use case: Dependency issues, environment issues

Checklist:
- [ ] Language runtime version
- [ ] Dependency package version
- [ ] System library version
- [ ] API version

## Config Load Verification

Use case: Config-related issues

Steps:
1. Print config content
2. Compare against expected values
3. Check load path