## Hold that each comment is hanging outline (Article VI.2), and doc holds one summary line
##   (VI.1): nuance stands two spaces past where text of its parent starts, its leading tag such
##   as `TODO:` included, as Architect ruled on #1020, so summary may wrap so too.
##   Fix moves each line at wrong step with lines below it, and nothing second time.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/knoller/[outlines, reports, tokens]


const  # TODO: Document.
  PRIMITIVES =
    "## Define fundamental geometric types of PGA.\n\n" &
    "# TODO: Represent multivector primitives using more compact data types.\n" &
    "#   E.g. Point, Line, Plane, Volume, Motor, Flector.\n" &
    "#   At cost of additional meta-programming, this affords:\n" &
    "#     - More optimization with SoA (how much more over SIMD of multivectors?),\n" &
    "#     - Simpler reasoning about objects resulting from operations.\n" &
    "#     - IDE support for recognizing resulting objects from operations.\n" &
    "#   Perhaps base library should only contain full multivector operations for simplicity?\n" &
    "#     I.e. to serve more as learning reference, optimising where necessary.\n" &
    "# TODO: Implement SIMD cayley table based macros for operating on arrays of Multivectors.\n"
    ## Lines 1 to 11 of `pga/multivectors.nim` of PGA library at `3d9696e`.
  UNARY =
    "## TODO: Document.\n\n# TODO: Implement in-place options for unary operators.\n" &
    "#         Maybe best to use template for defining both at once?\n"
    ## Lines 1 to 4 of `pga/operators.nim` at `3d9696e`, nuance two spaces past `Implement`.
  NESTED = "# TODO: Fit.\n#       Child.\n#         Grandchild.\n"
    ## Child at column of `Fit.`, six spaces past where text of parent starts, and grandchild
    ##   two spaces past child.
  GEONORM =
    "func `|`*(m: Multivector): MultivectorScalars {.inline.} =\n" &
    "  ## Get geometric norm of multivector as distance from origin.\n" &
    "  ##   I.e. for all objects in RGA, ‖𝐦‖ = ‖𝐦‖∙ + ‖𝐦‖∘,\n" &
    "  ##     or for equivalent flat objects in CGA, ‖𝐦‖ = ‖𝐦‖■ + ‖𝐦‖□.\n" &
    "  when IS_RIGID:\n    result[Basis.scalar] = (|∙m)[Basis.scalar]\n  else:\n" &
    "    # TODO: Does conformal even have base geometric norm?\n" &
    "    #   From reading it should be, for objects which are:\n" &
    "    #     Flat - Geonorm is ratio between flat bulk and weight norms.\n" &
    "    #       I.e. distance form flat object to origin.\n" &
    "    #     Round - Geonorm is ration between round bulk and weight norms.\n" &
    "    #       I.e. distance from object to carrier geometry.\n" &
    "    result[Basis.scalar] = (|■m)[Basis.scalar]\n"
    ## Lines 345 to 360 of `pga/operators.nim` at `3d9696e`, rigid branch cut to one line.
  GRADE =
    "func gradeAnti*(b: Basis): GradeAnti {.inline, noinit.} =\n" &
    "  ## Count number of vector basis elements absent in factorization of basis.\n" &
    "  ##  I.e. number of empty dimensions unoccupied by basis.\n" &
    "  GradeAnti(Grade.high - b.grade)\n"
    ## Lines 352 to 355 of `pga/algebra.nim` at `3d9696e`: nuance one space short.
  HEADER =
    "## Projective Geometric Algebra library and reference supporting rigid and conformal " &
    "metrics.\n##\n## Up to 9D PGAs supported, however recommendation is <= 6D.\n##\n" &
    "## Order of compile-time type bootstrapping:\n" &
    "##   [Algebra, BasisDigits, BasisFlags] -> Basis\n##   Basis -> BasisSigned\n" &
    "##         -> Multivector\n##   BasisSigned -> [Cayley1D, Cayley2D]\n##\n" &
    "## All operators are derived from (anti)metric and exterior product definitions.\n" &
    "## Cayley tables are defined for each major operator.\n##\n" &
    "## Extraction operators († = conformal only):\n" &
    "##   |-----|-------------------|-------------|\n" &
    "##   |Oper.| Name              | Lengyel     |\n"
    ## Lines 1 to 12 and 35 to 37 of `pga.nim` at `3d9696e`: paragraphs, diagram and table.
  NORM =
    "when IS_CONFORMAL:\n  defineOperator(\n    symbols = \"|∘²\",\n" &
    "    docs = \"\"\"Get round weight squared norm of multivector,\n" &
    "    as squared size of round weight components.\"\"\",\n" &
    "    cayley = CAYLEYS_NORM_SQUARED.weight.round,\n    as_unary = true,\n  )\n"
    ## Lines 220 to 226 of `pga/operators.nim` at `3d9696e`, under `when` that holds them:
    ##   summary runs on to line four spaces deeper in its string, so no wrap.


