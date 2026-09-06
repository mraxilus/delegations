## Enforce per-project Nim pin, and driver version derived from it (CURATOR.md duty 7).
##   Project's compiler is property of project, not of repository: `pga` needs 2.2.6 or
##   later, `dance_ontology` crashes compiler on 2.2.8 and later, so no single version
##   serves both. Pin therefore lives in project's nimble file as `requires "nim == x.y.z"`,
##   beside package requirements Atlas already reads, and is exact for same reason
##   `atlas.lock` is exact: it records what was verified, never range nobody tried.
##
##   Driver version, which builds koch and runs static checks, is not second pin: it is
##     `curator/audit`'s pin, since koch compiles that project's modules. Workflow names it
##     once as `NIM_VERSION`, and check below demands agreement, as `layout.nim` demands
##     agreement between `DOMAINS` and README tables.
##   Running compiler is one testament will invoke, so version comes from `nim --version`
##     rather than from `NimVersion` koch was built with; prebuilt `./koch` and newer `nim`
##     on PATH would otherwise disagree silently.
##
##   Pin is exact version, or exact commit of compiler itself where project follows
##     dependency onto `devel` and no release carries what it needs. Commit records what was
##     verified exactly as version does; `devel` label would record nothing, being moving
##     target. Commit is full forty hex characters, as `atlas.lock` records commits.
##   Driver project pins version, never commit: workflow installs it through setup action,
##     which knows releases and `devel` only, and every other job waits on it.
##
##   Rejected: `requires "nim >= x"`, which cannot express upper bound project needs;
##     separate `.nim-version` file, second place version lives beside nimble file naming
##     one already; dated nightly, cheap to install and retained only for window, so old
##     pin stops installing and record stops being reproducible.
##   Cost: bumping pin is deliberate act per project, so four projects can sit on four
##     compilers and curator changing checker needs every one installed.

{.experimental: "strictFuncs".}

import std/[options, os, osproc, strutils]
import ./[findings, projects, dependencies]


const
  NIM* = "nim"
    ## Requirement name pin carries.
  EXACT* = "=="
    ## Operator pin must use; ranges are rejected.
  DRIVER_DIR* = "curator/audit"
    ## Project whose pin is driver version, since koch compiles its modules.
  WORKFLOW_PATH* = ".github/workflows/check.yml"
    ## Workflow naming driver version once.
  VERSION_KEY* = "NIM_VERSION:"
    ## Key workflow states driver version under.
  HASH_KEY = "git hash:"
    ## Line `nim --version` reports its commit under.
  VERSION_CHARS = Digits + {'.'}
    ## Characters version string is built from.
  COMMIT_CHARS = {'0'..'9', 'a'..'f'}
    ## Characters commit pin is built from; lowercase hex only.
  COMMIT_LEN* = 40
    ## Length of full git commit, which is what pin carries.
  CACHE_KEY* = "KOCH_NIM_DIR"
    ## Environment name overriding where toolchains are cached.
  CACHE_DIR* = ".cache/koch/nim"
    ## Default cache, under home and beside Nim's own `~/.cache/nim`. Never inside checkout:
    ## audit reads untracked files, so toolchain there would be audited.
  DOWNLOAD* = "https://nim-lang.org/download/nim-"
    ## Prefix of published release tarball.
  SOURCE* = "https://github.com/nim-lang/Nim"
    ## Repository built from when no tarball serves pin.
  PLATFORMS* = [
    ("linux", "amd64", "linux_x64"),
    ("linux", "i386", "linux_x32"),
    ("macosx", "amd64", "macosx_x64"),
  ]
    ## Platforms nim-lang.org publishes tarball for, as `hostOS`, `hostCPU`, tarball name.
    ## Anything absent here is built from source, which serves every platform Nim serves.


func isVersion*(s: string): bool =
  ## Decide whether `s` is dotted version, i.e. digit runs separated by single dots.
  if s.len == 0 or not s.allCharsInSet(VERSION_CHARS): return false
  for part in s.split('.'):
    if part.len == 0: return false
  true


func isCommit*(s: string): bool =
  ## Decide whether `s` is full lowercase git commit.
  s.len == COMMIT_LEN and s.allCharsInSet(COMMIT_CHARS)


