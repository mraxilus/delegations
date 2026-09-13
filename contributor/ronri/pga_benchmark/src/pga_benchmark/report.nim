## Shape measurements as JSON, schema 1, and read them back; tool side only.
##   One document per configuration and kind: `bench` holds timing measurements of every measurand
##   of both implementations, `static` holds counts read from emitted C. Both open with same
##   `algebra` and `taken` objects, so any file says what it measured, on what, and when
##   (Article VII.6). Keys are measurand ids, ASCII, stable across runs.
##
##   Cost: `std/json` allocates freely; runs once per file, never on timed path.

{.experimental: "strictFuncs".}

import std/[cpuinfo, json, strutils, times]

import ./[inspector, model]


const
  SCHEMA* = 1
    ## Schema version written into every document; reader refuses another.
  NIM_COMMIT* {.strdefine: "pga_benchmark.nim_commit".} = "unmeasured"
    ## Compiler commit driver passes at build; "unmeasured" where built by hand.
  PGA_COMMIT* {.strdefine: "pga_benchmark.pga_commit".} = "unmeasured"
    ## Library commit driver reads from `atlas.lock` at build.
  FLAGS* {.strdefine: "pga_benchmark.flags".} = "unrecorded"
    ## Build flags driver passes, so measurements name their build.


proc takenNow*(): JsonNode =
  ## Describe this run: date, machine, compiler and library commits, flags.
  %*{
    "date": now().utc.format("yyyy-MM-dd"),
    "machine": hostOS & " " & hostCPU & ", " & $countProcessors() & " cores",
    "nim": NIM_COMMIT,
    "pga": PGA_COMMIT,
    "flags": FLAGS,
  }


func algebraNode*(name: string; dimensions: int; is_conformal: bool; size: int): JsonNode =
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


func checkSchema*(node: JsonNode; kind: string): string =
  ## Read why document cannot be used, empty when it can.
  if node.kind != JObject: return "Document is not object."
  if not node.hasKey("schema") or node["schema"].getInt != SCHEMA:
    return "Schema differs; got `" & $node{"schema"} & "`."
  if node{"kind"}.getStr != kind:
    return "Kind differs; got `" & node{"kind"}.getStr & "`, wanted `" & kind & "`."
  ""


func countsNode*(c: Counts): JsonNode =
  ## Shape counts as object with one field per count.
  %*{
    "multiplies": c.multiplies,
    "adds": c.adds,
    "subs": c.subs,
    "divides": c.divides,
    "zero_fills": c.zero_fills,
    "intermediates": c.intermediates,
    "copies": c.copies,
    "checks": c.checks,
    "calls": c.calls,
    "allocations": c.allocations,
    "lines": c.lines,
  }


func movementNode*(m: Movement): JsonNode =
  ## Shape movement model as object with one field per cause.
  %*{
    "bytes_read": m.bytes_read,
    "bytes_written": m.bytes_written,
    "bytes_zeroed": m.bytes_zeroed,
    "bytes_copied": m.bytes_copied,
    "bytes_intermediates": m.bytes_intermediates,
    "bytes_moved": m.bytes_moved,
  }


func moduleTail*(module: string): string =
  ## Read last two segments of mangled module path, `pga/operators` out of
  ## `OOZdepsZ...ZpgaZoperators`, since whole path spells checkout and outruns line width.
  ##   Compiler spells `/` as `Z` and `_` as `95`; only those two are undone.
  let parts = module.split('Z')
  let tail = if parts.len >= 2: parts[^2 .. ^1] else: parts
  tail.join("/").replace("95", "_")


func functionNode*(f: CFunction; own, total: Counts; size_multivector: int): JsonNode =
  ## Shape one inspected function: key parts, module tail, inline flag, own and total
  ## counts, movement modelled on total counts. Mangled name is left out: it spells
  ## checkout path and compiler hash, neither of which is measurement.
  %*{
    "symbol": f.symbol,
    "module": moduleTail(f.module),
    "params": f.params,
    "returns": f.result_stem,
    "inline": f.is_inline,
    "own": countsNode(own),
    "total": countsNode(total),
    "movement": movementNode(movement(f, total, size_multivector)),
  }


const GATED* = [
  "multiplies", "adds", "subs", "divides", "zero_fills", "intermediates", "copies", "checks",
  "calls", "allocations", "lines",
]
  ## Count names gate compares: any growth is finding, every one deterministic.
