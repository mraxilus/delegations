## Try proposed change on copy of library at pin: its suites, its counts, its timings, its claims.
##   Trial is how change or design earns figures page shows. It copies library checkout, applies
##     edits (base design first where design builds on one), then measures copy against pin:
##     - library's own suites, both typed algebras, pristine counts beside;
##     - static measurements of every function change touches, pin's baseline as before;
##     - runtime of every measurand, pristine and changed binaries run alternately, so drift
##       of machine lands on both alike, and ratio per measurand is median over runs;
##     - design claims: suites pass, tables equal pristine ones, programs run, counts hold,
##       and build of bench entry costs no more than stated share of pristine build.
##   Result is one document in `trials/`, taken at pin and naming digest of edits it tried,
##     so `drive` refuses trial of another commit or of edits since changed (`head.nim`).
##   Working copy keeps checkout's directory name, since function keys and module tails are
##     read from path and must match baseline's.
##
##   Cost: every trial compiles library four times per algebra (suites, counts, two timed
##     binaries); pristine binaries are built once per run of driver and shared.
##   Cost: timings are machine's, as every runtime measurement is; trial names machine.

{.experimental: "strictFuncs".}

import std/[algorithm, json, math, os, osproc, sequtils, strutils, tables]

import ./[changes, guard]


type
  Algebra* = object
    ## Define algebra trial measures: name, dimensions, metric.
    name*: string
      ## Short name, e.g. `rga4d`.
    dimensions*: int
      ## Vector space dimensions.
    is_conformal*: bool
      ## Metric: conformal where true, rigid else.
  Toolchain* = object
    ## Define where trial reads and writes, and what build it names.
    library*: string
      ## Library checkout at pin.
    work*: string
      ## Directory trials build under.
    nim*: string
      ## Compiler commit.
    pga*: string
      ## Library commit, i.e. pin.
    flags*: string
      ## Build flags every measured build carries.
    runs*: int
      ## Timed runs of each binary, alternating.
  Candidate* = object
    ## Define what one trial tries: edits in order, programs and claims.
    name*: string
      ## Trial name, file name of its document.
    path*: string
      ## Change file or design directory findings name.
    changes*: seq[Change]
      ## Changes applied in order, base design first.
    programs*: seq[string]
      ## Text of programs design's claims run, so digest moves when program does.
    claims*: JsonNode
      ## Claims design makes; empty array for change.


const
  ENTRY_BENCH = "src/pga_benchmark/bench.nim"
    ## Entry reaching every measurand.
  ENTRY_INSPECT = "src/pga_benchmark/inspect.nim"
    ## Entry reading cache into static measurements.
  COUNTED = ["multiplies", "adds", "subs", "divides", "zero_fills", "intermediates", "copies",
    "checks", "calls", "lines"]
    ## Totals trial reports where they differ from pin.
  MOVED = ["bytes_moved", "bytes_zeroed", "bytes_intermediates"]
    ## Movement trial reports where it differs from pin.
  SUITE_STUB = "tests" / "$1" / "test_$1.nim"
    ## Library's own stub per algebra, relative to checkout.



#[ Edits Digest ]#

func editsDigest*(changes: openArray[Change], claims: JsonNode, programs: seq[string]): string =
  ## Digest what trial tries: every edit, claims and program text; prose is left out.
  var text = $claims
  for change in changes:
    for edit in change.edits:
      text.add edit.path & "\0" & edit.quote & "\0" & edit.replacement & "\0" & edit.digest
  for program in programs: text.add "\0" & program
  digestOf(text)



#[ Library Copies ]#

proc readLibrary*(directory: string): Table[string, string] =
  ## Read every Nim file under library directory, keyed by relative path with `/`.
  for path in walkDirRec(directory, relative = true):
    if path.endsWith(".nim"): result[path.replace('\\', '/')] = readFile(directory / path)


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

proc runCompiler(args: openArray[string]): (string, int) =
  ## Run compiler with args, capturing output; output and exit code.
  let command = "nim " & args.mapIt(quoteShell(it)).join(" ")
  execCmdEx(command)


func algebraDefines(a: Algebra): seq[string] =
  ## Spell defines selecting algebra.
  @["-d:pga.dimensions=" & $a.dimensions, "-d:pga.is_conformal=" & $a.is_conformal]


