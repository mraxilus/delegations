## Read nimble requirements and drive Atlas per project (Articles II.8, XI.3).
##   Requirements live in `<project>.nimble` as `requires "..."` lines; `nim` itself is not
##   package. Project requiring packages carries `atlas.lock` (`atlas pin`); `deps/` stays
##   out of repository and `atlas rep` restores it from lock.
##   Pure part parses text; effect part runs Atlas in project directory with `--noexec`.
##   Atlas 0.9.0 `rep` exits 1 after restoring checkout (its submodule step fails), so
##     success is judged by `atlas changed` exiting 0 afterwards, i.e. checkouts match lock.
##   `atlas changed` exits 0 when checkout is absent entirely, warning only, so existence of
##     every directory lock names is demanded first; without it, restore that fetched
##     nothing reports success (measured on Atlas 0.9.0, 2026-09-06).
##
##   Cost: parser reads `requires` lines only; `when` branches count as unconditional, and
##     every literal on line is taken.
##   Cost: Atlas needs network for every command, even with zero packages, so runner
##     touches only projects holding lock file; layout demands lock where packages are
##     required.

{.experimental: "strictFuncs".}

import std/[json, os, strutils]
import ./[findings, projects]


const
  NIMBLE_EXT* = ".nimble"   ## Extension of package description file.
  LOCK_FILE* = "atlas.lock" ## Atlas lock file name.
  DEPS_DIR* = "deps"        ## Directory Atlas restores checkouts into, never committed.
  NAME_END = {' ', '#', '@', '>', '<', '=', '~', '^'}
    ## Characters ending package name inside requirement.


func packageName*(requirement: string): string =
  ## Read package name from requirement, i.e. text before version, hash or space.
  for i, c in requirement:
    if c in NAME_END: return requirement[0 ..< i]
  requirement


func requirements*(nimble: string): seq[string] =
  ## Collect required packages from nimble text, `nim` excluded.
  for line in nimble.splitLines:
    let s = line.strip
    if not s.startsWith("requires"): continue
    let rest = s[8 .. ^1]

    # Take every string literal on line.
    var i = 0
    while i < rest.len:
      if rest[i] != '"':
        inc i
        continue
      let close = rest.find('"', i + 1)
      if close < 0: break
      let requirement = rest[i + 1 ..< close]
      if requirement.packageName.toLowerAscii != "nim": result.add requirement
      i = close + 1


proc lockDirs*(lock: string): seq[string] =
  ## Read checkout directories lock names, `$deps` resolved to project-relative `deps`.
  let node = parseJson(lock)
  if "items" notin node: return
  for _, item in node["items"]:
    if "dir" notin item: continue
    result.add item["dir"].getStr.replace("$deps", DEPS_DIR)


proc checkCheckouts*(root, dir: string): seq[Finding] =
  ## Report checkout lock names that is absent on disk, and lock that will not parse.
  let lock_path = dir & "/" & LOCK_FILE
  var dirs: seq[string]
  try:
    dirs = readFile(root / lock_path).lockDirs
  except CatchableError as e:
    return @[finding(lock_path, 0, "Lock unreadable as JSON; got `" & e.msg & "`.")]
  for checkout in dirs:
    if not dirExists(root / dir / checkout):
      result.add finding(lock_path, 0, "Checkout absent after restore; got `" & checkout & "`.")


proc restoreDependencies*(root, dir: string): seq[Finding] =
  ## Restore project's checkouts from lock through Atlas, judged by presence then `changed`.
  echo "== " & dir
  discard runIn(root / dir, "atlas", ["--noexec", "rep"])
  result = checkCheckouts(root, dir)
  let code = runIn(root / dir, "atlas", ["changed"])
  if code != 0:
    result.add finding(
      dir & "/" & LOCK_FILE, 0, "Checkouts differ from lock; got exit `" & $code & "`."
    )


proc restoreAll*(root: string, dirs: openArray[string]): seq[Finding] =
  ## Restore every project holding lock file; projects without one need no network.
  for dir in dirs:
    if fileExists(root / dir / LOCK_FILE): result.add restoreDependencies(root, dir)
