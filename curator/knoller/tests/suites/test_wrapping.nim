## Hold separators and wrapping of lists (Article X.3, STYLE.md §5): each breach is reported and
##   fixed into its one layout; what rule leaves to hand is neither; fix changes nothing else,
##   and nothing second time.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/knoller/[reports, tokens, wrapping]


const
  EXAMPLE_PARAMETERS_LINE =
    "func filterFactors(\n" &
    "  cayley: var Cayley1D, factors: seq[Basis], as_exclusions = false\n" &
    ") {.compileTime.} =\n" &
    "  discard\n"
    ## STYLE.md §5, first signature example, as written there.
  EXAMPLE_GROUPS =
    "func constructProductsTransitional(\n" &
    "  complement, dual: Cayley1D; wedges: Spatial[Cayley2D]; chirality: Chirality; " &
    "space: Space\n" &
    "): array[Order, Cayley2D] {.compileTime.} =\n" &
    "  discard\n"
    ## STYLE.md §5, second signature example, as written there.
  EXAMPLE_CALL =
    "const\n" &
    "  CAYLEY_EXPAND_BULK_RIGHT* = constructProductInterior(\n" &
    "    CAYLEYS_DUAL.base.right,\n" &
    "    CAYLEYS_WEDGE.base,\n" &
    "    Chirality.Right,\n" &
    "  )\n"
    ## STYLE.md §5 call example, as written there.
  EXAMPLE_DECLARATIVE =
    "defineOperator(\n" &
    "  symbols = \"∧\",\n" &
    "  docs = \"Multiply multivectors through exterior product, i.e. 𝐦 ∧ 𝐧.\",\n" &
    "  cayley = CAYLEYS_WEDGE.base,\n" &
    ")\n"
    ## Article X example of declarative call, as written there.
  LONG_NAME = "constructProductsAcrossEveryOrderOfGradeAndChirality"
    ## Name long enough to push signature or call past `LINE_MAX`.


func fixed(source: string): string =
  ## Fix wrapping of source, as `koch fix` does.
  fixWrapping("a.nim", source).source


func messages(source: string): seq[string] =
  ## Collect messages every wrapping check reports over source.
  (checkSeparators("a.nim", source) & checkSignatures("a.nim", source) &
    checkCalls("a.nim", source) & checkTrailing("a.nim", source)).mapIt(it.message)


func isSettled(source: string): bool =
  ## Decide whether source reports no wrapping finding and fixes to itself again.
  source.messages.len == 0 and fixWrapping("a.nim", source).source == source and
    fixWrapping("a.nim", source).fixed.len == 0


func operatorsOf(source: string): seq[string] =
  ## Read spelling of each operator token of source, in order.
  for t in source.tokens:
    if t.kind == TokenKind.Operator: result.add t.spelling(source)


func isBrokenAlone(source: string): bool =
  ## Decide whether fix breaks lines alone: operator tokens read same in same order, and fixed
  ##   source settles.
  source.fixed.operatorsOf == source.operatorsOf and source.fixed.isSettled



