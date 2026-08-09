#!/bin/bash
# Builds Acknowledgement Force from source and installs it as a native macOS
# .app bundle. Safe to re-run — it replaces any previously installed copy.
#
# Usage:
#   ./install.sh                 Install to ~/Applications (no sudo needed)
#   ./install.sh --system        Install to /Applications (asks for sudo)
#   ./install.sh --prefix DIR    Install into a custom directory
#   ./install.sh --update        Re-build and replace the existing install in place
#                                (auto-detects the current install location)
#   ./install.sh --no-open       Don't launch the app after installing
#   ./install.sh --replace-others  Remove copies in other locations, no prompt
#   ./install.sh --keep-others   Leave copies in other locations in place
#   ./install.sh --package       Build a distributable .zip in ./dist (don't install)
#
# To ship a build that's pre-connected to your Supabase project (users only log
# in, no key entry), set both env vars. Bake + install locally:
#   FORCE_SUPABASE_URL=https://xxxx.supabase.co \
#   FORCE_SUPABASE_ANON_KEY=sb_publishable_... ./install.sh
# Bake + produce a shareable zip for people without Xcode:
#   FORCE_SUPABASE_URL=... FORCE_SUPABASE_ANON_KEY=... ./install.sh --package
#
# Before installing, the script checks the common install locations (and any
# it has installed to before) for an existing "Acknowledgement Force.app"
# outside the current target and offers to remove it, so you don't end up with
# stale duplicate copies on disk.
#
# After install the app lives at <prefix>/Acknowledgement Force.app. Turn on
# auto-launch from the app's onboarding/Settings, or run ./uninstall.sh to
# remove it completely.

set -euo pipefail

APP_NAME="Acknowledgement Force"
BUNDLE_ID="com.acknowledgementforce.app"
EXEC_NAME="Force"
RESOURCE_BUNDLE="Force_Force.bundle"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="$(tr -d '[:space:]' < "$REPO_DIR/VERSION" 2>/dev/null || echo "0.0.0")"
ICON_SRC="$REPO_DIR/landing/assets/raw/icon.png"

PREFIX="$HOME/Applications"
PREFIX_EXPLICIT=0
OPEN_AFTER=1
USE_SUDO=""
REPLACE_OTHERS=0
KEEP_OTHERS=0
PACKAGE=0
UPDATE=0
RECORD="$HOME/Library/Application Support/$EXEC_NAME/install-locations"

while [ $# -gt 0 ]; do
  case "$1" in
    --system) PREFIX="/Applications"; PREFIX_EXPLICIT=1; shift ;;
    --prefix) PREFIX="$2"; PREFIX_EXPLICIT=1; shift 2 ;;
    --update) UPDATE=1; shift ;;
    --no-open) OPEN_AFTER=0; shift ;;
    --package) PACKAGE=1; shift ;;
    --replace-others) REPLACE_OTHERS=1; shift ;;
    --keep-others) KEEP_OTHERS=1; shift ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

# --update: locate the current install and use its directory as PREFIX. This
# makes "upgrade in place" a one-line ergonomic. Falls back to the default
# prefix if we can't find an existing copy. Implies --keep-others (the existing
# install IS the one we're updating, others are unrelated and unchanged).
if [ "$UPDATE" -eq 1 ]; then
  FOUND=""
  CANDIDATES=("$HOME/Applications/$APP_NAME.app" "/Applications/$APP_NAME.app")
  if [ -f "$RECORD" ]; then
    while IFS= read -r line; do
      [ -n "$line" ] && CANDIDATES+=("$line/$APP_NAME.app")
    done < "$RECORD"
  fi
  for c in "${CANDIDATES[@]}"; do
    [ -d "$c" ] || continue
    FOUND="$(cd "$(dirname "$c")" && pwd -P)"
    break
  done
  if [ -n "$FOUND" ]; then
    if [ "$PREFIX_EXPLICIT" -eq 1 ] && [ "$PREFIX" != "$FOUND" ]; then
      echo "Note: --update found existing install at $FOUND but you also passed"
      echo "      --prefix/--system. Honoring the explicit flag and installing to $PREFIX."
    else
      PREFIX="$FOUND"
      echo "==> Update mode: replacing existing install at $PREFIX"
    fi
  else
    echo "==> Update mode: no existing install found, installing fresh to $PREFIX"
  fi
  # In update mode we don't want to prompt or churn other copies — just refresh.
  KEEP_OTHERS=1
fi

