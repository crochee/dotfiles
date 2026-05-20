---
name: md-review
description: Use when design document needs user review - auto-opens browser to render MD content
trigger: context-based (LLM decides when to invoke)
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
5. User reviews in browser; files cleaned on session end

## File Specification (Priority)

1. `file:` parameter - explicit path passed to skill
2. Conversation context - LLM extracts from current discussion
3. Config patterns - glob matching in `config.json`

## Supported Platforms

| Platform | Browser Command |
|----------|-----------------|
| Linux/WSL | `xdg-open` |
| macOS    | `open`          |
| Windows  | `start`         |

## Usage

```bash
# Direct invocation (LLM handles this)
./scripts/server.sh start /path/to/design.md

# The skill is invoked by LLM when context indicates review needed
```

## Cleanup

Server and temp files are cleaned when Claude Code session ends.
PID tracked in `~/.claude/md-review.pid`