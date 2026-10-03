# P04: Return exactly the bases a product reaches

One generic object holds the coefficients of any set of bases, dense in basis order. Each kind
of P02 is an alias of it: one for each grade, one for each parity, and one for the whole
algebra. A product returns the kind of exactly the bases that its table reaches. So a dot
product writes one slot, and the bulk of a bivector writes only the part of its grade it reaches.

This proposal builds on P02, `typed-multivectors`, and reads the tables that P01 derives. A
product whose terms all land in one slot returns a kind of one slot, not a `float`. So its type
still names its basis.

## What it is

- **Exact kinds.** `MultivectorOf[B]`, with `B: static set[Basis]`, holds `card(B)` floats. The
  slot of a basis is the count of the bases of `B` below it, folded at compile time.
- **Names.** `Kvector0` to `KvectorN`, `MultivectorEven`, `MultivectorOdd` and
  `MultivectorWhole` are aliases. A product that reaches one of those sets is that type, so the
  importer reads its name.
- **Products.** A type macro, `kindOf`, spells the set that a product reaches as a literal. A
  return type that computes the set through a call is not the same type as its alias.
- **No fill.** A product reaches every slot of its kind. So each product is `noinit`, and
  writes each slot once.

## What it buys

Bytes that each result holds, read with `sizeof` from the prototype:

| Product | Library | Smallest P02 kind | Exact kind, rga4d | Exact kind, cga5d |
|---------|---------|-------------------|-------------------|-------------------|
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

- The reach is what the table can produce, as in P02. A sandwich still reaches every odd basis.
- Where no alias fits, the importer reads `MultivectorOf[{E23, E31, E12}]`. P02 weighed that generic
  and rejected it. Here it shows only where no name fits, and there it names the bases.
- A norm takes a root of a squared norm, so it is a scalar function, and this proposal does not
  cover it.
- The prototype generates `∧`, `⟇`, `∙`, `∘` and the round parts alone, and no flat parts.

## Alternatives weighed

| Option | How it was tried, and why it lost |
|--------|-----------------------------------|
| `float` for a product of one slot | Scalar and antiscalar become one type, and the basis is lost |
| Smallest named kind, as P02 | Bulk of a bivector holds zeros in half its slots |
| Return type `MultivectorOf[reachOf(...)]` | Built; it is not the same type as its alias |
| Name `Blades` for the generic | A blade factors into vectors, and a motor or a screw does not |
| One named kind for each set reached | The names would spell the bases, as the generic does |

## Open decisions

- Whether `Multivector` becomes the alias of the whole set, since its layout is the same.
- Name the whole kind: `MultivectorWhole`, or another name.
