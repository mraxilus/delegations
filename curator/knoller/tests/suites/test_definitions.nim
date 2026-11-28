## Hold blank lines between definitions (X.2), as #443 rules them: each run of other count is
##   reported and fixed, cases of PGA library at `3d9696e` among them; second-tier sibling takes
##   one (Q1), routine of several lines takes two (Q2), and documented one-line definition takes
##   one after any definition or imports (Q3), call after routine among them (ruling `D3 a` of
##   #980). Runs beside banner and nested helper, after statement or pragma line, and inside
##   string, are never read; fix changes nothing else, and nothing second time.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/knoller/[blanks, reports]


const  # TODO: Document.
  PATH = "pga/operators.nim"  ## Path of library module, outside `tests/`.
  TWO = "definition takes two blank lines before it; got `"
    ## Message opening for definition no other bullet of X.2 names.
  BLOCK = "declaration block takes one blank line after another; got `"
    ## Message opening for declaration block after another.
  DOC = "documented one-line definition takes one blank line after another; got `"
    ## Message opening for documented one-line definition.
  FAMILY =
    "declarative call stacks in its family, and one blank line separates two families; got `"
    ## Message opening for declarative call after another.


func messages(source: string): seq[string] =
  ## Read each report of source as `line: message`.
  checkDefinitions(PATH, source).mapIt($it.line & ": " & it.brief)


func fixed(source: string): string =
  ## Fix blank lines between definitions of source, as `koch fix` does.
  fixDefinitions(PATH, source).source


func isSettled(source: string): bool =
  ## Decide whether source reports nothing and fixes to itself again.
  checkDefinitions(PATH, source).len == 0 and fixDefinitions(PATH, source).source == source and
      fixDefinitions(PATH, source).fixed.len == 0



