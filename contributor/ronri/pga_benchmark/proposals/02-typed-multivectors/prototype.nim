## Prototype generated k-vector types over library's derived tables (`typed-multivectors`).
##   Evaluation compiles this against changed library at each algebra its claim names, and exit code
##     is verdict: every law below holds, or program stops on assertion.
##   One macro call generates one concrete object per grade and per parity from `DIMENSIONS`
##     alone. Each stores only its own bases, densely; slot of basis is count of kind's bases
##     below it, folded at compile time. Products are generic over closed typeclass and return
##     smallest kind that holds what table can reach, or library's `Multivector` where none does.
##
##   Cost: prototype generates `∧` and `⟇` alone, and no conformal flat kinds; record says so.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import std/[macros, random]

import pga
import pga/[algebra {.all.}, cayleys {.all.}]


type Parity {.pure.} = enum  ## Define halves of algebra by parity of grade.
  Even, Odd


const
  SAMPLES = 256  ## Seeded samples each law is checked on.
  SEED = 0  ## Seed of sample generator, so every run checks same samples.



#[ Kinds ]#

func basesOfGrade(grade: Grade): set[Basis] {.compileTime.} =
  ## Get bases of one grade.
  for basis in Basis:
    if basis.grade == grade: result.incl basis


func basesOfParity(parity: Parity): set[Basis] {.compileTime.} =
  ## Get bases of one parity: even or odd subalgebra at any dimension.
  for basis in Basis:
    if (int(basis.grade) mod 2 == 0) == (parity == Parity.Even): result.incl basis


func kinds(): seq[(string, set[Basis])] {.compileTime.} =
  ## List every generated kind with its bases, smallest first: grades, then parities.
  for grade in Grade.low..Grade.high:
    result.add ("Kvector" & $int(grade), basesOfGrade(grade))
  result.add ("MultivectorEven", basesOfParity(Parity.Even))
  result.add ("MultivectorOdd", basesOfParity(Parity.Odd))


func slotOf(listed: set[Basis], basis: Basis): int =
  ## Get dense slot of basis among listed bases: count of listed bases below it.
  ##   Plain function rather than compile-time one, so runtime bodies can call it too.
  for other in Basis:
    if other == basis: return
    if other in listed: inc result


func literal(listed: set[Basis]): NimNode {.compileTime.} =
  ## Spell set of bases as literal, since `quote` cannot embed set value.
  result = nnkCurly.newTree()
  for basis in listed: result.add nnkDotExpr.newTree(ident"Basis", ident($basis))


macro defineMultivectors(): untyped =
  ## Generate one object per kind, its `bases`, and closed typeclass `SomeMultivector`.
  ##   Typeclass needs explicit type section, since `quote` cannot build infix of types.
  result = newStmtList()
  var names: seq[NimNode]
  for (name, listed) in kinds():
    let (kind, spelled) = (ident(name), literal(listed))
    names.add kind
    result.add quote do:
      type `kind`* = object
        elements*: array[card(`spelled`), float]
      func bases*(kind_type: typedesc[`kind`]): set[Basis] = `spelled`
  var class = names[0]
  for kind in names[1 .. ^1]: class = infix(class, "|", kind)
  result.add nnkTypeSection.newTree(
    nnkTypeDef.newTree(postfix(ident"SomeMultivector", "*"), newEmptyNode(), class),
  )


defineMultivectors()


template `[]`*(m: SomeMultivector, basis: static Basis): float =
  ## Read coefficient of basis from its dense slot.
  m.elements[static(slotOf(bases(typeof(m)), basis))]


template `[]=`*(m: var SomeMultivector, basis: static Basis, value: float) =
  ## Write coefficient of basis into its dense slot.
  m.elements[static(slotOf(bases(typeof(m)), basis))] = value



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
  for left in bases_m:
    for right in bases_n:
      for term in cayley[left][right]:
        reach.incl term.basis
        let product = infix(
          nnkBracketExpr.newTree(m, nnkDotExpr.newTree(ident"Basis", ident($left))),
          "*",
          nnkBracketExpr.newTree(n, nnkDotExpr.newTree(ident"Basis", ident($right))),
        )
        sums[term.basis].add(if term.is_negated: prefix(product, "-") else: product)
  let product = genSym(nskVar, "product")
  var body = newStmtList(newVarStmt(product, newCall("default", ident(kindOf(reach)))))
  for basis in Basis:
    if sums[basis].len == 0: continue
    var sum = sums[basis][0]
    for term in sums[basis][1 .. ^1]: sum = infix(sum, "+", term)
    body.add newAssignment(
      nnkBracketExpr.newTree(product, nnkDotExpr.newTree(ident"Basis", ident($basis))),
      sum,
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
  for basis in bases(T): result[basis] = m.elements[slotOf(bases(T), basis)]



#[ Laws ]#

proc sample[T: SomeMultivector](): T =
  ## Draw one kind with every slot uniform in [-1, 1].
  for index in 0..<result.elements.len: result.elements[index] = rand(-1.0..1.0)


proc main(): int =
  ## Hold laws on seeded samples; print where they hold, and exit zero.
  randomize(SEED)
  let (p, q, v) = (sample[Kvector1](), sample[Kvector1](), sample[MultivectorEven]())
  doAssert (p ∧ q) is Kvector2, "vector wedge vector must be bivector"
  doAssert ((v ⟇ p) ⟇ v) is MultivectorOdd, "even sandwich of vector reaches odd half"
  for _ in 1..SAMPLES:
    let
      (a, b) = (sample[Kvector1](), sample[Kvector2]())
      motor = sample[MultivectorEven]()
    doAssert (a ∧ b).toMultivector =~ (a.toMultivector ∧ b.toMultivector)
    doAssert ((motor ⟇ a) ⟇ motor).toMultivector =~
        ((motor.toMultivector ⟇ a.toMultivector) ⟇ motor.toMultivector)
  echo "typed-multivectors: laws hold at ", DIMENSIONS, "D, conformal ", IS_CONFORMAL
  0


when isMainModule:
  quit main()
