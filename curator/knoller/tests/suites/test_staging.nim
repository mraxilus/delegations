## Hold staging checks of compile time and their fixers: compile-time family carries
##   `compileTime` alike and no runtime pragma (STYLE.md §2), branch on what build fixes is `when`
##   (STYLE.md §3), and fix settles each report.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, tables, unittest]
import ../../src/knoller/[chain, command, reports, staging]


const
  LINES_HEAD = 4  ## Lines `module` puts before body: doc, blank, pragma, blank.
  STAGED = "func anchor(): int {.compileTime.} = 0\n"
    ## Member carrying its own `compileTime`, which stages family of its module.
  PRAGMAS_RUNTIME = ["inline", "noinit", "noinline", "codegenDecl: \"$# $#$#\""]
    ## Each pragma that acts only on generated code, which compile-time routine has none of.
  MESSAGE_MEMBER = "Routine compile time alone runs carries `compileTime`, as its family does; got "
    ## Opening of message of member lacking `compileTime`.
  MESSAGE_BRANCH = "Branch on static distinction is `when`; got "
    ## Opening of message of `if` on what build fixes.
  CONSTANTS = @["DIMENSIONS", "IS_RIGID", "X", "Y"]
    ## Constants other modules of package export, as caller reads them.


func module(body: string): string =
  ## Wrap body in smallest module passing pragma rule.
  "## Do one thing.\n\n{.experimental: \"strictFuncs\".}\n\n" & body


func families(source: string): seq[(int, string)] =
  ## Read line and message of each report of compile-time family over source.
  checkFamilies("a.nim", source).mapIt (it.line, it.message)


func fixedFamilies(source: string): string =
  ## Fix compile-time family of source, as `koch fix` does.
  fixFamilies("a.nim", source).source


func branches(source: string): seq[(int, string)] =
  ## Read line and message of each report of branch on what build fixes, constants of package
  ##   read.
  checkBranches("a.nim", source, CONSTANTS).mapIt (it.line, it.message)


func fixedBranches(source: string): string =
  ## Fix each branch on what build fixes, constants of package read.
  fixBranches("a.nim", source, CONSTANTS).source



