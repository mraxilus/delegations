## Read nimcache of one build and write counts of library, reference and dense functions as JSON.
##   `inspect <cache> <output.json> <nim> <pga> <flags>`
##   Compiled once per algebra, as `bench` is, since it carries catalogue: document names
##   every measurand with key of library function its expression calls and key of reference's,
##   so gap list joins measurands to counts without reading any Nim. Functions kept: library's
##   own, whose module names its checkout, typed reference's, and dense forms. Library generic
##   that timed calls instantiate first carries their module, and is kept by its measurand's head.
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

import std/[json, os, strutils, tables]

import pga

import ./[bound, catalogue, inspector, kinds, report]


const
  NAME_ALGEBRA = (if IS_CONFORMAL: "cga" else: "rga") & $DIMENSIONS & "d"
    ## Name of algebra this build inspects; umbrella spells same, kept here to stay entry.
  METRIC = Metric(dimensions: DIMENSIONS, is_conformal: IS_CONFORMAL)
    ## Algebra lower bounds are derived for, spelled from same build definitions library reads.
  KEY_SELECT = "{}(Multivector,int)"
    ## Key both grade selections share.
    ##   Antigrade's instantiation, second declared, takes key numbered by its overload index.
  KEY_PART = "[](Multivector,Basis)"
    ## Key component read shares with its `var` twin; read is declared first.


func stemLibrary(k: Kind, is_typed: bool): string =
  ## Read C stem library takes for operand: `float` for scalar, motor's stem where typed, since
  ##   catalogue types motor alone, and dense multivector else.
  if k == Kind.Scalar: "float" elif is_typed: STEM_MOTOR else: "Multivector"


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
  for i in 0..<int(p.arity): stems.add stemLibrary(p.operands[i], i in p.typed)
  head & "(" & stems.join(",") & ")"


func keyReference(p: Measurand): string =
  ## Get key of reference function measurand names, operands read off argument names.
  let
    open = p.reference.find('(')
    close = p.reference.rfind(')')
  if open < 0 or close < open: return ""
  var stems: seq[string]
  for argument in p.reference[open+1..<close].split(','):
    case argument.strip
    of "m": stems.add stemReference(p.operands[0])
    of "n": stems.add stemReference(p.operands[1])
    else: discard
  p.reference[0..<open] & "(" & stems.join(",") & ")"


func keyDense(p: Measurand): string =
  ## Get key of dense form of general measurand; empty on typed one, which has none.
  if p.reference.len > 0: return ""
  var stems: seq[string]
  for i in 0..<int(p.arity): stems.add stemLibrary(p.operands[i], is_typed = false)
  p.nameDense & "(" & stems.join(",") & ")"


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
    let b = p.boundLower(METRIC)
    if b.is_derived:
      result[p.id]["bound"] = %*{
        "shape": p.nameShape,
        "is_chain": b.is_chain,
        "steps": p.stepsNamed,
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


func keyedCatalogue*(functions: seq[FunctionC]): seq[(string, FunctionC)] =
  ## Key functions inspector keeps, by heads of catalogue's measurands, as `main` writes them.
  functions.keyed(CATALOGUE.heads)


proc main(): int =
  ## Read cache, count kept functions, write document.
  if paramCount() != 5:
    stderr.write "Usage: inspect <cache> <output.json> <nim> <pga> <flags>\n"
    return 2
  let
    functions = inspectCache(paramStr(1), STEMS_MULTIVECTOR)
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
  for (key, f) in functions.keyedCatalogue:
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
