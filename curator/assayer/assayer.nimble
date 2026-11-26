# Package description read by Atlas and nimble; requirements live here (Article II.8).
#   Knoller serves compiler of each pin (`compilers.nim`, `pins.nim`), so it is package here, at
#     commit of `main` that `atlas.lock` holds; `atlas.config` names repository and folder it
#     lives in, since requirement reads no folder (`PROVENANCE.md`, Package).

version = "0.1.0"
author = "Emmanuel M. Smith"
description = "Runner of each test file under each configuration of its header, in parallel."
license = "Prosperity-3.0.0"
srcDir = "src"

requires "nim == 2.4.2"
requires "knoller#11403468a97c0d3ae922182d894606e2688504e9"
