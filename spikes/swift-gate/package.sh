#!/usr/bin/env bash
# Packages the release binary into a launchable .app, the same way
# force-old/install.sh does it. No Xcode required — swift build only.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="Evening Gate"
EXEC_NAME="Gate"
BUNDLE_ID="dev.force.spike.gate"
VERSION="0.1.0"
OUT="$REPO_DIR/dist"

echo "==> Building $APP_NAME (release)..."
swift build -c release --package-path "$REPO_DIR"
BIN_DIR="$(swift build -c release --package-path "$REPO_DIR" --show-bin-path)"

BIN_PATH="$BIN_DIR/$EXEC_NAME"
[ -x "$BIN_PATH" ] || { echo "Error: built binary not found at $BIN_PATH" >&2; exit 1; }

# SwiftPM names the resource bundle <PackageName>_<TargetName>.bundle.
RESOURCE_BUNDLE="$BIN_DIR/SwiftGate_Gate.bundle"

echo "==> Assembling app bundle..."
APP="$OUT/$APP_NAME.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN_PATH" "$APP/Contents/MacOS/$EXEC_NAME"

# v1 drops the whole SwiftPM resource bundle at the .app root, because the
# generated Bundle.module accessor only looks there. codesign then refuses the
# bundle ("unsealed contents present in the bundle root"), so this spike flattens
# the two TTFs into Contents/Resources and resolves them by hand (Fonts.swift).
if [ -d "$RESOURCE_BUNDLE" ]; then
  find "$RESOURCE_BUNDLE" -name '*.ttf' -exec cp {} "$APP/Contents/Resources/" \;
else
  echo "Error: resource bundle not found at $RESOURCE_BUNDLE" >&2; exit 1
fi
ls "$APP/Contents/Resources/Fraunces.ttf" "$APP/Contents/Resources/Inter.ttf" >/dev/null

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>$EXEC_NAME</string>
    <key>CFBundleDisplayName</key><string>$APP_NAME</string>
    <key>CFBundleExecutable</key><string>$EXEC_NAME</string>
    <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundleVersion</key><string>$VERSION</string>
    <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSApplicationCategoryType</key><string>public.app-category.productivity</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSMicrophoneUsageDescription</key><string>The Evening Gate shows a live level meter while you speak your reckoning.</string>
</dict>
</plist>
PLIST

# Ad-hoc sign. TCC keys the microphone grant off the signature, so an unsigned
# bundle re-prompts on every rebuild.
if command -v codesign >/dev/null 2>&1; then
  if codesign --force --sign - --timestamp=none "$APP" 2>&1; then
    codesign --verify --strict "$APP" && echo "    signature verified (ad-hoc)"
  else
    echo "    (warning: ad-hoc code signing failed; app should still run)"
  fi
fi

echo "==> Built $APP"
du -sh "$APP"
