## Replicate STYLE.md §5 on type conversion: `x.T` that semantic pass settles becomes `T(x)`.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, tables, unittest]
import ../../src/knoller/[conversions, edits, rules, symbols]



suite "Style §5":
  test "type conversion `x.T` that semantic pass settles becomes prefix call `T(x)`":
    let
      source = "let\n  y = x.float\n  z = (a + b).int\n  w = rigid3.Point\n  v = -x.float.int\n" &
        "  t = (a, b).T\n"
      query = queryConversion("a.nim", source)
    check query.sites == @[(2, 8), (2, 6), (3, 14), (4, 13), (4, 6), (5, 9), (5, 7), (5, 15),
                           (6, 13)]  # names, and receiver's last name where it ends on one
    var answer = Answer(path: "a.nim")
    for site in [(2, 8), (3, 14), (4, 13), (5, 9), (5, 15), (6, 13)]:
      answer.symbols[site] = Symbol(kind: "skType")  # module `rigid3` resolves to none
    for site in [(2, 6), (5, 7)]: answer.symbols[site] = Symbol(kind: "skLet")
    let (edits, reports) = editsConversion("a.nim", source, answer, [])
    check source.applied(edits) ==
      "let\n  y = float(x)\n  z = int(a + b)\n  w = rigid3.Point\n  v = -int(float(x))\n" &
        "  t = T((a, b))\n"  # group gives call its parentheses, tuple keeps its own
    check reports.mapIt(it.line) == @[2, 3, 5, 5, 6]
    check checkConversions("a.nim", source, answer).len == 5
    check checkConversions("a.nim", source, answer).allIt(it.rule == Rule.Conversion)
    check checkConversions("a.nim", source, answer)[0].message.endsWith("got `x.float`.")
    check editsConversion("a.nim", source, answer, [2])[1].len == 4  # fenced line stays
    check editsConversion("a.nim", source, Answer(reason: "error"), [])[0].len == 0  # unresolved


  test "type conversion followed by call, receiver module or type, and template stay":
    for kept in [
      "let a = x.T(y)\n",  # two arguments
      "let b = Kind.Nim\n",  # capitalised receiver: type or enum
      "let b = T.int\n",  # one capital: placeholder (V.12), never global
      "let b = A.Nim.int\n",  # capitalised receiver ending chain
      "import std/os\nlet c = os.DirSep\n",  # imported module
      "export layout.Entry\n",  # export statement
    ]:
      check queryConversion("a.nim", kept).sites.len == 0


  test "dotted conversion of global becomes prefix call, which static pass leaves for now":
    # Case held: `FLOAT_TOLERANCE.float` asked nothing, since its receiver opens on capital; line
    #   88 of `pga/algebra.nim` of PGA library at `3d9696e` (rule 15 of #443). Global is
    #   `SCREAMING_SNAKE_CASE` (V.1), so value, never type or module. Domain: global of each shape,
    #   alone and ending chain, beside receivers that stay.
    let
      source = "const TOLERANCE_ABS* = Coefficient(10.pow(-FLOAT_TOLERANCE.float))\n"
      query = queryConversion("a.nim", source)
    check query.sites == @[(1, 59), (1, 43)]  # type name, then global
    var answer = Answer(path: "a.nim")
    answer.symbols[(1, 59)] = Symbol(kind: "skType")
    answer.symbols[(1, 43)] = Symbol(kind: "skConst")
    let (edits, reports) = editsConversion("a.nim", source, answer, [])
    check source.applied(edits) ==
      "const TOLERANCE_ABS* = Coefficient(10.pow(-float(FLOAT_TOLERANCE)))\n"
    check reports.mapIt((it.line, it.rule)) == @[(1, Rule.Conversion)]
    check checkConversions("a.nim", source, answer).len == 0  # static pass reads it later (#443)
    for (global, column_global, column_type) in [
      ("let a = SAMPLES.float\n", 8, 16),
      ("let a = PI.float32\n", 8, 11),
      ("let a = LIMIT_2.int\n", 8, 16),
      ("let a = -CAYLEYS.Cayley1D\n", 9, 17),
      ("let a = m.SAMPLES.int\n", 10, 18),  # global ends chain
    ]:
      let sites = queryConversion("a.nim", global).sites
      check (1, column_type) in sites and (1, column_global) in sites
