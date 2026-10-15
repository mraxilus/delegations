# P09: Name the geometric objects

`pga.nim` names the geometric objects of rga4d and cga5d, the algebras of 3D space that the book
uses. Each name is an alias of a named basis-set type of P04, gated on the algebra. So the
importer writes the object, not its bases. An alias adds no type, so a compiler message can print
any name of the type. The library below `pga.nim` knows no geometry.

This proposal builds on P04, `exact-kinds`, since each name is an alias of one of its named
basis-set types. It holds the names of objects, so that P04 holds its return rule alone.

## What it is

- **Rigid names.** At rga4d, `Point` is `Kvector1`, `Line` is `Kvector2` and `Plane` is
  `Kvector3`. `Motor` is `MultivectorEven`, and `Flector` is `MultivectorOdd`.
- **Conformal names.** At cga5d, `RoundPoint` is `Kvector1`, `Dipole` is `Kvector2`, `Circle` is
  `Kvector3` and `Sphere` is `Kvector4`.
- **Gate.** Each name is under `when` on the dimensions and the metric, in `pga.nim` alone.
- **Printed name.** A product of P04 spells its basis set, so its type prints as the generic. At
  rga4d, `laws.nim` prints the type of `p ∧ q` as `MultivectorOf` of six bases, and not as `Line`.
  A binding declared as `Line` prints as `Line`. So the name shows where the importer writes it.

## Laws

`laws.nim` holds each law on 256 seeded samples, at rga4d and cga5d. It imports the prototype of
P04, as P10 does. It compares each product with the wedge of the library on a whole
`Multivector`.

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
- The basis-set types of P04 live in its prototype alone. So `laws.nim` imports that prototype,
  and the names wait in `pga.nim` until P04 lands.
- The flat objects wait on the flat basis-set types, which P04 does not generate yet.
- A law holds that two types are equal. No law holds the name that a compiler message prints.

## Implementation

- **Files.** This proposal edits `pga.nim` alone. The names go after its import and export lines,
  and before the banner `#[ Extraction Operators ]#`. This proposal has no `change.md`, since its
  aliases need P04 in the library. The block below gives the code, and `laws.nim` holds the same
  names.
- **Types and signatures.** The block below declares nine aliases, five at rga4d and four at cga5d,
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
  and exports. P04, P10 and the changes `doc-comments` and `doc-comments-2` edit the import and
  export lines of `pga.nim`. These names go below those lines and quote none of them. No other
  proposal or change edits the banner after them, so this proposal lands after P04 in any order with
  the rest.

```nim
when DIMENSIONS == 4 and IS_RIGID:
  type
    Point* = Kvector1  ## Define point of 3D space, grade 1.
    Line* = Kvector2  ## Define line, grade 2.
    Plane* = Kvector3  ## Define plane, grade 3.
    Motor* = MultivectorEven  ## Define motor, even grades.
    Flector* = MultivectorOdd  ## Define flector, odd grades.

when DIMENSIONS == 5 and IS_CONFORMAL:
  type
    RoundPoint* = Kvector1  ## Define round point of 3D space, grade 1.
    Dipole* = Kvector2  ## Define dipole, grade 2.
    Circle* = Kvector3  ## Define circle, grade 3.
    Sphere* = Kvector4  ## Define sphere, grade 4.
```

## Open decisions

- Choose the names at rga3d, the rigid algebra of the plane. There the motor is antieven, grades 1
  and 3, as the typed reference of this project holds it. So `Motor` is `MultivectorOdd`, and
  `Flector` is `MultivectorEven`, with `Point` and `Line` as at rga4d.
- Choose the names at cga4d, the conformal algebra of the plane, such as `RoundPoint`, `Dipole`
  and `Circle` for grades 1 to 3.
- Spell the round point `PointRound`, head first as V.2 orders and as the operand kinds of this
  project spell it, or `RoundPoint`, as Lengyel does. The same holds for `FlatPoint`.
- Choose the names of the even and odd basis-set types at cga5d. The glossary calls their members
  a motion operator and a reflection operator.
- Choose the names of the flat objects, such as `FlatPoint`, once P04 generates flat basis-set
  types.
