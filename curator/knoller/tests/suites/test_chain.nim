## Replicate chain of `chain.nim` header: every fixer in one order until source settles, checks
##   of what fixers clear, warning naming what breaks inside each fence, and nimble files whose
##   copy lock holds.
##   Fixtures copy those of `curator/audit/tests/suites/test_fixes.nim`, which drives same chain
##     through `koch fix`; fix to one is finished only when other is checked.
##   Parser of compiler is stub (`stubs.nim`), answering what chain asks as commit pin of `ronri`
##     projects does, so needless parentheses go as `koch fix` removes them.
##   Cases of repair that widens its line are lines of tree as they stood before `koch fix` ran:
##     `picking.nim`, `gif.nim` and `tools/build.nim` of `rga_visualiser`, `verdicts.nim` of
##     `dance_ontology` and `test_camera_aim.nim` of `rga_visualiser`.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, strutils, unittest]
import ../../src/knoller/[chain {.all.}, fences, idioms, reports, tokens]
import ./stubs


const
  LAYOUT =
    "## Do.\n\n" & STRICT_FUNCS & "\n\nimport std/os\nimport std/strutils\n\n\n" &
    "#[ Section ]#\n\n" &
    "proc f(a: int; b: string): int {.noSideEffect, inline.} = a+b.len\n" &
    "proc g(\n    a: int\n) = discard\n" &
    "let x = foo(\n  1,\n  2\n)\necho x\n" &
    "let y = @[\n  first_item_named_at_length_so_list_crosses_column,\n" &
    "  second_item_named_at_length_so_list_crosses_column\n]\necho h(q=1)\nexport y, x\n"
    ## Nim source breaking each layout rule `checkFormatting` holds.
  ROWS_FENCED =
    "let m = matrix(\n  #!fix off\n  1,  0,\n\n  0,  1,\n  #!fix on\n)\n" &
    "let n = matrix(1+2)\n"
    ## Nim source whose hand-shaped rows fence keeps, and whose call after fence fix reaches.
  LOCK =
    "{\n  \"items\": {},\n  \"nimbleFile\": {\n    \"filename\": \"alpha.nimble\",\n" &
    "    \"content\": []\n  }\n}\n"
    ## Atlas lock holding copy of nimble file `alpha.nimble`.
  HEAD = STRICT_FUNCS & "\n\nproc p() =\n  ## Do.\n"
    ## Opening of each case: module pragma, and routine with its doc.
  PICKING =
      "  let\n    lateral = tangent_half_view*hypot(clip_x/depth*float(width)/float(height), " &
      "clip_y/depth)\n"
    ## Line of 92 runes that spacing takes to 102.
  GIF =
      "  let compressed = encodeLempelZivWelch(arena, dictionary, indices.toOpenArray(0, " &
      "width*height - 1))\n"
    ## Line of 100 runes that spacing takes to 102.
  VERDICTS =
      "var\n  READINGS_KEPT*: Readings  ## Readings report renders from.\n" &
      "  SWEEPS_WANTED: seq[SweepAsk] ## Sweeps render asked for and `READINGS_KEPT` " &
      "lacks, in order asked.\n  RUNGS_WANTED: seq[RungAsk]\n"
    ## Binding whose doc gap of one space takes line of 100 runes to 101.
  CAPTION =
      "  for i, line in lines:\n    if is_caption:\n" &
      "      if not line.namesKey(\"captionWindow\"):\n" &
      "        found.add PATH_DESKTOP_NIM & \":\" & $(i + 1) & \": caption must name " &
      "`captionWindow`; got \" &\n          line.strip\n"
    ## Message ending on its value, continued by hand two spaces in.
  SHOWN =
      "  if found.len > 0:\n    raise newException(\n      OSError,\n" &
      "      \"Shown text belongs in `wording.nim`, named by key; got \" & $found.len & " &
      "\":\\n  \" &\n        found.join(\"\\n  \"),\n    )\n"
    ## Message argument ending on list, continued by hand two spaces in.
  FACES =
      "  if code != 0:\n    raise newException(OSError,\n" &
      "      \"`koch fetch-assets` would not serve every face; got exit `\" & $code & " &
      "\"` --\\n\" & written)\n"
    ## Message whose shape takes its argument past `LINE_MAX`.
  AIM =
      "  block:\n    block:\n" &
      "      check camera.placed(framed).pivot =~ camera.pivot # Orbit turned; what it " &
      "turns about did not.\n"
    ## Assertion whose comment gap of one space takes line of 100 runes to 101.
  HELD =
      "  let depth = offset_x*bounds.forward.x + offset_y*bounds.forward.y + " &
      "offset_z*bounds.forward.z\n" &
      "  if flag: total = offset_x*forward_x + offset_y*forward_y + offset_z*forward_z + " &
      "offset_w*forward_w\n"
    ## Two lines spacing widens: first breaks after `+`; second, `:` before code, breaks nowhere.
  FILTERS =
      "  tag(\n    \"div\",\n    \"class=\\\"filters\\\"\",\n" &
      "    tag(\"div\", \"class=\\\"question\\\"\", tag(\"span\", \"class=\\\"asks\\\"\", " &
      "\"connections\") & holds) &\n" &
      "    tag(\"div\", \"class=\\\"question\\\"\", tag(\"span\", \"class=\\\"asks\\\"\", " &
      "\"lead's hand holds\") & lead) &\n" &
      "    tag(\"div\", \"class=\\\"question\\\"\", tag(\"span\", \"class=\\\"asks\\\"\", " &
      "\"follow's hand held\") & follow),\n  )\n"
    ## Argument hand continued at its own indent, whose lines four spaces in cross `LINE_MAX`.
  PACKED =
      "  found.add \"" & "a".repeat(60) & "\" &\n    \"" & "b".repeat(46) & " " &
      "b".repeat(46) & "\"\n"
    ## Command argument opening mid-line, continued two spaces in on line of 99 runes.
  NAMES = "  const NAMES =\n    \"" & "a".repeat(45) & "\"&\"" & "b".repeat(45) & "\"\n"
    ## Value after `=`, one line of 99 runes that spacing takes to 101.
  RANGES =
      "const\n  RANGES_COMMIT_MONO =\n" &
      "    \"20-7e a0-17f 192 1fa-1ff 218-21b 237 2c6-2c7 2c9 2d8-2dd 300-301 308 30a 326 " &
      "384-386 \" &\n" &
      "    \"388-38a 38c 38e-3a1 3a3-3ce 3d5 1e80-1e85 1ef2-1ef3 2010-201e 2020-2022 2026 2030 " &
      "2032-2033 \" &\n" &
      "    \"2039-203a 203c 203e 2044 204a 2070 2074-208e 20a3-20a4 20a7 20ac 2105 2113 " &
      "2116-2117 2122\"\n" &
    "    ## Codepoints Commit Mono maps: both `woff2` subsets and OpenType file of store map " &
    "one set.\n"
    ## Value of `assets.nim` of `audit` two spaces in, whose second line is 100 runes, and its doc.
  TWIST =
      "  let\n    (lower, upper) =\n      if arm == Arm.Right:\n" &
      "        (twist_range.lower, twist_range.upper)\n      else:\n" &
      "        (-twist_range.upper, -twist_range.lower)\n"
    ## `if` expression after `=`, one level under its statement, as `rigid.nim` of
    ##   `dance_ontology` writes it.
  STACKED =
      "  let\n    distance = (|∙ ⊖(m ∧ n)) div (|∙ (⊖m ∧ ⊖n))\n    negated = - -y\n"
    ## Prefix operator before operand opening with operator, as line 329 of `suites.nim` of PGA
    ##   library writes it, and ASCII form; glued, each pair lexes one operator.


