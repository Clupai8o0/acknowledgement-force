#!/bin/bash
# Stops Force and prevents it from relaunching.
#   - Removes the launchd auto-launch agent (so it won't come back on login/schedule)
#   - Kills any running Force process
#
# Usage: ./stop.sh

set -u

LABEL="com.acknowledgementforce.agent"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
UID_NUM="$(id -u)"

echo "Disabling auto-launch..."
launchctl bootout "gui/$UID_NUM/$LABEL" 2>/dev/null && echo "  unloaded launch agent" || echo "  launch agent not loaded"
if [ -f "$PLIST" ]; then
  rm -f "$PLIST" && echo "  removed $PLIST"
fi

echo "Stopping running instances..."
PIDS="$(pgrep -f '/Force$' || true)"
if [ -n "$PIDS" ]; then
  # shellcheck disable=SC2086
  kill $PIDS 2>/dev/null
  sleep 1
  STILL="$(pgrep -f '/Force$' || true)"
  if [ -n "$STILL" ]; then
    # shellcheck disable=SC2086
    kill -9 $STILL 2>/dev/null && echo "  force-killed $STILL"
  else
    echo "  stopped $PIDS"
  fi
else
  echo "  nothing running"
fi

echo "Done. Force is stopped and will not auto-launch."
