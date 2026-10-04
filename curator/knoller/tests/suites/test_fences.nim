## Replicate fence of `fences.nim` header: fenced lines read, masked while fixers run, and
##   written back.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/knoller/[fences, rules]



suite "Fences":
  test "fence runs from marker to marker, markers included; open fence runs to end":
    let source = "a\n#!fix off\nb\n#!fix on\nc\n#!fix off\nd\n"
    check source.fenceOf.lines == @[1, 2, 3, 5, 6]  # two fences, second left open
    check source.fenceOf.fault == -1  # every fence readable
    check "a\nb\n".fenceOf.lines.len == 0  # no marker, no fence


  test "each fence warns once, at its first line, with lines it keeps; open one runs to end":
    let
      source = "a\n#!fix off\nb\n#!fix on\nc\n#!fix off\nd\n"
      held = heldOf("a.nim", source.fenceOf)
    check held.mapIt(it.line) == @[2, 6]  # one warning for each fence, at its marker
    check held[0].message.endsWith("got lines `2` to `4`.")  # markers included
    check held[1].message.endsWith("got lines `6` to `7`.")  # open fence runs to last line
    check held.allIt(it.rule == Rule.FenceHeld)
    check heldOf("a.nim", "a\nb\n".fenceOf).len == 0  # no fence, no warning


  test "marker inside string fences nothing, and fence crossing bracket is fault":
    check ("let s = \"\"\"\n" & FENCE_OFF & "\n\"\"\"\n").fenceOf.lines.len == 0  # in string
    let crossing = "let m = f(\n  " & FENCE_OFF & "\n  1,\n)\n" & FENCE_ON & "\n"
    check crossing.fenceOf.fault == 0  # bracket opens outside fence, closes inside


  test "masked line reads as comment at its indent, and restored writes it back":
    let
      source = "let m = f(\n  #!fix off\n  1,  0,\n\n  #!fix on\n)\n"
      fence = source.fenceOf
      view = source.masked(fence)
    check view.splitLines[2].strip == view.splitLines[1].strip  # each fenced line one comment
    check view.splitLines[3] == view.splitLines[1].strip  # blank line reads at no indent
    check view.splitLines[2].startsWith("  #")  # indent kept
    check view.restored(source, fence) == source  # round trip
    check view.fenceShape.len == 4  # each fenced line, blank one among them
