## Name magnitudes typed references return, so scalar and antiscalar results never mix.
##   Shared by every algebra's reference; one definition rather than one per module
##   (Article II.9), since bridge embeds each into its own slot of library's multivector.

{.experimental: "strictFuncs".}


type Antiscalar* = distinct float
  ## Define magnitude landing in 𝟙, i.e. antiscalar; scalar 𝟏 stays plain `float`.


func `==`*(a, b: Antiscalar): bool {.borrow.}
  ## Compare antiscalars exactly; suites compare through tolerance on images instead.
