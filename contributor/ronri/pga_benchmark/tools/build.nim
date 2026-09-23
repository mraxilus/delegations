## Drive measurement of this project: `nim r tools/build.nim <command>`.
##   Koch runs suites and holds no verb for instruments, so project carries its own driver
##   (CONTRIBUTOR.md, "Directories inside your project are yours"), one level down from koch.
##
##   |----------|-----------------------------------------------------------------------|
##   | Command  | Effect                                                                |
##   |----------|-----------------------------------------------------------------------|
##   | inspect  | compile bench entry per algebra to C, read it, write static           |
##   |          | measurements as `build/static_<algebra>.json`                         |
##   | bench    | compile and run bench per algebra, plain then instrumented, record    |
##   |          | runtime measurements as `baseline/runtime_<algebra>.json`             |
##   | baseline | inspect, then record static measurements as                           |
##   |          | `baseline/static_<algebra>.json`                                      |
##   | guard    | compare last inspect against baseline; any count grown is finding     |
##   | drive    | inspect, guard, and hold committed `gaps.md` to regeneration          |
##   | gaps     | regenerate `gaps.md` and docket from committed baselines              |
##   | show     | print one function's emitted C, its counts, its movement and its      |
##   |          | machine code, e.g. `show ∧` or `show ⟇ cga5d`                         |
##   | sweep    | time general measurands at two to six dimensions, rigid; never in CI  |
##   | system   | print system packages build needs, one per line, for caller          |
##   | clean    | remove `build`                                                        |
##   |----------|-----------------------------------------------------------------------|
##   Exit: 0 done, 1 command failed or finding, 2 usage error.
##   Runs from project directory, on compiler nimble file pins, since every path is
##     relative and every build compiles library. `drive` is deterministic: static counts
##     only, no timing, so runner's verdict is same as local one.
##   Cost: `drive` compiles bench and inspect entries once per algebra, seconds each.
##   Cost: `bench` measurements name machine they were taken on; committing them records that
##     run and nothing more, as `PROVENANCE.md` says of every pair.

{.experimental: "strictFuncs".}

import std/[json, os, osproc, strutils]

import ../src/pga_benchmark/[gaps, guard, inspector, model]


const
  BUILD = "build"
    ## Directory caches, binaries and fresh documents land in; root `.gitignore` covers it.
  BASELINE = "baseline"
    ## Directory committed documents live in.
  PATH_GAPS = "gaps.md"
    ## Rendered list, committed.
  PATH_DOCKET = BASELINE / "docket.json"
    ## Identifier docket, committed.
  PATH_LOCK = "atlas.lock"
    ## Lock naming library commit.
  ENTRY_BENCH = "src/pga_benchmark/bench.nim"
    ## Entry reaching every measurand; its cache is what inspect reads.
  ENTRY_INSPECT = "src/pga_benchmark/inspect.nim"
    ## Entry reading cache, compiled per algebra for its catalogue.
  FLAGS = "-d:release"
    ## Build flags every measured build carries; documents name them.
  CONFIGS = [("rga4d", 4, false), ("cga5d", 5, true), ("rga3d", 3, false), ("cga4d", 4, true)]
    ## Algebras driven, typed ones first: name, dimensions, conformal.
  SWEEP = 2 .. 6
    ## Dimensions swept, rigid metric, general measurands only.
  SYSTEM: seq[(string, string)] = @[]
    ## System packages build needs beyond compiler: none. Compiler is toolchain, pinned in
    ## nimble file; library is Atlas checkout, pinned in lock; nothing else is fetched.
  USAGE = "Usage: nim r tools/build.nim " &
    "<inspect|bench|baseline|guard|drive|gaps|show|sweep|system|clean>" &
    " [symbol] [algebra]\n"
    ## Text printed on usage error; trailing words serve `show` alone.
  SHOWN_LINES = 40
    ## Lines of one function this driver prints before naming file rest sits in.
  SHOWN_WIDTH = 150
    ## Characters of one line this driver prints before cutting it.



#[ Processes ]#

proc run(command: string; args: openArray[string]) =
  ## Run command with args from project directory; raise on non-zero exit.
  let process = startProcess(command, args = args, options = {poUsePath, poParentStreams})
  let code = process.waitForExit
  process.close
  if code != 0:
    raise newException(OSError, command & " failed; got exit `" & $code & "`.")


proc nimCommit(): string =
  ## Read commit of compiler on PATH from its version text; `unmeasured` where absent.
  for line in execProcess("nim", args = ["-v"], options = {poUsePath}).splitLines:
    if line.startsWith("git hash: "): return line["git hash: ".len .. ^1].strip
  "unmeasured"


