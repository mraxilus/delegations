## Replicate V.8 on landmark index: each alias template or routine of one `typedesc` declares names
##   index for each type, and conversion writing that index bare becomes alias; where several
##   aliases name it, fix writes `low` or `high` (#443).
##   Case held: `Grade(1)` and `GradeAnti(1)` stood bare at lines 142, 148, 169, 241 and 261 of
##     `tests/suites.nim` of PGA library at `3d9696e` (rule 9 of #443), beside aliases of
##     `pga/algebra.nim`, which `ALIASES` of `sources.nim` quotes; `test_regressions.nim` holds
##     each through command line.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/knoller/[edits, landmarks, rules]
import ./sources


func fixed(source: string; landmarks: openArray[Landmark]; fenced: openArray[int] = []): string =
  ## Write alias of each landmark index of source, as `koch fix` would.
  source.applied(editsLandmark("a.nim", source, landmarks, fenced)[0])



suite "Article V.8":
  test "each alias names index of each type, through `when` on type and through other alias":
    check landmarksDeclared([ALIASES]).mapIt((it.name, it.index, it.aliases)) == @[
      ("Grade", "0", @["scalar", "low"]),  # `I.low` reads alias `low` through
      ("GradeAnti", "DIMENSIONS", @["scalar", "high"]),
      ("Grade", "DIMENSIONS", @["scalarAnti", "high"]),
      ("GradeAnti", "0", @["scalarAnti", "low"]),
      ("Grade", "1", @["vector"]),
      ("GradeAnti", "DIMENSIONS-1", @["vector"]),  # spaces out
      ("Grade", "DIMENSIONS-1", @["vectorAnti"]),
      ("GradeAnti", "1", @["vectorAnti"]),
      ("Basis", "DIMENSIONS", @["vectorLast"]),  # `infinity` under `when` names none
    ]  # `origin` branches on configuration, `Basis.low` is builtin, `horizon` returns other type


  test "landmark index written bare becomes alias, `low` or `high` where several name it":
    let landmarks = landmarksDeclared([ALIASES])
    for (given, written) in [
      ("if b.grade == Grade(1):\n", "if b.grade == Grade.vector:\n"),
      ("if b.grade == Grade(1) and c.grade == Grade(1):\n",
       "if b.grade == Grade.vector and c.grade == Grade.vector:\n"),
      ("if b.gradeAnti == GradeAnti(1) and c.gradeAnti == GradeAnti(1):\n",
       "if b.gradeAnti == GradeAnti.vectorAnti and c.gradeAnti == GradeAnti.vectorAnti:\n"),
      ("int(read.get(Grade(0)))\n", "int(read.get(Grade.low))\n"),  # `scalar` beside `low`
      ("let g = GradeAnti(DIMENSIONS)\n", "let g = GradeAnti.high\n"),  # `scalar` beside `high`
      ("let g = Grade(DIMENSIONS-1)\n", "let g = Grade.vectorAnti\n"),  # spaces aside
      ("let b = -Basis( DIMENSIONS ).succ\n", "let b = -Basis.vectorLast.succ\n"),
    ]:
      check given.fixed(landmarks) == written
      check checkLandmarks("a.nim", written, landmarks).len == 0
    let found = checkLandmarks("a.nim", "let a = 1\nif b.grade == Grade(1): discard\n", landmarks)
    check found.mapIt((it.line, it.rule)) == @[(2, Rule.AliasLandmark)]
    check found[0].message ==
      "Landmark index stands as its alias, `Grade.vector`; got `Grade(1)`."
    let (_, reports) = editsLandmark("a.nim", "let a = Grade(1)\n", landmarks, [])
    check reports.mapIt((it.line, it.rule)) == @[(1, Rule.AliasLandmark)]


  test "index of no alias, body of alias, placeholder and method stay; choice stays for hand":
    let landmarks = landmarksDeclared([ALIASES])
    for kept in [
      ALIASES,  # body of alias names its own index
      "let g = @[Grade(rand(DIMENSIONS - 1))]\n",  # index of no alias
      "let e = ELEMENTS[Basis(i-1)]\n",
      "let g = Grade(2)\n",
      "let g = Grade.vector\n",  # alias already
      "let g = x.Grade(1)\n",  # call by dot
      "let s = \"Grade(1)\"  # Grade(1)\n",  # string and comment
    ]:
      check checkLandmarks("a.nim", kept, landmarks).len == 0
      check kept.fixed(landmarks) == kept
    let
      twice = "template a*(t: typedesc[T]): T = T(5)\ntemplate b*(t: typedesc[T]): T = T(5)\n"
      chosen = landmarksDeclared([twice])
      found = checkLandmarks("a.nim", "let c = T(5)\n", chosen)
    check found.mapIt(it.message) ==
      @["Landmark index stands as one of its aliases, `T.a` or `T.b`; got `T(5)`."]
    check "let c = T(5)\n".fixed(chosen) == "let c = T(5)\n"  # choice stays for hand
    check "let g = Grade(1)\n".fixed(landmarks, fenced = [0]) == "let g = Grade(1)\n"  # fence
    let wide = "let g = " & 'x'.repeat(81) & " + Grade(1)\n"  # 100 characters, alias widens
    check wide.fixed(landmarks) == wide
    let held = [Edit(first: 8, after: 13, text: "Kind")]  # other edit writes span
    check editsLandmark("a.nim", "let g = Grade(1)\n", landmarks, [], held)[0].len == 0


  test "alias needs one `typedesc` parameter, its type returned, and one expression at top level":
    for alias in [
      "template a*(t: typedesc[T], n: int): T = T(1)\n",  # second parameter
      "template a*(t: T): T = T(1)\n",  # no `typedesc`
      "template a*(t: typedesc[T]): int = T(1)\n",  # returns other type
      "template a*(t: typedesc[T]): T =\n  let x = 1\n  T(x)\n",  # body of two lines
      "when X:\n  template a*(t: typedesc[T]): T = T(1)\n",  # under `when`
      "template a*(t: typedesc[T]): T = when X: T(1) else: T(2)\n",  # branch on configuration
    ]:
      check landmarksDeclared([alias]).len == 0
    check landmarksDeclared(["proc a*(t: typedesc[T]): T = T(1)\n"]).len == 1  # routine too


  test "aliases that name each other name no index, and walk through them ends":
    # Case of review of record: `DEPTH_MAX` held no case, so walk through cycle could run on;
    #   `p` and `q` name each other, and `r` alone names index.
    const source = "template p*(t: typedesc[Grade]): Grade = t.q\n  ## P.\n\n" &
      "template q*(t: typedesc[Grade]): Grade = t.p\n  ## Q.\n\n" &
      "template r*(t: typedesc[Grade]): Grade = Grade(2)\n  ## R.\n"
    check landmarksDeclared([source]).mapIt((it.name, it.index, it.aliases)) ==
      @[("Grade", "2", @["r"])]


  test "index is constant expression, so body sampling value names no landmark":
    # Case held: `sample` read as alias of `Coefficient`, so `Coefficient(rand(-1.0..1.0))` was
    #   reported as its index; line 95 of `proposals/04-basis-set-forms/laws.nim` of
    #   `pga_benchmark` at `4a06f521`. Domain: index of literal, name and arithmetic, beside
    #   call, field, float, range, string and index expression.
    const sampling =
      "proc sample(t: typedesc[Coefficient]): Coefficient =\n" &
      "  ## Sample scalar uniform in [-1, 1].\n" &
      "  Coefficient(rand(-1.0..1.0))\n"
    check landmarksDeclared([sampling]).len == 0
    check checkLandmarks("a.nim", "m[b] = Coefficient(rand(-1.0..1.0))\n",
      landmarksDeclared([sampling])).len == 0
    for (body, index) in [
      ("T(1)", "1"), ("T(N)", "N"), ("T(N - 1)", "N-1"), ("T(2 * N)", "2*N"),
      ("T(N div 2)", "Ndiv2"), ("T(-1)", "-1"),
    ]:
      check landmarksDeclared(["template a*(t: typedesc[T]): T = " & body & "\n"]).mapIt(
        it.index) == @[index]
    for body in ["T(rand(n))", "T(a.b)", "T(1.0)", "T(0..1)", "T(\"a\")", "T(a[0])"]:
      check landmarksDeclared(["template a*(t: typedesc[T]): T = " & body & "\n"]).len == 0
