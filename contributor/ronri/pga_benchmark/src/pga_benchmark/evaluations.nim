## Try proposed change on copy of library at pin: its suites, counts, timings and claims.
##   Evaluation is how change or proposal earns figures page shows. It copies library checkout,
##     applies edits (base proposal first where proposal builds on one), then measures copy
##     against pin:
##     - library's own suites, at rga4d and cga5d or all four when thorough, pristine counts
##       beside;
##     - static measurements of every function change touches, pin's baseline as before;
##     - runtime of every measurand, pristine and changed binaries run alternately, so drift
##       of machine lands on both alike, and ratio per measurand is median over runs;
##     - proposal claims: suites pass, tables equal pristine ones, programs run, counts hold,
##       and build of library alone costs no more than stated share of pristine build.
##   Result is one document in `evaluations/`, taken at pin and naming digest of edits it tried,
##     so `drive` refuses evaluation of another commit or of edits since changed (`head.nim`).
##   Each algebra names digest of C its two timed builds emitted. Restamped evaluation takes
##     every figure again but times, which it keeps where both builds emit same C (`head.nim`).
##   Working copy keeps checkout's directory name, since function keys and module tails are
##     read from path and must match baseline's.
##
##   Cost: every evaluation compiles library four times per algebra (suites, counts, two timed
##     binaries); pristine binaries are built once per run of driver and shared.
##   Cost: timings are machine's, as every runtime measurement is; evaluation names machine.
##   Cost: stages of evaluation (`prepareCopy`, `staticOf`, `checkClaims`, `tablesOf`, `buildCost`)
##     each serve one caller, yet stay at module scope; nested, `runEvaluation` and `checkClaims`
##     would run past two hundred lines, which X.4 asks to split.

{.experimental: "strictFuncs".}

import std/[algorithm, json, math, os, osproc, sequtils, strutils, tables]

import ./[changes, guard, head, report]
from ./proposals import definesOf


type
  Algebra* = object  ## Define algebra evaluation measures: name, dimensions, metric.
    name*: string  ## Short name, as `rga4d`.
    dimensions*: int  ## Vector space dimensions.
    is_conformal*: bool  ## Metric: conformal where true, rigid else.
  Toolchain* = object  ## Define where evaluation reads and writes, and what build it names.
    library*: string  ## Library checkout at pin.
    work*: string  ## Directory evaluations build under.
    nim*: string  ## Compiler commit.
    pga*: string  ## Library commit: pin.
    flags*: string  ## Build flags every measured build carries.
    runs*: int  ## Timed runs of each binary, alternating.
  Candidate* = object  ## Define what one evaluation tries: edits in order, programs and claims.
    name*: string  ## Evaluation name, file name of its document.
    path*: string  ## Change file or proposal directory findings name.
    changes*: seq[Change]  ## Changes applied in order, base proposal first.
    programs*: seq[string]
      ## Text of programs proposal's claims run, so digest moves when program does.
    claims*: JsonNode  ## Claims proposal makes; empty array for change.


const
  ENTRY_BENCH = "src/pga_benchmark/bench.nim"  ## Entry reaching every measurand.
  ENTRY_LIBRARY* = "import pga\n"
    ## Text of entry build claim compiles: library alone, so no module of harness sets peak.
  ENTRY_INSPECT = "src/pga_benchmark/inspect.nim"  ## Entry reading cache into static measurements.
  METRICS_COUNTED = [
    "multiplies",
    "adds",
    "subtractions",
    "divides",
    "fills_zero",
    "intermediates",
    "copies",
    "checks",
    "calls",
    "lines",
  ]
    ## Totals evaluation reports where they differ from pin.
  METRICS_MOVED = ["bytes_moved", "bytes_zeroed", "bytes_intermediates"]
    ## Movement evaluation reports where it differs from pin.
  PATH_STUB = "tests" / "$1" / "test_$1.nim"
    ## Library's own stub per algebra, relative to checkout.
  ALGEBRAS_EVALUATED* = ["rga4d", "cga5d"]
    ## Algebras every evaluation measures: 3D Euclidean ones; each more costs builds and runs.
  ALGEBRAS_THOROUGH* = ["rga3d", "cga4d"]  ## Algebras thorough evaluation adds: 2D Euclidean ones.


func algebrasEvaluated*(is_thorough: bool): seq[string] =
  ## Name algebras one evaluation measures: typed ones, and untyped ones too when thorough.
  result = @ALGEBRAS_EVALUATED
  if is_thorough: result.add ALGEBRAS_THOROUGH



