## Hold staging checks of compile time and their fixers: compile-time family carries
##   `compileTime` alike and no runtime pragma (STYLE.md §2), and fix settles each report.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/knoller/[chain, reports, staging]


const
  LINES_HEAD = 4  ## Lines `module` puts before body: doc, blank, pragma, blank.
  STAGED = "func anchor(): int {.compileTime.} = 0\n"
    ## Member carrying its own `compileTime`, which stages family of its module.
  PRAGMAS_RUNTIME = ["inline", "noinit", "noinline", "codegenDecl: \"$# $#$#\""]
    ## Each pragma that acts only on generated code, which compile-time routine has none of.
  MESSAGE_MEMBER = "Routine compile time alone runs carries `compileTime`, as its family does; got "
    ## Opening of message of member lacking `compileTime`.


func module(body: string): string =
  ## Wrap body in smallest module passing pragma rule.
  "## Do one thing.\n\n{.experimental: \"strictFuncs\".}\n\n" & body


func families(source: string): seq[(int, string)] =
  ## Read line and message of each report of compile-time family over source.
  checkFamilies("a.nim", source).mapIt (it.line, it.message)


func fixedFamilies(source: string): string =
  ## Fix compile-time family of source, as `koch fix` does.
  fixFamilies("a.nim", source).source



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
      let source = module(STAGED & "func c(): int =\n  1\n" & uses)
      let expected = if is_member: @[(LINES_HEAD + 2, MESSAGE_MEMBER & "`func c`.")] else: @[]
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
