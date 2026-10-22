# P02: Generate concrete k-vector types for any dimension

**What it is.** One macro call generates a concrete object type for each grade and for both
parities, from `DIMENSIONS` alone. It is withdrawn, since P04 now holds these types, and P09 their
names.

**What it is for.** Each product returns the smallest of these types that holds what it can reach.
So a motor sandwich on a point emits far fewer terms than on `Multivector`.

**What it costs.** The return type follows what the table can reach, not what the algebra
guarantees. So a sandwich can come back in a type wider than its value.

## Problem

At pin, every product reads and returns `Multivector`, which stores the whole algebra. So a motor
sandwich on a point emits the terms of an untyped multivector. Yet a point and a motor each hold
only some of the bases.

## Idea

- **Basis-set types.** `Kvector0` to `KvectorN`, one for each grade, then `MultivectorEven` and
  `MultivectorOdd`. Each type stores only its own bases, densely.
- **Indexes.** The `Basis` enum keeps its grade-major order. The index of a basis in a type is
  the count of the bases of the type below it. It folds at compile time wherever the basis is
  static, which in an emitted body it always is.
- **Products.** Products are generic over the closed set of these types. The emitter walks the
  whole table over the bases of the two operands. It finds the bases the product can reach, and
  returns the smallest type that holds them. Grade restriction lives in the emission, so the
  tables stay whole.
- **Names of objects.** `pga.nim` names the geometric objects, one alias for each line, gated on
  the algebra: `Point`, `Line`, `Plane`, `Motor` and their conformal kin. The library below
  knows no geometry.

The signatures stay generic, since a generic instantiates only the pairs of types that a program
uses. An importer writes `p ∧ q` and reads `Kvector2`, never a generic.

### Mechanics the prototype settled

- A compile-time index function cannot serve a runtime body. So `index` is a plain function,
  and `static(...)` forces it where the basis is static.
- `quote do` cannot embed a set value, so the macro builds the literal first.
- The typeclass needs an explicit type section.
- An `auto` result over a block that a macro builds infers the concrete type.

## Alternatives

| Option | Why it lost |
|--------|-------------|
| Contiguous ranges, `array[E41 .. E12, float]` | Plan of pin's TODO; no range names motor |
| `BasisEven`, `BasisOdd` enums with converters | Second enum, and converters for each operator |
| Basis order by parity first | Changes enum order and `succ`, which ranges use |
| Type as list of grades | Two-level index map for what one set gives |
| Composite of typed parts, as Lengyel's fields | Second level of emission |
| Phantom grade set over full storage | Bytes moved stay at full width |
| Grade mask at run time | Branches at run time; bodies not derived |
| Filtered table copy for each pair of types | About 1.7 GB of front-end memory at 6D |
| Exported generic over `static set[Basis]` | Built, equal at 3D, 4D, 5D; importer sees generic |
| One emitted procedure for each pair | About 6 000 bodies at 5D conformal, most never called |

### Names

Each name follows the charter: head first and qualifiers last (V.2), and a property is the
bare noun (V.3).

| Concept | Proposed | Options weighed |
|---------|----------|-----------------|
| One grade | `Kvector1` to `KvectorN` | `Grade1` reads as a grade; `Vector1` collides with vector |
| One parity | `MultivectorEven`, `MultivectorOdd` | Bare `Even` is vague; `Motion` names too few |
| Conformal flats | `Kvector2Flat` and kin | Grade, then formality, the axis `Formal[T]` names |
| Whole algebra | `Multivector` | Unchanged |
| Typeclass | `SomeMultivector` | Nim idiom, as `SomeInteger`; `MultivectorAny` reads as any |
| Base selector | `bases(Kvector2)` | `basesOf`, `getBases`: V.3 wants the bare noun |
| Generator | `defineMultivectors` | `defineKvectors` omits the parities |

Two mechanics bind the names. Nim ignores case after the first letter, so a type `Motor` and a
constant `MOTOR` are one identifier. `Grade` is a distinct `int`, so a selector takes an array
of grades, not a `set[Grade]`.

## Costs

- **Reach.** A sandwich comes back as `MultivectorOdd` at 4D, although its value lies in grade 1.
  An operator that knows better declares its product set, as `filter_product` does at the pin of
  its evaluation. P04, `exact-kinds`, replaces this return rule, as the Architect ruled on
  2026-10-04.
- **Callers.** `Multivector` stays the whole algebra, unchanged, so every line written today
  compiles.
- **Scope.** The prototype generates `∧` and `⟇` only, and no conformal flat types.

## Open decisions

- Name the typeclass: `SomeMultivector` or `MultivectorAny`.
- Choose the operators that declare a product set, such as the sandwiches and projections.
- Generate and test the conformal flat types.

## Landing

- **Order.** The prototype reads the derived tables of P01, `cayley-derivation`, by their names
  there.

## Evidence

The terms that a motor sandwich on a point emits at 4D:

| Typing | First product | Second, kept to grade 1 | Total |
|--------|---------------|-------------------------|-------|
| Untyped multivector | 192 | 192 | 384 |
| Contiguous ranges, motor at full width | 40 | 56 | 96 |
| Generated types over sets of bases | 20 | 28 | 48 |
