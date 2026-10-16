# P04: Return exactly the bases a product reaches

**What it is.** A new module of the library holds one generic type for the coefficients of any set
of bases. Each product of two such types returns exactly the bases that its table can reach.

**What it is for.** A product writes only the coefficients that it reaches, so a dot product
writes one number and not a whole multivector. The type of the result also says what it is.

**What it costs.** The compiler builds a body for each pair of types that a program uses, and no
measurement covers that cost. Only `∧`, `⟇`, `∙`, `∘` and the round parts take basis-set types,
so each other operator needs a widen first.

## Problem

At pin, each product returns a whole `Multivector` of 2ⁿ floats, also where the result has one
coefficient. So a dot product writes 128 bytes at rga4d and 256 at cga5d to give one number. The
type of the result does not say what the result is.

At rga4d, 16 measurands move more bytes than their multivector lower bound only because each
writes a whole multivector for one slot. They are the dot, the antidot, 6 typed dots and
antidots, and 8 squared norms. At cga5d, 15 do: the dot, the antidot, 8 typed dots and antidots,
and 5 squared norms. `baseline/static_rga4d.json` and `baseline/static_cga5d.json` hold them.

Three TODOs of `pga/multivectors.nim` ask for compact types, for subsets of multivectors and for
even and odd bases. This proposal replaces them with one TODO, for the question that stays open.

## Idea

### One type for any set of bases

`MultivectorOf[B]`, with `B: static set[Basis]`, holds `card(B)` floats, dense in basis order.

One macro names an alias for each grade and for each parity: `Kvector0` to `KvectorN`,
`MultivectorEven` and `MultivectorOdd`. An alias adds no type. So a product that reaches one of
those sets is that type, and it passes wherever the alias is asked. At rga4d the macro writes
these seven aliases:

| Alias | Bases at `rga4d` | Coefficients |
|-------|------------------|-------------:|
| `Kvector0` | `S` | 1 |
| `Kvector1` | `E1`, `E2`, `E3`, `E4` | 4 |
| `Kvector2` | `E41`, `E42`, `E43`, `E23`, `E31`, `E12` | 6 |
| `Kvector3` | `E423`, `E431`, `E412`, `E321` | 4 |
| `Kvector4` | `E1234` | 1 |
| `MultivectorEven` | `S`, the six bivectors and `E1234` | 8 |
| `MultivectorOdd` | the four vectors and the four trivectors | 8 |

### Slots

The `Basis` enum keeps its grade-major order. The slot of a basis is the count of the bases of `B`
below it. `slot` takes it from one set intersection, the bases of `B` up to the basis, less the
basis itself. It folds at compile time wherever the basis is static, which in an emitted body it
always is. So each read and each write uses a fixed offset. A static basis outside `B` stops the
compile, so no read reaches another slot.

`coefficient` reads a basis known only at run time, through a table that the compiler builds.
There, a basis outside `B` reads zero.

### Products

The emitter walks the whole table of the library over the bases of the two operands. It finds the
bases that the product can reach, and writes one line for each. `defineProduct` and `defineMap`
read the same tables as `defineOperator`, over the bases of the operands alone. So the tables stay
whole, and their count does not grow with the count of types. Products are generic, so a program
makes only the pairs of types that it uses.

A product reaches every slot of its exact basis-set type. So each product is `noinit`, and writes
each slot once. A product that reaches no basis returns `MultivectorOf[{}]`, which holds no
coefficient and widens to zero.

`typeReached` names the result type, and `defineProduct` or `defineMap` fills it. Both read the
same table, so the type and the body agree. `typeReached` spells the set as a literal, one basis
at a time, through `emitSet`. Nim reads the argument of a generic type as it is spelled. A sum typed
`MultivectorOf[A + B]` came out as `{E1..E4}`, and Nim refused it where it expected
`{E1, E2, E3, E4}`. `emitSet` spells each alias and each result, so each names the same type.

For example, at `rga3d` the product `Kvector1 ∧ Kvector1` reaches `Kvector2`, and
`defineProduct` writes three lines:

```nim
result[Basis.E23] = m[Basis.E2] * n[Basis.E3] + -(m[Basis.E3] * n[Basis.E2])
result[Basis.E31] = -(m[Basis.E1] * n[Basis.E3]) + m[Basis.E3] * n[Basis.E1]
result[Basis.E12] = m[Basis.E1] * n[Basis.E2] + -(m[Basis.E2] * n[Basis.E1])
```

The accessors then fold each basis to its slot, so the compiled body reads fixed offsets alone:

```nim
result.elements[0] = m.elements[1] * n.elements[2] + -(m.elements[2] * n.elements[1])
result.elements[1] = -(m.elements[0] * n.elements[2]) + m.elements[2] * n.elements[0]
result.elements[2] = m.elements[0] * n.elements[1] + -(m.elements[1] * n.elements[0])
```

No term that the table makes zero appears, such as `e2 ∧ e2`. The product holds no loop, no
branch and no lookup. `(𝐞₁ + 2𝐞₂) ∧ (3𝐞₂ + 4𝐞₃)` gives `8𝐞₂₃ - 4𝐞₃₁ + 3𝐞₁₂`, as by hand.

