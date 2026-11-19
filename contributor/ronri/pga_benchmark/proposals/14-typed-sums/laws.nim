## Hold sums and differences of any two named types to their rule (`typed-sums`).
##   Evaluation compiles this against changed library at each algebra its claim names; exit code
##     is verdict: every law below holds, or program stops on assertion.
##   Laws: for named types P and Q, each coefficient of 𝐦 + 𝐧 and 𝐦 − 𝐧 is sum or difference of
##     coefficients at that basis, absent one read as zero; result is P where P is Q, else exact
##     union of their bases, as named type with exactly those bases where one has them.
##   −𝐦 keeps its type; s + 𝐦, 𝐦 + s, s − 𝐦 and 𝐦 − s hold bases of 𝐦 and scalar, by same rule.
##   Pairs sweep every named type algebra declares with every one, on either side.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[macros, random, strformat]

import pga


const
  SAMPLES = 256  ## Seeded samples each law is checked on.
  SEED = 0  ## Seed of sample generator, so every run checks same samples.
  NAMES = ["Multivector0", "Multivector1", "Multivector2", "Multivector3", "Multivector4",
    "Multivector5", "Multivector6", "MultivectorEven", "MultivectorOdd", "MultivectorScalars",
    "Multivector"]
    ## Named types of any algebra, in order library lists them; each algebra lacks is skipped.


func basesType[B: static Bases](t: typedesc[MultivectorOf[B]]): Bases =
  ## Read bases of basis-set type.
  B


proc sample[B: static Bases](r: var Rand, t: typedesc[MultivectorOf[B]]): MultivectorOf[B] =
  ## Draw sample over bases of `t`; each coefficient uniform in [-1, 1].
  for b in B: result[b] = r.rand(-1.0 .. 1.0)


func coefficientOr[B: static Bases](m: MultivectorOf[B], b: Basis): float =
  ## Read coefficient of basis, or zero where type lacks it.
  if b in B: float(m[b]) else: 0.0


func basesExpected(a, b: Bases): Bases =
  ## Choose bases rule gives sum of types over `a` and `b`: exact union of both.
  a + b


macro holdTypeNamed(value: typed, expected: static Bases): untyped =
  ## Hold that value whose bases some named type has exactly takes that named type.
  ##   Nim compares static sets as written, so equal sets spelled apart would be two types.
  result = newStmtList()
  for name in NAMES:
    let kind = ident(name)
    result.add quote do:
      when declared(`kind`):
        when basesType(`kind`) == `expected`:
          doAssert typeof(`value`) is `kind`, "Named bases must take named type; got " &
            $typeof(`value`) & "."


template holdPair(r: var Rand, M, N: typedesc) =
  ## Hold sum and difference of one pair of types, and negation of first, on each sample.
  block:
    const expected = basesExpected(basesType(M), basesType(N))
    for _ in 0 ..< SAMPLES:
      let
        m = r.sample(M)
        n = r.sample(N)
        (sum, difference, negation) = (m + n, m - n, -m)
      doAssert basesType(typeof(sum)) == expected and basesType(typeof(difference)) == expected,
        "Sum and difference must take bases rule gives; got " & $typeof(sum) & "."
      holdTypeNamed(sum, expected)
      holdTypeNamed(difference, expected)
      doAssert typeof(negation) is M, "Negation must keep type of operand."
      for b in Basis:
        let (x, y) = (m.coefficientOr(b), n.coefficientOr(b))
        doAssert sum.coefficientOr(b) == x + y, "Sum must add coefficients at each basis."
        doAssert difference.coefficientOr(b) == x - y,
          "Difference must subtract coefficients at each basis."
        doAssert negation.coefficientOr(b) == -x, "Negation must negate each coefficient."


macro holdNamed(r: var Rand, count: var int): untyped =
  ## Hold every pair of named types algebra declares, and count pairs held.
  result = newStmtList()
  for left in NAMES:
    for right in NAMES:
      let (kind_m, kind_n) = (ident(left), ident(right))
      result.add quote do:
        when declared(`kind_m`) and declared(`kind_n`):
          holdPair(`r`, `kind_m`, `kind_n`)
          `count`.inc


template holdScalars(r: var Rand, M: typedesc) =
  ## Hold sums and differences of scalar and one type, on each sample.
  block:
    const expected = basesExpected(basesType(M), {Basis.scalar})
    for _ in 0 ..< SAMPLES:
      let
        m = r.sample(M)
        s = Coefficient(r.rand(-1.0 .. 1.0))
        results = [s + m, m + s, s - m, m - s]
      doAssert basesType(typeof(results[0])) == expected,
        "Sum with scalar must hold bases of operand and scalar; got " & $typeof(results[0]) & "."
      holdTypeNamed(results[0], expected)
      for b in Basis:
        let (x, t) = (m.coefficientOr(b), if b == Basis.scalar: float(s) else: 0.0)
        doAssert results[0].coefficientOr(b) == t + x and results[1].coefficientOr(b) == x + t,
          "Sum with scalar must add scalar at its basis alone."
        doAssert results[2].coefficientOr(b) == t - x and results[3].coefficientOr(b) == x - t,
          "Difference with scalar must subtract at each basis."


macro holdScalarsNamed(r: var Rand, count: var int): untyped =
  ## Hold sums and differences of scalar and each named type algebra declares, and count them.
  result = newStmtList()
  for name in NAMES:
    let kind = ident(name)
    result.add quote do:
      when declared(`kind`):
        holdScalars(`r`, `kind`)
        `count`.inc


macro holdTypesNamed(): untyped =
  ## Hold that sum of one named type keeps that type, and is not generic of same bases.
  ##   Nim compares static sets as written, so equal sets spelled apart would be two types.
  result = newStmtList()
  for name in NAMES:
    let kind = ident(name)
    result.add quote do:
      when declared(`kind`):
        var r = initRand(SEED)
        let m = r.sample(`kind`)
        doAssert typeof(m + m) is `kind`, "Sum of one named type must keep that type."


proc main() =
  var
    r = initRand(SEED)
    pairs = 0
    types = 0
  holdNamed(r, pairs)
  holdScalarsNamed(r, types)
  holdTypesNamed()
  echo &"{DIMENSIONS}D, conformal {IS_CONFORMAL}: laws hold at {pairs} pairs of named types, " &
    &"and at {types} types beside a scalar, on {SAMPLES} samples each."


main()
