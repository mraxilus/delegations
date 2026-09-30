# Delete commented-out sandwich macro and old operator bodies

`operators.nim` holds 116 commented lines: the sandwich macro, its four call sites, and
the old bodies of `∙` and `∘`. The transwedge generates `∙` and `∘`, and the composed forms
replace the sandwich. A reader meets these lines first, and no build reads them.

## Edit `pga/operators.nim`

```nim
# macro defineOperatorSandwich(
#   symbols, docs: static[string];
#   cayleys: static[Chiral[Cayley2D]];
#   is_right_to_left: static[bool] = false;
# ): untyped =
#   ## Construct multivector product variant using provided Cayley table.

#   # TODO: Modify to deal with Cayley2D's seq instead of Option.

#   # Determine calculations needed for each basis blade's coefficient assignment.
#   var expressions: array[Basis, seq[NimNode]]
#   for bm in Basis:
#     for bn in Basis:
#       let product1 =
#         if is_right_to_left: cayleys.right[bm][bn]
#           else: cayleys.left[bn][bm]
#       if product1.isNone: continue
#       let intermediate = product1.get

#       let product2 =
#         if is_right_to_left: cayleys.left[bn][intermediate.basis]
#         else: cayleys.right[intermediate.basis][bn]
#       if product2.isNone: continue

#       let
#         destination = product2.get
#         is_negated = intermediate.is_negated xor destination.is_negated
#         term = infix(
#           nnkBracketExpr.newTree(ident"m", ident($bm)),
#           "*",
#           infix(
#             nnkBracketExpr.newTree(ident"n", ident($bn)),
#             "*",
#             nnkBracketExpr.newTree(ident"n", ident($bn)),
#           )
#         )
#       expressions[destination.basis].add(if is_negated: prefix(term, "-") else: term)

#   # TODO: Elimintate term duplication (maybe store intermediaries).
#   #   This should be at least as efficient as non-condensed form, ideally faster.
#   #   This is likely where GA falls behind standard linear algebra.
#   #     Especially relevant for when (flec/mo)tors are implemented.

#   # Construct function body as collated assignments for each basis blade.
#   var assignments = newNimNode(nnkStmtList)
#   for b in Basis:
#     let terms = expressions[b]
#     if len(terms) == 0: continue
#     var expression = terms[0]
#     for term in terms[1 .. ^1]:
#       expression = infix(expression, "+", term)
#     assignments.add(
#       newAssignment(nnkBracketExpr.newTree(ident"result", ident($b)), expression)
#     )

#   # Construct function definition from generated assignments.
#   emitFunc(
#     name = symbols,
#     docs = docs,
#     params = nnkFormalParams.newTree(
#         ident"Multivector",
#         nnkIdentDefs.newTree(ident"m", ident"n", ident"Multivector", newEmptyNode()),
#     ),
#     pragma = newEmptyNode(),
#     body = assignments,
#     is_quoted = true,
#     is_public = true,
#   )
```

```nim
# `defineOperatorSandwich` removed: it predates Cayley2D holding a seq per cell,
#   and the four sandwich forms are aliases over live operators in pga.nim.
```

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
# Sandwich definitions removed with the macro above; the four composed forms are
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
