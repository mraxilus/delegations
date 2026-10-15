# P09: Name the geometric objects

**What it is.** `pga.nim` names the geometric objects of the book as aliases of the basis-set
types of P04. At rga4d these are `Point`, `Line`, `Plane`, `Motor` and `Flector`. At cga5d they are
`PointRound`, `Dipole`, `Circle` and `Sphere`.

**What it is for.** A caller writes the object of the book, and not `Kvector1` or a set of bases.
Each name is an alias, so the wedge of two points already is a `Line`, with no conversion. The
code then reads line by line beside the book.

**What it costs.** Nothing at run time, and no new code: an alias adds no type. So a compiler
message can print the generic with its bases, and not the name. The names cover rga4d and cga5d
alone, the algebras of 3D space that the book uses.

This proposal builds on P04, `exact-kinds`, since each name is an alias of one of its named
basis-set types. It holds the names of objects, so that P04 holds its return rule alone.

## How it works

- **Rigid names.** At rga4d, `Point` is `Kvector1`, `Line` is `Kvector2` and `Plane` is
  `Kvector3`. `Motor` is `MultivectorEven`, and `Flector` is `MultivectorOdd`.
- **Conformal names.** At cga5d, `PointRound` is `Kvector1`, `Dipole` is `Kvector2`, `Circle` is
  `Kvector3` and `Sphere` is `Kvector4`. The round point takes `PointRound`, head first, as V.2
  orders even against the word order of the domain.
- **Gate.** Each name is under `when` on the dimensions and the metric, in `pga.nim` alone.
- **Printed name.** A product of P04 spells its basis set, so its type prints as the generic. At
  rga4d, `laws.nim` prints the type of `p ∧ q` as `MultivectorOf` of six bases, and not as `Line`.
  A binding declared as `Line` prints as `Line`. So the name shows where the importer writes it.

## Laws

`laws.nim` holds each law on 256 seeded samples, at rga4d and cga5d. It imports the library with
P04 and this change applied, and nothing else. It compares each product with the wedge of the
library on a whole `Multivector`.

- At rga4d, the wedge of two points is a `Line`, and the wedge of three points is a `Plane`.
- At rga4d, `Motor` holds 8 floats of even grades, and `Flector` holds 8 floats of odd grades.
- At cga5d, the wedge of two round points is a `Dipole`, of three a `Circle`, and of four a
  `Sphere`.
- Each wedge equals the wedge of the library.

It also prints the name of the type of each first wedge, and of a binding declared with the
object name. Those names are evidence, and never guard.

## Limits

- The names cover rga4d and cga5d alone, the algebras of 3D space that the book uses. In any other
  algebra, `laws.nim` stops as it compiles.
- The flat objects wait on the flat basis-set types, which P04 does not generate yet.
- A law holds that two types are equal. No law holds the name that a compiler message prints.

## Implementation

- **Files.** `change.md` edits `pga.nim` alone. The names go under a banner of their own,
  `#[ Geometric Objects ]#`, before the banner `#[ Extraction Operators ]#`. `laws.nim` holds the
  laws.
- **Types and signatures.** The change declares nine aliases, five at rga4d and four at cga5d,
  each with its doc. An alias adds no type, so each name has the size, the alignment and the
  products of its named basis-set type.
- **Functions.** Added, removed and changed: none. Each product of P04 that reaches the bases of
  an object returns that object, since an alias is its type.
- **Callers.** No function or test of the library names an object, so none migrates there. In this
  project, `src/pga_benchmark/widening.nim` imports `pga` and exports the typed references. Those
  declare their own `Point`, `Line`, `Plane`, `Motor`, `Dipole`, `Circle` and `Sphere`. Where a
  module of this project sees both, the bare name is ambiguous once this proposal lands. So each
  use there names its module, as `rigid3.Point`.
- **Order of edits.** P04 lands first, since these names need `pga/basis_sets.nim`, which P04 adds
  and exports. The one quote of this change is the banner `#[ Extraction Operators ]#`, which no
  other proposal or change edits. So this proposal lands after P04 in any order with the rest, and
  P10 applies on top of it in either order.

## Open decisions

- Choose the names at rga3d, the rigid algebra of the plane. There the motor is antieven, grades 1
  and 3, as the typed reference of this project holds it. So `Motor` is `MultivectorOdd`, and
  `Flector` is `MultivectorEven`, with `Point` and `Line` as at rga4d.
- Choose the names at cga4d, the conformal algebra of the plane, such as `PointRound`, `Dipole`
  and `Circle` for grades 1 to 3.
- Choose the names of the even and odd basis-set types at cga5d. The glossary calls their members
  a motion operator and a reflection operator.
- Choose the names of the flat objects, such as `PointFlat`, once P04 generates flat basis-set
  types.
