#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_NAME="KeySound"
APP_BUNDLE="$PROJECT_DIR/build/${APP_NAME}.app"

echo "Building ${APP_NAME}..."
cd "$PROJECT_DIR"
swift build -c release 2>&1

# Get the built binary path
BINARY=$(swift build -c release --show-bin-path)/${APP_NAME}

if [ ! -f "$BINARY" ]; then
    echo "Error: Binary not found at $BINARY"
    exit 1
fi

echo "Assembling ${APP_NAME}.app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp "$BINARY" "$APP_BUNDLE/Contents/MacOS/${APP_NAME}"

# Copy Info.plist
cp "$PROJECT_DIR/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# Copy resources
if [ -d "$PROJECT_DIR/Resources" ]; then
    cp "$PROJECT_DIR/Resources/"*.wav "$APP_BUNDLE/Contents/Resources/" 2>/dev/null || true
fi

# Codesign so macOS Accessibility permission persists across rebuilds
codesign --force --sign - --identifier com.keysound.app "$APP_BUNDLE"

echo "Built: $APP_BUNDLE"
