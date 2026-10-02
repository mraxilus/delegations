## Hold partner of folded tables to its definition on every grade (`partner-sign`).
##   Evaluation compiles this against changed library at each algebra its claim names, and exit code
##     is verdict: every law below holds, or program stops on assertion.
##   Definition is spelled through exported operators, i.e. (-1)^(gr 𝐦 + 1) (𝐦☆)⊡ ∨ 𝐦⊟, with
##     sign read from grade sample was drawn at; partner reads no grade, so laws hold it to that.

{.experimental: "strictFuncs".}

when compileOption("profiler"): import std/nimprof

import std/[math, random]

import pga
import pga/algebra


const
  SAMPLES = 256  ## Seeded samples each grade is checked on.
  SEED = 0  ## Seed of sample generator, so every run checks same samples.


proc sample(grade: Grade): Multivector =
  ## Draw multivector of one grade, every slot of that grade uniform in [-1, 1].
  for basis in Basis:
    if basis.grade == grade: result[basis] = rand(-1.0..1.0)


proc main(): int =
  ## Hold partner to its definition on seeded samples of every grade; exit zero.
  randomize(SEED)
  for grade in Grade.low..Grade.high:
    let sign = float(-1 ^ (int(grade) + 1))
    for _ in 1..SAMPLES:
      let m = sample(grade)
      doAssert (⊛m) =~ ((sign * ⊡(☆m)) ∨ (⊟m)), "partner must equal its definition"
  echo "partner-sign: laws hold at ", DIMENSIONS, "D, conformal ", IS_CONFORMAL
  0


when isMainModule:
  quit main()
