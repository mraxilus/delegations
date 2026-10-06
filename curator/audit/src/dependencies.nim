## Read nimble requirements and drive Atlas per project (Articles II.8, XI.3).
##   Requirements live in `<project>.nimble` as `requires "..."` lines; `nim` itself is not
##   package, and knoller reads its pin from same literals (`pins.nim`), whose scan this module
##   imports (`requireLiterals`). Project requiring packages carries `atlas.lock` (`atlas pin`);
##   `deps/` stays out of repository and `atlas rep` restores it from lock.
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
##   Cost: Atlas needs network for every command, even with zero packages, so runner
##     touches only projects holding lock file; layout demands lock where packages are
##     required.

{.experimental: "strictFuncs".}

import std/[json, options, os, strutils]
import ../../knoller/src/knoller
import ./[findings, projects]


const
  DIRECTORY_DEPS* = "deps"  ## Directory Atlas restores into when `atlas.config` names none.
  ATLAS_CONFIG* = "atlas.config"  ## Where project names its checkout directory, under `deps`.
  MANIFEST_NODE* = "package.json"  ## Node manifest, naming tools project type-checks with.
  LOCK_NODE* = "package-lock.json"  ## Node lock, pinning every one of those to exact version.
  UNREADABLE = "Lock unreadable as JSON; got `"
    ## Opening of finding both lock readers report when JSON will not parse.


func requirements*(nimble: string): seq[string] =
  ## Collect required packages from nimble text, `nim` excluded.
  for requirement in nimble.requireLiterals:
    if requirement.packageName.toLowerAscii != NIM: result.add requirement


proc directoriesLock*(lock: string, directory_deps = DIRECTORY_DEPS): seq[string] =
  ## Read checkout directories lock names, `$deps` resolved to project-relative directory.
  let node = parseJson(lock)
  if "items" notin node: return
  for _, item in node["items"]:
    if "dir" notin item: continue
    result.add item["dir"].getStr.replace("$deps", directory_deps)


proc directoryDepsOf*(config: string): string =
  ## Read directory `atlas.config` restores into, i.e. its `deps` key; default when absent.
  ##   Project names it in full (`dependencies`, Article V.9) or keeps Atlas default `deps`.
  let node = parseJson(config)
  if "deps" notin node: return DIRECTORY_DEPS
  let named = node["deps"].getStr
  if named.len == 0: DIRECTORY_DEPS else: named


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


func differenceFirst(stored, nimble: string): int =
  ## Read one-based line where two texts first differ; `0` when they are identical.
  let
    held = stored.split('\n')
    committed = nimble.split('\n')
  for i in 0 ..< max(held.len, committed.len):
    let
      a = if i < held.len: held[i] else: ""
      b = if i < committed.len: committed[i] else: ""
    if a != b: return i + 1
  0


proc checkNimbleLock*(path_nimble, path_lock, lock, nimble: string): seq[Finding] =
  ## Report lock's stored nimble differing from committed one, naming line about to be lost.
  ##   Finding points at nimble file rather than at lock: that is file restore overwrites,
  ##   and its line numbers are real, while numbers inside stored copy resolve nowhere.
  var stored: Option[string]
  try:
    stored = lock.lockNimble
  except CatchableError as e:
    return @[finding(path_lock, 0, UNREADABLE & e.msg & "`.")]
  if stored.isNone: return
  let line = differenceFirst(stored.get, nimble)
  if line == 0: return
  let
    committed = nimble.split('\n')
    held = if line <= committed.len: committed[line - 1] else: ""
  result.add finding(
    path_nimble,
    line,
    "Lock's stored nimble differs here, and `atlas rep` writes it back over this file; " &
      "regenerate lock, or make its stored copy match; got `" & held & "`.",
  )


proc checkCheckouts*(root, directory: string): seq[Finding] =
  ## Report checkout lock names that is absent on disk, and lock that will not parse.
  let
    path_lock = directory & "/" & FILE_LOCK
    path_config = root / directory / ATLAS_CONFIG
    directory_deps =
      if fileExists(path_config): readFile(path_config).directoryDepsOf else: DIRECTORY_DEPS
  var directories: seq[string]
  try:
    directories = readFile(root / path_lock).directoriesLock(directory_deps)
  except CatchableError as e:
    return @[finding(path_lock, 0, UNREADABLE & e.msg & "`.")]
  for checkout in directories:
    if not dirExists(root / directory / checkout):
      result.add finding(path_lock, 0, "Checkout absent after restore; got `" & checkout & "`.")


proc restoreDependencies(root: string, target: Target): seq[Finding] =
  ## Restore project's checkouts from lock through Atlas, judged by presence then `changed`.
  ##   Atlas comes from same toolchain as compiler, since it records compiler it ran under
  ##   and warns of environment mismatch when lock was written by another.
  echo "== " & target.directory
  let atlas = target.bin.toolIn("atlas")
  discard runIn(root / target.directory, atlas, ["--noexec", "rep"], target.bin)
  result = checkCheckouts(root, target.directory)
  let code = runIn(root / target.directory, atlas, ["changed"], target.bin)
  if code != 0:
    result.add finding(
      target.directory & "/" & FILE_LOCK,
      0,
      "Checkouts differ from lock; got exit `" & $code & "`.",
    )


proc restoreAll*(root: string, targets: openArray[Target]): seq[Finding] =
  ## Restore every project holding lock file; projects without one need no network.
  for target in targets:
    if fileExists(root / target.directory / FILE_LOCK):
      result.add restoreDependencies(root, target)


proc restoreNode*(root: string, target: Target): seq[Finding] =
  ## Restore project's node tools from its lock, as Atlas restores its Nim ones.
  ##   `npm ci` rather than `install`: it installs exactly what lock names and fails where
  ##   manifest and lock disagree, which is same contract `atlas changed` holds Nim side to.
  ##   koch resolves Nim compiler it lacks and will not fetch node, so absent npm is finding
  ##   naming it rather than skip: check nobody notices doing nothing is worse than none.
  echo "== " & target.directory
  if findExe("npm").len == 0:
    return @[finding(
      target.directory & "/" & MANIFEST_NODE, 0,
      "Type check needs npm on `PATH`; install node, or drop this project's manifest; " &
        "got nothing.",
    )]
  let code = runIn(root / target.directory, "npm", ["ci", "--no-audit", "--no-fund"], target.bin)
  if code != 0:
    result.add finding(
      target.directory & "/" & LOCK_NODE,
      0,
      "Node restore failed; got exit `" & $code & "`.",
    )
