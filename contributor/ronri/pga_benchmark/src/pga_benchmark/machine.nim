## Call every measurand's library expression once, each in function of its own, so tracer counts
##   machine's work per measurand: `machine <entries.tsv>`.
##   Run under valgrind's `lackey` by `inspect`, which reads trace with `trace.nim`. Writes
##     runtime entry of every wrapper, and of driver calling them, so reader knows where each
##     wrapper's work starts and ends; trace alone names no function.
##   Each wrapper holds one expression and is called across boundary optimiser cannot see
##     through (VII.9): gcc's `noipa` keeps caller from inlining, cloning or dropping call, and
##     wrapper from knowing its operands. Library inlines each operator into every caller, so
##     count of bench names no operator, and count of wrapper does (VII.10).
##   Wrapper is `noinit` and returns expression as `result`, so work counted is operator's own
##     plus what its call site pays there: temporaries, fills and copies of returning by pointer.
##   Every wrapper shares one C file, so `inspect` builds it with no limit gcc sets over whole
##     file; then what gcc inlines into one wrapper depends on that wrapper alone (`verbs.nim`).
##   Operands come from pools of `OBJECTS` each, seeded as bench seeds them; `m` is first and `n`
##     last, so binary measurand never reads one object twice.
##   Library implementation alone: reference and dense forms move with no library change.
##
##   Cost: build is not one that ships, since shipped caller inlines operator; counts are
##     evidence for this build alone (VII.11, IX.6), and driver names it.
##   Cost: `noipa` is gcc's; clang ignores it and may inline wrapper, so build pins gcc.

{.experimental: "strictFuncs".}

import std/[macros, os, strutils]

# Typed references name objects that P09, `object-names`, names in `pga`; reference wins.
import pga except Circle, Dipole, Flector, Line, Motor, Plane, Point, PointRound, Sphere

import ./[catalogue, kinds, pools, trace]


const DECLARATION = "__attribute__((noinline, noipa)) $1 $2$3"
  ## C declaration of wrapper and driver: return type, name, parameters, behind boundary.


macro defineWrapper(index: static int, measurand: static Measurand): untyped =
  ## Define wrapper `wrapper<index>` of one measurand's library expression.
  let
    name = ident("wrapper" & $index)
    body = parseExpr(measurand.expression)
    (m, n) = (ident"m", ident"n")  # plain idents, so expression binds them
    pool_m = parseExpr(namePoolLibrary(measurand.operands[0], measurand.grade))
    pool_n = parseExpr(namePoolLibrary(measurand.operands[1], measurand.grade))
  if measurand.arity == 2:
    quote do:
      proc `name`(`m`: typeof(`pool_m`[0]); `n`: typeof(`pool_n`[0])): auto {.
          noinit, codegenDecl: DECLARATION.} =
        `body`
  else:
    quote do:
      proc `name`(`m`: typeof(`pool_m`[0])): auto {.noinit, codegenDecl: DECLARATION.} =
        `body`


macro defineWrappers(): untyped =
  ## Define every wrapper, driver calling each once in catalogue order, and `entries` listing
  ##   runtime entry of each, driver's first.
  result = newStmtList()
  let
    calls = newStmtList()
    listed = nnkBracket.newTree()
  for index in 0..<CATALOGUE.len:
    let
      measurand = CATALOGUE[index]
      name = ident("wrapper" & $index)
      pool_m = parseExpr(namePoolLibrary(measurand.operands[0], measurand.grade))
      pool_n = parseExpr(namePoolLibrary(measurand.operands[1], measurand.grade))
      id = newLit(measurand.id)
    result.add newCall(
      bindSym"defineWrapper",
      newLit(index),
      newTree(nnkBracketExpr, ident"CATALOGUE", newLit(index)),
    )
    if measurand.arity == 2:
      calls.add quote do:
        discard `name`(`pool_m`[0], `pool_n`[OBJECTS - 1])
    else:
      calls.add quote do:
        discard `name`(`pool_m`[0])
    listed.add quote do:
      (`id`, cast[uint](`name`))
  let symbol = newLit(SYMBOL_DRIVER)
  result.add quote do:
    proc drive() {.exportc: `symbol`, codegenDecl: DECLARATION.} =
      ## Call every wrapper once; results are dropped, and boundary keeps each call.
      `calls`

    proc entries*(): seq[(string, uint)] =
      ## List runtime entry of driver, then of every wrapper by measurand id.
      result = @[(SYMBOL_DRIVER, cast[uint](drive))]
      result.add @`listed`


defineWrappers()


proc main(): int =
  ## Fill pools, write entries to path given, then call every wrapper once.
  if paramCount() != 1:
    stderr.write "Usage: machine <entries.tsv>\n"
    return 2
  fillPools(0)
  var text = ""
  for (name, entry) in entries():
    text.add name & "\t" & entry.toHex.toLowerAscii & "\n"
  writeFile(paramStr(1), text)
  drive()
  0


when isMainModule:
  quit main()
