## Read nimble requirements and drive Atlas per project (Articles II.8, XI.3).
##   Requirements live in `<project>.nimble` as `requires "..."` lines; `nim` itself is not
##   package, and its pin is read by `toolchain.nim` from same literals. Project requiring
##   packages carries `atlas.lock` (`atlas pin`); `deps/` stays out of repository and
##   `atlas rep` restores it from lock.
##   Pure part parses text; effect part runs Atlas in project directory with `--noexec`.
##   Atlas 0.9.0 `rep` exits 1 after restoring checkout (its submodule step fails), so
##     success is judged by `atlas changed` exiting 0 afterwards, i.e. checkouts match lock.
##   `atlas changed` exits 0 when checkout is absent entirely, warning only, so existence of
##     every directory lock names is demanded first; without it, restore that fetched
##     nothing reports success (measured on Atlas 0.9.0, 2026-09-06).
##
##   Lock also stores whole nimble file, and `atlas rep` writes that copy back over project's
##     file. So requirement edited without regenerating lock is reverted, and silently:
##     compilation never reads nimble, so nothing fails when edit is lost; what fails is later
##     check, on reverted line contributor never wrote. Copy is therefore compared against
##     committed file, and difference is finding.
##   Comparison belongs to static pass, over tree as git holds it. Run after restore it would
##     compare file against copy it was just written from, pass always, and cover nothing.
##
##   Cost: lock storing no copy is compared against nothing, since one lock is thin evidence
##     for demanding key, and lock with no copy reverts nothing either way.
##   Cost: parser reads `requires` lines only; `when` branches count as unconditional, and
##     every literal on line is taken.
##   Cost: Atlas needs network for every command, even with zero packages, so runner
##     touches only projects holding lock file; layout demands lock where packages are
##     required.

{.experimental: "strictFuncs".}

import std/[json, options, os, strutils]
import ./[findings, projects]


const
  NIMBLE_EXT* = ".nimble"   ## Extension of package description file.
  LOCK_FILE* = "atlas.lock" ## Atlas lock file name.
  DEPS_DIR* = "deps"        ## Directory Atlas restores checkouts into, never committed.
  UNREADABLE = "Lock unreadable as JSON; got `"
    ## Opening of finding both lock readers report when JSON will not parse.
  NAME_END = {' ', '#', '@', '>', '<', '=', '~', '^'}
    ## Characters ending package name inside requirement.


func packageName*(requirement: string): string =
  ## Read package name from requirement, i.e. text before version, hash or space.
  for i, c in requirement:
    if c in NAME_END: return requirement[0 ..< i]
  requirement


func requireLiterals*(nimble: string): seq[string] =
  ## Collect every string literal on `requires` lines, compiler pin included.
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
      result.add rest[i + 1 ..< close]
      i = close + 1


func requirements*(nimble: string): seq[string] =
  ## Collect required packages from nimble text, `nim` excluded.
  for requirement in nimble.requireLiterals:
    if requirement.packageName.toLowerAscii != "nim": result.add requirement


proc lockDirs*(lock: string): seq[string] =
  ## Read checkout directories lock names, `$deps` resolved to project-relative `deps`.
  let node = parseJson(lock)
  if "items" notin node: return
  for _, item in node["items"]:
    if "dir" notin item: continue
    result.add item["dir"].getStr.replace("$deps", DEPS_DIR)


proc lockNimble*(lock: string): Option[string] =
  ## Read nimble copy lock stores, i.e. text `atlas rep` writes back over project's file.
  ##   Copy is array of lines; joining on newline reproduces original file exactly, since
  ##   final empty element carries its trailing newline.
  let node = parseJson(lock)
  if "nimbleFile" notin node: return
  let stored = node["nimbleFile"]
  if "content" notin stored: return
  var lines: seq[string]
  for line in stored["content"]: lines.add line.getStr
  some(lines.join("\n"))


func firstDifference(stored, nimble: string): int =
  ## Read one-based line where two texts first differ; `0` when they are identical.
  let held = stored.split('\n')
  let committed = nimble.split('\n')
  for i in 0 ..< max(held.len, committed.len):
    let a = if i < held.len: held[i] else: ""
    let b = if i < committed.len: committed[i] else: ""
    if a != b: return i + 1
  0


proc checkLockNimble*(nimble_path, lock_path, lock, nimble: string): seq[Finding] =
  ## Report lock's stored nimble differing from committed one, naming line about to be lost.
  ##   Finding points at nimble file rather than at lock: that is file restore overwrites,
  ##   and its line numbers are real, while numbers inside stored copy resolve nowhere.
  var stored: Option[string]
  try:
    stored = lock.lockNimble
  except CatchableError as e:
    return @[finding(lock_path, 0, UNREADABLE & e.msg & "`.")]
  if stored.isNone: return
  let line = firstDifference(stored.get, nimble)
  if line == 0: return
  let committed = nimble.split('\n')
  let held = if line <= committed.len: committed[line - 1] else: ""
  result.add finding(
    nimble_path, line,
    "Lock's stored nimble differs here, and `atlas rep` writes it back over this file; " &
      "regenerate lock, or make its stored copy match; got `" & held & "`.",
  )


proc checkCheckouts*(root, dir: string): seq[Finding] =
  ## Report checkout lock names that is absent on disk, and lock that will not parse.
  let lock_path = dir & "/" & LOCK_FILE
  var dirs: seq[string]
  try:
    dirs = readFile(root / lock_path).lockDirs
  except CatchableError as e:
    return @[finding(lock_path, 0, UNREADABLE & e.msg & "`.")]
  for checkout in dirs:
    if not dirExists(root / dir / checkout):
      result.add finding(lock_path, 0, "Checkout absent after restore; got `" & checkout & "`.")


proc restoreDependencies*(root: string, target: Target): seq[Finding] =
  ## Restore project's checkouts from lock through Atlas, judged by presence then `changed`.
  ##   Atlas comes from same toolchain as compiler, since it records compiler it ran under
  ##   and warns of environment mismatch when lock was written by another.
  echo "== " & target.dir
  let atlas = target.bin.toolIn("atlas")
  discard runIn(root / target.dir, atlas, ["--noexec", "rep"], target.bin)
  result = checkCheckouts(root, target.dir)
  let code = runIn(root / target.dir, atlas, ["changed"], target.bin)
  if code != 0:
    result.add finding(
      target.dir & "/" & LOCK_FILE, 0, "Checkouts differ from lock; got exit `" & $code & "`."
    )


proc restoreAll*(root: string, targets: openArray[Target]): seq[Finding] =
  ## Restore every project holding lock file; projects without one need no network.
  for target in targets:
    if fileExists(root / target.dir / LOCK_FILE):
      result.add restoreDependencies(root, target)
