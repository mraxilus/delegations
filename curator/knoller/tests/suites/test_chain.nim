## Replicate chain of `chain.nim` header: every fixer in one order until source settles, checks
##   of what fixers clear, and nimble files whose copy lock holds.
##   Fixtures copy those of `curator/audit/tests/suites/test_fixes.nim`, which drives same chain
##     through `koch fix`; fix to one is finished only when other is checked.
##   Cases of repair that widens its line are lines of tree as they stood before `koch fix` ran:
##     `picking.nim`, `gif.nim` and `tools/build.nim` of `rga_visualiser`, `verdicts.nim` of
##     `dance_ontology` and `test_camera_aim.nim` of `rga_visualiser`.

{.experimental: "strictFuncs".}

import std/[options, sequtils, strutils, unittest]
import ../../src/knoller/[chain {.all.}, fences, idioms, reports, tokens]


const
  LAYOUT =
    "## Do.\n\n" & STRICT_FUNCS & "\n\nimport std/os\nimport std/strutils\n\n\n" &
    "#[ Section ]#\n\n" &
    "proc f(a: int; b: string): int {.noSideEffect, inline.} = a+b.len\n" &
    "proc g(\n    a: int\n) = discard\n" &
    "let x = foo(\n  1,\n  2,\n)\necho x\nlet y = @[\n  1,\n  2\n]\necho h(q=1)\nexport y, x\n"
    ## Nim source breaking each layout rule `checkFormatting` holds.
  FENCED_ROWS =
    "let m = matrix(\n  #!fix off\n  1,  0,\n\n  0,  1,\n  #!fix on\n)\n" &
    "let n = matrix(1+2)\n"
    ## Nim source whose hand-shaped rows fence keeps, and whose call after fence fix reaches.
  LOCK =
    "{\n  \"items\": {},\n  \"nimbleFile\": {\n    \"filename\": \"alpha.nimble\",\n" &
    "    \"content\": []\n  }\n}\n"
    ## Atlas lock holding copy of nimble file `alpha.nimble`.
  HEAD = STRICT_FUNCS & "\n\nproc p() =\n"  ## Opening of each case: module pragma and routine.
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


func fixedOf(source: string): string =
  ## Fix module source by whole chain, as `koch fix` does.
  formatted("a.nim", source, Dialect.Module).source


func isSettled(source: string): bool =
  ## Decide whether chain reports nothing over source and fixes it to itself.
  checkFormatting("a.nim", source, Dialect.Module).len == 0 and source.fixedOf == source and
      formatted("a.nim", source, Dialect.Module).fixed.len == 0


func operatorsOf(source: string): seq[string] =
  ## Read spelling of each operator token of source, in order.
  for t in source.tokens:
    if t.kind == TokenKind.Operator: result.add t.spelling(source)


func toggled(path, source: string): Fix =
  ## Turn source `a` into `b`, and any other into `a`, so chain of it never settles.
  Fix(source: if source == "a\n": "b\n" else: "a\n")



