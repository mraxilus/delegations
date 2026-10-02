## Hold separators and wrapping of lists (Article X.3, STYLE.md §5): each breach is reported and
##   fixed into its one layout; what rule leaves to hand is neither; fix changes nothing else,
##   and nothing second time.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/[findings, wrapping]


const
  EXAMPLE_PARAMETERS_LINE =
    "func filterFactors(\n" &
    "  cayley: var Cayley1D, factors: seq[Basis], as_exclusions = false\n" &
    ") {.compileTime.} =\n" &
    "  discard\n"
    ## STYLE.md §5, first signature example, as written there.
  EXAMPLE_GROUP_LINES =
    "func constructProductsTransitional(\n" &
    "  complement, dual: Cayley1D;\n" &
    "  wedges: Spatial[Cayley2D];\n" &
    "  chirality: Chirality;\n" &
    "  space: Space;\n" &
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

  test "signature that fits joins one line; one that fits nowhere takes one group to line":
    let joined = "func f(\n    a: int, b: int\n): int =\n  a\n"
    check checkSignatures("a.nim", joined)[0].message.endsWith("got `3` lines.")
    check fixSignatures("a.nim", joined).source == "func f(a: int, b: int): int =\n  a\n"
    check fixSignatures("a.nim", joined).fixed[0].message == "signature wrapping (X.3) fixed"
    let
      groups = ["alpha: Cayley1D", "beta: Spatial[Cayley2D]", "gamma: Chirality", "delta: Space",
                "epsilon: Grade", "zeta: Order"]
      wide = "func " & LONG_NAME & "(" & groups.join(", ") & "): int =\n  discard\n"
    check wide.fixed == "func " & LONG_NAME & "(\n" & groups.mapIt("  " & it & ",\n").join &
      "): int =\n  discard\n"  # parameters fit no line of their own either
    check wide.fixed.isSettled

  test "STYLE.md §5 examples stand as written; layout author chose stands where both fit":
    for example in [EXAMPLE_PARAMETERS_LINE, EXAMPLE_GROUP_LINES]:
      check example.isSettled
    let indented = EXAMPLE_PARAMETERS_LINE.replace("\n  cayley", "\n    cayley")
    check indented.fixed == EXAMPLE_PARAMETERS_LINE  # re-indented one level
    let flat = "func filterFactors(cayley: var Cayley1D, factors: seq[Basis], as_exclusions = " &
      "false) {.compileTime.} =\n  discard\n"
    check flat.fixed == flat  # both layouts stand, so one-line form too wide waits for hand

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
      "\" &\n      name,\n  )\n"
    let rows = "check foo(bar, @[\n  1, 2,\n  3, 4,\n])\n"
    check rows.fixed == "check foo(\n  bar,\n  @[\n    1, 2,\n    3, 4,\n  ],\n)\n"
    check rows.fixed.isSettled

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

  test "clean source passes through unchanged":
    let clean = "proc f(a: int, b: string): int =\n  foo(a, b)\n\nlet x = @[\n  1,\n  2,\n]\n"
    check clean.isSettled
