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
    check "p/src/uses.nim:3: name-cut left: Name opens with head, axis value `left` last; got " &
      "`LEFT_NAME`." in outcome.lines  # rename needs semantic pass, which no plan gave
    check not outcome.lines.anyIt(it.startsWith("q/src/uses.nim:3: name-cut"))  # no wrapper
    let names = namesPackage([ALGEBRA, USES])
    check names.axes == @["left", "right"]
    check names.landmarks.mapIt((it.name, it.index, it.aliases)) ==
      @[("Grade", "1", @["vector"]), ("GradeAnti", "1", @["vector"])]  # body of no `when`
    check "chiral" in names.words and "name" in names.words


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
    check "p/src/uses.nim:3: name-cut left: Name opens with head, axis value `left` last; got " &
      "`LEFT_NAME`." notin outcome.lines  # wrapper of library is no axis value


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
    check outcome.lines.anyIt(it.startsWith("p/src/a.nim:12: name-cut warning: Rename to " &
      "`scalar_anti` stays for hand, since it is refused:"))
    check "p/src/a.nim:12: name-cut left: Name puts `anti` after word it qualifies, as " &
      "`scalarAnti`; got `antiscalar`." in outcome.lines
