## Read nimcache of one build and write counts of library and reference functions as JSON.
##   `inspect <cache> <output.json> <nim> <pga> <flags>`
##   Compiled once per algebra, as `bench` is, since it carries catalogue: document names
##   every measurand with key of library function its expression calls and key of reference's,
##   so gap list joins measurands to counts without reading any Nim. Functions kept: library's
##   own, whose module names its checkout, and typed reference's.
##
##   Cost: reads every C file of cache, megabytes at six dimensions; seconds.
##   Cost: `{}` instantiates twice, grade then antigrade, in order `selectGrade` and
##     `selectGradeAnti` are declared in library umbrella; antigrade takes second key.
##   Cost: measurand whose expression composes several calls (motor sandwich) names no library
##     function, so its counts are absent and its gap rests on timing alone.

{.experimental: "strictFuncs".}

import std/[json, os, strutils, tables]

import pga

import ./[catalogue, inspector, kinds, report]


const
  ALGEBRA_NAME = (if IS_CONFORMAL: "cga" else: "rga") & $DIMENSIONS & "d"
    ## Name of algebra this build inspects; umbrella spells same, kept here to stay entry.
  LIBRARY_MARK = "illuminatedZpga"
    ## Substring of module suffix of every library module, from its checkout path.
  REFERENCE_MARK = "referenceZ"
    ## Prefix of module suffix of every typed reference module.
  KEY_SELECT = "{}(Multivector,int)"
    ## Key both grade selections share; antigrade's instantiation takes numbered one.
  KEY_PART = "[](Multivector,Basis)"
    ## Key component read shares with its `var` twin; read is declared first.


func isKept(f: CFunction): bool =
  ## Decide whether function belongs to library or reference, i.e. to gap list.
  LIBRARY_MARK in f.module or f.module.startsWith(REFERENCE_MARK)


func libraryStem(k: Kind): string =
  ## Read C stem library takes for operand: `float` for scalar, dense multivector else.
  if k == Kind.Scalar: "float" else: "Multivector"


func referenceStem(k: Kind): string =
  ## Read C stem reference takes: `float` for scalar, dense for general, else kind's name.
  if k == Kind.Scalar: "float" elif k == Kind.General: "Multivector" else: $k


func libraryKey(p: Measurand): string =
  ## Key of library function measurand's expression calls; empty where it composes several.
  if p.symbol == "{}": return KEY_SELECT & (if "Anti" in p.expression: "#2" else: "")
  if p.symbol == "[]": return KEY_PART
  let head =
    if p.symbol.len > 0: p.emitted
    elif p.alias.len > 0 and p.expression.startsWith(p.alias & "("): p.alias
    else: return ""
  var stems: seq[string]
  for i in 0 ..< int(p.arity): stems.add libraryStem(p.operands[i])
  head & "(" & stems.join(",") & ")"


func referenceKey(p: Measurand): string =
  ## Key of reference function measurand names, operands read off argument names.
  let open = p.reference.find('(')
  let close = p.reference.rfind(')')
  if open < 0 or close < open: return ""
  var stems: seq[string]
  for arg in p.reference[open + 1 ..< close].split(','):
    case arg.strip
    of "m": stems.add referenceStem(p.operands[0])
    of "n": stems.add referenceStem(p.operands[1])
    else: discard
  p.reference[0 ..< open] & "(" & stems.join(",") & ")"


func measurandsNode(): JsonNode =
  ## Shape catalogue: one object per measurand naming both keys, expression and citation.
  result = newJObject()
  for p in CATALOGUE:
    result[p.id] = %*{
      "symbol": p.symbol,
      "alias": p.alias,
      "arity": int(p.arity),
      "expression": p.expression,
      "library": p.libraryKey,
      "reference": p.referenceKey,
      "cite": p.cite,
    }


func missingNode(): JsonNode =
  ## Shape operations reference carries and library lacks.
  result = newJObject()
  for p in MISSING:
    result[p.id] = %*{"symbol": p.symbol, "alias": p.alias, "cite": p.cite}


proc main(): int =
  ## Read cache, count kept functions, write document.
  if paramCount() != 5:
    stderr.write "Usage: inspect <cache> <output.json> <nim> <pga> <flags>\n"
    return 2
  let functions = inspectCache(paramStr(1))
  let total = totals(functions)
  var taken = takenNow()
  taken["nim"] = %paramStr(3)
  taken["pga"] = %paramStr(4)
  taken["flags"] = %paramStr(5)
  var doc = document(
    "static", algebraNode(ALGEBRA_NAME, DIMENSIONS, IS_CONFORMAL, SIZE_MULTIVECTOR), taken
  )
  var kept = newJObject()
  var count = 0
  for f in functions:
    if not f.isKept: continue
    # Instantiations sharing stems (`{}` over grade and antigrade) share key too; second and
    # later take numbered key, in emission order, which is instantiation order.
    var key = f.key
    var n = 1
    while kept.hasKey(key):
      inc n
      key = f.key & "#" & $n
    kept[key] = functionNode(f, count(f.body), total[f.name], SIZE_MULTIVECTOR)
    inc count
  doc["functions"] = kept
  doc["measurands"] = measurandsNode()
  doc["missing"] = missingNode()
  writeFile(paramStr(2), pretty(doc) & "\n")
  echo "inspected ", functions.len, " functions, kept ", count, " into ", paramStr(2)
  0


when isMainModule:
  quit main()
