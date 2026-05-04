#!/bin/bash
set -euo pipefail

# Build PasteRecord.app from the SwiftPM executable.
# Usage:
#   ./scripts/build-app.sh                # Release build
#   CONFIG=debug ./scripts/build-app.sh   # Debug build

cd "$(dirname "$0")/.."

# KeyboardShortcuts uses #Preview macros which require Xcode's bundled
# PreviewsMacros plugin. If `xcode-select -p` points at CommandLineTools,
# fall back to /Applications/Xcode.app for this build.
if [ -z "${DEVELOPER_DIR:-}" ]; then
    if ! xcrun --find swift-frontend 2>/dev/null | grep -q Xcode.app; then
        if [ -d "/Applications/Xcode.app/Contents/Developer" ]; then
            export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
            echo "Using DEVELOPER_DIR=$DEVELOPER_DIR (Xcode required for SwiftUI macros)"
        fi
    fi
fi

CONFIG="${CONFIG:-release}"
APP_NAME="PasteRecord"
DIST_DIR="dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"

echo "Building $APP_NAME ($CONFIG)…"
swift build -c "$CONFIG" --arch arm64 --arch x86_64

BIN_PATH="$(swift build -c "$CONFIG" --arch arm64 --arch x86_64 --show-bin-path)/$APP_NAME"
if [ ! -f "$BIN_PATH" ]; then
    echo "Could not find built binary at $BIN_PATH" >&2
    exit 1
fi

echo "Assembling $APP_BUNDLE…"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"
cp "$BIN_PATH" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# Ad-hoc sign so the app can request Accessibility permission with a stable identity.
codesign --force --deep --sign - "$APP_BUNDLE"

echo "Done: $APP_BUNDLE"
