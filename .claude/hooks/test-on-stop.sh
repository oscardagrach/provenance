#!/bin/zsh
# Stop hook: if Swift sources changed, run the tests before Claude is allowed to finish.
# Exit 2 sends the failure output back to Claude so it keeps working.
input=$(cat)
[[ "$(jq -r '.stop_hook_active' <<<"$input")" == "true" ]] && exit 0  # avoid loops

cd "$CLAUDE_PROJECT_DIR" || exit 0
git status --porcelain -- '*.swift' 'Package.swift' | grep -q . || exit 0

if ! out=$(scripts/test.sh 2>&1); then
  echo "Tests failed — fix before finishing:" >&2
  tail -40 <<<"$out" >&2
  exit 2
fi
exit 0
