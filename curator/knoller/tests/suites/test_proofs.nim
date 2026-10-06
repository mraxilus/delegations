## Replicate proof of `proofs.nim` header: probe run by compiler answers which candidate groups
##   go, alone and together, and compiler that does not run answers none, with reason.
##   Parser is real here: compiler building this suite, 2.2.12 in knoller's job, so verdicts of
##     ASCII cases that `stubs.nim` gives other suites are held to parser itself.

{.experimental: "strictFuncs".}

import std/[os, osproc, sequtils, strutils, tables, tempfiles, unittest]
import ../../src/knoller/[chain, parentheses, proofs, reports]


const
  NIM = getCurrentCompilerExe()  ## Compiler building suite, whose parser answers.
  HEAD = "{.experimental: \"strictFuncs\".}\n\n"  ## Opening of module chain writes nothing to.


proc provenBy(sources: openArray[string]): seq[seq[int]] =
  ## Answer each source by parser of `NIM`, in one run; empty where compiler fails.
  let proving = compilerProver(NIM)(@sources)
  check proving.failure.len == 0
  proving.answers


proc fixedBy(source: string): string =
  ## Fix module source by whole chain, asking parser of `NIM` what chain asks until it settles;
  ##   source opens with `strictFuncs`, so that rule writes nothing.
  var proofs = Proofs()
  for ask in 1 .. 8:
    let fix = formatted("a.nim", source, Dialect.Module, proofs)
    if fix.asked.len == 0: return fix.source
    check proofs.answered(fix.asked, compilerProver(NIM)).len == 0
  formatted("a.nim", source, Dialect.Module, proofs).source



suite "Proofs":
  test "probe names each source by file and each candidate by byte spans of its brackets":
    let probe = probeOf(["let s = @(x)\n", "let y = (a)\n"])
    check "prove(\"s0.nim\", @[[9, 10, 11, 12]])\n" in probe  # `(` and `)` of `(x)`
    check "prove(\"s1.nim\", @[])\n" in probe  # no candidate: parser asked nothing
    check "staticRead" in probe and "parseStmt" in probe


  test "answer lines read by source; output holding none is failure with its first line":
    let proving = provingOf("knoller-proof s1.nim: 8 20\nknoller-proof s0.nim:\nother\n", 2)
    check proving.answers == @[newSeq[int](), @[8, 20]] and proving.failure.len == 0
    let outside = provingOf("knoller-proof s7.nim: 1\nknoller-proof s0.nim:\n", 1)
    check outside.answers == @[newSeq[int]()]  # source not asked is passed over
    let failed = provingOf("\nError: cannot open file\nmore\n", 1)
    check failed.answers == @[newSeq[int]()]  # none proven
    check failed.failure == "Parser proved no removal, since compiler ran no probe; got " &
      "`Error: cannot open file`."


  test "parser proves bare operand after sigil, and keeps group whose removal moves reading":
    let sources = [
      "let s = @(x)\n",
      "let x = (a.b(c)[i]) + 1\n",
      "links = @(PAIRS[task.pair][0])\n",  # `tests/test_read.nim:79` of `dance_ontology` (#539)
      "let s = @(x.items)\n",  # sigil binds `x` before field, index or call
      "let s = @(f(a))\n",
      "let s = @@(x[0])\n",
      "let s = @(x[i])\n",
      "let x = b + -(1)\n",  # `-1` lexes one literal
      "let z = a - (-b) -1\n",
    ]
    check sources.provenBy == @[
      @[9], @[8], @[], @[], @[], @[], @[], @[], @[],
    ]


  test "group scanner reads as operand stays where parser reads command around it":
    # Scanner reads `(-b)` as prefix term beside `-`, and no guard of it looks past `-1`. Parser
    #   reads group as callee of command `(-b) -1`, and without it, `-` over command `b -1`.
    check provenBy(["let z = a - (-b) -1\n"]) == @[newSeq[int]()]
    check (HEAD & "let z = a - (-b) -1\n").fixedBy == HEAD & "let z = a - (-b) -1\n"
    check (HEAD & "let z = a - (-b) - 1\n").fixedBy == HEAD & "let z = a - -b - 1\n"  # binary


  test "chain removes what parser proves and nothing more, and second run writes nothing":
    for (given, mended) in [
      ("let s = @(x)\n", "let s = @x\n"),
      ("links = @(PAIRS[task.pair][0])\n", "links = @(PAIRS[task.pair][0])\n"),
      ("let x = (a.b(c)[i]) + @(f(a))\n", "let x = a.b(c)[i] + @(f(a))\n"),
    ]:
      check (HEAD & given).fixedBy == HEAD & mended
      check (HEAD & mended).fixedBy == HEAD & mended  # second run writes nothing


  test "source parser cannot read keeps every group; glyph of commit pin is name to 2.2.12":
    check provenBy(["let x = (a) + b)\n"]) == @[newSeq[int]()]  # unreadable
    check provenBy(["let c = ☆(m) ∧ 𝐞ₙ\n"]) == @[newSeq[int]()]  # `☆(m)` call, `☆m` name
    # Cost: wrong compiler can prove what right one refuses. 2.2.12 reads `■m` as one name, so
    #   `(■m).x` reads as `■m.x`; commit pin reads `■m.x` as `■(m.x)`. So `koch fix` passes pin.
    check provenBy(["let x = (■m).x + y\n"]) == @[@[8]]


  test "candidates proven alone that differ together join one at a time, in source order":
    # No pair of real groups was found to differ together (`PROVENANCE.md`), so group named
    #   twice stands in: alone each proves, together they cut four brackets of two.
    let directory = createTempDir("knoller_suite_", "")
    defer: removeDir(directory)
    writeFile(directory / "s0.nim", "let x = (y) + (z)\n")
    let probe = probeOf([""]).replace(
      "prove(\"s0.nim\", @[])",
      "prove(\"s0.nim\", @[[8, 9, 10, 11], [8, 9, 10, 11], [14, 15, 16, 17]])",
    )
    writeFile(directory / "probe.nim", probe)
    let output = execProcess(
      NIM,
      args = ["check", "--hints:off", "--nimcache:" & directory / "cache", directory / "probe.nim"],
      options = {poStdErrToStdOut},
    )
    check provingOf(output, 1).answers == @[@[8, 14]]  # second of twice-named group left out


  test "compiler that does not run proves nothing, and says why":
    let proving = compilerProver("/nonexistent/nim")(@["let s = @(x)\n"])
    check proving.answers == @[newSeq[int]()]
    check proving.failure.startsWith("Parser proved no removal, since compiler ran no probe; got `")
    check compilerProver("/nonexistent/nim")(@[]).failure.len == 0  # nothing asked, none run


  test "answers held by source, so each is asked once, and failure holds none proven":
    var
      runs = 0
      proofs = Proofs()
    let counted = proc (sources: seq[string]): Proving =
      inc runs
      Proving(answers: sources.mapIt(it.candidatesOf.mapIt(it.opening[0])))
    check proofs.answered(["let s = @(x)\n", "let s = @(x)\n"], counted).len == 0
    check runs == 1 and proofs.answers["let s = @(x)\n"] == @[9]
    discard proofs.answered(["let s = @(x)\n"], counted)
    check runs == 1  # answered source asks none
    let failure = proofs.answered(["let t = @(y)\n"], compilerProver("/nonexistent/nim"))
    check failure.len > 0 and proofs.answers["let t = @(y)\n"].len == 0
