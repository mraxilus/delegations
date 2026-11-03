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
# Compiler is pinned by release: 2.4.0 is first release to lex seven operator
#   characters that library's head spells its operators with (Nim pull request 26074);
#   see PROVENANCE.md, Dependencies and vendoring.
requires "nim == 2.4.0"
requires "https://gitlab.com/mraxilus/replications#295bafc"
