## Replicate reader of imports and both checks of `imports.nim`, as D1 of #927 rules them.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/[domains, imports, layout, projects, toolchain]
import ./fixtures


const
  TAGGER = DIRECTORY_TAGGER  ## Project that imported parser by path, then as package (#934).
  PARSER = DIRECTORY_PARSER  ## Project tagger reads.
  PROBE = CURATOR & "/probe"  ## Curator project outside checker.
  SOURCE_CHECKER = DIRECTORY_DRIVER & "/src"  ## Folder of check sources, inside checker.


func found(tree: Tree): seq[(string, int)] =
  ## Read path and line of each finding of check of imports by path.
  tree.checkImportsProject.mapIt((it.path, it.line))


func reached(tree: Tree): seq[(string, int, string)] =
  ## Read path, line and message of each finding of check of driver.
  tree.checkImportsDriver.mapIt((it.path, it.line, it.message))



suite "Reader":
  test "reader names each module statement names, in each form, at line that holds its path":
    check imports("import std/[os, strutils]\n").mapIt((it.line, it.target)) ==
      @[(1, "std/os"), (1, "std/strutils")]  # bracket joins prefix to each member
    check imports("import ./[a {.all.}, b]\n").mapIt(it.target) == @["./a", "./b"]  # pragma out
    check imports("import ../../p/src/[\n  nif,\n  merge,\n]\n").mapIt((it.line, it.target)) ==
      @[(1, "../../p/src/nif"), (1, "../../p/src/merge")]  # bracket spread over lines
    check imports("import\n  std/strutils,\n  ../../p/src/p\n").mapIt((it.line, it.target)) ==
      @[(2, "std/strutils"), (3, "../../p/src/p")]  # keyword alone, then one module to line
    check imports("from ./a import b, c\n").mapIt(it.target) == @["./a"]  # names imported out
    check imports("from ../x {.all.} import y\n").mapIt(it.target) == @["../x"]
    check imports("from ../x import\n  y,\n  z\n").mapIt(it.target) == @["../x"]
    check imports("import std/os except getEnv, putEnv\n").mapIt(it.target) == @["std/os"]
    check imports("import ./a as b, ./c\n").mapIt(it.target) == @["./a", "./c"]  # alias out
    check imports("include \"suites.nim\"\n").mapIt(it.target) == @["suites.nim"]  # quotes out
    check imports("import \"../../p/src/p\"\n").mapIt(it.target) == @["../../p/src/p"]
    check imports("when defined(js): import ../../p/src/p\n").mapIt(it.target) ==
      @["../../p/src/p"]  # guard on its line
    check imports("when compileOption(\"profiler\"):\n  import std/nimprof\n")
      .mapIt((it.line, it.target)) == @[(2, "std/nimprof")]  # block of guard
    check imports("import std/os\n\nimport ./a\n").mapIt((it.line, it.target)) ==
      @[(1, "std/os"), (3, "./a")]  # each statement at its own line


  test "comment, long string, and string outside statement name nothing":
    check imports("# import ../../p/src/p\n").len == 0  # comment
    check imports("## from ../x import y\n").len == 0  # doc comment
    check imports("let path = \"../../p/src/p\"\n").len == 0  # string outside statement
    check imports("const s = \"\"\"\nimport ../../p/src/p\nfrom ../x import y\n\"\"\"\n").len ==
      0  # each line inside long string is data
    check imports("const s = \"\"\"a\"\"\"\nimport ./a\n").mapIt(it.target) ==
      @["./a"]  # long string closed on its own line
    check imports("import_proto3 \"scene.proto\"\n").len == 0  # word that opens with keyword


  test "path resolves against folder of source, as compiler tries it first":
    check resolve(TAGGER & "/src", "../../lojban_parser/src/lojban_parser") ==
      PARSER & "/src/lojban_parser"
    check resolve(TAGGER & "/tools", "./lists") == TAGGER & "/tools/lists"
    check resolve(TAGGER & "/tools", "lists") == TAGGER & "/tools/lists"  # bare name, folder first
    check resolve("curator", "../../x").len == 0  # climbs past root
    check "./a".isRelative and "../a".isRelative
    check not "std/os".isRelative and not "knoller".isRelative and not "pkg/x".isRelative