suite "Compile-time family":
  test "STYLE.md §2 compile-time routine carries no runtime pragma, and fix drops each":
    # Case held: PGA library at `3d9696e`, `pga/algebra.nim` 247 read
    #   `func toBasisDigits(digits: string): BasisDigits {.compileTime, inline, noinit.} =`.
    let given = module("func f(s: string): int {.compileTime, inline, noinit.} =\n  s.len\n")
    check given.families == @[
      (
        LINES_HEAD + 1,
        "Compile-time routine carries no runtime pragma; got `{.compileTime, inline, noinit.}`.",
      ),
    ]
    check given.fixedFamilies == module("func f(s: string): int {.compileTime.} =\n  s.len\n")
    for pragma in PRAGMAS_RUNTIME:
      let source = module("func f(): int {.compileTime, " & pragma & ".} = 1\n")
      check source.families.len == 1
      check source.fixedFamilies == module("func f(): int {.compileTime.} = 1\n")


  test "STYLE.md §2 fix keeps each other pragma, comment and line of compile-time routine":
    # Case held: `pga/algebra.nim` 230 carried `used` beside `noinit`, and comment after it.
    let given = module(
      "func toBasis(b: int): int {.compileTime, noinit, used.} =  # Used in \"b.nim\".\n  b\n"
    )
    check given.fixedFamilies ==
      module("func toBasis(b: int): int {.compileTime, used.} =  # Used in \"b.nim\".\n  b\n")
    let nested = module(
      "func f(): int {.compileTime.} =\n  func g(): int {.compileTime, noinit.} = 1\n  g()\n"
    )
    check nested.families == @[
      (
        LINES_HEAD + 2,
        "Compile-time routine carries no runtime pragma; got `{.compileTime, noinit.}`.",
      ),
    ]
    check nested.fixedFamilies ==
      module("func f(): int {.compileTime.} =\n  func g(): int {.compileTime.} = 1\n  g()\n")


  test "STYLE.md §2 routine runtime may call keeps its runtime pragmas":
    for pragma in PRAGMAS_RUNTIME:
      let source = module("func f(): int {." & pragma & ".} = 1\nlet x = f()\n")
      check source.families.len == 0
      check source.fixedFamilies == source


  test "STYLE.md §2 routine nested in member carries its own compileTime":
    # Case held: `pga/cayleys.nim` 279, `constructNormSquared` nests in `constructNormsSquared`,
    #   whose every use lies in value of `const`, so compile time alone runs both.
    let given = module(
      "func a(): int {.compileTime.} =\n" &
      "  func b(): int =\n" &
      "    1\n" &
      "  b()\n"
    )
    check given.families == @[(LINES_HEAD + 2, MESSAGE_MEMBER & "`func b`.")]
    check given.fixedFamilies == module(
      "func a(): int {.compileTime.} =\n" &
      "  func b(): int {.compileTime.} =\n" &
      "    1\n" &
      "  b()\n"
    )
    let in_macro = module(STAGED & "macro m(): untyped =\n  func g(): int = 1\n  newLit(g())\n")
    check in_macro.families == @[(LINES_HEAD + 3, MESSAGE_MEMBER & "`func g`.")]
    check in_macro.fixedFamilies ==
      module(STAGED & "macro m(): untyped =\n  func g(): int {.compileTime.} = 1\n  newLit(g())\n")


  test "STYLE.md §2 private routine every use of which compile time runs is member":
    # Case held: `pga/cayleys.nim` 273, `constructNormsSquared` carried no `compileTime`, and
    #   value of `const` alone called it: incidental const evaluation.
    let cases = [
      ("const C = c()\n", true),
      ("static:\n  discard c()\n", true),
      ("macro m(): untyped =\n  discard c()\n  newEmptyNode()\n", true),
      ("func s(): int {.compileTime.} = c()\n", true),
      ("const\n  C = 1\n  D = c() + C\n", true),
      ("let x = c()\n", false),  # runtime binding
      ("proc p() =\n  echo c()\n", false),  # runtime routine
      ("const C = c()\nlet x = c()\n", false),  # one runtime use is enough
      ("", false),  # no use, so no stage reads it
    ]
    for (uses, is_member) in cases:
      let
        source = module(STAGED & "func c(): int =\n  1\n" & uses)
        expected = if is_member: @[(LINES_HEAD + 2, MESSAGE_MEMBER & "`func c`.")] else: @[]
      check source.families == expected
      if is_member:
        check source.fixedFamilies.contains("func c(): int {.compileTime.} =\n")
    let exported = module(STAGED & "func c*(): int =\n  1\nconst C = c()\n")
    check exported.families.len == 0  # other module may call it at runtime


  test "STYLE.md §2 operator reads as member by type of its parameter":
    # Case held: `pga/cayleys.nim` 49, `func `==`(a, b: Order): bool {.borrow.}`, where only
    #   compile-time code mentions `Order`, and no call names operator.
    let
      body =
        "type O = distinct int\n" &
        "func `==`(a, b: O): bool {.borrow.}\n" &
        "iterator items(t: typedesc[O]): O =\n" &
        "  yield O(0)\n" &
        "func f(): int {.compileTime.} =\n" &
        "  for o in O:\n" &
        "    if o == O(0): inc result\n"
      given = module(body)
    check given.families == @[(LINES_HEAD + 2, MESSAGE_MEMBER & "`func ==`.")]
    check given.fixedFamilies ==
      module(body.replace("{.borrow.}", "{.borrow, compileTime.}"))
    check module(body & "proc p() =\n  for o in O: echo o == O(1)\n").families.len == 0


  test "STYLE.md §2 family is module, staged where one member carries its own compileTime":
    # Case held: `pga/multivectors.nim` 39 and 44, routines nested in macro of module where no
    #   routine carries `compileTime`, pass.
    let body = "macro m(): untyped =\n  func g(): int = 1\n  newLit(g())\n"
    check module(body).families.len == 0
    check module(body).fixedFamilies == module(body)
    check module(STAGED & body).families.len == 1


  test "STYLE.md §2 code quote emits runs at runtime, so routine it calls or declares is none":
    # Case held: `contributor/ronri/pga_benchmark/proposals/04-basis-set-forms/laws.nim` 108,
    #   `isAgreeing`, which macro calls inside `quote do:` alone, and
    #   `proposals/02-typed-multivectors/prototype.nim` 78, `bases`, which `quote do:` declares.
    for opening in ["quote do:", "quote(\"@\") do:", "genAst():", "genAst(x):"]:
      let
        calls = module(
          STAGED & "func c(): int =\n  1\nmacro m(): untyped =\n  result = " & opening &
            "\n    echo c()\n"
        )
        declares = module(
          STAGED & "macro m(): untyped =\n  result = " & opening & "\n    func g(): int = 1\n"
        )
      check calls.families.len == 0
      check calls.fixedFamilies == calls
      check declares.families.len == 0
    let outside = module(
      STAGED & "func c(): int =\n  1\nmacro m(): untyped =\n  let x = c()\n" &
        "  result = quote do:\n    echo `x`\n"
    )
    check outside.families == @[(LINES_HEAD + 2, MESSAGE_MEMBER & "`func c`.")]


  test "STYLE.md §2 iterator and template pass, since Nim refuses compileTime on both":
    let source = module(
      "func f(): int {.compileTime.} =\n" &
      "  template t(): int = 1\n" &
      "  iterator i(): int =\n" &
      "    yield 1\n" &
      "  for k in i(): result += k + t()\n"
    )
    check source.families.len == 0
    check source.fixedFamilies == source


  test "X.10 fix puts compileTime among bare pragmas, in order, where signature ends":
    let cases = [
      ("func c(): bool {.used.} =", "func c(): bool {.compileTime, used.} ="),
      ("func c(): bool {.borrow.} =", "func c(): bool {.borrow, compileTime.} ="),
      ("func c(): bool {.raises: [].} =", "func c(): bool {.compileTime, raises: [].} ="),
      ("func c(): bool =", "func c(): bool {.compileTime.} ="),
      ("proc c() =", "proc c() {.compileTime.} ="),
      ("func c(): bool {.inline.} =", "func c(): bool {.compileTime.} ="),  # runtime pragma goes
      ("func c(\n  x = 1,\n): bool =", "func c(\n  x = 1,\n): bool {.compileTime.} ="),
    ]
    for (given, written) in cases:
      let
        source = module(STAGED & given & "\n  true\nconst C = c()\n")
        reports = source.families
      check reports.len == 1
      check reports[0][0] == LINES_HEAD + 1 + given.count('\n') + 1  # line pragmas stand on
      check source.fixedFamilies == module(STAGED & written & "\n  true\nconst C = c()\n")


  test "fix settles, and reports each line it rewrites by rule":
    let source = module(
      STAGED &
      "func c(): int {.noinit.} =\n  1\n" &
      "func d(): int {.compileTime, inline.} = c()\n" &
      "const C = c() + d()\n"
    )
    let fix = fixFamilies("a.nim", source)
    check fix.fixed.mapIt((it.line, it.rule)) == @[
      (LINES_HEAD + 2, Rule.FamilyCompileTime), (LINES_HEAD + 4, Rule.FamilyCompileTime),
    ]
    check checkFamilies("a.nim", fix.source).len == 0
    check fixFamilies("a.nim", fix.source).source == fix.source


  test "chain reports and fixes compile-time family in module alone":
    let
      given = module("func f(): int {.compileTime, noinit.} =\n  ## Give one.\n  1\n")
      written = module("func f(): int {.compileTime.} =\n  ## Give one.\n  1\n")
    check checkFormatting("a.nim", given, Dialect.Module).anyIt(it.rule == Rule.FamilyCompileTime)
    check formatted("a.nim", given, Dialect.Module).source == written
    check checkFormatting("a.nims", given, Dialect.Script).allIt(it.rule != Rule.FamilyCompileTime)
    check formatted("a.nims", given, Dialect.Script).source == given  # script runs in VM alone



