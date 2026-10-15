## Hold table of each chain to chain pin spells (`compound-tables`).
##   Evaluation compiles this against changed library at each algebra its claim names; exit code
##     is verdict: every law below holds, or program stops on assertion.
##   Each chain is spelled through operators proposal leaves alone: ∧, ∨, ☆, ★, ⊟ and right
##     complement.
##   Rigid laws: 𝐦∩ = 𝐦 ∨ (𝐞ₙ ∧ 𝐦☆) and 𝐦∪ = 𝐦 ∧ (𝐞̄ₙ ∨ 𝐦★).
##   Conformal laws: 𝐦⊞ = 𝐦☆ ∧ 𝐞∞, 𝐦⊙ = (𝐦☆ ∧ 𝐞∞) ∨ 𝐦 and 𝐦⊡ = 𝐦 ∧ (𝐦⊟)☆. Center is spelled
##     through ☆ and ∧, not through ⊞, since proposal replaces ⊞ with table too.
##   Samples are dense, every slot drawn, so each law reads every cell of its table.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/random

import pga


const
  SAMPLES = 256  ## Seeded dense samples each law is checked on.
  SEED = 0  ## Seed of sample generator, so every run checks same samples.

when IS_RIGID:
  const
    ELEMENT_ORIGIN = initElement(Basis.origin)  ## 𝐞ₙ, as pin's `∩` reads it.
    ELEMENT_HORIZON = complementRight(ELEMENT_ORIGIN)
      ## 𝐞̄ₙ, right complement of origin, as `horizon` of `cayleys.nim` derives it.
else:
  const ELEMENT_INFINITY = initElement(Basis.infinity)  ## 𝐞∞, as pin's `⊞` reads it.


proc sample(): Multivector =
  ## Draw dense multivector, every slot uniform in [-1, 1].
  for basis in Basis: result[basis] = rand(-1.0..1.0)


proc main(): int =
  ## Hold each table operator to pin's chain on seeded dense samples; exit zero.
  randomize(SEED)
  for _ in 1..SAMPLES:
    let m = sample()
    when IS_RIGID:
      doAssert (∩m) =~ (m ∨ (ELEMENT_ORIGIN ∧ ☆m)), "support must equal its chain"
      doAssert (∪m) =~ (m ∧ (ELEMENT_HORIZON ∨ ★m)), "antisupport must equal its chain"
    else:
      doAssert (⊞m) =~ (☆m ∧ ELEMENT_INFINITY), "cocarrier must equal its chain"
      doAssert (⊙m) =~ ((☆m ∧ ELEMENT_INFINITY) ∨ m), "center must equal its chain"
      doAssert (⊡m) =~ (m ∧ ☆(⊟m)), "container must equal its chain"
  echo "compound-tables: laws hold at ", DIMENSIONS, "D, conformal ", IS_CONFORMAL
  0


when isMainModule:
  quit main()
