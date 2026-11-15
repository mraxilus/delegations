# Package description read by Atlas and nimble; requirements live here (Article II.8).
#   Lojban is read through `lojban_parser`, sibling project of this repository, imported
#   by relative path as `curator/audit` imports knoller: parser exists to understand
#   lojban, and this project to tag and search by it, so neither repeats other (II.8,
#   II.9). Path, not package: both stand at one commit, so no lock line pins parser.
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
