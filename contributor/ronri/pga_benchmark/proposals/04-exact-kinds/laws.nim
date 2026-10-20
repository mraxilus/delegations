## Hold laws of basis-set types, as library carrying this change exports them (`exact-kinds`).
##   Evaluation compiles this against library with change applied, at each algebra its claim
##     names, and exit code is verdict: every law below holds, or program stops on assertion.
##   Each product of basis-set types equals library's product on whole multivectors, and its type
##     holds exactly bases its table reaches. Each named basis-set type holds its coefficients
##     unpadded, aligned to `alignment` of its count.
##   Samples narrow multivector of library to each type, so laws reach no private field.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[macros, random, strformat, strutils]

import pga


const
  SAMPLES = 256  ## Seeded samples each law is checked on.
  SEED = 0  ## Seed of sample generator, so every run checks same samples.
  ALIGNMENTS_NAMED = [(3, 8), (4, 32), (5, 8), (6, 16), (8, 64), (10, 16), (16, 64)]
    ## Count of coefficients of each named basis-set type, rga3d to cga5d, aligned at 64 bits.



#[ Laws ]#

func bases[B: static Bases](t: typedesc[MultivectorOf[B]]): Bases = B
  ## Get bases basis-set type holds.


proc sample[B: static Bases](t: typedesc[MultivectorOf[B]]): MultivectorOf[B] =
  ## Sample basis-set type with each coefficient uniform in [-1, 1], narrowed from multivector.
  var m: Multivector
  for basis in B: m[basis] = Coefficient(rand(-1.0..1.0))
  toMultivectorOf[bases(Multivector), B](m)


macro defineChecksLayout(): untyped =
  ## Define check of size and alignment of each named basis-set type, from its count of bases.
  result = newStmtList()
  let half = 1 shl (DIMENSIONS - 1)
  var named = @[("MultivectorEven", half), ("MultivectorOdd", half)]
  for grade in Grade.low..Grade.high:
    let bases = LUT_BASES_BY_GRADE[grade]
    named.add ("Multivector" & $int(grade), ord(bases.b) - ord(bases.a) + 1)
  for (name, count) in named:
    let
      alias = ident(name)
      (size, aligned) = (sizeof(Coefficient) * count, alignment(count))
    result.add quote do:
      doAssert sizeof(`alias`) == `size`,
        `name` & " must hold its coefficients unpadded; got `" & $sizeof(`alias`) & "`."
      doAssert alignof(`alias`) == `aligned`,
        `name` & " must align to alignment of its count; got `" & $alignof(`alias`) & "`."


proc holdAlignment() =
  ## Hold alignment of every count of coefficients, then of each count named types reach.
  for count in 0..64:
    let (size, aligned) = (sizeof(Coefficient) * count, alignment(count))
    doAssert aligned in [4, 8, 16, 32, 64], &"Alignment must be power of two; got `{aligned}`."
    doAssert size mod aligned == 0, &"Alignment must pad no count; got `{aligned}` at `{count}`."
    doAssert count == 0 or aligned == 64 or size mod (2 * aligned) != 0,
      &"Alignment must be largest that pads none; got `{aligned}` at `{count}`."
  for (count, aligned) in ALIGNMENTS_NAMED:
    if sizeof(Coefficient) != 8: break  # Table holds 64-bit coefficients.
    doAssert alignment(count) == aligned,
      &"Named type must align as proposal tables it; got `{alignment(count)}` at `{count}`."


