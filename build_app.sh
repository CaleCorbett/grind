#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "=== Building Grind Native macOS App ==="

APP_NAME="Grind"
BUILD_DIR="$DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Find all Swift source files
SWIFT_SOURCES=$(find "$DIR/Sources" -name "*.swift")

echo "Compiling Swift sources..."
export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"

xcrun swiftc \
  -target arm64-apple-macos14.0 \
  -parse-as-library \
  -O \
  -module-name Grind \
  $SWIFT_SOURCES \
  -o "$APP_BUNDLE/Contents/MacOS/Grind"

echo "Copying Info.plist..."
cp "$DIR/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

echo "Copying Resources..."
cp "$DIR/Resources"/*.wav "$APP_BUNDLE/Contents/Resources/"
cp "$DIR/Resources"/*.otf "$APP_BUNDLE/Contents/Resources/"
cp "$DIR/Resources"/*.icns "$APP_BUNDLE/Contents/Resources/"

echo "Signing application bundle with Hardened Runtime and App Sandbox..."
codesign --force --deep --options runtime --entitlements "$DIR/Entitlements.plist" --sign - "$APP_BUNDLE"

echo "=== Build Complete! ==="
echo "App bundle: $APP_BUNDLE"
