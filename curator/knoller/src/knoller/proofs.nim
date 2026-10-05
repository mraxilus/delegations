## Prove each removal of needless parentheses by parser of code's own compiler (Article X.4):
##   probe program, run by that compiler under `nim check`, reads each source asked with
##   `staticRead`, parses it with `macros.parseStmt`, and answers which candidate groups go.
##   Candidate goes where source without it parses to same tree, each `nnkPar` of one child
##     collapsed on both sides (`same`). Every candidate proven alone is then tried together;
##     where that tree differs, each joins in source order where set so far still proves, so
##     answer is largest set one pass in source order finds, same on every run.
##   Source parser cannot read answers none, so every group stays.
##   Compiler is caller's: `koch fix` passes pin of each project; command line takes `--nim`,
##     else pin of nearest nimble file above each file, else `nim` on PATH (`command.nim`).
##     Prover of each pin (`pinProvers`) resolves compiler serving it through one `Toolchains`
##     where first source asks, so pin no source asks about is never fetched.
##   One run of compiler answers every source asked at once, in private temporary directory
##     removed after; output lines `knoller-proof s<k>.nim: <offsets>` carry answers.
##   Prover is proc value (`Prover`), so suites stub it and chain stays pure: chain asks
##     (`Fix.asked`), caller runs prover and holds answers in `Proofs`, chain runs again.
##
##   Rejected: parser of compiler linked into knoller. Source of commit pin does not build under
##     standard library of 2.2.12 (`llstream.nim`: `readRawData`), and 2.2.12 parser lexes glyphs
##     of commit pin as names.
##   Cost: one compile of probe for each round of asking, about 0.5 s on this container
##     (measured 2026-10-05, both pins); caller asks again only where answer moves source.
##   Cost: compiler that does not run answers none, so rule removes nothing; caller prints why.
##   Cost: wrong compiler can prove what right one refuses. Glyph operators of commit pin of
##     `ronri` projects lex as names under 2.2.12, so 2.2.12 keeps `☆(m) ∧ n`, since `☆(m)`
##     reads as call there, but proves `(■m).x + y`, which commit pin reads as `■(m.x) + y`.
##     So `koch fix` passes pin of each project, and command line reads pin of nearest nimble
##     file, so `ronri` code takes its commit pin with no option.

{.experimental: "strictFuncs".}

import std/[options, os, osproc, sequtils, strutils, tables, tempfiles]
import ./[compilers, parentheses, pins, reports]


type
  Proving* = object  ## Define what one run of prover answered.
    answers*: seq[seq[int]]  ## Byte offset of `(` of each group proven, one list for each source.
    failure*: string  ## Why no compiler answered, ending with value; empty where one did.

  Prover* = proc (sources: seq[string]): Proving {.closure.}
    ## Define prover: sources asked in, answer of parser for each out.

  ProverOf* = proc (pin: string): Prover {.closure.}
    ## Define prover of each pin: parser of compiler serving it.


const
  MARK = "knoller-proof "  ## Opening of each answer line probe prints.
  PROBE = """
import std/[macros, strutils]

proc unwrapped(n: NimNode): NimNode =
  result = n
  while result.kind == nnkPar and result.len == 1: result = result[0]

proc same(a, b: NimNode): bool =
  let (a, b) = (a.unwrapped, b.unwrapped)
  if a == b: return true
  if a.kind != b.kind or a.len != b.len or a.len == 0: return false
  for i in 0 ..< a.len:
    if not same(a[i], b[i]): return false
  true

proc removed(text: string, groups: seq[array[4, int]]): string =
  var spans: seq[(int, int)]
  for g in groups: spans.add @[(g[0], g[1]), (g[2], g[3])]
  result = text
  for i in countdown(spans.high, 0):
    var best = 0
    for j in 1 .. i:
      if spans[j][0] > spans[best][0]: best = j
    let (a, b) = spans[best]
    spans.delete(best)
    result = result[0 ..< a] & result[b .. ^1]

proc tree(text: string): (bool, NimNode) =
  try: (true, parseStmt(text))
  except ValueError: (false, newEmptyNode())

macro prove(name: static string, groups: static seq[array[4, int]]): untyped =
  let text = staticRead(name)
  let (readable, given) = tree(text)
  var proven: seq[array[4, int]]
  if readable:
    for g in groups:
      let (ok, variant) = tree(text.removed(@[g]))
      if ok and same(given, variant): proven.add g
  var chosen = proven
  if proven.len > 1:
    let (ok, variant) = tree(text.removed(proven))
    if not (ok and same(given, variant)):
      chosen.setLen(0)
      for g in proven:
        let (fits, joined) = tree(text.removed(chosen & @[g]))
        if fits and same(given, joined): chosen.add g
  var line = "knoller-proof " & name & ":"
  for g in chosen: line.add " " & $g[0]
  echo line
"""
    ## Library of probe program: tree of source, tree without groups, and comparison.
  ITERATIONS_VM = 1_000_000_000  ## Loop iterations probe may take in compiler's VM.