suite "Definitions":
  test "routine of several lines takes two blank lines before it, never one or three (Q2)":
    # Cases: `operators.nim:305`, one line between templates, and `cayleys.nim:512`, three.
    let breach = "template `∧`*(m: Multivector, s: Coefficient): Multivector =\n  m * s\n\n" &
      "template `*`*(s: Coefficient, m: Multivector): Multivector =\n  s ∧ m\n\n\n\n" &
      "func constructProductGeometric(w: array[Order, Cayley2D]): Cayley2D {.compileTime.} =\n" &
      "  discard\n"
    check breach.messages == @["4: " & TWO & "1`", "9: " & TWO & "3`"]
    check breach.fixed == "template `∧`*(m: Multivector, s: Coefficient): Multivector =\n" &
      "  m * s\n\n\ntemplate `*`*(s: Coefficient, m: Multivector): Multivector =\n  s ∧ m\n\n\n" &
      "func constructProductGeometric(w: array[Order, Cayley2D]): Cayley2D {.compileTime.} =\n" &
      "  discard\n"
    check breach.fixed.isSettled
    check checkDefinitions(PATH, breach).allIt(it.rule == Rule.LinesBlankDefinition)
    check fixDefinitions(PATH, breach).fixed.mapIt(it.line) == @[4, 9]  # lines as given


  test "declaration block takes one after another, and two after routine":
    # Cases: `algebra.nim:88`, none between type and const; `cayleys.nim:125`, two; and
    #   `suites.nim:35`, `var` after routine.
    let blocks = "type Coefficient* = (when FLOAT_WIDTH == 32: float32 else: float64)\n" &
      "const TOLERANCE_ABS* = Coefficient(10.pow(-FLOAT_TOLERANCE.float))\n\n\n" &
      "const\n  A = 1\n  B = 2\n"
    check blocks.messages == @["2: " & BLOCK & "0`", "5: " & BLOCK & "2`"]
    check blocks.fixed == "type Coefficient* = (when FLOAT_WIDTH == 32: float32 else: float64)\n" &
      "\nconst TOLERANCE_ABS* = Coefficient(10.pow(-FLOAT_TOLERANCE.float))\n\n" &
      "const\n  A = 1\n  B = 2\n"
    check blocks.fixed.isSettled
    check "let a = 1  ## One.\nlet b = 2  ## Two.\n".isSettled  # bindings share keyword (X.5)
    check "let a = 1  ## One.\n# Why.\nlet b = 2  ## Two.\n".messages == @["3: " & BLOCK & "0`"]
    let routine = "proc fill() =\n  discard\n\nvar MULTIVECTORS: array[SAMPLES, Multivector]\n"
    check routine.messages == @["4: " & TWO & "1`"]
    check routine.fixed.isSettled


  test "documented one-line definition takes one after any definition, as one below sets (Q3)":
    # Cases: `algebra.nim:336`, two after documented one-line; `cayleys.nim:664` and
    #   `multivectors.nim:355`, two after routine of several lines; `algebra.nim:325`, one.
    let docs = "template low*[G: Grade | GradeAnti](t: typedesc[G]): G = G(0)\n" &
      "  ## Alias (anti)scalar's (anti)grade index.\n\n\n" &
      "template high*[G: Grade | GradeAnti](t: typedesc[G]): G = G(DIMENSIONS)\n" &
      "  ## Alias (anti)antiscalar's (anti)grade index.\n"
    check docs.messages == @["5: " & DOC & "2`"]
    check docs.fixed == docs.replace("index.\n\n\ntemplate", "index.\n\ntemplate")
    let long = "func sign(): BasisSigned =\n  result.basis = BasisSigned(\n    basis: b,\n" &
      "  )\n\n\n" &
      "func toSigned(b: Basis): BasisSigned {.compileTime, noinit.} = BasisSigned(basis: b)\n" &
      "  ## Convert basis to signed basis assuming positive.\n\n\n" &
      "template isMixed*(m: Multivector): bool = m.grade.isNone  ## Mixed grade.\n"
    check long.messages == @["7: " & DOC & "2`", "11: " & DOC & "2`"]
    check long.fixed == long.replace(")\n\n\nfunc", ")\n\nfunc").replace(
      "positive.\n\n\ntemplate", "positive.\n\ntemplate"
    )
    for settled in [docs.fixed, long.fixed]:
      check settled.isSettled
    let one = "template vectorAnti*[G: Grade | GradeAnti](t: typedesc[G]): G =\n" &
      "  ## Alias antigrade of (anti)vectors.\n" &
      "  when G is GradeAnti: G(1) else: G(DIMENSIONS - 1)\n\n" &
      "template vectorLast*(t: typedesc[Basis]): Basis = Basis(DIMENSIONS)\n  ## Alias.\n"
    check one.isSettled


  test "documented one-line call after routine takes one, as Q3 gives documented definition":
    # Ruling `D3 a` of #980: documented one-line call after routine reads Q3, never bullet of call
    #   after routine; call with no doc, or over lines, takes up to two still.
    let
      routine = "template foo*(x: int) = discard  ## Do.\n\n\nproc r*() =\n  ## Do.\n  discard\n"
      documented = routine & "\n\nfoo(1)  ## Count.\n"
    check documented.messages == @["9: " & DOC & "2`"]
    check documented.fixed == routine & "\nfoo(1)  ## Count.\n"
    check documented.fixed.isSettled
    check (routine & "foo(1)  ## Count.\n").messages == @["7: " & DOC & "0`"]
    for kept in [
      routine & "\n\nfoo(1)\n",  # no doc: call after routine takes up to two
      routine & "foo(1)\n",
      routine & "\n\nfoo(\n  1,\n)  ## Count.\n",  # call over lines is no one-line definition
    ]:
      check kept.isSettled


  test "undocumented one-line helpers stack; borrow counts as one line; first helper takes two":
    # Cases: `cayleys.nim:49` and `50`, borrow and iterator under type; `algebra.nim:121`,
    #   borrows that stack, one of them wrapped.
    let unit = "## Define type definition for transwedge order.\n" &
      "type Order = distinct range[0..DIMENSIONS]\n#func `<=`(a, b: Order): bool {.borrow.}\n" &
      "func `==`(a, b: Order): bool {.borrow.}\n" &
      "iterator items(t: typedesc[Order]): Order =\n  for i in 0..DIMENSIONS: yield Order(i)\n"
    check unit.messages == @["4: " & TWO & "0`", "5: " & TWO & "0`"]
    check unit.fixed == "## Define type definition for transwedge order.\n" &
      "type Order = distinct range[0..DIMENSIONS]\n\n\n#func `<=`(a, b: Order): bool {.borrow.}\n" &
      "func `==`(a, b: Order): bool {.borrow.}\n\n\n" &
      "iterator items(t: typedesc[Order]): Order =\n  for i in 0..DIMENSIONS: yield Order(i)\n"
    check unit.fixed.isSettled
    let stacked = "func `&`(a, b: BasisDigits): BasisDigits {.borrow, compileTime.}\n" &
      "func `and`(a, b: BasisFlags): BasisFlags {.borrow, compileTime, used.}  # Used there.\n" &
      "func `or`(\n  a, b: BasisFlags\n): BasisFlags {.borrow, compileTime.}\n" &
      "func `$`(b: BasisDigits): string = string(b)\n\n" &
      "func `in`(c: char, b: BasisDigits): bool = c in string(b)\n\n\n" &
      "func `not`(b: BasisFlags): BasisFlags {.borrow.}\n"
    check stacked.isSettled  # groups of helpers take up to two between them
    let wide = "func a(x: int): int = x\n\n\n\nfunc b(x: int): int = x\n"
    check wide.messages.len == 1
    check wide.fixed == "func a(x: int): int = x\n\n\nfunc b(x: int): int = x\n"


  test "declarative calls stack in their family, and run of two or more becomes one":
    # Case: `operators.nim:258`, two lines after `when` whose last call is of one family.
    let calls = "defineOperator(\n  symbols = \"⊖\",\n)\nwhen IS_CONFORMAL:\n" &
      "  defineOperator(\n    symbols = \"⊟\",\n  )\n\n\ndefineOperator(\n  symbols = \"⟑\",\n)\n" &
      "\ndefineOperator(symbols = \"∧\")\n"
    check calls.messages == @["10: " & FAMILY & "2`"]
    check calls.fixed == calls.replace("  )\n\n\ndefine", "  )\n\ndefine")
    check calls.fixed.isSettled
    let template_call = "template borrowOperationsGrade(T: typedesc) =\n" &
      "  func `-`*(g, h: T): T {.borrow.}\n\nborrowOperationsGrade(Grade)\n" &
      "borrowOperationsGrade(GradeAnti)\n"
    check template_call.isSettled  # call stacks right under its template (STYLE.md §2)


  test "comment or doc right above definition stands with it, and run above it is read":
    # Case: `algebra.nim:120`, borrows under group comment of two lines, one line after type.
    let commented = "type\n  GradeAnti* = distinct int  ## Define antigrade selector.\n\n" &
      "# Borrow necessary functions for using distinct types.\n" &
      "#   Ideally Nim would auto borrow.\n" &
      "func `&`(a, b: BasisDigits): BasisDigits {.borrow, compileTime.}\n"
    check commented.messages == @["6: " & TWO & "1`"]
    check commented.fixed == commented.replace("selector.\n\n#", "selector.\n\n\n#")
    check commented.fixed.isSettled
    let free = "proc a() =\n  discard\n\n# Free comment, which names no definition.\n\n" &
      "proc b() =\n  discard\n"
    check free.isSettled  # run after free comment is not read


  test "`when` counts as definition it holds first, below it as one it holds last; branch alike":
    # Cases: `cayleys.nim:217`, `when` of const after const; `operators.nim:331`, `336` and
    #   `340`, routines of several lines in `when` branch and around it; `operators.nim:408`.
    let branches = "const\n  A = (\n    1\n  )\nwhen IS_CONFORMAL:\n  const B = 2\n" &
      "  func f(): int =\n    1\n\n  func g(): int =\n    2\n\n" &
      "when IS_CONFORMAL:\n  func h(): int =\n    3\n  \n  func k(): int =\n    4\n" &
      "else:\n\n  func k(): int =\n    5\n\n  echo 1\n  func m() =\n    discard\n"
    check branches.messages == @[
      "5: " & BLOCK & "0`", "7: " & TWO & "0`", "10: " & TWO & "1`", "13: " & TWO & "1`",
      "17: " & TWO & "1`",
    ]
    check branches.fixed == "const\n  A = (\n    1\n  )\n\nwhen IS_CONFORMAL:\n" &
      "  const B = 2\n\n\n  func f(): int =\n    1\n\n\n  func g(): int =\n    2\n\n\n" &
      "when IS_CONFORMAL:\n  func h(): int =\n    3\n\n\n  func k(): int =\n    4\n" &
      "else:\n\n  func k(): int =\n    5\n\n  echo 1\n  func m() =\n    discard\n"
    check branches.fixed.isSettled


  test "first definition after imports takes two, as every other definition does":
    # Case: `emitters.nim:9`, first routine after imports in module with no banner.
    let imports = "{.experimental: \"strictFuncs\".}\n\nimport std/macros\n\nimport ./algebra\n\n" &
      "func emitFunc*(name, docs: string): NimNode {.compileTime.} =\n  ## Emit AST.\n  discard\n"
    check imports.messages == @["7: " & TWO & "1`"]
    check imports.fixed == imports.replace("algebra\n\nfunc", "algebra\n\n\nfunc")
    check imports.fixed.isSettled


  test "documented one-line definition after imports takes one, as one below sets (Q3)":
    # Case: `tools/head.nim:17` of `pga_visualiser` at `16a573cc`, two lines after imports.
    let imports = "{.experimental: \"strictFuncs\".}\n\nimport std/json\n\n\n" &
      "const DIGITS_SHORT = 7  ## Digits of commit finding names, as `git log --oneline` " &
      "prints.\n"
    check imports.messages == @["6: " & DOC & "2`"]
    check imports.fixed == imports.replace("json\n\n\nconst", "json\n\nconst")
    check imports.fixed.isSettled
    check "import std/json\n\nfunc d*(): int = 1  ## Count.\n".isSettled  # routine alike
    check "template foo*(x: int) = discard  ## Do.\nimport std/json\n\nfoo(1)  ## Count.\n"
      .isSettled  # call alike


  test "sibling inside second-tier section takes one, and first-tier sibling takes two (Q1)":
    # Case: `operators.nim:346`, two lines once `#[[ Norms ]]#` is second tier, as hand writes
    #   it; knoller changes tier of no banner.
    let second = "#[[ Norms ]]#\n\nfunc `|∘`*(m: Multivector): MultivectorScalars =\n" &
      "  discard\n\n" &
      "when IS_CONFORMAL:\n  func `|■`*(m: Multivector): MultivectorScalars =\n    discard\n\n" &
      "  func `|□`*(m: Multivector): MultivectorScalars =\n    discard\n\n\n" &
      "func `|`*(m: Multivector): MultivectorScalars =\n  discard\n"
    check second.messages ==
      @["14: sibling inside second-tier section takes one blank line before it; got `2`"]
    check second.fixed == second.replace("    discard\n\n\nfunc", "    discard\n\nfunc")
    check second.fixed.isSettled
    let first = second.replace("#[[ Norms ]]#", "#[ Norms ]#")
    check first.messages == @["6: " & TWO & "1`", "10: " & TWO & "1`"]
    check first.fixed.isSettled
    let quoted = "const TEXT = \"\"\"\n#[[ Parts. ]]#\n\"\"\"  ## Text.\n\n\n" &
      "proc a*() =\n  ## Do.\n  discard\n\n\nproc b*() =\n  ## Do.\n  discard\n"
    check quoted.isSettled  # probe of critic: banner inside string gives no tier


  test "doc is `##` comment on head line or inside item, never `##` inside `#` comment":
    # Probe of reviewer: comment holding `##` read as doc, so one line passed after routine.
    let source = "proc r*() =\n  ## Do.\n  discard\n\nfunc b(): int = 1  # Not ## a doc.\n"
    check source.messages == @["5: " & TWO & "1`"]
    check source.replace("# Not ## a doc", "## Count").isSettled  # doc on head line


  test "each pair of forms takes count X.2 gives it, and second tier caps each bound at one":
    # Law over small domain: form above, form below, count 0 to 3, and tier of section. Row
    #   gives counts first-tier run passes with; second tier caps each bound at one (Q1).
    #   Documented one-line call reads Q3 after routine (ruling `D3 a` of #980). Imports stand
    #   above alone, since rule reads no run before them.
    const
      forms = [
        ("call", "foo(1)\n"),
        ("routine", "proc r*() =\n  ## Do.\n  discard\n"),
        ("helper", "func h(): int = 1\n"),
        ("documented", "func d*(): int = 1  ## Count.\n"),
        ("block", "const\n  A* = 1  ## Count.\n"),
        ("documented call", "foo(2)  ## Count.\n"),
        ("imports", "import std/strutils\n"),
      ]  ## Name and text of each form, call of template module declares among them.
      counts = [
        [0 .. 1, 2 .. 2, 2 .. 2, 1 .. 1, 2 .. 2, 0 .. 1],  # call above
        [0 .. 2, 2 .. 2, 2 .. 2, 1 .. 1, 2 .. 2, 1 .. 1],  # routine of several lines above
        [0 .. 2, 2 .. 2, 0 .. 2, 1 .. 1, 2 .. 2, 1 .. 1],  # undocumented one-line helper above
        [0 .. 2, 2 .. 2, 2 .. 2, 1 .. 1, 2 .. 2, 1 .. 1],  # documented one-line routine above
        [2 .. 2, 2 .. 2, 2 .. 2, 1 .. 1, 1 .. 1, 1 .. 1],  # declaration block above
        [0 .. 1, 2 .. 2, 2 .. 2, 1 .. 1, 2 .. 2, 0 .. 1],  # documented one-line call above
        [2 .. 2, 2 .. 2, 2 .. 2, 1 .. 1, 2 .. 2, 1 .. 1],  # imports above
      ]  ## Counts passing between form above, by row, and form below, by column, as `forms`.
    for a in 0 ..< forms.len:
      for b in 0 ..< forms.len - 1:
        for is_second in [false, true]:
          for count in 0 .. 3:
            let
              banner = if is_second: "#[[ Parts. ]]#\n\n" else: ""
              head = "template foo*(x: int) = discard  ## Do.\n\n\n" & banner & forms[a][1]
              source = head & "\n".repeat(count) & forms[b][1]
              line = head.count('\n') + count + 1
              first = counts[a][b]
              passed = if is_second: min(first.a, 1) .. min(first.b, 1) else: first
            checkpoint forms[a][0] & " then " & forms[b][0] & ", " & $count & " blank lines, " &
              (if is_second: "second tier" else: "first tier")
            check checkDefinitions(PATH, source).anyIt(it.line == line) == (count notin passed)


  test "never read: run beside banner or nested helper, after statement or pragma, in string":
    for kept in [
      "proc a() =\n  discard\n\n\n\n#[ Section ]#\n\n\nproc b() =\n  discard\n",  # banner's
      "proc a() =\n  discard\n#[[ Part ]]#\nproc b() =\n  discard\n",
      "proc f() =\n  proc g() =\n    discard\n  proc h() =\n    discard\n  g()\n",  # nested
      "{.push raises: [].}\nproc a() =\n  discard\n{.pop.}\nproc b() =\n  discard\n",  # pragma
      "echo 1\nproc a() =\n  discard\nstatic:\n  discard\nproc b() =\n  discard\n",  # statement
      "const F = \"\"\"\nproc a() =\n  discard\nproc b() =\n  discard\n\"\"\"\n",  # string
      "when isMainModule:\n  main()\nproc b() =\n  discard\n",  # `when` of statement
      "proc a() =\n  discard\n\n\n\n\n",  # no definition below
    ]:
      check kept.isSettled