suite "Branch on what build fixes":
  test "STYLE.md §3 if expression on constant is when, and fix keeps its else":
    # Case held: PGA library at `3d9696e`, `tests/suites.nim` 173 read
    #   `let antiscalar = if DIMENSIONS != 3: 𝟙 else: -𝟙`, which constant of `pga/algebra.nim`
    #   fixes.
    let given =
      module("proc p() =\n  let antiscalar = if DIMENSIONS != 3: 1 else: -1\n  echo antiscalar\n")
    check given.branches == @[(LINES_HEAD + 2, MESSAGE_BRANCH & "`if DIMENSIONS != 3`.")]
    check given.fixedBranches == given.replace("= if DIMENSIONS", "= when DIMENSIONS")
    let rigid = module("proc p() =\n  let horizon = if IS_RIGID: 1 else: 2\n  echo horizon\n")
    check rigid.branches == @[(LINES_HEAD + 2, MESSAGE_BRANCH & "`if IS_RIGID`.")]
    check rigid.fixedBranches == rigid.replace("if IS_RIGID", "when IS_RIGID")


  test "STYLE.md §3 if statement on constant is when, and fix keeps each elif and else":
    let given = module(
      "proc p() =\n" &
      "  if X == 1:\n" &
      "    echo 1\n" &
      "  elif X == 2 or Y:\n" &
      "    echo 2\n" &
      "  else:\n" &
      "    echo 3\n"
    )
    check given.branches == @[(LINES_HEAD + 2, MESSAGE_BRANCH & "`if X == 1`.")]
    check given.fixedBranches == given.replace("  if X == 1:", "  when X == 1:")
    let one_line = module("proc p() =\n  if X: echo 1\n")
    check one_line.fixedBranches == one_line.replace("if X:", "when X:")


  test "STYLE.md §3 condition is static where it reads only what build fixes":
    let cases = [
      ("X", true),
      ("not X", true),
      ("X and not Y", true),
      ("DIMENSIONS >= 3 and DIMENSIONS != 4", true),
      ("X.len > 0", true),  # length of constant
      ("len(X) > 0", true),
      ("high(X) == 2 or low(X) == 0 or ord(X) == 1 or card(X) == 2", true),
      ("X in {1, 2}", true),
      ("defined(release)", true),
      ("declared(foo) and compiles(foo())", true),
      ("compileOption(\"profiler\")", true),
      ("sizeof(int) == 8", true),
      ("X > 1.5 and Y < 0x1F and X != 2'u8", true),  # literals of float, hexadecimal and suffix
      ("L == 2", true),  # local constant reaches branch
      ("x == 1", false),  # runtime binding
      ("X == x", false),
      ("f(X)", false),  # call of routine runtime may run
      ("X.field", false),  # only length, bounds, ordinal and cardinal stay static
      ("ord(x) == 1", false),
      ("X and isOn()", false),
    ]
    for (condition, is_static) in cases:
      let
        source = module(
          "proc p(x: int) =\n  const L = 2\n  if " & condition & ":\n    echo 1\n"
        )
        report = (LINES_HEAD + 3, MESSAGE_BRANCH & "`if " & condition & "`.")
      check source.branches == (if is_static: @[report] else: @[])


  test "STYLE.md §3 static and typedesc parameters and placeholders are fixed by build":
    let cases = [
      ("proc p[N: static int]() =\n  if N > 2:\n    echo 1\n", true),
      ("proc p(n: static int) =\n  if n > 2:\n    echo 1\n", true),
      ("proc p(G: typedesc) =\n  if G is int:\n    echo 1\n", true),
      ("proc p[T](t: T) =\n  if T is SomeFloat:\n    echo 1\n", true),
      ("proc p(n: int) =\n  if n > 2:\n    echo 1\n", false),
    ]
    for (body, is_static) in cases:
      check module(body).branches.len == (if is_static: 1 else: 0)


  test "STYLE.md §3 if where compile time alone runs passes, since it is no runtime branch":
    # Case held: `pga/operators.nim` 81 and 105 read `if not as_unary` on static parameter of
    #   macro, which Nim 2.4.0 cannot evaluate as `when` there.
    let cases = [
      "const C = if X: 1 else: 2\n",  # STYLE.md §5 writes `if` under `const`
      "const\n  C = if X: 1 else: 2\n",
      "macro m(as_unary: static bool): untyped =\n  if not as_unary:\n    discard\n" &
        "  newEmptyNode()\n",
      "macro m(): untyped =\n  if X:\n    discard\n  newEmptyNode()\n",
      "static:\n  if X:\n    echo 1\n",
      "func f(): int {.compileTime.} =\n  if X: 1 else: 2\n",
      "proc p() =\n  when X:\n    echo 1\n",  # already `when`
    ]
    for body in cases:
      check module(body).branches.len == 0
      check module(body).fixedBranches == module(body)


  test "STYLE.md §3 chain is static only where if and each elif are":
    let source = module("proc p(x: int) =\n  if X:\n    echo 1\n  elif x > 1:\n    echo 2\n")
    check source.branches.len == 0
    check source.fixedBranches == source


  test "STYLE.md §3 if expression is static only where each elif below its line is":
    # Case held: `contributor/ronri/pga_visualiser/src/desktop/main.nim` 3145 opens `if` in
    #   binding, and puts its `elif` on line below, which reading of its own line alone missed.
    let
      runtime = module(
        "proc p(x: int) =\n  let v = if X: 1\n    elif x > 1: 2\n    else: 3\n  echo v\n"
      )
      fixed = module(
        "proc p() =\n  let v = if X: 1\n    elif defined(linux): 2\n    else: 3\n  echo v\n"
      )
    check runtime.branches.len == 0
    check runtime.fixedBranches == runtime
    check fixed.branches == @[(LINES_HEAD + 2, MESSAGE_BRANCH & "`if X`.")]
    check fixed.fixedBranches == fixed.replace("= if X", "= when X")


  test "STYLE.md §1 branch that declares name stays for hand, as when opens no scope":
    let
      given = module("proc p() =\n  if X:\n    let y = 1\n    echo y\n  else:\n    echo 2\n")
      reports = checkBranches("a.nim", given, CONSTANTS)
    check reports.mapIt((it.line, it.message)) == @[(LINES_HEAD + 2, MESSAGE_BRANCH & "`if X`.")]
    check fixBranches("a.nim", given, CONSTANTS).source == given
    check fixBranches("a.nim", given, CONSTANTS).fixed.len == 0


  test "X.1 fix that would widen line past its limit stays for hand":
    let
      wide = "proc p() =\n  let v = if X: " & "1".repeat(76) & " else: 2\n"
      source = module(wide)
    check source.split('\n')[LINES_HEAD + 1].len == 100  # widest line allowed
    check source.branches.len == 1
    check source.fixedBranches == source


  test "fix settles, and reports each line it rewrites by rule":
    let
      source = module("proc p() =\n  if X:\n    echo 1\n  let v = if Y: 1 else: 2\n")
      fix = fixBranches("a.nim", source, CONSTANTS)
    check fix.fixed.mapIt((it.line, it.rule)) ==
      @[(LINES_HEAD + 2, Rule.StaticWhen), (LINES_HEAD + 4, Rule.StaticWhen)]
    check checkBranches("a.nim", fix.source, CONSTANTS).len == 0
    check fixBranches("a.nim", fix.source, CONSTANTS).source == fix.source


  test "constant is name const binds at module level and exports, for other modules":
    let source = module(
      "const X* = 1\n" &
      "const\n  Y* {.intdefine.} = 2\n  Z = 3\n" &
      "let W* = 4\n" &
      "proc p() =\n  const L* = 5\n  discard L\n" &
      "when true:\n  const V* = 6\n"
    )
    check source.constantsExported == @["X", "Y", "V"]


  test "module reads constants it binds itself, with none from caller":
    let source = module("const Q = 3\nproc p() =\n  if Q > 2:\n    echo 1\n")
    check checkBranches("a.nim", source).mapIt(it.line) == @[LINES_HEAD + 3]
    check fixBranches("a.nim", source, @[]).source == source.replace("  if Q", "  when Q")


  test "chain reports and fixes branch on constant in module alone":
    let
      given =
        module("const Q = 3  ## Count.\n\n\nproc p() =\n  ## Print.\n  if Q > 2:\n    echo 1\n")
      written = given.replace("  if Q", "  when Q")
    check checkFormatting("a.nim", given, Dialect.Module).anyIt(it.rule == Rule.StaticWhen)
    check formatted("a.nim", given, Dialect.Module).source == written
    check formatted("a.nims", given, Dialect.Script).source == given  # script runs in VM alone


  test "command line reads constants each module of package exports":
    let
      files = @[
        ("/p/src/a.nim", module("const X* = 1  ## Count.\n")),
        (
          "/p/src/b.nim",
          module("import ./a\n\n\nproc p() =\n  ## Print.\n  if X > 0:\n    echo 1\n"),
        ),
      ]
      nimbles = {"/p/src/a.nim": "/p/p.nimble", "/p/src/b.nim": "/p/p.nimble"}.toTable
      outcome = outcome(files, [], is_check = false, nimbles = nimbles)
    check outcome.lines.anyIt(it.startsWith("/p/src/b.nim:" & $(LINES_HEAD + 6) & ": when-static"))
    check outcome.written.anyIt(it[0] == "/p/src/b.nim" and "  when X > 0:" in it[1])
    let apart = outcome(files[1 .. 1], [], is_check = false, nimbles = nimbles)
    check apart.lines.allIt("when-static" notin it)  # constant of module not run stays unread
