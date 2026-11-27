## Hold that each gap of coverage shows in run (Article IX.9), as Architect ruled on rule 17 of
##   #443: skip gives its reason after it, on comment line right above it at its indent, or in echo
##   of text there. Gap inside test that runs, and test under bare `when`, report too; each stays
##   for hand, since no text gives reason. Bare `when` around whole suite configures suite, so
##   test under it passes (ruling `D3 a` of #980).

{.experimental: "strictFuncs".}

import std/[sequtils, unittest]
import ../../src/knoller/[reports, skips]


const
  EQUATION_87 =
    "  test \"Equation 2.87-89\":\n    when IS_RIGID:\n" &
    "      for 𝐦, _, _ in sampleMultivectors():\n" &
    "        #echo &\"{|∙𝐦=}, {sqrt(𝐦 ∙ 𝐦)=}\"\n" &
    "        check |∙𝐦 =~ sqrt(𝐦 ∙ 𝐦)  # 2.87\n" &
    "        check |∘𝐦 =~ sqrtAnti(𝐦 ∘ 𝐦)  # 2.88\n" &
    "        check ^𝐦 =~ 𝐦 div |∘𝐦  # 2.89a\n" &
    "        check ^𝐦 =~ 𝐦 div sqrtAnti(𝐦 ∘ 𝐦)  # 2.89b\n\n" &
    "    when IS_CONFORMAL: skip()\n"
    ## Lines 322 to 331 of `tests/suites.nim` of PGA library at `3d9696e`: skip under
    ##   configuration that gives no reason.
  GAP =
    "  test \"Equation 2.68-70\":\n    for 𝐦, 𝐧, _ in sampleMultivectors():\n" &
    "      when IS_CONFORMAL:\n        check ∙𝐦 ∧ ∙𝐧 =~ ∙(𝐦 ∧ 𝐧)  # 2.70a\n" &
    "        # TODO: Find out how other parts should distribute (2.70b/c/d).\n"
    ## Lines 271 to 288 of `tests/suites.nim` at `3d9696e`, rigid branch and first checks of
    ##   conformal branch cut: test runs, so its TODO is gap that run never shows.
  EQUATION_445 =
    "  test \"Equation 4.45\":\n    skip()\n    # when IS_RIGID: skip()\n" &
    "    # when IS_CONFORMAL:\n    #   for 𝐦, 𝐧, 𝐨 in sampleMultivectors():\n" &
    "    #     echo &\"{𝐦=}, {|⊘𝐦=}, {sqrt(𝐦 ∘ 𝐦)=}\"\n" &
    "    #     check |⊘𝐦 =~ sqrt(𝐦 ∘ 𝐦)\n"
    ## Lines 431 to 437 of `tests/suites.nim` at `3d9696e`: skip in every configuration, its law
    ##   commented out below it.
  PLACEHOLDER = "  test \"TODO: Add remaining chapter 2 tests\":\n    skip()\n"
    ## Lines 419 and 420 of `tests/suites.nim` at `3d9696e`: placeholder whose name gives reason.
  PATH = "tests/suites.nim"  ## Path under `tests` of package, where library holds its suite.
  NIMBLE = "pga.nimble"  ## Nimble file of package, at its root.
  SKIP = "skip carries its reason, so run shows why test skips; got `"
    ## Opening of message of skip that gives no reason.


func found(source: string): seq[(int, string)] =
  ## Read line and message of each report of skip reason in source, read as file of tests.
  checkSkips(PATH, source, NIMBLE).mapIt((it.line, it.brief))



