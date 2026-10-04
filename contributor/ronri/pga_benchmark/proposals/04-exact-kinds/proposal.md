# P04: Return exactly the bases a product reaches

One generic object holds the coefficients of any set of bases, dense in basis order. One macro
call names a kind for each grade, for both parities and for the whole algebra, from `DIMENSIONS`
alone. Each named kind is an alias of the generic one. A product returns the kind of exactly the
bases that its table reaches. So a dot product writes one slot, and the bulk of a bivector writes
only the part of its grade it reaches.

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
- **Names.** `Kvector0` to `KvectorN`, `MultivectorEven`, `MultivectorOdd` and
  `MultivectorWhole` are aliases. A product that reaches one of those sets is that type, so the
  importer reads its name. `Multivector` stays the whole algebra, so every line written today
  compiles.
- **Products.** The emitter walks the whole table over the bases of the two operands, and finds
  the bases that the product can reach. A type macro, `kindOf`, spells that set as a literal. A
  return type that computes the set through a call is not the same type as its alias.
- **No fill.** A product reaches every slot of its kind. So each product is `noinit`, and
  writes each slot once.
- **Names of objects.** `pga.nim` names the geometric objects, one alias for each line, gated on
  the algebra: `Point`, `Line`, `Plane`, `Motor` and their conformal kin. The library below
  knows no geometry.

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
  part and no flat kind, and it names no geometric object.

## Names

Each name follows the charter: head first and qualifiers last (V.2), and a property is the
bare noun (V.3).

| Slot | Proposed | Options weighed |
|------|----------|-----------------|
| One grade | `Kvector1` to `KvectorN` | `Grade1` reads as a grade; `Vector1` collides with vector |
| One parity | `MultivectorEven`, `MultivectorOdd` | `Even` says nothing in error; versor is wrong |
| Conformal flats | `Kvector2Flat` and kin | Grade, then formality, the axis `Formal[T]` names |
| Whole algebra | `Multivector`, and alias `MultivectorWhole` | Open, below |
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

## Open decisions

- Name the typeclass: `SomeMultivector` or `MultivectorAny`.
- Choose the operators that declare a product set, such as the sandwiches and projections.
- Generate and test the conformal flat kinds.
- Whether `Multivector` becomes the alias of the whole set, since its layout is the same.
- Name the whole kind: `MultivectorWhole`, or another name.
