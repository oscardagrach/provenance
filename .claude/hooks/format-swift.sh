#!/bin/zsh
# PostToolUse hook: format any .swift file Claude just edited or wrote.
file=$(jq -r '.tool_input.file_path // empty')
[[ "$file" == *.swift && -f "$file" ]] || exit 0
swift format format --in-place "$file" 2>/dev/null || true
exit 0