proc pgaCommit(): string =
  ## Read library commit from lock; `unmeasured` where lock names none.
  let items = parseJson(readFile(PATH_LOCK)){"items"}
  if items.isNil: return "unmeasured"
  for _, item in items.pairs: return item{"commit"}.getStr("unmeasured")
  "unmeasured"


func defines(dimensions: int; is_conformal: bool; nim, pga: string): seq[string] =
  ## Spell defines selecting algebra and naming build for its documents.
  @[
    "-d:pga.dimensions=" & $dimensions,
    "-d:pga.is_conformal=" & $is_conformal,
    "-d:pga_benchmark.nim_commit=" & nim,
    "-d:pga_benchmark.pga_commit=" & pga,
    "-d:pga_benchmark.flags=" & FLAGS,
  ]


proc compile(
  entry, binary, cache: string; dimensions: int; is_conformal: bool; nim, pga: string;
  extra: openArray[string] = [],
) =
  ## Compile entry for algebra into binary with its own cache.
  run(
    "nim",
    @["c", "--hints:off", FLAGS, "--nimcache:" & cache, "-o:" & binary] &
      defines(dimensions, is_conformal, nim, pga) & @extra & @[entry],
  )


proc readDocument(path: string): JsonNode =
  ## Read JSON document at path.
  parseJson(readFile(path))



#[ Commands ]#

proc inspect() =
  ## Compile bench entry per algebra to C only, then read its cache into document.
  let nim = nimCommit()
  let pga = pgaCommit()
  createDir BUILD
  for (name, dimensions, is_conformal) in CONFIGS:
    let cache = BUILD / "cache_" & name
    removeDir cache
    compile(
      ENTRY_BENCH, BUILD / "bench_" & name, cache, dimensions, is_conformal, nim, pga,
      ["--compileOnly"],
    )
    let inspector = BUILD / "inspect_" & name
    compile(
      ENTRY_INSPECT, inspector, BUILD / "cache_inspect_" & name, dimensions, is_conformal,
      nim, pga,
    )
    run(inspector, [cache, BUILD / "static_" & name & ".json", nim, pga, FLAGS])


proc merged(plain, instrumented: JsonNode): JsonNode =
  ## Take timings from plain run and allocation counts from instrumented one.
  result = plain
  result["taken"]["is_allocation_measured"] = instrumented{"taken", "is_allocation_measured"}
  for id, measurand in instrumented{"measurands"}.pairs:
    for implementation in ["library", "reference"]:
      let measurement = measurand{implementation}
      if measurement.isNil or measurement.kind != JObject: continue
      if not result["measurands"].hasKey(id): continue
      let target = result["measurands"][id]{implementation}
      if target.isNil or target.kind != JObject: continue
      target["allocations"] = measurement{"allocations"}


proc bench() =
  ## Compile and run bench per algebra, plain for timings and instrumented for allocations,
  ## and record merged measurements into `baseline/`.
  let nim = nimCommit()
  let pga = pgaCommit()
  createDir BUILD
  createDir BASELINE
  for (name, dimensions, is_conformal) in CONFIGS:
    let plain = BUILD / "bench_" & name
    compile(ENTRY_BENCH, plain, BUILD / "cache_" & name, dimensions, is_conformal, nim, pga)
    run(plain, [plain & ".json"])
    let instrumented = BUILD / "bench_alloc_" & name
    compile(
      ENTRY_BENCH, instrumented, BUILD / "cache_alloc_" & name, dimensions, is_conformal, nim,
      pga, ["-d:nimAllocStats"],
    )
    run(instrumented, [instrumented & ".json"])
    let doc = merged(readDocument(plain & ".json"), readDocument(instrumented & ".json"))
    let recorded = BASELINE / "runtime_" & name & ".json"
    writeFile(recorded, pretty(doc) & "\n")
    echo "Recorded ", recorded


proc baseline() =
  ## Inspect, then record every algebra's counts as its baseline.
  inspect()
  createDir BASELINE
  for (name, _, _) in CONFIGS:
    copyFile(BUILD / "static_" & name & ".json", BASELINE / "static_" & name & ".json")
    echo "Recorded ", BASELINE / "static_" & name & ".json"


proc guarded(): seq[Finding] =
  ## Compare last inspect of every algebra against its baseline; print improvements.
  for (name, _, _) in CONFIGS:
    let path = BASELINE / "static_" & name & ".json"
    let fresh = BUILD / "static_" & name & ".json"
    if not fileExists(path):
      result.add Finding(path: path, message: "No baseline recorded; run `baseline`.")
      continue
    if not fileExists(fresh):
      result.add Finding(path: path, message: "No inspect output to compare; run `inspect`.")
      continue
    let verdict = compare(readDocument(path), readDocument(fresh), path)
    for line in verdict.improvements: echo "notice: ", line
    result.add verdict.findings


