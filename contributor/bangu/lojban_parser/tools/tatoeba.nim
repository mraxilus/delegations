## Choose fixed sample of lojban sentences of Tatoeba that reaches most rules of CLL, and render it
##   as typed Nim module holding verdict parser gives each; `build.nim` runs it.
##   Reads `jbo_sentences_detailed.tsv`, decompressed from export `URL_TATOEBA` serves and pinned
##   by SHA-256 as in `lists.nim`; renders `tests/sample_tatoeba/sentences.nim`, and `NOTICE.md`
##   beside it.
##
##   Ruling `D4 c` of #819: sample is fixed, never seeded, since export only grows; it is diverse,
##     so its sentences reach as many rules of CLL as they can.
##   Feature is what reading of sentence shows: shape of each named rule of tree, as rule with
##     labels of its children, run of one label collapsed; each terminal; construct of 19.16
##     holding several words; kind of word, form of rafsi and hyphen of lujvo; pause, stress and
##     comma of stream; word in no unit, as erasure leaves; quoted text; and refusal with its rule.
##   Sample is greedy cover: sentence adding most features not yet reached comes first, tie going
##     to shorter text, then to lower id; cover stops where no sentence adds feature.
##     Cost: greedy cover is no least cover, which is NP-hard to find; greedy stays within
##       logarithmic factor of it.
##   Verdict is what parser gives at render: empty where sentence reads, else refusal and rule,
##     as `Grammar sumti-6 97`. Suite fails at each verdict that changes.
##   Verb prints count of each verdict over whole export, which record gives.
##   Cost: verb reads every sentence through parser once, so it runs for about one minute.

{.experimental: "strictFuncs".}

import std/[algorithm, options, os, osproc, sequtils, sets, strutils, tables]

import ../src/lojban_parser/[grammar, lujvo, prose, stream]
import ./literals


type
  Sentence* = object  ## Define one sentence of export: number, text, owner, and its reading.
    id*: int  ## Number Tatoeba gives sentence.
    text*: string  ## Sentence as export writes it.
    owner*: string  ## Name of account owning sentence; empty where none owns it.
    verdict*: string  ## Refusal and rule parser gives; empty where sentence reads.
    features*: HashSet[string]  ## Features reading shows.

  Sample* = object  ## Define what export gives: sentences chosen, and verdicts over all of it.
    sentences*: seq[Sentence]  ## Sentences of sample, in order of number.
    count_features*: int  ## Features sentences of sample reach together.
    counts*: CountTable[string]  ## Count of each verdict over whole export; empty where read.
    count_sentences*: int  ## Sentences of whole export.
    digest*: string  ## SHA-256 of export as read.


const
  DIGEST_TATOEBA* = "bf91e751a78a5137ffa741b0971df3c4e7a5444e18b47545be51d0593629bb40"
    ## SHA-256 of `jbo_sentences_detailed.tsv`, decompressed from export of 2026-10-31.
  URL_TATOEBA* =
    "https://downloads.tatoeba.org/exports/per_language/jbo/jbo_sentences_detailed.tsv.bz2"
    ## Address export is saved from.
  URL_LICENCE* = "https://creativecommons.org/licenses/by/2.0/fr/"  ## Licence of sentences.
  URL_SENTENCE* = "https://tatoeba.org/en/sentences/show/"  ## Page of sentence, before number.
  PATH_SENTENCES* = "tests/sample_tatoeba/sentences.nim"  ## Module sample renders to.
  PATH_NOTICE_TATOEBA* = "tests/sample_tatoeba/NOTICE.md"  ## Notice of licence, beside module.
  OWNER_NONE = "\\N"  ## Mark export writes for sentence no account owns.
  WORDS_CONSTRUCT = 3  ## Words of construct beyond which feature counts no more.
  INDENT_TEXT = 12  ## Column text of long sentence opens at, after `text: ` of its field.
  INDENT_CONTINUED = 10  ## Indent of each later line of text: four past line of its field.



#[ Features ]#

