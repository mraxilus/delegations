# State and assert precondition of partner

`⊛` reads `m.grade.get`, which panics with no message on a multivector of mixed grade.
This change asserts single grade, with a message. It also puts parentheses around both
operands of `∨`, since `∨` binds looser than `*`.

When the sign of the partner folds into its table, the grade scan goes, and this assert can go
with it.

## Edit `pga/operators.nim`

```nim
    let sign = float(-1 ^ (int(m.grade.get) + 1))
    sign * ⊡(☆m) ∨ ⊟m
```

```nim
    ##   Requires single-grade multivector; mixed grade has no defined partner.
    let grade_option = m.grade
    doAssert grade_option.isSome, "partner requires single-grade multivector"
    let sign = float(-1 ^ (int(grade_option.get) + 1))
    (sign * ⊡(☆m)) ∨ (⊟m)
```