#[ Edits Digest ]#

func digestEdits*(changes: openArray[Change], claims: JsonNode, programs: seq[string]): string =
  ## Digest what evaluation tries: every edit, claims and program text; prose is left out.
  var text = $claims
  for change in changes:
    for edit in change.edits:
      text.add edit.path & "\0" & edit.quote & "\0" & edit.replacement & "\0" & edit.digest
  for program in programs: text.add "\0" & program
  digestOf(text)



#[ Library Copies ]#

proc readLibrary*(directory: string): Table[string, string] =
  ## Read every Nim file under library directory, keyed by relative path with `/`.
  ##   Checkout holding no Nim file raises, so no page quotes library it could not read.
  for path in walkDirRec(directory, relative = true):
    if path.endsWith(".nim"): result[path.replace('\\', '/')] = readFile(directory / path)
  if result.len == 0:
    raise newException(
      IOError,
      "Library checkout holds no Nim file; restore it with `nim r koch fetch-deps`; got `" &
      directory & "`.",
    )


proc digestCache*(cache, pin: string): string =
  ## Digest C build left in cache, pin's commit left out (`head.nim`).
  var sources: seq[(string, string)]
  for path in walkFiles(cache / "*.c"): sources.add (path.extractFilename, readFile(path))
  if sources.len == 0: raise newException(IOError, "Cache holds no C; got `" & cache & "`.")
  digestSources(sources, pin)


proc prepareCopy(chain: Toolchain, candidate: Candidate): (string, seq[Finding]) =
  ## Copy library, apply candidate's changes, write copy; path of copy and findings.
  let copy = chain.work / candidate.name / chain.library.lastPathPart
  removeDir copy
  copyDir(chain.library, copy)
  var
    files = readLibrary(chain.library)
    findings: seq[Finding]
  for change in candidate.changes:
    findings.add applyChange(files, change, candidate.path)
  for path, text in files.pairs:
    writeFile(copy / path, text)
  (copy, findings)



#[ Builds ]#

proc runCompiler(arguments: openArray[string]): (string, int) =
  ## Run compiler with arguments, capturing output; output and exit code.
  let command = "nim " & arguments.mapIt(quoteShell(it)).join(" ")
  execCmdEx(command)


func definesAlgebra(algebra: Algebra): seq[string] =
  ## Spell defines selecting algebra.
  @["-d:pga.dimensions=" & $algebra.dimensions, "-d:pga.is_conformal=" & $algebra.is_conformal]


func definesBuild(chain: Toolchain, pga: string): seq[string] =
  ## Spell defines naming build in documents it writes, and leaving dense forms out.
  ##   Dense forms read tables by name at pin, and change may rename them.
  @[
    "-d:pga_benchmark.commit_nim=" & chain.nim,
    "-d:pga_benchmark.commit_pga=" & pga,
    "-d:pga_benchmark.flags=" & chain.flags,
    "-d:pga_benchmark.has_forms_dense=false",
  ]


proc compileAgainst(
  chain: Toolchain; library, entry, binary, cache: string; algebra: Algebra; should_stop_at_c: bool
): (string, int) =
  ## Compile project entry against library copy, skipping project `nim.cfg` that names pin's.
  var arguments = @["c", "--hints:off", "--warnings:off", chain.flags, "--skipParentCfg:on",
    "--noNimblePath", "--path:" & library, "--nimcache:" & cache, "-o:" & binary]
  arguments.add definesAlgebra(algebra) & definesBuild(chain, chain.pga)
  if should_stop_at_c: arguments.add "--compileOnly"
  arguments.add entry
  runCompiler(arguments)


proc suites(
  library, cache: string; algebra: Algebra; defines: openArray[string] = []
): JsonNode =
  ## Compile and run library's own suites on copy, with defines claim adds; count passed and
  ##   failed tests.
  let stub = library / PATH_STUB % algebra.name
  if not fileExists(stub): return %*{"ok": 0, "failed": 0, "built": false}
  var arguments = @["c", "--hints:off", "--warnings:off", "--skipParentCfg:on", "--noNimblePath",
    "-d:testing", "-d:nimUnittestAbortOnError:off", "--nimcache:" & cache,
    "-o:" & cache / "suites", "-r"]
  arguments.add definesAlgebra(algebra)
  arguments.add defines
  arguments.add stub
  let (output, code) = runCompiler(arguments)
  %*{
    "ok": output.count("[OK]"),
    "failed": output.count("[FAILED]"),
    "built": code == 0 or output.contains("[OK]"),
  }