func proofsModule(source: string): Proofs =
  ## Answer module source and what chain asks of it by stub parser, as `koch fix` asks.
  proofsStub("a.nim", source, Dialect.Module)


func fixed(source: string): string =
  ## Fix module source by whole chain, parser answering, as `koch fix` does.
  formatted("a.nim", source, Dialect.Module, source.proofsModule).source


func isSettled(source: string): bool =
  ## Decide whether chain reports nothing over source and fixes it to itself.
  let proofs = source.proofsModule
  checkFormatting("a.nim", source, Dialect.Module, proofs).len == 0 and
    source.fixed == source and formatted("a.nim", source, Dialect.Module, proofs).fixed.len == 0


func operators(source: string): seq[string] =
  ## Read spelling of each operator token of source, in order.
  for t in source.tokens:
    if t.kind == KindToken.Operator: result.add t.spelling(source)


func toggled(path, source: string): Fix =
  ## Turn source `a` into `b`, and any other into `a`, so chain of it never settles.
  Fix(source: if source == "a\n": "b\n" else: "a\n")



suite "Chain":
  test "every layout rule settles in one run, and second run writes nothing":
    let found = checkFormatting("a.nim", LAYOUT, Dialect.Module)
    for rule in ["First-tier banner", "Binary operator", "Parameters take", "Signature", "Call",
                 "trailing separator", "share one bracket", "alphabetised", "`=` takes",
                 "takes doc comment"]:
      check found.anyIt(rule in it.message)  # each rule reported
    let fix = formatted("a.nim", LAYOUT, Dialect.Module)
    check fix.source == "## Do.\n\n" & STRICT_FUNCS & "\n\nimport std/[os, strutils]\n" &
      "\n\n\n#[ Section ]#\n\n" &
      "proc f(a: int, b: string): int {.inline, noSideEffect.} = a + b.len\n" &
      "  ## TODO: Document.\nproc g(a: int) = discard\n  ## TODO: Document.\n" &
      "let x = foo(1, 2)  ## TODO: Document.\necho x\n" &
      "let y = @[  ## TODO: Document.\n  first_item_named_at_length_so_list_crosses_column,\n" &
      "  second_item_named_at_length_so_list_crosses_column,\n]\necho h(q = 1)\nexport x, y\n"
    check checkFormatting("a.nim", fix.source, Dialect.Module).len == 0  # all cleared
    check formatted("a.nim", fix.source, Dialect.Module).source == fix.source  # settled
    check fix.fixed.allIt(it.line in 0 .. LAYOUT.count('\n'))  # each report names line as given


  test "missing doc joins line wrapping leaves, never line opening bracket call wrapping joins":
    let split = STRICT_FUNCS & "\n\nlet x = foo(\n  1,\n  2\n)\n"
    check split.fixed == STRICT_FUNCS & "\n\nlet x = foo(1, 2)  ## TODO: Document.\n"
    check split.fixed.isSettled  # second run writes nothing


  test "dialect decides idiom fixers and checks: module reads them, script does not":
    let breach = "import std/os\nimport std/strutils\nlet a = b+c  ## Sum.\n"
    check checkFormatting("a.nims", breach, Dialect.Script).allIt(it.rule == Rule.SpacingExpression)
    check checkFormatting("a.nim", breach, Dialect.Module).len == 2  # brackets too
    check formatted("a.nims", breach, Dialect.Script).source ==
      "import std/os\nimport std/strutils\nlet a = b + c  ## Sum.\n"  # imports left to module
    check formatted("a.nim", breach, Dialect.Module).source == STRICT_FUNCS &
      "\n\nimport std/[os, strutils]\nlet a = b + c  ## Sum.\n"  # pragma and bracket too


  test "idioms of any Nim code reach script and package, checks and fixers, module's do not":
    # Case held: static pass of `curator/audit` ran idiom checks on `.nim` alone, and chain took
    #   idiom fixers in module alone (`audit.nim`, `steps`), so script and package read none
    #   (#557); domain is each dialect, idioms of any Nim code in each, module's in module alone.
    let breach =
      "let A = 1  ## One.\nlet B = 2  ## Two.\n{.push inline.}\nproc f(): int =\n  ## Do.\n" &
        "  return result\n{.pop.}\n"
    for dialect in Dialect:
      let rules = checkSource("a" & EXTENSIONS[dialect], breach, dialect).mapIt(it.rule)
      check Rule.BindingsSingle in rules and Rule.ReturnResult in rules  # fixer reaches both
      check Rule.PushForeign in rules  # no fixer reaches it
      check (Rule.StrictFuncs in rules) == (dialect == Dialect.Module)  # STYLE.md §2: module
      check formatted("a" & EXTENSIONS[dialect], breach, dialect).source.contains(
        "let\n  A = 1  ## One.\n  B = 2  ## Two.\n",
      )  # bindings share keyword in every dialect
    check checkSource("tests/a.nims", "echo x\n", Dialect.Script).mapIt(it.rule) ==
      @[Rule.OutputDebug]  # test rules of any Nim code read script under `tests/`
    check checkSource("tests/test_a.nims", "echo \"x\"\n", Dialect.Script).len == 0  # no stub


  test "fence keeps lines between its markers, and fix reaches every other line":
    let
      source = "## Do.\n\n" & STRICT_FUNCS & "\n\n" & ROWS_FENCED
      unfenced = source.replace("  " & FENCE_OFF & "\n", "").replace("  " & FENCE_ON & "\n", "")
    check checkFormatting("a.nim", unfenced, Dialect.Module).anyIt(
      it.line == 5 and it.rule == Rule.WrappingCall,
    )  # rows join
    # after fence, and doc each binding takes
    check checkFormatting("a.nim", source, Dialect.Module).mapIt((it.line, it.rule)) == @[
      (12, Rule.SpacingExpression), (5, Rule.DocMissing), (12, Rule.DocMissing),
    ]
    check formatted("a.nim", source, Dialect.Module).source == source.replace(
      "let m = matrix(\n", "let m = matrix(  ## TODO: Document.\n"
    ).replace("let n = matrix(1+2)\n", "let n = matrix(1 + 2)  ## TODO: Document.\n")


  test "fence names each rule broken inside, by count and first line, in order of `Rule`":
    let
      source = "let A = 1  ## One.\n" & FENCE_OFF & "\nlet B = 1+2  ## Sum.\n" &
        "let C = not A == B  ## Same.\nlet D = 3*4  ## Product.\n" & FENCE_ON & "\n"
      unfenced = source.replace(FENCE_OFF, "# Rows.").replace(FENCE_ON, "# Rows.")
      held = checkFenceHeld("a.nims", source, Dialect.Script)
    check held.len == 1 and held[0].line == 2 and held[0].rule == Rule.FenceHeld  # at marker
    check held[0].message == "Fence keeps its lines as written, and inside them " &
      "not-over-binary breaks once at line 4, single-bindings once at line 3 and " &
      "expression-spacing 2 times from line 3" &
      "; got lines `2` to `6`."  # rule left for hand and rule fixer clears alike
    check checkFormatting("a.nims", unfenced, Dialect.Script).mapIt((it.line, it.rule)).sorted ==
      @[(3, Rule.SpacingExpression), (4, Rule.NotOverBinary), (5, Rule.SpacingExpression)]
      # same lines report same unfenced
    check formatted("a.nims", source, Dialect.Script).source == source  # fenced lines unwritten


  test "each fence gives one line: clean one breaks nothing, and open one runs to last line":
    let
      source = "let A = 1+2  ## Sum.\n" & FENCE_OFF & "\nlet B = 1+2  ## Sum.\n" & FENCE_ON &
        "\nlet C = 3  ## Three.\n" & FENCE_OFF & "\nlet D = 4  ## Four.\n"
      held = checkFenceHeld("a.nims", source, Dialect.Script)
    check held.mapIt(it.line) == @[2, 6]  # one for each fence
    check held[0].message.contains(" expression-spacing breaks once at line 3; got")  # 1 outside
    check held[1].message == "Fence keeps its lines as written, and nothing inside breaks a " &
      "rule; got lines `6` to `7`."
    check checkFenceHeld("a.nims", "let a = 1+2\n", Dialect.Script).len == 0  # no fence, no line


  test "fence counts idioms of its dialect, and module's own in module alone":
    let source =
      FENCE_OFF & "\nimport std/[strutils, os]\nlet A = 1  ## One.\nlet B = 2  ## Two.\n" &
        "proc f(): int =\n  ## Do.\n  return result\n"
    check checkFenceHeld("a.nim", source, Dialect.Module)[0].message.contains(
      "inside them return-result breaks once at line 7, bracket-import once at line 2 and " &
        "single-bindings once at line 3; got",
    )
    check checkFenceHeld("a.nims", source, Dialect.Script)[0].message.contains(
      "inside them return-result breaks once at line 7 and single-bindings once at line 3; got",
    )  # script keeps its imports


  test "fence crossing bracket leaves source as written, and is its one finding":
    let crossing = "let a = 1+2\nlet m = f(\n  " & FENCE_OFF & "\n  1,  0,\n)\n" & FENCE_ON & "\n"
    check formatted("a.nims", crossing, Dialect.Script).source == crossing  # nothing written
    check formatted("a.nims", crossing, Dialect.Script).fixed.len == 0
    check checkFormatting("a.nims", crossing, Dialect.Script).mapIt(it.rule) == @[Rule.Fence]
    check checkFenceHeld("a.nims", crossing, Dialect.Script).len == 0  # fault, and no warning


  test "comment table stays as written: width reader sees depends on font, so reading holds it":
    let table = "## Map operators.\n##   |-----|------|\n##   |Oper.| Name |\n" &
      "##   |-----|------|\n##   | ⊖  | anti |\n##   |-----|------|\n\n" & STRICT_FUNCS & "\n"
    check table.isSettled  # glyph row, padded as hand's font shows it (I.4)


  test "nimble file whose copy lock holds is named, beside its lock":
    let files = @[
      ("p/alpha/atlas.lock", LOCK),
      ("p/alpha/alpha.nimble", "version = \"0.1.0\"\n"),
      ("p/beta/beta.nimble", "version = \"0.1.0\"\n"),
    ]
    check nimblesLocked(files) == @["p/alpha/alpha.nimble"]  # lock names its copy
    check nimblesLocked([("atlas.lock", LOCK)]) == @["alpha.nimble"]  # lock at root
    check nimblesLocked([("p/alpha/atlas.lock", "{}\n")]).len == 0  # lock holding no copy



