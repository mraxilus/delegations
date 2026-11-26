## Read nimble requirements and drive Atlas per project (Articles II.8, XI.3).
##   Requirements live in `<project>.nimble` as `requires "..."` lines; `nim` itself is not
##   package, and knoller reads its pin from same literals (`pins.nim`), whose scan this module
##   imports (`requireLiterals`). Project requiring packages carries `atlas.lock` (`atlas pin`);
##   `deps/` stays out of repository and `atlas rep` restores it from lock.
##   Pure part parses text and compares commits; effect part runs Atlas in project directory
##     with `--noexec`, and reads commit of each checkout through git.
##   Exit of `rep` is discarded, since it can fail where each checkout matches lock: Atlas
##     0.14.7 exits 1 where it cannot read its list of packages, which it caches in `.cache` of
##     `dependencies/`. Success is judged by each checkout lock names, then by `atlas changed`
##     exiting 0.
##   `atlas changed` exits 0 when checkout is absent entirely, warning only, so existence of
##     every directory lock names is demanded first; without it, restore that fetched
##     nothing reports success (Atlas 0.14.7, 2026-11-16).
##   `atlas changed` exits 0 too while it warns that commit differs, so commit each present
##     checkout stands at is held to commit lock holds for it; without it, checkout that `rep`
##     cannot move to commit of lock gives no finding (Atlas 0.14.7, 2026-11-16; #947).
##     Directory holding no commit git reads is finding too, since nothing shows it matches; so
##     is item naming no commit, as `atlas changed` warns commit differs there (Atlas 0.14.7).
##   Cost: one run of git for each item of each lock, at each restore.
##
##   Lock also stores whole nimble file, and `atlas rep` writes that copy back over project's
##     file. So requirement edited without regenerating lock is reverted, and silently:
##     compilation never reads nimble, so nothing fails when edit is lost; what fails is later
##     check, on reverted line contributor never wrote. Copy is therefore compared against
##     committed file, and difference is finding.
##   Lock stores name of copy too, and `atlas rep` writes copy under it; name of other file
##     writes second nimble file, so name is held to nimble file of project (#631).
##   Comparison belongs to static pass, over tree as git holds it. Run after restore it would
##     compare file against copy it was just written from, pass always, and cover nothing.
##
##   Cost: lock storing no copy is compared against nothing, since one lock is thin evidence
##     for demanding key, and lock with no copy reverts nothing either way.
##   Restore needs network only where checkout is cold, since verdict reads no cache: over warm
##     checkouts with network cut, `atlas changed` exits 0, and so does `atlas --noexec rep` where
##     its cache stands too (Atlas 0.14.7, 2026-11-16; PROVENANCE.md, Dependencies, has time).
##     Project holding no lock has nothing to restore, and Atlas exits 1 there, reading no lock;
##     so runner touches only projects holding lock file, and layout demands lock where packages
##     are required.
##   Cost: cold restore clones each package, so it needs network.

{.experimental: "strictFuncs".}

import std/[json, options, os, strutils]
from ../../knoller/src/knoller/command import runGit
import ../../knoller/src/knoller
import ./[findings, projects]


const
  DIRECTORY_DEPS* = "deps"  ## Directory Atlas restores into when `atlas.config` names none.
  ATLAS_CONFIG* = "atlas.config"  ## Where project names its checkout directory, under `deps`.
  MANIFEST_NODE* = "package.json"  ## Node manifest, naming tools project type-checks with.
  LOCK_NODE* = "package-lock.json"  ## Node lock, pinning every one of those to exact version.
  KEY_FILENAME* = "\"filename\":"  ## Key of lock line naming nimble copy, as Atlas writes it.
  UNREADABLE = "Lock unreadable as JSON; got `"
    ## Opening of finding both lock readers report when JSON will not parse.


type Checkout* = object  ## Define one checkout lock names, and commit lock holds for it.
  name*: string  ## Name of item, as lock keys it.
  directory*: string  ## Directory of checkout, project-relative, `$deps` resolved.
  commit*: string  ## Commit lock holds for checkout; empty where item names none.


func requirements*(nimble: string): seq[string] =
  ## Collect required packages from nimble text, `nim` excluded.
  for requirement in nimble.requireLiterals:
    if requirement.namePackage.toLowerAscii != NIM: result.add requirement


proc checkoutsLock*(lock: string, directory_deps = DIRECTORY_DEPS): seq[Checkout] =
  ## Read checkouts lock names with their commits, `$deps` resolved to project-relative directory.
  let node = parseJson(lock)
  if "items" notin node: return
  for name, item in node["items"]:
    if "dir" notin item: continue
    result.add Checkout(
      name: name,
      directory: item["dir"].getStr.replace("$deps", directory_deps),
      commit: item{"commit"}.getStr,
    )


proc directoryDeps*(config: string): string =
  ## Read directory `atlas.config` restores into, i.e. its `deps` key; default when absent.
  ##   Project names it in full (`dependencies`, Article V.9) or keeps Atlas default `deps`.
  let node = parseJson(config)
  if "deps" notin node: return DIRECTORY_DEPS
  let named = node["deps"].getStr
  if named.len == 0: DIRECTORY_DEPS else: named


proc nimbleLock*(lock: string): Option[string] =
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
    stored = lock.nimbleLock
  except CatchableError as e:
    return @[finding(path_lock, 0, Check.LockUnreadable, UNREADABLE & e.msg & "`.")]
  if stored.isNone: return
  let line = differenceFirst(stored.get, nimble)
  if line == 0: return
  let
    committed = nimble.split('\n')
    held = if line <= committed.len: committed[line - 1] else: ""
  result.add finding(
    path_nimble,
    line,
    Check.NimbleLock,
    "Lock's stored nimble differs here, and `atlas rep` writes it back over this file; got `" &
      held & "`.",
    help = "regenerate lock, or make its stored copy match",
  )


