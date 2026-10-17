## Hold laws of basis-set types, as library carrying this change exports them (`exact-kinds`).
##   Evaluation compiles this against library with change applied, at each algebra its claim
##     names, and exit code is verdict: every law below holds, or program stops on assertion.
##   Each product of basis-set types equals library's product on whole multivectors, and its type
##     holds exactly bases its table reaches. Each named basis-set type holds its floats unpadded,
##     aligned to `alignment` of its count.
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
    ## Count of floats of each named basis-set type, from rga3d to cga5d, and its alignment.



#[ Laws ]#

proc sample[B: static set[Basis]](t: typedesc[MultivectorOf[B]]): MultivectorOf[B] =
  ## Sample basis-set type with each coefficient uniform in [-1, 1], narrowed from multivector.
  var m: Multivector
  for basis in B: m[basis] = rand(-1.0..1.0)
  m.toMultivectorOf(t)


macro defineChecksLayout(): untyped =
  ## Define check of size and alignment of each named basis-set type, from its count of bases.
  result = newStmtList()
  let half = 1 shl (DIMENSIONS - 1)
  var named = @[("MultivectorEven", half), ("MultivectorOdd", half)]
  for grade in Grade.low..Grade.high:
    let bases = LUT_BASES_BY_GRADE[grade]
    named.add ("Kvector" & $int(grade), ord(bases.b) - ord(bases.a) + 1)
  for (name, count) in named:
    let
      alias = ident(name)
      (size, aligned) = (sizeof(float) * count, alignment(count))
    result.add quote do:
      doAssert sizeof(`alias`) == `size`,
        `name` & " must hold its floats unpadded; got `" & $sizeof(`alias`) & "`."
      doAssert alignof(`alias`) == `aligned`,
        `name` & " must align to alignment of its count; got `" & $alignof(`alias`) & "`."


proc holdAlignment() =
  ## Hold alignment of every count of floats, then of each count named basis-set types reach.
  for count in 0..64:
    let (size, aligned) = (sizeof(float) * count, alignment(count))
    doAssert aligned in [8, 16, 32, 64], &"Alignment must be power of two; got `{aligned}`."
    doAssert size mod aligned == 0, &"Alignment must pad no count; got `{aligned}` at `{count}`."
    doAssert count == 0 or aligned == 64 or size mod (2 * aligned) != 0,
      &"Alignment must be largest that pads none; got `{aligned}` at `{count}`."
  for (count, aligned) in ALIGNMENTS_NAMED:
    doAssert alignment(count) == aligned,
      &"Named type must align as proposal tables it; got `{alignment(count)}` at `{count}`."


