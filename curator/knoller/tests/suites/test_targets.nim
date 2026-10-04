## Replicate STYLE.md §5 on `to<Target>` calls: plain subject goes first, and compound subject
##   keeps prefix call; fix changes nothing else, and nothing second time.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/knoller/targets


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
