# Draw antiscalar grade in sample pool

The pool draws `Grade(rand(DIMENSIONS - 1))`, so it never draws grade `DIMENSIONS`, which
is the antiscalar. This change draws `rand(DIMENSIONS)`, so the pool draws every grade.

## Edit `tests/suites.nim`

```nim
  let grades = if rand(1'f) > 0.1: @[Grade(rand(DIMENSIONS - 1))] else: @[]
```

```nim
  let grades = if rand(1'f) > 0.1: @[Grade(rand(DIMENSIONS))] else: @[]
```
