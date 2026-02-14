#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_BUNDLE="$PROJECT_DIR/build/KeySound.app"
DMG_DIR="$PROJECT_DIR/build/dmg"
DMG_PATH="$PROJECT_DIR/build/KeySound.dmg"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "Error: $APP_BUNDLE not found. Run make ship first."
    exit 1
fi

rm -rf "$DMG_DIR" "$DMG_PATH"
mkdir -p "$DMG_DIR"

cp -R "$APP_BUNDLE" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"

hdiutil create -volname "KeySound" -srcfolder "$DMG_DIR" \
    -ov -format UDZO "$DMG_PATH"

rm -rf "$DMG_DIR"
echo "Created: $DMG_PATH"
