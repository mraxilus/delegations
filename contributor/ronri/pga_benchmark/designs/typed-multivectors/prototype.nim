## Prototype generated k-vector types over library's derived tables (`typed-multivectors`).
##   Trial compiles this against changed library at each algebra its claim names, and exit code
##     is verdict: every law below holds, or program stops on assertion.
##   One macro call generates one concrete object per grade and per parity from `DIMENSIONS`
##     alone. Each stores only its own bases, densely; slot of basis is count of kind's bases
##     below it, folded at compile time. Products are generic over closed typeclass and return
##     smallest kind that holds what table can reach, or library's `Multivector` where none does.
##
##   Cost: prototype generates `∧` and `⟇` alone, and no conformal flat kinds; record says so.

{.experimental: "strictFuncs".}

import std/[macros, random]

import pga
import pga/[algebra {.all.}, cayleys {.all.}]


type Parity {.pure.} = enum
  ## Define halves of algebra by parity of grade.
  Even, Odd


const
  SAMPLES = 256
    ## Seeded samples each law is checked on.
  SEED = 0
    ## Seed of sample generator, so every run checks same samples.



#[ Kinds ]#

func basesOfGrade(g: Grade): set[Basis] {.compileTime.} =
  ## Get bases of one grade.
  for b in Basis:
    if b.grade == g: result.incl b


func basesOfParity(parity: Parity): set[Basis] {.compileTime.} =
  ## Get bases of one parity, i.e. even or odd subalgebra at any dimension.
  for b in Basis:
    if (int(b.grade) mod 2 == 0) == (parity == Parity.Even): result.incl b


func kinds(): seq[(string, set[Basis])] {.compileTime.} =
  ## List every generated kind with its bases, smallest first: grades, then parities.
  for g in Grade.low .. Grade.high: result.add(("Kvector" & $int(g), basesOfGrade(g)))
  result.add(("MultivectorEven", basesOfParity(Parity.Even)))
  result.add(("MultivectorOdd", basesOfParity(Parity.Odd)))


func slotOf(listed: set[Basis], b: Basis): int =
  ## Get dense slot of basis among listed bases, i.e. count of listed bases below it.
  ##   Plain function rather than compile-time one, so runtime bodies can call it too.
  for x in Basis:
    if x == b: return
    if x in listed: inc result


func literal(listed: set[Basis]): NimNode {.compileTime.} =
  ## Spell set of bases as literal, since `quote` cannot embed set value.
  result = nnkCurly.newTree()
  for b in listed: result.add nnkDotExpr.newTree(ident"Basis", ident($b))


macro defineMultivectors(): untyped =
  ## Generate one object per kind, its `bases`, and closed typeclass `SomeMultivector`.
  ##   Typeclass needs explicit type section, since `quote` cannot build infix of types.
  result = newStmtList()
  var names: seq[NimNode]
  for (name, listed) in kinds():
    let (t, spelled) = (ident(name), literal(listed))
    names.add t
    result.add quote do:
      type `t`* = object
        elements*: array[card(`spelled`), float]
      func bases*(T: typedesc[`t`]): set[Basis] = `spelled`
  var class = names[0]
  for t in names[1 .. ^1]: class = infix(class, "|", t)
  result.add nnkTypeSection.newTree(
    nnkTypeDef.newTree(postfix(ident"SomeMultivector", "*"), newEmptyNode(), class)
  )


defineMultivectors()


template `[]`*(m: SomeMultivector, b: static Basis): float =
  ## Read coefficient of basis from its dense slot.
  m.elements[static(slotOf(bases(typeof(m)), b))]


template `[]=`*(m: var SomeMultivector, b: static Basis, value: float) =
  ## Write coefficient of basis into its dense slot.
  m.elements[static(slotOf(bases(typeof(m)), b))] = value



#[ Products ]#

func kindOf(reach: set[Basis]): string {.compileTime.} =
  ## Name smallest kind holding every basis reached; library's `Multivector` where none does.
  for (name, listed) in kinds():
    if reach <= listed: return name
  "Multivector"


macro emitProduct(
  cayley: static Cayley2D; bases_m, bases_n: static set[Basis]; m, n: untyped
): untyped =
  ## Emit block computing product over operands' bases alone, typed as smallest kind.
  ##   Walks whole table and reads only cells both operands name, so no table is copied.
  var
    reach: set[Basis]
    sums: array[Basis, seq[NimNode]]
  for a in bases_m:
    for b in bases_n:
      for term in cayley[a][b]:
        reach.incl term.basis
        let product = infix(
          nnkBracketExpr.newTree(m, nnkDotExpr.newTree(ident"Basis", ident($a))),
          "*",
          nnkBracketExpr.newTree(n, nnkDotExpr.newTree(ident"Basis", ident($b))),
        )
        sums[term.basis].add(if term.is_negated: prefix(product, "-") else: product)
  let product = genSym(nskVar, "product")
  var body = newStmtList(newVarStmt(product, newCall("default", ident(kindOf(reach)))))
  for o in Basis:
    if sums[o].len == 0: continue
    var sum = sums[o][0]
    for term in sums[o][1 .. ^1]: sum = infix(sum, "+", term)
    body.add newAssignment(
      nnkBracketExpr.newTree(product, nnkDotExpr.newTree(ident"Basis", ident($o))), sum
    )
  body.add product
  result = newBlockStmt(body)


func `∧`*[M, N: SomeMultivector](m: M, n: N): auto =
  ## Multiply through exterior product; result is smallest kind holding reach.
  emitProduct(CAYLEYS_WEDGE.base, bases(M), bases(N), m, n)


func `⟇`*[M, N: SomeMultivector](m: M, n: N): auto =
  ## Multiply through geometric antiproduct; result is smallest kind holding reach.
  emitProduct(CAYLEYS_WEDGE_DOT.anti, bases(M), bases(N), m, n)


func toMultivector*[T: SomeMultivector](m: T): Multivector =
  ## Widen generated kind to library's multivector, same coefficients.
  for b in bases(T): result[b] = m.elements[slotOf(bases(T), b)]



#[ Laws ]#

proc sample[T: SomeMultivector](): T =
  ## Draw one kind with every slot uniform in [-1, 1].
  for i in 0 ..< result.elements.len: result.elements[i] = rand(-1.0 .. 1.0)


when isMainModule:
  randomize(SEED)
  let (p, q, v) = (sample[Kvector1](), sample[Kvector1](), sample[MultivectorEven]())
  doAssert (p ∧ q) is Kvector2, "vector wedge vector must be bivector"
  doAssert ((v ⟇ p) ⟇ v) is MultivectorOdd, "even sandwich of vector reaches odd half"
  for _ in 1 .. SAMPLES:
    let
      (a, b) = (sample[Kvector1](), sample[Kvector2]())
      motor = sample[MultivectorEven]()
    doAssert (a ∧ b).toMultivector =~ (a.toMultivector ∧ b.toMultivector)
    doAssert ((motor ⟇ a) ⟇ motor).toMultivector =~
      ((motor.toMultivector ⟇ a.toMultivector) ⟇ motor.toMultivector)
  echo "typed-multivectors: laws hold at ", DIMENSIONS, "D, conformal ", IS_CONFORMAL