### Widen and narrow

`toMultivector` widens a basis-set type to `Multivector`, and `toMultivectorOf` narrows it back.
The narrow asserts that each other coefficient is zero within the comparison tolerance, which is
the zero test of `grade` at pin. Each walks the bases of `B` with a running slot.

### Alignment

Each basis-set type aligns to `alignment` of its count of floats: the largest power of two that
divides their bytes, and at most 64. So it pads no count, and the empty set keeps the alignment of
a float. Each takes it from the size of its basis set, as the Architect ruled on 2026-10-04.
`MultivectorOf[B]` chooses among 8, 16, 32 and 64 through `when`, so a named type and an unnamed
type follow one rule.

## Alternatives

This proposal keeps the basis-set types of P02, `typed-multivectors`, and replaces its return rule,
as the Architect ruled on 2026-10-04. P02 returned the smallest named basis-set type that holds a
product, and it is withdrawn.

| Option | Why it lost |
|--------|-------------|
| Smallest named basis-set type, as P02 | Bulk of a bivector holds zeros in half its slots |
| Generic alone, with no alias | Built, equal at 3D, 4D, 5D; importer spells bases in source |
| `float` for a product of one slot | Scalar and antiscalar become one type, and the basis is lost |
| Return type `MultivectorOf[reach(...)]` | Built; it is not the same type as its alias |
| Name `Blades` for the generic | A blade factors into vectors, and a motor or a screw does not |
| One named type for each set reached | The names would spell the bases, as the generic does |
| Contiguous ranges, `array[E41 .. E12, float]` | Plan of pin's TODO; no range names motor |
| `BasisEven`, `BasisOdd` enums with converters | Second enum, and converters for each operator |
| Basis order by parity first | Changes enum order and `succ`, which ranges use |
| Type as list of grades | Two-level slot map for what one set gives |
| Slot counted by a loop over `Basis` | The Architect ruled for the intersection on 2026-10-16 |
| Composite of typed parts, as Lengyel's fields | Second level of emission |
| Phantom grade set over full storage | Bytes moved stay at full width |
| Grade mask at run time | Branches at run time; bodies not derived |
| Filtered copy of each table for each pair of types | About 1.7 GB of compiler memory at 6D |
| One emitted procedure for each pair | About 6 000 bodies at 5D conformal, most never called |
| 64 bytes for each basis-set type | Pads 3, 4, 5, 6 and 10 floats; most padded ones ran slower |
| `align` of an expression of `B` | Pinned compiler stops: "cannot generate code for: B" |

One filtered copy of a 2D table costs 0.1 MB at 4D, 0.35 MB at 5D and 0.9 MB at 6D. About eight
types and thirty binary operators give some 1 900 copies, or about 1.7 GB at 6D.

### Names

Each name follows the charter: head first and qualifiers last (V.2), and a property is the
bare noun (V.3).

| Slot | Proposed | Options weighed |
|------|----------|-----------------|
| One grade | `Kvector0` to `KvectorN` | `Grade1` reads as a grade; `Vector1` collides with vector |
| One parity | `MultivectorEven`, `MultivectorOdd` | Bare `Even` is vague; `Motion` names too few |
| Conformal flats | `Kvector2Flat` and kin | Grade, then formality, the axis `Formal[T]` names |
| Whole algebra | `Multivector` | Rejected: `MultivectorWhole`, a second name for one type |
| Any set of bases | `MultivectorOf[B]` | `Blades` is wrong, above |
| Typeclass | None: each operator is generic over `MultivectorOf[B]` | `SomeMultivector` |
| Base selector | `bases(Kvector2)` | `basesOf`, `getBases`: V.3 wants the bare noun |
| Generator | `defineMultivectors` | `defineKvectors` omits the parities |
| Widen | `toMultivector` | `to<Target>` names a change of representation (V.3) |
| Narrow | `toMultivectorOf(m, Kvector2)` | `toKvector2` and kin, one name for each alias |
| Read at run time | `coefficient(m, basis)` | `getCoefficient`: V.3 wants the bare noun |
| Type a product reaches | `typeReached(cayley, A, B)` | `kindOf`: glossary keeps kind for operand |
| Alignment of a count | `alignment(count)` | `alignmentOf`: V.3 wants the bare noun |

Nim reads a name without case after its first letter, so the type `Motor` and the constant
`MOTOR` are one identifier.

## Costs

- **Compile time.** Each instance of a generic product takes a whole `Cayley2D` as a static
  argument. No measurement covers its cost in compile time.
- **Few generic operators.** Only `∧`, `⟇`, the binary `∙` and `∘`, and the round parts are
  generic. These stay on `Multivector` alone: `∨` and `⟑`, the duals, complements and reverses,
  and the flat parts. So do the interior products, the squared norms and norms, `unitize`, the
  chains, `+`, `-`, `=~`, `$` and `grade`. A caller widens a basis-set type for each of them, and
  narrows the result back. The change generates no flat basis-set type.
