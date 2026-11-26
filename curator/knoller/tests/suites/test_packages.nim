## Replicate names of package that rules of one file take from caller (`packages.nim`), as
##   command line reads them: modules of run by nimble file of their package, library each
##   package builds on by `--path` of its `nim.cfg`, and rename of name cut through semantic pass,
##   joined with case rename of same declaration (rules 8, 9 and 15 of #443).

{.experimental: "strictFuncs".}

import std/[os, osproc, sequtils, strutils, tables, tempfiles, unittest]
import ../../src/knoller/[command, compilers, packages, rules]
from ../../src/knoller/command {.all.} import modulesLibrary, nimblesNearest, pathConfigured


const
  ALGEBRA =
    "{.experimental: \"strictFuncs\".}\n\n" &
    "type Chiral*[T] = object  ## Pair of sides.\n" &
    "  left*, right*: T  ## Side.\n\n" &
    "template vector*[G: Grade | GradeAnti](t: typedesc[G]): G = G(1)\n" &
    "  ## Alias grade of vectors.\n"
    ## Module of package declaring wrapper (V.7) and alias (V.8).
  USES =
    "{.experimental: \"strictFuncs\".}\n\n" &
    "let LEFT_NAME* = Grade(1)  ## Name.\n"
    ## Module using landmark index bare, whose global opens with axis value.


proc writeTree(root: string, files: openArray[(string, string)]) =
  ## Write each file under root, path then text, creating its directory.
  for (path, text) in files:
    createDir((root / path).parentDir)
    writeFile(root / path, text)



