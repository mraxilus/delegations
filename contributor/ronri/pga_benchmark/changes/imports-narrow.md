# Name symbols that `operators.nim` imports

Two open imports hide which internals the operators use. An open import also hid a broken
grade table from the suites.

This change names each symbol. The compiler gives the list: compile, add each symbol it names,
and compile again. The equality of `Grade` is a private borrow, so the list names `==` too.

Two proposals change which tables the operators read. Of this change and each of them, the
second to land writes the merged import:

- P08, `compound-tables`: with both applied, the build stops on
  `undeclared identifier: 'CAYLEY_SUPPORT'`. The merged import adds `CAYLEY_SUPPORT` and
  `CAYLEY_SUPPORT_ANTI` in an import under `when IS_RIGID:`. It adds `CAYLEY_CARRIER_CO`,
  `CAYLEY_CENTER` and `CAYLEY_CONTAINER` to the conformal import of `cayleys`. It drops
  `origin`, `horizon` and `infinity`, which no operator then reads. The proposal of P08 gives
  the merged import in full.
- P03, `partner-sign`, which lands after P08: the merged import also adds
  `CAYLEY_PARTNER_CONTAINER` and `CAYLEY_PARTNER_MEET` to the conformal import of `cayleys`, and
  drops `grade`.

## Edit `pga/operators.nim`

```nim
import ./[algebra {.all.}, cayleys {.all.}, helpers, multivectors]
```

```nim
import ./[helpers, multivectors]
from ./algebra {.all.} import
  Basis, Grade, GradeAnti, DIMENSIONS, IS_CONFORMAL, IS_RIGID,
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
