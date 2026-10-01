#!/bin/sh
# Run one koch hook verb with pinned compiler on PATH; `start` installs pin and builds koch.
#   not Nim because hook command is what puts compiler on PATH before any Nim can run, and
#   git runs its hooks as executable scripts (`.githooks/`), which call back into this file.
#   Pin is read from audit's nimble file, so it is stated once (CURATOR.md duty 8).
#   Tarball is linux_x64; other platform with `nim` already on PATH falls through, and one
#   without it fails loudly at build rather than silently at every hook.
#   `binaries/` is ignored by git, so built koch never reaches audit or repository.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PIN="$(sed -n 's/.*requires "nim == \(.*\)".*/\1/p' "$ROOT/curator/audit/audit.nimble")"
CACHE="${KOCH_NIM_DIR:-$HOME/.cache/koch/nim}/$PIN"
export PATH="$CACHE/bin:$PATH"

if [ "$1" = start ]; then
  if ! command -v nim >/dev/null 2>&1; then
    mkdir -p "$CACHE"
    curl -sSL "https://nim-lang.org/download/nim-$PIN-linux_x64.tar.xz" |
      tar xJ -C "$CACHE" --strip-components=1
  fi
  (cd "$ROOT" && nim c --hints:off -o:binaries/koch koch.nim >/dev/null)
  git -C "$ROOT" config core.hooksPath .githooks
  if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
    echo "export PATH=\"$CACHE/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
  fi
fi

if [ -x "$ROOT/binaries/koch" ]; then
  exec "$ROOT/binaries/koch" hook "$1" --root:"$ROOT"
fi
cd "$ROOT" && exec nim r --hints:off koch hook "$1"