proc checkNameNimble*(path_nimble, path_lock, lock: string): seq[Finding] =
  ## Report lock naming its nimble copy after other file than nimble file of its project.
  ##   `atlas rep` writes copy under that name, so other name writes second nimble file, which
  ##     layout refuses; project move left one such lock (#631).
  ##   Finding points at lock, at line naming copy, since regenerating lock is fix.
  ##   Lock that will not parse is `checkNimbleLock`'s to report, so it is reported once.
  var node: JsonNode
  try:
    node = parseJson(lock)
  except CatchableError:
    return
  if "nimbleFile" notin node or "filename" notin node["nimbleFile"]: return
  let (named, expected) = (node["nimbleFile"]["filename"].getStr, path_nimble.extractFilename)
  if named == expected: return

  # Locate line naming copy, so finding opens where fix lands.
  var line = 0
  let lines = lock.split('\n')
  for i, text in lines:
    if text.strip.startsWith(KEY_FILENAME) and named in text:
      line = i + 1
      break
  result.add finding(
    path_lock,
    line,
    Check.NameLock,
    "Lock names nimble copy after nimble file of project, or `atlas rep` writes second one " &
      "beside it; got `" & named & "`.",
    expected = some(expected),
    help = "regenerate lock",
  )


func checkCommitCheckout*(
  path_lock: string, checkout: Checkout, commit_found: Option[string]
): seq[Finding] =
  ## Report checkout standing at other commit than lock holds for it, or at none git reads.
  ##   Finding names item and both commits, which `atlas changed` names only in its warning.
  if commit_found.isNone:
    return @[finding(
      path_lock,
      0,
      Check.CommitCheckout,
      "Checkout holds no commit git reads after restore; got `" & checkout.directory & "`.",
    )]
  if commit_found.get == checkout.commit: return
  result.add finding(
    path_lock,
    0,
    Check.CommitCheckout,
    "Checkout of `" & checkout.name & "` stands at other commit than lock holds after restore; " &
      "got `" & commit_found.get & "`.",
    expected = some(checkout.commit),
  )


proc readHead(directory: string): Option[string] =
  ## Read commit `HEAD` of checkout at directory names; none where git reads none there.
  ##   Git reads `.git` of directory alone, since plain directory under project would read
  ##     `HEAD` of repository holding it, which for knoller is package's own.
  ##   Exit decides, never output: git that reads no commit still prints `HEAD` it was given.
  let (output, _, code) = runGit(directory, ["--git-dir=.git", "rev-parse", "HEAD"])
  if code != 0: return
  some(output.strip)


proc checkCheckouts*(root, directory: string): seq[Finding] =
  ## Report checkout lock names that is absent on disk or stands at other commit than lock
  ##   holds, and lock that will not parse.
  ##   One parse of lock serves both; absent checkout reads no commit, so it is one finding.
  let
    path_lock = directory & "/" & FILE_LOCK
    path_config = root / directory / ATLAS_CONFIG
    directory_deps =
      if fileExists(path_config): readFile(path_config).directoryDeps else: DIRECTORY_DEPS
  var checkouts: seq[Checkout]
  try:
    checkouts = readFile(root / path_lock).checkoutsLock(directory_deps)
  except CatchableError as e:
    return @[finding(path_lock, 0, Check.LockUnreadable, UNREADABLE & e.msg & "`.")]
  for checkout in checkouts:
    let path = root / directory / checkout.directory
    if not dirExists(path):
      result.add finding(
        path_lock,
        0,
        Check.CheckoutMissing,
        "Checkout absent after restore; got `" & checkout.directory & "`."
      )
      continue
    result.add checkCommitCheckout(path_lock, checkout, path.readHead)


func differing*(directory: string, code: int): seq[Finding] =
  ## Report checkouts of project that `atlas changed` finds apart from lock, by its exit code.
  @[finding(
    directory & "/" & FILE_LOCK,
    0,
    Check.RestoreDependency,
    "Checkouts differ from lock; got exit `" & $code & "`.",
  )]


proc restoreDependencies(root: string, target: Target): seq[Finding] =
  ## Restore project's checkouts from lock through Atlas, judged by each checkout, then `changed`.
  ##   Atlas comes from same toolchain as compiler, since it records compiler it ran under
  ##   and warns of environment mismatch when lock was written by another.
  echo "== " & target.directory
  let atlas = target.bin.toolIn("atlas")
  discard runIn(root / target.directory, atlas, ["--noexec", "rep"], target.bin)
  result = checkCheckouts(root, target.directory)
  let code = runIn(root / target.directory, atlas, ["changed"], target.bin)
  if code != 0: result.add differing(target.directory, code)


proc restoreAll*(root: string, targets: openArray[Target]): seq[Finding] =
  ## Restore every project holding lock file; project without one has nothing to restore.
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
      Check.RestoreNode,
      "Type check needs npm on `PATH`.",
      help = "install node, or drop this project's manifest",
    )]
  let code = runIn(root / target.directory, "npm", ["ci", "--no-audit", "--no-fund"], target.bin)
  if code != 0:
    result.add finding(
      target.directory & "/" & LOCK_NODE,
      0,
      Check.RestoreNode,
      "Node restore failed; got exit `" & $code & "`.",
    )
