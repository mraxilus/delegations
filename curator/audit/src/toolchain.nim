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

import std/[options, osproc, strutils]
import ./[findings, dependencies]


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


func checkRunning*(dir, pin: string, running: Compiler): seq[Finding] =
  ## Report compiler on PATH differing from project's pin, by commit or by version.
  let present = if pin.isCommit: running.commit else: running.version
  if pin != present:
    result.add finding(
      dir, 0,
      "Compiler differs from project pin `" & pin & "`; install or build it, then run " &
        "again; got `" & (if present.len > 0: present else: "nothing") & "`.",
    )


proc runningCompiler*(): Compiler =
  ## Read version and commit of `nim` on PATH, i.e. compiler testament will invoke.
  ##   Commit comes from `git hash:` line, which release tarballs carry as well as builds
  ##   made from source, so commit pin is checkable either way.
  let (output, code) = execCmdEx("nim --version")
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
