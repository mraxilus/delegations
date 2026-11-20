## Hold that each stage of routine or test opens with comment naming its purpose (Article VI.4),
##   in narrow form Architect ruled on rule 4 of #443: paragraph that blank line opens takes
##   stage comment where its routine opens another stage with one, and where it holds three
##   lines of code or more. Fix writes placeholder above paragraph, at its indent, and nothing
##   second time.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/knoller/[reports, stages]


const
  PLACEHOLDER = "# TODO: Describe stage's purpose."  ## Text VI.4 gives stage comment waiting.
  OPERATOR =
    "macro defineOperator(\n  symbols, docs: static[string];\n  cayley: static[Cayley1D];\n" &
    "): untyped =\n" &
    "  ## Construct multivector mapping variant using provided Cayley table.\n\n" &
    "  # Determine mappings needed for each basis element's coefficient assignment.\n" &
    "  var expressions: array[Basis, seq[NimNode]]\n  for b in Basis:\n" &
    "    for destination in cayley[b]:\n" &
    "        let source = nnkBracketExpr.newTree(ident\"m\", ident($b))\n" &
    "        expressions[destination.basis].add(\n" &
    "          if destination.is_negated: prefix(source, \"-\") else: source\n        )\n\n" &
    "  # Construct function body as collated assignments for each basis element.\n" &
    "  var assignments = newNimNode(nnkStmtList)\n  for b in Basis:\n    let terms =\n" &
    "      if expressions[b].len != 0: expressions[b]\n" &
    "      else: @[newFloatLitNode(0.0)]\n\n" &
    "    var expression = terms[0]\n    for term in terms[1 .. ^1]:\n" &
    "       expression = infix(expression, \"+\", term)\n\n" &
    "    assignments.add newAssignment(\n" &
    "      nnkBracketExpr.newTree(ident\"result\", ident($b)),\n      expression,\n    )\n\n" &
    "  # Construct function definition from generated assignments.\n" &
    "  emitFunc(\n    name = symbols,\n    docs = docs,\n    body = assignments,\n  )\n"
    ## Lines 19 to 62 of `pga/operators.nim` of PGA library at `3d9696e`, call of `emitFunc`
    ##   cut to three arguments: paragraphs of lines 41 and 45 hold no stage comment.
  FILTER =
    "func filterBases(\n  cayley: var Cayley2D,\n  operands_m = default(seq[Basis]),\n" &
    "  as_exclusions = false,\n) {.compileTime.} =\n" &
    "  ## Filter out specific operands/products from 2D cayley table by bases.\n" &
    "  for m in Basis:\n\n    # Filter by m operands.\n" &
    "    if (operands_m.len != 0 and m notin operands_m) or " &
    "(as_exclusions and m in operands_m):\n" &
    "      for n in Basis:\n        cayley[m][n] = @[]\n\n" &
    "    for n in Basis:\n      if cayley[m][n].len == 0: continue\n\n" &
    "      # Filter by n operands.\n      cayley[m][n] = @[]\n"
    ## Lines 721 to 739 of `pga/cayleys.nim` at `3d9696e`, parameters and last stage cut:
    ##   paragraph of line 734 holds two lines of code alone.


func fixed(source: string): string =
  ## Write placeholder of each stage check reports, as `koch fix` does.
  fixStages("a.nim", source).source


func isSettled(source: string): bool =
  ## Decide whether source reports no stage and fixes to itself again.
  checkStages("a.nim", source).len == 0 and source.fixed == source



