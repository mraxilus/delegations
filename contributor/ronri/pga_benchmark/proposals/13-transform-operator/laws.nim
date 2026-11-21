## Hold sandwich operator to chain pin spells, for each pair of types (`transform-operator`).
##   Evaluation compiles this against changed library at each algebra its claim names; exit code
##     is verdict: every law below holds, or program stops on assertion.
##   Chain is spelled through operators proposal leaves alone, ⟇ and ~∘, on full multivectors.
##   Laws, for each pair of types below: 𝐦 ⟇⟇~∘ 𝐧 equals (𝐧 ⟇ 𝐦) ⟇ 𝐧̰ of widened operands; its type
##     holds exactly bases chain reaches over samples; alias `transform` reads same. Two full
##     multivectors take chain itself.
##   Pairs hold motor and flector parts, single grades and full type, so each kind of table runs.
##     Typed 𝐦 by full 𝐧 takes table of both types too, as it does over every pair of 𝐧.
##   Samples are dense in their types, every coefficient drawn, so each law reads every term.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[random, strformat]

import pga


const
  SAMPLES = 256  ## Seeded samples each law is checked on, for each pair of types.
  SEED = 0  ## Seed of sample generator, so every run checks same samples.
  TOLERANCE_ZERO = 1e-12  ## Magnitude below which coefficient of chain counts as unreached.


func basesAntieven(): Bases {.compileTime.} =
  ## Choose bases of even antigrade, which motion operator holds alone.
  for b in Basis:
    if int(b.gradeAnti) mod 2 == 0: result.incl b


func basesAntiodd(): Bases {.compileTime.} =
  ## Choose bases of odd antigrade, which reflection operator holds alone.
  for b in Basis:
    if int(b.gradeAnti) mod 2 != 0: result.incl b


func basesOfGrade(g: int): Bases {.compileTime.} =
  ## Choose bases of grade `g`.
  for b in Basis:
    if int(b.grade) == g: result.incl b


func basesEvery(): Bases {.compileTime.} =
  ## Choose every basis, i.e. bases of full type.
  for b in Basis: result.incl b


func basesType[B: static Bases](t: typedesc[MultivectorOf[B]]): Bases =
  ## Read bases of basis-set type.
  B


proc sample[B: static Bases](r: var Rand, t: typedesc[MultivectorOf[B]]): MultivectorOf[B] =
  ## Draw sample dense in its type; each coefficient uniform in [-1, 1].
  for b in B: result[b] = r.rand(-1.0 .. 1.0)


template holdPair(r: var Rand, name: string, M, N: typedesc) =
  ## Hold sandwich of type `M` by type `N` to chain, its type to bases chain reaches, and alias.
  block:
    var reached: Bases
    for _ in 0 ..< SAMPLES:
      let
        m = r.sample(M)
        n = r.sample(N)
        sandwich = m ⟇⟇~∘ n
        m_full = toMultivector(m)
        n_full = toMultivector(n)
        chain = (n_full ⟇ m_full) ⟇ (~∘ n_full)
      doAssert toMultivector(sandwich) =~ chain, name & ": sandwich must equal chain."
      doAssert toMultivector(transform(m, n)) =~ chain, name & ": alias must equal chain."
      for b in Basis:
        if abs(chain[b]) > TOLERANCE_ZERO: reached.incl b
    const typed = basesType(typeof(default(M) ⟇⟇~∘ default(N)))
    doAssert reached <= typed, name & ": chain must reach no basis outside type of result."
    doAssert typed <= reached, name & ": type of result must hold no basis that chain misses."


proc main() =
  var
    r = initRand(SEED)
    held = 0
  holdPair(r, "full by motor part", MultivectorOf[basesEvery()], MultivectorOf[basesAntieven()])
  held.inc
  holdPair(r, "full by flector part", MultivectorOf[basesEvery()], MultivectorOf[basesAntiodd()])
  held.inc
  holdPair(r, "vector by motor part", MultivectorOf[basesOfGrade(1)],
    MultivectorOf[basesAntieven()])
  held.inc
  holdPair(r, "bivector by motor part", MultivectorOf[basesOfGrade(2)],
    MultivectorOf[basesAntieven()])
  held.inc
  holdPair(r, "motor part by motor part", MultivectorOf[basesAntieven()],
    MultivectorOf[basesAntieven()])
  held.inc
  holdPair(r, "vector by vector", MultivectorOf[basesOfGrade(1)], MultivectorOf[basesOfGrade(1)])
  held.inc
  holdPair(r, "full by vector", MultivectorOf[basesEvery()], MultivectorOf[basesOfGrade(1)])
  held.inc
  holdPair(r, "vector by full", MultivectorOf[basesOfGrade(1)], Multivector)
  held.inc
  holdPair(r, "motor part by full", MultivectorOf[basesAntieven()], Multivector)
  held.inc
  for _ in 0 ..< SAMPLES:
    let
      m = toMultivector(r.sample(MultivectorOf[basesEvery()]))
      n = toMultivector(r.sample(MultivectorOf[basesEvery()]))
      sandwich = m ⟇⟇~∘ n
      chain = (n ⟇ m) ⟇ (~∘ n)
    for b in Basis:
      doAssert sandwich[b] == chain[b], "Two full multivectors must take chain itself."
  held.inc
  echo &"{DIMENSIONS}D, conformal {IS_CONFORMAL}: laws hold for {held} pairs of types " &
    &"on {SAMPLES} samples."


main()
