# Fill the center norm

At pin, each of the four norms of the book measures the size of its own part, and the radius norm
roots the antidot. The center norm, (4.43), is still a stub. This change fills it on 𝟏, as a
weighted distance from the origin to the center. Chapter 4 gains two suites, from Tables 4.12
and 4.13. How unitization treats a flat object is P11, which unitizes any element by one rule.

## Edit `pga/operators.nim`

```nim
  func `|⊘`*(m: Multivector): Multivector {.inline.} =
    ## Get radius norm of multivector.
    ##   Taken from antidot to avoid square root of negative.
    result[Basis.scalarAnti] = (`|⊘²`m)[Basis.scalarAnti].sqrt
```

```nim
  func `|⊘`*(m: Multivector): Multivector {.inline.} =
    ## Get radius norm of multivector.
    ##   Taken from antidot to avoid square root of negative.
    result[Basis.scalarAnti] = (`|⊘²`m)[Basis.scalarAnti].sqrt

  func `|⊙`*(m: Multivector): Multivector {.inline.} =
    ## Get center norm of multivector, i.e. ‖𝐦‖⊙ = √(‖𝐦‖∙² + ‖𝐦‖□²) (4.43).
    ##   Weighted distance from origin to center; divide by round weight norm for distance.
    result[Basis.scalar] = sqrt((`|∙²`m)[Basis.scalar] + (`|□²`m)[Basis.scalarAnti])
```

## Edit `pga.nim`

```nim
  func normCenter*(m: Multivector): Multivector {.inline, error: "TODO:  |⊙m".}
    ## Get center norm of multivector.
```

```nim
  func normCenter*(m: Multivector): Multivector {.inline.} = |⊙m
    ## Get center norm of multivector as weighted distance from origin to its center.
```

## Edit `tests/suites.nim`

```nim
  test "TODO: Add chapter 4 tests":
    skip()
```

```nim
  test "Table 4.12: four norms measure four parts":
    when IS_CONFORMAL and DIMENSIONS == 5:
      # Round bulk, round weight, flat bulk and flat weight of each object, by Table 4.11.
      let objects: seq[array[4, seq[Basis]]] = @[
        [@[], @[], @[E15, E25, E35], @[E45]],  # flat point
        [@[], @[], @[E235, E315, E125], @[E415, E425, E435]],  # line
        [@[], @[], @[E3215], @[E4235, E4315, E4125]],  # plane
        [@[E1, E2, E3], @[E4], @[E5], @[]],  # round point
        [@[E23, E31, E12], @[E41, E42, E43], @[E15, E25, E35], @[E45]],  # dipole
        [@[E321], @[E423, E431, E412], @[E235, E315, E125], @[E415, E425, E435]],  # circle
        [@[], @[E1234], @[E3215], @[E4235, E4315, E4125]],  # sphere
      ]
      for parts in objects:
        for _ in 1..SAMPLES div 8:
          var
            𝐮: Multivector
            sizes: array[4, float]
          for i, part in parts:
            for b in part:
              𝐮[b] = gauss()
              sizes[i] += 𝐮[b] ^ 2
          check |∙𝐮 =~ initElement(Basis.scalar, sizes[0].sqrt)  # 4.12, round bulk
          check |∘𝐮 =~ initElement(Basis.scalarAnti, sizes[1].sqrt)  # 4.12, round weight
          check |■𝐮 =~ initElement(Basis.scalar, sizes[2].sqrt)  # 4.12, flat bulk
          check |□𝐮 =~ initElement(Basis.scalarAnti, sizes[3].sqrt)  # 4.12, flat weight

    else: skip()

  test "Table 4.13: center and radius norms of round objects":
    when IS_CONFORMAL and DIMENSIONS == 5:
      for _ in 1..SAMPLES:
        var 𝐚, 𝐝, 𝐜, 𝐬: Multivector
        for b in [E1, E2, E3, E4, E5]: 𝐚[b] = gauss()
        for b in [E23, E31, E12, E41, E42, E43, E15, E25, E35, E45]: 𝐝[b] = gauss()
        for b in [E321, E423, E431, E412, E235, E315, E125, E415, E425, E435]: 𝐜[b] = gauss()
        for b in [E1234, E3215, E4235, E4315, E4125]: 𝐬[b] = gauss()
        let
          centers = [
            𝐚[E1]^2 + 𝐚[E2]^2 + 𝐚[E3]^2,
            𝐝[E23]^2 + 𝐝[E31]^2 + 𝐝[E12]^2 + 𝐝[E45]^2,
            𝐜[E321]^2 + 𝐜[E415]^2 + 𝐜[E425]^2 + 𝐜[E435]^2,
            𝐬[E4235]^2 + 𝐬[E4315]^2 + 𝐬[E4125]^2,
          ]
          radii = [
            2*𝐚[E4]*𝐚[E5] - 𝐚[E1]^2 - 𝐚[E2]^2 - 𝐚[E3]^2,
            𝐝[E45]^2 - 𝐝[E23]^2 - 𝐝[E31]^2 - 𝐝[E12]^2 -
              2*(𝐝[E15]*𝐝[E41] + 𝐝[E25]*𝐝[E42] + 𝐝[E35]*𝐝[E43]),
            𝐜[E415]^2 + 𝐜[E425]^2 + 𝐜[E435]^2 - 𝐜[E321]^2 +
              2*(𝐜[E423]*𝐜[E235] + 𝐜[E431]*𝐜[E315] + 𝐜[E412]*𝐜[E125]),
            𝐬[E4235]^2 + 𝐬[E4315]^2 + 𝐬[E4125]^2 - 2*𝐬[E3215]*𝐬[E1234],
          ]
        for i, 𝐮 in [𝐚, 𝐝, 𝐜, 𝐬]:
          check |⊙𝐮 =~ initElement(Basis.scalar, centers[i].sqrt)  # 4.43, Table 4.13
          check 𝐮 ∘ 𝐮 =~ initElement(Basis.scalarAnti, radii[i])  # 4.45, Table 4.13
          if radii[i] >= 0:
            check |⊘𝐮 =~ initElement(Basis.scalarAnti, radii[i].sqrt)  # 4.45, real object

    else: skip()
```
