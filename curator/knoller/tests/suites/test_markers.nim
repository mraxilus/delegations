## Replicate Article I.6 and STYLE.md §5 on sibling markers, as `markers.nim` reads them, with
##   three answers of rule 7 of #443: suite needs no marker (Q1), marker stands only where its own
##   module never uses symbol (Q2), and import into other project is not read (Q3).
##   Semantic pass is real in one test: `nimsuggest` beside compiler building this suite.

{.experimental: "strictFuncs".}

import std/[os, sequtils, strutils, tables, tempfiles, unittest]
import ../../src/knoller/[edits, markers, rules, symbols]


const
  ALGEBRA = """
{.experimental: "strictFuncs".}

type
  BasisDigits = distinct string  ## Define digit representation of basis.
  Grade* = distinct int  ## Define grade selector for multivectors.

func `and`(a, b: BasisFlags): BasisFlags {.borrow, compileTime, used.}  # Used in cayleys.nim.
func countSetBits(b: BasisFlags): int {.borrow, compileTime.}
iterator items(b: BasisDigits): char = (for d in string(b): yield d)
template `[]`(b: BasisDigits, i: int): char {.used.} = string(b)[i]  # Used in cayleys.nim.

func toBasis(b: BasisDigits): Basis {.compileTime, noinit, used.} =  # Used in "cayleys.nim".
  ## Convert digit representation of basis to associated basis.
  b.toFlags.toBasis

const LIMIT = 3
when IS_CONFORMAL:
  template infinity*(t: typedesc[Basis]): Basis = t.vectorLast
  func helper(x: int): int =
    let local = x
    local

when isMainModule:
  proc main() = discard
"""
    ## Shapes of `pga/algebra.nim` of PGA library at `3d9696e`: marks of its author on lines 7,
    ##   10 and 12, type with trailing doc, and private symbol under `when`.
  OPERATORS = "import std/[macros, math, options]\n\n" &
    "import ./[algebra {.all.}, cayleys {.all.}, emitters, multivectors]\n"
    ## Imports of `pga/operators.nim:10` of PGA library at `3d9696e`; `algebra {.all.}` reaches
    ##   nothing there (rule 7 of #443).
  SUITES = "import ../pga\nimport ../pga/[algebra {.all.}, multivectors {.all.}, operators]\n"
    ## Imports of `tests/suites.nim:11` of PGA library at `3d9696e`; `multivectors {.all.}`
    ##   reaches nothing there (rule 7 of #443).
  ROOT_FIXTURE = "/r"  ## Root of package answers of hand name.


func at(source, text: string): (int, int) =
  ## Read line and column of first `text` in source.
  let k = source.find(text)
  (source[0 ..< k].count('\n') + 1, k - source[0 ..< k].rfind('\n') - 1)


func reached(source, text: string; siblings: seq[string]; is_own = false): Uses =
  ## Build uses where siblings reach symbol whose name opens at first `text` of source.
  result.privates[source.at(text)] = UsePrivate(siblings: siblings, is_own: is_own)



