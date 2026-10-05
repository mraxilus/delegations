## Drive measurement of this project: `nim r tools/build.nim <command>`.
##   Koch runs suites and holds no verb for instruments, so project carries its own driver
##   (CONTRIBUTOR.md, "Directories inside your project are yours"), one level down from koch.
##   This file dispatches, and imports `std/` alone: `koch check-types` runs its `types` on
##     koch's compiler, and type check compiles no project code (CONTRIBUTOR.md, TypeScript and
##     Node). `types` and `system` run here. Every other verb runs in `tools/verbs.nim`,
##     through `nim r` on compiler on PATH, which koch sets to pin, so project code compiles on
##     pin alone.
##     Rejected: one driver importing project modules, which `check-types` then compiled on
##     koch's compiler rather than pin.
##     Cost: second program, compiled again whenever its sources change.
##
##   |-----------|----------------------------------------------------------------------|
##   | Command   | Effect                                                               |
##   |-----------|----------------------------------------------------------------------|
##   | inspect   | compile bench entry per algebra to C, read it, write static          |
##   |           | measurements as `build/static_<algebra>.json`                        |
##   | bench     | compile and run bench per algebra, plain ones five times alternating |
##   |           | then instrumented, record runtime measurements as                    |
##   |           | `baseline/runtime_<algebra>.json`                                    |
##   | baseline  | inspect, then record static measurements as                          |
##   |           | `baseline/static_<algebra>.json`                                     |
##   | guard     | compare last inspect against baseline; any count grown is finding    |
##   | evaluate  | try one change or proposal at pin, `stale` ones, or `all`, and       |
##   |           | record what each measured as `evaluations/<name>.json`; typed        |
##   |           | algebras alone, or all four after `--thorough`                       |
##   | restamp   | move every timed record to pin where its builds emit C it was        |
##   |           | timed on, keep its times, and take every other figure of each        |
##   |           | evaluation again; finding where C differs (`head.nim`)               |
##   | pages     | build every page from committed files into `build/<name>.html`       |
##   | types     | type-check harness `tools/drive/`, and emit it into `build/drive/`;  |
##   |           | no browser, no page                                                  |
##   | published | record URL and digest of page just published, as                     |
##   |           | `published docket <url>`, in `pages/published.json`                  |
##   | drive     | inspect, guard, hold `gaps.md` to regeneration, and hold every       |
##   |           | measurement, evaluation, file, page and checkout to pin (`head.nim`) |
##   |           | then `types`, render every page as host serves it, and fail where    |
##   |           | face of system draws character beyond ASCII, or where control page   |
##   |           | raises other findings than it expects (`render.nim`)                 |
##   | head      | compare pin with library head; finding where library moved since     |
##   | gaps      | regenerate `gaps.md` and docket from committed baselines             |
##   | show      | print one function's emitted C, its counts, its movement and its     |
##   |           | machine code, as `show ∧` or `show ⟇ cga5d`                          |
##   | sweep     | time general measurands at two to six dimensions, rigid, and record  |
##   |           | them in `baseline/sweep.json`; never in CI                           |
##   | system    | print system packages build needs, one per line, for caller          |
##   | clean     | remove `build`                                                       |
##   |-----------|----------------------------------------------------------------------|
##   Exit: 0 done, 1 command failed or finding, 2 usage error.
##     `nim r` exits 1 for any program that fails, so this file checks usage before handing on.
##   Cost: `types` and `drive` need node and npm, and `drive` needs Chromium, which `browser`
##     fetches unless `PGA_CHROMIUM` names one.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import std/[os, osproc]


