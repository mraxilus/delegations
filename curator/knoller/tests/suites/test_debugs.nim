## Hold that code leaves no debug output (Article VIII.5), as Architect ruled on rule 19 of #443:
##   knoller fixes none, since fix would change what code prints, and warns of each build-time
##   printer and `debugEcho`, in any file, and of `echo` at top level of library module. Warning
##   fails no check, as fence's warning does.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, tables, unittest]
import ../../src/knoller/[command, idioms, reports]


const
  CLEAN = "## Do.\n\n{.experimental: \"strictFuncs\".}\n\nexpandMacros:\n  defineMultivectors()\n"
    ## Module whose build-time printer breaks no rule of knoller but debug output.
  MULTIVECTORS = "\nexpandMacros:\n  defineMultivectors()\n"
    ## Lines 82 to 84 of `pga/multivectors.nim` of PGA library at `3d9696e`: each build prints
    ##   type section macro emits, and nothing reads it.
  NIMBLE = "pga.nimble"  ## Nimble file of package, at its root.
  WARNING = "code leaves no debug output, which nothing reads; got `"
    ## Opening of message of each warning.


func warned(path, source: string): seq[(int, string)] =
  ## Read line and message of each warning of debug output in source at path.
  warnDebug(path, source, NIMBLE).mapIt((it.line, it.brief))


func ran(is_check: bool): Outcome =
  ## Run command line on `CLEAN`, as check or as fix.
  outcome(
    [("pga/multivectors.nim", CLEAN)], [], is_check,
    nimbles = {"pga/multivectors.nim": NIMBLE}.toTable,
  )



suite "Debug output":
  test "build-time printer of library warns, and fix leaves it":
    check warned("pga/multivectors.nim", MULTIVECTORS) == @[(2, WARNING & "expandMacros:`")]
    for (source, got) in [
      ("dumpTree:\n  a\n", "dumpTree:"),
      ("dumpLisp:\n  a\n", "dumpLisp:"),
      ("macro m(): untyped =\n  ## Make.\n  dumpAstGen(body)\n", "dumpAstGen(body)"),
      ("macro m(n: untyped): untyped =\n  ## Make.\n  echo n.treeRepr\n", "echo n.treeRepr"),
      ("macro m(n: untyped): untyped =\n  ## Make.\n  echo n.lispRepr\n", "echo n.lispRepr"),
      ("macro m(n: untyped): untyped =\n  ## Make.\n  echo n.astGenRepr\n", "echo n.astGenRepr"),
      ("proc p() =\n  ## Do.\n  debugEcho x\n", "debugEcho x"),
    ]:
      check warned("pga/a.nim", source).mapIt(it[1]) == @[WARNING & got & "`"]
      check warned("tests/test_a.nim", source).len == 1  # printer warns in tests too
      check warned("config.nims", source).len == 1  # and in script
      check warned(NIMBLE, source).len == 1  # and in nimble file
    check ran(is_check = false).written.len == 0  # fix writes none of it


  test "echo at top level of library module warns, and echo of tool, test or entry passes":
    check warned("pga/a.nim", "echo \"loaded\"\n") == @[(1, WARNING & "echo \"loaded\"`")]
    for (path, source) in [
      ("pga/a.nim", "proc p() =\n  ## Do.\n  echo x\n"),  # inside routine: output of tool
      ("pga/a.nim", "macro m(n: untyped): untyped =\n  ## Make.\n  echo n.repr\n"),  # by `repr`
      ("pga/a.nim", "# echo x\n"),  # commented out: no code
      ("pga/a.nim", "echo x\n\nwhen isMainModule:\n  discard\n"),  # program, no library
      ("pga/a.nim", "echo x\nif FAILURES.len > 0: quit 1\n"),  # program, as it quits at top level
      ("tools/a.nim", "echo x\n"),
      ("tests/test_a.nim", "echo x\n"),  # rule of tests reads it
      ("pga.nimble", "echo x\n"),  # task of package prints
    ]:
      check warned(path, source).len == 0


  test "command line prints each warning, which changes no exit code":
    let outcome = ran(is_check = true)
    check outcome.lines.anyIt(it.startsWith("pga/multivectors.nim:5: debug-output warning: ") and
      "message=\"code leaves no debug output" in it)
    check not outcome.lines.anyIt("debug-output: " in it)  # warning, never finding
    check outcome.code == 0  # source breaks no other rule, so warning stands alone
