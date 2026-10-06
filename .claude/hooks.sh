#!/bin/sh
# Run one koch hook verb with pinned compiler on PATH; build koch first where its source moved.
#   not Nim because hook command is what puts compiler on PATH before any Nim can run, and
#   git runs its hooks as executable scripts (`.githooks/`), which call back into this file.
#   Pin is read from audit's nimble file, so it is stated once (CURATOR.md duty 8).
#   Toolchain lands in cache knoller resolves each pin from (`compilers.nim` there), so hook,
#     koch and knoller share one toolchain for each pin.
#   Tarball is linux_x64; other platform with `nim` already on PATH falls through, and one
#   without it fails loudly at build rather than silently at every hook.
#   `binaries/` is ignored by git, so built koch never reaches audit or repository.
#   Binary keeps key beside it: object ids of koch, its flags, nimble file and source of audit
#   and of knoller, which audit imports by path, at HEAD. Commit, merge or switch of branch that
#   moves one builds again before hook runs, so no hook runs checker older than checkout holds.
#   Key reads HEAD and never working tree, so edit in progress builds nothing until committed.
#   Trap: `rev-parse` prints first path HEAD lacks back as given, then stops. Knoller comes
#     last, its source before its nimble file, so older branch keeps stable key and no path
#     that exists is dropped from it.
#   Build writes beside binary, then renames, so no hook runs half-written file. Directory lock
#   lets one build run while concurrent hook runs binary it finds; lock older than ten minutes
#   is one that killed build left.
#   Cost: one `git rev-parse` per hook, and about five seconds of build where key moved.
#   Cost: binary built from tree with uncommitted edits keeps them under key of HEAD.
#   Cost: checker bug committed in this checkout reaches next hook; checker work in worktree
#     leaves hooks of main checkout as they were.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PIN="$(sed -n 's/.*requires "nim == \(.*\)".*/\1/p' "$ROOT/curator/audit/audit.nimble")"
CACHE="${KNOLLER_NIM_DIR:-$HOME/.cache/knoller/nim}/$PIN"
export PATH="$CACHE/bin:$PATH"
BINARY="$ROOT/binaries/koch"
KEY="$(git -C "$ROOT" rev-parse HEAD:koch.nim HEAD:koch.nim.cfg \
  HEAD:curator/audit/audit.nimble HEAD:curator/audit/src \
  HEAD:curator/knoller/src HEAD:curator/knoller/knoller.nimble 2>/dev/null | tr '\n' ' ')"

if [ "$1" = start ]; then
  if ! command -v nim >/dev/null 2>&1; then
    mkdir -p "$CACHE"
    curl -sSL "https://nim-lang.org/download/nim-$PIN-linux_x64.tar.xz" |
      tar xJ -C "$CACHE" --strip-components=1
  fi
  git -C "$ROOT" config core.hooksPath .githooks
  if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
    echo "export PATH=\"$CACHE/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
  fi
fi

# Build where binary is absent or its key is not HEAD's; failed build keeps binary it had.
if [ ! -x "$BINARY" ] || { [ -n "$KEY" ] && [ "$KEY" != "$(cat "$BINARY.key" 2>/dev/null)" ]; }
then
  mkdir -p "$ROOT/binaries"
  find "$ROOT/binaries" -maxdepth 1 -name .lock -mmin +10 -exec rmdir {} \; 2>/dev/null || true
  if mkdir "$ROOT/binaries/.lock" 2>/dev/null; then
    if (cd "$ROOT" && nim c --hints:off -o:"binaries/koch.$$" koch.nim >/dev/null) &&
      mv -f "$ROOT/binaries/koch.$$" "$BINARY"; then
      printf '%s\n' "$KEY" > "$BINARY.key"
      rmdir "$ROOT/binaries/.lock"
    else
      rm -f "$ROOT/binaries/koch.$$"
      rmdir "$ROOT/binaries/.lock"
      [ "$1" != start ] || exit 1
    fi
  fi
fi

if [ -x "$BINARY" ]; then
  exec "$BINARY" hook "$1" --root:"$ROOT"
fi
cd "$ROOT" && exec nim r --hints:off koch hook "$1"
