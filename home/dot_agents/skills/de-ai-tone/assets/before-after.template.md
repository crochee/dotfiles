# Before / after — {{document}}

Source: `{{path}}` · Reviewer: {{name}} · Date: {{YYYY-MM-DD}} · Delivery language: {{en|zh}}

One row per changed line or sentence. `Category` is the pattern number and the scan category that
fired, written as `A1 not-just-x`, or `judgement` for a tell with no detector. `Reason` says what
the sentence was doing before and what it does now. `Precision kept?` is `yes`, `yes — <qualifier
retained>`, or `no — <fact lost and why that is safe>`. The `Before` and `After` columns always hold
the verbatim text.

| Location | Before | After | Category | Reason | Precision kept? |
|---|---|---|---|---|---|
| `{{path}}:{{line}}` | {{verbatim original}} | {{verbatim rewrite}} | `{{pattern id}} {{category}}` | {{what changed and why}} | {{yes / yes — modal retained / no — …}} |

## Scan log

```console
$ python3 scripts/scan.py {{path}}; echo exit=$?
{{score line}}
{{hit lines}}
exit={{0|1}}
```

Final:

```console
$ python3 scripts/scan.py {{path}}; echo exit=$?
{{score line}}
{{hit lines or none}}
exit={{0|1}}
```

## Surviving hits

| Location | Category | Why it stays |
|---|---|---|
| `{{path}}:{{line}}` | `{{pattern id}} {{category}}` | {{quote, code, domain sense, or load-bearing contrast}} |

## Claims check

- Numeric tokens introduced: {{none / list with source}}
- Numeric tokens removed: {{none / list with justification}}
- Qualifiers changed: {{none / list}}
