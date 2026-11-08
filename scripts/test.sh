#!/bin/zsh
# Runs the test suite. Works with full Xcode or Command Line Tools only
# (CLT ships Swift Testing but doesn't put it on the default search path).
set -euo pipefail
cd "${0:A:h}/.."

flags=()
if [[ "$(xcode-select -p)" == *CommandLineTools* ]]; then
  F=/Library/Developer/CommandLineTools/Library/Developer/Frameworks
  flags=(-Xswiftc -F$F -Xswiftc -Xfrontend -Xswiftc -disable-cross-import-overlays -Xlinker -F$F -Xlinker -rpath -Xlinker $F)
fi
exec swift test "${flags[@]}" "$@"
