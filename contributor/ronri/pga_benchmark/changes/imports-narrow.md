# Name symbols that `operators.nim` imports

Two open imports hide which internals the operators use. An open import also hid a broken
grade table from the suites.

This change names each symbol. The compiler gives the list: compile, add each symbol it names,
and compile again. The equality of `Grade` is a private borrow, so the list names `==` too.

Four proposals change which symbols the operators read. Of this change and each of them, the
second to land writes the merged import:

- P08, `compound-tables`: with both applied, the build stops on
  `undeclared identifier: 'CAYLEYS_SUPPORT'` under the rigid metric. Under the conformal metric,
  it stops on `undeclared identifier: 'CAYLEY_CARRIER_CO'`. The merged import adds
  `CAYLEYS_SUPPORT` in an import under `when IS_RIGID:`. It adds `CAYLEY_CARRIER_CO`,
  `CAYLEY_CENTER` and `CAYLEY_CONTAINER` to the conformal import of `cayleys`. It drops
  `origin`, `horizon` and `infinity`, which no operator then reads. The proposal of P08 gives
  the merged import in full.
- P03, `partner-sign`, which lands after P08: the merged import also adds
  `CAYLEY_PARTNER_CONTAINER` and `CAYLEY_PARTNER_MEET` to the conformal import of `cayleys`.
- P11, `unitize-general`: `^∘` names `TOLERANCE_ABS` in its conformal branch. With both applied,
  the conformal build stops on `undeclared identifier: 'TOLERANCE_ABS'`. The merged import adds
  `TOLERANCE_ABS` to the import from `./algebra` under `when IS_CONFORMAL:`.
- P12, `cayley-cells`: the operators read each cell through `items`. With both applied, the build
  stops on `type mismatch` at `items(cayley[b])`. The merged import adds `items` to the import of
  `cayleys`.

## Edit `pga/operators.nim`

```nim
import ./[algebra {.all.}, cayleys {.all.}, emitters, multivectors]
```

```nim
import ./[emitters, multivectors]
from ./algebra {.all.} import
  Basis, Coefficient, Grade, GradeAnti, DIMENSIONS, IS_CONFORMAL, IS_RIGID,
  grade, gradeAnti, scalar, scalarAnti, origin, high, low, `==`
from ./cayleys {.all.} import
  Cayley1D, Cayley2D, BasisSigned, Chiral, Formal, Partial, Spatial, complement,
  CAYLEYS_COMPLEMENT, CAYLEYS_DOT, CAYLEYS_DUAL, CAYLEYS_INTERIOR, CAYLEYS_PARTS,
  CAYLEYS_REVERSE, CAYLEYS_WEDGE, CAYLEYS_WEDGE_DOT, CAYLEYS_NORM_SQUARED, CAYLEY_ATTITUDE,
  horizon
when IS_CONFORMAL:
  from ./algebra {.all.} import infinity
  from ./cayleys {.all.} import CAYLEY_CARRIER, CAYLEYS_NORM_SQUARED_RADIUS
```
