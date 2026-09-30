# Test equation 2.73 against independent expectation

At pin, the test of 2.73 checks `⊖𝐦` against `𝐦 ∨ /horizon`, which is how `⊖` is defined.
So the test cannot fail, and it reports green for any definition.

This change checks each basis vector instead: its attitude is its weight, in the scalar slot.
The weight is the coordinate on 𝐞ₙ under the rigid metric, and on 𝐞ₙ₋₁ under the conformal
metric, where the library puts the horizon.

## Edit `tests/suites.nim`

```nim
    let horizon = if IS_RIGID: 𝐞ₙ else: 𝐞ₙ₋₁
    for 𝐦, _, _ in randMultivectors():
      check ⊖𝐦 =~ 𝐦 ∨ /horizon
```

```nim
    # Expectation independent of operator: attitude of point is its weight, in scalar slot.
    for b, 𝐦 in enumerateBasis():
      if b.grade == Grade(1):
        check (⊖𝐦)[Basis.scalar] =~ 𝐦[Basis(if IS_RIGID: DIMENSIONS else: DIMENSIONS - 1)]
```
