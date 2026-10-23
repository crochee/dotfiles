# Before / after — {{document}}

Source: `{{path}}` · Reviewer: {{name}} · Date: {{YYYY-MM-DD}}

One row per changed line or sentence. `Category` is the scan category that fired, or `judgement` for
a tell with no detector. `Reason` says what the sentence was doing before and what it does now.
`Precision kept?` is `yes`, `yes — <qualifier retained>`, or `no — <fact lost and why that is safe>`.

| Location | Before | After | Category | Reason | Precision kept? |
|---|---|---|---|---|---|
| `{{path}}:{{line}}` | {{verbatim original}} | {{verbatim rewrite}} | {{category}} | {{what changed and why}} | {{yes / yes — modal retained / no — …}} |

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
| `{{path}}:{{line}}` | {{category}} | {{quote, code, domain sense, or load-bearing contrast}} |

## Claims check

- Numeric tokens introduced: {{none / list with source}}
- Numeric tokens removed: {{none / list with justification}}
- Qualifiers changed: {{none / list}}