proc report(findings: seq[Finding]) =
  ## Print findings and count, and fail where any.
  for f in findings: echo f.render
  echo $findings.len & " finding(s)."
  if findings.len > 0: quit 1


proc guard() =
  ## Compare and report.
  report(guarded())


proc algebras(): seq[Algebra] =
  ## Read every algebra's committed documents, in driven order; bench nil where absent.
  for (name, _, _) in CONFIGS:
    let path = BASELINE / "static_" & name & ".json"
    if not fileExists(path): continue
    var a = Algebra(name: name, static_measurements: readDocument(path))
    let bench_path = BASELINE / "runtime_" & name & ".json"
    if fileExists(bench_path): a.runtime_measurements = readDocument(bench_path)
    result.add a


proc generated(): (string, string) =
  ## Generate list and docket text from committed documents.
  let docket =
    if fileExists(PATH_DOCKET): docketOf(readDocument(PATH_DOCKET)) else: docketOf(nil)
  let (text, grown) = generate(algebras(), docket)
  (text, pretty(grown.toJson) & "\n")


proc gaps() =
  ## Regenerate list and docket.
  let (text, docket) = generated()
  createDir BASELINE
  writeFile(PATH_GAPS, text)
  writeFile(PATH_DOCKET, docket)
  echo "Wrote ", PATH_GAPS, " and ", PATH_DOCKET


proc drive() =
  ## Inspect, check against baselines, and hold committed list and docket to regeneration.
  inspect()
  var findings = guarded()
  let (text, docket) = generated()
  if not fileExists(PATH_GAPS) or readFile(PATH_GAPS) != text:
    findings.add Finding(path: PATH_GAPS, message: "List differs from regeneration; run `gaps`.")
  if not fileExists(PATH_DOCKET) or readFile(PATH_DOCKET) != docket:
    findings.add Finding(
      path: PATH_DOCKET, message: "Docket differs from regeneration; run `gaps`."
    )
  report(findings)


proc sweep() =
  ## Time general measurands at every swept dimension, rigid metric, and print medians.
  let nim = nimCommit()
  let pga = pgaCommit()
  createDir BUILD
  var docs: seq[JsonNode]
  for dimensions in SWEEP:
    let name = "sweep_" & $dimensions & "d"
    let binary = BUILD / name
    compile(ENTRY_BENCH, binary, BUILD / "cache_" & name, dimensions, false, nim, pga)
    run(binary, [binary & ".json"])
    docs.add readDocument(binary & ".json")
  var header = "measurand".alignLeft(26)
  for dimensions in SWEEP: header.add ($dimensions & "d").align(10)
  echo header
  for id, _ in docs[0]{"measurands"}.pairs:
    var line = id.alignLeft(26)
    for doc in docs:
      let measurement = doc{"measurands", id, "library"}
      line.add(
        if measurement.isNil or measurement.kind != JObject: "–".align(10)
        else: formatFloat(measurement{"ns_median"}.getFloat, ffDecimal, 1).align(10)
      )
    echo line


func shortened(text, stem, plain: string): string =
  ## Replace mangled type name and its hash with plain one, wherever stem appears.
  var i = 0
  while true:
    let at = text.find(stem & "__", i)
    if at < 0:
      result.add text[i .. ^1]
      break
    result.add text[i ..< at]
    result.add plain
    var j = at + stem.len + 2
    while j < text.len and (text[j].isAlphaNumeric or text[j] == '_'): inc j
    i = j


func unindexed(text: string): string =
  ## Replace `(((Basis) n) - 0)` with `n`, which is what compiler spells there.
  const OPEN = "(((Basis) "
  const CLOSE = ") - 0)"
  var i = 0
  while true:
    let at = text.find(OPEN, i)
    if at < 0:
      result.add text[i .. ^1]
      break
    let close = text.find(CLOSE, at)
    if close < 0:
      result.add text[i .. ^1]
      break
    result.add text[i ..< at]
    result.add text[at + OPEN.len ..< close]
    i = close + CLOSE.len


func readable(text: string): string =
  ## Rewrite emitted C so reader sees types and slots rather than hashes.
  ##   Reading aid alone: cache holds exact text every count is read from.
  text.shortened(MULTIVECTOR, "Multivector").shortened("tyEnum_Basis", "Basis").unindexed


