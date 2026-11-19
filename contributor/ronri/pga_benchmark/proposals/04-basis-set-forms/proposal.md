# P04: Return exactly the bases an operator reaches

**What it is.** At pin, one generic type holds the coefficients of any set of bases, but each
operator takes and returns a whole multivector. This proposal gives each operator that the library
builds from one table a form for any basis-set types. Each form returns exactly the bases that its
table can reach. Scaling, the norms, unitizing, the operators built from others and each alias
take any type through these forms.

**What it is for.** A form writes only the coefficients that it reaches, so a dot product or a
squared norm writes one number, not a whole multivector. The type of the result also says what it
is.

**What it costs.** The compiler builds a body for each type or pair of types that a program uses.
A form that reaches no basis returns the type of no bases, whose value is zero. Each type aligns
to at most 16 bytes, so an object that holds one beside other fields can pad.

## Problem

At pin, `MultivectorOf[B]` holds any set of bases. But each product takes and returns a whole
`Multivector` of 2ⁿ coefficients, also where the result has one. So a dot product writes 128 bytes
at rga4d and 256 at cga5d to give one number. The type of the result does not say what the result
is.

At rga4d, 16 measurands move more bytes than their multivector lower bound only because each
writes a whole multivector for one coefficient. They are the dot, the antidot, 6 typed dots and
antidots, and 8 squared norms. At cga5d, 15 do: the dot, the antidot, 8 typed dots and antidots,
and 5 squared norms. `baseline/static_rga4d.json` and `baseline/static_cga5d.json` hold them.

The norms, unitizing, the supports and the conformal operators built from others take a whole
multivector alone too, and so does each alias of `pga.nim`. At pin, each basis-set type aligns to
its coefficient, 8 bytes at 64 bits, whatever its count.

## Idea

### Basis-set types at pin

`MultivectorOf[B]`, with `B: static Bases`, holds `card(B)` coefficients, dense in basis order.
`Multivector` is the alias of the whole set, and `MultivectorScalars` of the scalar and the
antiscalar. One macro names an alias for each grade and for each parity. At rga4d these are:

| Alias | Bases at rga4d | Coefficients |
|-------|----------------|-------------:|
| `Multivector0` | `S` | 1 |
| `Multivector1` | `E1`, `E2`, `E3`, `E4` | 4 |
| `Multivector2` | `E41`, `E42`, `E43`, `E23`, `E31`, `E12` | 6 |
| `Multivector3` | `E423`, `E431`, `E412`, `E321` | 4 |
| `Multivector4` | `E1234` | 1 |
| `MultivectorEven` | `S`, the six bivectors and `E1234` | 8 |
| `MultivectorOdd` | the four vectors and the four trivectors | 8 |

The index of a basis is the count of the bases of `B` below it, which `index` folds wherever the
basis is static. A static basis outside `B` stops the compile. `toMultivector` widens a
basis-set type, and `toMultivectorOf` narrows it.

### Basis-set forms

The library builds 21 operators from one table each in a rigid build, and 27 in a conformal
build. This proposal gives each one a basis-set form, as the glossary names it:

| Kind | Operators | Algebras |
|------|-----------|----------|
| Products | `∧`, `∨`, `⟑`, `⟇`, `∙`, `∘` | every algebra |
| Interior products | `∧★`, `∧☆`, `∨★`, `∨☆` | every algebra |
| Parts and maps | `∙`, `∘`, `/`, `\`, `~`, `~∘`, `★`, `☆`, `⊖` | every algebra |
| Squared norms | `‖𝐦‖∙²`, `‖𝐦‖∘²` | every algebra |
| Parts and maps | `■`, `□`, `⊟` | conformal |
| Squared norms | `‖𝐦‖■²`, `‖𝐦‖□²`, `‖𝐦‖⊘²` | conformal |

The forms are the code of the patch of D1 of pga_visualiser, as the Architect ruled (D51 b).
Three private templates define each map, each product and each squared norm from one call, so
each form names its table once (D10 b). They stand in `pga/operators.nim`, beside the operators
of pin (D11 b). `basesMapped` and `basesMultiplied` walk the whole table over the bases of the
operands, at compile time, and find the bases that a form reaches. So the tables stay whole, and
their count does not grow with the count of types.

`emitMappedByBasis` and `emitMultipliedByBasis` write one assignment for each basis of the result.
Each assignment sums the terms that the table gives, at a constant basis. The accessors then fold
each basis to its index, so the compiled body reads fixed offsets alone. Each form is `inline`
and `noinit`, as each operator of the library is, and writes each coefficient once.

`zeroNamed` of P14, `typed-sums`, names the type of each result. Where a named type has exactly
the bases reached, the result takes it, so `Multivector1 ∧ Multivector1` returns `Multivector2`
and prints so. Where a form reaches every basis, it returns `Multivector`, so each operator of
the library takes the result.

Nim prefers the operator of the library to a generic one that also matches. So an operator on
whole multivectors stays as at pin, and returns `Multivector`. A product of a whole multivector
and a basis-set type had no operator at pin, and takes the generic one.

For example, at rga3d the product `Multivector1 ∧ Multivector1` reaches `Multivector2`.
`emitMultipliedByBasis` writes three lines, shown here with the names of the bases:

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

### Type of no bases

A form that reaches no basis returns `MultivectorOf[{}]`, the type of no bases, as the Architect
ruled (D9 b). Its value widens to zero, which the operator of the library gives there. At pin
that type does not build, since `B.card` of `{}` stops the compiler on `firstOrd(tyEmpty)`. So
`MultivectorOf` counts its bases through `Bases(B).card`. `=~`, `toMultivectorOf` and
`toMultivector` skip each loop over an empty set, since `index` gives an empty range there.

Each form also takes the type of no bases as an operand, and a sum with it keeps the type of the
other operand. At rga2d the wedge of a vector and a bivector reaches no basis, and at rga2d and
cga3d the bulk of a bivector does too. Under the rigid metric the bulk dual of the antiscalar
reaches none, and so does the geometric product of two antiscalars.

### Operators built from others

Each routine takes every type that its operators take. That follows the rule that a routine is
correct for each value of each type that it takes (IV.8):

- **Scaling.** `*` and `∧` with a scalar on either side keep the type of the multivector.
- **Norms.** Each norm reads the scalar or the antiscalar of the form of its squared norm, through
  `coefficientOr`. It returns `MultivectorScalars`, as at pin.
- **Unitizing.** `^∙`, `^∘` and `^` scale by the reciprocal of a norm, and keep the type.
- **Supports and conformal operators.** `∩`, `∪`, `⊞`, `⊙`, `⊡` and `⊛` take any type through the
  forms that they read. Each takes the type that those tables reach in turn.

### Aliases

Each alias of `pga.nim` whose operator takes any type takes any type too, and returns `auto` (D12
b). So an alias forwards to its operator over the same types, and never reimplements it (III.2).
The selections of a grade keep `Multivector`, and `normCenter` keeps its stop.

### Alignment

Each basis-set type aligns to `alignment` of its count of coefficients. That is the largest power
of two that divides their bytes, and at most 16 (D13 b). So the type pads no count, and storage
from `alloc`, which aligns each block to 16 bytes, stays valid. The type of no bases keeps the
alignment of its coefficient. `MultivectorOf[B]` chooses 16 or 8 bytes through `when`, so a named
type and an unnamed type follow one rule.

At 64 bits the counts that named types reach from rga3d to cga5d take:

| Floats | Objects | Bytes | `alignment` |
|-------:|---------|------:|------------:|
| 3 | rga3d point and line | 24 | 8 |
| 4 | rga3d motor and flector, rga4d point and plane | 32 | 16 |
| 5 | cga5d round point and sphere | 40 | 8 |
| 6 | rga4d line | 48 | 16 |
| 8 | rga4d motor and flector | 64 | 16 |
| 10 | cga5d dipole and circle | 80 | 16 |
| 16 | cga5d even and odd parts | 128 | 16 |

`alignment` stays private to `pga/multivectors.nim`. `laws.nim` reads it through `{.all.}`, as
the tests of the library read private names.

## Alternatives

This proposal replaces the return rule of P02, `typed-multivectors`, as the Architect ruled on
2026-10-04. P02 returned the smallest named basis-set type that holds a product, and it is
withdrawn.

| Option | Why it lost |
|--------|-------------|
| Forms by hand that name their type through `typeReached` | The Architect ruled the patch (D51 b) |
| Stop the compile where a form reaches no basis | The Architect ruled the empty type (D9 b) |
| A module of its own, `pga/basis_sets.nim` | Each operator of pin is in `operators.nim` (D11 b) |
| Aliases that name a table in their return types | Each would wrap past one line (D12 b) |
| Alignment to at most 64 bytes | An AVX2 build can fault on storage from `alloc` (D13 b) |
| A declared result set for the sandwiches | A later proposal chooses those sets (D7 a) |
| Flat basis-set types of the conformal metric | A later change adds them (D8 a) |
| Smallest named basis-set type, as P02 | Bulk of a bivector holds zeros in half its coefficients |
| `Coefficient` for a product of one coefficient | Scalar and antiscalar become one type |
| Filtered copy of each table for each pair of types | About 1 700 MiB of compiler memory at 6D |
| One emitted procedure for each pair | About 6 000 bodies at 5D conformal, most never called |
| `align` of a static parameter | Pinned compiler stops, even on `align(A)` of `A: static int` |

## Costs

- **Compile cost.** With P14 and this proposal, a program that imports the library alone
  builds at cga5d in 5.9 s, and peaks at 211 MiB. At pin it takes 5.4 to 5.6 s and 207 MiB. At
  cga6d it takes 15.3 s and 530 MiB, against 14.7 to 14.8 s and 522 MiB. A form costs only where
  a program uses it. The laws build every form over every pair of named types, and peak at
  1 545 MiB at cga5d.
- **Reach of the table.** The reach is what the table can produce, not what the algebra
  guarantees. A sandwich of a vector comes back as `MultivectorOdd` at each of the nine algebras,
  although its value lies in grade 1. A later proposal can declare a result set (D7 a).
- **Operators built from others.** Each takes the type that its tables reach in turn, which can
  hold bases where terms cancel. The partner widens its operand to read its grade, as at pin.
- **Type of no bases.** A caller can get a result type that it does not expect. A value of that
  type takes 8 bytes at 64 bits, the size of one coefficient.
- **Alignment.** Some basis-set types hold bytes that are not a power of two, as 3, 5, 6 and 10
  floats at 64 bits. Such a type can still cross a line of the cache. Only padding would prevent
  that, and padding costs more than the line.
- **Caller objects.** A field of a basis-set type aligns its object to 16 bytes, where pin aligns
  it to 8. So an object that holds one beside other fields pads to 16, and so does each `seq` or
  array of such objects. At rga4d, a motor and an `int32` take 80 bytes and not 72. A vector and a
  float take 48 and not 40.
- **Storage of a caller.** `alloc`, `create` and `createU` align each block to 16 bytes, so their
  storage stays valid. An allocator of a caller's own must align each block to 16 bytes too.
- **Memory manager.** No record tests a `seq` of basis-set types under `--mm:refc` or
  `--mm:markAndSweep`. The library at pin names no memory manager.
- **Time.** The whole set aligns to 16 bytes from rga3d up at 64 bits, where pin aligns it to
  8. In the evaluation, the 111 measurands at rga4d and the 135 at cga5d read ×0.99 to ×1.02 of
  pin. The highest are `+` at rga4d, which P14 gives, and the selection of an antigrade at cga5d.
  Two earlier takes of the same day read ×0.98 to ×1.03.
- **Static reading.** The inspector keeps the functions of the library by the module in their C
  name. Seven functions of pin now take in that name the module of the bench that calls them, so
  the reading holds them no more. They are `+`, `-` and negation of whole multivectors, and the
  four projections.
- **Aliases.** Each alias returns `auto`, which has no use at pin. So its signature no longer
  states its type, and a caller reads the type from its operator.
- **Callers.** A caller that lets the compiler place its basis-set types does not migrate, since
  every type and operator at pin stays. The field `elements` stays private, so `laws.nim` samples
  each type through the narrow.
- **Machines.** The timings come from Intel Xeons alone. None covers an AMD or an ARM core.

## Open decisions

None. The Architect ruled each decision of this proposal on
[the list of decisions (#921)](https://github.com/mraxilus/delegations/issues/921). The rulings
are D6 a, D7 a, D8 a, D9 b, D10 b, D11 b, D12 b, D13 b and D51 b.

## Landing

- **P14, `typed-sums`.** This proposal builds on it. Its forms name their result types through
  `zeroNamed`, and its tests follow the suite `Arithmetic` of P14. Every edit quotes text of pin
  as P14 leaves it.
- **P05, `multivector-align`.** It adds nothing once this proposal lands, since this proposal
  aligns the whole set by the same rule (D14 b, D15 b).
- **P09 and P10.** P09, `object-names`, names objects by the aliases at pin. P10,
  `homogeneous-scalar`, multiplies its pairs through the `⟑` and `⟇` of this proposal. Both
  build on it.
- **P08, `compound-tables`.** It builds the supports, the cocarrier, the center and the container
  from one table each. Here each of them takes any type through the forms that it reads. So
  whichever of the two lands second gives each of those tables a form.
- **Float width.** Each basis-set type holds `Coefficient`, and `alignment` reads its size. So a
  32-bit build aligns by the same rule, and at least to 4 bytes. `laws.nim` holds this at 32 bits
  at each algebra up to 5D.
- **Shared quotes.** These texts quote lines that this proposal edits: the changes
  `conformal-norms`, `doc-comments`, `doc-comments-2` and `partner-guard`, and P03, P07, P10, P11
  and P13. Whichever of each pair lands second quotes them again. P13, `transform-operator`, is
  written again by type after this proposal.

## Evidence

### Bytes

The table gives the bytes that each result holds, at rga4d and then at cga5d. At pin each one is a
whole `Multivector`. P02 writes the smallest named basis-set type, or `Multivector` where none
holds the result. `laws.nim` prints each exact size. A vector and a whole multivector stand for
the operands of each dot, since two whole ones keep the operator of the library.

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

### Laws

`laws.nim` holds each form against the operator of the library on whole operands, on 256 seeded
samples of each type or pair. It sweeps each part, map, squared norm, norm and unitizing over each
named type, and so each operator built from others. Up to 5D it sweeps each product over every
pair of named types and the whole multivector. At 6D a vector pairs with each type, on either
side. Each scaling holds with the scalar on either side of each named type.

Each map and product also takes exactly the bases that the operator of the library gives on single
bases of its operands. So where the library gives no basis there, the form takes the type of no
bases, and the library gives zero on each sample. A squared norm reads pairs of bases, so its laws
hold its value alone. Where the library gives NaN, as the radius norm of a scalar at cga3d does,
the form gives NaN in the same coefficient.

Each alias returns the type of its operator, and equals it and the library. Each reverse keeps its
type, and each complement takes grade k to grade N - k. A copy whose maps drop the sign of their
table fails at rga4d. A copy whose `⟑` takes one basis more, written as zero, fails there too,
where a law on values alone holds. Each copy ran by hand with Nim 2.4.0 on 2026-11-19.

The laws held at each of the nine algebras in the evaluation of 2026-11-19, and at 32 bits at
seven. Builds by hand on the same day, three at once, on the machine of the evaluation, gave these
figures:

| Algebra | Pairs of each product | Forms that hold | Of them with no basis | Peak of build |
|---------|-----------------------|----------------:|----------------------:|--------------:|
| rga2d | every pair | 465 | 105 | 394 MiB |
| rga3d | every pair | 618 | 139 | 539 MiB |
| rga4d | every pair | 791 | 185 | 722 MiB |
| rga5d | every pair | 984 | 241 | 1 247 MiB |
| rga6d | a vector with each type | 397 | 75 | 1 212 MiB |
| cga3d | every pair | 682 | 115 | 616 MiB |
| cga4d | every pair | 866 | 159 | 843 MiB |
| cga5d | every pair | 1 070 | 213 | 1 545 MiB |
| cga6d | a vector with each type | 494 | 86 | 1 490 MiB |

### The patch of D1 of pga_visualiser

[The patch of D1](https://github.com/mraxilus/delegations/issues/734#issuecomment-6611896928)
gives pga_visualiser the forms of this proposal. pga_visualiser measured it on 2026-11-03, on one
still frame of its largest demo. There its planes go through typed products, and each placement
comes out the same in each bit:

| Count | At pin | Planes through typed products |
|-------|-------:|------------------------------:|
| Arrays of 16 floats built on JS | 2 320 | 226 |
| Placing step in Chromium, panel shut | 3.30 ms | 2.00 ms |
| `placeEvery` on C | 0.43 ms | 0.41 ms |

This proposal takes the operators, emitters and tests of the patch as they are, and adds five
things:

- the alignment of each type, as D13 b rules;
- the aliases of `pga.nim` that take any type, as D12 b and the rule of IV.8 ask;
- guards that read `Bases(B).card`, as the type does;
- the helper `basesType` of the suite of P14, in place of its own helper;
- a private `convertByBasis` that holds the loop of `toMultivectorOf`, so that no edit quotes the
  line of pin that ends with a space.

### Alignment

`timing.nim` times a stand-in for each count of floats, since a stand-in reads no library. Each
stand-in has its own sum and negation, which return by value, as the library writes its operators.
`timing.nim` exits zero when it runs, and its figures never guard. The evaluation runs it at rga4d.

It ran twice by hand on 2026-11-19, on `linux amd64, 4 cores`, a Xeon of family 6 model 207. Each
cell is the median of 41 rounds over 1 024 objects, as a ratio to the natural layout, in both runs:

| Floats | `alignment` | 16 bytes: sum, negation | 64 bytes: sum, negation |
|-------:|------------:|-------------------------|-------------------------|
| 3 | 8, natural | ×3.2, ×5.0 to ×5.6 | ×3.5 to ×3.6, ×5.5 to ×6.2 |
| 4 | 16 | ×0.81 to ×0.82, ×0.83 to ×0.84 | ×1.65 to ×1.68, ×1.72 to ×1.73 |
| 5 | 8, natural | ×2.14 to ×2.15, ×2.19 | ×2.20, ×2.34 |
| 6 | 16 | ×0.90, ×0.91 | ×1.00 to ×1.01, ×1.06 to ×1.07 |
| 8 | 16 | ×0.80 to ×0.81, ×0.85 | ×0.73, ×0.84 |
| 10 | 16 | ×0.86 to ×0.87, ×0.89 to ×0.90 | ×1.21, ×1.23 to ×1.24 |
| 16 | 16 | ×0.80 to ×0.81, ×0.83 | ×0.76 to ×0.77, ×0.82 |

Where `alignment` takes 16 bytes, a stand-in runs ×0.80 to ×0.91 of the natural layout. A layout
that pads, as 3 and 5 floats at 16 bytes, runs ×2.1 to ×5.6, so `alignment` never pads. At 64
bytes, 4 and 10 floats pad and run ×1.21 to ×1.73. There 8 and 16 floats run ×0.73 to ×0.84,
against ×0.80 to ×0.85 at 16 bytes.

### Evaluation

Its evaluation of 2026-11-19 passes each claim at pin, with P14 applied first. The suites of the
library pass 44 tests at rga4d and 39 at cga5d, with the 5 tests of the suite `Typed operators`.
`laws.nim` holds at the nine algebras, and at 32 bits at seven. The 111 measurands at rga4d and the
135 at cga5d read ×0.99 to ×1.02 of pin, as Costs gives.

The static reading names seven functions that move: `+`, `-` and negation of whole multivectors,
and `projectCentral`, `projectCentralAnti`, `projectOrthogonal` and `projectOrthogonalAnti`. Each
has a reading at pin and none after the change. In the C of the bench, the central projection is
`projectCentral_u0__measurements` with this proposal, after the module that calls it. Under P14
alone it carries the name of the library, so the inspector finds it there. Their times read ×1.00
to ×1.02 of pin.