func addShapes(features: var HashSet[string], node: Node, units: openArray[Unit]) =
  ## Add shape of each named rule under node: rule, then labels of its children, run collapsed.
  if node.is_terminal: return
  var labels: seq[string]
  for child in node.children:
    let label = (if child.is_terminal: $units[child.at].terminal else: child.rule)
    if labels.len == 0 or labels[^1] != label: labels.add label
  features.incl "shape " & node.rule & "(" & labels.join(" ") & ")"
  for child in node.children: features.addShapes(child, units)


func reading*(text: string): tuple[verdict: string, features: HashSet[string]] =
  ## Read sentence through parser, and give its verdict and features reading shows.
  let reading = text.readText
  if not reading.is_read:
    result.verdict = $reading.refusal & (if reading.rule.len > 0: " " & reading.rule else: "")
    result.features.incl "refusal " & result.verdict
    return
  result.features.addShapes(reading.tree, reading.units)
  var count_held = 0
  for unit in reading.units:
    result.features.incl "terminal " & $unit.terminal
    count_held += unit.words.len
    if unit.words.len > 1:
      result.features.incl "construct " & $unit.terminal & " " &
          $min(unit.words.len, WORDS_CONSTRUCT)
  if count_held < reading.occurrences.len: result.features.incl "word in no unit"
  for occurrence in reading.occurrences:
    if occurrence.pause != Pause.Absent: result.features.incl "pause " & $occurrence.pause
    if occurrence.stress.isSome: result.features.incl "stress"
    if occurrence.breaks.len > 0: result.features.incl "comma"
    if not occurrence.reading.is_word:
      result.features.incl "quoted text"
      continue
    result.features.incl "kind " & $occurrence.reading.kind
    for piece in occurrence.reading.pieces:
      result.features.incl "rafsi " & $piece.form
      if piece.hyphen != Hyphen.None: result.features.incl "hyphen " & $piece.hyphen



#[ Reading ]#

proc readSentences*(path: string): tuple[sentences: seq[Sentence], digest: string] =
  ## Read every sentence of export at `path`, each through parser, with digest of file.
  if not fileExists(path):
    quit "Export is missing; save `" & URL_TATOEBA & "`; got `" & path & "`.", 1
  let (output, code) = execCmdEx("sha256sum " & quoteShell(path))
  if code != 0: quit "Digest could not be read; got `" & output.strip & "`.", 1
  result.digest = output.splitWhitespace[0]
  for line in readFile(path).splitLines:
    if line.len == 0: continue
    let fields = line.split('\t')
    doAssert fields.len == 6, "Line should hold six fields; got `" & line & "`."
    let (verdict, features) = fields[2].reading
    result.sentences.add Sentence(
      id: parseInt(fields[0]),
      text: fields[2],
      owner: (if fields[3] == OWNER_NONE: "" else: fields[3]),
      verdict: verdict,
      features: features,
    )


func isBefore(a, b: Sentence): bool =
  ## Decide whether `a` goes before `b` where both add as many features: shorter text, lower id.
  (a.text.len, a.id) < (b.text.len, b.id)


func toSample*(sentences: openArray[Sentence], digest: string): Sample =
  ## Choose sample by greedy cover of features, and count each verdict over every sentence.
  var
    reached: HashSet[string]
    is_chosen = newSeq[bool](sentences.len)
  while true:
    var
      best = -1
      gain_best = 0
    for i, sentence in sentences:
      if is_chosen[i]: continue
      let gain = sentence.features.countIt(it notin reached)
      if gain == 0: continue
      if gain > gain_best or (gain == gain_best and sentence.isBefore(sentences[best])):
        (best, gain_best) = (i, gain)
    if best < 0: break
    is_chosen[best] = true
    reached.incl sentences[best].features
  for i, sentence in sentences:
    if is_chosen[i]: result.sentences.add sentence
    result.counts.inc sentence.verdict
  result.sentences.sort(proc (a, b: Sentence): int = cmp(a.id, b.id))
  result.count_features = reached.len
  result.count_sentences = sentences.len
  result.digest = digest



#[ Rendering ]#

