#!/bin/bash
set -e

source $(dirname "$0")/server.sh

# Test port detection - any valid port number
PORT=$(get_available_port)
if [ "$PORT" -lt 1024 ] || [ "$PORT" -gt 65535 ]; then
    echo "FAIL: Port out of valid range: $PORT"
    exit 1
fi

# Test PID file creation
rm -f ~/.claude/md-review.pid
echo "1234" > ~/.claude/md-review.pid
if [ ! -f ~/.claude/md-review.pid ]; then
    echo "FAIL: PID file not created"
    exit 1
fi

# Test PID cleanup
remove_pid
if [ -f ~/.claude/md-review.pid ]; then
    echo "FAIL: PID file not removed"
    exit 1
fi

echo "PASS"