suite "Stages":
  test "paragraph blank line opens takes stage comment where its routine comments another":
    check checkStages("a.nim", OPERATOR).mapIt((it.line, it.message)) == @[
      (23, "Paragraph opened by blank line takes stage comment; got `var expression = terms[0]`."),
      (27, "Paragraph opened by blank line takes stage comment; got " &
        "`assignments.add newAssignment(`."),
    ]  # lines 41 and 45 of `pga/operators.nim`
    let lines = OPERATOR.fixed.split('\n')
    check lines[22] == "    " & PLACEHOLDER  # above paragraph, at its indent (VI.4)
    check lines[27] == "    " & PLACEHOLDER
    check OPERATOR.fixed.split('\n').filterIt(it notin ["    " & PLACEHOLDER]) ==
      OPERATOR.split('\n')  # fix writes placeholder alone
    check OPERATOR.fixed.isSettled  # second run writes nothing
    check fixStages("a.nim", OPERATOR).fixed.mapIt((it.line, it.rule)) ==
      @[(23, Rule.CommentStage), (27, Rule.CommentStage)]


  test "paragraph of fewer than three lines of code passes, comment lines not counted":
    check FILTER.isSettled  # line 734 of `pga/cayleys.nim`: two lines of code
    let
      head = "proc p() =\n  ## Do.\n  # Read.\n  let a = 1\n\n"
      counted = head & "  let b = a\n  # Why.\n  let c = b\n"  # two lines of code, one comment
      three = head & "  let b = a\n  let c = b\n  echo c\n"
    check counted.isSettled
    check checkStages("a.nim", three).mapIt(it.line) == @[6]
    check three.fixed == head & "  " & PLACEHOLDER & "\n  let b = a\n  let c = b\n  echo c\n"


  test "routine that comments no stage passes, as narrow form asks":
    let bare = "proc p() =\n  ## Do.\n  let a = 1\n\n  let b = a\n  let c = b\n  echo c\n"
    check bare.isSettled
    check (bare & "\n  # Close.\n  echo a\n").fixed ==
      "proc p() =\n  ## Do.\n  let a = 1\n\n  " & PLACEHOLDER &
      "\n  let b = a\n  let c = b\n  echo c\n\n  # Close.\n  echo a\n"
        # comment of later stage counts as well as earlier one


  test "stage comment right after doc counts, and first stage needs none":
    let source = "proc p() =\n  ## Do.\n  # Read.\n  let a = 1\n\n  let b = a\n" &
      "  let c = b\n  echo c\n"
    check checkStages("a.nim", source).mapIt(it.line) == @[6]
    check "proc p() =\n  let a = 1\n  let b = a\n  let c = b\n\n  # Echo.\n  echo c\n".isSettled


  test "paragraph at any depth counts, and trailing comment on its first line is none":
    let source = "proc p() =\n  ## Do.\n  # Walk.\n  for i in 0..2:\n    let a = i\n\n" &
      "    let b = a  # Why.\n    let c = b\n    echo c\n"
    check checkStages("a.nim", source).mapIt(it.message) == @[
      "Paragraph opened by blank line takes stage comment; got `let b = a`.",
    ]
    check source.fixed.split('\n')[6] == "    " & PLACEHOLDER


  test "body of test reads as routine, and each routine kind reads alike":
    let test = "suite \"S\":\n  test \"t\":\n    # Make.\n    let a = 1\n\n" &
      "    let b = a\n    let c = b\n    check c == 1\n"
    check checkStages("a.nim", test).mapIt(it.line) == @[6]
    for keyword in ["func", "iterator", "template", "macro", "method", "converter"]:
      let source = keyword & " p() =\n  # Read.\n  let a = 1\n\n" &
        "  let b = a\n  let c = b\n  echo c\n"
      check checkStages("a.nim", source).mapIt(it.line) == @[5]


  test "nested helper is no stage of its owner, and its body reads as its own":
    let source = "proc owner() =\n  ## Own.\n\n  proc helper() =\n    ## Help.\n" &
      "    # Read.\n    let a = 1\n\n    let b = a\n    let c = b\n    echo c\n\n" &
      "  let d = 1\n  let e = d\n  echo e\n"
    check checkStages("a.nim", source).mapIt(it.line) == @[9]
      # helper comments its first stage; owner comments none, so its stage passes


  test "line inside string, comment or `quote do:` opens no paragraph":
    for kept in [
      "proc p() =\n  # Read.\n  let a = \"\"\"\n\nx\ny\nz\n\"\"\"\n  echo a\n",
      "proc p() =\n  # Read.\n  #[ Note\n\n  a\n  b\n  c ]#\n  echo 1\n",
      "macro m(): untyped =\n  # Build.\n  result = quote do:\n    let a = 1\n\n" &
        "    let b = a\n    let c = b\n    echo c\n",
    ]:
      check kept.isSettled


  test "module code and suite body outside test take no stage comment":
    for kept in [
      "# Read.\nlet a = 1\n\nlet b = a\nlet c = b\necho c\n",
      "suite \"S\":\n  # Make.\n  let a = 1\n\n  let b = a\n  let c = b\n  echo c\n",
    ]:
      check kept.isSettled