func linesSentence(sentence: Sentence): seq[string] =
  ## Render one sentence as constructor: on one line where it fits, else one field to line.
  let
    id = "id: " & $sentence.id
    owner = "owner: " & sentence.owner.toLiteral
    verdict = "verdict: " & sentence.verdict.toLiteral
    line = "    SentenceTatoeba(" & id & ", text: " & sentence.text.toLiteral & ", " & owner &
        ", " & verdict & "),"
  if line.isFit: return @[line]
  result.add "    SentenceTatoeba("
  result.add "      " & id & ","
  let text = sentence.text.linesLiteral(INDENT_TEXT, ",")  # pieces fit first line, widest
  result.add "      text: " & text[0].strip(trailing = false)
  for line in text[1 .. ^1]: result.add repeat(' ', INDENT_CONTINUED) & line.strip(trailing = false)
  result.add "      " & owner & ","
  result.add "      " & verdict & ","
  result.add "    ),"


func toModuleSentences*(sample: Sample): string =
  ## Render sample as committed module text.
  var lines = @[
    "## Hold fixed sample of lojban sentences of Tatoeba, with verdict parser gave each, for " &
    "suite.",
    "##   Written by `nim r tools/build.nim tatoeba <export>` from `jbo_sentences_detailed.tsv` of",
    "##   Tatoeba export of 2026-10-31, SHA-256 `" & sample.digest[0..31] & "`",
    "##   `" & sample.digest[32 .. ^1] & "`; never edit by hand, run verb again.",
    "##   Sentences of Tatoeba, under licence CC BY 2.0 FR; folder holding module is distributed",
    "##     under that licence, as `NOTICE.md` beside module gives, never under licence of",
    "##     repository.",
    "##   Sample is greedy cover of features of reading, as `tools/tatoeba.nim` defines them.",
    "",
    "{.experimental: \"strictFuncs\".}",
    "",
    "",
    "type SentenceTatoeba* = object  ## Define one sentence of sample: number, text, owner, " &
    "verdict.",
    "  id* {.requiresInit.}: int  ## Number Tatoeba gives sentence, as `599308`.",
    "  text* {.requiresInit.}: string  ## Sentence as export writes it.",
    "  owner* {.requiresInit.}: string  ## Name of account owning sentence; empty where none " &
    "owns it.",
    "  verdict* {.requiresInit.}: string  ## Refusal and rule parser gave; empty where it reads.",
    "",
    "",
    "const",
    "  COUNT_FEATURES_TATOEBA* = " & $sample.count_features &
    "  ## Features of reading sample reaches at render.",
    "  SENTENCES_TATOEBA* = [",
  ]
  for sentence in sample.sentences: lines.add sentence.linesSentence
  lines.add "  ]"
  lines.add "    ## Sentences of sample, in order of number."
  lines.join("\n") & "\n"


func toKeyDictionary(text: string): (string, string) =
  ## Key of dictionary order: case and `_` ignored, tie to code point (Article X.10).
  (text.toLowerAscii.replace("_", ""), text)


func toNotice*(sample: Sample): string =
  ## Render notice of licence, with changes made and each owner credited.
  var lines = @[
    "# Notice",
    "",
    "The file `sentences.nim` in this folder holds lojban sentences from Tatoeba, at",
    "<https://tatoeba.org>. They come from the export of 2026-10-31, at",
    "<" & URL_TATOEBA & ">.",
    "",
    "Tatoeba releases these sentences under the Creative Commons Attribution 2.0 France licence",
    "(CC BY 2.0 FR), at <" & URL_LICENCE & ">.",
    "This folder is not under the licence of the repository. It is distributed under that",
    "licence.",
    "",
    "These are the changes:",
    "",
    "- Only a sample of the sentences is kept.",
    "- Of each sentence, only its number, its text and the name of its owner are kept.",
    "- The text of each sentence does not change.",
    "",
    "The command `nim r tools/build.nim tatoeba <export>` writes this folder from the export.",
    "The page of each sentence is `" & URL_SENTENCE & "<number>`.",
    "A sentence with no owner is credited to Tatoeba. These are the owners of the sentences of",
    "the sample:",
    "",
  ]
  var owners: seq[string]
  for sentence in sample.sentences:
    if sentence.owner.len > 0 and sentence.owner notin owners: owners.add sentence.owner
  owners.sort(proc (a, b: string): int = cmp(a.toKeyDictionary, b.toKeyDictionary))
  for owner in owners: lines.add "- `" & owner & "`"
  lines.join("\n") & "\n"