func isPin*(s: string): bool =
  ## Decide whether `s` names compiler exactly, as commit or as version.
  ##   Commit is tested first: forty digits would satisfy both, and absurd version loses.
  s.isCommit or s.isVersion


func nimPin*(nimble: string): Option[string] =
  ## Read exact Nim version pinned by nimble text; `none` when absent or inexact.
  for requirement in nimble.requireLiterals:
    if requirement.packageName.toLowerAscii != NIM: continue
    let rest = requirement[requirement.packageName.len .. ^1].strip
    if not rest.startsWith(EXACT): return none(string)
    let pin = rest[EXACT.len .. ^1].strip
    return if pin.isPin: some(pin) else: none(string)
  none(string)


func checkPin*(path, nimble: string): seq[Finding] =
  ## Report nimble file carrying no exact Nim pin.
  if nimble.nimPin.isNone:
    result.add finding(
      path, 0,
      "Nimble file must pin compiler exactly as `requires \"" & NIM & " " & EXACT &
        " <version>\"`, or by full commit where project follows compiler onto devel; " &
        "ranges cannot record what was verified; got `" &
        nimble.requireLiterals.join(", ") & "`.",
    )


func workflowVersion*(workflow: string): Option[string] =
  ## Read driver version workflow states, quotes stripped; `none` when key is absent.
  for line in workflow.splitLines:
    let s = line.strip
    if not s.startsWith(VERSION_KEY): continue
    let value = s[VERSION_KEY.len .. ^1].strip.strip(chars = {'\'', '"'})
    return if value.isVersion: some(value) else: none(string)
  none(string)


func checkDriver*(workflow, pin: string): seq[Finding] =
  ## Report driver pinned by commit, or workflow version disagreeing with driver's pin.
  if pin.isCommit:
    return @[finding(
      DRIVER_DIR & "/" & DRIVER_DIR.split('/')[^1] & ".nimble", 0,
      "Driver project pins version, never commit: setup action installs releases only, and " &
        "every job waits on it; got `" & pin & "`.",
    )]
  let stated = workflow.workflowVersion
  if stated.isNone:
    result.add finding(
      WORKFLOW_PATH, 0,
      "Workflow must state driver version as `" & VERSION_KEY & " '<version>'`; got nothing.",
    )
  elif stated.get != pin:
    result.add finding(
      WORKFLOW_PATH, 0,
      "Driver version must equal `" & DRIVER_DIR & "` pin `" & pin & "`; got `" & stated.get &
        "`.",
    )


type Compiler* = object
  ## Define what `nim --version` says about compiler on PATH.
  version*: string  ## Dotted release version it names.
  commit*: string   ## Git hash it reports; empty when it reports none.


func serves*(pin: string, compiler: Compiler): bool =
  ## Decide whether compiler is one pin names, by commit or by version.
  pin == (if pin.isCommit: compiler.commit else: compiler.version)


func checkRunning*(dir, pin: string, running: Compiler): seq[Finding] =
  ## Report compiler on PATH differing from project's pin, by commit or by version.
  let present = if pin.isCommit: running.commit else: running.version
  if not pin.serves(running):
    result.add finding(
      dir, 0,
      "Compiler differs from project pin `" & pin & "`; install or build it, then run " &
        "again; got `" & (if present.len > 0: present else: "nothing") & "`.",
    )


proc compilerAt*(nim_path: string): Compiler =
  ## Read version and commit compiler at path reports; empty record when it will not run.
  ##   Commit comes from `git hash:` line, which release tarballs carry as well as builds
  ##   made from source, so commit pin is checkable either way.
  let (output, code) = execCmdEx(nim_path.quoteShell & " --version")
  if code != 0: return
  let lines = output.splitLines
  for word in lines[0].splitWhitespace:
    if word.isVersion:
      result.version = word
      break
  for line in lines:
    let s = line.strip
    if not s.startsWith(HASH_KEY): continue
    let hash = s[HASH_KEY.len .. ^1].strip
    if hash.isCommit: result.commit = hash
    break


proc runningCompiler*(): Compiler =
  ## Read compiler on PATH, i.e. one koch itself was invoked through.
  compilerAt("nim")


