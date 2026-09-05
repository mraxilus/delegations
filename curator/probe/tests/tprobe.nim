discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
matrix: "-d:probe.modulus=4; -d:probe.modulus=5"
batchable: true
joinable: true
"""
## Replicate ring laws of `probe.nim` header table, in two ring sizes.

import std/unittest
import ../src/probe


iterator enumerateSteps(): Step =
  ## Yield every step of ring, i.e. MODULUS steps, exhaustive.
  for n in 0 ..< MODULUS: yield Step(n)


suite "Ring":
  test "advance is commutative and associative":
    for a in enumerateSteps():
      for b in enumerateSteps():  # MODULUS² pairs
        check a ⊕ b == b ⊕ a  # commutative
        check a.advance(b) == a ⊕ b  # alias forwards
        for c in enumerateSteps():  # MODULUS³ triples
          check (a ⊕ b) ⊕ c == a ⊕ (b ⊕ c)  # associative

  test "identity and inverse":
    for a in enumerateSteps():  # MODULUS steps
      check a ⊕ 𝟎 == a  # identity
      check a ⊕ a.invert == 𝟎  # inverse returns to identity
      check a.invert.invert == a  # inversion is involution
    check 𝟎.invert == 𝟎  # identity inverts to itself

  test "positions stay inside ring":
    for a in enumerateSteps():
      for b in enumerateSteps():  # MODULUS² pairs
        check (a ⊕ b).position in 0 ..< MODULUS  # never reaches MODULUS
    check $Step(MODULUS - 1) == $(MODULUS - 1)  # renders position

  test "poisons fail to compile":
    check not compiles(Step(0) + Step(1))  # plain sum poisoned
    check not compiles(Step(16))  # literal beyond every ring; const expression compiles
