# Package description read by Atlas and nimble; requirements live here (Article II.8).

version = "0.1.0"
author = "Emmanuel M. Smith"
description = "Benchmark and gap list of pga against Lengyel's hand-rolled reference."
license = "Prosperity-3.0.0"
srcDir = "src"

# PGA library is subject this project measures, so it is dependency rather than copy
#   (Article II.8). It lives inside replications repository rather than at its root,
#   and that repository carries no nimble file, so requirement pins commit and
#   `nim.cfg` names path Atlas restores it to. Pin follows library's head, as Architect
#   instructed; every pull request says which commit it measured and whether that is
#   head.
# Compiler is pinned by commit rather than release: library's head spells its operators
#   with characters no release lexes. Same commit `rga_visualiser` pins, so one cached
#   build serves both projects; see PROVENANCE.md, Dependencies.
requires "nim == 27763495bcfe265507ca98aedc1c7064bf1e0e4d"
requires "https://gitlab.com/mraxilus/replications#9f9019b"