proc main(): int =
  ## Hold laws on seeded samples; print where they hold, and exit zero.
  randomize(SEED)
  holdAlignment()
  defineChecksLayout()
  var written = sample(Kvector1)
  let
    (p, q) = (sample(Kvector1), sample(Kvector1))
    (m, n) = (sample(MultivectorOf[{Basis.low..Basis.high}]),
        sample(MultivectorOf[{Basis.low..Basis.high}]))
    bivector = sample(Kvector2)
    even = sample(MultivectorEven)
    top = sample(MultivectorOf[{Basis.scalarAnti}])
  doAssert alignof(typeof(∙bivector)) == alignment(card(bases(typeof(∙bivector)))),
    "Type product returns must align by same rule as named ones."
  doAssert (p ∧ q) is Kvector2, "Vector wedge vector must be bivector, equal to its alias."
  doAssert ($typeof(p ∧ q)).startsWith("MultivectorOf[{"),
    "Alias must add no type, so type prints as generic with its bases."
  echo "exact-kinds: vector wedge vector prints as ", $typeof(p ∧ q)
  doAssert (m ∙ n) is MultivectorOf[{Basis.scalar}], "Dot of whole multivectors must be scalar."
  doAssert sizeof(m ∙ n) == sizeof(float), "Dot must write one slot, never whole multivector."
  doAssert sizeof(m ∘ n) == sizeof(float), "Antidot must write one slot, never whole multivector."
  doAssert sizeof(∘p) == sizeof(float), "Weight of vector must write one slot."
  doAssert sizeof(∙m) * (when IS_RIGID: 2 else: 4) == sizeof(Multivector),
    "Bulk of whole must hold half of bases under rigid metric, and quarter under conformal."
  doAssert ((even ⟇ p) ⟇ even) is MultivectorOdd,
    "Sandwich of vector must reach whole odd parity, as table can produce."
  echo "exact-kinds: bytes of m ∙ n ", sizeof(m ∙ n), ", m ∘ n ", sizeof(m ∘ n), ", ∙ bivector ",
    sizeof(∙bivector), ", ∘ vector ", sizeof(∘p), ", ∙ whole ", sizeof(∙m), ", sandwich ",
    sizeof((even ⟇ p) ⟇ even), ", library ", sizeof(Multivector)
  doAssert bases(typeof(∙bivector)) < bases(Kvector2), "Bulk of bivector must be part of grade."
  when IS_RIGID:
    doAssert bases(typeof(∙bivector)) + bases(typeof(∘bivector)) == bases(Kvector2),
      "Bulk and weight of bivector must cover its grade, under rigid metric."
  doAssert card(bases(typeof(top ∧ top))) == 0 and (top ∧ top).toMultivector =~ 0.0,
    "Product that reaches no basis must hold no coefficient, and widen to zero."
  doAssert not compiles(p[Basis.scalar]) and not compiles(written[Basis.scalar] = 1.0),
    "Basis outside bases of type must stop compile, never reach another slot."
  var expected = written.toMultivector
  written[Basis.vectorLast] = 1.0
  expected[Basis.vectorLast] = 1.0
  doAssert written.toMultivector =~ expected, "Write must reach slot of its basis alone."
  var read: Multivector
  for basis in Basis: read[basis] = bivector.coefficient(basis)
  doAssert read =~ bivector.toMultivector, "Read at run time must equal widened, zero outside."
  doAssert even.toMultivector.toMultivectorOf(MultivectorEven).toMultivector =~
      even.toMultivector,
    "Narrow of widened must return same coefficients."
  doAssertRaises(AssertionDefect): discard m.toMultivector.toMultivectorOf(Kvector1)
  doAssert wedge(p, q).toMultivector =~ (p ∧ q).toMultivector, "Alias must forward to operator."
  for _ in 1..SAMPLES:
    let
      (a, b) = (sample(Kvector1), sample(Kvector2))
      (u, v) = (sample(MultivectorOf[{Basis.low..Basis.high}]),
          sample(MultivectorOf[{Basis.low..Basis.high}]))
      motor = sample(MultivectorEven)
    doAssert (a ∧ b).toMultivector =~ (a.toMultivector ∧ b.toMultivector),
      &"Wedge must equal library's; got `{(a ∧ b).toMultivector}`."
    doAssert ((motor ⟇ a) ⟇ motor).toMultivector =~
        ((motor.toMultivector ⟇ a.toMultivector) ⟇ motor.toMultivector),
      &"Antiproduct must equal library's; got `{((motor ⟇ a) ⟇ motor).toMultivector}`."
    doAssert (u ∙ v).toMultivector =~ (u.toMultivector ∙ v.toMultivector),
      &"Dot must equal library's; got `{(u ∙ v).toMultivector}`."
    doAssert (u ∘ v).toMultivector =~ (u.toMultivector ∘ v.toMultivector),
      &"Antidot must equal library's; got `{(u ∘ v).toMultivector}`."
    doAssert (∙b).toMultivector =~ ∙b.toMultivector,
      &"Bulk must equal library's; got `{(∙b).toMultivector}`."
    doAssert (∘b).toMultivector =~ ∘b.toMultivector,
      &"Weight must equal library's; got `{(∘b).toMultivector}`."
  echo "exact-kinds: laws hold at ", DIMENSIONS, "D, conformal ", IS_CONFORMAL
  0


when isMainModule:
  quit main()
