## Run every measurand of this algebra and write measurements as JSON: `bench <output.json>`.
##   Entry point driver compiles once per configuration, with `-d:release` for timings and
##   again with `-d:nimAllocStats` for allocation counts. Same build's nimcache is what
##   inspector reads, since every library operation is reached from here and Nim emits
##   only reached procedures.
##   Prints one line per measurand and sink's checksum, so run is legible without JSON.
##
##   Cost: pools fill once (seeded), then `measureCatalogue` walks catalogue; JSON writing is
##     tool side and allocates after every measurement is taken.

{.experimental: "strictFuncs".}

import std/[json, os, strutils]

import pga

import ./[catalogue, kinds, measurements, pools, report]


const ALGEBRA_NAME = (if IS_CONFORMAL: "cga" else: "rga") & $DIMENSIONS & "d"
  ## Name of algebra this build measures; umbrella spells same, kept here to stay entry.


func measurementNode(f: Measurement): JsonNode =
  ## Shape one implementation's measurement; absent implementation is `null`.
  if not f.is_measured: return newJNull()
  %*{
    "ns_median": f.ns_median,
    "ns_min": f.ns_min,
    "allocations": f.allocations,
    "nan_share": f.nan_share,
  }


proc benchDocument(): JsonNode =
  ## Shape every measurand's measurements into `bench` document.
  result = document(
    "runtime", algebraNode(ALGEBRA_NAME, DIMENSIONS, IS_CONFORMAL, SIZE_MULTIVECTOR), takenNow()
  )
  result["taken"]["rounds"] = %ROUNDS
  result["taken"]["objects"] = %OBJECTS
  result["taken"]["is_allocation_measured"] = %isAllocationMeasured()
  var measurands = newJObject()
  for index, measurand in CATALOGUE:
    measurands[measurand.id] = %*{
      "symbol": measurand.symbol,
      "arity": int(measurand.arity),
      "library": measurementNode(MEASUREMENTS[Implementation.Library][index]),
      "reference": measurementNode(MEASUREMENTS[Implementation.Reference][index]),
    }
  result["measurands"] = measurands


proc controlAllocation(): bool =
  ## Prove allocation counter moves, so zero counts below mean zero and not inert gauge.
  let before = getAllocStats()
  var control = newSeq[float](8)
  control[0] = 1.0
  let after = getAllocStats()
  SINK += control[0]
  allocationsOf(after - before) > 0


proc main(): int =
  ## Fill pools, run measurands, print measurements, write JSON to path given.
  if paramCount() != 1:
    stderr.write "Usage: bench <output.json>\n"
    return 2
  fillPools(0)
  if isAllocationMeasured() and not controlAllocation():
    stderr.write "Allocation counter inert under -d:nimAllocStats; refusing to report.\n"
    return 1
  measureCatalogue()
  echo "algebra ", ALGEBRA_NAME, " objects ", OBJECTS, " rounds ", ROUNDS, " allocation gauge ",
    (if isAllocationMeasured(): "live" else: "off")
  for index, measurand in CATALOGUE:
    let l = MEASUREMENTS[Implementation.Library][index]
    let r = MEASUREMENTS[Implementation.Reference][index]
    var line = measurand.id.alignLeft(34) & formatFloat(l.ns_median, ffDecimal, 2).align(9) & " ns"
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
