#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_NAME="KeySound"
APP_BUNDLE="$PROJECT_DIR/build/${APP_NAME}.app"

SWIFT_FLAGS=""
if [ "${ENABLE_DEBUG_FEATURES:-1}" = "1" ]; then
    SWIFT_FLAGS="-Xswiftc -DDEBUG_FEATURES"
fi

echo "Building ${APP_NAME}..."
cd "$PROJECT_DIR"
swift build -c release $SWIFT_FLAGS 2>&1

# Get the built binary path
BINARY=$(swift build -c release $SWIFT_FLAGS --show-bin-path)/${APP_NAME}

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
if [ -d "$PROJECT_DIR/Resources/sounds" ]; then
    cp -R "$PROJECT_DIR/Resources/sounds" "$APP_BUNDLE/Contents/Resources/sounds"
fi

# Codesign so macOS Accessibility permission persists across rebuilds.
# Use a real signing identity if available (stable CDHash across rebuilds),
# otherwise fall back to ad-hoc (requires re-granting permission each build).
IDENTITY=$(security find-identity -v -p codesigning 2>/dev/null | grep -o '"[^"]*"' | head -1 | tr -d '"')
if [ -n "$IDENTITY" ]; then
    echo "Signing with: $IDENTITY"
    codesign --force --sign "$IDENTITY" --identifier com.keysound.app "$APP_BUNDLE"
else
    echo "Warning: No signing identity found, using ad-hoc (accessibility permission won't persist across rebuilds)"
    codesign --force --sign - --identifier com.keysound.app "$APP_BUNDLE"
fi

echo "Built: $APP_BUNDLE"