func buildDefines(chain: Toolchain, pga: string): seq[string] =
  ## Spell defines naming build in documents it writes.
  @[
    "-d:pga_benchmark.nim_commit=" & chain.nim,
    "-d:pga_benchmark.pga_commit=" & pga,
    "-d:pga_benchmark.flags=" & chain.flags,
  ]


proc compileAgainst(
  chain: Toolchain;
  library, entry, binary, cache: string;
  a: Algebra;
  compile_only: bool;
): (string, int) =
  ## Compile project entry against library copy, skipping project `nim.cfg` that names pin's.
  var args = @["c", "--hints:off", "--warnings:off", chain.flags, "--skipParentCfg:on",
    "--noNimblePath", "--path:" & library, "--nimcache:" & cache, "-o:" & binary]
  args.add algebraDefines(a) & buildDefines(chain, chain.pga)
  if compile_only: args.add "--compileOnly"
  args.add entry
  runCompiler(args)


proc suites(library, cache: string, a: Algebra): JsonNode =
  ## Compile and run library's own suites on copy; count passed and failed tests.
  let stub = library / SUITE_STUB % a.name
  if not fileExists(stub): return %*{"ok": 0, "failed": 0, "built": false}
  var args = @["c", "--hints:off", "--warnings:off", "--skipParentCfg:on", "--noNimblePath",
    "-d:testing", "-d:nimUnittestAbortOnError:off", "--nimcache:" & cache,
    "-o:" & cache / "suites", "-r"]
  args.add algebraDefines(a)
  args.add stub
  let (output, code) = runCompiler(args)
  %*{
    "ok": output.count("[OK]"),
    "failed": output.count("[FAILED]"),
    "built": code == 0 or output.contains("[OK]"),
  }


proc staticOf(chain: Toolchain, library, directory: string, a: Algebra): (JsonNode, string) =
  ## Inspect emitted C of bench entry built against library; document and failure text.
  let
    cache = directory / "cache_bench_" & a.name
    inspector = directory / "inspect_" & a.name
    output = directory / "static_" & a.name & ".json"
  removeDir cache
  var (log, code) = compileAgainst(chain, library, ENTRY_BENCH, directory / "bench_c_" & a.name,
    cache, a, compile_only = true)
  if code != 0: return (nil, log)
  (log, code) = compileAgainst(chain, library, ENTRY_INSPECT, inspector,
    directory / "cache_inspect_" & a.name, a, compile_only = false)
  if code != 0: return (nil, log)
  (log, code) = execCmdEx(quoteShell(inspector) & " " & quoteShell(cache) & " " &
    quoteShell(output) & " " & quoteShell(chain.nim) & " " & quoteShell(chain.pga) & " " &
    quoteShell(chain.flags))
  if code != 0: return (nil, log)
  (parseJson(readFile(output)), "")



#[ Comparisons ]#

func countsOf(f: JsonNode): JsonNode =
  ## Shape totals and movement trial reports for one function.
  ##   Count document lacks is JSON null, never nil.
  result = newJObject()
  for key in COUNTED:
    let node = f{"total", key}
    result[key] = if node.isNil: newJNull() else: node
  for key in MOVED:
    let node = f{"movement", key}
    result[key] = if node.isNil: newJNull() else: node


func functionsChanged*(before, after: JsonNode): JsonNode =
  ## Compare static documents function by function; keep those whose counts differ.
  ##   Function on one side only is JSON null on other, never nil, so document prints.
  result = newJObject()
  let
    was = before{"functions"}
    now = after{"functions"}
  if was.isNil or now.isNil: return
  var keys = toSeq(was.keys)
  for key in now.keys:
    if key notin keys: keys.add key
  keys.sort
  for key in keys:
    let
      a = if was.hasKey(key): countsOf(was[key]) else: newJNull()
      b = if now.hasKey(key): countsOf(now[key]) else: newJNull()
    if a != b: result[key] = %*{"before": a, "after": b}


func median(values: seq[float]): float =
  ## Read median of values; zero for none.
  if values.len == 0: return 0.0
  let sorted = values.sorted
  let middle = sorted.len div 2
  if sorted.len mod 2 == 1: sorted[middle] else: (sorted[middle - 1] + sorted[middle]) / 2.0


