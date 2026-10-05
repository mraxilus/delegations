## Write measurements as JSON, schema 1, and read them back; tool side only.
##   One document per configuration and kind: `runtime` holds timing measurements of every
##   measurand in each of `IMPLEMENTATIONS`, `static` holds counts read from emitted C. Both
##   open with same `algebra` and `taken` objects, so any file says what it measured, on what,
##   and when (Article VII.6). Keys are measurand ids, ASCII, stable across runs.
##
##   Cost: `std/json` allocates freely; runs once per file, never on timed path.

{.experimental: "strictFuncs".}

import std/[algorithm, cpuinfo, json, math, sequtils, strutils, times]

import ./[inspector, model]


const
  SCHEMA* = 1  ## Schema version written into every document; reader refuses another.
  COMMIT_NIM* {.strdefine: "pga_benchmark.commit_nim".} = "unmeasured"
    ## Compiler commit driver passes at build; "unmeasured" where built by hand.
  COMMIT_PGA* {.strdefine: "pga_benchmark.commit_pga".} = "unmeasured"
    ## Library commit driver reads from `atlas.lock` at build.
  FLAGS* {.strdefine: "pga_benchmark.flags".} = "unrecorded"
    ## Build flags driver passes, so measurements name their build.
  IMPLEMENTATIONS* = ["library", "reference", "dense"]
    ## Keys runtime document gives each implementation of measurand.


proc takenNow*(): JsonNode =
  ## Describe this run: date, machine, compiler and library commits, flags.
  %*{
    "date": now().utc.format("yyyy-MM-dd"),
    "machine": hostOS & " " & hostCPU & ", " & $countProcessors() & " cores",
    "nim": COMMIT_NIM,
    "pga": COMMIT_PGA,
    "flags": FLAGS,
  }


func nodeAlgebra*(name: string, dimensions: int, is_conformal: bool, size: int): JsonNode =
  ## Describe algebra measured: name, dimensions, metric, multivector size in bytes.
  %*{
    "name": name,
    "dimensions": dimensions,
    "is_conformal": is_conformal,
    "sizeof_multivector": size,
  }


func document*(kind: string; algebra, taken: JsonNode): JsonNode =
  ## Open document of given kind with shared header.
  %*{"schema": SCHEMA, "kind": kind, "algebra": algebra, "taken": taken}


func checkSchema*(node: JsonNode, kind: string): string =
  ## Read why document cannot be used, empty when it can.
  if node.kind != JObject: return "Document is not object."
  if not node.hasKey("schema") or node["schema"].getInt != SCHEMA:
    return "Schema differs; got `" & $node{"schema"} & "`."
  if node{"kind"}.getStr != kind:
    return "Kind differs; got `" & node{"kind"}.getStr & "`, wanted `" & kind & "`."
  ""


func nodeCounts*(counts: Counts): JsonNode =
  ## Build counts as object with one field per count.
  %*{
    "multiplies": counts.multiplies,
    "adds": counts.adds,
    "subtractions": counts.subtractions,
    "divides": counts.divides,
    "fills_zero": counts.fills_zero,
    "intermediates": counts.intermediates,
    "copies": counts.copies,
    "checks": counts.checks,
    "calls": counts.calls,
    "allocations": counts.allocations,
    "lines": counts.lines,
  }


func nodeMovement*(movement: Movement): JsonNode =
  ## Build movement model as object with one field per cause.
  %*{
    "bytes_read": movement.bytes_read,
    "bytes_written": movement.bytes_written,
    "bytes_zeroed": movement.bytes_zeroed,
    "bytes_copied": movement.bytes_copied,
    "bytes_intermediates": movement.bytes_intermediates,
    "bytes_moved": movement.bytes_moved,
  }


func tailModule*(module: string): string =
  ## Read last two segments of mangled module path, i.e. `pga/operators`.
  ##   Source is e.g. `OOZdependenciesZ...ZpgaZoperators`; whole path spells checkout and
  ##     outruns line width.
  ##   Compiler spells `/` as `Z` and `_` as `95`; only those two are undone.
  let
    parts = module.split('Z')
    tail = if parts.len >= 2: parts[^2 .. ^1] else: parts
  tail.join("/").replace("95", "_")


func isModuleLibrary*(module: string): bool =
  ## Decide whether module tail names library's module, rather than reference's or dense forms'.
  ##   Dense module's tail is `dense` in bench build, and path ends so elsewhere.
  not module.startsWith("reference/") and module != "dense" and not module.endsWith("/dense")


func nodeFunction*(function: FunctionC; own, total: Counts; size_multivector: int): JsonNode =
  ## Build object of one inspected function.
  ##   Object holds key parts, module tail, inline flag, own and total counts, and movement
  ##     modelled on total counts.
  ##   Mangled name is left out: it spells checkout path and compiler hash, neither of which
  ##     is measurement.
  %*{
    "symbol": function.symbol,
    "module": tailModule(function.module),
    "params": function.parameters,
    "returns": function.stem_result,
    "inline": function.is_inline,
    "own": nodeCounts(own),
    "total": nodeCounts(total),
    "movement": nodeMovement(movement(function, total, size_multivector)),
  }


func median*(values: openArray[float]): float =
  ## Read median of values, mean of middle two for even count; zero for none.
  if values.len == 0: return 0.0
  let
    sorted = values.sorted
    middle = sorted.len div 2
  if sorted.len mod 2 == 1: sorted[middle] else: (sorted[middle-1] + sorted[middle]) / 2.0


func combineRuns*(runs: openArray[JsonNode]): JsonNode =
  ## Combine runtime documents of alternating runs of one binary into one.
  ##   Per implementation, it keeps median of run medians, least minimum, and each run's
  ##   median in run order as `ns_runs`.
  ##   Run medians pair by index across implementations, since one run times both.
  ##   Header, NaN share and allocations are first run's; every run computes same pools.
  if runs.len == 0: return newJNull()
  result = runs[0].copy
  result["taken"]["runs"] = %runs.len
  for id, measurand in result{"measurands"}.pairs:
    for implementation in IMPLEMENTATIONS:
      let measurement = measurand{implementation}
      if measurement.isNil or measurement.kind != JObject: continue
      var medians, minimums: seq[float]
      for run in runs:
        let other = run{"measurands", id, implementation}
        if other.isNil or other.kind != JObject: continue
        medians.add other{"ns_median"}.getFloat
        minimums.add other{"ns_min"}.getFloat
      measurement["ns_median"] = %medians.median.round(2)
      measurement["ns_min"] = %minimums.min.round(2)
      measurement["ns_runs"] = %medians.mapIt(it.round(2))


const METRICS_GATED* = [
  "multiplies",
  "adds",
  "subtractions",
  "divides",
  "fills_zero",
  "intermediates",
  "copies",
  "checks",
  "calls",
  "allocations",
  "lines",
]
  ## Count names gate compares: any growth is finding, every one deterministic.
