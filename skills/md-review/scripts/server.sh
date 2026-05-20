#!/bin/bash
# server.sh - HTTP server lifecycle management for md-review

set -e

PID_FILE="${HOME}/.claude/md-review.pid"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

get_available_port() {
    python3 - << 'PYEOF'
import socket
s = socket.socket()
s.bind(('', 0))
port = s.getsockname()[1]
s.close()
print(port)
PYEOF
}

get_browser_cmd() {
    case "$(uname -s)" in
        Linux*) echo "xdg-open" ;;
        Darwin*) echo "open" ;;
        MINGW*|MSYS*|CYGWIN*) echo "start" ;;
        *) echo "xdg-open" ;;
    esac
}

start_server() {
    local md_file="$1"
    local port=$(get_available_port)

    source "${SCRIPT_DIR}/renderer.sh"

    local temp_html=$(mktemp --suffix=.html)
    render_markdown "$md_file" "$temp_html"

    cd "$(dirname "$temp_html")"
    python3 -m http.server "$port" &
    local pid=$!

    echo "$pid" > "$PID_FILE"
    echo "$port:$temp_html:$pid" > "${HOME}/.claude/md-review.info"

    sleep 1

    if [ -z "$CI" ]; then
        local browser_cmd=$(get_browser_cmd)
        "$browser_cmd" "http://localhost:$port/$(basename "$temp_html")"
    fi

    echo "Server running on port $port, PID $pid"
    echo "Temp file: $temp_html"
}

stop_server() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null || true
        fi
        remove_pid
    fi

    if [ -f "${HOME}/.claude/md-review.info" ]; then
        local info=$(cat "${HOME}/.claude/md-review.info")
        local temp_html=$(echo "$info" | cut -d: -f2)
        rm -f "$temp_html" 2>/dev/null || true
        rm -f "${HOME}/.claude/md-review.info"
    fi
}

remove_pid() {
    rm -f "$PID_FILE"
}

cleanup_on_exit() {
    stop_server
}

trap cleanup_on_exit EXIT INT TERM

"$@"