# P04: Return exactly the bases a product reaches

One generic object holds the coefficients of any set of bases, dense in basis order. One macro
call names a kind for each grade and for both parities, from `DIMENSIONS` alone. Each named kind
is an alias of the generic one. A product returns the kind of exactly the bases that its table
reaches. So a dot product writes one slot, and the bulk of a bivector writes only the part of its
grade it reaches.

This proposal builds on P01, `cayley-derivation`, and reads the tables that it derives. It holds
what P02, `typed-multivectors`, proposed, and replaces its return rule, as the Architect ruled on
2026-10-04. P02 returned the smallest named kind that holds a product, and it is withdrawn. A
product whose terms all land in one slot returns a kind of one slot, not a `float`. So its type
still names its basis.

## What it is

- **Exact kinds.** `MultivectorOf[B]`, with `B: static set[Basis]`, holds `card(B)` floats.
- **Slots.** The `Basis` enum keeps its grade-major order. The slot of a basis is the count of
  the bases of `B` below it. It folds at compile time wherever the basis is static, which in an
  emitted body it always is.
- **Names.** `Kvector0` to `KvectorN`, `MultivectorEven` and `MultivectorOdd` are aliases. A
  product that reaches one of those sets is that type, so the importer reads its name.
  `Multivector` stays the whole algebra, so every line written today compiles.
- **Products.** The emitter walks the whole table over the bases of the two operands, and finds
  the bases that the product can reach. A type macro, `kindOf`, spells that set as a literal. A
  return type that computes the set through a call is not the same type as its alias.
- **No fill.** A product reaches every slot of its kind. So each product is `noinit`, and
  writes each slot once.
- **Alignment.** Each kind aligns to `alignmentOf` of its count of floats: the largest power of
  two that divides their bytes, and at most 64. So it pads no count.

Products stay generic, since one body for each pair of kinds costs too much. At 5D conformal
that is some 6 000 bodies, and most are never called. A generic makes only the pairs that a
program uses.

## What it buys

The terms that a motor sandwich on a point emits at 4D, as the prototype of P02 counts them:

| Typing | First product | Second, kept to grade 1 | Total |
|--------|---------------|-------------------------|-------|
| Untyped multivector | 192 | 192 | 384 |
| Contiguous ranges, motor at full width | 40 | 56 | 96 |
| Named kinds over sets of bases, as P02 | 20 | 28 | 48 |

An exact kind holds a subset of the bases of the smallest named kind that holds it. So exact
kinds spend at most those terms, and the prototype of this proposal does not count them.

Bytes that each result holds, read with `sizeof` from the prototype:

| Product | Library | Smallest named kind | Exact kind, rga4d | Exact kind, cga5d |
|---------|---------|---------------------|-------------------|-------------------|
| `m ∙ n`, both whole | 128, 256 | none | 8 | 8 |
| `m ∘ n`, both whole | 128, 256 | none | 8 | 8 |
| `∙ m`, bulk of bivector | 128, 256 | 48, 80 | 24 | 24 |
| `∘ m`, weight of vector | 128, 256 | 32, 40 | 8 | 8 |
| `∙ m`, bulk of whole | 128, 256 | none | 64 | 64 |
| Even sandwich of vector | 128, 256 | 64, 128 | 64 | 128 |

At rga4d, 16 measurands stand above the byte bound only because they write a whole multivector
for one slot. At cga5d, 12 do. They are the dots, the antidots and the squared norms. Each one
written as an exact kind writes 8 bytes, which is the bound.

## Alignment of kinds

A kind holds the count of floats of its bases. So at rga3d a vector holds 3, and at cga5d a
vector holds 5. `timing.nim` times kinds that hold each count, since they read no library. Each
kind has its own sum and negation, which return by value, as the library writes its operators.
These runs came with the timings of P05, on a Cascade Lake Xeon, `linux amd64, 4 cores`, on
2026-10-03. They also ran on an Emerald Rapids Xeon, family 6 model 207, a KVM guest with 4
cores, on 2026-10-04. On Cascade Lake, the median of 60 runs, time of each alignment over the
natural one:

