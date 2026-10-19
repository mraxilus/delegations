# P09: Name the geometric objects

**What it is.** `pga.nim` names the geometric objects of the book, each as an alias of one
basis-set type.

**What it is for.** A caller writes the object of the book, and not `Multivector1` or a set of
bases.
So the code reads line by line beside the book.

**What it costs.** Nothing at run time, but a compiler message can print the generic with its
bases, and not the name. The names cover rga4d and cga5d alone.

## Problem

At pin, the library names no geometric object of the book. It names basis-set types such as
`Multivector1` and `MultivectorEven`. So a caller writes `Multivector1` or a set of bases, where
the book writes a point or a line.

## Idea

Each name is an alias of one named basis-set type of the library. It stands in `pga.nim` alone,
under `when` on the dimensions and the metric.

- **Rigid names.** At rga4d, `Point` is `Multivector1`, `Line` is `Multivector2` and `Plane` is
  `Multivector3`. `Motor` is `MultivectorEven`, and `Flector` is `MultivectorOdd`.
- **Conformal names.** At cga5d, `PointRound` is `Multivector1`, `Dipole` is `Multivector2`,
  `Circle` is `Multivector3` and `Sphere` is `Multivector4`.
- **No new type.** An alias adds no type, so each name has the size, the alignment and the
  products of its basis-set type. Each product of P04 that reaches the bases of an object returns
  that object. So the wedge of two points already is a `Line`, with no conversion.

## Alternatives

| Option | Why it lost |
|--------|-------------|
| `RoundPoint`, in the word order of the domain | V.2 puts the head first, as in `PointRound` |

## Costs

- **Two algebras.** The names cover rga4d and cga5d alone, the algebras of 3D space that the book
  uses. In any other algebra, `laws.nim` stops as it compiles.
- **No flat objects.** The flat objects wait on the flat basis-set types, which the library does
  not name yet.
- **Printed name.** A product of P04 spells its basis set, so a compiler message prints its type
  as the generic with its bases. The name shows only where the importer writes it. A law holds
  that two types are equal, and no law holds the name that a compiler message prints.
- **Callers.** No function or test of the library names an object, so none migrates there.
- **Callers in this project.** `src/pga_benchmark/widening.nim` imports `pga` and exports the
  typed references. These declare their own `Point`, `Line`, `Plane`, `Motor`, `PointRound`,
  `Dipole`, `Circle` and `Sphere`. If a module sees both, it reads each bare name as ambiguous,
  and the bench of the evaluation does not build. So `widening.nim`, `pools.nim` and
  `measurements.nim` import `pga` except these names, and the typed references keep them. Nim
  takes `except` of a name that the library lacks, so the same line builds at pin.

## Open decisions

- Choose the names at rga3d, the rigid algebra of the plane. There the motor is antieven, grades 1
  and 3, as the typed reference of this project holds it. So `Motor` is `MultivectorOdd`, and
  `Flector` is `MultivectorEven`, with `Point` and `Line` as at rga4d.
- Choose the names at cga4d, the conformal algebra of the plane, such as `PointRound`, `Dipole`
  and `Circle` for grades 1 to 3.
- Choose the names of the even and odd basis-set types at cga5d. The glossary calls their members
  a motion operator and a reflection operator.
- Choose the names of the flat objects, such as `PointFlat`, once the library names flat
  basis-set types.

## Landing

- **Order.** P04 lands first, since the laws of these names need its products, which return
  these types. This proposal holds the names apart from P04, so that P04 holds its return rule
  alone.
- **Quotes.** The one quote of this change is the banner `#[ Extraction Operators ]#`, which no
  other proposal or change edits. So this proposal lands after P04 in any order with the rest.
  P10 applies on top of it in either order.

## Evidence

`laws.nim` imports the library with P04 and this change applied, and nothing else. It holds these
laws on 256 seeded samples:

- At rga4d, the wedge of two points is a `Line`, and the wedge of three points is a `Plane`.
- At rga4d, `Motor` holds 8 coefficients of even grades, and `Flector` holds 8 of odd grades.
- At cga5d, the wedge of two round points is a `Dipole`, of three a `Circle`, and of four a
  `Sphere`.
- Each wedge equals the wedge of the library, on a whole `Multivector`.

`laws.nim` also prints the type of each first wedge, and of a binding declared with the object
name. At rga4d, it prints the type of `p ∧ q` as `MultivectorOf` of six bases, and a binding
declared as `Line` as `Line`. These prints are evidence, and never guard.
