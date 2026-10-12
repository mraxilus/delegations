## Replicate STYLE.md §5 on calls of `define…` and `emit…`: dotted call becomes prefix call with
##   receiver first, module path and `construct…` call stay, and fix changes nothing else, and
##   nothing second time.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/knoller/[generations, reports, rules]


const
  CALLS_FIXED = [
    ("discard MESHES.emitObject(placed, tint, scale)\n",
      "discard emitObject(MESHES, placed, tint, scale)\n"),
    ("result.add node.emitFunc(name)\n", "result.add emitFunc(node, name)\n"),
    ("let n = data.emitEnum()\n", "let n = emitEnum(data)\n"),
    ("let n = data.emitEnum\n", "let n = emitEnum(data)\n"),
    ("let n = a[i].b.emitEnum(c)\n", "let n = emitEnum(a[i].b, c)\n"),
    ("let n = (a & b).emitEnum(c)\n", "let n = emitEnum(a & b, c)\n"),
    ("let n = -x.emitSigned(c)\n", "let n = -emitSigned(x, c)\n"),
    ("CAYLEY.defineOperator(symbols = \"∧\")\n", "defineOperator(CAYLEY, symbols = \"∧\")\n"),
    ("let n = x.emitA(y).emitB(z)\n", "let n = emitB(emitA(x, y), z)\n"),
    ("let n = x.emitA.len\n", "let n = emitA(x).len\n"),
  ]
    ## Dotted call and prefix call fixer writes: arguments, none, bare name, chain and group as
    ##   receiver, prefix operator before, named argument, call inside receiver, chain after.
  CALLS_KEPT = [
    "import rga_visualiser/tessellate\ndiscard tessellate.emitObject(placed)\n",
    "let anti = base.constructAnti(COMPLEMENT)\n",
    "discard emitObject(MESHES, placed)\n",
    "let e = x.emission(y)\n",
    "let e = x.emitter\n",
    "let d = x.defined\n",
    "## Doc names `MESHES.emitObject`.\n",
    "let s = \"MESHES.emitObject(x)\"\n",
  ]
    ## Source rule reads no dotted call in: module path, `construct…` call, prefix call, verb with
    ##   no capital after it, comment, string.
  CALLS_HAND = [
    "let n = data\n  .emitEnum(c)\n",
    "let n = x.emitEnum[int](c)\n",
    "x.emitEnum c\n",
    "discard x.emitEnum(\n  c,\n)\n",
  ]
    ## Dotted call check reports and fixer leaves for hand: receiver above `.`, generic, command
    ##   call, arguments below `(`.


func fixed(source: string): string =
  ## Fix calls of `define…` and `emit…` in source, as `koch fix` does.
  fixGenerations("a.nim", source).source


func isSettled(source: string): bool =
  ## Decide whether source reports no dotted call and fixes to itself again.
  checkGenerations("a.nim", source).len == 0 and fixGenerations("a.nim", source).fixed.len == 0



suite "Style §5":
  test "dotted call of `define…` or `emit…` becomes prefix call, receiver first":
    for (source, prefixed) in CALLS_FIXED:
      check checkGenerations("a.nim", source).len > 0
      check source.fixed == prefixed


  test "fixed call settles: no finding, and fix writes nothing second time":
    for (_, prefixed) in CALLS_FIXED:
      check prefixed.isSettled  # idempotent


  test "module path, `construct…` call, prefix call and other words stay":
    for kept in CALLS_KEPT:
      check kept.isSettled


  test "receiver above dot, generic, command call and arguments below `(` report, but stay":
    for kept in CALLS_HAND:
      check checkGenerations("a.nim", kept).len == 1
      check kept.fixed == kept


  test "finding names rule, line and call as written, and rewrite its line":
    let found = checkGenerations("a.nim", "let a = 1\ndiscard MESHES.emitObject(placed)\n")
    check found.mapIt((it.line, it.rule)) == @[(2, Rule.CallGeneration)]
    check found[0].message == "Call of `define…` or `emit…` is prefix call, as " &
      "`emitFunc(name, docs)`; got `MESHES.emitObject`."
    check fixGenerations("a.nim", "\ndiscard MESHES.emitObject(placed)\n").fixed.mapIt(
      (it.line, it.rule)
    ) == @[(2, Rule.CallGeneration)]
    check checkGenerations("a.nim", CALLS_HAND[0])[0].message.endsWith("got `.emitEnum`.")