func timesOf*(pristine, candidate: seq[JsonNode]): JsonNode =
  ## Pair runs of both binaries by measurand; median ns of each and median of per-run ratios.
  result = newJObject()
  if pristine.len == 0 or candidate.len == 0: return
  for id, _ in pristine[0]{"measurands"}.pairs:
    var ns_before, ns_after, ratios: seq[float]
    for i in 0 ..< min(pristine.len, candidate.len):
      let
        a = pristine[i]{"measurands", id, "library", "ns_median"}
        b = candidate[i]{"measurands", id, "library", "ns_median"}
      if a.isNil or b.isNil or a.kind != JFloat or b.kind != JFloat: continue
      ns_before.add a.getFloat
      ns_after.add b.getFloat
      if a.getFloat > 0: ratios.add b.getFloat / a.getFloat
    if ratios.len == 0: continue
    result[id] = %*[ns_before.median.round(2), ns_after.median.round(2), ratios.median.round(4)]


func nanOf*(pristine, candidate: seq[JsonNode]): JsonNode =
  ## Compare share of NaN results per measurand, first run of each side; keep those that differ.
  ##   Share is property of samples and code, never of machine, so one run of each suffices.
  result = newJObject()
  if pristine.len == 0 or candidate.len == 0: return
  for id, _ in pristine[0]{"measurands"}.pairs:
    let
      a = pristine[0]{"measurands", id, "library", "nan_share"}
      b = candidate[0]{"measurands", id, "library", "nan_share"}
    if a.isNil or b.isNil or a.kind != JFloat or b.kind != JFloat: continue
    if a.getFloat != b.getFloat: result[id] = %*[a.getFloat, b.getFloat]


func successOf*(output: string): (float, float) =
  ## Read seconds and peak memory in MiB from compiler's success line; zeros where absent.
  for line in output.splitLines:
    if not line.contains("[SuccessX]"): continue
    var seconds, peak: float
    for part in line.split("; "):
      if part.endsWith("MiB peakmem"):
        peak = parseFloat(part[0 ..< part.len - "MiB peakmem".len])
      elif part.endsWith("s") and part.len > 1 and part[0].isDigit:
        try: seconds = parseFloat(part[0 ..< ^1])
        except ValueError: discard
    return (seconds, peak)


proc timedRun(binary, output: string): JsonNode =
  ## Run one timed binary into output; its document, nil where run failed.
  let (_, code) = execCmdEx(quoteShell(binary) & " " & quoteShell(output))
  if code == 0: parseJson(readFile(output)) else: nil


proc timed(chain: Toolchain, pristine, candidate, directory: string): (JsonNode, JsonNode) =
  ## Run both binaries alternately `runs` times each; times and NaN shares per measurand.
  var before, after: seq[JsonNode]
  for run in 1 .. chain.runs:
    let
      a = timedRun(pristine, directory / "pristine_" & $run & ".json")
      b = timedRun(candidate, directory / "changed_" & $run & ".json")
    if a.isNil or b.isNil: continue
    before.add a
    after.add b
  (timesOf(before, after), nanOf(before, after))



#[ Claims ]#

const TABLES_PROGRAM = """
import std/json
import pga/[algebra {.all.}, cayleys {.all.}, multivectors]

proc term(b: BasisSigned): JsonNode = %*{"to": $b.basis, "neg": b.is_negated}

proc cell(c: auto): JsonNode =
  result = newJArray()
  when c is seq:
    for b in c: result.add term(b)
  else:
    if c.isSome: result.add term(c.get)

proc cells(table: auto): JsonNode =
  result = newJObject()
  for a in Basis:
    when table[a] is array:
      for b in Basis:
        let terms = cell(table[a][b])
        if terms.len > 0: result[$a & "," & $b] = terms
    else:
      let terms = cell(table[a])
      if terms.len > 0: result[$a] = terms

var tables = newJArray()
$1
echo tables
"""
  ## Program printing tables as JSON, one `tables.add cells(<expression>)` line per table.
  ##   Serializer reads both cell shapes, `Option` and `seq`, so one program serves pristine
  ##   library and changed one alike.