proc main(): int =
  ## Hold laws on seeded samples; print where they hold, and exit zero.
  randomize(SEED)
  holdAlignment()
  defineChecksLayout()
  let
    (p, q) = (sample(Multivector1), sample(Multivector1))
    (m, n) = (sample(Multivector), sample(Multivector))
    bivector = sample(Multivector2)
    even = sample(MultivectorEven)
    top = sample(MultivectorOf[{Basis.scalarAnti}])
  doAssert alignof(typeof(p ∧ m)) == alignment(card(bases(typeof(p ∧ m)))),
    "Type product returns must align by same rule as named ones."
  doAssert (p ∧ q) is Multivector2, "Vector wedge vector must be bivector, equal to its alias."
  doAssert ($typeof(p ∧ q)).startsWith("MultivectorOf[{"),
    "Alias must add no type, so type prints as generic with its bases."
  echo "exact-kinds: vector wedge vector prints as ", $typeof(p ∧ q)
  doAssert (m ∙ n) is Multivector,
    "Product of two whole multivectors must stay library's, so no caller sees change."
  doAssert (p ∙ m) is Multivector0, "Dot of vector and whole multivector must be scalar."
  doAssert ((p ∧ q) ⟇ (m ∧ n)) is Multivector,
    "Product that reaches every basis must be `Multivector`, so library takes it."
  doAssert sizeof(p ∙ m) == sizeof(Coefficient),
    "Dot must write one coefficient, never whole multivector."
  doAssert sizeof(p ∘ m) == sizeof(Coefficient),
    "Antidot must write one coefficient, never whole multivector."
  doAssert sizeof(∘p) == sizeof(Coefficient), "Weight of vector must write one coefficient."
  doAssert (∙m) is Multivector, "Bulk of whole multivector must stay library's."
  doAssert ((even ⟇ p) ⟇ even) is MultivectorOdd,
    "Sandwich of vector must reach whole odd parity, as table can produce."
  echo "exact-kinds: bytes of p ∙ m ", sizeof(p ∙ m), ", p ∘ m ", sizeof(p ∘ m), ", ∙ bivector ",
    (when compiles(∙bivector): sizeof(∙bivector) else: 0), ", ∘ vector ", sizeof(∘p),
    ", ∙ whole ", sizeof(∙m), ", sandwich ", sizeof((even ⟇ p) ⟇ even), ", library ",
    sizeof(Multivector)
  # Bivectors hold no bulk at rga2d, where grade 2 is antiscalar, nor at cga3d.
  when compiles(∙bivector):
    doAssert bases(typeof(∙bivector)) < bases(Multivector2),
      "Bulk of bivector must be part of grade."
    when IS_RIGID:
      doAssert bases(typeof(∙bivector)) + bases(typeof(∘bivector)) == bases(Multivector2),
        "Bulk and weight of bivector must cover its grade, under rigid metric."
  doAssert not compiles(top ∧ top), "Product that reaches no basis must stop compile."
  doAssert not compiles(p[Basis.scalar]),
    "Static basis outside bases of type must stop compile, so product reads fixed indexes alone."
  doAssert wedge(p, q).toMultivector =~ (p ∧ q).toMultivector, "Alias must forward to operator."
  for _ in 1..SAMPLES:
    let
      (a, b, c) = (sample(Multivector1), sample(Multivector2), sample(Multivector1))
      (u, v) = (sample(MultivectorOdd), sample(Multivector))
      motor = sample(MultivectorEven)
    doAssert (a ∧ c).toMultivector =~ (a.toMultivector ∧ c.toMultivector),
      &"Wedge must equal library's; got `{(a ∧ c).toMultivector}`."
    when compiles(a ∧ b):  # Vector wedge bivector reaches no basis at rga2d.
      doAssert (a ∧ b).toMultivector =~ (a.toMultivector ∧ b.toMultivector),
        &"Wedge must equal library's; got `{(a ∧ b).toMultivector}`."
    doAssert ((motor ⟇ a) ⟇ motor).toMultivector =~
        ((motor.toMultivector ⟇ a.toMultivector) ⟇ motor.toMultivector),
      &"Antiproduct must equal library's; got `{((motor ⟇ a) ⟇ motor).toMultivector}`."
    doAssert (u ∙ v).toMultivector =~ (u.toMultivector ∙ v.toMultivector),
      &"Dot must equal library's; got `{(u ∙ v).toMultivector}`."
    doAssert (u ∘ v).toMultivector =~ (u.toMultivector ∘ v.toMultivector),
      &"Antidot must equal library's; got `{(u ∘ v).toMultivector}`."
    when compiles(∙b):
      doAssert (∙b).toMultivector =~ ∙b.toMultivector,
        &"Bulk must equal library's; got `{(∙b).toMultivector}`."
    when compiles(∘b):
      doAssert (∘b).toMultivector =~ ∘b.toMultivector,
        &"Weight must equal library's; got `{(∘b).toMultivector}`."
  echo "exact-kinds: laws hold at ", DIMENSIONS, "D, conformal ", IS_CONFORMAL
  0


when isMainModule:
  quit main()