| Floats | Natural | 16-byte, size | Sum | Negation | 64-byte, size | Sum | Negation |
|--------|---------|---------------|-----|----------|---------------|-----|----------|
| 3 | 24 B | 32 B | ×2.71 | ×4.54 | 64 B | ×2.98 | ×4.90 |
| 4 | 32 B | 32 B | ×0.83 | ×0.90 | 64 B | ×1.49 | ×1.61 |
| 5 | 40 B | 48 B | ×2.09 | ×2.20 | 64 B | ×2.13 | ×2.36 |
| 6 | 48 B | 48 B | ×0.88 | ×0.90 | 64 B | ×0.92 | ×0.99 |
| 8 | 64 B | 64 B | ×0.77 | ×0.83 | 64 B | ×0.74 | ×0.76 |
| 10 | 80 B | 80 B | ×0.89 | ×0.89 | 128 B | ×1.18 | ×1.32 |
| 16 | 128 B | 128 B | ×0.81 | ×0.89 | 128 B | ×0.78 | ×0.79 |

On Cascade Lake, each kind that an alignment pads runs slower, except 6 floats at 64 bytes.
Each kind that it does not pad runs faster. On Emerald Rapids, under SSE2, AVX2 and AVX-512, 3
and 5 floats padded to 16 bytes run ×2.6 to ×5.6. There, a kind that an alignment does not pad
runs at most ×1.11.

At 16 bytes the cause is in the machine code. The copy of a padded result reads its last 16
bytes in one load. That load spans two 8-byte stores, the last float and the zeroed padding,
and the processor cannot forward it.

So a kind takes the alignment that pads it at no count. `alignmentOf` gives it from the size of
the basis set of the kind alone. Each range below is the sum and the negation, on Cascade Lake
and on Emerald Rapids under SSE2, AVX2 and AVX-512:

| Floats | Kinds | Bytes | `alignmentOf` | Time over natural |
|--------|-------|-------|---------------|-------------------|
| 3 | rga3d point and line | 24 | 8, natural | ×1 |
| 4 | rga3d motor and flector, rga4d point and plane | 32 | 32 | ×0.85 to ×1.17, Emerald Rapids |
| 5 | cga5d round point and sphere | 40 | 8, natural | ×1 |
| 6 | rga4d line | 48 | 16 | ×0.86 to ×1.08 |
| 8 | rga4d motor and flector | 64 | 64 | ×0.65 to ×1.11 |
| 10 | cga5d dipole and circle | 80 | 16 | ×0.86 to ×1.00 |
| 16 | cga5d even and odd parts | 128 | 64 | ×0.76 to ×0.97 |

The kind of 4 floats is timed at 32 bytes on Emerald Rapids alone, on 2026-10-04: 20 executions
under each of SSE2, AVX2 and AVX-512. It pads nothing there, and it gains nothing over 16 bytes,
which reads ×0.86 to ×1.00 in the same runs. So 32 bytes is safe for that count, and not better.

A kind of an odd count keeps 8 bytes, so it can still cross a line. Only padding would prevent
that, and padding costs more than the line.

`align.nim` holds `alignmentOf` at each count from 1 to 64, and at each count in the table above.
Each kind takes it from the size of its basis set when it lands, as the Architect ruled on
2026-10-04. The prototype does not apply it yet.

## Limits

- The reach is what the table can produce, not what the algebra guarantees. A sandwich comes
  back as `MultivectorOdd` at 4D, although its value lies in grade 1. An operator that knows
  better declares its product set, as `filter_product` does at pin.
- Where no alias fits, the importer reads `MultivectorOf[{E23, E31, E12}]`. P02 weighed that
  generic as the type an importer reads, and rejected it. Here it shows only where no name fits,
  and there it names the bases.
