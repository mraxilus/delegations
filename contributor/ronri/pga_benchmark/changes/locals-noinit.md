# Write each step of a compound operator into a local without zero fill

At pin, the pinned compiler fills a temporary with zeros before each call that returns a
multivector. It does so where the callee is `noinit` too. A compound operator chains two or three
products, so it fills two or three temporaries, and its own result. The products write every
coefficient, so no fill is needed.

This change writes each step into a local declared `{.noinit.}`, and marks the operator
`{.noinit.}`. An assignment to such a local passes the local itself as the result, so the compiler
fills nothing. A `let` with `{.noinit.}` does not do this, because the compiler still fills a
temporary and then copies it.

The change edits the five compound operators that are not inline: the support and antisupport of
the rigid algebras, and the cocarrier, center and container of the conformal ones. An inline
operator gains nothing, because the C compiler removes those fills already. The partner `⊛` keeps
its lines, since `partner-guard` quotes them.

Proposal P08, `compound-tables`, gives each of the five operators one table, with no step and no
temporary. So this change is void once P08 lands. P08 also gains more. At `rga4d`, the support
takes 0.53 of its time with this change, and 0.15 with P08. At `cga5d`, the center takes 0.74
and 0.30. This change costs five local edits, and P08 costs five tables that each build derives.

## Edit `pga/operators.nim`

```nim
  func `∩`*(m: Multivector): Multivector =
    ## Get right support of multivector, i.e. 𝐦∩ = 𝐦 ∨ (𝐞ₙ ∧ 𝐦☆).
    const 𝐞ₙ = initElement(Basis.origin)
    m ∨ (𝐞ₙ ∧ ☆m)
```

```nim
  func `∩`*(m: Multivector): Multivector {.noinit.} =
    ## Get right support of multivector, i.e. 𝐦∩ = 𝐦 ∨ (𝐞ₙ ∧ 𝐦☆).
    ##   Each step writes local declared noinit, since compiler zero-fills temporary of call.
    const 𝐞ₙ = initElement(Basis.origin)
    var dual {.noinit.}: Multivector
    dual = ☆m
    var expansion {.noinit.}: Multivector
    expansion = 𝐞ₙ ∧ dual
    result = m ∨ expansion
```

## Edit `pga/operators.nim`

```nim
  func `∪`*(m: Multivector): Multivector =
    ## Get right antisupport of multivector, i.e. 𝐦∪ = 𝐦 ∧ (𝐞̄ₙ ∨ 𝐦★).
    const 𝐞̄ₙ = block:
      let h = Basis.horizon
      h.basis.initElement(if h.is_negated: -1 else: 1)
    m ∧ (𝐞̄ₙ ∨ ★m)
```

```nim
  func `∪`*(m: Multivector): Multivector {.noinit.} =
    ## Get right antisupport of multivector, i.e. 𝐦∪ = 𝐦 ∧ (𝐞̄ₙ ∨ 𝐦★).
    ##   Each step writes local declared noinit, since compiler zero-fills temporary of call.
    const 𝐞̄ₙ = block:
      let h = Basis.horizon
      h.basis.initElement(if h.is_negated: -1 else: 1)
    var dual {.noinit.}: Multivector
    dual = ★m
    var contraction {.noinit.}: Multivector
    contraction = 𝐞̄ₙ ∨ dual
    result = m ∧ contraction
```

## Edit `pga/operators.nim`

```nim
  func `⊞`*(m: Multivector): Multivector =
    ## Get cocarrier of multivector, i.e. 𝐦☆ ∧ 𝐞ₙ.
    const 𝐞ₙ = Basis.infinity.initElement()
    ☆m ∧ 𝐞ₙ

  func `⊙`*(m: Multivector): Multivector = ⊞m ∨ m
    ## Get center of multivector, i.e. 𝐦⊞ ∨ 𝐦.

  func `⊡`*(m: Multivector): Multivector = m ∧ ☆(⊟m)
    ## Get container of multivector, i.e. 𝐦 ∧ (𝐦⊟)☆.
```

```nim
  func `⊞`*(m: Multivector): Multivector {.noinit.} =
    ## Get cocarrier of multivector, i.e. 𝐦☆ ∧ 𝐞ₙ.
    ##   Each step writes local declared noinit, since compiler zero-fills temporary of call.
    const 𝐞ₙ = Basis.infinity.initElement()
    var dual {.noinit.}: Multivector
    dual = ☆m
    result = dual ∧ 𝐞ₙ

  func `⊙`*(m: Multivector): Multivector {.noinit.} =
    ## Get center of multivector, i.e. 𝐦⊞ ∨ 𝐦.
    ##   Each step writes local declared noinit, since compiler zero-fills temporary of call.
    var cocarrier {.noinit.}: Multivector
    cocarrier = ⊞m
    result = cocarrier ∨ m

  func `⊡`*(m: Multivector): Multivector {.noinit.} =
    ## Get container of multivector, i.e. 𝐦 ∧ (𝐦⊟)☆.
    ##   Each step writes local declared noinit, since compiler zero-fills temporary of call.
    var carrier {.noinit.}: Multivector
    carrier = ⊟m
    var dual {.noinit.}: Multivector
    dual = ☆carrier
    result = m ∧ dual
```
