#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# Create test markdown
TEST_MD=$(mktemp --suffix=.md)
cat > "$TEST_MD" << 'EOF'
# Architecture Design

## Overview
This is a test design document.

## Components
- Component A
- Component B

```bash
echo "Hello"
```
EOF

# Start server with test file
bash "${SCRIPT_DIR}/server.sh" start_server "$TEST_MD"

sleep 2

# Check server is running
PID=$(cat ~/.claude/md-review.pid)
if ! kill -0 "$PID" 2>/dev/null; then
    echo "FAIL: Server not running"
    exit 1
fi

# Check temp HTML exists
INFO=$(cat "${HOME}/.claude/md-review.info")
TEMP_HTML=$(echo "$INFO" | cut -d: -f2)
if [ ! -f "$TEMP_HTML" ]; then
    echo "FAIL: Temp HTML not created"
    exit 1
fi

# Check HTML content
if ! grep -q "Architecture Design" "$TEMP_HTML"; then
    echo "FAIL: Markdown not rendered"
    exit 1
fi

# Clean up via trap (exit)
echo "PASS"