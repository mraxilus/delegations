## Hold separators of parameters (STYLE.md §5): each breach is reported and fixed; what
##   rule leaves to hand is neither; fix changes nothing else, and nothing second time.

{.experimental: "strictFuncs".}

import std/[sequtils, unittest]
import ../../src/[findings, wrapping]


func fixed(source: string): string =
  ## Fix wrapping of source, as `koch fix` does.
  fixWrapping("a.nim", source).source


func messages(source: string): seq[string] =
  ## Collect messages every wrapping check reports over source.
  checkSeparators("a.nim", source).mapIt(it.message)


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
    check wrapped.fixed.isSettled
    let typed = "type P = proc (a: int; b: int): int\nlet l = proc (a: int; b: int): int = a\n"
    check typed.fixed ==
      "type P = proc (a: int, b: int): int\nlet l = proc (a: int, b: int): int = a\n"
    let untyped = "template t(a; b: int) = discard\n"
    check untyped.fixed == untyped  # group without type is read by no rule

  test "clean source passes through unchanged":
    let clean = "proc f(a: int, b: string): int =\n  foo(a, b)\n\nlet x = @[\n  1,\n  2,\n]\n"
    check clean.isSettled
