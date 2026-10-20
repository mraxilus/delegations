# P04: Return exactly the bases a product reaches

**What it is.** At pin, one generic type holds the coefficients of any set of bases. This proposal
adds products of two such types that return exactly the bases that their table can reach. It also
aligns each type to the largest power of two that divides its bytes, at most one cache line.

**What it is for.** A product writes only the coefficients that it reaches, so a dot product
writes one number and not a whole multivector. The type of the result also says what it is.

**What it costs.** The compiler builds a body for each pair of types that a program uses, and no
measurement covers that cost. Only `∧`, `⟇`, `∙`, `∘` and the round parts take basis-set types,
so each other operator needs a widen first.

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

### Products

The emitter walks the whole table of the library over the bases of the two operands. It finds the
bases that the product can reach, and writes one line for each. `defineProduct` and `defineMap`
read the same tables as `defineOperator`, over the bases of the operands alone. So the tables stay
whole, and their count does not grow with the count of types. Products are generic, so a program
makes only the pairs of types that it uses.

A product reaches every coefficient of its exact basis-set type. So each product is `noinit`, and
writes each coefficient once. `typeReached` names the result type, and `defineProduct` or
`defineMap` fills it. Both read the same table, so the type and the body agree.

Nim reads the argument of a generic type as it is spelled. `MultivectorOf[{Basis.E1..Basis.E4}]`
is not `Multivector1`, which lists its four bases, and a set of all bases listed is not
`Multivector`, which spells a range. So `typeReached` lists each basis through
`emitMultivectorOf`, as the aliases of each grade and parity do. Where a product reaches every
basis, it names `Multivector`, so each operator of the library takes the result.

A product that reaches no basis is zero for any operands. The pinned compiler instantiates no
`MultivectorOf` of an empty set: `B.card` stops on `firstOrd(tyEmpty)`, and `index` on an empty
range. So `typeReached` stops the compile there, and says why.

Nim prefers the operator of the library to a generic one that also matches. So a product of two
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
| Type a product reaches | `typeReached(cayley, A, B)` | `kindOf`: glossary keeps kind for operand |
| Alignment of a count | `alignment(count)` | `alignmentOf`: V.3 wants the bare noun |
| Module | `basis_sets` | `products`: `operators.nim` holds products too |

## Costs

- **Compile time.** Each instance of a generic product takes a whole `Cayley2D` as a static
  argument. No measurement covers its cost in compile time.
- **Few generic operators.** Only `∧`, `⟇`, the binary `∙` and `∘`, and the round parts are
  generic here. These stay on `Multivector` alone: `∨` and `⟑`, the duals, complements and
  reverses, and the flat parts. So do the interior products, the squared norms and norms,
  `unitize`, the chains, `-`, `$` and `grade`. A caller widens a basis-set type for each of them,
  and narrows the result back. At pin `+` and `=~` already take any basis-set type. The library
  names no flat basis-set type.
- **Reach of the table.** The reach is what the table can produce, not what the algebra
  guarantees. A sandwich of a vector comes back as `MultivectorOdd` at each of the four algebras,
  although its value lies in grade 1. An operator that knows better declares its product set. The
  emitter at pin takes no grade filter, so that set comes from the table that the operator reads.
- **Printed name.** At rga4d, `$typeof(p ∧ q)` of two vectors prints the generic with its bases,
  and not `Multivector2`, as `laws.nim` prints:
  `MultivectorOf[{Basis.E41, Basis.E42, Basis.E43, Basis.E23, Basis.E31, Basis.E12}]`. A compiler
  message can print any name of the type. The alias serves where the importer writes a type in
  source.
- **Product that reaches no basis.** It stops the compile, so generic code over every pair of
  sets must leave it out. At rga2d the wedge of a vector and a bivector is one, and at rga2d and
  cga3d the bulk of a bivector.
- **Norms.** A norm takes a root of a squared norm, and at pin it returns `MultivectorScalars`, so
  this proposal does not cover it. The change emits no squared norm. The library reads each one
  from a 2D table with one operand, and `defineProduct` takes two. A call with one type and one
  operand twice would emit it, and no law holds that form.
- **Alignment.** A basis-set type of an odd count keeps the alignment of its coefficient, so it
  can still cross a line. Only padding would prevent that, and padding costs more than the line. An
  alias holds no field of its own. So `laws.nim` writes each number into its laws, and not into a
  type.
- **Callers.** No caller must migrate, since every type and operator at pin stays. A product of
  two whole multivectors keeps the operator of the library. A product of a whole multivector and a
  basis-set type had no operator at pin. The field `elements` stays private, so `laws.nim` samples
  each type through the narrow.
- **Machines.** The runtime measurements of basis-set types come from two Intel Xeons. None
  covers an AMD or an ARM core.

## Open decisions

- Choose the operators that declare a product set, such as the sandwiches and projections.
- Generate and test the conformal flat basis-set types.
- Whether the library emits the squared norms as exact basis-set types, through `defineProduct`
  with one operand twice.
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

A result of one coefficient writes 8 bytes, which meets the multivector lower bound. P02 also
returns one coefficient for a dot, as the alias of grade 0 or of grade N. So this proposal gains
over P02 on the parts, and not on the dots. For the squared norms, the 8 bytes are a claim of design
alone, since the change emits none.

The prototype of P02 counts the terms that a motor sandwich on a point emits at 4D, with the
second product kept to grade 1. It counts 384 untyped, 96 over contiguous ranges with the motor at
full width, and 48 over named basis-set types. An exact basis-set type holds a subset of the bases
of the smallest named type that holds it, so it spends at most 48. `laws.nim` does not count them.

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