proc disassembled(cache, name: string): seq[string] =
  ## Read machine code of one function from whichever object file in cache holds it.
  for path in walkFiles(cache / "*.o"):
    let (text, code) = execCmdEx("objdump -d --no-show-raw-insn " & quoteShell(path))
    if code != 0: continue
    var inside = false
    for line in text.splitLines:
      if line.contains("<" & name & ">:"): inside = true
      if not inside: continue
      result.add line
      if line.contains("\tret"): return
    if result.len > 0: return


proc showFunction(symbol, algebra: string) =
  ## Print one emitted function: what it is, what it spends, what it moves, what it becomes.
  ##   Compiles bench entry whole rather than to C alone, so cache holds object file and
  ##   machine code can be read beside C. Reads that cache with same inspector every
  ##   measurement uses, so figures here and figures in `gaps.md` come from one reading.
  var found = false
  for (name, dimensions, is_conformal) in CONFIGS:
    if name != algebra: continue
    found = true
    let nim = nimCommit()
    let pga = pgaCommit()
    createDir BUILD
    let cache = BUILD / "cache_show_" & name
    compile(ENTRY_BENCH, BUILD / "show_" & name, cache, dimensions, is_conformal, nim, pga)
    let size = 8 shl dimensions
    var seen = 0
    for f in inspectCache(cache):
      if f.symbol != symbol: continue
      inc seen
      let c = f.body.count
      let m = movement(f, c, size)
      echo ""
      echo "── ", f.symbol, "(", f.params.join(","), ") → ", f.result_stem,
        "   ", algebra, ", ", size, "-byte multivector"
      echo "   emitted as ", (if f.is_inline: "static N_INLINE" else: "N_NIMCALL"),
        " `", f.name, "`"
      echo ""
      echo "   counts, callees folded in"
      echo "     multiplies    ", c.multiplies
      echo "     divides       ", c.divides
      echo "     zero fills    ", c.zero_fills, "   × ", size, " bytes"
      echo "     intermediates ", c.intermediates, "   × ", size, " bytes"
      echo "     copies        ", c.copies, "   × ", size, " bytes"
      echo "     error checks  ", c.checks
      echo "     lines of C    ", c.lines
      echo ""
      echo "   bytes moved = operands read + result written"
      echo "               + (zero fills + intermediates + copies) × width"
      echo "     operands read     ", m.bytes_read
      echo "     result written    ", m.bytes_written
      echo "     zero fills        ", m.bytes_zeroed
      echo "     intermediates     ", m.bytes_intermediates
      echo "     copies            ", m.bytes_copied
      echo "     ───────────────── ", m.bytes_moved
      echo ""
      echo "   emitted C"
      var printed = 0
      for line in f.body.readable.splitLines:
        if printed >= SHOWN_LINES:
          echo "     … ", c.lines - printed, " more lines; whole body is in ", cache
          break
        echo "     ", (if line.len > SHOWN_WIDTH: line[0 ..< SHOWN_WIDTH] & " …" else: line)
        inc printed
      echo ""
      echo "   machine code"
      let lines = disassembled(cache, f.name)
      if lines.len == 0:
        echo "     no symbol of its own, since it is inline; read its caller instead."
        continue
      for i, line in lines:
        if i >= SHOWN_LINES:
          echo "     … ", lines.len - i, " more instructions."
          break
        echo "     ", line
    if seen == 0:
      echo "No function spells `", symbol, "` in ", algebra, "."
  if not found:
    raise newException(ValueError, "No algebra named `" & algebra & "`.")


proc system() =
  ## Print every system package this build needs, one per line and nothing else.
  for (package, _) in SYSTEM: echo package


proc clean() =
  ## Remove every product, leaving only what git holds.
  removeDir BUILD
  echo "Removed ", BUILD



#[ Entry Point ]#

when isMainModule:
  if paramCount() notin 1 .. 3 or (paramStr(1) == "show" and paramCount() < 2):
    stderr.write USAGE
    quit 2
  if paramStr(1) != "show" and paramCount() != 1:
    stderr.write USAGE
    quit 2
  try:
    case paramStr(1)
    of "show":
      showFunction(paramStr(2), if paramCount() >= 3: paramStr(3) else: CONFIGS[0][0])
    of "inspect": inspect()
    of "bench": bench()
    of "baseline": baseline()
    of "guard": guard()
    of "drive": drive()
    of "gaps": gaps()
    of "sweep": sweep()
    of "system": system()
    of "clean": clean()
    else:
      stderr.write USAGE
      quit 2
  except CatchableError as e:
    stderr.write e.msg & "\n"
    quit 1
