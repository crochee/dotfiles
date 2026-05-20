#!/bin/bash
# Test renderer generates valid HTML

set -e

source "$(dirname "$0")/renderer.sh"

TEMP_FILE=$(mktemp)
echo "# Test

Hello world" > "$TEMP_FILE.md"

render_markdown "$TEMP_FILE.md" "$TEMP_FILE.html"

# Verify HTML output
grep -q "marked.min.js" "$TEMP_FILE.html"
grep -q "github-markdown-css" "$TEMP_FILE.html"
grep -q "Test" "$TEMP_FILE.html"

rm -f "$TEMP_FILE.md" "$TEMP_FILE.html"
echo "PASS"