- **Reach of the table.** The reach is what the table can produce, not what the algebra
  guarantees. A sandwich of a vector comes back as `MultivectorOdd` at each of the four algebras,
  although its value lies in grade 1. An operator that knows better declares its product set. The
  emitter at pin takes no grade filter, so that set comes from the table that the operator reads.
- **Printed name.** At rga4d, `$typeof(p ∧ q)` of two vectors prints the generic with its bases,
  and not `Kvector2`, as `laws.nim` prints:
  `MultivectorOf[{Basis.E41, Basis.E42, Basis.E43, Basis.E23, Basis.E31, Basis.E12}]`. A compiler
  message can print any name of the type. The alias serves where the importer writes a type in
  source.
- **Norms.** A norm takes a root of a squared norm, so it is a scalar function, and this proposal
  does not cover it. The change emits no squared norm. The library reads each one from a 2D table
  with one operand, and `defineProduct` takes two. A call with one type and one operand twice
  would emit it, and no law holds that form.
- **Alignment.** A basis-set type of an odd count keeps 8 bytes, so it can still cross a line.
  Only padding would prevent that, and padding costs more than the line. An alias holds no field
  of its own. So the macro that names the basis-set types writes each number into their laws, and
  not into a type.
- **Callers.** No caller must migrate, since `Multivector` and every operator at pin stay. The
  field `elements` stays private, as on `Multivector` at pin. So a caller that imports `pga` alone
  cannot reach it, and `laws.nim` samples each type through the narrow.
- **Machines.** The runtime measurements of basis-set types come from two Intel Xeons. None
  covers an AMD or an ARM core.

## Open decisions

- Choose the operators that declare a product set, such as the sandwiches and projections.
- Generate and test the conformal flat basis-set types.
- Whether the library emits the squared norms as exact basis-set types, through `defineProduct`
  with one operand twice.
- Whether the narrow takes the zero test that P07, `part-scale`, gives `grade`, or the one test
  that P07 and P11, `unitize-general`, leave open. At pin it takes the zero test of `grade`.
- Whether `Multivector` becomes the alias of the whole set once P05 lands. At pin `Multivector`
  aligns to 8, and `alignment` gives the whole set 64 from rga3d up, so their layouts differ.

## Landing

- **Quotes.** Every quote applies at pin. No other proposal edits a line that this change quotes.
- **Changes `doc-comments` and `doc-comments-2`.** Both edit the import and export lines of
  `pga.nim`, and `doc-comments` edits the TODOs of `pga/multivectors.nim` too. Whichever of each
  pair lands second quotes those lines again.
- **P06, `float-width`.** The basis-set types hold `float`, as `Multivector` does at pin. P06 turns
  `float` into `Coefficient`, and names these types among what it leaves out. So whichever of the
  two lands second writes the new module with `Coefficient`, and `alignment` reads
  `sizeof(Coefficient)`.
- **P09 and P10.** P09, `object-names`, holds the names of objects that P02 proposed, so it can
  name the objects of the book. P10, `homogeneous-scalar`, can give each norm a type of two floats.

## Evidence

### Bytes and terms

The table gives the bytes that each result holds, at rga4d and then at cga5d. At pin each one is a
whole `Multivector`. P02 writes the smallest named basis-set type, or `Multivector` where none
holds the result. `laws.nim` prints each exact size, and holds the rule of each row.

| Product | Smallest named, as P02 | Exact, rga4d | Exact, cga5d |
|---------|------------------------|--------------|--------------|
| `m ∙ n`, both whole | 8, 8 | 8 | 8 |
| `m ∘ n`, both whole | 8, 8 | 8 | 8 |
| `∙ m`, bulk of bivector | 48, 80 | 24 | 24 |
| `∘ m`, weight of vector | 32, 40 | 8 | 8 |
| `∙ m`, bulk of whole | 128, 256, `Multivector` | 64 | 64 |
| Even sandwich of vector | 64, 128 | 64 | 128 |

A result of one slot writes 8 bytes, which meets the multivector lower bound. P02 also returns one
slot for a dot, as `Kvector0` or `KvectorN`. So this proposal gains over P02 on the parts, and not
on the dots. For the squared norms, the 8 bytes are a claim of design alone, since the change
emits none.

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

### Slot during compilation

One compile at rga6d calls `slot` 2,282 times. Each figure is the cost of one call, the median of
three runs of about 300,000 calls on 2026-10-15, with the forms run in turn. The noise was about
±1.5 µs for each call.

| Bases | Intersection | Loop over `Basis` |
|-------|--------------|-------------------|
| Vectors | 2.4 µs | 0.8 µs |
| Even | 4.9 µs | 16.8 µs |
| Whole | 9.8 µs | 6.5 µs |

So the calls of one compile take at most about 22 ms with the intersection, and 38 ms with the
loop. That compile takes 8.3 s, so each form costs under 0.5% of it.

### Running slot

In the widen and the narrow, a slot counted for each basis took ×1.05 to ×16.5 as long as the
running slot. It ran at rga4d, cga5d and rga6d on an Intel Xeon at 2.1 GHz with 4 cores, on
2026-10-15. The gain grows with the count of bases, and a vector gains least.
