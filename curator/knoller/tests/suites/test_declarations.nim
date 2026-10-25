## Hold that declaration carries doc (Article VI.1), and where it states its doc and its type
##   (VI.9, X.12; STYLE.md §5): each breach is reported and fixed; doc of several lines, routine
##   doc and default literal of other type are neither; fix changes nothing else, and nothing
##   second time.
##   Missing doc is held over each kind and shape of declaration, and over what passes. Cases
##     held: value or signature of this repository running past its first line, each named
##     where it stands.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/knoller/[declarations, reports, tokens]


func fixed(source: string): string =
  ## Fix docs, then defaults, of source, as `koch fix` does.
  let docs = fixDocs("a.nim", source).source
  fixDefaults("a.nim", docs).source


func isSettled(source: string): bool =
  ## Decide whether source reports no declaration finding and fixes to itself again.
  (checkDocs("a.nim", source) & checkDefaults("a.nim", source)).len == 0 and
    source.fixed == source


func documented(source: string): string =
  ## Write missing docs of source, as `koch fix` does.
  fixDocsMissing("a.nim", source).source


func isDocumented(source: string): bool =
  ## Decide whether source reports no missing doc, and fix writes nothing to it.
  checkDocsMissing("a.nim", source).len == 0 and source.documented == source


func spellingsCode(source: string): seq[string] =
  ## Read spelling of each token of source but comments, in order.
  for t in source.tokens:
    if t.kind != KindToken.Comment: result.add t.spelling(source)



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



  test "declaration of each kind with no doc takes `TODO: Document.` where doc position puts it":
    let breach = "const N* = 3\ntype\n  Shape {.pure.} = enum\n    Round\n  Box* = object\n" &
      "    width*: int\nproc area*(b: Box): int =\n  b.width\nfunc scale*(\n" &
      "  b: Box, factor: int,\n): Box =\n  b\nconst\n  NAME = \"" & "x".repeat(70) & "\"\n" &
      "  WHY = 1  # Reason.\n"
    let found = checkDocsMissing("a.nim", breach)
    check found.mapIt(it.line) == @[1, 3, 4, 5, 6, 7, 9, 14, 15]
    check found.mapIt(it.message)[0 .. 1] == @[
      "Declaration takes doc comment; got `const N`.",
      "Declaration takes doc comment; got `type Shape`.",
    ]
    check found.mapIt(it.message)[5 .. 6] == @[
      "Declaration takes doc comment; got `proc area`.",
      "Declaration takes doc comment; got `func scale`.",
    ]
    check breach.documented == "const N* = 3  ## TODO: Document.\ntype\n" &
      "  Shape {.pure.} = enum  ## TODO: Document.\n    Round  ## TODO: Document.\n" &
      "  Box* = object  ## TODO: Document.\n    width*: int  ## TODO: Document.\n" &
      "proc area*(b: Box): int =\n  ## TODO: Document.\n  b.width\n" &
      "func scale*(\n  b: Box, factor: int,\n): Box =\n  ## TODO: Document.\n  b\n" &
      "const\n  NAME = \"" & "x".repeat(70) & "\"\n    ## TODO: Document.\n" &
      "  WHY = 1  # Reason.\n    ## TODO: Document.\n"  # joined where it fits, else next line
    check breach.documented.isDocumented  # second run writes nothing
    check fixDocsMissing("a.nim", breach).fixed.mapIt(it.rule).deduplicate == @[Rule.DocMissing]


  test "doc in place, local, parameter, placeholder, generated code and stacked borrow pass":
    for kept in [
      "const N = 3  ## Size.\n",
      "const\n  N = 3\n    ## Size.\n",  # next line, one level in
      "const T = [\n  1,\n]  ## Table.\n",  # last line of value
      "const T = block:\n  ## Table.\n  1\n",  # doc right below first line counts, as cost
      "proc f[T](x: T): T =\n  ## Echo.\n  let y = x\n  y\n",
      "func g() =\n  ##[ Block doc. ]##\n  discard\n",
      "macro m(): untyped =\n  ## Emit.\n  quote do:\n    proc h() = discard\n",
      "# Bounds of order.\nfunc low(a: O): O {.borrow.}\nfunc next(a: O): O = succ(a)\n",
      "## Doc above.\nconst N = 3\n",  # out of place, which doc position reads
      "const N = 3  ## TODO: Document.\n",  # doc waiting for text
    ]:
      check kept.isDocumented


  test "names one line declares share one doc, enum members among them, so line reports once":
    let breach = "type P = object\n  ## Pair.\n  left*, right*: int\nlet (a, b) = (1, 2)\n" &
        "type K = enum\n  ## Kind.\n  A, B, C\n  D,\n  E  ## Last.\n"
    check checkDocsMissing("a.nim", breach).mapIt((it.line, it.message)) == @[
      (3, "Declaration takes doc comment; got `field left`."),
      (4, "Declaration takes doc comment; got `let a`."),
      (7, "Declaration takes doc comment; got `member A`."),  # doc above is its type's own
      (8, "Declaration takes doc comment; got `member D`."),  # `,` opens next member, not value
    ]
    check breach.documented == "type P = object\n  ## Pair.\n" &
        "  left*, right*: int  ## TODO: Document.\nlet (a, b) = (1, 2)  ## TODO: Document.\n" &
        "type K = enum\n  ## Kind.\n  A, B, C  ## TODO: Document.\n  D,  ## TODO: Document.\n" &
        "  E  ## Last.\n"
    check breach.documented.isDocumented  # second run writes nothing


  test "doc holding design note keeps note as comment above, and waits for text":
    # Case held: `Bases*` and `toMultivector*` of `pga/multivectors.nim` of PGA library at
    #   `3d9696e`, whose docs hold notes `TODO: Make distinct.` and `TODO: Define via macro.`.
    let breach = "type\n  Bases* = set[int]  ## TODO: Make distinct.\n" &
      "func f*(): int =\n  ## TODO: Define via macro.\n  1\n"
    check checkDocsMissing("a.nim", breach).mapIt(it.message) == @[
      "Doc holds `TODO: Document.` and nothing else; got `## TODO: Make distinct.`.",
      "Doc holds `TODO: Document.` and nothing else; got `## TODO: Define via macro.`.",
    ]
    check breach.documented == "type\n  # TODO: Make distinct.\n" &
      "  Bases* = set[int]  ## TODO: Document.\n# TODO: Define via macro.\n" &
      "func f*(): int =\n  ## TODO: Document.\n  1\n"  # note keeps design journal (VIII.3)
    check breach.documented.isDocumented
    let outlined = "proc g() =\n  ## TODO: Split.\n  ##   Since it grows.\n  discard\n"
    check checkDocsMissing("a.nim", outlined).len == 1
    check outlined.documented == outlined  # outline may elaborate note or text, so hand moves it


  test "forward declaration takes doc of its routine, and fix leaves move of that doc for hand":
    # Case held: `proc dance` of `app/app.nim` of `dance_ontology`, whose definition holds doc.
    let forward = "proc dance(key: string)\n\nproc dance(key: string) =\n  ## Dance.\n  echo key\n"
    check checkDocsMissing("a.nim", forward).mapIt((it.line, it.message)) == @[
      (1, "Forward declaration takes doc of its routine, which `nim doc` reads there; got " &
        "`proc dance`."),
    ]
    check forward.documented == forward and fixDocsMissing("a.nim", forward).fixed.len == 0
    let planned = "func planned*(m: int): int {.error:\n  \"Planned.\"\n.}\n"
    check planned.documented == planned & "  ## TODO: Document.\n"  # no body and no definition


  test "value or signature running on reads doc where it ends":
    for kept in [
      "const\n  DIRECTORY_CACHE* = \".cache/knoller/nim\"\n" &
        "    ## Default cache, under home and beside Nim's own `~/.cache/nim`.\n",
        # `compilers.nim` of `knoller`: value of string alone
      "const MATRIX_REST {.used.}: Matrix =  # Used in `plan.nim`.\n" &
        "  [[1.0, 0.0, 0.0], [0.0, -1.0, 0.0], [0.0, 0.0, -1.0]]\n" &
        "  ## Upper arm's frame at rest in body's terms.\n",
        # `simulation/rigid.nim` of `dance_ontology`: comment after `=`
      "func placings*(rig: Rig, plan: Plan, wind: float, is_away: bool, turner = Body.Two):\n" &
        "    tuple[chests: array[Body, Stance], arms: array[4, ArmPlacing]] =\n" &
        "  ## Where every body of couple stands at this plan.\n  discard\n",
        # `simulation/plan.nim` of `dance_ontology`: return type below parameters
      "const KEYS_DRIVEN = [\n  stepKey(Scancode.BracketRight, uint32(ord(']'))),\n" &
        "]  ## Script one keyboard step per frame for `--drive-keys`.\n",
        # `src/desktop/main.nim` of `pga_visualiser`: bracket inside character literal
      "const STYLE* = \"\"\"<style>\n\"\"\" &\n  \"\"\"</style>\"\"\"\n  ## Style of page.\n",
        # `design/page.nim` of `dance_ontology`: long strings joined over lines
      "const DOC_EMPTY = \"## TODO: Document.\"  ## Doc waiting for honest text.\n",
        # `declarations.nim` of `knoller`: string holding note is no doc
      "let s = \"\"\"\n#!fix off\n\"\"\"  ## Text.\n",
        # `tests/suites/test_fixes.nim` of `audit`: doc trailing close of long string
      "const\n  FLOOR_FUNCTIONS_REFERENCE =\n    when DIMENSIONS == 4 and IS_RIGID: 73\n" &
      "    elif DIMENSIONS == 5 and IS_CONFORMAL: 84\n    else: 1\n" &
      "    ## Reference functions own nimcache holds at pin.\n",
        # `tests/suites.nim` of `pga_benchmark`: branches of `when` below `=`
      "const\n  BYTES_MEMORY_TOTAL* =\n" &
      "      CAPACITY_ARENA_PROGRAM + 2 * CAPACITY_ARENA_FRAME +\n" &
      "      FRAMES_TIMING_MAX * sizeof(float32)\n" &
      "    ## Sum every fixed-size reservation this binary makes.\n",
        # `src/desktop/main.nim` of `pga_visualiser`: sum running on after `+`
      "const FACINGS* =\n  block:\n    var each = 0\n    each\n" &
      "  ## Name each state two stand in to one another.\n",
        # `simulation/words.nim` of `dance_ontology`: `block:` below `=`
      "const WIDE_TEMPO* = Tempo(\n  ## Hold how long this drawing takes to say move.\n" &
      "  quick: 1)\n",
        # `src/dance_ontology/map.nim` of `dance_ontology`: doc right below first line, as cost
    ]:
      check kept.isDocumented
    check checkDocsMissing("a.nim", "let s = \"\"\"\nx\n\"\"\"  ## Text.\nlet t = 1\n").mapIt(
      it.line,
    ) == @[4]  # doc trailing long string stands above next line as no doc of it


  test "value or body opening long string takes doc where string closes, never inside it":
    # Case held: `DRIVE_NIM` of `tests/suites/test_waits.nim` of `audit`, and `HEAD_BODY` of
    #   `design/rig_page.nim` of `dance_ontology`, each value opening long string on its line.
    let
      value = "const\n  PAGE* = \"\"\"\n<p>\n\"\"\"\n  NEXT = 1  ## Next.\n"
      wide = "const PAGE* = \"\"\"\n<p>\n\"\"\" & \"" & "x".repeat(80) & "\"\n"
      body = "func page*(): string = \"\"\"\n<main>\n\"\"\"\n"
    check value.documented == value.replace("\"\"\"\n  NEXT", "\"\"\"  ## TODO: Document.\n  NEXT")
    check wide.documented == wide & "  ## TODO: Document.\n"  # joined line would not fit
    check body.documented == body & "  ## TODO: Document.\n"  # first line after body string
    for source in [value, wide, body]: check source.documented.isDocumented


  test "value whose first line ends on entry of argument or field takes doc where it closes":
    # Nim 2.2.12 refuses doc after `=` of named argument and after `:` of field or table key
    #   inside open bracket, as `expression expected`; after `(`, `,` or operator it parses.
    let
      field = "const P = Pair(a:\n  1, b: 2)\n"
      argument = "const Q = foo(a =\n  2, b = 3)\n"
      opened = "const R = foo(\n  1, 2)\n"
    check field.documented == "const P = Pair(a:\n  1, b: 2)  ## TODO: Document.\n"
    check argument.documented == "const Q = foo(a =\n  2, b = 3)  ## TODO: Document.\n"
    check opened.documented == "const R = foo(  ## TODO: Document.\n  1, 2)\n"  # first line
    for source in [field, argument, opened]: check source.documented.isDocumented


  test "type running over lines reads doc where it closes, and name inside its brackets none":
    # Cases held: `stamp_shown` of `src/desktop/panel.nim` of `pga_visualiser`, `WalkAsk` of
    #   `simulation/walk.nim` and `Posed` of `tests/test_rigid.nim` of `dance_ontology`, and
    #   `DecodeBrotli` of `src/font_files.nim` of `audit`, whose fix broke parse of each.
    for kept in [
      "type Panel = object  ## Panel.\n  stamp_shown*: Option[tuple[\n" &
        "    revision: int, search: string,\n    revision_selection: Option[int]\n  ]]\n" &
        "    ## What list was last filtered against.\n",
      "type WalkAsk = tuple[rig: Rig, band: Band, apart, most,\n" &
        "                    step: float, is_away: bool]\n  ## One walk, by every argument.\n",
      "type DecodeBrotli = proc (\n  size_encoded: csize_t, encoded: ptr uint8\n" &
        "): cint {.cdecl, gcsafe.}\n  ## Define one-shot decode into sized buffer.\n",
    ]:
      check kept.isDocumented
    # Case held: `leaving` of `tests/suites/test_timings.nim` of `pga_visualiser`, routine
    #   declared inside bracket, whose body takes doc as any routine's does.
    let declared = "check not compiles(block:\n  proc leaving() =\n    return\n  leaving())\n"
    check checkDocsMissing("a.nim", declared).mapIt(it.line) == @[2]
    check declared.documented == "check not compiles(block:\n  proc leaving() =\n" &
        "    ## TODO: Document.\n    return\n  leaving())\n"
    let bare = "type Pair = tuple[a: int,\n  b: int]\n"
    check bare.documented == "type Pair = tuple[a: int,  ## TODO: Document.\n  b: int]\n"


  test "one-line routine reads as stacked only under run of such routines and its comment":
    # Case held: `template at` of `src/comments.nim` of `audit`, nested below bindings of routine
    #   whose doc stands above them.
    let nested = "proc scan() =\n  ## Scan.\n  let n = 1\n  template at(k: int): int = k + n\n" &
      "  discard at(0)\n"
    check checkDocsMissing("a.nim", nested).mapIt(it.line) == @[4]
    check "# Bounds.\nfunc low(a: O): O {.borrow.}\nfunc high(a: O): O {.borrow.}\n".isDocumented
    # Case held: `page` of `tests/suites/test_asks.nim` of `dance_ontology`, nested right below
    #   doc of its routine, which is no group comment.
    let below = "func arranged(): float =\n  ## Where follow stands.\n" &
        "  func page(radians: float): float = 90.0 - radians\n  page(1.0)\n"
    check checkDocsMissing("a.nim", below).mapIt(it.line) == @[3]
    # Case held: stack of `design/rig_view.nim` of `dance_ontology`, whose third routine is no
    #   delegation, so run ends there for each routine below it.
    let broken = "# Entries of recording, read as viewer reads them.\n" &
      "proc entry(i: int): JsObject = ENTRIES_ALL[i]\nproc sweep(): JsObject = entry(PICK)\n" &
      "proc moments(recording: JsObject): int = (if has(recording, \"at\"): count(recording.at) " &
      "else: 0)\nproc moments(): int = moments(sweep())\n" &
      "proc isStill(recording: JsObject): bool = has(recording, \"key\")\n"
    check checkDocsMissing("a.nim", broken).mapIt(it.line) == @[4, 5, 6]
    check broken.documented.isDocumented  # one run writes each doc due


  test "fix writes comments alone, so each token of code stays as it was":
    for breach in [
      "const N* = 3\ntype\n  Box* = object\n    width*: int\n" &
        "proc area*(b: Box): int =\n  b.width\n",
      "type\n  Bases* = set[int]  ## TODO: Make distinct.\n" &
        "func f*(): int =\n  ## TODO: Later.\n  1\n",
      "const\n  PAGE* = \"\"\"\n<p>\n\"\"\"\n  NEXT = 1\n" &
        "func page*(): string = \"\"\"\n<main>\n\"\"\"\n",
      "let x = foo(\n  1,\n)\nlet (a, b) = (1, 2)\nconst S = \"## TODO: x\"\n",
    ]:
      check breach.documented != breach  # each source takes doc
      check breach.documented.spellingsCode == breach.spellingsCode


  test "fix traces each line it writes to none, and each line it keeps to its input line":
    let fix = fixDocsMissing("a.nim", "const N = 3\nproc f() =\n  discard\n")
    check fix.source == "const N = 3  ## TODO: Document.\nproc f() =\n  ## TODO: Document.\n" &
      "  discard\n"
    check fix.origin == @[1, 2, 0, 3, 4]  # joined line keeps its input line
    check fix.fixed.mapIt(it.line) == @[1, 2]