proc tablesOf(
  library, directory, side: string, expressions: seq[string], a: Algebra
): (JsonNode, string) =
  ## Compile and run table program against library; tables in order and failure text.
  let
    source = directory / "tables_" & side & "_" & a.name & ".nim"
    lines = expressions.mapIt("tables.add cells(" & it & ")").join("\n")
  writeFile(source, TABLES_PROGRAM.replace("$1", lines))
  var args = @["c", "--hints:off", "--warnings:off", "--skipParentCfg:on", "--noNimblePath",
    "-d:release", "--path:" & library, "--nimcache:" & directory / "cache_" & side & "_" & a.name,
    "-o:" & directory / "tables_" & side & "_" & a.name, "-r"]
  args.add algebraDefines(a)
  args.add source
  let (output, code) = runCompiler(args)
  if code != 0: return (nil, output)
  let last = output.strip.splitLines[^1]
  (parseJson(last), "")


proc buildCost(
  chain: Toolchain, library, directory, side: string, a: Algebra
): (float, float, string) =
  ## Compile bench entry to C from empty cache; seconds and peak MiB compiler reports.
  let cache = directory / "cache_build_" & side & "_" & a.name
  removeDir cache
  var args = @["c", "--hints:on", "--warnings:off", chain.flags, "--skipParentCfg:on",
    "--noNimblePath", "--path:" & library, "--nimcache:" & cache, "--compileOnly",
    "-o:" & directory / "build_" & side & "_" & a.name]
  args.add algebraDefines(a) & buildDefines(chain, chain.pga)
  args.add ENTRY_BENCH
  let (output, code) = runCompiler(args)
  if code != 0: return (0.0, 0.0, output.strip.splitLines[^1])
  let (seconds, peak) = successOf(output)
  (seconds, peak, "")


func algebraNamed(name: string, algebras: openArray[Algebra]): Algebra =
  ## Find algebra by name, rigid 4D where name is unknown.
  for a in algebras:
    if a.name == name: return a
  Algebra(name: name, dimensions: parseInt(name[3 .. ^2]), is_conformal: name.startsWith("cga"))


proc checkClaims(
  chain: Toolchain;
  copy, directory: string;
  candidate: Candidate;
  counted, suited: JsonNode;
  algebras: openArray[Algebra];
): JsonNode =
  ## Check each claim design makes; one verdict per claim, with detail.
  result = newJArray()
  for claim in candidate.claims:
    let kind = claim{"kind"}.getStr
    var
      passed = true
      detail: seq[string]
    case kind
    of "suites":
      for name, node in suited.pairs:
        if node{"failed"}.getInt > 0 or not node{"built"}.getBool:
          passed = false
          detail.add name & " failed " & $node{"failed"}.getInt
    of "tables":
      let pairs = claim{"pairs"}
      var pristine_side, changed_side: seq[string]
      for pair in pairs:
        pristine_side.add pair[0].getStr
        changed_side.add pair[1].getStr
      for name in claim{"algebras"}:
        let a = algebraNamed(name.getStr, algebras)
        let
          (before, why_before) =
            tablesOf(chain.library, directory, "pristine", pristine_side, a)
          (after, why_after) = tablesOf(copy, directory, "changed", changed_side, a)
        if before.isNil or after.isNil:
          let why = (why_before & why_after).strip.splitLines
          passed = false
          detail.add a.name & " did not build: " & (if why.len > 0: why[^1] else: "")
          continue
        for i in 0 ..< pairs.len:
          if before[i] != after[i]:
            passed = false
            detail.add a.name & " " & changed_side[i] & " differs"
    of "program":
      let program = claim{"path"}.getStr
      for name in claim{"algebras"}:
        let a = algebraNamed(name.getStr, algebras)
        var args = @["c", "--hints:off", "--warnings:off", "--skipParentCfg:on",
          "--noNimblePath", "-d:release", "--path:" & copy,
          "--nimcache:" & directory / "cache_program_" & a.name,
          "-o:" & directory / "program_" & a.name, "-r"]
        args.add algebraDefines(a)
        args.add program
        let (output, code) = runCompiler(args)
        if code != 0:
          passed = false
          detail.add a.name & " exit " & $code & ": " & output.strip.splitLines[^1]
    of "build":
      let
        a = algebraNamed(claim{"algebra"}.getStr, algebras)
        (seconds_before, peak_before, why_before) =
          buildCost(chain, chain.library, directory, "pristine", a)
        (seconds_after, peak_after, why_after) = buildCost(chain, copy, directory, "changed", a)
      if why_before.len > 0 or why_after.len > 0 or peak_before <= 0 or seconds_before <= 0:
        passed = false
        detail.add a.name & " did not build: " & why_before & why_after
      else:
        let
          ratio = case claim{"metric"}.getStr
            of "seconds": seconds_after / seconds_before
            else: peak_after / peak_before
        passed = ratio <= claim{"at_most"}.getFloat
        detail.add a.name & " peak " & formatFloat(peak_before, ffDecimal, 1) & " → " &
          formatFloat(peak_after, ffDecimal, 1) & " MiB, " & formatFloat(seconds_before,
          ffDecimal, 2) & " → " & formatFloat(seconds_after, ffDecimal, 2) & " s, ×" &
          formatFloat(ratio, ffDecimal, 2)
    of "count":
      let
        a = claim{"algebra"}.getStr
        document = counted{a}
        key = document{"measurands", claim{"measurand"}.getStr, "library"}
        got = if key.isNil: nil else: document{"functions", key.getStr, "total",
          claim{"metric"}.getStr}
      if got.isNil or got.getInt != claim{"value"}.getInt:
        passed = false
        detail.add a & " got " & (if got.isNil: "none" else: $got.getInt)
    else:
      passed = false
      detail.add "unknown claim kind " & kind
    var verdict = claim.copy
    verdict["passed"] = %passed
    verdict["detail"] = %detail
    result.add verdict



