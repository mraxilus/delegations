# State and assert precondition of partner

`⊛` reads `m.grade.get`, which panics with no message on a multivector of mixed grade.
This change asserts single grade, with a message. It also puts parentheses around both
operands of `∨`, since `∨` binds looser than `*`.

P03, `partner-sign`, folds the sign of the partner into its first table. It removes these lines,
with the grade scan and this assert, so this change is void once P03 lands. P06, `float-width`,
edits the sign line too. If P06 lands first, this change quotes and keeps `Coefficient(...)` in
place of `float(...)`. If this change lands first, P06 quotes its sign line.

## Edit `pga/operators.nim`

```nim
    let sign = float(-1^(int(m.grade.get) + 1))
    sign * ⊡(☆m) ∨ ⊟m
```

```nim
    ##   Requires single-grade multivector; mixed grade has no defined partner.
    let grade_option = m.grade
    doAssert grade_option.isSome, "partner requires single-grade multivector"
    let sign = float(-1^(int(grade_option.get) + 1))
    (sign * ⊡(☆m)) ∨ ⊟m
```
