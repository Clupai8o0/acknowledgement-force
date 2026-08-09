#!/bin/bash
# Completely removes Acknowledgement Force:
#   - disables and removes the launchd auto-launch agent
#   - quits/kills any running instance
#   - deletes the installed .app bundle
#   - optionally deletes saved data (history, settings)
#
# Usage:
#   ./uninstall.sh            Remove the app and auto-launch agent (keep data)
#   ./uninstall.sh --purge    Also delete saved history and settings
#   ./uninstall.sh --system   Also look for the app in /Applications

set -u

APP_NAME="Acknowledgement Force"
EXEC_NAME="Force"
BUNDLE_ID="com.acknowledgementforce.app"
LABEL="com.acknowledgementforce.agent"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
SUPPORT_DIR="$HOME/Library/Application Support/$EXEC_NAME"
UID_NUM="$(id -u)"

PURGE=0
SEARCH_DIRS=("$HOME/Applications")

while [ $# -gt 0 ]; do
  case "$1" in
    --purge) PURGE=1; shift ;;
    --system) SEARCH_DIRS+=("/Applications"); shift ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

echo "Disabling auto-launch..."
launchctl bootout "gui/$UID_NUM/$LABEL" 2>/dev/null && echo "  unloaded launch agent" || echo "  launch agent not loaded"
[ -f "$PLIST" ] && rm -f "$PLIST" && echo "  removed $PLIST"

echo "Quitting any running instance..."
osascript -e "tell application \"$APP_NAME\" to quit" >/dev/null 2>&1 || true
sleep 1
PIDS="$(pgrep -f "/$EXEC_NAME\$" || true)"
if [ -n "$PIDS" ]; then
  # shellcheck disable=SC2086
  kill $PIDS 2>/dev/null
  sleep 1
  STILL="$(pgrep -f "/$EXEC_NAME\$" || true)"
  # shellcheck disable=SC2086
  [ -n "$STILL" ] && kill -9 $STILL 2>/dev/null && echo "  force-killed $STILL" || echo "  stopped"
else
  echo "  nothing running"
fi

echo "Removing app bundle..."
removed=0
for dir in "${SEARCH_DIRS[@]}"; do
  APP="$dir/$APP_NAME.app"
  if [ -d "$APP" ]; then
    if [ -w "$dir" ]; then rm -rf "$APP"; else sudo rm -rf "$APP"; fi
    echo "  removed $APP"
    removed=1
  fi
done
[ "$removed" -eq 0 ] && echo "  no installed app found"

if [ "$PURGE" -eq 1 ]; then
  echo "Purging saved data..."
  [ -d "$SUPPORT_DIR" ] && rm -rf "$SUPPORT_DIR" && echo "  removed $SUPPORT_DIR" || echo "  no saved data"
  defaults delete "$BUNDLE_ID" >/dev/null 2>&1 && echo "  cleared preferences ($BUNDLE_ID)" || true
  # The Supabase session lives in the Keychain (not in preferences).
  security delete-generic-password -s "com.acknowledgementforce.sync" -a "supabase-session" \
    >/dev/null 2>&1 && echo "  removed Keychain session" || true
else
  echo "Saved data left in place ($SUPPORT_DIR). Use --purge to delete it."
fi

echo "Done. Acknowledgement Force has been uninstalled."
