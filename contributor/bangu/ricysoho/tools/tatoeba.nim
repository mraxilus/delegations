## cuxna lo stomupli be fi lo jboju'a pe `Tatoeba` be'o poi jarco so'e javni pe `CLL`
##   .i ciska le mupli ta'i pa samtci datnyvei pe `Nim` zi'e poi ponse lo klesi gi'e vasru lo seljdi
##       be le genturfa'i bei ro le jufra
##   .i `build.nim` pilno le vi datnyvei
##
## ni'o tcidu `jbo_sentences_detailed.tsv`
##   .i le datnyvei cu selcpa fi le vreji poi `URL_TATOEBA` benji ke'a ku'o ta'i lo nu kalri le
##       vreji kei gi'e selstosni sepi'o `SHA-256` ta'i lo nu `lists.nim` stosni lo liste
##   .i ciska `tests/sample_tatoeba/sentences.nim` .e `NOTICE.md` noi lamji `sentences.nim`
##
## ni'o `Architect` jdice `D4 c` bu'u `#819`
##   .i le mupli cu stodi gi'e no roi seljdi lo tsiju
##   .i ki'u bo le vreji cu zenba po'o
##   .i le mupli cu vrici
##   .i se ki'u bo le jufra pe le mupli cu jarco ro javni be fi `CLL` be'o poi le jufra cu ka'e
##       jarco ke'a
##
## ni'o lo tcila cu selja'o lo se tcidu pe pa jufra
##   .i lo tarmi be ro javni poi selcme gi'e zvati le tricu cu tcila
##   .i lo tarmi cu du le javni jo'u lo tcita be lo panzi be le javni
##   .i va'o lo nu pa tcita cu rapli kei le tcita cu zvati le tarmi pa roi
##   .i ro genvla .e ro gensu'a poi selski `CLL 19.16` gi'e vasru su'o re valsi cu tcila
##
## ni'o ro klesi be lo valsi be'o .e ro tarmi be lo rafsi be'o .e ro lerjo'e pe lo lujvo cu tcila
##   .i lo sinxa pe lo porsi be lo valsi cu tcila gi'e du lo denpa jo'u lo nu basna kei jo'u lo
##       lerfu po'u slaka bu
##   .i lo valsi poi no pagbu cu vasru ke'a tcila mu'u lo vi'uvla
##   .i lo selci'a poi se sitna cu tcila
##   .i lo nu to'e curmi kei jo'u le javni be le nu to'e curmi cu tcila
##
## ni'o le mupli cu gacri le tcila ta'i lo nu ro roi cuxna lo traji
##   .i lo jufra poi traji lo ka ce'u jmina so'i tcila poi na pu selja'o cu lidne ro datyju'a
##   .i va'o lo nu dunli kei lo jufra poi tormau cu selcu'a
##   .i ba bo va'o lo nu dunli kei lo jufra poi ckini lo mecna'u cu selcu'a
##   .i le gacri cu mulno va'o lo nu no jufra cu jmina su'o tcila
##
## ni'o jdima fa lo nu le mupli na du lo gacri poi traji lo ka ce'u cmalu
##   .i lo nu facki le gacri poi traji lo ka ce'u cmalu cu cmima `NP-hard`
##   .i ku'i lo ni le mupli cu barda cu na zmadu lo pilji be lo ni le raircmagai cu barda kei bei lo
##       dugri
##
## ni'o lo seljdi cu du lo seldu'a be le genturfa'i ca lo nu ciska
##   .i va'o lo nu le jufra cu se tcidu kei le seljdi cu kunti
##   .i va'o lo drata le seljdi cu du lo nu to'e curmi kei jo'u le javni mu'u `Grammar sumti-6 97`
##   .i le cipra cu fliba ca ro nu pa seljdi cu cenba
##
## ni'o lo minde po'u `tatoeba` cusku lo te kancu be ro se jdice ne'i le mulvei
##   .i `PROVENANCE.md` cusku le te kancu
##   .i jdima fa lo nu le minde cu tcidu ro jufra sepi'o le genturfa'i pa roi
##   .i se ki'u bo le nu le minde cu zukte cu mentu li ji'i 1

{.experimental: "strictFuncs".}

import std/[algorithm, options, os, osproc, sequtils, sets, strutils, tables]

import ../src/ricysoho/[grammar, lujvo, prose, stream]
import ./literals


