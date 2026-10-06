## Replicate STYLE.md §5 on type conversion: `x.T` that semantic pass settles becomes `T(x)`.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, tables, unittest]
import ../../src/[conversions, findings, rewrites, symbols]



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
    let (edits, reports) = conversionEdits("a.nim", source, answer, [])
    check source.applied(edits) ==
      "let\n  y = float(x)\n  z = int(a + b)\n  w = rigid3.Point\n  v = -int(float(x))\n" &
        "  t = T((a, b))\n"  # group gives call its parentheses, tuple keeps its own
    check reports.mapIt(it.line) == @[2, 3, 5, 5, 6]
    check checkConversions("a.nim", source, answer).len == 5
    check checkConversions("a.nim", source, answer)[0].message.endsWith("got `x.float`.")
    check conversionEdits("a.nim", source, answer, [2])[1].len == 4  # fenced line stays
    check conversionEdits("a.nim", source, Answer(reason: "error"), [])[0].len == 0  # unresolved


  test "type conversion followed by call, receiver module or type, and template stay":
    for kept in [
      "let a = x.T(y)\n",  # two arguments
      "let b = Kind.Nim\n",  # capitalised receiver: type or enum
      "import std/os\nlet c = os.DirSep\n",  # imported module
      "export layout.Entry\n",  # export statement
    ]:
      check queryConversion("a.nim", kept).sites.len == 0
