## Shape figures and counts as JSON, schema 1, and read them back; tool side only.
##   One document per configuration and kind: `bench` holds timing figures of every probe
##   on both sides, `inspect` holds counts read from emitted C. Both open with same
##   `config` and `taken` objects, so any file says what it measured, on what, and when
##   (Article VII.6). Keys are probe ids, ASCII, stable across runs.
##
##   Cost: `std/json` allocates freely; runs once per file, never on timed path.

{.experimental: "strictFuncs".}

import std/[cpuinfo, json, times]


const
  SCHEMA* = 1
    ## Schema version written into every document; reader refuses another.
  NIM_COMMIT* {.strdefine: "pga_benchmark.nim_commit".} = "unmeasured"
    ## Compiler commit driver passes at build; "unmeasured" where built by hand.
  PGA_COMMIT* {.strdefine: "pga_benchmark.pga_commit".} = "unmeasured"
    ## Library commit driver reads from `atlas.lock` at build.
  FLAGS* {.strdefine: "pga_benchmark.flags".} = "unrecorded"
    ## Build flags driver passes, so figures name their build.


proc takenNow*(): JsonNode =
  ## Describe this run: date, machine, compiler and library commits, flags.
  %*{
    "date": now().utc.format("yyyy-MM-dd"),
    "machine": hostOS & " " & hostCPU & ", " & $countProcessors() & " cores",
    "nim": NIM_COMMIT,
    "pga": PGA_COMMIT,
    "flags": FLAGS,
  }


func configNode*(name: string; dimensions: int; is_conformal: bool; size: int): JsonNode =
  ## Describe algebra measured: name, dimensions, metric, multivector size in bytes.
  %*{
    "name": name,
    "dimensions": dimensions,
    "is_conformal": is_conformal,
    "sizeof_multivector": size,
  }


func document*(kind: string; config, taken: JsonNode): JsonNode =
  ## Open document of given kind with shared header.
  %*{"schema": SCHEMA, "kind": kind, "config": config, "taken": taken}


func checkSchema*(node: JsonNode; kind: string): string =
  ## Read why document cannot be used, empty when it can.
  if node.kind != JObject: return "Document is not object."
  if not node.hasKey("schema") or node["schema"].getInt != SCHEMA:
    return "Schema differs; got `" & $node{"schema"} & "`."
  if node{"kind"}.getStr != kind:
    return "Kind differs; got `" & node{"kind"}.getStr & "`, wanted `" & kind & "`."
  ""
