## Hold that sums, differences and negations copy no set of bases on JS backend (`typed-sums`).
##   Evaluation builds this for Node against changed library at each algebra its claim names;
##     exit code is verdict: no operation copies more than assignment of its result alone.
##   Counts each `nimCopy` call, nested ones too, so count is that of whole operation.
##   At pin, `+` of whole multivectors copies its set of bases at each call there, which this
##     program reads as one copy beyond assignment.

{.experimental: "strictFuncs".}

import std/macros

import pga


var COPIES {.exportc: "copiesCounted".}: int  ## Count of `nimCopy` calls since last reset.

{.emit: """
if (typeof nimCopy === "function") {
  var nimCopyCounted = nimCopy;
  nimCopy = function(dest, src, ti) { copiesCounted += 1; return nimCopyCounted(dest, src, ti); };
}
""".}


const NAMES = ["Multivector", "MultivectorEven", "MultivectorOdd", "MultivectorScalars",
  "Multivector0", "Multivector1", "Multivector2", "Multivector3", "Multivector4", "Multivector5",
  "Multivector6"]
  ## Named types of any algebra; each one algebra lacks is skipped.

var
  FAILURES: seq[string]  ## Label of each operation that copies more than assignment.
  HELD = 0  ## Count of operations held.


proc sample[B: static Bases](t: typedesc[MultivectorOf[B]]): MultivectorOf[B] =
  ## Sample multivector of type `t`, each coefficient its basis's ordinal plus one.
  for b in B: result[b] = Coefficient(ord(b) + 1)


proc record(label: string, counted, baseline: int) =
  ## Record operation whose assignment copies more than assignment of its result alone.
  HELD.inc
  if counted != baseline:
    FAILURES.add label & ": " & $(counted - baseline) & " copies beyond assignment"


template hold(label: string, operation: untyped) =
  ## Hold one operation to copies of plain assignment of value of its type.
  block:
    var r = operation
    let q = r
    COPIES = 0
    r = q
    let baseline = COPIES
    COPIES = 0
    r = operation
    record(label, COPIES, baseline)
    doAssert r =~ r


template holdType(M: typedesc) =
  ## Hold sum, difference and negation of one named type, where library takes each.
  block:
    let (m, n) = (sample(M), sample(M))
    when compiles(m + n): hold($M & " +"): m + n
    when compiles(m - n): hold($M & " -"): m - n
    when compiles(-m): hold("-" & $M): -m


template holdPair(M, N: typedesc) =
  ## Hold sum and difference of two named types, where library takes them.
  block:
    let (m, n) = (sample(M), sample(N))
    when compiles(m + n): hold($M & " + " & $N): m + n
    when compiles(m - n): hold($M & " - " & $N): m - n


macro holdNamed(): untyped =
  ## Hold each named type algebra declares, alone and in each pair.
  result = newStmtList()
  for name in NAMES:
    let kind = ident(name)
    result.add quote do:
      when declared(`kind`): holdType(`kind`)
    for other in NAMES:
      if other == name: continue
      let kind_other = ident(other)
      result.add quote do:
        when declared(`kind`) and declared(`kind_other`): holdPair(`kind`, `kind_other`)


holdNamed()
for failure in FAILURES: echo failure
if FAILURES.len > 0: quit 1
echo DIMENSIONS, "D, conformal ", IS_CONFORMAL, ": ", HELD,
  " operations copy nothing beyond assignment."
