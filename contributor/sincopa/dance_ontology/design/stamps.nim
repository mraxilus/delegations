## Stamp each recording with what gave it: physics of simulation, questions asked of it, and verb
## that asked them.
##
##   `design/modelled.json` and `design/rig.json` are recorded by verbs of their own, which take
##     minutes each, and pages read what was last recorded.  So recording carries stamp, and
##     verb whose stamp is unchanged records nothing again.  Law refuses recording whose stamp
##     is not what tree would give (`tests/suites/test_asks.nim`).
##   Stamp is digest of three things.  Physics is `readings.physics`, which leaves out files
##     that only say words.  Questions are each question as text, in order asked, so card added
##     or moved is question changed.  Verb is its own source, so way it records is in stamp too.

{.experimental: "strictFuncs".}

import std/strutils

import ../simulation/readings


const
  HASH_OFFSET = 0xcbf29ce484222325'u64
  HASH_PRIME = 0x100000001b3'u64


func digest(parts: openArray[string]): string =
  ## FNV-1a over every part, with NUL after each so no two run together.
  var hash = HASH_OFFSET
  for part in parts:
    for character in part:
      hash = (hash xor uint64(ord(character))) * HASH_PRIME
    hash = hash * HASH_PRIME
  hash.toHex(16).toLowerAscii

proc stampOf*(verb: string; questions: openArray[string]): string =
  ## Stamp of recording `verb` makes of `questions`: physics, verb's source, then each
  ## question.
  var parts = @[physics(), readFile(verb)]
  for question in questions: parts.add question
  digest(parts)
