## Hold that each declaration takes doc (Article VI.1), and where it states its doc and its type
##   (VI.9, X.12; STYLE.md §5): each breach is reported and fixed; doc of several lines, routine
##   doc and default literal of other type are neither; fix changes nothing else, and nothing
##   second time; source each fix writes parses.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/knoller/[declarations, reports]


func fixed(source: string): string =
  ## Fix docs, then defaults, of source, as `koch fix` does.
  let docs = fixDocs("a.nim", source).source
  fixDefaults("a.nim", docs).source


func isSettled(source: string): bool =
  ## Decide whether source reports no declaration finding and fixes to itself again.
  (checkDocs("a.nim", source) & checkDefaults("a.nim", source)).len == 0 and
    source.fixed == source


func fixedMissing(source: string): string =
  ## Fix missing docs of source, as `koch fix` does.
  fixDocsMissing("a.nim", source).source


func isSettledMissing(source: string): bool =
  ## Decide whether source reports no missing doc and fixes to itself again.
  checkDocsMissing("a.nim", source).len == 0 and source.fixedMissing == source



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
    check fixDocs("a.nim", breach).fixed[0].rule == Rule.PositionDoc


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
    check fixDefaults("a.nim", breach).fixed[0].rule == Rule.DefaultLiteral


  test "default of other type, named constant, template, macro and field stay":
    for kept in [
      "proc k(a: float = 0, b: cfloat = 0.0, c: HalfTurns = 0, d: int = SAMPLES) = discard\n",
      "proc k(e: float32 = 1.0, f: uint8 = 0'u8, g: string = r\"a\") = discard\n",
      "template t(a: int = 0) = discard\nmacro m(a: int = 0) = discard\n",
      "type O = object\n  x: int = 0\n",
    ]:
      check kept.isSettled


  test "declaration with no doc takes `TODO: Document.` where STYLE.md §5 puts it (VI.1)":
    # Case as found on review page of #443: library at `3d9696e` declared `DIMENSIONS` bare.
    let
      bare = "const\n  DIMENSIONS* {.define: \"pga.dimensions\".} = 4\n" &
          "type\n  Obj* = object\n    left*, right*: int\n" &
          "proc area*(o: Obj): int =\n  o.left * o.right\n"
      found = checkDocsMissing("a.nim", bare)
    check found.mapIt(it.line) == @[2, 4, 5, 6]
    check found[0].message == "Declaration takes doc comment; got `const DIMENSIONS`."
    check "got `field left, right`." in found[2].message  # names sharing line, once
    check "got `proc area`." in found[3].message
    check bare.fixedMissing == "const\n" &
        "  DIMENSIONS* {.define: \"pga.dimensions\".} = 4  ## TODO: Document.\n" &
        "type\n  Obj* = object  ## TODO: Document.\n    left*, right*: int  ## TODO: Document.\n" &
        "proc area*(o: Obj): int =\n  ## TODO: Document.\n  o.left * o.right\n"
    check bare.fixedMissing.isSettledMissing
    check fixDocsMissing("a.nim", bare).fixed[0].rule == Rule.DocMissing


  test "local binding, parameter and placeholder take no doc":
    # Architect's ruling on review page of #443.
    let source = "proc f*[T](x: T): T =\n  ## Echo.\n  let y = x\n  y\n"
    check checkDocsMissing("a.nim", source).len == 0
    let single = "type Kind* = enum  ## Kind.\n  A\n  B  ## Second.\n"
    check checkDocsMissing("a.nim", single).mapIt(it.line) == @[2]  # member alone on line


  test "enum members sharing line share its one doc, which describes each of them":
    # Architect's ruling on D1 of #752: members listed on one line share doc of that line.
    let
      shared = "type Kind* = enum  ## Kind.\n  A, B, C\n"
      found = checkDocsMissing("a.nim", shared)
    check found.mapIt(it.line) == @[2]  # line reports once
    check found[0].message == "Declaration takes doc comment; got `member A, B, C`."
    check shared.fixedMissing == "type Kind* = enum  ## Kind.\n  A, B, C  ## TODO: Document.\n"
    check shared.fixedMissing.isSettledMissing
    let documented = "type Kind* = enum  ## Kind.\n  A, B, C  ## Letters.\n"
    check checkDocsMissing("a.nim", documented).len == 0


  test "doc in each place rule of position reads passes, since place is that rule's":
    let placed = "let a = 1  ## Same line.\n" &
        "## Above, at its indent.\nlet b = 2\n" &
        "const C = [\n  1, 2,\n]\n  ## After closing bracket, as `TYPES_BUILTIN` stands.\n" &
        "const D = 4\n  ## Next line, one level in.\n" &
        "func e(): int =\n  ## Body's first line.\n  5\n" &
        "func g(): int = 6\n  ## One-line routine's next line.\n"
    check checkDocsMissing("a.nim", placed).len == 0


  test "doc awaiting text under other TODO reads `TODO: Document.`, and TODO moves above it":
    # Case as found on review page of #443: library doc `## TODO: Make distinct.`.
    let
      todo = "type\n  Grade* = int  ## TODO: Make distinct.\n" &
          "proc f*() =\n  ## TODO: Document.\n  discard\n"
      found = checkDocsMissing("a.nim", todo)
    check found.len == 1 and found[0].line == 2  # `TODO: Document.` itself passes
    check found[0].message ==
        "Doc awaiting text reads `TODO: Document.` alone; got `## TODO: Make distinct.`."
    check todo.fixedMissing == "type\n  # TODO: Make distinct.\n" &
        "  Grade* = int  ## TODO: Document.\nproc f*() =\n  ## TODO: Document.\n  discard\n"
    check todo.fixedMissing.isSettledMissing


  test "one-line borrow or forward under one group comment, and quoted code, take no doc":
    let excepted = "type Grade* = distinct int  ## Grade.\n" &
        "# Borrow arithmetic of grade.\nfunc inc*(g: Grade): Grade {.borrow.}\n" &
        "func dec*(g: Grade): Grade {.borrow.}\n" &
        "macro m*(): untyped =\n  ## Emit.\n  result = quote do:\n    proc p() = discard\n"
    check checkDocsMissing("a.nim", excepted).len == 0
    let alone = "type Grade* = distinct int  ## Grade.\nfunc inc*(g: Grade): Grade {.borrow.}\n"
    check checkDocsMissing("a.nim", alone).mapIt(it.line) == @[2]  # no group comment above it
    check alone.fixedMissing == "type Grade* = distinct int  ## Grade.\n" &
        "func inc*(g: Grade): Grade {.borrow.}\n  ## TODO: Document.\n"


  test "line too wide, or carrying comment, takes doc on next line; value of lines, after it":
    # Doc after value stands outside its brackets, where every such doc of repository stands.
    let
      wide = "const NAME* = \"" & "x".repeat(80) & "\"\n"
      commented = "const N* = 3  # Three.\n"
      opened = "const LIST* = [\n  1, 2,\n]\n"
      signature = "proc g*(\n  a: int, b: int\n): int =\n  a + b\n"
    check wide.fixedMissing == wide[0 ..< ^1] & "\n  ## TODO: Document.\n"
    check commented.fixedMissing == "const N* = 3  # Three.\n  ## TODO: Document.\n"
    check opened.fixedMissing == "const LIST* = [\n  1, 2,\n]\n  ## TODO: Document.\n"
    check signature.fixedMissing ==
        "proc g*(\n  a: int, b: int\n): int =\n  ## TODO: Document.\n  a + b\n"
    for source in [wide, commented, opened, signature]:
      check source.fixedMissing.isSettledMissing


  test "doc of value of several lines stands after it, never inside its brackets":
    # Cases as found over repository at `03b86db3`: fix wrote doc after `,` inside call or
    #   after `:` inside constructor, and Nim then failed to parse 11 of 147 files it changed.
    let
      commented = "const M* = max(  # Pair.\n  1,\n  2,\n)\n"
      wide = "const PAIR* = max(" & "x".repeat(70) & ", 2,\n  3)\n"
      continued = "const S* =\n  \"text\"\n"
      text = "const T* = \"\"\"\nline (\n\"\"\"\n"  # doc joining line would stand in string
    check commented.fixedMissing == commented & "  ## TODO: Document.\n"
    check wide.fixedMissing == wide & "  ## TODO: Document.\n"
    check continued.fixedMissing == continued & "  ## TODO: Document.\n"
    check text.fixedMissing == text & "  ## TODO: Document.\n"
    for source in [commented, wide, continued, text]:
      check source.fixedMissing.isSettledMissing


  test "doc of value opening body stands first in body, so body keeps its last expression":
    # Case as found over repository at `03b86db3`: doc after `block:` value stood last in block,
    #   and Nim then read block's value as expression left unused.
    let
      opened = "const T* = block:\n  var t = 1\n  t\n"
      lambda = "const F* = proc (x: int): int =\n  x + 1\n"
      later = "const G* = max(1,\n  2).pred do:\n    discard\n"  # body opens below first line
    check opened.fixedMissing == "const T* = block:\n  ## TODO: Document.\n  var t = 1\n  t\n"
    check lambda.fixedMissing == "const F* = proc (x: int): int =\n  ## TODO: Document.\n  x + 1\n"
    check later.fixedMissing == "## TODO: Document.\n" & later
    for source in [opened, lambda, later]:
      check source.fixedMissing.isSettledMissing
    check checkDocsMissing("a.nim", "const S* =\n  \"text\"\n  ## Text.\n").len == 0


  test "doc of routine takes indent of its body, below signature of any shape":
    # Cases as found over repository at `03b86db3`: body four spaces in, and return type on
    #   line below `):` or inside brackets left open; fix wrote doc inside signature.
    let
      deep = "proc p*() =\n    discard\n"
      below = "func f*(a: int):\n    int =\n  a\n"
      opened = "func f*(a: int): tuple[b: int,\n    c: int] =\n  (a, a)\n"
      pragma = "proc p*() =\n  {.cast(noSideEffect).}:\n    discard\n"  # body's, past `=`
    check deep.fixedMissing == "proc p*() =\n    ## TODO: Document.\n    discard\n"
    check below.fixedMissing == "func f*(a: int):\n    int =\n  ## TODO: Document.\n  a\n"
    check opened.fixedMissing ==
        "func f*(a: int): tuple[b: int,\n    c: int] =\n  ## TODO: Document.\n  (a, a)\n"
    check pragma.fixedMissing ==
        "proc p*() =\n  ## TODO: Document.\n  {.cast(noSideEffect).}:\n    discard\n"
    for source in [deep, below, opened, pragma]:
      check source.fixedMissing.isSettledMissing


  test "name inside brackets of declaration's value is part of it, and takes no doc":
    # Cases as found over repository at `03b86db3`: parameters of proc type, and fields of
    #   tuple inside field's type, read as fields; fix wrote doc inside brackets.
    let inside = "type\n  F* = proc (\n    a: int, b: int\n  ): int\n    ## Add.\n" &
        "  O* = object  ## Hold pair.\n    pair*: Option[tuple[\n      a: int, b: int\n    ]]\n" &
        "      ## Pair.\n"
    check checkDocsMissing("a.nim", inside).len == 0


  test "TODO of doc above declaration moves above that doc, so doc stays its declaration's":
    let above = "type T* = int  ## Hold.\n## TODO: Make distinct.\nconst X* = 1\n"
    check above.fixedMissing ==
        "type T* = int  ## Hold.\n# TODO: Make distinct.\n## TODO: Document.\nconst X* = 1\n"
    check above.fixedMissing.isSettledMissing