suite "Chain":
  test "every layout rule settles in one run, and second run writes nothing":
    let found = checkFormatting("a.nim", LAYOUT, Dialect.Module)
    for rule in ["(X.2)", "(X.9)", "(STYLE.md §5)", "Signature", "Call", "trailing separator",
                 "share one bracket", "alphabetised", "`=` takes"]:
      check found.anyIt(rule in it.message)  # each rule reported
    let fix = formatted("a.nim", LAYOUT, Dialect.Module)
    check fix.source == "## Do.\n\n" & STRICT_FUNCS & "\n\nimport std/[os, strutils]\n" &
      "\n\n\n#[ Section ]#\n\n" &
      "proc f(a: int, b: string): int {.inline, noSideEffect.} = a + b.len\n" &
      "proc g(a: int) = discard\n" &
      "let x = foo(1, 2)\necho x\nlet y = @[\n  1,\n  2,\n]\necho h(q = 1)\nexport x, y\n"
    check checkFormatting("a.nim", fix.source, Dialect.Module).len == 0  # all cleared
    check formatted("a.nim", fix.source, Dialect.Module).source == fix.source  # settled
    check fix.fixed.allIt(it.line in 0 .. LAYOUT.count('\n'))  # each report names line as given


  test "dialect decides idiom fixers and checks: module reads them, script does not":
    let breach = "import std/os\nimport std/strutils\nlet a = b+c\n"
    check checkFormatting("a.nims", breach, Dialect.Script).mapIt(it.message).allIt("X.9" in it)
    check checkFormatting("a.nim", breach, Dialect.Module).len == 2  # brackets too
    check formatted("a.nims", breach, Dialect.Script).source ==
      "import std/os\nimport std/strutils\nlet a = b + c\n"  # imports left to module
    check formatted("a.nim", breach, Dialect.Module).source == STRICT_FUNCS &
      "\n\nimport std/[os, strutils]\nlet a = b + c\n"  # pragma and bracket too


  test "fence keeps lines between its markers, and fix reaches every other line":
    let
      source = "## Do.\n\n" & STRICT_FUNCS & "\n\n" & FENCED_ROWS
      unfenced = source.replace("  " & FENCE_OFF & "\n", "").replace("  " & FENCE_ON & "\n", "")
    check checkFormatting("a.nim", unfenced, Dialect.Module).anyIt(it.line == 5)  # rows join
    check checkFormatting("a.nim", source, Dialect.Module).mapIt(it.line) == @[12]  # after fence
    check formatted("a.nim", source, Dialect.Module).source == source.replace("1+2", "1 + 2")


  test "fence crossing bracket leaves source as written, and is its one finding":
    let crossing = "let a = 1+2\nlet m = f(\n  " & FENCE_OFF & "\n  1,  0,\n)\n" & FENCE_ON & "\n"
    check formatted("a.nims", crossing, Dialect.Script).source == crossing  # nothing written
    check formatted("a.nims", crossing, Dialect.Script).fixed.len == 0
    check checkFormatting("a.nims", crossing, Dialect.Script).mapIt(it.rule) == @[Rule.Fence]


  test "nimble file whose copy lock holds is named, beside its lock":
    let files = @[
      ("p/alpha/atlas.lock", LOCK),
      ("p/alpha/alpha.nimble", "version = \"0.1.0\"\n"),
      ("p/beta/beta.nimble", "version = \"0.1.0\"\n"),
    ]
    check lockedNimbles(files) == @["p/alpha/alpha.nimble"]  # lock names its copy
    check lockedNimbles([("atlas.lock", LOCK)]) == @["alpha.nimble"]  # lock at root
    check lockedNimbles([("p/alpha/atlas.lock", "{}\n")]).len == 0  # lock holding no copy