suite "Wrapping":
  test "parameters take `,` while each type appears once, and `;` where group shares one":
    let breach = "proc f(a: int; b: string) = discard\nproc g(a, b: int, c: string) = discard\n"
    check checkSeparators("a.nim", breach).len == 2
    check fixSeparators("a.nim", breach).source ==
      "proc f(a: int, b: string) = discard\nproc g(a, b: int; c: string) = discard\n"
    check breach.fixed.isSettled
    let wrapped = "proc g(\n  a, b: int,\n  c: string,\n) = discard\n"
    check fixSeparators("a.nim", wrapped).source ==
      "proc g(\n  a, b: int;\n  c: string;\n) = discard\n"  # trailing too, lines kept
    check wrapped.fixed == "proc g(a, b: int; c: string) = discard\n"  # then joined, as it fits
    let typed = "type P = proc (a: int; b: int): int\nlet l = proc (a: int; b: int): int = a\n"
    check typed.fixed ==
      "type P = proc (a: int, b: int): int\nlet l = proc (a: int, b: int): int = a\n"
    let untyped = "template t(a; b: int) = discard\n"
    check untyped.fixed == untyped  # group without type is read by no rule


  test "tuple type takes `,` between fields, its comments kept":
    let tuples = "type T = tuple[a, b: int; c: string]\nlet u: tuple[\n  x: int;  # Why.\n" &
      "  y: int;\n] = (1, 2)\n"
    check checkSeparators("a.nim", tuples).mapIt(it.message).allIt(it.startsWith("Tuple type"))
    check fixSeparators("a.nim", tuples).source == "type T = tuple[a, b: int, c: string]\n" &
      "let u: tuple[\n  x: int,  # Why.\n  y: int,\n] = (1, 2)\n"
    check checkSeparators("a.nim", "let p = (a; b)\n").len == 0  # statement list, no tuple


  test "signature that fits joins one line; one that fits nowhere takes one group to line":
    let joined = "func f(\n    a: int, b: int\n): int =\n  a\n"
    check checkSignatures("a.nim", joined)[0].message.endsWith("got `3` lines.")
    check fixSignatures("a.nim", joined).source == "func f(a: int, b: int): int =\n  a\n"
    check fixSignatures("a.nim", joined).fixed[0].rule == Rule.SignatureWrapping
    let
      groups = ["alpha: Cayley1D", "beta: Spatial[Cayley2D]", "gamma: Chirality", "delta: Space",
                "epsilon: Grade", "zeta: Order"]
      wide = "func " & LONG_NAME & "(" & groups.join(", ") & "): int =\n  discard\n"
    check wide.fixed == "func " & LONG_NAME & "(\n" & groups.mapIt("  " & it & ",\n").join &
      "): int =\n  discard\n"  # parameters fit no line of their own either
    check wide.fixed.isSettled


  test "parameters take one line of their own where it fits, so one layout stands for each":
    check EXAMPLE_PARAMETERS_LINE.isSettled
    let indented = EXAMPLE_PARAMETERS_LINE.replace("\n  cayley", "\n    cayley")
    check indented.fixed == EXAMPLE_PARAMETERS_LINE  # re-indented one level
    let flat = "func filterFactors(cayley: var Cayley1D, factors: seq[Basis], as_exclusions = " &
      "false) {.compileTime.} =\n  discard\n"
    check flat.fixed == EXAMPLE_PARAMETERS_LINE  # 102 runes on one line
    check EXAMPLE_GROUPS.isSettled
    let group_lines = "func constructProductsTransitional(\n  complement, dual: Cayley1D;\n" &
      "  wedges: Spatial[Cayley2D];\n  chirality: Chirality;\n  space: Space;\n" &
      "): array[Order, Cayley2D] {.compileTime.} =\n  discard\n"
    check group_lines.fixed == EXAMPLE_GROUPS  # parameters line of 91 runes fits
    let single = "proc " & LONG_NAME & "(parameter_named_at_length: Multivector): Multivector =\n"
    check single.fixed == "proc " & LONG_NAME & "(\n  parameter_named_at_length: Multivector,\n" &
      "): Multivector =\n"  # one item to line takes separator
    check single.fixed.isSettled


  test "signature holding comment, or fitting where body after `=` does not, stays":
    let commented = "func f(\n  a: int,  # Why.\n  b: int,\n): int = a\n"
    check commented.fixed == commented
    let body = "func f(a: int): int = " & "a + ".repeat(20) & "a\n"
    check checkSignatures("a.nim", body).len == 0  # moving body and wrapping are two answers


  test "call that fits joins; one that fits not takes one argument to line, trailing comma":
    check fixCalls("a.nim", "foo(\n  a,\n  b,\n)\n").source == "foo(a, b)\n"
    check fixCalls("a.nim", "x\nfoo(\n  a,\n)\ny\n").fixed.mapIt(it.line) == @[2]  # line as given
    check "if foo(\n  a,\n):\n  discard\n".fixed == "if foo(a):\n  discard\n"  # `:` of `if`
    let wide = "  result.add " & LONG_NAME & "(path, line, \"message long enough to cross " &
      "column one hundred\")\n"
    check wide.fixed == "  result.add " & LONG_NAME & "(\n    path,\n    line,\n" &
      "    \"message long enough to cross column one hundred\",\n  )\n"
    let own_line = "  result.add finding(\n    path, 0, \"" & "x".repeat(84) & "\",\n  )\n"
    check own_line.fixed == "  result.add finding(\n    path,\n    0,\n    \"" & "x".repeat(84) &
      "\",\n  )\n"  # never all arguments on one line of their own
    for example in [EXAMPLE_CALL, EXAMPLE_DECLARATIVE]: check example.isSettled


  test "outermost call crossing column splits first, then each line it leaves":
    let nested = "let x = outer(first_argument_of_outer, " & LONG_NAME & "(inner_first, " &
      "inner_second_argument))\n"
    check nested.fixed == "let x = outer(\n  first_argument_of_outer,\n  " & LONG_NAME &
      "(inner_first, inner_second_argument),\n)\n"
    check nested.fixed.isSettled


  test "argument wrapped by hand keeps its breaks, and hand-shaped list keeps its rows":
    let continued = "  result.add finding(\n    path, 0,\n    \"" & "x".repeat(90) & "\" &\n" &
      "      name,\n  )\n"
    check continued.fixed == "  result.add finding(\n    path,\n    0,\n    \"" & "x".repeat(90) &
      "\" &\n        name,\n  )\n"  # continuation four spaces in (STYLE.md §5)
    let rows = "check foo(bar, @[\n  1, 2,\n  3, 4,\n])\n"
    check rows.fixed == "check foo(\n  bar,\n  @[\n    1, 2,\n    3, 4,\n  ],\n)\n"
    check rows.fixed.isSettled


  test "line no call split fits breaks after operator of lowest precedence, latest that fits":
    let
      sum = "offset_x * bounds.forward.x + offset_y * bounds.forward.y + " &
        "offset_z * bounds.forward.z"
      statement = "  let depth = " & sum & "\n"  # 101 runes
    check statement.fixed == "  let depth = offset_x * bounds.forward.x + offset_y * " &
      "bounds.forward.y +\n      offset_z * bounds.forward.z\n"  # `+` before `*`, second `+`
    check checkCalls("a.nim", statement).mapIt(it.rule) == @[Rule.OperatorWrapping]
    let mixed = "  check " & "a".repeat(40) & " + " & "b".repeat(20) & " and " &
      "c".repeat(30) & "\n"
    check mixed.fixed == "  check " & "a".repeat(40) & " + " & "b".repeat(20) & " and\n" &
      "      " & "c".repeat(30) & "\n"  # `and` binds loosest, so breaks first
    for source in [statement, mixed]: check source.isBrokenAlone


  test "operator break holds inside split call, under `if`, and on continuation line":
    let call = "  result.add finding(path, \"" & "x".repeat(60) & "\" & name & \"" &
      "y".repeat(30) & "\")\n"
    check call.fixed == "  result.add finding(\n    path,\n    \"" & "x".repeat(60) &
      "\" & name &\n        \"" & "y".repeat(30) & "\",\n  )\n"  # argument breaks four in
    let condition = "  if " & "a".repeat(45) & " and " & "b".repeat(45) & ":\n    discard\n"
    check condition.fixed == "  if " & "a".repeat(45) & " and\n      " & "b".repeat(45) &
      ":\n    discard\n"  # condition four in, body two
    let continued = "  let x = first +\n      " & "a".repeat(45) & " + " & "b".repeat(47) & "\n"
    check continued.fixed == "  let x = first +\n      " & "a".repeat(45) & " +\n      " &
      "b".repeat(47) & "\n"  # continuation line keeps its indent
    let ranged = "  let r = " & "a".repeat(44) & " ..^ " & "b".repeat(45) & "\n"
    check ranged.fixed == "  let r = " & "a".repeat(44) & " ..^\n      " & "b".repeat(45) &
      "\n"  # compound operator stays whole
    for source in [call, condition, continued, ranged]: check source.isBrokenAlone


  test "call split comes before operator break, and line it cannot break stays":
    let split = "  let total = first_value + combine(alpha_argument, beta_argument, " &
      "gamma_argument, delta_argument_name)\n"  # 103 runes
    check split.fixed == "  let total = first_value + combine(\n    alpha_argument,\n" &
      "    beta_argument,\n    gamma_argument,\n    delta_argument_name,\n  )\n"
    for kept in [
      "  let x = " & "a".repeat(45) & " + " & "b".repeat(45) & "  # Why.\n",  # comment
      "  let x = " & "a".repeat(30) & " + " & "b".repeat(48) & " * " & "c".repeat(48) & "\n",
      "foo(\n  " & "a".repeat(60) & " &\n      " & "b".repeat(60) & ",\n)\n",  # by hand
      "  let x = " & "a".repeat(45) & " in " & "b".repeat(45) & "\n",  # membership
      "  if a: " & "b".repeat(45) & " + " & "c".repeat(45) & "\n",  # `:` before code
    ]:
      check kept.fixed == kept
      check checkCalls("a.nim", kept).len == 0


  test "continuation takes four spaces more than line opening it; call keeps one level":
    let hand = "let x = a +\n  b\ncheck c ==\n  d +\n  e\n"
    check checkContinuations("a.nim", hand).mapIt(it.line) == @[2, 4, 5]
    check checkContinuations("a.nim", hand)[0].message.endsWith("got `2`.")
    check hand.fixed == "let x = a +\n    b\ncheck c ==\n    d +\n    e\n"
    check hand.fixed.isSettled
    # Last line of 100 runes two spaces in crosses `LINE_MAX` four spaces in.
    let packed = "let x = a +\n  b +\n  " & "c".repeat(48) & " * " & "d".repeat(47) & "\n"
    check packed.fixed == packed  # run stays whole where one line would widen
    check checkContinuations("a.nim", packed).mapIt(it.line) == @[2, 3]  # findings stay
    for kept in [
      "if a and\n    b:\n  discard\n",  # condition four in already
      EXAMPLE_CALL,  # arguments one level in
      "let x = a +\n  # Why.\n  b\n",  # comment line between
      "let x = a +\n  @[\n    1,\n  ]\n",  # last line leaves bracket open
      "let x =\n  a\n",  # `=` ends no expression
    ]:
      check checkContinuations("a.nim", kept).len == 0
      check kept.fixed == kept


  test "call holding comment, long string spanning lines, or block stays":
    for kept in [
      "foo(\n  a,  # Why.\n  b\n)\n",
      "foo(\n  \"\"\"\ntext\n\"\"\",\n)\n",
      "foo(a,\n  proc () = discard)\n",
      "test(\"name\"):\n  discard\n",
      "foo(a) do (x: int):\n  discard\n",
    ]:
      check checkCalls("a.nim", kept).len == 0
    check "foo(\n  a,  # Why.\n  b\n)\n".fixed == "foo(\n  a,  # Why.\n  b,\n)\n"  # trailing alone


  test "list written one item to line takes trailing separator":
    let lists = "let\n  a = @[\n    1,\n    2\n  ]\n  b = {\n    'x',\n    'y'\n  }\n" &
      "  c = (\n    1,\n    2\n  )\n  d = Foo(\n    x: 1,  # Why.\n    y: 2\n  )\n"
    check checkTrailing("a.nim", lists).len == 4
    check lists.fixed == lists.replace("2\n  ]", "2,\n  ]").replace("'y'\n", "'y',\n")
      .replace("2\n  )\n  d", "2,\n  )\n  d").replace("y: 2\n", "y: 2,\n")
    check lists.fixed.isSettled
    let imported = "import ./[\n  a,\n  b\n]\n"
    check imported.fixed == "import ./[\n  a,\n  b,\n]\n"
    check fixTrailing("a.nim", imported).source == imported.fixed  # rule alone writes it
    for kept in [
      "let a = (\n  b\n)\n",
      "let a = @[1, 2,\n  3, 4]\n",
      "type T = array[\n  3,\n  int\n]\n",
    ]:
      check checkTrailing("a.nim", kept).len == 0  # grouping, flowed list, type bracket


  test "trailing separator held on no line widens it, and keeps width guard on held line":
    # Item line of 100 runes; separator makes 101.
    let near = "let a = @[\n  1,\n  " & "x".repeat(48) & " + " & "y".repeat(47) & "\n]\n"
    check fixTrailing("a.nim", near, Held()).source == near.replace("y\n]", "y,\n]")
    check fixTrailing("a.nim", near, Held(lines: @[3])).source == near  # its line held
    check near.fixed == near  # two-argument form holds every line


  test "clean source passes through unchanged":
    let clean = "proc f(a: int, b: string): int =\n  foo(a, b)\n\nlet x = @[\n  1,\n  2,\n]\n"
    check clean.isSettled
