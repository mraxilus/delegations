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
##   Rejected: `requires "nim >= x"`, which cannot express upper bound project needs;
##     separate `.nim-version` file, second place version lives beside nimble file naming
##     one already.
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
  VERSION_CHARS = Digits + {'.'}
    ## Characters version string is built from.


func isVersion*(s: string): bool =
  ## Decide whether `s` is dotted version, i.e. digit runs separated by single dots.
  if s.len == 0 or not s.allCharsInSet(VERSION_CHARS): return false
  for part in s.split('.'):
    if part.len == 0: return false
  true


func nimPin*(nimble: string): Option[string] =
  ## Read exact Nim version pinned by nimble text; `none` when absent or inexact.
  for requirement in nimble.requireLiterals:
    if requirement.packageName.toLowerAscii != NIM: continue
    let rest = requirement[requirement.packageName.len .. ^1].strip
    if not rest.startsWith(EXACT): return none(string)
    let version = rest[EXACT.len .. ^1].strip
    return if version.isVersion: some(version) else: none(string)
  none(string)


func checkPin*(path, nimble: string): seq[Finding] =
  ## Report nimble file carrying no exact Nim pin.
  if nimble.nimPin.isNone:
    result.add finding(
      path, 0,
      "Nimble file must pin compiler exactly as `requires \"" & NIM & " " & EXACT &
        " <version>\"`; ranges cannot record what was verified; got `" &
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
  ## Report workflow driver version disagreeing with driver project's pin.
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


func checkRunning*(dir, pin, running: string): seq[Finding] =
  ## Report compiler on PATH differing from project's pin.
  if pin != running:
    result.add finding(
      dir, 0,
      "Compiler differs from project pin `" & pin & "`; install it, then run again; got `" &
        running & "`.",
    )


proc runningVersion*(): string =
  ## Read version of `nim` on PATH, i.e. compiler testament will invoke; empty when absent.
  let (output, code) = execCmdEx("nim --version")
  if code != 0: return ""
  for word in output.splitLines[0].splitWhitespace:
    if word.isVersion: return word
  ""
