# Package description read by Atlas and nimble; requirements live here (Article II.8).
#   Morphology of lojban is what project exists to understand, so it is derived from CLL,
#   never imported (II.8).
#   `protobuf_serialization` of Status reads and writes exchange files of `suggester`:
#   data one program writes and another reads is Protocol Buffers (CONTRIBUTOR.md, Data),
#   external concern, so package; `atlas.lock` pins it with each package it needs.
#   Trap: `atlas.lock` keeps each line as JSON string, indented, quote escaped, so line
#   stays within 91 characters, quote counting twice, and copy fits width (X.1).

version = "0.1.0"
author = "Emmanuel M. Smith"
description = "Tag anything with gismu and lujvo, and find it again by gismu or English."
license = "Prosperity-3.0.0"
srcDir = "src"

requires "nim == 2.4.0"
requires "https://github.com/status-im/nim-protobuf-serialization"
