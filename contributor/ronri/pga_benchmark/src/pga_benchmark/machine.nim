## Call every measurand's library expression once, each in function of its own, so tracer counts
##   machine's work per measurand: `machine <entries.tsv>`.
##   Run under valgrind's `lackey` by `inspect`, which reads trace with `trace.nim`. Writes
##     runtime entry of every wrapper, and of driver calling them, so reader knows where each
##     wrapper's work starts and ends; trace alone names no function.
##   Each wrapper has copy, later in same C file, on same operands. Copy must read counts of its
##     original, so `guard` finds wrapper whose count moves with code around it (`guard.nim`).
##     Rejected: twin of same C over other operands, since operator such as `⊛` branches on
##     kind of its operand, and twins then read apart with no coupling.
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


macro defineWrapper(name: untyped; measurand: static Measurand): untyped =
  ## Define wrapper of one measurand's library expression, under name given.
  let
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
  ## Define every wrapper and its copy, driver calling each once, and `entries` listing runtime
  ##   entry of each, driver's first.
  ##   Originals come in catalogue order, then copies in same order, in definition, call and list
  ##     alike, so each copy stands later in same C file than its original.
  result = newStmtList()
  let
    calls = newStmtList()
    listed = nnkBracket.newTree()
  for is_copy in [false, true]:
    for index in 0..<CATALOGUE.len:
      let
        measurand = CATALOGUE[index]
        name = ident((if is_copy: "copy" else: "wrapper") & $index)
        pool_m = parseExpr(namePoolLibrary(measurand.operands[0], measurand.grade))
        pool_n = parseExpr(namePoolLibrary(measurand.operands[1], measurand.grade))
        id = newLit(measurand.id)
        copy = newLit(is_copy)
      result.add newCall(
        bindSym"defineWrapper",
        name,
        newTree(nnkBracketExpr, ident"CATALOGUE", newLit(index)),
      )
      if measurand.arity == 2:
        calls.add quote do:
          discard `name`(`pool_m`[0], `pool_n`[OBJECTS - 1])
      else:
        calls.add quote do:
          discard `name`(`pool_m`[0])
      listed.add quote do:
        Entry(name: `id`, address: cast[uint](`name`), is_copy: `copy`)
  let symbol = newLit(SYMBOL_DRIVER)
  result.add quote do:
    proc drive() {.exportc: `symbol`, codegenDecl: DECLARATION.} =
      ## Call every wrapper once, then every copy; results are dropped, and boundary keeps each.
      `calls`

    proc entries*(): seq[Entry] =
      ## List runtime entry of driver, then of every wrapper by measurand id, then every copy.
      result = @[Entry(name: SYMBOL_DRIVER, address: cast[uint](drive))]
      result.add @`listed`


defineWrappers()


proc main(): int =
  ## Fill pools, write entries to path given, then call every wrapper once.
  if paramCount() != 1:
    stderr.write "Usage: machine <entries.tsv>\n"
    return 2
  fillPools(0)
  var text = ""
  for entry in entries():
    text.add entry.name & "\t" & entry.address.toHex.toLowerAscii & "\t" &
        (if entry.is_copy: "copy" else: "") & "\n"
  writeFile(paramStr(1), text)
  drive()
  0


when isMainModule:
  quit main()
