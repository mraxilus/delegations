## Drive every project's tests through testament (Article IX.6) and run tools in projects.
##   One verb per project: `testament pattern "tests/t*.nim"` in project directory, with
##   compiler named by absolute path so testament resolves it from any cwd. Output streams
##   through untouched; failure becomes finding at project's tests directory.
##   Rejected: per-project build file (make, config.nims), which repeats one line per
##     project and adds second toolchain or compiler-VM glue; koch holds verb once.
##
##   Each project carries `Target`, i.e. its directory and `bin` of toolchain serving its
##     pin. Tools come from that `bin`, never from PATH: two projects on two pins would
##     otherwise share one compiler silently, which is defect this replaced. Empty `bin`
##     names PATH, which is what CI installs per job.
##   Testament and Atlas come from same `bin` as compiler, since each Nim ships its own and
##     Atlas records compiler it ran under; mixing them reports environment mismatch.
##
##   Cost: projects and their stubs run serially. One testament per stub, four at once, cut
##     `dance_ontology` less `trigid` from 52 s to 17 s; not adopted, since concurrent runs
##     share `testresults/` and interleave output, and slowest stub bounds project anyway.
##   Cost: project in other language needs its own runner arm here (none exists yet).

{.experimental: "strictFuncs".}

import std/[os, osproc, streams, strtabs, strutils]
from ../../knoller/src/knoller import NIM
import ./[findings, font_stacks]


const
  FILE_DRIVER* = "tools/build.nim"  ## Build driver project carries, holding verbs koch has none of.
  VERB_TYPES* = "types"
    ## Verb type-checking project's own scripts, deriving what they read first, and
    ## stopping before anything needing browser. Named here and in CONTRIBUTOR.md.
  VERB_DRIVEN* = "drive"
    ## Verb building project's page and driving it through real events. Project gains driven
    ## checks by carrying this verb and nothing else (`plan.nim`, `directoriesVerb`).
  VERB_HEAD* = "head"
    ## Verb holding project's pin to outside reference that moves without commit here, such as
    ## head of library repository. Its verdict varies with that reference, so it runs daily in
    ## `head.yml` and never where merge waits (CONTRIBUTOR.md, Tests are paramount).
  VERB_SYSTEM* = "system"
    ## Verb printing system packages project needs, one bare name per line, for caller to
    ## install. Named here and in CONTRIBUTOR.md, "System dependencies".
  SYSTEM_KOCH* = [
    ("git", "tree is what git lists, and `check` fetches base to compare against"),
    ("curl", "compiler pin nothing on machine serves is downloaded"),
    ("tar", "that download is archive, and unpacking it is what makes it toolchain"),
    ("coreutils", "`sha256sum` checking it against digest published beside it"),
    ("libbrotli1", "`drive` reads `cmap` of `woff2` font face page ships, in one Brotli stream"),
  ]
    ## System packages koch itself needs, whatever any project declares. Same shape rule asks
    ## of every project, kept by driver that enforces it: declaration is data carrying its
    ## reason, and `koch list-packages` prints it.
    ##   Nim is not here: it is toolchain koch runs under rather than package machine installs,
    ##   and `compilers.nim` of knoller resolves each pin itself. npm is not here either -- it is
    ##   needed where project carries node manifest, so it belongs to that project rather than to
    ##   koch, and `restoreNode` reports its absence by name.
    ##   `libbrotli1` serves koch's `drive`, which reads font faces each project's pages ship,
    ##   and suite of `assets.nim` too (`font_files.nim`). Drive job installs what project
    ##   declares, so project whose pages ship `woff2` declares it as well.


type Target* = object  ## Define one project to run, with toolchain serving its pin.
  directory*: string  ## Project directory, repository-relative.
  bin*: string  ## Directory holding compiler and its tools; empty names PATH.


func pathTool*(bin, tool: string): string =
  ## Read path tool would have inside toolchain; bare name when `bin` names PATH.
  if bin.len == 0: tool else: bin / tool


proc toolIn*(bin, tool: string): string =
  ## Read program to run for tool, falling back to PATH when toolchain carries none.
  ##   Source build carries whatever tools Nim's own `koch` produced, and that set moves
  ##   between Nim versions; naming absent file would raise rather than report, and PATH tool
  ##   still works, announcing its own mismatch where one matters.
  let path = bin.pathTool(tool)
  if bin.len == 0 or fileExists(path): path else: tool


proc pathNim*(bin: string): string =
  ## Read compiler path testament must be told, absolute so any cwd resolves it.
  if bin.len == 0: findExe(NIM) else: bin / NIM


proc envChild(bin: string): StringTableRef =
  ## Build environment putting toolchain first on PATH; `nil` inherits this process's own.
  ##   Naming tool by path is not enough: Atlas resolves `nim` through PATH, so toolchain's
  ##   own Atlas still reads whichever compiler PATH holds and reports environment mismatch
  ##   against lock (measured 2026-09-06, same Atlas warning appearing under one PATH and
  ##   silent under other).
  if bin.len == 0: return nil
  result = newStringTable(modeCaseSensitive)
  for key, value in envPairs(): result[key] = value
  result["PATH"] = bin & PathSep & getEnv("PATH")


proc runIn*(directory, program: string; arguments: openArray[string]; bin = ""): int =
  ## Run program with arguments in directory, output streamed; return exit code.
  ##   Toolchain `bin` leads child's PATH, so tools it shells out to are its own.
  let process = startProcess(
    program,
    args = arguments,
    workingDir = directory,
    env = envChild(bin),
    options = {poUsePath, poParentStreams},
  )
  result = process.waitForExit
  process.close


