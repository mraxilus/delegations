# P04: Return exactly the bases a product reaches

**What it is.** A new module of the library, `pga/basis_sets.nim`, holds one generic type,
`MultivectorOf[B]`, for the coefficients of any set B of bases. It names one type for each grade,
`Kvector0` to `KvectorN`, and one for each parity, `MultivectorEven` and `MultivectorOdd`. Each
product of two such types reads the table of the library at compile time, finds the bases that its
result can reach, and returns exactly that type.

**What it is for.** At pin, each product returns a whole `Multivector` of 2ⁿ floats, also where
the result has one coefficient. A dot product writes 128 bytes at rga4d and 256 at cga5d to give
one number. Here it writes 8 bytes, and the bulk of a bivector writes 24. The type also says what
the result is. So P09 can name the objects of the book, and P10 can give each norm a type of two
floats.

**What it costs.** Each product is generic, so each pair of types that a program uses compiles a
body of its own, and that cost is unmeasured. Only `∧`, `⟇`, `∙`, `∘` and the round parts take
basis-set types, so any other operator needs a widen to `Multivector` first. `Multivector` and each
of its operators stay, so no caller changes.

This proposal holds the basis-set types of P02, `typed-multivectors`, and replaces their return
rule, as the Architect ruled on 2026-10-04. P02 returned the smallest named basis-set type that
holds a product, and P02 is withdrawn. P09, `object-names`, holds the names of objects that P02
proposed. A product whose terms all land in one slot returns a type of one slot, not a `float`, so
its type still names its basis.

## How it works

- **Basis-set types.** `MultivectorOf[B]`, with `B: static set[Basis]`, holds `card(B)` floats.
  Its field `elements` stays private, as pin keeps the field of `Multivector` private.
- **Slots.** The `Basis` enum keeps its grade-major order. The slot of a basis is the count of
  the bases of `B` below it. It folds at compile time wherever the basis is static, which in an
  emitted body it always is. A static basis outside `B` stops the compile, so no read reaches
  another slot. `coefficient` reads a basis known only at run time, and a basis outside `B` reads
  zero.
- **Names.** `Kvector0` to `KvectorN`, `MultivectorEven` and `MultivectorOdd` are aliases. A
  product that reaches one of those sets is that type, so it passes wherever the alias is asked.
  An alias adds no type, and the limits below say what the type prints. `Multivector` stays the
  whole algebra, so every line written against pin compiles.
- **Products.** The emitter walks the whole table over the bases of the two operands, and finds
  the bases that the product can reach. The tables stay whole, so the count of tables does not
  grow with the count of types. A type macro, `typeReached`, spells that set as a literal. A
  return type that computes the set through a call is not the same type as its alias.
- **No fill.** A product reaches every slot of its exact basis-set type. So each product is
  `noinit`, and writes each slot once. A product that reaches no basis returns
  `MultivectorOf[{}]`, which holds no coefficient and widens to zero.
- **Widen and narrow.** `toMultivector` widens a basis-set type to `Multivector`.
  `toMultivectorOf` narrows a `Multivector` to a basis-set type. It asserts that each other
  coefficient is zero within the comparison tolerance, which is the zero test of `grade` at pin.
  Each walks the bases of `B` with a running slot. A slot counted for each basis took ×2 to ×15
  as long, at rga4d, cga5d and rga6d on an Intel Xeon at 2.1 GHz with 4 cores, on 2026-10-15.
- **Alignment.** Each basis-set type aligns to `alignment` of its count of floats: the largest
  power of two that divides their bytes, and at most 64. So it pads no count. The empty set
  keeps the alignment of a float.
  `MultivectorOf[B]` takes it through `when`, so a named type and an unnamed type follow one
  rule.
- **Coefficients.** The basis-set types hold `float`, as `Multivector` does at pin. Under P06,
  `float-width`, they would hold `Coefficient`, and `alignment` would read
  `sizeof(Coefficient)`. P06 names them among what it leaves out.

Products stay generic, since one body for each pair of basis-set types costs too much. At 5D
conformal that is some 6 000 bodies, and most are never called. A generic makes only the pairs
that a program uses.

## What it buys

The terms that a motor sandwich on a point emits at 4D, as the prototype of P02 counts them:

| Typing | First product | Second, kept to grade 1 | Total |
|--------|---------------|-------------------------|-------|
| Untyped multivector | 192 | 192 | 384 |
| Contiguous ranges, motor at full width | 40 | 56 | 96 |
| Named basis-set types, as P02 | 20 | 28 | 48 |

An exact basis-set type holds a subset of the bases of the smallest named type that holds it.
So exact basis-set types spend at most those terms. `laws.nim` of this proposal does not count
them.

