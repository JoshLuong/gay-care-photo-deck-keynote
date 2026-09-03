#!/usr/bin/env bash
# Compiles PhotoDeckHelper.applescript into a .app bundle, bundles the
# standalone HTTP server binary, and zips for distribution.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="PhotoDeck"
APP_OUT="$SCRIPT_DIR/dist/${APP_NAME}.app"
APPLET_SCRIPT="$SCRIPT_DIR/PhotoDeckHelper.applescript"
BUILD_SCRIPT="$SCRIPT_DIR/build_photo_deck.applescript"
SERVER_BIN="$SCRIPT_DIR/dist/photodeck-server"

mkdir -p "$SCRIPT_DIR/dist"

if [ ! -f "$SERVER_BIN" ]; then
  echo "Building server binary..."
  pkg "$SCRIPT_DIR/server.js" --targets node18-macos-arm64 --output "$SERVER_BIN"
fi

echo "Compiling applet..."
osacompile -o "$APP_OUT" "$APPLET_SCRIPT"

echo "Copying resources into bundle..."
cp "$BUILD_SCRIPT" "$APP_OUT/Contents/Resources/build_photo_deck.applescript"
cp "$SERVER_BIN" "$APP_OUT/Contents/Resources/photodeck-server"
chmod +x "$APP_OUT/Contents/Resources/photodeck-server"

echo "Patching Info.plist..."
INFO_PLIST="$APP_OUT/Contents/Info.plist"

/usr/libexec/PlistBuddy -c "Delete :CFBundleIdentifier" "$INFO_PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string com.joshluong.photodeck" "$INFO_PLIST"

# Remove URL scheme — no longer needed
/usr/libexec/PlistBuddy -c "Delete :CFBundleURLTypes" "$INFO_PLIST" 2>/dev/null || true

echo "Zipping..."
cd "$SCRIPT_DIR/dist"
rm -f "${APP_NAME}.app.zip"
zip -r "${APP_NAME}.app.zip" "${APP_NAME}.app"

echo "Done: $SCRIPT_DIR/dist/${APP_NAME}.app.zip"
