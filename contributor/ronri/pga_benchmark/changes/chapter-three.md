# Open chapter 3 with two suites

At pin, chapter 3 is one skipped test, and no suite tests `⟑ ⟇ ~ ~∘`. This change adds two
laws. The reverse and the antireverse are involutions. The geometric product of two vectors is
their wedge plus their dot.

## Edit `tests/suites.nim`

```nim
  test "TODO: Add chapter 3 tests":
    skip()
```

```nim
  test "Equation 3.30: reverse is involution":
    for 𝐦, _, _ in randMultivectors():
      check ~(~𝐦) =~ 𝐦
      check ~∘(~∘ 𝐦) =~ 𝐦

  test "Equation 3.14: geometric product contains wedge and dot":
    for b, c, 𝐮, 𝐯 in enumerateBasisPair():
      if b.grade == Grade(1) and c.grade == Grade(1):
        check 𝐮 ⟑ 𝐯 =~ (𝐮 ∧ 𝐯) + (𝐮 ∙ 𝐯)
```
