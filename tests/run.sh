#!/usr/bin/env bash
# Runs every tests/*_test.lua with stubbed WoW globals and syntax-checks the
# addon. Uses Lua 5.1 (the game's Lua). Override with LUA=/path/to/lua.
set -euo pipefail
cd "$(dirname "$0")/.."
LUA=${LUA:-lua5.1}
LUAC=${LUAC:-luac5.1}
fail=0

echo "== syntax"
for f in NicknameForever/*.lua NicknameForever/Libs/*.lua CustomNames/*.lua; do
  "$LUAC" -p "$f" || { echo "SYNTAX ERROR: $f"; fail=1; }
done

for t in tests/*_test.lua; do
  echo "== $t"
  if ! out=$(NF_ROOT=./ "$LUA" "$t" 2>&1); then fail=1; fi
  echo "$out" | grep -v '^  chat>' || true
  if echo "$out" | grep -q '^FAIL'; then fail=1; fi
done

if [ "$fail" -ne 0 ]; then echo "TESTS FAILED"; exit 1; fi
echo "all tests passed"
