## Run every probe of this algebra and write figures as JSON: `bench <output.json>`.
##   Entry point driver compiles once per configuration, with `-d:release` for timings and
##   again with `-d:nimAllocStats` for allocation counts. Same build's nimcache is what
##   inspector reads, since every library operation is reached from here and Nim emits
##   only reached procedures.
##   Prints one line per probe and sink's checksum, so run is legible without JSON.
##
##   Cost: pools fill once (seeded), then `runProbes` walks catalogue; JSON writing is
##     tool side and allocates after every figure is taken.

{.experimental: "strictFuncs".}

import std/[json, os, strutils]

import pga

import ./[catalogue, kinds, pools, probes, report]


const CONFIG = (if IS_CONFORMAL: "cga" else: "rga") & $DIMENSIONS & "d"
  ## Name of algebra this build measures; umbrella spells same, kept here to stay entry.


func figureNode(f: Figure): JsonNode =
  ## Shape one side's figure; absent side is `null`.
  if not f.is_measured: return newJNull()
  %*{
    "ns_median": f.ns_median,
    "ns_min": f.ns_min,
    "allocations": f.allocations,
    "nan_share": f.nan_share,
  }


proc benchDocument(): JsonNode =
  ## Shape every probe's figures into `bench` document.
  result = document(
    "bench", configNode(CONFIG, DIMENSIONS, IS_CONFORMAL, SIZE_MULTIVECTOR), takenNow()
  )
  result["taken"]["rounds"] = %ROUNDS
  result["taken"]["objects"] = %OBJECTS
  result["taken"]["is_allocation_measured"] = %isAllocationMeasured()
  var probes = newJObject()
  for index, probe in PROBES:
    probes[probe.id] = %*{
      "symbol": probe.symbol,
      "arity": int(probe.arity),
      "library": figureNode(FIGURES[Side.Library][index]),
      "reference": figureNode(FIGURES[Side.Reference][index]),
    }
  result["probes"] = probes


proc controlAllocation(): bool =
  ## Prove allocation counter moves, so zero counts below mean zero and not inert gauge.
  let before = getAllocStats()
  var control = newSeq[float](8)
  control[0] = 1.0
  let after = getAllocStats()
  SINK += control[0]
  allocationsOf(after - before) > 0


proc main(): int =
  ## Fill pools, run probes, print figures, write JSON to path given.
  if paramCount() != 1:
    stderr.write "Usage: bench <output.json>\n"
    return 2
  fillPools(0)
  if isAllocationMeasured() and not controlAllocation():
    stderr.write "Allocation counter inert under -d:nimAllocStats; refusing to report.\n"
    return 1
  runProbes()
  echo "config ", CONFIG, " objects ", OBJECTS, " rounds ", ROUNDS, " allocation gauge ",
    (if isAllocationMeasured(): "live" else: "off")
  for index, probe in PROBES:
    let l = FIGURES[Side.Library][index]
    let r = FIGURES[Side.Reference][index]
    var line = probe.id.alignLeft(34) & formatFloat(l.ns_median, ffDecimal, 2).align(9) & " ns"
    if r.is_measured:
      line.add "  reference " & formatFloat(r.ns_median, ffDecimal, 2).align(8) & " ns"
    if l.allocations > 0: line.add "  allocations " & $l.allocations
    if l.nan_share > 0.0: line.add "  nan " & formatFloat(l.nan_share, ffDecimal, 2)
    echo line
  echo "checksum ", SINK
  writeFile(paramStr(1), pretty(benchDocument()) & "\n")
  0


when isMainModule:
  quit main()
