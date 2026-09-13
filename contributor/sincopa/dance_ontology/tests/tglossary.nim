discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Hold chain's names to glossary they are meant to speak.
##   `GLOSSARY.md` is agreed vocabulary, and every entry carries `_Avoid_` line
##     naming words that entry replaced.  Nothing in project read that line, so
##     build could print word glossary rejects and stay green -- which is what
##     happened: chain's two middle shapes were written `X` and `box`, both
##     listed under `_Avoid_`, while glossary called them `Cross` and
##     `Diamond`.
##   Law is glossary's, not this file's: document is parsed rather than
##     restated, so ruling made there reaches build without second edit here
##     (Article II.1).
##   Every hold walks same chain (rule 31), so claim is made over both holds
##     workbench draws, never over one example (Article IX.2).

import std/[options, os, strutils, tables, unittest]

import ../design/parts
import ../design/rules


const
  GLOSSARY = currentSourcePath().parentDir.parentDir / "GLOSSARY.md"
    ## Vocabulary this project agreed, beside its code.
  SHAPE_AT = {0: "Open", 5: "Cross", 10: "Diamond", 15: "Swan"}.toTable
    ## Glossary's word for each step of chain, by wind in tenths of turn.
    ##   Tenths because wind is float and key must compare exactly.
  CHAIN_TERMS = ["Open", "Cross", "Diamond", "Swan"]
    ## Entries naming step of chain, which are only ones position may speak.
    ##   Rest of glossary is held to elsewhere; word another entry rejects is
    ##     no business of position's name.
  HOLDS = [HAND_TO_HAND, [some Arm.L, some Arm.R]]
    ## Both holds workbench walks: app's own frame, and its dual (rule 31).


func avoided(source: string): Table[string, seq[string]] =
  ## Collect words each chain entry replaced, by term entry names.
  ##   Entry opens `**Term**:` and its rejected words sit on `_Avoid_:` line
  ##     inside same entry, comma separated.
  var term = ""
  for line in source.splitLines:
    let bare = line.strip
    if bare.startsWith("**") and bare.endsWith("**:"):
      term = bare[2 ..< bare.len - 3]
    elif bare.startsWith("_Avoid_:") and term in CHAIN_TERMS:
      for word in bare["_Avoid_:".len .. ^1].split(','):
        result.mgetOrPut(term, @[]).add word.strip.toLowerAscii


func says(text, phrase: string): bool =
  ## Decide whether text speaks phrase as whole words, not inside longer one.
  var from_here = 0
  while true:
    let at = text.find(phrase, from_here)
    if at < 0: return false
    if (at == 0 or text[at - 1] notin Letters) and
        (at + phrase.len >= text.len or text[at + phrase.len] notin Letters):
      return true
    from_here = at + 1


suite "chain speaks glossary":
  let
    source = readFile(GLOSSARY)
    rejected = source.avoided

  test "glossary still names every step of chain":
    # Laws below are vacuous where entries they read are missing, so entries
    # are demanded first.
    for term in CHAIN_TERMS:
      check term in rejected
      check rejected[term].len > 0

  test "no position is named by word glossary rejects":
    for holds in HOLDS:
      for position in chainFor(holds):
        let name = position.name.toLowerAscii
        for _, words in rejected:
          for word in words:
            check not name.says(word)

  test "every position carries glossary's own word":
    for holds in HOLDS:
      for position in chainFor(holds):
        let tenths = int(abs(position.wind) * 10)
        if tenths in SHAPE_AT:
          check position.name.toLowerAscii.says(SHAPE_AT[tenths].toLowerAscii)