proc staticOf(chain: Toolchain; library, directory: string; algebra: Algebra): (JsonNode, string) =
  ## Inspect emitted C of bench entry built against library; document and failure text.
  let
    cache = directory / "cache_bench_" & algebra.name
    inspector = directory / "inspect_" & algebra.name
    output = directory / "static_" & algebra.name & ".json"
  removeDir cache
  var (log, code) = compileAgainst(
    chain,
    library,
    ENTRY_BENCH,
    directory / "bench_c_" & algebra.name,
    cache,
    algebra,
    should_stop_at_c = true,
  )
  if code != 0: return (nil, log)
  (log, code) = compileAgainst(
    chain,
    library,
    ENTRY_INSPECT,
    inspector,
    directory / "cache_inspect_" & algebra.name,
    algebra,
    should_stop_at_c = false,
  )
  if code != 0: return (nil, log)
  (log, code) = execCmdEx(
    quoteShell(inspector) & " " & quoteShell(cache) & " " &
    quoteShell(output) & " " & quoteShell(chain.nim) & " " & quoteShell(chain.pga) & " " &
    quoteShell(chain.flags),
  )
  if code != 0: return (nil, log)
  (parseJson(readFile(output)), "")



#[ Comparisons ]#

func functionsChanged*(before, after: JsonNode): JsonNode =
  ## Compare static documents function by function; keep those whose counts differ.
  ##   Function on one side only is JSON null on other, never nil, so document prints.
  ##   Dense form changed build leaves out is no move: changed build omits dense forms, since
  ##     change may rename tables they read, and pristine counts hold them.

  func countsOf(function: JsonNode): JsonNode =
    ## Build totals and movement evaluation reports for one function.
    ##   Count document lacks is JSON null, never nil.
    result = newJObject()
    for key in METRICS_COUNTED:
      let node = function{"total", key}
      result[key] = if node.isNil: newJNull() else: node
    for key in METRICS_MOVED:
      let node = function{"movement", key}
      result[key] = if node.isNil: newJNull() else: node

  result = newJObject()
  let
    was = before{"functions"}
    now = after{"functions"}
  if was.isNil or now.isNil: return
  var forms_dense: seq[string]
  if not before{"measurands"}.isNil:
    for _, measurand in before{"measurands"}.pairs:
      let name = measurand{"dense"}.getStr
      if name.len > 0: forms_dense.add name
  var keys = was.keys.toSeq
  for key in now.keys:
    if key notin keys: keys.add key
  keys.sort
  for key in keys:
    if key in forms_dense and not now.hasKey(key): continue
    let
      counts_before = if was.hasKey(key): countsOf(was[key]) else: newJNull()
      counts_after = if now.hasKey(key): countsOf(now[key]) else: newJNull()
    if counts_before != counts_after:
      result[key] = %*{"before": counts_before, "after": counts_after}


func timesOf*(pristine, candidate: seq[JsonNode]): JsonNode =
  ## Pair runs of both binaries by measurand; median ns of each and median of per-run ratios.
  result = newJObject()
  if pristine.len == 0 or candidate.len == 0: return
  for id, _ in pristine[0]{"measurands"}.pairs:
    var ns_before, ns_after, ratios: seq[float]
    for i in 0..<min(pristine.len, candidate.len):
      let
        ns_pristine = pristine[i]{"measurands", id, "library", "ns_median"}
        ns_changed = candidate[i]{"measurands", id, "library", "ns_median"}
      if ns_pristine.isNil or ns_changed.isNil: continue
      if ns_pristine.kind != JFloat or ns_changed.kind != JFloat: continue
      ns_before.add ns_pristine.getFloat
      ns_after.add ns_changed.getFloat
      if ns_pristine.getFloat > 0: ratios.add ns_changed.getFloat / ns_pristine.getFloat
    if ratios.len == 0: continue
    result[id] = %*[ns_before.median.round(2), ns_after.median.round(2), ratios.median.round(4)]


func nanOf*(pristine, candidate: seq[JsonNode]): JsonNode =
  ## Compare share of NaN results per measurand, first run of each side; keep those that differ.
  ##   Share is property of samples and code, never of machine, so one run of each suffices.
  result = newJObject()
  if pristine.len == 0 or candidate.len == 0: return
  for id, _ in pristine[0]{"measurands"}.pairs:
    let
      share_pristine = pristine[0]{"measurands", id, "library", "share_nan"}
      share_changed = candidate[0]{"measurands", id, "library", "share_nan"}
    if share_pristine.isNil or share_changed.isNil: continue
    if share_pristine.kind != JFloat or share_changed.kind != JFloat: continue
    if share_pristine.getFloat != share_changed.getFloat:
      result[id] = %*[share_pristine.getFloat, share_changed.getFloat]