func probeOf*(sources: openArray[string]): string =
  ## Write probe program asking parser about each source, read from file `s<k>.nim` beside it,
  ##   with candidate groups of each (`candidatesOf`) as byte spans.
  result = PROBE
  for k, source in sources:
    let groups = source.candidatesOf.mapIt(
      "[" & $it.opening[0] & ", " & $it.opening[1] & ", " & $it.closing[0] & ", " &
        $it.closing[1] & "]",
    )
    result.add "prove(\"s" & $k & ".nim\", @[" & groups.join(", ") & "])\n"


func provingOf*(output: string, count: int): Proving =
  ## Read answers of probe from output of compiler for `count` sources; source probe answered
  ##   none for proves none. Output holding no answer at all is failure, with its first line.
  result.answers = newSeq[seq[int]](count)
  var found = 0
  for line in output.splitLines:
    if not line.startsWith(MARK): continue
    let
      parts = line[MARK.len .. ^1].split(':')
      name = parts[0]
    if parts.len != 2 or not name.startsWith("s") or not name.endsWith(".nim"): continue
    let k = try: parseInt(name[1 ..< ^4]) except ValueError: -1
    if k < 0 or k >= count: continue
    inc found
    for offset in parts[1].splitWhitespace: result.answers[k].add parseInt(offset)
  if found == 0 and count > 0:
    let first = output.splitLines.filterIt(it.strip.len > 0)
    result.failure = "Parser proved no removal, since compiler ran no probe; got `" &
      (if first.len > 0: first[0].strip else: "no output") & "`."


proc compilerProver*(nim: string): Prover =
  ## Build prover running compiler `nim` on probe in private temporary directory, removed after.
  result = proc (sources: seq[string]): Proving =
    if sources.len == 0: return Proving()
    let directory = createTempDir("knoller_proof_", "")
    defer: removeDir(directory)
    for k, source in sources: writeFile(directory / "s" & $k & ".nim", source)
    writeFile(directory / "probe.nim", probeOf(sources))
    let command = nim.quoteShell & " check --hints:off --warnings:off --maxLoopIterationsVM:" &
      $ITERATIONS_VM & " --nimcache:" & quoteShell(directory / "cache") & " " &
      quoteShell(directory / "probe.nim")
    let output =
      try: execCmdEx(command, options = {poStdErrToStdOut, poEvalCommand}).output
      except OSError as e: e.msg
    provingOf(output, sources.len)


func failureProver*(failure: string): Prover =
  ## Build prover answering none for each source, with failure, as compiler that cannot run.
  result = proc (sources: seq[string]): Proving =
    Proving(answers: newSeq[seq[int]](sources.len), failure: failure)


proc pinProvers*(toolchains: Toolchains): ProverOf =
  ## Build prover of each pin: parser of compiler `toolchains` serve it, resolved where first
  ##   source asks, once for each pin; pin nothing serves proves nothing, with reason naming it.
  var held = toolchains
  result = proc (pin: string): Prover =
    result = proc (sources: seq[string]): Proving =
      let bin = held.binFor(pin)
      if bin.isNone:
        let failure = "Parser proved no removal, since no compiler serves pin; got `" & pin & "`."
        return failureProver(failure)(sources)
      compilerProver(if bin.get.len == 0: NIM else: bin.get / NIM)(sources)


proc answered*(proofs: var Proofs; asked: openArray[string]; prover: Prover): string =
  ## Ask prover each source of `asked` no answer holds yet, and hold its answers; return why no
  ##   compiler answered, empty where one did. Source of failed run is held answered with none,
  ##   so its groups stay and no run asks it again.
  let open = asked.filterIt(it notin proofs.answers).deduplicate
  if open.len == 0: return
  let proving = prover(open)
  for k, source in open: proofs.answers[source] = proving.answers[k]
  proving.failure
