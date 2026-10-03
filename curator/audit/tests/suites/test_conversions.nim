## Replicate STYLE.md §5 on conversion calls: `to<Target>` takes its plain subject first, and
##   compound subject keeps prefix call; fix changes nothing else, and nothing second time.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import std/tables
import ../../src/[conversions, findings, rewrites, symbols]


func fixed(source: string): string =
  ## Fix `to<Target>` calls of source, as `koch fix` does.
  fixTargets("a.nim", source).source


func isSettled(source: string): bool =
  ## Decide whether source reports no target finding and fixes to itself again.
  checkTargets("a.nim", source).len == 0 and fixTargets("a.nim", source).fixed.len == 0



suite "Style §5":
  test "`to<Target>` of plain argument takes it first: name, call, index or field chain":
    check "let m = toMultivector(eye)\n".fixed == "let m = eye.toMultivector\n"
    check "check toText(scene.labelAt(h)) == s\n".fixed == "check scene.labelAt(h).toText == s\n"
    check "let p = toMultivector(Position(x: 0, y: 1))\n".fixed ==
      "let p = Position(x: 0, y: 1).toMultivector\n"  # constructor is call
    check "let v = -toFloat(a[i].b)\n".fixed == "let v = -a[i].b.toFloat\n"  # `.` binds first
    check "let s = toSeq(s.items)\n".fixed == "let s = s.items.toSeq\n"  # iterator compiles too
    check "let f = toFixed(toFloat(x), 2)\n".fixed == "let f = toFixed(x.toFloat, 2)\n"
    check "let d = toA(toB(x)).c\n".fixed == "let d = x.toB.toA.c\n"  # inner first, then outer
    check "let m = toMultivector(eye)\n".fixed.isSettled
    let found = checkTargets("a.nim", "let a = 1\nlet m = toMultivector(eye)\n")
    check found.mapIt(it.line) == @[2]
    check found[0].message.endsWith("got `toMultivector(eye)`.")


  test "`to<Target>` of compound argument, generic, several arguments or spanning lines stays":
    for kept in [
      "let m = toMultivector(a + b)\n",  # compound: no parentheses hide it
      "let m = toMultivector(-v)\n",  # prefix operator
      "let r = toRadians(25)\n",  # literal
      "let s = toSeq(1..3)\n",  # range
      "let h = toHex[uint8](x)\n",  # generic
      "let o = toOpenArray(a, 0, 3)\n",  # several arguments
      "let m = toMultivector(\n  eye,\n)\n",  # spans lines
      "let m = a.toText(b)\n",  # method call already
      "let f = toFunc(x)(y)\n",  # call after: `x.toFunc(y)` would pass two
      "let f = toSeq(x)[0]\n",  # index after: may read as generic
      "func toGrade(x: int): Grade = Grade(x)\n",  # declaration
      "let s = \"toText(x)\"  # toText(x)\n",  # string and comment
      "let t = topology(x)\n",  # no capital after `to`
    ]:
      check checkTargets("a.nim", kept).len == 0
      check kept.fixed == kept


  test "type conversion `x.T` that semantic pass settles becomes prefix call `T(x)`":
    let
      source = "let\n  y = x.float\n  z = (a + b).int\n  w = rigid3.Point\n  v = -x.float.int\n" &
        "  t = (a, b).T\n"
      query = conversionQuery("a.nim", source)
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
      check conversionQuery("a.nim", kept).sites.len == 0