suite "Skips":
  test "skip with no reason reports, under configuration and in every configuration":
    check EQUATION_87.found == @[(10, SKIP & "when IS_CONFORMAL: skip()`")]  # library line 331
    check EQUATION_445.found == @[(2, SKIP & "skip()`")]  # line 432; law below it is no code
    check PLACEHOLDER.found.len == 0  # name opening with `TODO:` gives reason


  test "reason stands after skip, on comment line right above it, or in echo of text there":
    for kept in [
      "  test \"a\":\n    when IS_CONFORMAL: skip()  # TODO: Enable when dot product fixed.\n",
      "  test \"a\":\n    # Conformal dot product breaks it.\n    when IS_CONFORMAL: skip()\n",
      "  test \"a\":\n    echo \"Conformal dot product breaks it.\"\n" &
        "    when IS_CONFORMAL: skip()\n",
    ]:
      check kept.found.len == 0
    check ("  test \"a\":\n    # Small build cannot hold it.\n    if SMALL:\n      skip()\n" &
      "    else:\n      check b\n").found.len == 0  # reason right above branch that skips
    check ("  test \"a\":\n    # Small build cannot hold it.\n    if SMALL:\n      skip()\n" &
      "      check c\n").found.len == 1  # skip opening branch is not its whole body
    for bare in [
      "  test \"a\":\n    when IS_RIGID:\n      check b\n      # Rigid alone.\n" &
        "    when IS_CONFORMAL: skip()\n",  # comment at other indent
      "  test \"a\":\n    # Reason apart.\n\n    when IS_CONFORMAL: skip()\n",  # blank line between
      "  test \"a\":\n    echo x\n    when IS_CONFORMAL: skip()\n",  # echo of no text
    ]:
      check bare.found.mapIt(it[0]) == @[bare.count('\n')]


  test "TODO inside test that runs is gap, and TODO that gives reason of skip is none":
    check GAP.found == @[
      (5, "gap in coverage is placeholder test that skips, so run shows it; got " &
        "`# TODO: Find out how other parts should distribute (2.70b/c/d).`"),
    ]  # library line 288
    check "  test \"a\":\n    check b  # TODO: Widen.\n".found.len == 1  # trailing TODO too
    check "  test \"a\":\n    check b  # Name opening with `TODO:` passes.\n".found.len == 0
      # comment that names word, and opens with none, marks no gap
    check "  test \"a\":\n    skip()  # Waits on parser.\n    # TODO: Write law.\n".found.len == 0
      # test skipping at its own level shows in run as skipped


  test "test under bare `when` reports, and test under `when` with other branch passes":
    let gated = "when defined(js):\n  test \"a\":\n    check b\n"
    check gated.found == @[
      (2, "test that cannot run under configuration skips there, so run keeps it; got " &
        "`test \"a\":` under `when defined(js):`"),
    ]
    check (gated & "else:\n  test \"a\":\n    skip()  # Needs browser.\n").found.len == 0
    check "when isMainModule:\n  test \"a\":\n    check b\n".found.len == 0  # entry of module
    check "when A:\n  when B:\n    test \"a\":\n      check b\n".found.len == 1  # test reports once


  test "test under bare `when` around whole suite passes, and under one inside suite reports":
    # Ruling `D3 a` of #980: gate around whole suite configures suite, and skips no test in it.
    #   Cases: `tests/suites/test_arenas_frame.nim:10` of `pga_visualiser` at `16a573cc`, gate
    #   around suite, cut to its first test; `tests/suites/test_share.nim:36`, gate inside suite.
    let around = "when not defined(js):\n  suite \"Frame Arenas\":\n    var\n" &
      "      backing_first: array[512, byte]\n\n\n" &
      "    test \"a frame carves from one block while the other holds the frame before it\":\n" &
      "      var arenas = initArenasFrame(backing_first, backing_second)\n"
    check around.found.len == 0
    let inside = "suite \"Share\":\n  test \"a\":\n    check b\n\n\n  when not defined(js):\n" &
      "    test \"a desktop frame is owned by the file its code is in\":\n      let paths = [1]\n"
    check inside.found == @[
      (7, "test that cannot run under configuration skips there, so run keeps it; got " &
        "`test \"a desktop frame is owned by the file its code is in\":` under " &
        "`when not defined(js):`"),
    ]
    check ("when A:\n  suite \"S\":\n    test \"a\":\n      check b\n" &
      "    when B:\n      test \"c\":\n        check d\n").found.mapIt(it[0]) == @[6]
      # gate inside suite reports, though gate around suite holds both
    let nested = "when A:\n  when B:\n    suite \"S\":\n      test \"a\":\n        check b\n"
    check nested.found.len == 0  # each gate around suite configures it
    check "when A:\n  suite(\"S\"):\n    test \"a\":\n      check b\n".found.len == 1
      # cost: suite written as call is unread, so gate around it reports its test


  test "skip of generated code, and file outside `tests` of package, report none":
    check "  test \"a\":\n    let n = quote do:\n      skip()\n".found.len == 0
    check "  let n = quote do:\n    test \"a\":\n      skip()\n".found.len == 0  # test generated
    check checkSkips("src/a.nim", EQUATION_87, NIMBLE).len == 0