suite "Repair that widens its line":
  test "spacing past `LINE_MAX` splits call crossing it, arguments one level in":
    check (HEAD & PICKING).fixedOf == HEAD & "  let\n    lateral = tangent_half_view * hypot(\n" &
        "      clip_x / depth * float(width) / float(height),\n      clip_y / depth,\n    )\n"
    check (HEAD & GIF).fixedOf == HEAD & "  let compressed = encodeLempelZivWelch(\n    arena,\n" &
        "    dictionary,\n    indices.toOpenArray(0, width * height - 1),\n  )\n"
    for source in [PICKING, GIF]: check (HEAD & source).fixedOf.isSettled


  test "doc gap past `LINE_MAX` moves doc to next line, one round after gap widens":
    check (STRICT_FUNCS & "\n\n" & VERDICTS).fixedOf == STRICT_FUNCS & "\n\nvar\n" &
        "  READINGS_KEPT*: Readings  ## Readings report renders from.\n" &
        "  SWEEPS_WANTED: seq[SweepAsk]\n    ## Sweeps render asked for and `READINGS_KEPT` " &
        "lacks, in order asked.\n  RUNGS_WANTED: seq[RungAsk]\n"
    check (STRICT_FUNCS & "\n\n" & VERDICTS).fixedOf.isSettled


  test "message ending on its value takes shape, and its continuation four spaces in":
    check (HEAD & CAPTION).fixedOf == HEAD & "  for i, line in lines:\n    if is_caption:\n" &
        "      if not line.namesKey(\"captionWindow\"):\n        found.add PATH_DESKTOP_NIM & " &
        "\":\" & $(i + 1) & \": caption must name `captionWindow`; got `\" &\n" &
        "            line.strip & \"`.\"\n"  # first line exactly 100 runes
    check (HEAD & SHOWN).fixedOf == HEAD & "  if found.len > 0:\n    raise newException(\n" &
        "      OSError,\n      \"Shown text belongs in `wording.nim`, named by key; got `\" & " &
        "$found.len & \"`:\\n  `\" &\n          found.join(\"\\n  \") & \"`.\",\n    )\n"
    for source in [CAPTION, SHOWN]: check (HEAD & source).fixedOf.isSettled


  test "message shape fitting no call split breaks after operator, four spaces in":
    check (HEAD & FACES).fixedOf == HEAD & "  if code != 0:\n    raise newException(\n" &
        "      OSError,\n      \"`koch fetch-assets` would not serve every face; got exit `\" & " &
        "$code & \"` --\\n`\" & written &\n          \"`.\",\n    )\n"
    check (HEAD & FACES).fixedOf.isSettled


  test "comment gap past `LINE_MAX` moves plain comment to own line above":
    check (HEAD & AIM).fixedOf == HEAD & "  block:\n    block:\n" &
        "      # Orbit turned; what it turns about did not.\n" &
        "      check camera.placed(framed).pivot =~ camera.pivot\n"
    check (HEAD & AIM).fixedOf.isSettled


  test "repair no wrap fits keeps width guard on its line alone, with its finding":
    let fix = formatted("a.nim", HEAD & HELD, Dialect.Module)
    check fix.source == HEAD & "  let depth = offset_x * bounds.forward.x + offset_y * " &
        "bounds.forward.y +\n      offset_z * bounds.forward.z\n  if flag: total = " &
        "offset_x*forward_x + offset_y*forward_y + offset_z*forward_z + offset_w*forward_w\n"
    check checkFormatting("a.nim", fix.source, Dialect.Module).mapIt(it.line).deduplicate ==
        @[6]  # finding stays on held line alone
    check attempted("a.nim", HEAD & HELD, Dialect.Module.stepsOf).attempts == 2  # one holds it
    check formatted("a.nim", fix.source, Dialect.Module).source == fix.source  # settled


  test "continuation run with line no wrap fits keeps its indent whole, with its findings":
    check (HEAD & FILTERS).fixedOf == HEAD & FILTERS  # no continuation parts from its run
    check checkFormatting("a.nim", HEAD & FILTERS, Dialect.Module).mapIt(it.line) == @[8, 9]


  test "operator tokens read same before and after, `&` of message shape aside":
    let verdicts = STRICT_FUNCS & "\n\n" & VERDICTS
    for source in [PICKING, GIF, CAPTION, SHOWN, FACES, AIM, HELD].mapIt(HEAD & it) & verdicts:
      let (before, after) = (source.operatorsOf, source.fixedOf.operatorsOf)
      check after.filterIt(it != "&") == before.filterIt(it != "&")
      check after.countIt(it == "&") - before.countIt(it == "&") in 0 .. 1  # one shape at most


  test "file that does not settle stays as written, and its fix says why":
    let fix = formattedBy("a.nim", "a\n", [guarded(toggled)])
    check fix.source == "a\n" and fix.fixed.len == 0  # half-settled file never written
    check fix.left.mapIt(it.rule) == @[Rule.Unsettled]
    check fix.left[0].message.endsWith("got `3` rounds.")
    check formattedBy("a.nim", "a\n", [guarded(toggled), guarded(toggled)]).left.len == 0


  test "output agrees whatever order files come in, and on second run":
    let
      sources = [LAYOUT, HEAD & PICKING, HEAD & HELD, HEAD & FACES, HEAD & AIM]
      outputs = sources.mapIt(it.fixedOf)
    var backward = newSeq[string](sources.len)
    for k in countdown(sources.high, 0): backward[k] = sources[k].fixedOf
    check backward == outputs  # order of files moves nothing
    check sources.mapIt(it.fixedOf) == outputs  # second run agrees
