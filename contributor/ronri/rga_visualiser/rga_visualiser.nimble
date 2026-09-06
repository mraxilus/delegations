# Package description read by Atlas and nimble; requirements live here (Article II.8).

version = "0.1.0"
author = "Emmanuel M. Smith"
description = "Interactive visualiser of rigid geometric algebra objects and operations."
license = "Prosperity-3.0.0"
srcDir = "src"

# PGA library is derived subject this project exists to exercise, so it is dependency
#   rather than copy (Article II.8). It lives inside replications repository rather than at
#   its root, and that repository carries no nimble file, so requirement pins commit and
#   `nim.cfg` names path Atlas restores it to.
# Compiler is pinned by commit rather than release: library's head spells its operators
#   with characters no release lexes, and commit is where Nim added them. CI builds it from
#   source and caches per commit; see PROVENANCE.md, Dependencies / Vendoring.
requires "nim == 27763495bcfe265507ca98aedc1c7064bf1e0e4d"
requires "https://gitlab.com/mraxilus/replications#295bafc"
