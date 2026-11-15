## Hold sandwich operator to chain pin spells (`transform-operator`).
##   Evaluation compiles this against changed library at each algebra its claim names; exit code
##     is verdict: every law below holds, or program stops on assertion.
##   Chain is spelled through operators proposal leaves alone: ⟇ and ~∘.
##   Laws: for motion operator 𝐧, i.e. antieven element, 𝐦 ⟇⟇~∘ 𝐧 = (𝐧 ⟇ 𝐦) ⟇ 𝐧̰; for any 𝐧, it
##     equals chain of antieven part of 𝐧 alone; alias `transform` reads same.
##   Samples are dense, every coefficient drawn, so each law reads every term of table.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[random, strformat]

import pga


const
  SAMPLES = 256  ## Seeded dense samples each law is checked on.
  SEED = 0  ## Seed of sample generator, so every run checks same samples.


func isAntiEven(b: Basis): bool =
  ## Decide whether basis belongs to antieven part, which motion operator holds alone.
  int(b.gradeAnti) mod 2 == 0


proc sample(r: var Rand, is_antieven_only = false): Multivector =
  ## Draw dense sample; each coefficient uniform in [-1, 1], antieven bases alone if asked.
  for b in Basis:
    if not is_antieven_only or b.isAntiEven: result[b] = r.rand(-1.0 .. 1.0)


func antieven(m: Multivector): Multivector =
  ## Keep antieven part of multivector.
  for b in Basis:
    if b.isAntiEven: result[b] = m[b]


proc main() =
  var r = initRand(SEED)
  for _ in 0 ..< SAMPLES:
    let
      m = r.sample
      motion = r.sample(is_antieven_only = true)
      general = r.sample
    let chain = (motion ⟇ m) ⟇ (~∘ motion)
    doAssert (m ⟇⟇~∘ motion) =~ chain, &"Sandwich must equal chain for motion operator; got `{m=}`."
    doAssert transform(m, motion) =~ chain, &"Alias must equal operator; got `{m=}`."
    let part = antieven(general)
    doAssert (m ⟇⟇~∘ general) =~ (part ⟇ m) ⟇ (~∘ part),
      &"Sandwich must read antieven part of operator alone; got `{general=}`."
  echo &"{DIMENSIONS}D, conformal {IS_CONFORMAL}: 3 laws hold on {SAMPLES} samples."


main()
