#!/usr/bin/env bash
# PostToolUse hook: extract files from apply_patch and delegate formatting to the
# shared Claude hook by synthesizing its tool-input payload.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
input="$(cat)"
command_str="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
[ -n "$command_str" ] || exit 0

status=0
while IFS= read -r file; do
  case "$file" in
    "$ROOT"/*) file="${file#"$ROOT"/}" ;;
    /*) continue ;;
  esac

  [ -f "$ROOT/$file" ] || continue
  jq -n --arg file "$file" '{tool_input:{file_path:$file}}' \
    | "$ROOT/.claude/hooks/format.sh" || status=$?
done < <(
  printf '%s\n' "$command_str" \
    | grep -oE '^\*\*\* (Update|Add|Move) File: .+$' \
    | sed -E 's/^\*\*\* (Update|Add|Move) File: //; s/^.* -> //'
)

exit "$status"