suite "Imports by path":
  test "import by path into other project is finding at its line, naming project (D1 of #927)":
    # Case as found: 16 imports of lojban_tagger led into folder of lojban_parser until #934, as
    #   `import ../../../lojban_parser/src/lojban_parser` of `src/lojban_tagger/tags.nim` at
    #   `0d6eaaeb`; assayer imported knoller so until #905. Domain: each form of import, path
    #   into own project or its clone, and one finding to line for each project it reaches.
    let tree = @[
      entry(TAGGER & "/src/lojban_tagger/tags.nim",
        "import std/strutils\nimport ../../../lojban_parser/src/lojban_parser\n"),
      entry(TAGGER & "/tools/lists.nim",
        "from ../../lojban_parser/tools/lists import LIST_GISMU\n" &
        "from ../dependencies/lojban_parser/contributor/bangu/lojban_parser/tools/lists import\n" &
        "  LIST_LUJVO\n" &
        "import ../src/lojban_tagger/entries\n"),
      entry(TAGGER & "/tests/suites/test_names.nim",
        "import ../../../lojban_parser/src/lojban_parser/[\n  entries,\n  nif,\n]\n" &
        "include \"../../../lojban_parser/tests/suites/corpora.nim\"\n"),
      entry("curator/assayer/src/assayer/command.nim",
        "when defined(nimcheck): import \"../../../knoller/src/knoller/pins\"\n"),
    ]
    check tree.found == @[
      (TAGGER & "/src/lojban_tagger/tags.nim", 2),
      (TAGGER & "/tools/lists.nim", 1),
      (TAGGER & "/tests/suites/test_names.nim", 1),
      (TAGGER & "/tests/suites/test_names.nim", 5),
      ("curator/assayer/src/assayer/command.nim", 1),
    ]  # clone under `dependencies/` and own module are no other project
    let first = tree.checkImportsProject[0]
    check first.message.endsWith("got `" & PARSER & "`.")  # project it reaches
    check "atlas.lock" in first.message and "(CONTRIBUTOR.md, Dependencies)" in first.message


  test "import among projects of checker stands, and checker reaching any other is finding":
    # Root `koch.nim`, audit and knoller build as one program from each checkout, and audit
    #   imports knoller by path; each other path stays finding, from checker too.
    let tree = @[
      entry(SOURCE_CHECKER & "/plan.nim", "import ../../knoller/src/knoller\n"),
      entry(DIRECTORY_AUDIT & "/tests/suites/test_x.nim", "import ../../../knoller/src/knoller\n"),
      entry(DIRECTORY_KNOLLER & "/src/knoller/x.nim", "import ../../../audit/src/findings\n"),
      entry(SOURCE_CHECKER & "/probing.nim", "import ../../probe/src/probe\n"),
      entry("koch.nim", "import ./curator/audit/src/audit\nimport ./curator/probe/src/probe\n"),
    ]
    check PROJECTS_CHECKER == [DIRECTORY_DRIVER, DIRECTORY_KNOLLER]
    check tree.found == @[(SOURCE_CHECKER & "/probing.nim", 1)]  # koch.nim is in no project
    check tree.checkImportsProject[0].message.endsWith("got `" & PROBE & "`.")



suite "Driver":
  test "driver reaching package, itself or through module of its project, is finding (#934)":
    # Case as found (#934): driver of lojban_tagger imported `./lists`, and `tools/lists.nim`
    #   imported `tools/lists` of parser from its clone under `dependencies/`, so driver did not
    #   compile before restore, and `koch list-packages` printed nothing. Finding stands at line
    #   of driver that leads there, and names package and module that imports it.
    let tree = @[
      entry(TAGGER & "/" & FILE_DRIVER, "import std/[os, osproc]\n\nimport ./lists\n"),
      entry(TAGGER & "/tools/lists.nim",
        "import std/strutils\n" &
        "from ../dependencies/lojban_parser/contributor/bangu/lojban_parser/tools/lists import\n" &
        "  LIST_GISMU\n" &
        "import ../src/lojban_tagger/entries\n"),
      entry(TAGGER & "/src/lojban_tagger/entries.nim", "import std/strutils\n"),
    ]
    check tree.reached.mapIt((it[0], it[1])) == @[(TAGGER & "/" & FILE_DRIVER, 3)]
    check tree.reached[0][2].endsWith(
      "got `../dependencies/lojban_parser/contributor/bangu/lojban_parser/tools/lists` in " &
        "`tools/lists.nim`."
    )  # module of clone, which tree lacks, and module of project that names it
    check "(CONTRIBUTOR.md, Dependencies)" in tree.reached[0][2]
    let fixed = tree.replaced(TAGGER & "/" & FILE_DRIVER, "import std/[os, osproc]\n")
    check fixed.reached.len == 0  # driver runs `tools/lists.nim` as program of its own instead


  test "driver reaches standard library and modules its project holds, and each other is package":
    # Domain: `std/` module; own module by path, by bare name and by `include`, and through
    #   two of them, cycle included; name of package, bare and as `pkg/`; module tree lacks;
    #   module of other project, which check of paths reports; project with no driver.
    const project = CONTRIBUTOR & "/ronri/alpha"
    let
      own = @[
        entry(project & "/" & FILE_DRIVER,
          "import std/os\nimport ./[verbs, title]\nimport lists\ninclude \"steps.nim\"\n" &
          "import ../design/page\n"),
        entry(project & "/tools/verbs.nim", "import ./title\n"),
        entry(project & "/tools/title.nim", "import ./verbs\nimport std/strutils\n"),
        entry(project & "/tools/lists.nim", "import std/json\n"),
        entry(project & "/tools/steps.nim", "discard\n"),
        entry(project & "/design/page.nim", "import ../src/alpha/[draw]\n"),
        entry(project & "/src/alpha/draw.nim", "import std/math\n"),
      ]
      other = own.with(
        entry(PARSER & "/src/lojban_parser.nim", "import knoller\n"),
        entry(
          project & "/tools/other.nim", "import ../../../bangu/lojban_parser/src/lojban_parser\n"
        ),
      )
    check own.reached.len == 0  # standard library and modules of project alone, cycle ends
    check other.replaced(project & "/" & FILE_DRIVER, "import ./other\n").reached.len ==
      0  # module of other project is read no further
    for (source, got) in [
      ("import knoller\n", "`knoller` in `tools/build.nim`"),  # name of package
      ("import knoller/compilers\n", "`knoller/compilers` in `tools/build.nim`"),
      ("import pkg/npeg\n", "`pkg/npeg` in `tools/build.nim`"),
      ("import ./verbs\n", "`../build/generated` in `tools/verbs.nim`"),  # module tree lacks
      ("import ./title\n", "`../build/generated` in `tools/verbs.nim`"),  # through two modules
    ]:
      let tree = own.replaced(project & "/tools/verbs.nim", "import ../build/generated\n")
        .replaced(project & "/" & FILE_DRIVER, "import std/os\n" & source)
      check tree.reached.mapIt((it[0], it[1])) == @[(project & "/" & FILE_DRIVER, 2)]
      check tree.reached[0][2].endsWith("got " & got & ".")
    check own.without(project & "/" & FILE_DRIVER).reached.len == 0  # project with no driver