type
  Sentence* = object
    ## pa jufra pe le vreji
    ##   .i le klesi cu vasru lo namcu .e lo selci'a .e lo ponse .e lo se tcidu pe le jufra
    id*: int  ## lo namcu poi `Tatoeba` dunda ke'a le jufra
    text*: string  ## le jufra ta'i lo nu le vreji cu ciska le jufra
    owner*: string
      ## lo cmene be lo ponse be le jufra
      ##   .i va'o lo nu no da ponse le jufra kei le cmene cu kunti
    verdict*: string
      ## lo nu to'e curmi kei jo'u lo javni vu'o poi le genturfa'i cu dunda ke'a
      ##   .i va'o lo nu le jufra cu se tcidu kei le seljdi cu kunti
    features*: HashSet[string]  ## lo tcila poi le se tcidu cu jarco ke'a

  Sample* = object
    ## lo seldu'a be le vreji
    ##   .i le klesi cu vasru lo jufra poi selcu'a ku'o .e lo seljdi ne'i le mulvei
    sentences*: seq[Sentence]  ## lo jufra pe le mupli ta'i lo porsi be lo namcu
    count_features*: int  ## lo te kancu be lo tcila poi su'o jufra pe le mupli cu jarco ke'a
    counts*: CountTable[string]
      ## lo te kancu be ro se jdice ne'i le mulvei
      ##   .i le seljdi be lo jufra poi se tcidu cu kunti
    count_sentences*: int  ## lo te kancu be lo jufra pe le mulno vreji
    digest*: string  ## `SHA-256` pe le vreji poi se tcidu


const
  DIGEST_TATOEBA* = "bf91e751a78a5137ffa741b0971df3c4e7a5444e18b47545be51d0593629bb40"
    ## `SHA-256` pe `jbo_sentences_detailed.tsv` noi selcpa fi le vreji pe de'i `2026-10-31` ta'i lo
    ##     nu kalri
  URL_TATOEBA* =
    "https://downloads.tatoeba.org/exports/per_language/jbo/jbo_sentences_detailed.tsv.bz2"
    ## lo judri poi le vreji cu selcpa fi ke'a
  URL_LICENCE* = "https://creativecommons.org/licenses/by/2.0/fr/"  ## le crujva pe le jufra
  URL_SENTENCE* = "https://tatoeba.org/en/sentences/show/"
    ## le judri be lo papri be pa jufra
    ##   .i le namcu pe le jufra cu se jmina fi le fanmo be le judri
  PATH_SENTENCES* = "tests/sample_tatoeba/sentences.nim"
    ## lo datnyvei poi le mupli cu selci'a fi ke'a
  PATH_NOTICE_TATOEBA* = "tests/sample_tatoeba/NOTICE.md"
    ## lo notci be le crujva
    ##   .i le notci cu lamji le samtci datnyvei
  OWNER_NONE = "\\N"  ## lo sinxa poi le vreji cu ciska ke'a va'o lo nu no da ponse le jufra
  WORDS_CONSTRUCT = 3
    ## lo te kancu be lo valsi pe pa gerna stura
    ##   .i lo tcila cu kancu su'e le te kancu
  INDENT_TEXT = 12
    ## lo stuzi poi lo selci'a pe lo claju'a cu cfari bu'u ke'a ba `text: ` pe le datnypau
  INDENT_CONTINUED = 10
    ## lo stuzi poi ro linji pe le selci'a zi'e poi na pamoi cu cfari bu'u ke'a
    ##   .i le stuzi cu zmadu le cfastu be le linji pe le datnypau fo li 4



#[ ni'o ni'o ni'o lo tcila ]#

func addShapes(features: var HashSet[string], node: Node, units: openArray[Unit]) =
  ## jmina lo tarmi be ro javni poi selcme gi'e cnita `node`
  ##   .i le tarmi cu du le javni jo'u lo tcita be lo panzi be le javni
  ##   .i va'o lo nu pa tcita cu rapli kei le tcita cu zvati le tarmi pa roi
  if node.is_terminal: return
  var labels: seq[string]
  for child in node.children:
    let label = (if child.is_terminal: $units[child.at].terminal else: child.rule)
    if labels.len == 0 or labels[^1] != label: labels.add label
  features.incl "shape " & node.rule & "(" & labels.join(" ") & ")"
  for child in node.children: features.addShapes(child, units)


func reading*(text: string): tuple[verdict: string, features: HashSet[string]] =
  ## tcidu lo jufra sepi'o le genturfa'i gi'e dunda lo seljdi pe le jufra ge'u .e lo tcila poi le se
  ##     tcidu cu jarco ke'a
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



#[ ni'o ni'o ni'o lo nu tcidu ]#

proc readSentences*(path: string): tuple[sentences: seq[Sentence], digest: string] =
  ## tcidu ro jufra pe le vreji poi zvati `path` ku'o sepi'o le genturfa'i gi'e dunda lo snina'u be
  ##     le datnyvei
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
  ## jdice lo du'u xu kau `a` lidne `b` va'o lo nu le re jufra cu jmina lo mityterkancu be lo tcila
  ##   .i lo jufra poi tormau cu lidne
  ##   .i va'o lo nu dunli kei lo jufra poi ckini lo mecna'u cu lidne
  (a.text.len, a.id) < (b.text.len, b.id)


func toSample*(sentences: openArray[Sentence], digest: string): Sample =
  ## cuxna lo mupli sepi'o lo nu gacri lo tcila ta'i lo nu ro roi cuxna lo traji
  ##   .i ji'a kancu ro seljdi ne'i ro jufra
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



