#!/bin/bash
# Builds Vole and wraps it in Vole.app so macOS privacy settings can list it.
set -euo pipefail

cd "$(dirname "$0")/.."

swift build -c release

BIN_DIR="$(swift build -c release --show-bin-path)"
APP="Vole.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN_DIR/Vole" "$APP/Contents/MacOS/Vole"
cp Resources/Info.plist "$APP/Contents/Info.plist"

# Ad-hoc signature. No entitlements are needed because the app is not sandboxed.
codesign --force --sign - "$APP"

echo "Built $(pwd)/$APP"
