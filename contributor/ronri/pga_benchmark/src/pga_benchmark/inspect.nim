## Read nimcache of one build and write counts of library, reference and dense functions as JSON.
##   `inspect <cache> <output.json> <nim> <pga> <flags>`
##   Compiled once per algebra, as `bench` is, since it carries catalogue: document names
##   every measurand with key of library function its expression calls and key of reference's,
##   so gap list joins measurands to counts without reading any Nim. Functions kept: library's
##   own, whose module names its checkout, typed reference's, and dense forms.
##
##   Cost: reads every C file of cache, megabytes at six dimensions; seconds.
##   Cost: functions sharing stems share key; later ones are numbered by overload index,
##     which compiler assigns in declaration order, so key holds whatever order C emits them
##     in. `{}` instantiates twice, grade then antigrade, as `selectGrade` and
##     `selectGradeAnti` are declared; antigrade is `#u1`.
##   Cost: measurand whose expression composes several calls (motor sandwich) names no library
##     function, so its counts are absent and its gap rests on timing alone.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import std/[algorithm, json, os, strutils, tables]

import pga

import ./[bound, catalogue, inspector, kinds, report]


const
  NAME_ALGEBRA = (if IS_CONFORMAL: "cga" else: "rga") & $DIMENSIONS & "d"
    ## Name of algebra this build inspects; umbrella spells same, kept here to stay entry.
  METRIC = Metric(dimensions: DIMENSIONS, is_conformal: IS_CONFORMAL)
    ## Algebra lower bounds are derived for, spelled from same build definitions library reads.
  MARK_LIBRARY = "illuminatedZpga"
    ## Substring of module suffix of every library module, from its checkout path.
  MARK_REFERENCE = "referenceZ"  ## Prefix of module suffix of every typed reference module.
  MODULE_DENSE = "dense"
    ## Module suffix of dense form module, as bench entry beside it names it.
    ##   Build from elsewhere spells path before it, ending `Zdense`.
  KEY_SELECT = "{}(Multivector,int)"
    ## Key both grade selections share.
    ##   Antigrade's instantiation, second declared, takes key numbered by its overload index.
  KEY_PART = "[](Multivector,Basis)"
    ## Key component read shares with its `var` twin; read is declared first.


func isKept(f: FunctionC): bool =
  ## Decide whether function belongs to library, reference or dense forms, i.e. to gap list.
  MARK_LIBRARY in f.module or f.module.startsWith(MARK_REFERENCE) or
    f.module == MODULE_DENSE or f.module.endsWith("Z" & MODULE_DENSE)


func keyed(functions: seq[FunctionC]): seq[(string, FunctionC)] =
  ## Key kept functions, numbering those sharing stems by overload index.
  ##   Key then holds whatever order compiler emits them in: lowest index keeps bare key,
  ##     others append `#u<n>`.
  ##   `{}` over grade and antigrade, and `[]` read beside its `var` twin, collide.
  var
    groups: Table[string, seq[FunctionC]]
    order: seq[string]
  for f in functions:
    if not f.isKept: continue
    if f.key notin groups: order.add f.key
    groups.mgetOrPut(f.key, @[]).add f
  for key in order:
    var group = groups[key]
    group.sort(proc (a, b: FunctionC): int = cmp(a.overload, b.overload))
    for i, f in group:
      let numbered = if i == 0: key else: key & "#u" & $f.overload
      result.add((numbered, f))


func stemLibrary(k: Kind): string =
  ## Read C stem library takes for operand: `float` for scalar, dense multivector else.
  if k == Kind.Scalar: "float" else: "Multivector"


func stemReference(k: Kind): string =
  ## Read C stem reference takes: `float` for scalar, dense for general, else kind's name.
  if k == Kind.Scalar: "float" elif k == Kind.General: "Multivector" else: $k


func keyLibrary(p: Measurand): string =
  ## Get key of library function measurand's expression calls; empty where it composes several.
  if p.symbol == "{}": return KEY_SELECT & (if "Anti" in p.expression: "#u1" else: "")
  if p.symbol == "[]": return KEY_PART
  let head = p.headEmitted
  if head.len == 0: return ""
  var stems: seq[string]
  for i in 0..<int(p.arity): stems.add stemLibrary(p.operands[i])
  head & "(" & stems.join(",") & ")"


func keyReference(p: Measurand): string =
  ## Get key of reference function measurand names, operands read off argument names.
  let
    open = p.reference.find('(')
    close = p.reference.rfind(')')
  if open < 0 or close < open: return ""
  var stems: seq[string]
  for argument in p.reference[open + 1..<close].split(','):
    case argument.strip
    of "m": stems.add stemReference(p.operands[0])
    of "n": stems.add stemReference(p.operands[1])
    else: discard
  p.reference[0..<open] & "(" & stems.join(",") & ")"


func keyDense(p: Measurand): string =
  ## Get key of dense form of general measurand; empty on typed one, which has none.
  if p.reference.len > 0: return ""
  var stems: seq[string]
  for i in 0..<int(p.arity): stems.add stemLibrary(p.operands[i])
  p.nameDenseOf & "(" & stems.join(",") & ")"


func nodeMeasurands(): JsonNode =
  ## Build catalogue: one object per measurand naming its keys, expression and citation.
  result = newJObject()
  for p in CATALOGUE:
    result[p.id] = %*{
      "symbol": p.symbol,
      "alias": p.alias,
      "arity": int(p.arity),
      "expression": p.expression,
      "library": p.keyLibrary,
      "reference": p.keyReference,
      "dense": p.keyDense,
      "cite": p.cite,
    }
    let b = p.boundOf(METRIC)
    if b.is_derived:
      result[p.id]["bound"] = %*{
        "shape": p.nameShapeOf,
        "is_chain": b.is_chain,
        "steps": p.stepsOf,
        "multiplies": b.multiplies,
        "adds": b.adds,
        "divides": b.divides,
        "roots": b.roots,
        "bytes_moved": b.bytesMoved,
      }


func nodeMissing(): JsonNode =
  ## Build operations reference carries and library lacks.
  result = newJObject()
  for p in MISSING:
    result[p.id] = %*{"symbol": p.symbol, "alias": p.alias, "cite": p.cite}


proc main(): int =
  ## Read cache, count kept functions, write document.
  if paramCount() != 5:
    stderr.write "Usage: inspect <cache> <output.json> <nim> <pga> <flags>\n"
    return 2
  let
    functions = inspectCache(paramStr(1))
    total = totals(functions)
  var taken = takenNow()
  taken["nim"] = %paramStr(3)
  taken["pga"] = %paramStr(4)
  taken["flags"] = %paramStr(5)
  var doc = document(
    "static",
    nodeAlgebra(NAME_ALGEBRA, DIMENSIONS, IS_CONFORMAL, SIZE_MULTIVECTOR),
    taken,
  )
  var
    kept = newJObject()
    count = 0
  for (key, f) in functions.keyed:
    kept[key] = nodeFunction(f, count(f.body), total[f.name], SIZE_MULTIVECTOR)
    inc count
  doc["functions"] = kept
  doc["measurands"] = nodeMeasurands()
  doc["missing"] = nodeMissing()
  writeFile(paramStr(2), pretty(doc) & "\n")
  echo "inspected ", functions.len, " functions, kept ", count, " into ", paramStr(2)
  0


when isMainModule:
  quit main()
