#!/bin/bash
# renderer.sh - Generate HTML from Markdown with GitHub styling

set -e

RENDER_DIR="$(dirname "$0")"
TEMP_DIR="${TMPDIR:-/tmp}/md-review-$$"
mkdir -p "$TEMP_DIR"

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

render_markdown() {
    local md_file="$1"
    local html_file="$2"

    if [ ! -f "$md_file" ]; then
        echo "Error: File not found: $md_file" >&2
        return 1
    fi

    local md_content=$(cat "$md_file")
    local escaped_content
    escaped_content=${md_content//\\/\\\\}
    escaped_content=${escaped_content//&/&amp;}
    escaped_content=${escaped_content//</&lt;}
    escaped_content=${escaped_content//>/&gt;}
    escaped_content=${escaped_content//\"/&quot;}

    cat > "$html_file" << HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MD Review</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/github-markdown-css/github-markdown.min.css">
    <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/highlight.js@11.9.0/lib/core.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/highlight.js@11.9.0/lib/languages/bash.min.js"></script>
    <style>
        .markdown-body { box-sizing: border-box; min-width: 200px; max-width: 980px; margin: 0 auto; padding: 45px; }
        @media (max-width: 767px) { .markdown-body { padding: 15px; } }
    </style>
</head>
<body>
    <div class="markdown-body" id="content"></div>
    <script>
        hljs.registerLanguage('bash', hljsLanguages.bash);
        document.getElementById('content').innerHTML = marked.parse(\`MD_CONTENT_PLACEHOLDER\`);
        hljs.highlightAll();
    </script>
</body>
</html>
HTMLEOF

    printf '%s' "$escaped_content" | python3 -c "
import sys
content = sys.stdin.read()
print(content, end='')
" > "${html_file}.tmp"
    python3 -c "
import re
with open('${html_file}', 'r') as f:
    html = f.read()
with open('${html_file}.tmp', 'r') as f:
    content = f.read()
html = html.replace('MD_CONTENT_PLACEHOLDER', content)
with open('${html_file}', 'w') as f:
    f.write(html)
"
    rm -f "${html_file}.tmp"
}