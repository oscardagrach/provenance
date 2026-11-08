#!/bin/zsh
# Builds ProvenanceApp and wraps it in build/Provenance.app (ad-hoc signed).
# Usage: scripts/build-app.sh [debug|release]   then: open build/Provenance.app
set -euo pipefail
cd "${0:A:h}/.."
config=${1:-debug}

swift build -c "$config" --product ProvenanceApp
bin="$(swift build -c "$config" --show-bin-path)/ProvenanceApp"

app=build/Provenance.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin" "$app/Contents/MacOS/ProvenanceApp"
cp Resources/Info.plist "$app/Contents/Info.plist"
codesign --force --sign - "$app" >/dev/null
echo "Built $app"