The table gives the bytes that each result holds, at rga4d and then at cga5d. The library
writes a whole `Multivector`. P02 writes the smallest named basis-set type, or `Multivector`
where none holds the result. `laws.nim` prints each exact size, and holds the rule of each row:

| Product | Library | Smallest named, as P02 | Exact, rga4d | Exact, cga5d |
|---------|---------|------------------------|--------------|--------------|
| `m ∙ n`, both whole | 128, 256 | 8, 8 | 8 | 8 |
| `m ∘ n`, both whole | 128, 256 | 8, 8 | 8 | 8 |
| `∙ m`, bulk of bivector | 128, 256 | 48, 80 | 24 | 24 |
| `∘ m`, weight of vector | 128, 256 | 32, 40 | 8 | 8 |
| `∙ m`, bulk of whole | 128, 256 | 128, 256, `Multivector` | 64 | 64 |
| Even sandwich of vector | 128, 256 | 64, 128 | 64 | 128 |

At rga4d, 16 measurands move more bytes than their multivector lower bound only because each
writes a whole multivector for one slot. They are the dot, the antidot, 6 typed dots and
antidots, and 8 squared norms. At cga5d, 15 do: the dot, the antidot, 8 typed dots and antidots,
and 5 squared norms. `baseline/static_rga4d.json` and `baseline/static_cga5d.json` hold them. A
result of one slot writes 8 bytes, which meets the bound.

P02 also returns one slot for a dot, as `Kvector0` or `KvectorN`. So this proposal gains over
P02 on the parts, and not on the dots. For the squared norms, the 8 bytes are a claim of design
alone. This change does not emit them, since the library reads each one from a 2D table with
one operand.

## Alignment of basis-set types

A basis-set type holds the count of floats of its bases. So at rga3d a vector holds 3, and at
cga5d a vector holds 5. `timing.nim` times a stand-in for each count, since a stand-in reads no
library. Each stand-in has its own sum and negation, which return by value, as the library writes
its operators.

The record of this proposal keeps no timing, so the tables below are runs by hand. On a Cascade Lake
Xeon, `linux amd64, 4 cores`, they ran with the timings of P05 on 2026-10-03. Those are five
alternating runs of pin `d9be8ae`, of 16 bytes and of 64 bytes, at four algebras, so 60 runs. Each
run takes the median of 41 rounds. They also ran on an Emerald Rapids Xeon, family 6 model 207, a
KVM guest with 4 cores, on 2026-10-04.

On Cascade Lake, each cell is the median of the 60 runs, time of each alignment over the natural
one:

| Floats | Natural | 16-byte, size | Sum | Negation | 64-byte, size | Sum | Negation |
|--------|---------|---------------|-----|----------|---------------|-----|----------|
| 3 | 24 B | 32 B | ×2.71 | ×4.54 | 64 B | ×2.98 | ×4.90 |
| 4 | 32 B | 32 B | ×0.83 | ×0.90 | 64 B | ×1.49 | ×1.61 |
| 5 | 40 B | 48 B | ×2.09 | ×2.20 | 64 B | ×2.13 | ×2.36 |
| 6 | 48 B | 48 B | ×0.88 | ×0.90 | 64 B | ×0.92 | ×0.99 |
| 8 | 64 B | 64 B | ×0.77 | ×0.83 | 64 B | ×0.74 | ×0.76 |
| 10 | 80 B | 80 B | ×0.89 | ×0.89 | 128 B | ×1.18 | ×1.32 |
| 16 | 128 B | 128 B | ×0.81 | ×0.89 | 128 B | ×0.78 | ×0.79 |

On Cascade Lake, each stand-in that an alignment pads runs slower, except 6 floats at 64 bytes.
Each stand-in that it does not pad runs faster. On Emerald Rapids, under SSE2, AVX2 and AVX-512,
3 and 5 floats padded to 16 bytes run ×2.6 to ×5.6. There, a stand-in that an alignment does not
pad runs at most ×1.17 at the median.

At 16 bytes the cause is in the machine code. The copy of a padded result reads its last 16
bytes in one load. That load spans two 8-byte stores, the last float and the zeroed padding,
and the processor cannot forward it.

So a basis-set type takes the alignment that pads it at no count. `alignment` gives it from the
size of the basis set alone. Each range below spans the medians of the sum and the negation, on
Cascade Lake and on Emerald Rapids under SSE2, AVX2 and AVX-512:

