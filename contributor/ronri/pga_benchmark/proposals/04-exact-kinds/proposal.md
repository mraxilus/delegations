# P04: Return exactly the bases an operator reaches

**What it is.** At pin, one generic type holds the coefficients of any set of bases. This proposal
gives these types a basis-set form of each operator that the library builds from one table. Each
form returns exactly the bases that its table can reach. It also aligns each type to the largest
power of two that divides its bytes, at most one cache line.

**What it is for.** A form writes only the coefficients that it reaches, so a dot product or a
squared norm writes one number and not a whole multivector. The type of the result also says
what it is.

**What it costs.** The compiler builds a body for each type or pair of types that a program uses.
Each term of a body takes about 0.3 MiB of compiler memory. A form that reaches no basis stops
the compile, where a widened call gives zero.

## Problem

At pin, `MultivectorOf[B]` holds any set of bases. But each product takes and returns a whole
`Multivector` of 2ⁿ coefficients, also where the result has one. So a dot product writes 128 bytes
at rga4d and 256 at cga5d to give one number. The type of the result does not say what the result
is.

At rga4d, 16 measurands move more bytes than their multivector lower bound only because each
writes a whole multivector for one coefficient. They are the dot, the antidot, 6 typed dots and
antidots, and 8 squared norms. At cga5d, 15 do: the dot, the antidot, 8 typed dots and antidots,
and 5 squared norms. `baseline/static_rga4d.json` and `baseline/static_cga5d.json` hold them.

At pin, each basis-set type aligns to its coefficient, 8 bytes at 64 bits, whatever its count.

## Idea

### Basis-set types at pin

`MultivectorOf[B]`, with `B: static Bases`, holds `card(B)` coefficients, dense in basis order.
`Multivector` is the alias of the whole set, and `MultivectorScalars` of the scalar and the
antiscalar. One macro names an alias for each grade and for each parity. At rga4d these are:

| Alias | Bases at `rga4d` | Coefficients |
|-------|------------------|-------------:|
| `Multivector0` | `S` | 1 |
| `Multivector1` | `E1`, `E2`, `E3`, `E4` | 4 |
| `Multivector2` | `E41`, `E42`, `E43`, `E23`, `E31`, `E12` | 6 |
| `Multivector3` | `E423`, `E431`, `E412`, `E321` | 4 |
| `Multivector4` | `E1234` | 1 |
| `MultivectorEven` | `S`, the six bivectors and `E1234` | 8 |
| `MultivectorOdd` | the four vectors and the four trivectors | 8 |

The index of a basis is the count of the bases of `B` below it, which `index` folds wherever the
basis is static. A static basis outside `B` stops the compile. `toMultivector` widens a
basis-set type, and `toMultivectorOf` narrows it. This proposal reads all of these, and adds none.

### Basis-set forms

The library builds 21 operators from one table each in a rigid build, and 27 in a conformal
build. This proposal gives each one a basis-set form, as the glossary names it. `pga.nim` gives
each form the alias of its operator, where the library names one:

