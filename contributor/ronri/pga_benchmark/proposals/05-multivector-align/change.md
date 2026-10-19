# Align multivector to one cache line

At pin, a multivector aligns to 8 bytes, as its coefficients do at 64 bits. A large `seq` of them
then starts 56 bytes into a 64-byte cache line, so each multivector touches one line more than it
holds. A multivector holds 2^D coefficients, so this change aligns it to `min(64, size)`. From three
dimensions up it starts on a line. At rga2d it aligns to its own 32 bytes, so it never crosses a
line.

At pin, `Multivector` is the alias of `MultivectorOf` of all bases. So this change aligns that
set alone, through a `when` in the type definition, and every other basis-set type keeps its
alignment. P04, `exact-kinds`, replaces the same type definition, and aligns every set by its
count. The second of the two to land quotes the first. The rule of P04 gives the whole set
`min(64, size)`, so once P04 lands its rule spells both.

## Edit `pga/multivectors.nim`

```nim
  MultivectorOf*[B: static Bases] = object
    elements: array[B.card, Coefficient]
```

```nim
  MultivectorOf*[B: static Bases] = object
    when B == {Basis.scalar..Basis.scalarAnti}:
      elements {.align(min(64, sizeof(array[Basis, Coefficient]))).}: array[B.card, Coefficient]
        ## Align whole set to cache line, or to own size where smaller, so it touches fewest lines.
    else:
      elements: array[B.card, Coefficient]
```
