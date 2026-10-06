## Replicate rules checker holds itself to, from `checker.nim` header.
##   Each fixture is one fault written down: dead routine, module without suite, verb set
##   drifting, and usage text leaving out option parser takes.

{.experimental: "strictFuncs".}

import std/[strutils, unittest]
import ../../src/[checker, markdown]


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


  test "exported routine of every keyword is collected, `method` among them, and fixed alike":
    # Case held: `ROUTINES` of `checker.nim` lacked `method`, so exported `method` nothing names
    #   was never dead, and its `*` never dropped (#557); domain is each keyword opening routine.
    for keyword in ["func", "proc", "iterator", "template", "macro", "converter", "method"]:
      let source = keyword & " area*(s: Shape): float = 1.0\n"
      check exportedRoutines(source) == @["area"]  # collected
      check checkDeadExports(["m.nim"], [source], []).len == 1  # dead where nothing names it
      check fixDeadExports("m.nim", source & "let x = area(s)\n", ["area"]).source ==
        keyword & " area(s: Shape): float = 1.0\nlet x = area(s)\n"  # `*` drops where called


  test "routine no other module and no suite names is dead, however it is called":
    let dead = "func gone*(): int = 1\n"
    check checkDeadExports(["m.nim"], [dead], []).len == 1
    # Own module's call is no reason to export: `*` marks intentional export alone.
    check checkDeadExports(["m.nim"], [dead & "let x = gone()\n"], []).len == 1
    # Call written either way counts, which is why identifier runs are scanned, not words.
    check checkDeadExports(["m.nim", "n.nim"], [dead, "let x = gone()\n"], []).len == 0
    check checkDeadExports(["m.nim", "n.nim"], [dead, "let x = tree.gone\n"], []).len == 0
    # Suite alone naming it keeps it: pure rules are covered by calling them directly.
    check checkDeadExports(["m.nim"], [dead], ["check gone() == 1\n"]).len == 0
    let found = checkDeadExports(["m.nim"], [dead], [])
    check found[0].path == "m.nim"
    check found[0].message.endsWith("got `gone`.")


  test "dead export drops its `*` where own module calls it, and stays where nothing does":
    let
      used = "func gone*(): int = 1\nfunc gone*(x: int): int = x  # Overload.\nlet y = gone()\n"
      unused = "func idle*(): int = 1  # `idle` named in comment alone.\n"
      dead = deadExports(["m.nim", "n.nim"], [used, unused], [])
    check dead == @[("m.nim", "gone"), ("m.nim", "gone"), ("n.nim", "idle")]
    let fix = fixDeadExports("m.nim", used, ["gone"])
    check fix.source == used.replace("gone*", "gone")  # every overload, call kept
    check fix.fixed.len == 2 and fix.fixed[0].line == 1
    check checkDeadExports(["m.nim", "n.nim"], [fix.source, unused], []).len == 1  # `idle` alone
    check fixDeadExports("m.nim", fix.source, ["gone"]).fixed.len == 0  # second fix: nothing
    check fixDeadExports("n.nim", unused, ["idle"]).source == unused  # delete is choice: stays


  test "every check module carries suite named after it":
    let paired = ["curator/audit/src/form.nim", "curator/audit/tests/suites/test_form.nim"]
    check checkSuites(paired).len == 0
    let alone = ["curator/audit/src/form.nim"]
    check checkSuites(alone).len == 1
    check checkSuites(alone)[0].message.endsWith(
      "`curator/audit/tests/suites/test_form.nim`; got nothing.",
    )
    check checkSuites(["koch.nim", "README.md"]).len == 0  # rule covers check modules only
    check moduleOf("curator/audit/src/form.nim") == "form"
    check moduleOf("curator/probe/src/probe.nim").len == 0  # other projects group differently


  test "verbs are read from dispatch, never from option parser above it":
    check KOCH.dispatchVerbs == @["ci", "tree"]  # `root` and `all` are options, not verbs
    check dispatchVerbs("proc run() = discard\n").len == 0


  test "one parser reads project driver too, since both drivers hold one shape":
    # koch learns which verbs project carries by reading its driver (`plan.nim`, `verbDirectories`),
    #   so line opening dispatch is given rather than fixed. Project cases over its first
    #   argument where koch cases over parsed options.
    const driver = """
when isMainModule:
  case paramStr(1)
  of "web": web()
  of "drive": drive()
  else:
    stderr.write USAGE
"""
    check driver.dispatchVerbs(DRIVER_CASE) == @["drive", "web"]
    check driver.dispatchVerbs.len == 0  # koch's own opening matches nothing here
    check KOCH.dispatchVerbs(DRIVER_CASE).len == 0  # and neither way round
    check dispatchVerbs("", DRIVER_CASE).len == 0  # project carrying no driver at all


  test "usage text and checks table must name what dispatch names":
    let
      usage = "Usage: koch <verb>\n\nVerbs:\n  ci    every check\n  tree  files\n\nOptions:\n"
      table = "## Checks reference\n\n| Command | Reads |\n|---|---|\n| `ci` | x |\n" &
        "| `tree` | y |\n"
    check (KOCH & usage).usageVerbs == @["ci", "tree"]  # first word of each indented line
    check checkVerbs(KOCH & usage, table).len == 0  # three statements, one set
    let short = "Usage: koch <verb>\n\nVerbs:\n  ci    every check\n\nOptions:\n"
    check checkVerbs(KOCH & short, table).len == 1  # usage short
    let stale = table & "| `audit` | retired |\n"
    check checkVerbs(KOCH & usage, stale).len == 1  # table keeps row for retired verb
    check checkVerbs(KOCH & usage, stale)[0].path == CURATOR_PATH


  test "usage text must print every option parser takes, and no other":
    let usage = "Usage: koch <verb>\n\nOptions:\n  --root:<dir>  root\n  --all  every\n\"\"\"\n"
    check KOCH.optionLabels == @["all", "root"]  # parser's branches, never dispatch's
    check (KOCH & usage).usageOptions == @["all", "root"]
    check checkOptions(KOCH & usage).len == 0  # two statements, one set
    let short = "Usage: koch <verb>\n\nOptions:\n  --root:<dir>  root\n\"\"\"\n"
    check checkOptions(KOCH & short).len == 1  # option parsed and never printed
    check checkOptions(KOCH & short)[0].path == KOCH_PATH
    let retired = "Usage: koch <verb>\n  --root:<dir> --all --gone\n\"\"\"\n"
    check checkOptions(KOCH & retired).len == 1  # option printed and never parsed
    # Text after usage block is not usage: header prose names options too.
    check (KOCH & usage & "## `--later` is prose\n").usageOptions == @["all", "root"]
    let hyphened = "Usage: koch <verb>\n  --dry-run  print\n\"\"\"\n"
    check hyphened.usageOptions == @["dry-run"]  # hyphen inside name is name


  test "knoller, which checker imports by path, is held to dead-export rule":
    check isExporting("curator/audit/src/layout.nim")  # check module
    check isExporting(KOCH_PATH)  # driver
    check isExporting("curator/knoller/src/knoller.nim")  # umbrella of knoller
    check isExporting("curator/knoller/src/knoller/tokens.nim")  # module of knoller
    check not isExporting("curator/knoller/tests/suites/test_tokens.nim")  # suite exports none
    check not isExporting("curator/probe/src/probe.nim")  # other project
    check isCalling("curator/audit/tests/suites/test_layout.nim")  # audit's suite calls
    check isCalling("curator/knoller/tests/suites/test_tokens.nim")  # knoller's suite calls
    check not isCalling("curator/knoller/src/knoller/tokens.nim")  # module is no suite


  test "only checks-reference table is read, since document tables others":
    # Repository map rows open with backticked paths and would otherwise read as verbs.
    let document = "## Repository map\n\n| Path | Who |\n|---|---|\n| `koch.nim` | curator |\n" &
      "\n## Checks reference\n\n| Command | Reads |\n|---|---|\n| `tree` | files |\n"
    check document.tableVerbs == @["tree"]
    # Header row survives, since only `|---|` rule is dropped; backtick filter is what
    #   separates verb rows from it.
    check document.section("## Checks reference").tableRows.len == 2
    check document.section("## Absent").len == 0


  test "mention of koch run as command names verb koch dispatches":
    # Fixture builds each mention from `KOCH_MARK`, so this file writes none it would report.
    let run = "`nim r " & KOCH_MARK & "tree`"
    check run.mentionedVerbs == @[(1, "tree")]  # compile-and-run form
    check ("x\n./" & KOCH_MARK & "ci --all").mentionedVerbs == @[(2, "ci")]  # built form, line 2
    check ("`" & KOCH_MARK & "tree <project>`").mentionedVerbs == @[(1, "tree")]  # code span
    check ("nim r --hints:off " & KOCH_MARK & "ci").mentionedVerbs == @[(1, "ci")]  # options
    # Prose naming koch itself is no command, nor is placeholder.
    check "Nim's own `koch` holds dispatch; koch reads it.".mentionedVerbs.len == 0
    check ("`" & KOCH_MARK & "<verb>`").mentionedVerbs.len == 0  # placeholder
    check ("nim r x " & KOCH_MARK & "ci").mentionedVerbs.len == 0  # word between is no option
    let stale = checkMentions("GUIDE.md", "a\n" & run.replace("tree", "gone"), ["ci", "tree"])
    check stale.len == 1  # verb koch does not dispatch
    check stale[0].path == "GUIDE.md" and stale[0].line == 2
    check stale[0].message.endsWith("got `gone`.")
    check checkMentions("GUIDE.md", run, ["ci", "tree"]).len == 0  # dispatched verb passes