#[ Trial ]#

proc runTrial*(
  chain: Toolchain;
  candidate: Candidate;
  algebras: openArray[Algebra];
  baselines: Table[string, JsonNode];
  pristine: Table[string, string];
  pin_suites, taken: JsonNode;
): (JsonNode, seq[Finding]) =
  ## Try candidate on every algebra; trial document and findings that stopped it.
  let directory = chain.work / candidate.name
  createDir directory
  let (copy, findings) = prepareCopy(chain, candidate)
  if findings.len > 0: return (nil, findings)
  var
    trial = %*{
      "schema": 1,
      "kind": "trial",
      "name": candidate.name,
      "path": candidate.path,
      "edits_digest": editsDigest(candidate.changes, candidate.claims, candidate.programs),
      "taken": taken,
      "pin_suites": pin_suites,
      "algebras": {},
    }
    counted = newJObject()
    suited = newJObject()
  for a in algebras:
    let suite = suites(copy, directory / "cache_suites_" & a.name, a)
    suited[a.name] = suite
    let (after, why) = staticOf(chain, copy, directory, a)
    if after.isNil:
      return (nil, @[Finding(path: candidate.path, message: "Changed library does not " &
        "build at " & a.name & "; got `" & why.strip.splitLines[^1] & "`.")])
    counted[a.name] = after
    let binary = directory / "bench_" & a.name
    let (log, code) = compileAgainst(chain, copy, ENTRY_BENCH, binary,
      directory / "cache_timed_" & a.name, a, compile_only = false)
    if code != 0:
      return (nil, @[Finding(path: candidate.path, message: "Timed build failed at " &
        a.name & "; got `" & log.strip.splitLines[^1] & "`.")])
    let (times, nan) = timed(chain, pristine[a.name], binary, directory)
    trial["algebras"][a.name] = %*{
      "suites": suite,
      "functions": functionsChanged(baselines[a.name], after),
      "times": times,
      "nan": nan,
    }
  trial["claims"] = checkClaims(chain, copy, directory, candidate, counted, suited, algebras)
  (trial, @[])


proc pristineSuites*(chain: Toolchain, algebras: openArray[Algebra]): JsonNode =
  ## Count library's own suites at pin, so trial's counts read against them.
  result = newJObject()
  for a in algebras:
    result[a.name] = suites(chain.library, chain.work / "pristine" / "cache_suites_" & a.name, a)


proc pristineBinary*(chain: Toolchain, a: Algebra): string =
  ## Build timed bench against library at pin; path of binary.
  let directory = chain.work / "pristine"
  createDir directory
  result = directory / "bench_" & a.name
  let (log, code) = compileAgainst(chain, chain.library, ENTRY_BENCH, result,
    directory / "cache_timed_" & a.name, a, compile_only = false)
  if code != 0: raise newException(OSError, "Pristine bench failed; got `" & log & "`.")