| Floats | Objects | Bytes | `alignment` | Time over natural |
|--------|---------|-------|---------------|-------------------|
| 3 | rga3d point and line | 24 | 8, natural | ×1 |
| 4 | rga3d motor and flector, rga4d point and plane | 32 | 32 | ×0.85 to ×1.17, Emerald Rapids |
| 5 | cga5d round point and sphere | 40 | 8, natural | ×1 |
| 6 | rga4d line | 48 | 16 | ×0.86 to ×1.08 |
| 8 | rga4d motor and flector | 64 | 64 | ×0.65 to ×1.11 |
| 10 | cga5d dipole and circle | 80 | 16 | ×0.86 to ×1.00 |
| 16 | cga5d even and odd parts | 128 | 64 | ×0.76 to ×0.97 |

The stand-in of 4 floats is timed at 32 bytes on Emerald Rapids alone, on 2026-10-04: 20
executions under each of SSE2, AVX2 and AVX-512. It pads nothing there, and it gains nothing over
16 bytes, which reads ×0.86 to ×1.00 in the same runs. So 32 bytes is safe for that count, and
not better.

A basis-set type of an odd count keeps 8 bytes, so it can still cross a line. Only padding would
prevent that, and padding costs more than the line.

`laws.nim` holds `alignment` at each count from 0 to 64, and at each count in the table above.
Each basis-set type takes it from the size of its basis set, as the Architect ruled on
2026-10-04. The laws hold the size and the alignment of each named basis-set type at each of the
nine algebras of the library.

## Limits

- The reach is what the table can produce, not what the algebra guarantees. A sandwich of a
  vector comes back as `MultivectorOdd` at each of the four algebras, although its value lies in
  grade 1. An operator that knows better declares its product set. The emitter at pin takes no
  grade filter, so that set comes from the table that the operator reads.
- An alias adds no type. So at rga4d, `$typeof(p ∧ q)` of two vectors prints the generic with
  its bases, and not `Kvector2`, as `laws.nim` prints:
  `MultivectorOf[{Basis.E41, Basis.E42, Basis.E43, Basis.E23, Basis.E31, Basis.E12}]`. A
  compiler message can print any name of the type. The alias serves where the importer writes a
  type in source.
- A norm takes a root of a squared norm, so it is a scalar function, and this proposal does not
  cover it.
- The change emits no squared norm. The library reads each one from a 2D table with one
  operand, and `defineProduct` takes two. A call with one type and one operand twice would emit
  it, and no law holds that form.
- The change generates `∧`, `⟇`, `∙`, `∘` and the round parts alone. It generates no flat part
  and no flat basis-set type.
- The timings of basis-set types come from two Intel Xeons. An AMD or an ARM core is not
  measured.
- Cascade Lake does not time the stand-in of 4 floats at 32 bytes. On Emerald Rapids under AVX2,
  its sum ranged ×0.86 to ×1.47 over 20 single executions. That range is of executions, and the
  medians lie inside ×0.85 to ×1.17.
- At pin, `align` of an expression of a generic parameter stops the compiler. So the generic
  basis-set type chooses among 8, 16, 32 and 64 through `when`. An alias holds no field of its
  own. So the macro that names the basis-set types writes each number into their laws, and not
  into a type.
- Each instance of a generic product takes a whole `Cayley2D` as a static argument. Its cost in
  compile time is not measured.
- `timing.nim` exits zero when it runs. Its figures never guard.

## Implementation

- **Files.** `change.md` adds one module, `pga/basis_sets.nim`, and `pga.nim` imports and exports
  it. `pga.nim` also gains the type in its bootstrap diagram, and one alias for each generic
  operator, beside the alias of that operator on `Multivector`. Three TODOs of
  `pga/multivectors.nim` asked for compact types, subsets of multivectors and even and odd bases,
  so one TODO replaces them, for the question that stays open. `laws.nim` holds the laws, and
  `timing.nim` times stand-ins of each count, with no library.
- **Types and signatures.** Every type and signature at pin stays. `MultivectorOf` and its
  aliases are new, and the new signatures are below. The constant `ALIGNMENT_MAX` stays private.
- **Functions.** The change adds the functions below, and the private `slot`, `emitSet`,
  `emitRead` and `emitWrites`. It also adds the macros `defineMultivectors`, `typeReached`,
  `defineProduct` and `defineMap`. It removes and changes no function. `defineProduct` and
  `defineMap` read the same tables as `defineOperator`, but over the bases of the operands
  alone. `defineOperator` stays, and so does every operator on `Multivector`.
- **Generic operators.** Only `∧`, `⟇`, the binary `∙` and `∘`, and the round parts are generic.
  Their aliases are `wedge`, `wedgeDotAnti`, `dot`, `dotAnti`, and `bulk` and `weight` under the
  rigid metric, or `bulkRound` and `weightRound` under the conformal one. These stay on
  `Multivector` alone: `∨` and `⟑`, the duals, complements and reverses, and the flat parts. So do
  the interior products, the squared norms and norms, `unitize`, the chains, `+`, `-`, `=~`, `$`
  and `grade`.