#[ ni'o ni'o ni'o lo nu ciska ]#

func linesSentence(sentence: Sentence): seq[string] =
  ## ciska pa jufra ta'i lo zbafancu
  ##   .i va'o lo nu mapti kei le jufra cu selci'a fi pa linji
  ##   .i va'o lo drata ro datnypau cu selci'a fi pa linji
  let
    id = "id: " & $sentence.id
    owner = "owner: " & sentence.owner.toLiteral
    verdict = "verdict: " & sentence.verdict.toLiteral
    line = "    SentenceTatoeba(" & id & ", text: " & sentence.text.toLiteral & ", " & owner &
        ", " & verdict & "),"
  if line.isFit: return @[line]
  result.add "    SentenceTatoeba("
  result.add "      " & id & ","
  # ro pagbu cu mapti le pamoi linji
  #   .i lo selci'a pe le pamoi linji cu cfari bu'u lo stuzi poi traji lo ka darno
  let text = sentence.text.linesLiteral(INDENT_TEXT, ",")
  result.add "      text: " & text[0].strip(trailing = false)
  for line in text[1 .. ^1]: result.add repeat(' ', INDENT_CONTINUED) & line.strip(trailing = false)
  result.add "      " & owner & ","
  result.add "      " & verdict & ","
  result.add "    ),"


func toModuleSentences*(sample: Sample): string =
  ## ciska le mupli ta'i lo selci'a be fi le datnyvei poi selra'e
  var lines = @[
    "## ralte lo stomupli be fi lo lojbo jufra pe `Tatoeba` mu'i le cipra",
    "##   .i le mupli cu vasru lo seljdi be le genturfa'i bei ro le jufra",
    "##   .i lo minde po'u `nim r tools/build.nim tatoeba <export>` ciska le vi datnyvei ra'i",
    "##       `jbo_sentences_detailed.tsv` pe le vreji pe `Tatoeba` zi'e pe de'i `2026-10-31`",
    "##   .i lo snina'u be `jbo_sentences_detailed.tsv` cu du zoi ky. SHA-256",
    "##       `" & sample.digest[0..31] & "` `" & sample.digest[32 .. ^1] & "` .ky.",
    "##   .i lo nu xanga'i le vi datnyvei cu na drani",
    "##   .i lo nu galfi le vi datnyvei cu nitcu lo nu rapypli le minde",
    "##   .i lo jufra pe `Tatoeba` seljva `CC BY 2.0 FR`",
    "##   .i `NOTICE.md` noi lamji le vi datnyvei cu cusku lo du'u le datnyveiste poi vasru le vi",
    "##       datnyvei cu seljva le crujva gi'e no roi seljva le crujva pe `delegations`",
    "##   .i le mupli cu gacri lo tcila pe lo se tcidu ta'i lo nu ro roi cuxna lo traji",
    "##   .i `tools/tatoeba.nim` skicu le tcila",
    "",
    "{.experimental: \"strictFuncs\".}",
    "",
    "",
    "type SentenceTatoeba* = object",
    "  ## pa jufra pe le mupli",
    "  ##   .i le klesi cu vasru lo namcu .e lo selci'a .e lo ponse .e lo seljdi",
    "  id* {.requiresInit.}: int",
    "    ## lo namcu poi `Tatoeba` dunda ke'a le jufra ku'o mu'u `599308`",
    "  text* {.requiresInit.}: string  ## le jufra ta'i lo nu le vreji cu ciska le jufra",
    "  owner* {.requiresInit.}: string",
    "    ## lo cmene be lo ponse be le jufra",
    "    ##   .i va'o lo nu no da ponse le jufra kei le cmene cu kunti",
    "  verdict* {.requiresInit.}: string",
    "    ## lo nu to'e curmi kei jo'u lo javni vu'o poi le genturfa'i pu dunda ke'a",
    "    ##   .i va'o lo nu le jufra cu se tcidu kei le seljdi cu kunti",
    "",
    "",
    "const",
    "  COUNT_FEATURES_TATOEBA* = " & $sample.count_features,
    "    ## lo te kancu be lo tcila pe lo se tcidu zi'e poi le mupli cu jarco ke'a ca lo nu ciska",
    "  SENTENCES_TATOEBA* = [",
  ]
  for sentence in sample.sentences: lines.add sentence.linesSentence
  lines.add "  ]"
  lines.add "    ## lo jufra pe le mupli ta'i lo porsi be lo namcu"
  lines.join("\n") & "\n"


func toKeyDictionary(text: string): (string, string) =
  ## dunda lo ckiku be lo vlaste porsi
  ##   .i lo ka brale'u kei .e `_` na'e vajni
  ##   .i va'o lo nu dunli kei lo lerna'u cu jdice to `Article X.10` toi
  (text.toLowerAscii.replace("_", ""), text)


func toNotice*(sample: Sample): string =
  ## ciska lo notci be le crujva
  ##   .i le notci cu cusku ro nu galfi kei gi'e sitna ro ponse be lo jufra
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
