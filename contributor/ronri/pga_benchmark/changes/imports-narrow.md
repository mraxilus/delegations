# Name symbols that `operators.nim` imports

Two open imports hide which internals the operators use. An open import also hid a broken
grade table from the suites.

This change names each symbol. The compiler gives the list: compile, add each symbol it names,
and compile again. The equality of `Grade` is a private borrow, so the list names `==` too.

## Edit `pga/operators.nim`

```nim
import ./[algebra {.all.}, helpers, cayleys {.all.}, multivectors]
```

```nim
import ./[helpers, multivectors]
from ./algebra {.all.} import
  Basis, Grade, GradeAnti, DIMENSIONS, IS_CONFORMAL, IS_RIGID,
  grade, gradeAnti, scalar, scalarAnti, origin, high, low, `==`
from ./cayleys {.all.} import
  Cayley1D, Cayley2D, BasisSigned, Chiral, Formal, Partial, Spatial, complement,
  CAYLEYS_COMPLEMENT, CAYLEYS_CONTRACT, CAYLEYS_DOT, CAYLEYS_DUAL, CAYLEYS_EXPAND,
  CAYLEYS_PARTS, CAYLEYS_REVERSE, CAYLEYS_WEDGE, CAYLEYS_WEDGE_DOT,
  CAYLEY_CONTRACT_WEIGHT_RIGHT, CAYLEY_EXPAND_BULK_RIGHT,
  CAYLEYS_NORM_SQUARED, CAYLEY_ATTITUDE, horizon
when IS_CONFORMAL:
  from ./algebra {.all.} import infinity
  from ./cayleys {.all.} import CAYLEY_CARRIER
```