- **Callers.** No caller must migrate, since `Multivector` and every operator at pin stay. A
  caller that takes basis-set types widens through `toMultivector` for each operator that stays
  on `Multivector`. It narrows the result through `toMultivectorOf`, which asserts that each
  other coefficient is zero within the comparison tolerance. A caller imports `pga` alone, and
  it cannot reach `elements`, so `laws.nim` samples each type through the narrow.
- **Order of edits.** Every quote applies at pin. The changes `doc-comments` and `doc-comments-2`
  edit the import and export lines of `pga.nim`, and `doc-comments` edits the TODOs of
  `pga/multivectors.nim` too. Whichever of each pair lands second quotes those lines again. P06,
  `float-width`, turns `float` into `Coefficient`, so whichever of P06 and this proposal lands
  second writes the new module with `Coefficient`. No other proposal edits a line that this change
  quotes. P09, `object-names`, and P10, `homogeneous-scalar`, build on this proposal, so they land
  after it.

```nim
type MultivectorOf*[B: static set[Basis]] = object  # private `elements`, `card(B)` floats
type Kvector0* = MultivectorOf[{Basis.S}]  # likewise to KvectorN, MultivectorEven, MultivectorOdd
func alignment*(count: int): int
template `[]`*[B: static set[Basis]](m: MultivectorOf[B], basis: static Basis): float
template `[]=`*[B: static set[Basis]](m: var MultivectorOf[B], basis: static Basis, value: float)
func coefficient*[B: static set[Basis]](m: MultivectorOf[B], basis: Basis): float
func bases*[B: static set[Basis]](t: typedesc[MultivectorOf[B]]): set[Basis]
func toMultivector*[B: static set[Basis]](m: MultivectorOf[B]): Multivector
func toMultivectorOf*[B: static set[Basis]](
  m: Multivector, t: typedesc[MultivectorOf[B]]
): MultivectorOf[B]
macro typeReached*(cayley: static Cayley2D; bases_m, bases_n: static set[Basis]): untyped
func `∧`*[A, B: static set[Basis]](
  m: MultivectorOf[A], n: MultivectorOf[B]
): typeReached(CAYLEYS_WEDGE.base, A, B) {.noinit.}  # and ⟇, ∙, ∘ on their tables
func `∙`*[A: static set[Basis]](
  m: MultivectorOf[A],
): typeReached(CAYLEYS_PARTS.bulk.round, A) {.noinit.}  # and ∘ on weight table
```

## Names

Each name follows the charter: head first and qualifiers last (V.2), and a property is the
bare noun (V.3).

| Slot | Proposed | Options weighed |
|------|----------|-----------------|
| One grade | `Kvector0` to `KvectorN` | `Grade1` reads as a grade; `Vector1` collides with vector |
| One parity | `MultivectorEven`, `MultivectorOdd` | Bare `Even` is vague; `Motion` names too few |
| Conformal flats | `Kvector2Flat` and kin | Grade, then formality, the axis `Formal[T]` names |
| Whole algebra | `Multivector` | Rejected: `MultivectorWhole`, a second name for one type |
| Any set of bases | `MultivectorOf[B]` | `Blades` is wrong, below |
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

## Alternatives weighed

| Option | How it was tried, and why it lost |
|--------|-----------------------------------|
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
| Composite of typed parts, as Lengyel's fields | Second level of emission |
| Phantom grade set over full storage | Bytes moved stay at full width |
| Grade mask at run time | Branches at run time; bodies not derived |
| Filtered copy of each table for each pair of types | About 1.7 GB of compiler memory at 6D |
| One emitted procedure for each pair | About 6 000 bodies at 5D conformal |
| 64 bytes for each basis-set type | Pads 3, 4, 5, 6 and 10 floats; most padded ones ran slower |
| `align` of an expression of `B` | Pinned compiler stops: "cannot generate code for: B" |

One filtered copy of a 2D table costs 0.1 MB at 4D, 0.35 MB at 5D and 0.9 MB at 6D. About
eight types and thirty binary operators give some 1 900 copies, or about 1.7 GB at 6D. So the
tables stay whole, and the emitter reads only the cells of the bases of its operands.

## Open decisions

- Choose the operators that declare a product set, such as the sandwiches and projections.
- Generate and test the conformal flat basis-set types.
- Whether the library emits the squared norms as exact basis-set types, through `defineProduct`
  with one operand twice.
- Whether the narrow takes the zero test that P07, `part-scale`, gives `grade`, or the one test
  that P07 and P11, `unitize-general`, leave open. At pin it takes the zero test of `grade`.
- Whether `Multivector` becomes the alias of the whole set once P05 lands. At pin `Multivector`
  aligns to 8, and `alignment` gives the whole set 64 from rga3d up, so their layouts differ.