suite "Repair that widens its line":
  test "spacing past `LINE_MAX` splits call crossing it, arguments one level in":
    check (HEAD & PICKING).fixed == HEAD & "  let\n    lateral = tangent_half_view * hypot(\n" &
        "      clip_x / depth * float(width) / float(height),\n      clip_y / depth,\n    )\n"
    check (HEAD & GIF).fixed == HEAD & "  let compressed = encodeLempelZivWelch(\n    arena,\n" &
        "    dictionary,\n    indices.toOpenArray(0, width * height - 1),\n  )\n"
    for source in [PICKING, GIF]: check (HEAD & source).fixed.isSettled


  test "doc gap past `LINE_MAX` moves doc to next line, one round after gap widens":
    check (STRICT_FUNCS & "\n\n" & VERDICTS).fixed == STRICT_FUNCS & "\n\nvar\n" &
        "  READINGS_KEPT*: Readings  ## Readings report renders from.\n" &
        "  SWEEPS_WANTED: seq[SweepAsk]\n    ## Sweeps render asked for and `READINGS_KEPT` " &
        "lacks, in order asked.\n  RUNGS_WANTED: seq[RungAsk]  ## TODO: Document.\n"
    check (STRICT_FUNCS & "\n\n" & VERDICTS).fixed.isSettled


  test "message ending on its value takes shape; continuation four in, or flat in argument":
    check (HEAD & CAPTION).fixed == HEAD & "  for i, line in lines:\n    if is_caption:\n" &
        "      if not line.namesKey(\"captionWindow\"):\n        found.add PATH_DESKTOP_NIM & " &
        "\":\" & $(i + 1) & \": caption must name `captionWindow`; got `\" &\n" &
        "            line.strip & \"`.\"\n"  # first line exactly 100 runes
    check (HEAD & SHOWN).fixed == HEAD & "  if found.len > 0:\n    raise newException(\n" &
        "      OSError,\n      \"Shown text belongs in `wording.nim`, named by key; got `\" & " &
        "$found.len & \"`:\\n  `\" &\n      found.join(\"\\n  \") & \"`.\",\n    )\n"
    for source in [CAPTION, SHOWN]: check (HEAD & source).fixed.isSettled


  test "message shape fitting no call split breaks after operator, flat in its argument":
    check (HEAD & FACES).fixed == HEAD & "  if code != 0:\n    raise newException(\n" &
        "      OSError,\n      \"`koch fetch-assets` would not serve every face; got exit `\" & " &
        "$code & \"` --\\n`\" & written &\n      \"`.\",\n    )\n"
    check (HEAD & FACES).fixed.isSettled


  test "comment gap past `LINE_MAX` moves plain comment to own line above":
    check (HEAD & AIM).fixed == HEAD & "  block:\n    block:\n" &
        "      # Orbit turned; what it turns about did not.\n" &
        "      check camera.placed(framed).pivot =~ camera.pivot\n"
    check (HEAD & AIM).fixed.isSettled


  test "repair no wrap fits keeps width guard on its line alone, with its finding":
    let fix = formatted("a.nim", HEAD & HELD, Dialect.Module)
    check fix.source == HEAD & "  let depth = offset_x * bounds.forward.x + offset_y * " &
        "bounds.forward.y +\n      offset_z * bounds.forward.z\n  if flag: total = " &
        "offset_x*forward_x + offset_y*forward_y + offset_z*forward_z + offset_w*forward_w\n"
    check checkFormatting("a.nim", fix.source, Dialect.Module).mapIt(it.line).deduplicate ==
        @[7]  # finding stays on held line alone
    check attempted("a.nim", HEAD & HELD, Dialect.Module.steps).attempts == 2  # one holds it
    check formatted("a.nim", fix.source, Dialect.Module).source == fix.source  # settled


  test "continuation run with line no wrap fits keeps its indent whole, with its findings":
    check (HEAD & PACKED).fixed == HEAD & PACKED  # no continuation parts from its run
    check checkFormatting("a.nim", HEAD & PACKED, Dialect.Module).mapIt(it.line) == @[6]


  test "argument continued at its own indent stays, since its first piece opens its line":
    check (HEAD & FILTERS).isSettled


  test "value after `=` that breaks after operator sits four spaces past statement, flat":
    check (HEAD & NAMES).fixed == HEAD & "  const NAMES =\n      \"" & "a".repeat(45) &
        "\" &\n      \"" & "b".repeat(45) & "\"\n"
    check (HEAD & NAMES).fixed.isSettled


  test "value after `=` with line no wrap fits keeps its indent whole, with its findings":
    let source = STRICT_FUNCS & "\n\n" & RANGES
    check source.fixed == source
    check checkFormatting("a.nim", source, Dialect.Module).mapIt(it.line) == @[5, 6, 7]


  test "dotted call statement drops its double bracket, and call layout keeps its lines":
    let hugged = HEAD & "  result[a][b].add(BasisSigned(\n    basis: term.basis,\n" &
      "    is_negated: dual_signed.is_negated xor term.is_negated,\n  ))\n"
    check hugged.fixed == HEAD & "  result[a][b].add BasisSigned(\n    basis: term.basis,\n" &
      "    is_negated: dual_signed.is_negated xor term.is_negated,\n  )\n"
    check hugged.fixed.isSettled


  test "group one item to line that would not fit joined takes comma, lines and chain kept":
    let
      chained = HEAD & "  result[m][n].add BasisSigned(\n    basis: product_to.basis,\n" &
        "    is_negated: (\n      m_from.is_negated xor\n      n_from.is_negated xor\n" &
        "      term.is_negated xor\n      product_to.is_negated\n    )\n  )\n"
      dual = HEAD & "  result[b_from] = @[BasisSigned(\n    basis: b_to_complement.basis,\n" &
        "    is_negated: b_to_signed.is_negated xor b_to_complement.is_negated\n  )]\n"
      sliced = HEAD & "  result[b] = @[BasisSigned(\n    basis: result[b][0].basis,\n" &
        "    is_negated: result[b][0].is_negated xor basis.is_negated\n  )]\n"
    check chained.fixed == chained.replace("    )\n  )\n", "    ),\n  )\n")  # `cayleys.nim:271`
    check dual.fixed == dual.replace("is_negated\n  )]", "is_negated,\n  )]")  # `:338`
    check sliced.fixed == sliced.replace("is_negated\n  )]", "is_negated,\n  )]")  # `:604`
    for source in [chained, dual, sliced]: check source.fixed.isSettled  # second run


  test "block head whose last line would stand at body's indent reads apart from body":
    let head = HEAD & "  if check(a_long_name, first_condition or second_condition or\n" &
      "    second_condition and first_condition):\n    echo a_long_name\n"
    check head.fixed == HEAD &
      "  if check(a_long_name, first_condition or second_condition or\n" &
      "      (second_condition and first_condition)):\n    echo a_long_name\n"  # STYLE.md §5
    check head.fixed.isSettled


  test "needless parentheses go, and spacing glues prefix operator they leave, in one round":
    let distances = HEAD & "  let distance_b = (|∙ ⊖(𝐦 ∧ 𝐧)) + (|∘ (𝐦 ∧ ⊖𝐧))\n"
    check distances.fixed == HEAD & "  let distance_b = |∙ ⊖(𝐦 ∧ 𝐧) + |∘(𝐦 ∧ ⊖𝐧)\n"
    check attempted("a.nim", distances, Dialect.Module.steps, distances.proofsModule).attempts == 1
    check distances.fixed.isSettled


  test "power operator and needless parentheses agree on wrapped exponent, in one round":
    let wrapped = HEAD & "  let p = a^(-b)\n"
    check wrapped.isSettled  # parentheses rule keeps group power operator needs
    for breach in [HEAD & "  let p = a ^ -b\n", HEAD & "  let p = a ^ (-b)\n"]:
      check breach.fixed == wrapped
      check attempted("a.nim", breach, Dialect.Module.steps, breach.proofsModule).attempts == 1
    for (breach, mended) in [
      ("  let p = -1 ^ (k)\n", "  let p = -1^k\n"),  # group of one operand goes (X.4)
      ("  let p = -1 ^ (a * b)\n", "  let p = -1^(a * b)\n"),  # group of math stays
    ]:
      check (HEAD & breach).fixed == HEAD & mended
      check (HEAD & mended).isSettled


  test "needless parentheses wait for parser: none goes unanswered, and chain asks for each":
    let
      source = HEAD & "  let c = ☆(m) ∧ n + ■(k)\n"
      unanswered = formatted("a.nim", source, Dialect.Module)
    check unanswered.source == source  # nothing else due, so nothing written
    check unanswered.asked == @[source]  # source as parentheses step reads it
    check checkFormatting("a.nim", source, Dialect.Module).len == 0  # no answer, no finding
    let proofs = source.proofsModule
    check checkFormatting("a.nim", source, Dialect.Module, proofs).mapIt(it.rule) ==
      @[Rule.ParenthesesNeedless, Rule.ParenthesesNeedless]
    let fix = formatted("a.nim", source, Dialect.Module, proofs)
    check fix.source == HEAD & "  let c = ☆m ∧ n + ■k\n" and fix.asked.len == 0  # all answered
    let fenced = HEAD & "  #!fix off\n  let c = ☆(m) ∧ n + ■(k)\n  #!fix on\n"
    check checkFenceHeld("a.nim", fenced, Dialect.Module)[0].message.contains(
      "nothing inside breaks",
    )
    check checkFenceHeld("a.nim", fenced, Dialect.Module, fenced.proofsModule)[0].message.contains(
      "needless-parentheses breaks 2 times from line 6",
    )  # answer for source as given counts its groups


  test "value after `=` that is no chain keeps one level under its statement":
    check (HEAD & TWIST).fixed == HEAD & TWIST
    check checkFormatting("a.nim", HEAD & TWIST, Dialect.Module).len == 0


  test "operator tokens read same before and after, `&` of message shape aside":
    let verdicts = STRICT_FUNCS & "\n\n" & VERDICTS
    for source in [PICKING, GIF, CAPTION, SHOWN, FACES, AIM, HELD, STACKED].mapIt(HEAD & it) &
        verdicts:
      let (before, after) = (source.operators, source.fixed.operators)
      check after.filterIt(it != "&") == before.filterIt(it != "&")
      check after.countIt(it == "&") - before.countIt(it == "&") in 0 .. 1  # one shape at most


  test "file that does not settle stays as written, and its fix says why":
    let fix = formattedBy("a.nim", "a\n", [guarded(toggled)])
    check fix.source == "a\n" and fix.fixed.len == 0  # half-settled file never written
    check fix.unsettled == "File still changes after 3 rounds of fixers, so fix leaves it as " &
        "written; got `3` rounds."  # message of its own, which no rule names
    check formattedBy("a.nim", "a\n", [guarded(toggled), guarded(toggled)]).unsettled.len == 0


  test "output agrees whatever order files come in, and on second run":
    let
      sources = [LAYOUT, HEAD & PICKING, HEAD & HELD, HEAD & FACES, HEAD & AIM]
      outputs = sources.mapIt(it.fixed)
    var backward = newSeq[string](sources.len)
    for k in countdown(sources.high, 0): backward[k] = sources[k].fixed
    check backward == outputs  # order of files moves nothing
    check sources.mapIt(it.fixed) == outputs  # second run agrees
