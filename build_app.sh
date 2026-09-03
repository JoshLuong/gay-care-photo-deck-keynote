#!/usr/bin/env bash
# Compiles PhotoDeckHelper.applescript into a .app bundle and configures
# the custom URL scheme (photodeck://) in its Info.plist.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="PhotoDeck"
APP_OUT="$SCRIPT_DIR/dist/${APP_NAME}.app"
APPLET_SCRIPT="$SCRIPT_DIR/PhotoDeckHelper.applescript"
BUILD_SCRIPT="$SCRIPT_DIR/build_photo_deck.applescript"

mkdir -p "$SCRIPT_DIR/dist"

echo "Compiling applet..."
osacompile -o "$APP_OUT" "$APPLET_SCRIPT"

echo "Copying build script into Resources..."
cp "$BUILD_SCRIPT" "$APP_OUT/Contents/Resources/build_photo_deck.applescript"

echo "Patching Info.plist..."
INFO_PLIST="$APP_OUT/Contents/Info.plist"

# Set bundle identifier
/usr/libexec/PlistBuddy -c "Delete :CFBundleIdentifier" "$INFO_PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string com.joshluong.photodeck" "$INFO_PLIST"

# Register URL scheme
/usr/libexec/PlistBuddy -c "Delete :CFBundleURLTypes" "$INFO_PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes array" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0 dict" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLName string PhotoDeck Helper" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes array" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string photodeck" "$INFO_PLIST"

echo "Zipping..."
cd "$SCRIPT_DIR/dist"
zip -r "${APP_NAME}.app.zip" "${APP_NAME}.app"

echo "Done: $SCRIPT_DIR/dist/${APP_NAME}.app.zip"
