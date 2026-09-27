---
name: md-review
description: Use when a design document needs user review - starts a local server and auto-opens the browser to render the Markdown
metadata:
  author: skills-team
---

# MD Review

Automatically opens a browser to render Markdown design documents for review.

## When to Use

- User needs to review a design document
- LLM detects discussion about a design spec
- File path extracted from conversation context

## How It Works

1. LLM calls skill with file path (via parameter, context, or config pattern)
2. Skill generates temporary HTML with GitHub-style rendering
3. Python HTTP server starts on random available port
4. Platform-appropriate command opens browser
5. User reviews in browser; cleanup via `stop_server`

## File Specification (Priority)

1. `file:` parameter - explicit path passed to skill
2. Conversation context - LLM extracts from current discussion

## Supported Platforms

| Platform | Browser Command |
|----------|-----------------|
| Linux/WSL | `xdg-open` |
| macOS    | `open`          |
| Windows  | `start`         |

## Usage

```bash
# Direct invocation
bash scripts/server.sh start_server /path/to/design.md
```

Lifecycle: `start_server` keeps the HTTP server running after the script exits
(review happens in the browser). Clean up explicitly with
`bash scripts/server.sh stop_server` (also fires on INT/TERM). PID tracked in
`~/.claude/md-review.pid`.