func platformOf*(os_name, cpu: string): string =
  ## Read tarball name nim-lang.org publishes for platform; empty when it publishes none.
  for (name, arch, tarball) in PLATFORMS:
    if name == os_name and arch == cpu: return tarball
  ""


func isBuilt*(pin, platform: string): bool =
  ## Decide whether pin must be built from source rather than fetched as tarball.
  ##   Commit is never published, and platform without tarball has nothing to fetch.
  pin.isCommit or platform.len == 0


func releaseUrl*(version, platform: string): string =
  ## Read address of published tarball for release on platform.
  DOWNLOAD & version & "-" & platform & ".tar.xz"


func cacheRoot*(override: string): string =
  ## Read cache directory toolchains live under, override winning when set.
  if override.len > 0: override else: getHomeDir() / CACHE_DIR


func binOf*(root, pin: string): string =
  ## Read directory holding compiler serving pin, once it is cached.
  root / pin / "bin"


func missing*(dir, pin, bin: string): seq[Finding] =
  ## Report pin no compiler serves, naming cache koch tried, so remedy is visible.
  @[finding(
    dir, 0,
    "No compiler serves project pin, and fetching one failed; install it under `" & bin &
      "`, or make network reachable, then run again; got `" & pin & "`.",
  )]


proc fetchRelease(version, platform, dir: string): bool =
  ## Download published tarball and unpack it as `dir`; false when any step fails.
  ##   Tarball holds one top folder, `nim-<version>`, which becomes `dir` itself so every
  ##   pin has same shape whether fetched or built.
  let work = dir & ".fetching"
  removeDir(work)
  createDir(work)
  defer: removeDir(work)
  let archive = work / "nim.tar.xz"
  if runIn(work, "curl", ["-sSLf", "-o", archive, releaseUrl(version, platform)]) != 0:
    return false
  if runIn(work, "tar", ["xf", archive]) != 0: return false
  let unpacked = work / ("nim-" & version)
  if not dirExists(unpacked): return false
  moveDir(unpacked, dir)
  true


proc buildSource(pin, dir: string): bool =
  ## Clone Nim, check pin out and build it, then move finished tree to `dir`.
  ##   Same recipe `check.yml` runs for commit pin, so it is proven rather than new.
  ##   Version pin arrives here only where no tarball is published, and its tag is `v<x>`.
  ##   Build happens beside `dir` and moves in once done, as fetch does: half-built tree
  ##   carries `bin/nim` of bootstrap stage, which answers `--version` with another commit
  ##   entirely, so second koch reading it mid-build would take it for finished toolchain
  ##   (measured 2026-09-06, probing bootstrap binary five minutes before boot completed).
  let work = dir & ".building"
  removeDir(work)
  removeDir(dir)
  let reference = if pin.isCommit: pin else: "v" & pin
  if runIn(".", "git", ["clone", "--filter=blob:none", "--quiet", SOURCE, work]) != 0:
    return false
  if runIn(work, "git", ["checkout", "--quiet", reference]) != 0: return false
  if runIn(work, "sh", ["build_all.sh"]) != 0: return false
  moveDir(work, dir)
  true


proc resolve*(pin: string, running: Compiler, root: string): Option[string] =
  ## Read `bin` of toolchain serving pin, fetching or building it when absent.
  ##   `none` is failure; `some("")` names compiler on PATH, which CI installs per job and
  ##   so always takes first branch. Two outcomes stay apart, since empty string means
  ##   PATH everywhere else here and would otherwise read as success.
  if pin.serves(running): return some("")
  let bin = binOf(root, pin)
  if pin.serves(compilerAt(bin / NIM)): return some(bin)
  let dir = root / pin
  createDir(root)
  echo "== fetching Nim " & pin
  let platform = platformOf(hostOS, hostCPU)
  let is_built =
    if pin.isBuilt(platform): buildSource(pin, dir)
    else: fetchRelease(pin, platform, dir)

  # Fetched compiler is asked what it is: wrong tarball or half-built tree is not toolchain.
  if is_built and pin.serves(compilerAt(bin / NIM)): return some(bin)
  removeDir(dir)
  none(string)