suite "Style §5":
  test "private symbol reads at top level of module, operator and template among them":
    let found = ALGEBRA.privatesTop
    check found.mapIt(it.name) == @[
      "BasisDigits", "`and`", "countSetBits", "items", "`[]`", "toBasis", "LIMIT", "helper",
    ]  # exported, local, entry block and field none
    check found.mapIt(it.keyword) ==
      @["type", "func", "func", "iterator", "template", "func", "const", "func"]
    check found.mapIt((it.line, it.column)) == @[
      ALGEBRA.at("BasisDigits ="), ALGEBRA.at("`and`"), ALGEBRA.at("countSetBits"),
      ALGEBRA.at("items("), ALGEBRA.at("`[]`"), ALGEBRA.at("toBasis("), ALGEBRA.at("LIMIT"),
      ALGEBRA.at("helper"),
    ]
    let query = queryUses("pga/algebra.nim", ALGEBRA)
    check query.usages[0] == (4, 12)  # last byte of name
    check query.usages[1] == (7, 6)  # first byte of operator, past backtick
    check query.usages[5] == (12, 11)  # past column 5, which implicit `result` answers


  test "each item `{.all.}` opens reads, in each form of import":
    check OPERATORS.importsAll.mapIt((it.module, it.line, it.column)) ==
      @[("./algebra", 3, 10), ("./cayleys", 3, 27)]
    check SUITES.importsAll.mapIt(it.module) == @["../pga/algebra", "../pga/multivectors"]
    let source = "import ./algebra {.all.}\nfrom ./rig {.all.} import BANDS, SHOWN\n" &
      "import ../../src/ricysoho/[\n  clusters, lujvo {.all.},\n]\nimport std/[os, strutils]\n"
    check source.importsAll.mapIt(it.module) ==
      @["./algebra", "./rig", "../../src/ricysoho/lujvo"]
    check source.importsAll[1].names == @["BANDS", "SHOWN"]


  test "private symbol sibling reaches, and its own module never uses, takes marker (Q2)":
    # Domain: each case of Q2; symbol its own module uses takes none, as nine of
    #   `pga/algebra.nim` at `3d9696e` do, `countSetBits` among them (used at line 346).
    let
      uses = ALGEBRA.reached("countSetBits", @["cayleys.nim"])
      found = checkMarkers("pga/algebra.nim", ALGEBRA, uses)
    check found.len == 1
    check found[0].rule == Rule.UsedMarker and found[0].line == 8
    check found[0].message == "Private symbol sibling `cayleys.nim` reaches carries " &
      "`{.used.}` and comment naming sibling; got `func countSetBits`."
    let (edits, reports) = editsMarkers("pga/algebra.nim", ALGEBRA, uses, [])
    check ALGEBRA.applied(edits).splitLines[7] == "func countSetBits(b: BasisFlags): int " &
      "{.borrow, compileTime, used.}  # Used in `cayleys.nim`."
    check reports.mapIt(it.line) == @[8]
    for (siblings, is_own) in [(@["cayleys.nim"], true), (newSeq[string](), false)]:
      let other = ALGEBRA.reached("countSetBits", siblings, is_own)
      check checkMarkers("pga/algebra.nim", ALGEBRA, other).len == 0  # own use, or suite alone


  test "marker passes where its comment names each sibling, in any spelling":
    # Case: three of five marks of `pga/algebra.nim` at `3d9696e`, naming sibling in each spelling.
    var uses: Uses
    for name in ["`and`", "`[]`", "toBasis("]:
      uses.privates[ALGEBRA.at(name)] = UsePrivate(siblings: @["cayleys.nim"])
    check checkMarkers("pga/algebra.nim", ALGEBRA, uses).len == 0
    let other = ALGEBRA.reached("`and`", @["operators.nim"])  # names other sibling
    check checkMarkers("pga/algebra.nim", ALGEBRA, other).mapIt(it.line) == @[7]
    check editsMarkers("pga/algebra.nim", ALGEBRA, other, [])[0].len == 0  # left for hand


  test "fixer writes marker in each shape of declaration, and comment naming each sibling":
    for (source, name, siblings, fixed) in [
      (
        "func f(x: int): int {.inline, raises: [].} =\n  x\n", "f(", @["b.nim"],
        "func f(x: int): int {.inline, used, raises: [].} =  # Used in `b.nim`.\n  x\n",
      ),
      (
        "proc f(x: int) {.varargs.} = discard\n", "f(", @["b.nim"],
        "proc f(x: int) {.used, varargs.} = discard  # Used in `b.nim`.\n",
      ),
      (
        "func f[T](x: T): T =\n  x\n", "f[", @["a.nim", "b.nim"],
        "func f[T](x: T): T {.used.} =  # Used in `a.nim` and `b.nim`.\n  x\n",
      ),
      (
        "func f(\n  x: int\n): int =\n  x\n", "f(", @["b.nim"],
        "func f(\n  x: int\n): int {.used.} =  # Used in `b.nim`.\n  x\n",
      ),
      (
        "type\n  BasisDigits = distinct string  ## Define digit representation of basis.\n",
        "BasisDigits", @["cayleys.nim"],
        "type\n  BasisDigits {.used.} = distinct string  # Used in `cayleys.nim`.\n" &
          "    ## Define digit representation of basis.\n",
      ),
      ("const LIMIT = 3\n", "LIMIT", @["b.nim"], "const LIMIT {.used.} = 3  # Used in `b.nim`.\n"),
      (
        "let\n  speed: float = 2.0\n", "speed", @["b.nim"],
        "let\n  speed {.used.}: float = 2.0  # Used in `b.nim`.\n",
      ),
    ]:
      checkpoint source
      let (edits, reports) = editsMarkers("a.nim", source, source.reached(name, siblings), [])
      check source.applied(edits) == fixed
      check reports.len == 1


  test "marker stays for hand on line holding plain comment, too wide, fenced or written":
    let
      source = "func f(x: int): int = x  # Plain.\nfunc g(x: int): int = x\n" &
        "func h(x: int): int = " & 'x'.repeat(70) & "\n"
      uses = block:
        var u = source.reached("f(", @["b.nim"])
        u.privates[source.at("g(")] = UsePrivate(siblings: @["b.nim"])
        u.privates[source.at("h(")] = UsePrivate(siblings: @["b.nim"])
        u
    check checkMarkers("a.nim", source, uses).mapIt(it.line) == @[1, 2, 3]
    check editsMarkers("a.nim", source, uses, [])[1].mapIt(it.line) == @[2]  # wide `h` stays
    check editsMarkers("a.nim", source, uses, [1])[1].len == 0  # fenced `g`
    let
      k = source.find("int = x\nfunc h")
      held = [Edit(first: k, after: k + 7, text: "int = y")]  # other fixer writes over `g` head
    check editsMarkers("a.nim", source, uses, [], held)[1].len == 0


  test "`{.all.}` reaching no private symbol goes, as in PGA library at `3d9696e`":
    # Cases: `pga/operators.nim:10` and `tests/suites.nim:11`, 2 lines rule 7 of #443
    #   changes; suite's `{.all.}` that reaches symbol stays, and needs no marker there (Q1).
    var operators, suites: Uses
    operators.imports[(3, 10)] = false
    operators.imports[(3, 27)] = true
    suites.imports[(2, 15)] = true
    suites.imports[(2, 32)] = false
    let found = checkMarkers("pga/operators.nim", OPERATORS, operators)
    check found.mapIt(it.line) == @[3]
    check found[0].message ==
      "Import takes `{.all.}` only where it reaches private symbol; got `algebra {.all.}`."
    check OPERATORS.applied(editsMarkers("pga/operators.nim", OPERATORS, operators, [])[0])
      .splitLines[2] == "import ./[algebra, cayleys {.all.}, emitters, multivectors]"
    check SUITES.applied(editsMarkers("tests/suites.nim", SUITES, suites, [])[0])
      .splitLines[1] == "import ../pga/[algebra {.all.}, multivectors, operators]"
    check checkMarkers("a.nim", OPERATORS, Uses()).len == 0  # outside package, absent (Q3)
    operators.reason = "error"
    check checkMarkers("pga/operators.nim", OPERATORS, operators).len == 0  # unresolved


  test "uses gather from answers of semantic pass: sibling, own use, suite and borrow apart":
    let
      module = "func countSetBits(b: int): int = b\n" &
        "template `[]`(b: string, i: int): char = b[i]\nfunc toFlags(b: int): int = b\n"
      files = @[
        ("pga/algebra.nim", module),
        ("pga/cayleys.nim", "import ./algebra {.all.}\n"),
        ("pga/operators.nim", "import ./[algebra {.all.}, cayleys]\n"),
        ("pga/rig.nim", "from ./algebra {.all.} import toFlags\n"),
        ("tests/suites.nim", "import ../pga/[algebra {.all.}]\n"),
        ("pga/bench.nim", "import pga/[cayleys {.all.}]\n"),  # module of other package (Q3)
      ]

    func answered(site: (int, int); lines: seq[Symbol]): Answer =
      result = Answer(path: "pga/algebra.nim")
      result.usages[site] = lines

    func symbol(section, name, file: string; line, column: int; signature = "int"): Symbol =
      Symbol(
        section: section,
        name: name,
        signature: signature,
        file: ROOT_FIXTURE & "/" & file,
        line: line,
        column: column,
      )

    let
      count = (1, 16)  # Site asked of `countSetBits`, last byte of its name.
      bracket = (2, 10)  # Site asked of `[]`, first byte past backtick.
      flags = (3, 11)  # Site asked of `toFlags`.
      answers = @[
        ("pga/cayleys.nim", answered(count, @[
          symbol("def", "algebra.countSetBits", "pga/algebra.nim", 1, 5),
          symbol("use", "bitops.countSetBits", "pga/algebra.nim", 1, 33),  # borrowed, own line
          symbol("use", "algebra.countSetBits", "pga/cayleys.nim", 7, 3),
          symbol("use", "algebra.countSetBits", "tests/suites.nim", 5, 3),
        ])),
        ("pga/cayleys.nim", answered(bracket, @[
          symbol("def", "algebra.`[]`", "pga/algebra.nim", 2, 9, "char"),
          symbol("use", "algebra.`[]`", "pga/algebra.nim", 2, 10, "char"),  # own name
          symbol("use", "algebra.`[]`", "pga/cayleys.nim", 4, 8, "char"),
        ])),
        ("pga/operators.nim", answered(flags, @[
          symbol("def", "algebra.toFlags", "pga/algebra.nim", 3, 5),
          symbol("use", "algebra.toFlags", "pga/algebra.nim", 1, 30),  # own use
          symbol("use", "algebra.toFlags", "pga/rig.nim", 2, 3),
        ])),
      ]
      uses = usesPackage(files, answers, ROOT_FIXTURE)
    check uses["pga/algebra.nim"].privates[(1, 5)] == UsePrivate(siblings: @["cayleys.nim"])
    check uses["pga/algebra.nim"].privates[(2, 9)] == UsePrivate(siblings: @["cayleys.nim"])
    check uses["pga/algebra.nim"].privates[(3, 5)] ==
      UsePrivate(siblings: @["rig.nim"], is_own: true)
    check uses["pga/cayleys.nim"].imports[(1, 9)]  # reaches `countSetBits` and `[]`
    check not uses["pga/operators.nim"].imports[(1, 10)]  # reaches nothing
    check uses["pga/rig.nim"].imports[(1, 7)]  # names private `toFlags` in its text
    check uses["tests/suites.nim"].imports[(1, 15)]  # suite reaches, and makes no sibling (Q1)
    check "pga/bench.nim" notin uses  # `pga/cayleys` names no file of package, so unread (Q3)
    let hinted = usesPackage(
      files, answers, ROOT_FIXTURE, {"pga/algebra.nim": @[(1, "countSetBits")]}.toTable
    )
    check not hinted["pga/algebra.nim"].privates[(1, 5)].is_own  # compiler hints it unused
    check hinted["pga/algebra.nim"].privates[(2, 9)].is_own  # it hints none, so module uses it
    let failed = usesPackage(files, @[("pga/cayleys.nim", Answer(path: "pga/algebra.nim",
      reason: "error"))], ROOT_FIXTURE)
    check failed["pga/cayleys.nim"].reason == "error" and
      failed["pga/algebra.nim"].reason == "error"


  test "semantic pass answers every use of private symbol, across modules of entry":
    let
      root = createTempDir("knoller_", "_markers")
      files = @[
        ("fixture.nimble", "version = \"0.1.0\"\n"),
        ("a.nim", "func helper(x: int): int = x + 1\nfunc other*(x: int): int = x\n"),
        ("b.nim", "import ./a {.all.}\n\necho helper(1)\n"),
        ("c.nim", "import ./a {.all.}\n\necho other(1)\n"),
      ]
    defer: removeDir(root)
    for (path, content) in files: writeFile(root / path, content)
    var answers: seq[(string, Answer)]
    for importer in ["b.nim", "c.nim"]:
      let request = Request(
        query: queryUses("a.nim", files[1][1]),
        root: root,
        directory: root,
        includer: importer,
      )
      for answer in resolve([request]): answers.add (importer, answer)
    check answers.allIt(it[1].reason.len == 0)
    let uses = usesPackage(files[1 .. ^1], answers, root)
    check uses["a.nim"].privates[(1, 5)] == UsePrivate(siblings: @["b.nim"])
    check uses["b.nim"].imports[(1, 9)] and not uses["c.nim"].imports[(1, 9)]
    let lines = answers[0][1].usages[(1, 10)]
    check lines.anyIt(it.section == "use" and it.file.endsWith("/b.nim") and it.line == 3)
    check lines.allIt(it.section.len > 0 and it.signature.len > 0)


  test "edit moving doc traces each line back to line it came from":
    let
      source = "type\n  A = int  ## Doc.\nlet b = 1\n"
      uses = source.reached("A =", @["c.nim"])
      (edits, _) = editsMarkers("a.nim", source, uses, [])
    check source.applied(edits) == "type\n  A {.used.} = int  # Used in `c.nim`.\n    ## Doc.\n" &
      "let b = 1\n"
    check source.originApplied(edits) == @[1, 2, 2, 3, 4]
    check source.originApplied([Edit(first: 0, after: 4, text: "kind")]).len == 0  # none moves
