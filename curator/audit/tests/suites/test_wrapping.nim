## Hold separators of parameters and wrapping of signatures (Article X.3, STYLE.md §5): each
##   breach is reported and fixed into its one layout; what rule leaves to hand is neither;
##   fix changes nothing else, and nothing second time.

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
  LONG_NAME = "constructProductsAcrossEveryOrderOfGradeAndChirality"
    ## Name long enough to push signature or call past `LINE_MAX`.


func fixed(source: string): string =
  ## Fix wrapping of source, as `koch fix` does.
  fixWrapping("a.nim", source).source


func messages(source: string): seq[string] =
  ## Collect messages every wrapping check reports over source.
  (checkSeparators("a.nim", source) & checkSignatures("a.nim", source)).mapIt(it.message)


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

  test "clean source passes through unchanged":
    let clean = "proc f(a: int, b: string): int =\n  foo(a, b)\n\nlet x = @[\n  1,\n  2,\n]\n"
    check clean.isSettled