- A norm takes a root of a squared norm, so it is a scalar function, and this proposal does not
  cover it.
- The prototype generates `∧`, `⟇`, `∙`, `∘` and the round parts alone. It generates no flat
  part and no flat kind.
- The timings of kinds come from two Intel Xeons. An AMD or an ARM core is not measured.
- Cascade Lake does not time the kind of 4 floats at 32 bytes. Under AVX2 its sum ranged ×0.86
  to ×1.47 over 20 executions on Emerald Rapids.
- At pin, `align` of an expression of a generic parameter stops the compiler. So the generic
  kind chooses among 8, 16, 32 and 64 through `when`. The macro that names its kinds knows each
  count when it runs, and writes the number.
- `timing.nim` exits zero when it runs. Its figures never guard.

## Names

Each name follows the charter: head first and qualifiers last (V.2), and a property is the
bare noun (V.3).

| Slot | Proposed | Options weighed |
|------|----------|-----------------|
| One grade | `Kvector1` to `KvectorN` | `Grade1` reads as a grade; `Vector1` collides with vector |
| One parity | `MultivectorEven`, `MultivectorOdd` | `Even` says nothing in error; versor is wrong |
| Conformal flats | `Kvector2Flat` and kin | Grade, then formality, the axis `Formal[T]` names |
| Whole algebra | `Multivector` | A second name, `MultivectorWhole`, went on 2026-10-07 |
| Any set of bases | `MultivectorOf[B]` | `Blades` is wrong, below |
| Typeclass | `SomeMultivector` | Nim idiom, as `SomeInteger`; `MultivectorAny` reads as any |
| Base selector | `bases(Kvector2)` | `basesOf`, `getBases`: V.3 wants the bare noun |
| Generator | `defineMultivectors` | `defineKvectors` omits the parities |

Nim reads a name without case after its first letter, so the type `Motor` and the constant
`MOTOR` are one identifier. And `Grade` is a distinct `int`, so a selector takes an array of
grades, not a `set[Grade]`.

## Alternatives weighed

| Option | How it was tried, and why it lost |
|--------|-----------------------------------|
| Smallest named kind, as P02 | Bulk of a bivector holds zeros in half its slots |
| Generic alone, as type importer reads | Built, equal at 3D, 4D, 5D; importer saw a generic |
| `float` for a product of one slot | Scalar and antiscalar become one type, and the basis is lost |
| Return type `MultivectorOf[reachOf(...)]` | Built; it is not the same type as its alias |
| Name `Blades` for the generic | A blade factors into vectors, and a motor or a screw does not |
| One named kind for each set reached | The names would spell the bases, as the generic does |
| Contiguous ranges, `array[E41 .. E12, float]` | Plan of pin's TODO; no range names motor |
| `BasisEven`, `BasisOdd` enums with converters | Second enum, and converters for each operator |
| Basis order by parity first | Changes enum order and `succ`, which ranges use |
| Type as list of grades | Two-level slot map for what one set gives |
| Composite of typed parts, as Lengyel's fields | Second level of emission |
| Phantom grade set over full storage | Bytes moved stay at full width |
| Grade mask at run time | Branches at run time; bodies not derived |
| Filtered table copy for each pair of types | About 1.7 GB of front-end memory at 6D |
| One emitted procedure for each pair | About 6 000 bodies at 5D conformal |
| 64 bytes for each kind | Pads 3, 4, 5, 6 and 10 floats; most padded kinds ran slower |
| `align` of an expression of `B` | Pinned compiler stops: "cannot generate code for: B" |

## Open decisions

- Name the typeclass: `SomeMultivector` or `MultivectorAny`.
- Choose the operators that declare a product set, such as the sandwiches and projections.
- Generate and test the conformal flat kinds.
- Whether `Multivector` becomes the alias of the whole set, since its layout is the same.
