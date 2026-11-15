# Mark the operand of each map as one that the result never overlaps

Under Nim 2.4.0 a call writes its result in place, through a pointer. Nim builds C with
`-fno-strict-aliasing`, so gcc must take that result as a possible overlap of the operand. Each map
that `defineOperator` builds writes a coefficient right after it reads one. So where gcc cannot
tell the two apart, it keeps each read after the write before it, and emits no vector instruction.
Under Nim 2.3.1 the call wrote a temporary, which let gcc load the whole operand first.

Nim never passes a map an operand that its result overlaps. Where the target may be the operand,
as in `a = ☆a` or `p[] = ☆q[]`, Nim 2.4.0 writes a temporary and copies it back. This change
states that fact with `noalias` on the operand, which Nim emits as C `restrict`. The body of each
map keeps its form, which writes each coefficient as it reads it.

A machine build at pin with this change gives the maps the instructions of Nim 2.3.1 again.
`reverse` takes 27 instructions at rga4d in place of 45, and 46 at cga5d in place of 87. Of 451
measurands, 142 take fewer instructions and none take more. In the timed bench, gcc already sees
that the operand and the result are apart, so no timed function changes at rga4d or cga5d. These
builds ran on `linux amd64, 4 cores` on 2026-11-01, under gcc 13.3.0.

## Edit `pga/operators.nim`

```nim
    params = nnkFormalParams.newTree(
      ident"Multivector",
      nnkIdentDefs.newTree(ident"m", ident"Multivector", newEmptyNode()),
    ),
    pragma = nnkPragma.newTree(ident"inline", ident"noinit"),
```

```nim
    params = nnkFormalParams.newTree(
      ident"Multivector",
      nnkIdentDefs.newTree(
        nnkPragmaExpr.newTree(ident"m", nnkPragma.newTree(ident"noalias")),
        ident"Multivector",
        newEmptyNode(),
      ),
    ),
    pragma = nnkPragma.newTree(ident"inline", ident"noinit"),
```
