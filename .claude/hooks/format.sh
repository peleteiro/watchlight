#!/usr/bin/env bash
# PostToolUse hook: format only the edited firmware file. Whole-project checks
# remain in `mise run check`; lefthook still guards staged source files.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

file="$(jq -r '.tool_input.file_path // empty')"
[ -n "$file" ] || exit 0

case "$file" in
  "$ROOT"/*) file="${file#"$ROOT"/}" ;;
  /*) exit 0 ;;
esac

[ -f "$file" ] || exit 0

case "$file" in
  src/*.c | src/*.cc | src/*.cpp | src/*.h | src/*.hpp)
    mise exec -- clang-format -i "$file" >/dev/null 2>&1 || true
    ;;
esac

exit 0