suite "Names of package":
  test "names come from modules of run, by nimble file of package, and reach its files alone":
    let
      files = [("p/src/algebra.nim", ALGEBRA), ("p/src/uses.nim", USES), ("q/src/uses.nim", USES)]
      nimbles = {"p/src/algebra.nim": "p/p.nimble", "p/src/uses.nim": "p/p.nimble",
                 "q/src/uses.nim": "q/q.nimble"}.toTable
      outcome = outcome(files, [], is_check = false, nimbles = nimbles)
      written = outcome.written.toTable
    check "Grade.vector" in written["p/src/uses.nim"]  # alias of package
    check "q/src/uses.nim" notin written  # other package declares no alias
    check "p/src/uses.nim:3: landmark-alias fixed" in outcome.lines
    check "p/src/uses.nim:3: name-cut: actual=\"LEFT_NAME\" message=\"name opens with head, " &
      "axis value `left` last\"" in outcome.lines  # rename needs semantic pass, which no plan gave
    check not outcome.lines.anyIt(it.startsWith("q/src/uses.nim:3: name-cut"))  # no wrapper
    let names = namesPackage([ALGEBRA, USES])
    check names.axes == @["left", "right"]
    check names.landmarks.mapIt((it.name, it.index, it.aliases)) ==
      @[("Grade", "1", @["vector"]), ("GradeAnti", "1", @["vector"])]  # body of no `when`
    check "chiral" in names.words and "name" in names.words


  test "what fixers leave reports by check of chain, and fence names rule of package names":
    # Domain: alias that would widen its line past `LINE_MAX`, generic `to<Target>` of compound
    #   argument, and bare index inside fence; each stays as written, and reports as left or in
    #   warning of its fence.
    let
      kept =
        "{.experimental: \"strictFuncs\".}\n\n" &
        "let g = " & 'x'.repeat(81) & " + Grade(1)\n" &  # 100 runes, and alias gives 104
        "let h = (a + b).toX[int]\n" &
        "#!fix off\nlet f = Grade(1)\n#!fix on\n"
      files = [("p/src/algebra.nim", ALGEBRA), ("p/src/kept.nim", kept)]
      nimbles = {"p/src/algebra.nim": "p/p.nimble", "p/src/kept.nim": "p/p.nimble"}.toTable
      lines = outcome(files, [], is_check = true, nimbles = nimbles).lines
    check "p/src/kept.nim:3: landmark-alias: actual=\"Grade(1)\" message=\"landmark index " &
      "stands as its alias, `Grade.vector`\"" in lines
    check "p/src/kept.nim:4: conversion-prefix: actual=\"(a + b).toX\" message=\"conversion " &
      "of compound argument is prefix call, as `toMultivector(a + b)`\"" in lines
    check lines.anyIt(it.startsWith("p/src/kept.nim:5: fence-held warning:") and
      "landmark-alias" in it)


  test "library package builds on gives aliases, by `--path` of `nim.cfg` beside nimble file":
    check pathConfigured("--path:\"dependencies/x\"") == "dependencies/x"
    check pathConfigured("--path:lib") == "lib"
    check pathConfigured("  -p:lib") == "lib"
    check pathConfigured("path = \"lib\"") == "lib"
    check pathConfigured("--define:\"pga.dimensions=4\"") == ""
    check pathConfigured("--paths:lib") == ""
    let root = createTempDir("knoller_", "_library")
    defer: removeDir(root)
    root.writeTree([
      ("p/p.nimble", "version = \"0.1.0\"\n"),
      ("p/nim.cfg", "--path:\"lib\"\n--path:\"missing\"\n--path:\"$nim\"\n--define:\"x\"\n"),
      ("p/lib/algebra.nim", ALGEBRA),
      ("p/src/uses.nim", USES),
    ])
    let
      nimbles = nimblesNearest(["p/src/uses.nim"], root)
      libraries = nimbles.modulesLibrary
    check toSeq(libraries.values) == @[@[ALGEBRA]]  # missing directory and variable read none
    let outcome = outcome(
      [("p/src/uses.nim", USES)], [], false, root, nimbles = nimbles, libraries = libraries
    )
    check outcome.written.len == 1 and "Grade.vector" in outcome.written[0][1]
    check "p/src/uses.nim:3: name-cut: actual=\"LEFT_NAME\" message=\"name opens with head, " &
      "axis value `left` last\"" notin outcome.lines  # wrapper of library is no axis value


  test "cut rename goes through semantic pass, joins case rename, and refused rename warns":
    # Case held: `𝐦_grade`, `left_name` and `antiscalar`, lines 392 of `tests/suites.nim`, 45 of
    #   `pga/emitters.nim` and 173 of `tests/suites.nim` of PGA library at `3d9696e` (rule 8 of
    #   #443); `scalar_anti` reads as template `scalarAnti`, so its rename is refused.
    let root = createTempDir("knoller_", "_cuts")
    defer: removeDir(root)
    const source =
      "{.experimental: \"strictFuncs\".}\n\n" &
      "type Chiral*[T] = object  ## Pair of sides.\n" &
      "  left*, right*: T  ## Side.\n\n" &
      "template scalarAnti*(t: typedesc[int]): int = 1\n  ## Antiscalar.\n\n" &
      "proc f*(left_name: string, rightName: int): string =\n" &
      "  ## Join.\n" &
      "  let 𝐦_grade = left_name & $rightName\n" &
      "  let antiscalar = int.scalarAnti\n" &
      "  𝐦_grade & $antiscalar\n"
    root.writeTree([("p/p.nimble", "version = \"0.1.0\"\nsrcDir = \"src\"\n"),
                    ("p/src/a.nim", source)])
    check execCmd("git -C " & root.quoteShell & " init -q") == 0
    check execCmd("git -C " & root.quoteShell & " add -A") == 0
    var toolchains = initToolchains()
    let
      files = [("p/src/a.nim", source)]
      nimbles = nimblesNearest(["p/src/a.nim"], root)
      plans = files.planRenames([], "", root, toolchains, nimbles)
    check plans.mapIt((it.rename.name, it.rename.renamed, it.rename.rule, it.refusal.len > 0)) ==
      @[("rightName", "name_right", Rule.CaseName, false),  # case and cut: one new name
        ("left_name", "name_left", Rule.CutName, false),
        ("𝐦_grade", "grade_𝐦", Rule.CutName, false),  # notation keeps its letters
        ("antiscalar", "scalar_anti", Rule.CutName, true)]
    let outcome = outcome(files, [], false, root, plans = plans, nimbles = nimbles)
    check outcome.written.len == 1
    let written = outcome.written[0][1]
    for name in ["name_left", "name_right", "grade_𝐦", "antiscalar"]: check name in written
    for name in ["left_name", "rightName", "𝐦_grade", "scalar_anti"]: check name notin written
    check "p/src/a.nim:11: name-cut fixed" in outcome.lines  # each use of `𝐦_grade`
    check "p/src/a.nim:9: name-case fixed" in outcome.lines
    check outcome.lines.anyIt(it.startsWith("p/src/a.nim:12: name-cut warning: " &
      "actual=\"antiscalar\" message=\"rename to `scalar_anti` stays for hand, since it is " &
      "refused:"))
    check "p/src/a.nim:12: name-cut: actual=\"antiscalar\" message=\"name puts `anti` after " &
      "word it qualifies, as `scalarAnti`\"" in outcome.lines


  test "planner that refuses composed rename writes neither its case part nor its cut":
    # Cost of record: `composed` joins case rename and cut of one declaration into one rename,
    #   so one refusal leaves both; `name_right` reads as template `nameRight` here.
    let root = createTempDir("knoller_", "_composed")
    defer: removeDir(root)
    const source =
      "{.experimental: \"strictFuncs\".}\n\n" &
      "type Chiral*[T] = object  ## Pair of sides.\n" &
      "  left*, right*: T  ## Side.\n\n" &
      "template nameRight*(): int = 1\n  ## Right name.\n\n\n" &
      "proc f*(rightName: int): int =\n" &
      "  ## Add.\n" &
      "  rightName + nameRight()\n"
    root.writeTree([("p/p.nimble", "version = \"0.1.0\"\nsrcDir = \"src\"\n"),
                    ("p/src/a.nim", source)])
    check execCmd("git -C " & root.quoteShell & " init -q") == 0
    check execCmd("git -C " & root.quoteShell & " add -A") == 0
    var toolchains = initToolchains()
    let
      files = [("p/src/a.nim", source)]
      nimbles = nimblesNearest(["p/src/a.nim"], root)
      plans = files.planRenames([], "", root, toolchains, nimbles)
    check plans.mapIt((it.rename.name, it.rename.renamed, it.rename.rule, it.refusal.len > 0)) ==
      @[("rightName", "name_right", Rule.CaseName, true)]
    let outcome = outcome(files, [], false, root, plans = plans, nimbles = nimbles)
    for written in outcome.written:
      for name in ["right_name", "name_right"]: check name notin written[1]
    check "p/src/a.nim:10: name-case: actual=\"rightName\" message=\"parameter is " &
      "`snake_case`\"" in outcome.lines
    check "p/src/a.nim:10: name-cut: actual=\"rightName\" message=\"name opens with head, " &
      "axis value `right` last\"" in outcome.lines
    check outcome.lines.anyIt(it.startsWith("p/src/a.nim:10: name-case warning: " &
      "actual=\"rightName\" message=\"rename to `name_right` stays for hand, since it is " &
      "refused:"))


  test "rename refused before semantic pass warns at path run names, from root or inside":
    # Case of wiring of audit: rename of `Anticlockwise` at `rotation.nim:70` of `dance_ontology`
    #   printed `left` alone, since plan refused before pass kept path inside its project.
    #   Domain: path run names, from root of repository and from inside project.
    let root = createTempDir("knoller_", "_early")
    defer: removeDir(root)
    const source =
      "type\n" &
      "  Way* {.pure.} = enum  ## Sense of turn.\n" &
      "    Clockwise, Anticlockwise\n" &
      "  Chiral*[T] = object  ## Pair of sides.\n" &
      "    left*, right*: T  ## Side.\n\n\n" &
      "const LEFT_NAME* {.strdefine.} = \"a\"  ## Name.\n"
    root.writeTree([("p/p.nimble", "version = \"0.1.0\"\nsrcDir = \"src\"\n"),
                    ("p/src/a.nim", source)])
    check execCmd("git -C " & root.quoteShell & " init -q") == 0
    check execCmd("git -C " & root.quoteShell & " add -A") == 0
    var toolchains = initToolchains()
    for (directory, path) in [(root, "p/src/a.nim"), (root / "p", "src/a.nim")]:
      let
        files = [(path, source)]
        nimbles = nimblesNearest([path], directory)
        plans = files.planRenames([], "", directory, toolchains, nimbles)
      check plans.mapIt((it.rename.path, it.rename.renamed, it.refusal.len > 0)) ==
        @[(path, "ClockwiseAnti", true), (path, "NAME_LEFT", true)]
      let outcome = outcome(files, [], false, directory, plans = plans, nimbles = nimbles)
      check outcome.lines.anyIt(it.startsWith(path & ":3: name-cut warning: " &
        "actual=\"Anticlockwise\" message=\"rename to `ClockwiseAnti` stays for hand, since " &
        "it is refused: `$` of member reads its name"))
      check outcome.lines.anyIt(it.startsWith(path & ":8: name-cut warning: " &
        "actual=\"LEFT_NAME\" message=\"rename to `NAME_LEFT` stays for hand, since it is " &
        "refused: `strdefine` gives `LEFT_NAME`"))
