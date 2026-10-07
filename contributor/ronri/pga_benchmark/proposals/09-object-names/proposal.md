# P09: Name the geometric objects

`pga.nim` names the geometric objects of each algebra, one alias for each name, gated on the
algebra. Each name is an alias of a kind of P04, so the importer reads the object, not its
bases. The library below `pga.nim` knows no geometry.

This proposal builds on P04, `exact-kinds`, since each name is an alias of one of its kinds. It
came out of P04 when the Architect ruled on 2026-10-07, so that P04 holds its return rule alone.

## What it is

- **Rigid names.** At rga4d, `Point` is `Kvector1`, `Line` is `Kvector2` and `Plane` is
  `Kvector3`. `Motor` is `MultivectorEven`, and `Flector` is `MultivectorOdd`.
- **Conformal names.** At cga5d, `RoundPoint` is `Kvector1`, `Dipole` is `Kvector2`, `Circle` is
  `Kvector3` and `Sphere` is `Kvector4`.
- **Gate.** Each name is under `when` on the dimensions and the metric, in `pga.nim` alone.

## Limits

- No program holds these names, since the kinds of P04 live in its prototype alone. So this
  proposal makes no claim, and its evidence waits until P04 lands.
- Other dimensions name other objects, so they get no names here.
- The flat objects wait on the flat kinds, which P04 does not generate yet.

## Open decisions

- Choose the names of the flat objects, such as `FlatPoint`, once P04 generates flat kinds.
