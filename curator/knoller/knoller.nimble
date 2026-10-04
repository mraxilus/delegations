# Package description read by Atlas and nimble; requirements live here (Article II.8).
#   Standard library only, so package installs anywhere its compiler does (II.8).

version = "0.1.0"
author = "Emmanuel M. Smith"
description = "Fixers of Nim source that read text of one file alone."
license = "Prosperity-3.0.0"
srcDir = "src"
installExt = @["nim"]

requires "nim == 2.2.12"