func fixed(source: string): string =
  ## Move each nuance check reports, as `koch fix` does.
  fixOutlines("a.nim", source).source


func isSettled(source: string): bool =
  ## Decide whether source reports no outline and fixes to itself again.
  checkOutlines("a.nim", source).len == 0 and source.fixed == source


func spellingsCode(source: string): seq[string] =
  ## Read spelling of each token of source but comments, in order.
  for t in source.tokens:
    if t.kind != KindToken.Comment: result.add t.spelling(source)



suite "Outlines":
  test "nuance stands two spaces past text of its parent, its tag included, and moves with it":
    check PRIMITIVES.isSettled  # lines 1 to 11 of `pga/multivectors.nim`, as library writes them
    check GEONORM.isSettled  # lines 345 to 360 of `pga/operators.nim`
    check checkOutlines("a.nim", UNARY).mapIt((it.line, it.rule, it.brief)) == @[
      (4, Rule.OutlineDoc, "nuance indents two spaces past where its parent's text starts; " &
        "got `9` spaces after `#`, parent's text at `1`"),
    ]  # line 4 of `pga/operators.nim`, two spaces past `Implement`
    check UNARY.fixed == UNARY.replace("#         Maybe", "#   Maybe")
    check UNARY.fixed.isSettled  # second run writes nothing
    check checkOutlines("a.nim", NESTED).mapIt((it.line, it.brief)) == @[
      (2, "nuance indents two spaces past where its parent's text starts; got `7` spaces " &
        "after `#`, parent's text at `1`"),
    ]  # grandchild stands two spaces past child as written
    check NESTED.fixed == "# TODO: Fit.\n#   Child.\n#     Grandchild.\n"  # grandchild moves too
    check fixOutlines("a.nim", NESTED).fixed.mapIt(it.line) == @[2]


  test "tag is text of its line, so nuance and second summary stand two spaces past tag":
    for kept in [
      "# Cost: one fetch,\n#   paid once.\n",
      "# Rejected: nimpretty,\n#   which sets one space.\n",
      "## Note: returns range.\n##   Since int checks.\n",
      "# TODO: Note: split,\n#   since it grows.\n",  # each leading tag
      "# E.g. point, line,\n#   plane.\n",  # no colon
      "# Order of bootstrapping: types,\n#   then tables.\n",  # word before colon
      "# TODO:mixed\n#   wrap.\n",
    ]:
      check kept.isSettled
    check "# Cost: one fetch,\n#         paid once.\n".fixed ==
      "# Cost: one fetch,\n#   paid once.\n"  # two spaces past where `Cost:` starts
    check "## Cost: reads twice.\n## Second claim.\n".fixed ==
      "## Cost: reads twice.\n##   Second claim.\n"  # second summary, past where `Cost:` starts


  test "nuance off its step moves there, in doc and comment, at any column":
    check checkOutlines("a.nim", GRADE).mapIt(it.brief) == @[
      "nuance indents two spaces past where its parent's text starts; got `2` spaces after " &
        "`##`, parent's text at `1`",
    ]  # line 354 of `pga/algebra.nim`
    check GRADE.fixed == GRADE.replace("##  I.e.", "##   I.e.")
    let trailing = "type O = object\n  count*: int  ## Count of items,\n" &
      "                ##       read once.\n"
    check trailing.fixed == "type O = object\n  count*: int  ## Count of items,\n" &
      "                ##   read once.\n"  # column of marker stays, as lexer joins doc
    check trailing.fixed.isSettled


  test "doc holds one summary line: second moves under it, and summary run on stays for hand":
    let second = "proc f() =\n  ## Do one thing.\n  ## Do other thing.\n  ##   In parts.\n" &
      "  discard\n"
    check checkOutlines("a.nim", second).mapIt((it.line, it.rule, it.brief)) == @[
      (3, Rule.SummaryDoc, "doc holds one summary line, so next claim indents two spaces; " &
        "got `Do other thing.`"),
    ]
    check second.fixed == "proc f() =\n  ## Do one thing.\n  ##   Do other thing.\n" &
      "  ##     In parts.\n  discard\n"  # lines below it move with it
    let runs = "proc f() =\n  ## Do one thing and\n  ## other thing.\n  discard\n"
    check checkOutlines("a.nim", runs).mapIt((it.line, it.rule, it.brief)) == @[
      (2, Rule.SummaryDoc, "summary line of doc ends its sentence, or wraps two spaces " &
        "deeper; got `Do one thing and`"),
    ]
    check runs.fixed == runs  # hand alone knows where summary ends
    for kept in [
      "proc f() =\n  ## Do one thing and\n  ##   other thing.\n  discard\n",  # wrap ruling lets
      "## Do.\n##\n## Paragraph one.\n## Paragraph two.\n",  # paragraphs after blank line
      "# Do one thing.\n# Do other thing.\n",  # comment holds no summary
    ]:
      check kept.isSettled


  test "header of module takes paragraphs, and table, diagram and code hold no step":
    check HEADER.isSettled  # lines 1 to 12 and 35 to 37 of `pga.nim`
    check "## Do.\n##   ```nim\n##   let x =\n##       f(1)\n##   ```\n".isSettled
    check "## Do.\n##   a -> b\n##        -> c\n".isSettled
    check "## Do.\n##   [boundary, camera, scene]\n##     -> orrery\n".isSettled  # group, arrow


  test "arrow inside backticks or between words of prose marks no diagram":
    let quoted = "## Diagram (`->`) holds no step,\n##     past summary.\n"
    check checkOutlines("a.nim", quoted).mapIt(it.line) == @[2]  # summary is line 1
    check quoted.fixed == "## Diagram (`->`) holds no step,\n##   past summary.\n"
    let prose = "## Neck round 0.39 -> 0.37,\n##     so torso takes it.\n"
    check checkOutlines("a.nim", prose).mapIt(it.line) == @[2]  # arrow of measure, not of diagram
    check prose.fixed == "## Neck round 0.39 -> 0.37,\n##   so torso takes it.\n"


  test "comment whose first line stands at even step is commented code, so no outline":
    for kept in ["#func `<=`(a, b: Order): bool {.borrow.}\n#   x\n", "#  let x = 1\n#     y\n"]:
      check kept.isSettled


  test "summary of generated doc ends in period, or wraps two spaces deeper to one that does":
    check checkOutlines("a.nim", NORM).mapIt((it.line, it.rule, it.brief)) == @[
      (4, Rule.SummaryDoc, "summary line of generated doc ends in period; got `Get round " &
        "weight squared norm of multivector,`"),
    ]  # line 222 of `pga/operators.nim`
    check NORM.fixed == NORM  # string holds doc, so hand writes it
    for kept in [
      "emitFunc(name = \"f\", docs = \"Do.\")\n",
      "defineOperator(\n  docs = \"\"\"Do one thing and\n  other thing.\"\"\",\n)\n",
      "emitFunc(name = \"f\", docs = &\"Do {b} once.\")\n",
      "let docs = \"Not passed\"\n",
    ]:
      check kept.isSettled


  test "move that would widen line past `LINE_MAX` stays for hand, report and all":
    let wide = "# Fit.\n#  " & "w".repeat(97) & "\n"  # move to step 3 gives 101 bytes
    check checkOutlines("a.nim", wide).mapIt(it.line) == @[2]
    check wide.fixed == wide


  test "fix writes comments alone, so each token of code stays as it was":
    for source in [PRIMITIVES, GEONORM, GRADE]:
      check source.fixed.spellingsCode == source.spellingsCode