| Kind | Operators | Algebras |
|------|-----------|----------|
| Products | `∧`, `∨`, `⟑`, `⟇`, `∙`, `∘` | every algebra |
| Interior products | `∧★`, `∧☆`, `∨★`, `∨☆` | every algebra |
| Parts and maps | `∙`, `∘`, `/`, `\`, `~`, `~∘`, `★`, `☆`, `⊖` | every algebra |
| Squared norms | `‖𝐦‖∙²`, `‖𝐦‖∘²` | every algebra |
| Parts and maps | `■`, `□`, `⊟` | conformal |
| Squared norms | `‖𝐦‖■²`, `‖𝐦‖□²`, `‖𝐦‖⊘²` | conformal |

The emitter walks the whole table of the library over the bases of the operands. It finds the
bases that the form can reach, and writes one line for each. `defineProduct` and `defineMap`
read the same tables as `defineOperator`, over the bases of the operands alone. So the tables stay
whole, and their count does not grow with the count of types. Forms are generic, so a program
makes only the types and pairs of types that it uses.

A squared norm applies a table of two operands to one operand. So `defineProduct` reads that
operand on both sides, as `as_unary` of the library does. The library spells the squared norms
`|∙²` to `|⊘²`, names no alias for them, and this proposal adds none.

A form reaches every coefficient of its exact basis-set type. So each form is `noinit`, and
writes each coefficient once. `typeReached` names the result type, and `defineProduct` or
`defineMap` fills it. Both read the same table, so the type and the body agree.

Nim reads the argument of a generic type as it is spelled. `MultivectorOf[{Basis.E1..Basis.E4}]`
is not `Multivector1`, which lists its four bases, and a set of all bases listed is not
`Multivector`, which spells a range. So `typeReached` lists each basis through
`emitMultivectorOf`, as the aliases of each grade and parity do. Where a form reaches every
basis, it names `Multivector`, so each operator of the library takes the result.

A form that reaches no basis is zero for any operands. The pinned compiler instantiates no
`MultivectorOf` of an empty set: `B.card` stops on `firstOrd(tyEmpty)`, and `index` on an empty
range. So `typeReached` stops the compile there, and says why.

Nim prefers the operator of the library to a generic one that also matches. So an operator on
whole multivectors stays as at pin, and returns `Multivector`. A product of a whole multivector
and a basis-set type had no operator at pin, and takes the generic one.

For example, at `rga3d` the product `Multivector1 ∧ Multivector1` reaches `Multivector2`, and
`defineProduct` writes three lines through `emitTerm`:

```nim
result[E23] = m[E2] * n[E3] + -(m[E3] * n[E2])
result[E31] = -(m[E1] * n[E3]) + m[E3] * n[E1]
result[E12] = m[E1] * n[E2] + -(m[E2] * n[E1])
```

The accessors then fold each basis to its index, so the compiled body reads fixed offsets alone:

```nim
result.elements[0] = m.elements[1] * n.elements[2] + -(m.elements[2] * n.elements[1])
result.elements[1] = -(m.elements[0] * n.elements[2]) + m.elements[2] * n.elements[0]
result.elements[2] = m.elements[0] * n.elements[1] + -(m.elements[1] * n.elements[0])
```

No term that the table makes zero appears, such as `e2 ∧ e2`. The product holds no loop, no
branch and no lookup. `(𝐞₁ + 2𝐞₂) ∧ (3𝐞₂ + 4𝐞₃)` gives `8𝐞₂₃ - 4𝐞₃₁ + 3𝐞₁₂`, as by hand.

### Alignment

Each basis-set type aligns to `alignment` of its count of coefficients: the largest power of two
that divides their bytes, and at most 64. So it pads no count. Each takes it from the size of its
basis set, as the Architect ruled on 2026-10-04. `MultivectorOf[B]` chooses among 16, 32 and 64
through `when`, and otherwise keeps the alignment of its coefficient. So a named type and an
unnamed type follow one rule. The whole set takes 64 bytes from rga3d up at 64 bits, which is the
alignment that P05, `multivector-align`, gives `Multivector`.

## Alternatives

This proposal replaces the return rule of P02, `typed-multivectors`, as the Architect ruled on
2026-10-04. P02 returned the smallest named basis-set type that holds a product, and it is
withdrawn.

| Option | Why it lost |
|--------|-------------|
| Forms of `∧`, `⟇`, `∙`, `∘` and the round parts alone | Each other operator widens, then narrows |
| Smallest named basis-set type, as P02 | Bulk of a bivector holds zeros in half its coefficients |
| `Coefficient` for a product of one coefficient | Scalar and antiscalar become one type; basis is
lost |
| Return type `MultivectorOf[reach(...)]` | Built; it is not the same type as its alias |
| One named type for each set reached | The names would spell the bases, as the generic does |
| Empty set for a product that reaches none | Pinned compiler stops on `B.card` and on `index` |
| Generic product of two whole multivectors | Callers of pin would see a new type |
| Filtered copy of each table for each pair of types | About 1.7 GB of compiler memory at 6D |
| One emitted procedure for each pair | About 6 000 bodies at 5D conformal, most never called |
| 64 bytes for each basis-set type | Pads 3, 4, 5, 6 and 10 floats; most padded ones ran slower |
| `align` of an expression of `B` | Pinned compiler stops: "cannot generate code for: B" |

One filtered copy of a 2D table costs 0.1 MB at 4D, 0.35 MB at 5D and 0.9 MB at 6D. About eight
types and thirty binary operators give some 1 900 copies, or about 1.7 GB at 6D.

### Names

Each name follows the charter: head first and qualifiers last (V.2), and a property is the
bare noun (V.3).

| Item | Proposed | Options weighed |
|------|----------|-----------------|
| Type a form reaches | `typeReached(cayley, A, B)` | `kindOf`: glossary keeps kind for operand |
| Alignment of a count | `alignment(count)` | `alignmentOf`: V.3 wants the bare noun |
| Module | `basis_sets` | `products`: `operators.nim` holds products too |
| Product of one operand | `as_unary`, as the library names it | `defineSquare`: a second macro |

## Costs

- **Compile memory.** The compiler takes about 0.3 MiB for each term that a form emits, and about
  1 MiB for each instance. At rga4d, 63 instances of `⟑` over the pairs of named types emit 1 536
  terms. They take 495 MiB above the 218 MiB of the library alone. Each instance takes a whole
  table as a static argument, and that costs little: 63 instances of `∙` take 74 MiB. A sweep of
  every form over every pair of types emits about 20 000 terms at rga5d, and peaks at 7 158 MiB.
  Compile time is unmeasured, apart from the runs of `laws.nim`.
- **Operators from no table.** These stay on `Multivector` alone: the norms, `unitize`, the
  supports and the projections. So do the cocarrier, center, container and partner, and `-`, `$`
  and `grade`. A caller widens a basis-set type for each of them, and narrows the result back. At
  pin `+` and `=~` already take any basis-set type. The library names no flat basis-set type.
- **Reach of the table.** The reach is what the table can produce, not what the algebra
  guarantees. A sandwich of a vector comes back as `MultivectorOdd` at each of the four algebras,
  although its value lies in grade 1. An operator that knows better declares its product set. The
  emitter at pin takes no grade filter, so that set comes from the table that the operator reads.
- **Printed name.** At rga4d, `$typeof(p ∧ q)` of two vectors prints the generic with its bases,
  and not `Multivector2`, as `laws.nim` prints:
  `MultivectorOf[{Basis.E41, Basis.E42, Basis.E43, Basis.E23, Basis.E31, Basis.E12}]`. A compiler
  message can print any name of the type. The alias serves where the importer writes a type in
  source.
- **Form that reaches no basis.** It stops the compile, where a widened call gives zero. So
  generic code over every pair of sets must leave it out. At rga2d the wedge of a vector and a
  bivector is one, and at rga2d and cga3d the bulk of a bivector. Under the rigid metric the bulk
  dual of the antiscalar is one, and so is the geometric product of two antiscalars. `laws.nim`
  counts them at each algebra.
- **Norms.** A norm takes a root of its squared norm, and at pin it returns `MultivectorScalars`.
  So a norm stays on `Multivector`, and this proposal does not cover it. Each squared norm has a
  form, and that form of a vector writes 8 bytes.
- **Alignment.** A basis-set type of an odd count keeps the alignment of its coefficient, so it
  can still cross a line. Only padding would prevent that, and padding costs more than the line. An
  alias holds no field of its own. So `laws.nim` writes each number into its laws, and not into a
  type.
- **Callers.** No caller must migrate, since every type and operator at pin stays. An operator on
  whole multivectors keeps its form at pin. A product of a whole multivector and a basis-set type
  had no operator at pin. The field `elements` stays private, so `laws.nim` samples
  each type through the narrow.
- **Machines.** The runtime measurements of basis-set types come from two Intel Xeons. None
  covers an AMD or an ARM core.

## Open decisions

- Choose the operators that declare a product set, such as the sandwiches and projections.
- Generate and test the conformal flat basis-set types.
- Whether a product that reaches no basis stops the compile, as here, or the library admits a
  basis-set type of an empty set.

## Landing

- **Quotes.** Every quote applies at pin.
- **P05, `multivector-align`.** It aligns the whole set alone, on the type definition that the
  first edit replaces. The second of the two to land quotes the first. Once this change lands, the
  whole set takes `alignment` of its count, which equals the alignment of P05.
- **Changes `doc-comments` and `doc-comments-2`.** `doc-comments` edits the import line of
  `pga.nim`, and `doc-comments-2` its export line. Whichever of each pair lands second quotes that
  line again.
- **Float width.** Each basis-set type holds `Coefficient`, and `alignment` reads its size. So a
  32-bit build aligns by the same rule, and at least to 4 bytes.
- **P09 and P10.** P09, `object-names`, names the objects of the book by the aliases at pin. P10,
  `homogeneous-scalar`, gives arithmetic to the type of two scalars that each norm returns.

## Evidence

### Bytes and terms

The table gives the bytes that each result holds, at rga4d and then at cga5d. At pin each one is a
whole `Multivector`. P02 writes the smallest named basis-set type, or `Multivector` where none
holds the result. `laws.nim` prints each exact size, and holds the rule of each row. A vector and a
whole multivector stand for the operands of each dot, since two whole ones keep the operator of the
library.

| Product | Smallest named, as P02 | Exact, rga4d | Exact, cga5d |
|---------|------------------------|--------------|--------------|
| `p ∙ m`, vector and whole | 8, 8 | 8 | 8 |
| `p ∘ m`, vector and whole | 8, 8 | 8 | 8 |
| `∙ m`, bulk of bivector | 48, 80 | 24 | 24 |
| `∘ m`, weight of vector | 32, 40 | 8 | 8 |
| Even sandwich of vector | 64, 128 | 64 | 128 |
| `‖p‖∙²`, squared norm of vector | 8, 8 | 8 | 8 |
| `/ p`, complement of vector | 32, 40 | 32 | 40 |
| `★ p`, bulk dual of vector | 32, 40 | 24 | 40 |
| `☆ p`, weight dual of vector | 32, 40 | 8 | 40 |
| `p ⟑ q`, two vectors | 64, 128 | 56 | 88 |

A result of one coefficient writes 8 bytes, which meets the multivector lower bound. The rule of
P02 also gives one coefficient for a dot or a squared norm, the alias of grade 0 or of grade N. So
this proposal gains over that rule on the parts, the duals at rga4d and the product of two vectors.
It gains nothing on the dots and the squared norms.

The prototype of P02 counts the terms that a motor sandwich on a point emits at 4D, with the
second product kept to grade 1. It counts 384 untyped, 96 over contiguous ranges with the motor at
full width, and 48 over named basis-set types. An exact basis-set type holds a subset of the bases
of the smallest named type that holds it, so it spends at most 48. `laws.nim` does not count them.

### Laws

`laws.nim` holds each form against the operator of the library, on 256 seeded samples of each type
or pair. It sweeps each part, map and squared norm over each named type. Up to 4D it sweeps each
product over every pair of named types and the whole multivector. At 5D and 6D a vector pairs with
each type, on either side, since the compiler takes about 0.3 MiB for each term. Where a form stops
the compile, the operator of the library gives zero on each sample.

| Algebra | Pairs of each product | Forms that hold | Forms that stop | Peak of build |
|---------|-----------------------|----------------:|----------------:|--------------:|
| rga2d | every pair | 302 | 103 | 554 MiB |
| rga3d | every pair | 409 | 137 | 1 132 MiB |
| rga4d | every pair | 524 | 183 | 2 579 MiB |
| rga5d | a vector with each type | 195 | 63 | 1 683 MiB |
| rga6d | a vector with each type | 216 | 73 | 3 941 MiB |
| cga3d | every pair | 472 | 110 | 1 415 MiB |
| cga4d | every pair | 595 | 154 | 3 371 MiB |
| cga5d | a vector with each type | 235 | 71 | 2 230 MiB |
| cga6d | a vector with each type | 262 | 81 | 5 334 MiB |

Each alias returns the type of its operator, and equals it. Each reverse keeps its type, and each
complement takes grade k to grade N - k. A map that drops the sign of its table fails at rga4d, at
the right complement of a bivector. A squared norm that reads half its table holds at rga4d, whose
metric is diagonal. It fails at cga5d, at the squared radius norm of a vector.

### Alignment

`timing.nim` times a stand-in for each count of floats, since a stand-in reads no library. Each
stand-in has its own sum and negation, which return by value, as the library writes its operators.
`timing.nim` exits zero when it runs, and its measurements never guard.

The record of this proposal keeps no timing, so these tables are runs by hand. On a Cascade
Lake Xeon, `linux amd64, 4 cores`, they ran with the timings of P05 on 2026-10-03. Those are five
alternating runs of pin `d9be8ae`, of 16 bytes and of 64 bytes, at four algebras, so 60 runs. Each
run takes the median of 41 rounds. They also ran on an Emerald Rapids Xeon, family 6 model 207, a
KVM guest with 4 cores, on 2026-10-04.

On Cascade Lake, each cell is the median of the 60 runs, time of each alignment over the natural
one:

| Floats | 16-byte, size | Sum | Negation | 64-byte, size | Sum | Negation |
|--------|---------------|-----|----------|---------------|-----|----------|
| 3 | 32 B | ×2.71 | ×4.54 | 64 B | ×2.98 | ×4.90 |
| 4 | 32 B | ×0.83 | ×0.90 | 64 B | ×1.49 | ×1.61 |
| 5 | 48 B | ×2.09 | ×2.20 | 64 B | ×2.13 | ×2.36 |
| 6 | 48 B | ×0.88 | ×0.90 | 64 B | ×0.92 | ×0.99 |
| 8 | 64 B | ×0.77 | ×0.83 | 64 B | ×0.74 | ×0.76 |
| 10 | 80 B | ×0.89 | ×0.89 | 128 B | ×1.18 | ×1.32 |
| 16 | 128 B | ×0.81 | ×0.89 | 128 B | ×0.78 | ×0.79 |

On Cascade Lake, each stand-in that an alignment pads runs slower, except 6 floats at 64 bytes.
Each stand-in that it does not pad runs faster. On Emerald Rapids, under SSE2, AVX2 and AVX-512,
3 and 5 floats padded to 16 bytes run ×2.6 to ×5.6. There, a stand-in that an alignment does not
pad runs at most ×1.17 at the median.

At 16 bytes the cause is in the machine code. The copy of a padded result reads its last 16 bytes
in one load. That load spans two 8-byte stores, the last float and the zeroed padding, and the
processor cannot forward it.

Each range below spans the medians of the sum and the negation, on Cascade Lake and on Emerald
Rapids under SSE2, AVX2 and AVX-512:

| Floats | Objects | Bytes | `alignment` | Time over natural |
|--------|---------|-------|---------------|-------------------|
| 3 | rga3d point and line | 24 | 8, natural | ×1 |
| 4 | rga3d motor and flector, rga4d point and plane | 32 | 32 | ×0.85 to ×1.17, Emerald Rapids |
| 5 | cga5d round point and sphere | 40 | 8, natural | ×1 |
| 6 | rga4d line | 48 | 16 | ×0.86 to ×1.08 |
| 8 | rga4d motor and flector | 64 | 64 | ×0.65 to ×1.11 |
| 10 | cga5d dipole and circle | 80 | 16 | ×0.86 to ×1.00 |
| 16 | cga5d even and odd parts | 128 | 64 | ×0.76 to ×0.97 |

Emerald Rapids alone times the stand-in of 4 floats at 32 bytes, on 2026-10-04: 20 executions
under each of SSE2, AVX2 and AVX-512. It pads nothing there, and it gains nothing over 16 bytes,
which reads ×0.86 to ×1.00 in the same runs. So 32 bytes is safe for that count, and not better.
Under AVX2, its sum ranged ×0.86 to ×1.47 over the 20 single executions. That range is of
executions, and the medians lie inside the range of the table.

`laws.nim` holds `alignment` at each count from 0 to 64, and at each count in the table above. It
also holds the size and the alignment of each named basis-set type at each of the nine algebras.
