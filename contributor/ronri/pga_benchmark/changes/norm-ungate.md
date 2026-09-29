# Ungate norm suites under conformal metric

At pin, each norm law skips under the conformal metric. This change removes each gate, so
the suites show what fails there.

Five suites fail: 2.87-89, 2.90-94, 2.97-98, 2.99 and 2.103. 2.88 and 2.89 compare against
plain `sqrt`, which is NaN where the weight dot is negative. With the signed root of
`signed-sqrt`, the same five fail, so the norms do not explain all of them.

## Edit `tests/suites.nim`

```nim
  test "Equation 2.87-89":
    when IS_RIGID:
```

```nim
  test "Equation 2.87-89":
    block:  # gate removed
```

## Edit `tests/suites.nim`

```nim
        check ^𝐦 =~ 𝐦 div sqrt(𝐦 ∘ 𝐦)  # 2.89b

    when IS_CONFORMAL: skip()

```

```nim
        check ^𝐦 =~ 𝐦 div sqrt(𝐦 ∘ 𝐦)  # 2.89b


```

## Edit `tests/suites.nim`

```nim
  test "Equation 2.90-94":
    when IS_RIGID:
```

```nim
  test "Equation 2.90-94":
    block:  # gate removed
```

## Edit `tests/suites.nim`

```nim
    when IS_CONFORMAL: skip()


  test "Equation 2.97-98":
```

```nim


  test "Equation 2.97-98":
```

## Edit `tests/suites.nim`

```nim
  test "Equation 2.97-98":
    when IS_RIGID:
```

```nim
  test "Equation 2.97-98":
    block:  # gate removed
```

## Edit `tests/suites.nim`

```nim
    when IS_CONFORMAL: skip()


  test "Equation 2.99":
```

```nim


  test "Equation 2.99":
```

## Edit `tests/suites.nim`

```nim
  test "Equation 2.99":
    when IS_RIGID:
```

```nim
  test "Equation 2.99":
    block:  # gate removed
```

## Edit `tests/suites.nim`

```nim
        check abs(^distance_a) =~ ^distance_b

    when IS_CONFORMAL: skip()

```

```nim
        check abs(^distance_a) =~ ^distance_b


```

## Edit `tests/suites.nim`

```nim
  test "Equation 2.103":
    when IS_RIGID:
```

```nim
  test "Equation 2.103":
    block:  # gate removed
```

## Edit `tests/suites.nim`

```nim
    when IS_CONFORMAL: skip()

```

```nim

```
