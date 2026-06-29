#!/bin/bash
set -euo pipefail

# Simple script to launch ResearchBar from this repo (kills stale ResearchBar instances first)
# Usage: ./Scripts/launch.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_PATH="$PROJECT_ROOT/ResearchBar.app"
APP_PROCESS_PATTERN="$PROJECT_ROOT/ResearchBar.app/Contents/MacOS/ResearchBar"

echo "==> Killing existing ResearchBar instances"
pkill -f "$APP_PROCESS_PATTERN" || true
pkill -x "ResearchBar" || true
sleep 0.5

if [[ ! -d "$APP_PATH" ]]; then
    echo "ERROR: ResearchBar.app not found at $APP_PATH"
    echo "Run ./Scripts/package_app.sh first to build the app"
    exit 1
fi

echo "==> Launching ResearchBar from $APP_PATH"
open -n "$APP_PATH"

# Wait a moment and check if it's running
sleep 1
if pgrep -f "$APP_PROCESS_PATTERN" > /dev/null; then
    echo "OK: ResearchBar is running."
else
    echo "ERROR: App exited immediately. Check crash logs in Console.app (User Reports)."
    exit 1
fi