func successOf*(output: string): (float, float) =
  ## Read seconds and peak memory in MiB from compiler's success line; zeros where absent.
  for line in output.splitLines:
    if not line.contains("[SuccessX]"): continue
    var seconds, peak: float
    for part in line.split("; "):
      if part.endsWith("MiB peakmem"):
        peak = parseFloat(part[0..<part.len-"MiB peakmem".len])
      elif part.endsWith("s") and part.len > 1 and part[0].isDigit:
        try: seconds = parseFloat(part[0 ..< ^1])
        except ValueError: discard
    return (seconds, peak)


proc timed(chain: Toolchain; pristine, candidate, directory: string): (JsonNode, JsonNode) =
  ## Run both binaries alternately `runs` times each; times and NaN shares per measurand.

  proc runTimed(binary, output: string): JsonNode =
    ## Run one timed binary into output; its document, nil where run failed.
    let (_, code) = execCmdEx(quoteShell(binary) & " " & quoteShell(output))
    if code == 0: parseJson(readFile(output)) else: nil

  var before, after: seq[JsonNode]
  for run in 1..chain.runs:
    let
      run_pristine = runTimed(pristine, directory / "pristine_" & $run & ".json")
      run_changed = runTimed(candidate, directory / "changed_" & $run & ".json")
    if run_pristine.isNil or run_changed.isNil: continue
    before.add run_pristine
    after.add run_changed
  (timesOf(before, after), nanOf(before, after))



#[ Claims ]#

const TABLES_PROGRAM = """
import std/json
import pga/[algebra {.all.}, cayleys {.all.}, multivectors]
import pga_benchmark/cells

var tables = newJArray()
$1
echo tables
"""
  ## Program printing tables as JSON, one `tables.add cells(<expression>)` line per table.
  ##   Serialiser is `cells.nim`, which suites run against pin, so it reads both cell types
  ##   and program itself holds nothing to test.


proc tablesOf(
  library, directory, side: string; expressions: seq[string]; algebra: Algebra
): (JsonNode, string) =
  ## Compile and run table program against library; tables in order and failure text.
  let
    source = directory / "tables_" & side & "_" & algebra.name & ".nim"
    lines = expressions.mapIt("tables.add cells(" & it & ")").join("\n")
  writeFile(source, TABLES_PROGRAM.replace("$1", lines))
  var arguments = @["c", "--hints:off", "--warnings:off", "--skipParentCfg:on", "--noNimblePath",
    "-d:release", "--path:" & library, "--path:" & getCurrentDir() / "src",
    "--nimcache:" & directory / "cache_" & side & "_" & algebra.name,
    "-o:" & directory / "tables_" & side & "_" & algebra.name, "-r"]
  arguments.add definesAlgebra(algebra)
  arguments.add source
  let (output, code) = runCompiler(arguments)
  if code != 0: return (nil, output)
  let last = output.strip.splitLines[^1]
  (parseJson(last), "")


proc buildCost(
  chain: Toolchain; library, directory, side: string; algebra: Algebra
): (float, float, string) =
  ## Compile library alone to C from empty cache; seconds and peak MiB compiler reports.
  ##   Bench entry put harness in measured build: one change to its inspector moved peak of
  ##     changed side by fifty MiB, and pristine side by none, whose derivation peaks higher.
  let
    cache = directory / "cache_build_" & side & "_" & algebra.name
    entry = directory / "build_" & side & ".nim"
  removeDir cache
  writeFile(entry, ENTRY_LIBRARY)
  var arguments = @["c", "--hints:on", "--warnings:off", chain.flags, "--skipParentCfg:on",
    "--noNimblePath", "--path:" & library, "--nimcache:" & cache, "--compileOnly",
    "-o:" & directory / "build_" & side & "_" & algebra.name]
  arguments.add definesAlgebra(algebra) & definesBuild(chain, chain.pga)
  arguments.add entry
  let (output, code) = runCompiler(arguments)
  if code != 0: return (0.0, 0.0, output.strip.splitLines[^1])
  let (seconds, peak) = successOf(output)
  (seconds, peak, "")


