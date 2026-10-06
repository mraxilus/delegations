## Enforce per-project Nim pin, and driver version derived from it (CURATOR.md duty 8).
##   Project's compiler is property of project, not of repository: `pga` needs lexer change
##   no release carries yet, so `rga_visualiser` pins commit while every other project pins
##   release, and no single version serves them all. Pin therefore lives in project's nimble
##   file as `requires "nim == <pin>"`, beside package requirements Atlas already reads, and
##   is exact for same reason `atlas.lock` is exact: it records what was verified, never
##   range nobody tried.
##
##   Driver version, which builds koch and runs static checks, is not second pin: it is
##     `curator/audit`'s pin, since koch compiles that project's modules. Every workflow
##     installing compiler names it as `NIM_VERSION`, and check below demands agreement, as
##     `layout.nim` demands agreement between `DOMAINS` and README tables.
##   `curator/knoller` pins driver version too: audit imports it by path, so koch compiles it.
##     Sibling imported by path is no package, so it carries no lock.
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
##   This module holds policy of this repository alone. Reading pin, and obtaining compiler
##     serving one, are knoller's (`pins.nim`, `compilers.nim`), which audit imports, since
##     reading rule and fetching toolchain are separate jobs and knoller's command needs both.
##   Cost: bumping pin is deliberate act per project, so four projects can sit on four
##     compilers; koch obtains each, so no curator installs four by hand.

{.experimental: "strictFuncs".}

import std/[options, strutils]
import ../../knoller/src/knoller
import ./findings


const
  DRIVER_DIRECTORY* = "curator/audit"
    ## Project whose pin is driver version, since koch compiles its modules.
  KNOLLER_DIRECTORY* = "curator/knoller"
    ## Project driver imports by path, so koch compiles it and it pins driver version.
  WORKFLOW_PATH* = ".github/workflows/check.yml"
    ## Driver's own workflow, which must name driver version; others must agree where they do.
  VERSION_KEY* = "NIM_VERSION:"  ## Key workflow states driver version under.


func checkPin*(path, nimble: string): seq[Finding] =
  ## Report nimble file carrying no exact Nim pin as `nim == <pin>`.
  ##   `nim#<commit>`, which knoller reads as pin too, is finding here: repository writes pin in
  ##   one form, which CONTRIBUTOR.md (Toolchain) names and `.claude/hooks.sh` reads as text.
  let is_exact = nimble.requirementNim.get("").startsWith(EXACT)
  if nimble.nimPin.isNone or not is_exact:
    result.add finding(
      path,
      0,
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


func checkDriver*(path, workflow, pin: string): seq[Finding] =
  ## Report driver pinned by commit, or workflow version disagreeing with driver's pin.
  ##   Every workflow installing compiler states version, and each must agree: second copy
  ##   drifts, which is why `layout.nim` holds README tables to `DOMAINS` as well.
  ##   Pin itself and absent key are named against driver's own workflow alone, however many
  ##   state version: both are one fault, and reporting it per file would multiply it.
  if pin.isCommit:
    if path != WORKFLOW_PATH: return
    return @[finding(
      DRIVER_DIRECTORY & "/" & DRIVER_DIRECTORY.split('/')[^1] & ".nimble", 0,
      "Driver project pins version, never commit: setup action installs releases only, and " &
        "every job waits on it; got `" & pin & "`.",
    )]
  let stated = workflow.workflowVersion
  if stated.isNone:
    if path != WORKFLOW_PATH: return
    result.add finding(
      path,
      0,
      "Workflow must state driver version as `" & VERSION_KEY & " '<version>'`; got nothing.",
    )
  elif stated.get != pin:
    result.add finding(
      path,
      0,
      "Driver version must equal `" & DRIVER_DIRECTORY & "` pin `" & pin & "`; got `" & stated.get &
        "`.",
    )


func checkKnoller*(path: string; pin, driver: Option[string]): seq[Finding] =
  ## Report knoller pinning other than driver version; absent pin is `layout.nim`'s to report.
  if pin.isNone or driver.isNone or pin == driver: return
  result.add finding(
    path,
    0,
    "Project driver imports by path pins driver version `" & driver.get & "`, since koch " &
      "compiles it; got `" & pin.get & "`.",
  )
