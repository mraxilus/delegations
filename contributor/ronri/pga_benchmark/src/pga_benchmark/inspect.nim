## Read nimcache of one build and write counts of library and reference functions as JSON.
##   `inspect <cache> <output.json> <config> <dimensions> <is_conformal> <nim> <pga> <flags>`
##   Imports no library, so driver compiles it once and runs it over every configuration's
##   cache; configuration is named on command line and copied into document header.
##   Functions kept: library's own (module names its checkout), typed reference's, and
##   library generics instantiated where probes live, which is where `{}` lands.
##
##   Cost: reads every C file of cache, megabytes at six dimensions; seconds.

{.experimental: "strictFuncs".}

import std/[json, os, strutils, tables]

import ./[inspector, report]


const
  LIBRARY_MARK = "illuminatedZpga"
    ## Substring of module suffix of every library module, from its checkout path.
  REFERENCE_MARK = "referenceZ"
    ## Prefix of module suffix of every typed reference module.
  PROBES_MODULE = "probes"
    ## Module generics instantiate into; library's `{}` is read there.


func isKept(f: CFunction): bool =
  ## Decide whether function belongs to library or reference, i.e. to gap list.
  LIBRARY_MARK in f.module or f.module.startsWith(REFERENCE_MARK) or
    (f.module == PROBES_MODULE and f.symbol == "{}")


proc main(): int =
  ## Read cache, count kept functions, write document.
  if paramCount() != 8:
    stderr.write(
      "Usage: inspect <cache> <output.json> <config> <dimensions> <is_conformal> <nim> " &
      "<pga> <flags>\n"
    )
    return 2
  let cache = paramStr(1)
  let dimensions = parseInt(paramStr(4))
  let size_multivector = 8 * (1 shl dimensions)
  let functions = inspectCache(cache)
  let total = totals(functions)
  var taken = takenNow()
  taken["nim"] = %paramStr(6)
  taken["pga"] = %paramStr(7)
  taken["flags"] = %paramStr(8)
  var doc = document(
    "inspect",
    configNode(paramStr(3), dimensions, paramStr(5) == "true", size_multivector),
    taken,
  )
  var kept = newJObject()
  var count = 0
  for f in functions:
    if not f.isKept: continue
    # Generic instantiations sharing stems (`{}` over grade and antigrade) share key too;
    # second and later take numbered key, in emission order, which is declaration order.
    var key = f.key
    var n = 1
    while kept.hasKey(key):
      inc n
      key = f.key & "#" & $n
    kept[key] = functionNode(f, count(f.body), total[f.name], size_multivector)
    inc count
  doc["functions"] = kept
  writeFile(paramStr(2), pretty(doc) & "\n")
  echo "inspected ", functions.len, " functions, kept ", count, " into ", paramStr(2)
  0


when isMainModule:
  quit main()