# Normalize to an absolute path so duplicate detection and the sudo check below
# compare apples to apples.
case "$PREFIX" in /*) ;; *) PREFIX="$PWD/$PREFIX" ;; esac

if [ "$(uname -s)" != "Darwin" ]; then
  echo "Error: Acknowledgement Force is a macOS app and only installs on macOS." >&2
  exit 1
fi
if ! command -v swift >/dev/null 2>&1; then
  echo "Error: 'swift' not found. Install Xcode or the Command Line Tools:" >&2
  echo "  xcode-select --install" >&2
  exit 1
fi

# Writing into /Applications needs root; everywhere under $HOME does not.
case "$PREFIX" in
  "$HOME"/*) USE_SUDO="" ;;
  *) [ -w "$PREFIX" ] || USE_SUDO="sudo" ;;
esac

# Optionally bake the Supabase connection into the binary so installed copies
# work with just a login (no manual key entry). Set both env vars to enable:
#   FORCE_SUPABASE_URL=https://xxxx.supabase.co \
#   FORCE_SUPABASE_ANON_KEY=eyJ... ./install.sh
# The anon key is the public key (protected by row-level security), safe to embed.
CONFIG_SRC="$REPO_DIR/Sources/ForceKit/Sync/SupabaseConfig.swift"
CONFIG_BACKUP=""
STAGE=""
cleanup() {
  [ -n "$CONFIG_BACKUP" ] && [ -f "$CONFIG_BACKUP" ] && mv -f "$CONFIG_BACKUP" "$CONFIG_SRC"
  [ -n "$STAGE" ] && rm -rf "$STAGE"
}
trap cleanup EXIT

if [ -n "${FORCE_SUPABASE_URL:-}" ] && [ -n "${FORCE_SUPABASE_ANON_KEY:-}" ]; then
  # Validate before splicing into Swift source: a malformed value would
  # otherwise corrupt the string literal (or worse, inject code).
  case "$FORCE_SUPABASE_URL" in
    https://*) ;;
    *) echo "Error: FORCE_SUPABASE_URL must start with https://" >&2; exit 1 ;;
  esac
  case "$FORCE_SUPABASE_URL$FORCE_SUPABASE_ANON_KEY" in
    *'|'*|*'"'*|*'\'*|*'&'*|*'$'*)
      echo "Error: FORCE_SUPABASE_URL / FORCE_SUPABASE_ANON_KEY must not contain | \" \\ & or \$" >&2
      exit 1 ;;
  esac
  echo "==> Baking Supabase connection into the build..."
  CONFIG_BACKUP="$(mktemp)"
  cp "$CONFIG_SRC" "$CONFIG_BACKUP"
  # '|' is a safe delimiter: validated above, URLs and anon keys never contain it.
  sed -i '' \
    -e "s|__FORCE_SUPABASE_URL__|${FORCE_SUPABASE_URL}|g" \
    -e "s|__FORCE_SUPABASE_ANON_KEY__|${FORCE_SUPABASE_ANON_KEY}|g" \
    "$CONFIG_SRC"
elif [ -n "${FORCE_SUPABASE_URL:-}" ] || [ -n "${FORCE_SUPABASE_ANON_KEY:-}" ]; then
  echo "Warning: set BOTH FORCE_SUPABASE_URL and FORCE_SUPABASE_ANON_KEY to bake" >&2
  echo "         credentials. Building without baked config." >&2
fi

echo "==> Building Acknowledgement Force $VERSION (release)..."
swift build -c release --package-path "$REPO_DIR"
BIN_DIR="$(swift build -c release --package-path "$REPO_DIR" --show-bin-path)"

BIN_PATH="$BIN_DIR/$EXEC_NAME"
BUNDLE_PATH="$BIN_DIR/$RESOURCE_BUNDLE"
[ -x "$BIN_PATH" ] || { echo "Error: built binary not found at $BIN_PATH" >&2; exit 1; }

echo "==> Assembling app bundle..."
STAGE="$(mktemp -d)"
APP="$STAGE/$APP_NAME.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN_PATH" "$APP/Contents/MacOS/$EXEC_NAME"
# Bundle.module resolves against Bundle.main.bundleURL (the .app root), so the
# resource bundle must live at Acknowledgement Force.app/Force_Force.bundle —
# NOT inside Contents/Resources.
[ -d "$BUNDLE_PATH" ] && cp -R "$BUNDLE_PATH" "$APP/"

# Build a multi-resolution .icns from the source PNG.
ICON_REF=""
if [ -f "$ICON_SRC" ] && command -v iconutil >/dev/null 2>&1; then
  ICONSET="$STAGE/AppIcon.iconset"
  mkdir -p "$ICONSET"
  # The source asset may be a JPEG with a .png name, so force real PNG output —
  # iconutil rejects anything that isn't a true PNG.
  for sz in 16 32 128 256 512; do
    sips -s format png -z "$sz" "$sz" "$ICON_SRC" --out "$ICONSET/icon_${sz}x${sz}.png" >/dev/null 2>&1 || true
    d=$((sz * 2))
    sips -s format png -z "$d" "$d" "$ICON_SRC" --out "$ICONSET/icon_${sz}x${sz}@2x.png" >/dev/null 2>&1 || true
  done
  if iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns" >/dev/null 2>&1; then
    ICON_REF="AppIcon"
  fi
fi

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
$( [ -n "$ICON_REF" ] && printf '    <key>CFBundleIconFile</key><string>%s</string>\n' "$ICON_REF" )
</dict>
</plist>
PLIST

# Ad-hoc sign so Gatekeeper trusts the locally built bundle and the launchd
# agent gets a stable executable path. Non-fatal if codesign is unavailable.
if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - --options runtime "$APP" >/dev/null 2>&1 || \
    echo "    (warning: ad-hoc code signing failed; app should still run)"
fi

# --package: emit a distributable zip instead of installing locally. The
# recipient unzips and drags the .app to /Applications — no Swift, no keys.
if [ "$PACKAGE" -eq 1 ]; then
  DIST="$REPO_DIR/dist"
  mkdir -p "$DIST"
  rm -rf "$DIST/$APP_NAME.app"
  cp -R "$APP" "$DIST/$APP_NAME.app"
  ZIP="$DIST/Acknowledgement-Force-$VERSION.zip"
  rm -f "$ZIP"
  # ditto preserves the bundle structure, symlinks, and code signature.
  ditto -c -k --keepParent "$DIST/$APP_NAME.app" "$ZIP"
  echo "==> Packaged: $ZIP"
  # Publish this hash next to the download so recipients can verify the zip
  # wasn't tampered with in transit (the build is not notarized).
  if command -v shasum >/dev/null 2>&1; then
    SHA="$(shasum -a 256 "$ZIP" | cut -d' ' -f1)"
    echo "    SHA-256: $SHA"
    echo "$SHA  $(basename "$ZIP")" > "$ZIP.sha256"
  fi
  if [ -z "${FORCE_SUPABASE_URL:-}" ] || [ -z "${FORCE_SUPABASE_ANON_KEY:-}" ]; then
    echo "    NOTE: built WITHOUT baked keys — set FORCE_SUPABASE_URL and"
    echo "    FORCE_SUPABASE_ANON_KEY to embed them so recipients only log in."
  fi
  echo "    This build is ad-hoc signed, not notarized: on first open the"
  echo "    recipient must right-click the app and choose Open the first time."
  echo "    For wider distribution, sign with a Developer ID and notarize."
  exit 0
fi

DEST="$PREFIX/$APP_NAME.app"

# Look for copies installed somewhere other than the current target so a user
# who once ran `--system` and later the default (or vice versa) doesn't leave a
# stale duplicate behind. Scan the common locations plus anywhere we've
# installed before.
SCAN_DIRS=("$HOME/Applications" "/Applications")
if [ -f "$RECORD" ]; then
  while IFS= read -r line; do [ -n "$line" ] && SCAN_DIRS+=("$line"); done < "$RECORD"
fi

abs_app() {  # echoes the physical path of "<dir>/<APP_NAME>.app" if <dir> exists
  local dir="$1"
  [ -d "$dir" ] || { echo "$dir/$APP_NAME.app"; return; }
  echo "$(cd "$dir" && pwd -P)/$APP_NAME.app"
}
DEST_PHYS="$(abs_app "$PREFIX")"

STRAYS=()
for dir in "${SCAN_DIRS[@]}"; do
  cand="$dir/$APP_NAME.app"
  [ -d "$cand" ] || continue
  cphys="$(abs_app "$dir")"
  [ "$cphys" = "$DEST_PHYS" ] && continue
  case " ${STRAYS[*]-} " in *" $cphys "*) continue ;; esac
  STRAYS+=("$cphys")
done

if [ "${#STRAYS[@]}" -gt 0 ]; then
  echo "==> Found Acknowledgement Force installed in other location(s):"
  for s in "${STRAYS[@]}"; do echo "      $s"; done
  remove=0
  if [ "$KEEP_OTHERS" -eq 1 ]; then
    echo "    Keeping them (--keep-others)."
  elif [ "$REPLACE_OTHERS" -eq 1 ]; then
    remove=1
  elif [ -t 0 ]; then
    printf "    Remove these before installing to %s? [y/N] " "$PREFIX"
    read -r ans
    case "$ans" in [yY]*) remove=1 ;; esac
  else
    echo "    Non-interactive run — leaving them. Re-run with --replace-others to remove."
  fi
  if [ "$remove" -eq 1 ]; then
    for s in "${STRAYS[@]}"; do
      if [ -w "$(dirname "$s")" ]; then rm -rf "$s"; else sudo rm -rf "$s"; fi
      echo "    removed $s"
    done
  fi
fi

echo "==> Installing to $PREFIX..."
$USE_SUDO mkdir -p "$PREFIX"
# If a previous copy is running, ask it to quit so we can replace it.
osascript -e "tell application \"$APP_NAME\" to quit" >/dev/null 2>&1 || true
$USE_SUDO rm -rf "$DEST"
$USE_SUDO cp -R "$APP" "$DEST"

# Remember where we installed so future runs can find duplicates here too.
mkdir -p "$(dirname "$RECORD")"
if ! { [ -f "$RECORD" ] && grep -qxF "$PREFIX" "$RECORD"; }; then
  echo "$PREFIX" >> "$RECORD"
fi

echo ""
echo "Installed: $DEST"
echo "Version:   $VERSION"
echo ""
echo "Launch it from Spotlight/Launchpad, or enable auto-launch in the app's"
echo "Settings. To remove everything later, run: ./uninstall.sh"

if [ "$OPEN_AFTER" -eq 1 ]; then
  echo ""
  echo "==> Opening Acknowledgement Force..."
  open "$DEST"
fi
