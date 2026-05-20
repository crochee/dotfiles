---
name: agent-coach
description: "Progressive coaching skill for agent behavior enhancement. Trigger: first failure / unverified completion claims / retry on same problem / says 'can't solve'. Functions: persistence enhancement (prevent early give-up), proactiveness enhancement (proactively check related issues), methodology guidance (debugging/search/review methods). Style: professional, concise, coaching. Manual commands: /coach activate enhanced mode, /coach:light L1 only, /coach:deep L3 directly, /coach:off pause."
---

# Agent Coach

## Mission

Make AI more persistent, more proactive, and more methodical.

## Three-Tier Intervention

### L1 Prompt

**Triggers:**
- First failure
- Unverified claim of completion
- Asking user questions they could search for

**Output format:**
```
[coach] Check if similar modules have the same issue.
[coach] Run verification commands before claiming done.
[coach] Have you tried searching for similar solutions?
```

### L2 Methodology

**Triggers:**
- Same problem retried 2+ times
- Using assumptions instead of verification
- Only fixing surface issues

**Output format:**
```
[Methodology · Debug]
→ grep ERROR to locate failure point
→ Check dependency version compatibility
→ Verify config loaded correctly
```

### L3 Diagnosis

**Triggers:**
- 3+ failures
- Says "can't solve"
- Complex multi-module problems

**Output format:**
```
┌──────────────────────────────────────────────────────┐
│  Diagnosis Report                                     │
├──────────────────────────────────────────────────────┤
│  Problem Location                                     │
│  ├─ Surface symptom: ...                             │
│  ├─ Root cause: ...                                  │
│  └─ Impact scope: ...                                │
├──────────────────────────────────────────────────────┤
│  Verified Attempts                                    │
│  1. ...                                              │
│  2. ...                                              │
├──────────────────────────────────────────────────────┤
│  Hypotheses & Verification Plan                      │
│  ├─ Hypothesis A: ... → verification: ...            │
│  └─ Hypothesis B: ... → verification: ...            │
├──────────────────────────────────────────────────────┤
│  Next Steps                                          │
│  → ...                                               │
│  → ...                                               │
└──────────────────────────────────────────────────────┘
```

## Methodology Router

| Task Type | Recommended Method |
|-----------|-------------------|
| Debug | Log trace → Isolate variables → Version check |
| New Feature | Search reference → Minimal viable → Gradual expand |
| Code Review | Edge cases → Upstream/downstream impact → Security check |
| Config Issue | Config load verification → Format check → Env comparison |

## Owner Checklist

After each task completes, check:
1. What was the root cause? (not how to fix, but why it happened)
2. Who else might be affected? (upstream, downstream, similar modules)
3. How to prevent next time? (add check or test)
4. Where's the verification result? (output evidence)

## Manual Commands

| Command | Function |
|---------|----------|
| `/coach` | Activate enhanced mode |
| `/coach:light` | L1 prompts only |
| `/coach:deep` | Direct to L3 diagnosis |
| `/coach:off` | Pause intervention |

## Reference Files

Detailed methodology:
- [references/method-debug.md](references/method-debug.md) - Debug methodology
- [references/method-proactive.md](references/method-proactive.md) - Proactiveness methodology
- [references/method-verify.md](references/method-verify.md) - Verification methodology