proc checkClaims(
  chain: Toolchain;
  copy, directory: string;
  candidate: Candidate;
  counted, suited: JsonNode;
  algebras: openArray[Algebra];
): JsonNode =
  ## Check each claim proposal makes; one verdict per claim, with detail.

  func algebraNamed(name: string, algebras: openArray[Algebra]): Algebra =
    ## Find algebra by name; one no evaluation measures is read from name, as `rga6d`.
    for algebra in algebras:
      if algebra.name == name: return algebra
    Algebra(name: name, dimensions: parseInt(name[3 .. ^2]), is_conformal: name.startsWith("cga"))

  result = newJArray()
  for claim in candidate.claims:
    let kind = claim{"kind"}.getStr
    var
      is_holding = true
      detail: seq[string]
    case kind
    of "suites":
      var held = suited
      if claim.hasKey("defines"):
        held = newJObject()
        for algebra in algebras:
          held[algebra.name] = suites(
            copy,
            directory / "cache_suites_defined_" & algebra.name,
            algebra,
            definesOf(claim),
          )
      for name, node in held.pairs:
        if node{"failed"}.getInt > 0 or not node{"built"}.getBool:
          is_holding = false
          detail.add name & " failed " & $node{"failed"}.getInt
    of "tables":
      let pairs = claim{"pairs"}
      var side_pristine, side_changed: seq[string]
      for pair in pairs:
        side_pristine.add pair[0].getStr
        side_changed.add pair[1].getStr
      for name in claim{"algebras"}:
        let algebra = algebraNamed(name.getStr, algebras)
        let
          (before, why_before) =
            tablesOf(chain.library, directory, "pristine", side_pristine, algebra)
          (after, why_after) = tablesOf(copy, directory, "changed", side_changed, algebra)
        if before.isNil or after.isNil:
          let why = (why_before & why_after).strip.splitLines
          is_holding = false
          detail.add algebra.name & " did not build: " & (if why.len > 0: why[^1] else: "")
          continue
        for i in 0..<pairs.len:
          if before[i] != after[i]:
            is_holding = false
            detail.add algebra.name & " " & side_changed[i] & " differs"
    of "program":
      let program = candidate.path & "/" & claim{"path"}.getStr  # relative to proposal
      for name in claim{"algebras"}:
        let algebra = algebraNamed(name.getStr, algebras)
        var arguments = @["c", "--hints:off", "--warnings:off", "--skipParentCfg:on",
          "--noNimblePath", "-d:release", "--path:" & copy,
          "--nimcache:" & directory / "cache_program_" & algebra.name,
          "-o:" & directory / "program_" & algebra.name, "-r"]
        arguments.add definesAlgebra(algebra)
        arguments.add definesOf(claim)
        arguments.add program
        let (output, code) = runCompiler(arguments)
        if code != 0:
          is_holding = false
          detail.add algebra.name & " exit " & $code & ": " & output.strip.splitLines[^1]
    of "build":
      let
        algebra = algebraNamed(claim{"algebra"}.getStr, algebras)
        (seconds_before, peak_before, why_before) =
          buildCost(chain, chain.library, directory, "pristine", algebra)
        (seconds_after, peak_after, why_after) =
          buildCost(chain, copy, directory, "changed", algebra)
      if why_before.len > 0 or why_after.len > 0 or peak_before <= 0 or seconds_before <= 0:
        is_holding = false
        detail.add algebra.name & " did not build: " & why_before & why_after
      else:
        let
          ratio = case claim{"metric"}.getStr
            of "seconds": seconds_after / seconds_before
            else: peak_after / peak_before
        is_holding = ratio <= claim{"at_most"}.getFloat
        detail.add algebra.name & " peak " & formatFloat(peak_before, ffDecimal, 1) & " → " &
          formatFloat(peak_after, ffDecimal, 1) & " MiB, " & formatFloat(
            seconds_before,
            ffDecimal,
            2,
          ) & " → " & formatFloat(seconds_after, ffDecimal, 2) & " s, ×" &
          formatFloat(ratio, ffDecimal, 2)
    of "count":
      let
        name_algebra = claim{"algebra"}.getStr
        document = counted{name_algebra}
        key = document{"measurands", claim{"measurand"}.getStr, "library"}
        got = if key.isNil: nil else: document{"functions", key.getStr, "total",
          claim{"metric"}.getStr}
      if got.isNil or got.getInt != claim{"value"}.getInt:
        is_holding = false
        detail.add name_algebra & " got " & (if got.isNil: "none" else: $got.getInt)
    else:
      is_holding = false
      detail.add "unknown claim kind " & kind
    var verdict = claim.copy
    verdict["passed"] = %is_holding
    verdict["detail"] = %detail
    result.add verdict



