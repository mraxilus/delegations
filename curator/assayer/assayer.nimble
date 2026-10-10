# Package description read by Atlas and nimble; requirements live here (Article II.8).
#   Standard library and sibling `curator/knoller`, reached by relative path, so pin is knoller's.

version = "0.1.0"
author = "Emmanuel M. Smith"
description = "Runner of each test file under each configuration of its header, in parallel."
license = "Prosperity-3.0.0"
srcDir = "src"

requires "nim == 2.2.12"
