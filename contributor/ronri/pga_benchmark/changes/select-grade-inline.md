# Make grade selection inline, as the other light operators are

`{}` selects the part of one grade or antigrade of a multivector. It spends no multiply, add or
subtract. At pin it is the one light operator that a measurand times and that is not `inline`. So
each call crosses the boundary of the module, which is gap cause D06.

This change marks `{}` as `inline`, as `pga/multivectors.nim` marks `+`, `-` and each conversion.
The body keeps its form, and the result is still filled with zeros before the loop writes the grade.
Its C then defines `{}` as `static N_INLINE`, so no operator that a measurand times stays an
instance of D06.

Its evaluation of 2026-11-15 times `select_grade` at ×0.85 to ×0.93 of pin, and `select_grade_anti`
at ×0.67 to ×0.87, over the four algebras. The other 443 measurands read ×0.95 to ×1.05, at a median
of ×1.00. At pin the runtime baselines time `select_grade` at ×1.3 to ×2.9 of its dense form. So
most of that gap probably stays, and its cause is not isolated.

## Edit `pga/multivectors.nim`

```nim
func `{}`*[G: Grade | GradeAnti](m: Multivector, grade: G): Multivector =
```

```nim
func `{}`*[G: Grade | GradeAnti](m: Multivector, grade: G): Multivector {.inline.} =
```