#[ Evaluation ]#

proc runEvaluation*(
  chain: Toolchain;
  candidate: Candidate;
  algebras: openArray[Algebra];
  baselines: Table[string, JsonNode];
  pristine: Table[string, string];
  suites_pin, taken: JsonNode;
  earlier: JsonNode = nil;
): (JsonNode, seq[Finding]) =
  ## Try candidate on every algebra; evaluation document and findings that stopped it.
  ##   With `earlier`, earlier evaluation of candidate: keep its times where both timed builds
  ##     emit C they were timed on, and find where they do not; time nothing.
  ##   Work directory starts empty, so digest reads C of this build alone.
  let directory = chain.work / candidate.name
  removeDir directory
  createDir directory
  let (copy, findings) = prepareCopy(chain, candidate)
  if findings.len > 0: return (nil, findings)
  var
    evaluation = %*{
      "schema": 1,
      "kind": "evaluation",
      "name": candidate.name,
      "path": candidate.path,
      "edits_digest": digestEdits(candidate.changes, candidate.claims, candidate.programs),
      "taken": taken,
      "pin_suites": suites_pin,
      "algebras": {},
    }
    counted = newJObject()
    suited = newJObject()
  for algebra in algebras:
    let suite = suites(copy, directory / "cache_suites_" & algebra.name, algebra)
    suited[algebra.name] = suite
    let (after, why) = staticOf(chain, copy, directory, algebra)
    if after.isNil:
      return (nil, @[Finding(path: candidate.path, message: "Changed library does not " &
        "build at " & algebra.name & "; got `" & why.strip.splitLines[^1] & "`.")])
    counted[algebra.name] = after
    let
      binary = directory / "bench_" & algebra.name
      (log, code) = compileAgainst(
        chain,
        copy,
        ENTRY_BENCH,
        binary,
        directory / "cache_timed_" & algebra.name,
        algebra,
        should_stop_at_c = false,
      )
    if code != 0:
      return (nil, @[Finding(path: candidate.path, message: "Timed build failed at " &
        algebra.name & "; got `" & log.strip.splitLines[^1] & "`.")])
    let digests = %*{
      "pristine": digestCache(
        pristine[algebra.name].parentDir / "cache_timed_" & algebra.name,
        chain.pga,
      ),
      "changed": digestCache(directory / "cache_timed_" & algebra.name, chain.pga),
    }
    var times, nan: JsonNode
    if earlier.isNil:
      (times, nan) = timed(chain, pristine[algebra.name], binary, directory)
    else:
      let
        before = earlier{"algebras", algebra.name}
        is_current = earlier{"edits_digest"}.getStr == evaluation["edits_digest"].getStr
        why = checkRestamp(
          if before.isNil: nil else: before{"digest_c"},
          digests,
          if is_current: earlier{"taken", "pga"}.getStr else: "",
          chain.pga,
          candidate.path,
          "run `evaluate " & candidate.name & "`",
        )
      if why.len > 0: return (nil, why)
      times = before{"times"}
      nan = before{"nan"}
    evaluation["algebras"][algebra.name] = %*{
      "suites": suite,
      "functions": functionsChanged(baselines[algebra.name], after),
      "times": times,
      "nan": nan,
      "digest_c": digests,
    }
  evaluation["claims"] = checkClaims(chain, copy, directory, candidate, counted, suited, algebras)
  (evaluation, @[])


proc suitesPristine*(chain: Toolchain, algebras: openArray[Algebra]): JsonNode =
  ## Count library's own suites at pin, so evaluation's counts read against them.
  result = newJObject()
  for algebra in algebras:
    result[algebra.name] =
      suites(chain.library, chain.work / "pristine" / "cache_suites_" & algebra.name, algebra)


proc binaryPristine*(chain: Toolchain, algebra: Algebra): string =
  ## Build timed bench against library at pin from empty cache, which digest then reads alone;
  ##   path of binary.
  let directory = chain.work / "pristine"
  createDir directory
  removeDir directory / "cache_timed_" & algebra.name
  result = directory / "bench_" & algebra.name
  let (log, code) = compileAgainst(
    chain,
    chain.library,
    ENTRY_BENCH,
    result,
    directory / "cache_timed_" & algebra.name,
    algebra,
    should_stop_at_c = false,
  )
  if code != 0: raise newException(OSError, "Pristine bench failed; got `" & log & "`.")
