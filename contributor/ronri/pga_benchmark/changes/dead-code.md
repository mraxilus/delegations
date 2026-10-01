# Delete commented-out sandwich calls and old operator bodies

`operators.nim` holds 49 commented lines: the four calls of the sandwich macro, and the old
bodies of `∙` and `∘`. The macro itself is gone, the transwedge generates `∙` and `∘`, and the
composed forms replace the sandwich. A reader meets these lines first, and no build reads them.

## Edit `pga/operators.nim`

```nim
# defineOperatorSandwich(
#   symbols = "∨∧★∘",
#   docs = "Multiply multivectors through sandwich product 𝐧 ∨ (𝐦 ∧ 𝐧☆).",
#   cayleys = Chiral[Cayley2D](
#     left: CAYLEYs_WEDGE.anti,
#     right: CAYLEY_EXPAND_WEIGHT_RIGHT,
#   ),
#   is_right_to_left = true,
# )
# defineOperatorSandwich(
#   symbols = "∧∨★∘",
#   docs = "Multiply multivectors through sandwich product 𝐧 ∧ (𝐦 ∨ 𝐧☆).",
#   cayleys = Chiral[Cayley2D](
#     left: CAYLEYS_WEDGE.base,
#     right: CAYLEY_CONTRACT_WEIGHT_RIGHT,
#   ),
#   is_right_to_left = true,
# )
# defineOperatorSandwich(
#   symbols = "∧∨★∙",
#   docs = "Multiply multivectors through sandwich product 𝐧 ∧ (𝐦 ∨ 𝐧★).",
#   cayleys = Chiral[Cayley2D](
#     left: CAYLEYS_WEDGE.base,
#     right: CAYLEY_CONTRACT_BULK_RIGHT,
#   ),
#   is_right_to_left = true,
# )
# defineOperatorSandwich(
#   symbols = "∨∧★∙",
#   docs = "Multiply multivectors through sandwich product 𝐧 ∨ (𝐦 ∧ 𝐧★).",
#   cayleys = Chiral[Cayley2D](
#     left: CAYLEYS_WEDGE.anti,
#     right: CAYLEY_EXPAND_BULK_RIGHT,
#   ),
#   is_right_to_left = true,
# )
```

```nim
# Sandwich definitions removed, since their macro is gone; the four composed forms are
#   aliases in pga.nim (projectCentral, projectCentralAnti, projectOrthogonal,
#   projectOrthogonalAnti).
```

## Edit `pga/operators.nim`

```nim
# func `∙`*(m, n: Multivector): Multivector =
#   ## Multiply multivectors through inner product between bulks, i.e. 𝐦∙𝐧 = (𝐦ᵀ𝐆𝐧)𝟏.
#   # TODO: Generate from transwedge specialization with `defineOperator`.
#   let n_bulk = ∙ n
#   for b in Basis:
#     result[Basis.scalar] += m[b]*n_bulk[b]

# func `∘`*(m, n: Multivector): Multivector =
#   ## Multiply multivectors through inner product between weights, i.e. 𝐦∘𝐧 = (𝐦ᵀ𝔾𝐧)𝟙.
#   # TODO: Generate from transwedge specialization with `defineOperator`.
#   let n_weight = ∘ n
#   for b in Basis:
#     result[Basis.scalarAnti] += m[b]*n_weight[b]
```

```nim
# Old hand-written `∙` and `∘` removed: both are generated from the transwedge
#   tables above, which is what their TODO asked for.
```
