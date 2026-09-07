discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Replicate rules checker holds itself to, from `checker.nim` header.
##   Each rule here is one curator pass of 2026-09-06 found by reading, so each fixture
##   is that fault written down: dead routine, module without suite, verb set drifting.

import std/[strutils, unittest]
import ../src/[markdown, checker]


const KOCH = """
proc parseOptions(): Option[Options] =
  for kind, key, value in getopt():
    case key
    of "root": options.root = value
    of "all": options.is_all = true
    else: return none(Options)

proc run(options: Options): int =
  case options.command
  of "tree":
    found = auditTree(tree)
  of "ci":
    found = runJobs(root)
  else:
    stderr.write USAGE
"""
  ## Driver shape: option parser cases over labels before dispatch cases over verbs.


suite "Checker":
  test "exported routines are collected, and operators are left alone":
    check exportedRoutines("func isPin*(s: string): bool =\n").len == 1
    check exportedRoutines("proc render*(f: Finding): string =\n") == @["render"]
    check exportedRoutines("func hidden(s: string): bool =\n").len == 0  # unexported
    # Indentation does not disqualify: `when` block indents routines that are still
    #   top-level, and Nim rejects export at any depth that is not.
    check exportedRoutines("  func guarded*(): int =\n").len == 1
    # Operator is spelled where used, never named, so counting identifiers cannot find it.
    check exportedRoutines("func `<`*(a, b: Finding): bool =\n").len == 0

  test "routine nothing names is dead, however it is called":
    let dead = "func gone*(): int = 1\n"
    check checkDeadExports(["m.nim"], [dead]).len == 1
    # Call written either way counts, which is why identifier runs are scanned, not words.
    check checkDeadExports(["m.nim"], [dead & "let x = gone()\n"]).len == 0
    check checkDeadExports(["m.nim"], [dead & "let x = tree.gone\n"]).len == 0
    # Caller may sit in another module of checker.
    check checkDeadExports(["m.nim", "n.nim"], [dead, "let x = gone()\n"]).len == 0
    let found = checkDeadExports(["m.nim"], [dead])
    check found[0].path == "m.nim"
    check found[0].message.endsWith("got `gone`.")

  test "every check module carries suite named after it":
    let paired = ["curator/audit/src/form.nim", "curator/audit/tests/tform.nim"]
    check checkSuites(paired).len == 0
    let alone = ["curator/audit/src/form.nim"]
    check checkSuites(alone).len == 1
    check checkSuites(alone)[0].message.endsWith("`curator/audit/tests/tform.nim`; got nothing.")
    check checkSuites(["koch.nim", "README.md"]).len == 0  # rule covers check modules only
    check moduleOf("curator/audit/src/form.nim") == "form"
    check moduleOf("curator/probe/src/probe.nim").len == 0  # other projects group differently

  test "verbs are read from dispatch, never from option parser above it":
    check KOCH.dispatchVerbs == @["ci", "tree"]  # `root` and `all` are options, not verbs
    check dispatchVerbs("proc run() = discard\n").len == 0

  test "one parser reads project driver too, since both drivers hold one shape":
    # koch learns which verbs project carries by reading its driver (`plan.nim`, `verbDirs`),
    #   so line opening dispatch is given rather than fixed. Project cases over its first
    #   argument where koch cases over parsed options.
    const DRIVER = """
when isMainModule:
  case paramStr(1)
  of "web": web()
  of "drive": drive()
  else:
    stderr.write USAGE
"""
    check DRIVER.dispatchVerbs(DRIVER_CASE) == @["drive", "web"]
    check DRIVER.dispatchVerbs.len == 0  # koch's own opening matches nothing here
    check KOCH.dispatchVerbs(DRIVER_CASE).len == 0  # and neither way round
    check dispatchVerbs("", DRIVER_CASE).len == 0  # project carrying no driver at all

  test "usage text and checks table must name what dispatch names":
    let usage = "Usage: koch <ci|tree> [project]\n"
    let table = "## Checks reference\n\n| Command | Reads |\n|---|---|\n| `ci` | x |\n" &
      "| `tree` | y |\n"
    check checkVerbs(KOCH & usage, table).len == 0  # three statements, one set
    check checkVerbs(KOCH & "Usage: koch <ci> [project]\n", table).len == 1  # usage short
    let stale = table & "| `audit` | retired |\n"
    check checkVerbs(KOCH & usage, stale).len == 1  # table keeps row for retired verb
    check checkVerbs(KOCH & usage, stale)[0].path == CURATOR_PATH

  test "only checks-reference table is read, since document tables others":
    # Repository map rows open with backticked paths and would otherwise read as verbs.
    let document = "## Repository map\n\n| Path | Who |\n|---|---|\n| `koch.nim` | curator |\n" &
      "\n## Checks reference\n\n| Command | Reads |\n|---|---|\n| `tree` | files |\n"
    check document.tableVerbs == @["tree"]
    # Header row survives, since only `|---|` rule is dropped; backtick filter is what
    #   separates verb rows from it.
    check document.section("## Checks reference").tableRows.len == 2
    check document.section("## Absent").len == 0
