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
requires "nim == 2.2.10"
requires "https://gitlab.com/mraxilus/replications#f8861e0b"