proc linesIn*(
  directory, program: string; arguments: openArray[string]; bin = ""
): tuple[lines: seq[string], code: int, failure: string] =
  ## Run program with arguments in directory; read its stdout as lines, empty on non-zero exit,
  ##   its exit code, and last line of its stderr.
  ##   Streaming variant above is for checks, whose product is their verdict; this is for
  ##   verb whose product is its output.
  ##   Line carrying whitespace is dropped: contract is one bare name per line, and only
  ##   thing else reaching this stream is compiler complaining, which always spells position
  ##   before its message.
  ##   Stderr is read once stdout ends, and its last line kept: compiler says there why driver
  ##     failed, so caller names it. Cost: program writing pipe's worth to stderr before it
  ##     closes stdout waits on that pipe, which is read after.
  let process = startProcess(
    program,
    args = arguments,
    workingDir = directory,
    env = envChild(bin),
    options = {poUsePath},
  )
  defer: process.close
  let
    output = process.outputStream.readAll
    failure = process.errorStream.readAll
  result.code = process.waitForExit
  for line in failure.splitLines:
    if line.strip.len > 0: result.failure = line.strip
  if result.code != 0: return
  for line in output.splitLines:
    let s = line.strip
    if s.len > 0 and not s.contains({' ', '\t'}): result.lines.add s


proc runVerb(root: string; targets: openArray[Target]; verb, failed: string): seq[Finding] =
  ## Run one verb of each project's driver, on toolchain its pin names; exit other than 0 is
  ##   finding against driver, carrying that code.
  for target in targets:
    echo "== " & target.directory
    let code = runIn(
      root / target.directory,
      target.bin.pathNim,
      ["r", "--hints:off", FILE_DRIVER, verb],
      target.bin,
    )
    if code != 0:
      result.add finding(
        target.directory & "/" & FILE_DRIVER,
        0,
        Check.VerbProject,
        failed & "; got exit `" & $code & "`.",
      )


proc runTypes*(root: string, targets: openArray[Target]): seq[Finding] =
  ## Type-check each project's own scripts, through build driver that project carries.
  ##   Verb is project's, never koch's: what type-checking needs differs per project, and
  ##   driver already derives its declarations first. koch names verb and nothing else.
  runVerb(root, targets, VERB_TYPES, "Type check failed")


proc runDriven*(root: string, targets: openArray[Target]): seq[Finding] =
  ## Drive each project's built page through real events, through driver that project carries,
  ##   then judge font faces its pages draw (`font_stacks.nim`).
  ##   Same shape as `runTypes` one step further along: verb is project's, koch names it and
  ##   nothing else. What that verb builds first, and what browser it reaches for, is project's
  ##   own business (CONTRIBUTOR.md, "System dependencies").
  ##   Control page is written before verb, which reads it. Verdict follows verb that passed:
  ##     verb that failed may leave its file half written, and its run is red already.
  for target in targets:
    writeControl(root, target.directory)
    let failed = runVerb(root, [target], VERB_DRIVEN, "Driven checks failed")
    result.add failed
    if failed.len == 0: result.add checkFontFaces(root, target.directory)


proc runHead*(root: string, targets: openArray[Target]): seq[Finding] =
  ## Hold each project's pin to its outside reference, through driver that project carries.
  ##   Verb prints its own finding; koch adds exit code alone, so workflow posting output
  ##   posts what project said.
  runVerb(root, targets, VERB_HEAD, "Head check failed")


proc packagesSystem*(
  root: string, targets: openArray[Target]
): tuple[packages: seq[string], failed: seq[Finding]] =
  ## Read system packages every project declares, through each project's own verb, and finding
  ##   naming each driver that fails.
  ##   Read rather than listed: workflow installing these names no project, exactly as it
  ##   names none for compiler matrix, so package arrives by being declared.
  ##   Driver that fails gives no package and one finding, with its exit code and last line of
  ##     its stderr; nothing raises, since caller installs what each other driver declares.
  ##     Rejected: failure giving nothing and no finding, since `koch list-packages` then prints
  ##     nothing and exits 0, so run installs none and stops at tool it lacks (#934).
  for target in targets:
    let (lines, code, failure) = linesIn(
      root / target.directory,
      target.bin.pathNim,
      ["r", "--hints:off", FILE_DRIVER, VERB_SYSTEM],
      target.bin,
    )
    if code != 0:
      let said = if failure.len > 0: " and `" & failure & "`" else: ""
      result.failed.add finding(
        target.directory & "/" & FILE_DRIVER,
        0,
        Check.PackagesSystem,
        "System packages unread, since driver failed; got exit `" & $code & "`" & said & ".",
      )
    for package in lines:
      if package notin result.packages: result.packages.add package


proc runTests*(root: string, targets: openArray[Target]): seq[Finding] =
  ## Run testament over `tests/t*.nim` in each project, each on toolchain its pin names.
  ##   Pattern covers `test_<name>.nim` (Article V.9) and older `t<name>.nim` alike, until
  ##     every project carries full form.
  for target in targets:
    echo "== " & target.directory
    let code = runIn(
      root / target.directory,
      target.bin.toolIn("testament"),
      ["--nim:" & target.bin.pathNim, "pattern", "tests/t*.nim"],
      target.bin,
    )
    if code != 0:
      result.add finding(
        target.directory & "/tests",
        0,
        Check.Testament,
        "Testament failed; got exit `" & $code & "`.",
      )
