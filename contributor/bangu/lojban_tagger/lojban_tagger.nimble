# Package description read by Atlas and nimble; requirements live here (Article II.8).
#   Lojban is read through `lojban_parser`, sibling project of this repository: parser exists
#   to understand lojban, and this project to tag and search by it, so neither repeats other
#   (II.8, II.9). Parser is package, at commit of `main` that `atlas.lock` holds, and
#   `atlas.config` names repository and folder it lives in, since requirement reads no folder:
#   import by path breaks wherever either folder moves (`PROVENANCE.md`, Reading through
#   lojban_parser).
#   `protobuf_serialization` of Status reads and writes exchange files of `suggester`:
#   data one program writes and another reads is Protocol Buffers (CONTRIBUTOR.md, Data),
#   external concern, so package; `atlas.lock` pins it with each package it needs.

version = "0.1.0"
author = "Emmanuel M. Smith"
description = "Tag anything with gismu and lujvo, and find it again by gismu or English."
license = "Prosperity-3.0.0"
srcDir = "src"

requires "nim == 2.4.0"
requires "https://github.com/status-im/nim-protobuf-serialization"
requires "lojban_parser#0d6eaaebb95eeecc84359b6b4bf7da8c0715f26c"