const
  PATH_VERBS = "tools" / "verbs.nim"
    ## Program every verb but `types` and `system` runs in, on compiler on PATH.
  PATH_TSCONFIG = "tsconfig.json"  ## Type-checker configuration of harness.
  VARIABLE_CHROMIUM = "PGA_CHROMIUM"
    ## Environment variable naming Chromium to drive; empty fetches Playwright's own.
  SYSTEM = [
    ("git", "read library head and trees `drive` holds pin to"),
    ("curl", "fetch faces asked of shared store, one level down through `koch fetch-assets`"),
    ("binutils", "`objdump` disassembles object files `show` reads machine code from"),
    ("coreutils", "`sha256sum` store checks those faces with"),
    ("nodejs", "run type-checker `types` drives and harness `drive` runs"),
  ]
    ## System packages build needs beyond compiler.
    ##   Compiler is toolchain, pinned in nimble file.
    ##   Library is Atlas checkout, pinned in lock.
    ##   Faces come from repository's store.
    ##   Type-checker and Playwright are node packages, pinned by `package-lock.json`.
  USAGE = "Usage: nim r tools/build.nim " &
      "<inspect|bench|baseline|guard|evaluate|restamp|pages|types|published|drive|head|gaps|show|" &
      "sweep|system|clean> [name|symbol] [url|algebra|--thorough]\n"
    ## Text printed on usage error; trailing words serve `evaluate`, `published` and `show`.
  FLAG_THOROUGH = "--thorough"  ## Flag after `evaluate <name>` that measures 2D algebras too.



#[ Processes ]#

proc runStatus(command: string, arguments: openArray[string]): int =
  ## Run command with arguments from project directory; exit code.
  ##   Twin of `runStatus` in `tools/verbs.nim`: this file imports `std/` alone, so shares none.
  let process = startProcess(command, args = arguments, options = {poUsePath, poParentStreams})
  result = process.waitForExit
  process.close


proc run(command: string, arguments: openArray[string]) =
  ## Run command with arguments from project directory; raise on non-zero exit.
  let code = runStatus(command, arguments)
  if code != 0:
    raise newException(OSError, command & " failed; got exit `" & $code & "`.")


proc delegated(): int =
  ## Run verb command line names in `tools/verbs.nim`, with its arguments; exit code of run.
  ##   Compiler is one on PATH, which koch sets to pin, so project code compiles on pin alone.
  var arguments = @["r", "--hints:off", PATH_VERBS]
  for index in 1..paramCount(): arguments.add paramStr(index)
  runStatus("nim", arguments)



#[ Commands ]#

proc types() =
  ## Type-check harness, and emit it into `build/drive/`; no browser, no page, no Nim.
  run("npx", ["tsc", "--project", PATH_TSCONFIG])


proc browser() =
  ## Fetch Chromium Playwright pins, unless `PGA_CHROMIUM` names browser outright.
  ##   Pin is version: `package-lock.json` fixes `@playwright/test`, and version fixes browser
  ##   revision. Playwright publishes no checksum, so bytes arrive on TLS alone.
  ##   Costs nothing warm: `playwright install` keeps build already at pinned revision.
  let named = getEnv(VARIABLE_CHROMIUM)
  if named.len > 0:
    echo "Kept ", named, ", named by ", VARIABLE_CHROMIUM
    return
  run("npx", ["playwright", "install", "chromium"])


proc system() =
  ## Print every system package this build needs, one per line and nothing else.
  for (package, _) in SYSTEM: echo package



#[ Entry Point ]#

proc main(): int =
  ## Run verb named on command line; exit code, 2 on usage error and 1 on failure.
  let
    verb = if paramCount() > 0: paramStr(1) else: ""
    arguments =
      case verb
      of "show": 2..3
      of "evaluate": 2..3
      of "published": 3..3
      else: 1..1
  if paramCount() notin arguments or
      (verb == "evaluate" and paramCount() == 3 and paramStr(3) != FLAG_THOROUGH):
    stderr.write USAGE
    return 2
  try:
    case paramStr(1)
    of "show": return delegated()
    of "inspect": return delegated()
    of "bench": return delegated()
    of "baseline": return delegated()
    of "guard": return delegated()
    of "evaluate": return delegated()
    of "restamp": return delegated()
    of "pages": return delegated()
    of "types": types()
    of "published": return delegated()
    of "drive":
      # Ready harness and browser here, so `drive` there compiles project code once.
      types()
      browser()
      return delegated()
    of "head": return delegated()
    of "gaps": return delegated()
    of "sweep": return delegated()
    of "system": system()
    of "clean": return delegated()
    else:
      stderr.write USAGE
      return 2
  except CatchableError as e:
    stderr.write e.msg & "\n"
    return 1
  0


when isMainModule:
  quit main()
