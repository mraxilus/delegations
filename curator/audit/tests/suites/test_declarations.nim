## Hold where declaration states its doc and its type (Article VI.9, X.12; STYLE.md §5): each
##   breach is reported and fixed; doc of several lines, routine doc and default literal of
##   other type are neither; fix changes nothing else, and nothing second time.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/[declarations, findings]


func fixed(source: string): string =
  ## Fix docs, then defaults, of source, as `koch fix` does.
  let docs = fixDocs("a.nim", source).source
  fixDefaults("a.nim", docs).source


func isSettled(source: string): bool =
  ## Decide whether source reports no declaration finding and fixes to itself again.
  (checkDocs("a.nim", source) & checkDefaults("a.nim", source)).len == 0 and
    source.fixed == source


suite "Declarations":
  test "one-line doc of type, field, binding and enum member joins its line where it fits":
    let breach = "type\n  Kind {.pure.} = enum\n    ## Kind of thing.\n    A\n      ## First.\n" &
      "    B = 2\n      ## Second.\n\n  Obj* = object\n    ## Holder.\n    x*: int\n" &
      "      ## Count.\n\nconst\n  N* = 3\n    ## Size.\nlet m = 1\n  ## Mass.\n"
    check checkDocs("a.nim", breach).mapIt(it.line) == @[2, 4, 6, 9, 11, 15, 17]
    check breach.fixed == "type\n  Kind {.pure.} = enum  ## Kind of thing.\n    A  ## First.\n" &
      "    B = 2  ## Second.\n\n  Obj* = object  ## Holder.\n    x*: int  ## Count.\n\n" &
      "const\n  N* = 3  ## Size.\nlet m = 1  ## Mass.\n"
    check breach.fixed.isSettled
    check fixDocs("a.nim", breach).fixed[0].message == "doc position (STYLE.md §5)"

  test "doc that cannot join takes next line, one level in; trailing doc too wide moves there":
    let
      value = "  NAME = \"" & "x".repeat(60) & "\""
      doc = "## " & "y".repeat(40)
      settled = "const\n" & value & "\n    " & doc & "\n"
    check ("const\n" & value & "\n      " & doc & "\n").fixed == settled  # re-indented
    check ("const\n" & value & "  " & doc & "\n").fixed == settled  # 116 runes split
    check settled.isSettled

  test "doc of several lines, routine doc, and line that is no declaration stay":
    for kept in [
      "const\n  N = 3\n    ## Size,\n    ##   in units.\n",
      "proc f() =\n  ## Do.\n  discard\n",
      "func f(): int = 1\n  ## One.\n",
      "const\n  N = a +\n    b\n    ## Sum.\n",
      "const\n  T = [\n    1,\n  ]\n    ## Table.\n",
      "type\n  ## Group.\n  A = int\n",
      "const N = 3  # Why.\n  ## Size.\n",
      "proc f() =\n  let x = 1\n  ## Next.\n",
    ]:
      check kept.isSettled

  test "parameter drops type its literal default gives exactly":
    let breach = "proc f(now: float = 0.0, on: bool = false, s: string = \"a\", c: char = 'x', " &
      "n: int = -1) = discard\nproc g(a: Foo = default(Foo), b: Option[int] = none(int), " &
      "p, q: int = 0x1F) = discard\n"
    check checkDefaults("a.nim", breach).len == 8
    check breach.fixed == "proc f(now = 0.0, on = false, s = \"a\", c = 'x', n = -1) = discard\n" &
      "proc g(a = default(Foo), b = none(int), p, q = 0x1F) = discard\n"
    check breach.fixed.isSettled
    check fixDefaults("a.nim", breach).fixed[0].message == "literal default (X.12)"

  test "default of other type, named constant, template, macro and field stay":
    for kept in [
      "proc k(a: float = 0, b: cfloat = 0.0, c: HalfTurns = 0, d: int = SAMPLES) = discard\n",
      "proc k(e: float32 = 1.0, f: uint8 = 0'u8, g: string = r\"a\") = discard\n",
      "template t(a: int = 0) = discard\nmacro m(a: int = 0) = discard\n",
      "type O = object\n  x: int = 0\n",
    ]:
      check kept.isSettled
