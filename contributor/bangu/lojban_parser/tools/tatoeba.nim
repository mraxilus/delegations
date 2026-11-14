## cuxna lo stodi mupli be fi lo lojbo jufra pe la'o gy. Tatoeba .gy. be'o poi jarco so'e javni pe
##   la'o gy. CLL .gy. .i ciska le mupli ta'i pa samtci datnyvei pe la'o gy. Nim .gy. zi'e poi ponse
##   lo klesi gi'e vasru lo se jdice be le genturfa'i bei ro le jufra .i `build.nim` cu pilno le vi
##   datnyvei
##   .i tcidu `jbo_sentences_detailed.tsv` .i le datnyvei cu se cpacu fi le vreji poi `URL_TATOEBA`
##     cu benji ke'a ku'o ta'i lo nu kalri le vreji .i le datnyvei cu se stodi sinxa sepi'o la'o gy.
##     SHA-256 .gy. ta'i lo nu `lists.nim` cu stodi sinxa lo liste .i ciska
##     `tests/sample_tatoeba/sentences.nim` .e `NOTICE.md` noi lamji `sentences.nim`
##
##   .i la'o gy. Architect .gy. cu jdice `D4 c` bu'u `#819` .i le mupli cu stodi gi'e no roi se
##     jdice lo tsiju .i ki'u bo le vreji cu zenba po'o .i le mupli cu vrici .i se ki'u bo le jufra
##     pe le mupli cu jarco ro javni be fi la'o gy. CLL .gy. be'o poi le jufra cu ka'e jarco ke'a
##   .i lo tcila cu se jarco lo se tcidu pe pa jufra .i lo tarmi be ro javni poi se cmene gi'e zvati
##     le tricu cu tcila .i lo tarmi cu du le javni jo'u lo tcita be lo panzi be le javni .i va'o lo
##     nu pa tcita cu rapli kei le tcita cu zvati le tarmi pa roi .i ro gerna valsi cu tcila .i ro
##     gerna stura poi se skicu `CLL 19.16` gi'e vasru su'o re valsi cu tcila .i ro klesi be lo
##     valsi be'o .e ro tarmi be lo rafsi be'o .e ro lerfu jorne pe lo lujvo cu tcila .i lo sinxa pe
##     lo porsi be lo valsi cu tcila .i le sinxa cu du lo denpa jo'u lo nu basna kei jo'u lo lerfu
##     po'u slaka bu .i lo valsi poi no pagbu cu vasru ke'a cu tcila mu'u lo vimcu valsi .i lo se
##     ciska poi se sitna cu tcila .i lo nu to'e curmi kei jo'u le javni be le nu to'e curmi cu
##     tcila
##   .i le mupli cu gacri le tcila ta'i lo nu ro roi cuxna lo traji .i lo jufra poi traji lo ka ce'u
##     jmina so'i tcila poi na pu se jarco cu lidne ro drata jufra .i va'o lo nu dunli kei lo jufra
##     poi tordu zmadu cu se cuxna .i ba bo va'o lo nu dunli kei lo jufra poi ckini lo mleca namcu
##     cu se cuxna .i le gacri cu mulno va'o lo nu no jufra cu jmina su'o tcila
##     .i jdima fa lo nu le mupli na du lo gacri poi traji lo ka ce'u cmalu .i lo nu facki le gacri
##       poi traji lo ka ce'u cmalu cu cmima la'o gy. NP-hard .gy. .i ku'i lo ni le mupli cu barda
##       kei cu na zmadu lo pilji be lo ni le traji cmalu gacri cu barda kei bei lo dugri
##   .i lo se jdice cu du lo se dunda be le genturfa'i ca lo nu ciska .i va'o lo nu le jufra cu se
##     tcidu kei le se jdice cu kunti .i va'o lo drata le se jdice cu du lo nu to'e curmi kei jo'u
##     le javni mu'u `Grammar sumti-6 97` .i le cipra cu fliba ca ro nu pa se jdice cu cenba
##   .i lo minde po'u `tatoeba` cu cusku lo te kancu be ro se jdice ne'i le mulno vreji .i
##     `PROVENANCE.md` cu cusku le te kancu
##   .i jdima fa lo nu le minde cu tcidu ro jufra sepi'o le genturfa'i pa roi .i se ki'u bo le nu le
##     minde cu zukte kei cu mentu li ji'i pa

{.experimental: "strictFuncs".}

import std/[algorithm, options, os, osproc, sequtils, sets, strutils, tables]

import ../src/lojban_parser/[grammar, lujvo, prose, stream]
import ./literals


type
  Sentence* = object
    ## pa jufra pe le vreji .i le klesi cu vasru lo namcu .e lo se ciska .e lo ponse .e lo se tcidu
    ##   pe le jufra
    id*: int  ## lo namcu poi la'o gy. Tatoeba .gy. cu dunda ke'a le jufra
    text*: string  ## le jufra ta'i lo nu le vreji cu ciska le jufra
    owner*: string
      ## lo cmene be lo ponse be le jufra .i va'o lo nu no da ponse le jufra kei le cmene cu kunti
    verdict*: string
      ## lo nu to'e curmi kei jo'u lo javni vu'o poi le genturfa'i cu dunda ke'a .i va'o lo nu le
      ##   jufra cu se tcidu kei le se jdice cu kunti
    features*: HashSet[string]  ## lo tcila poi le se tcidu cu jarco ke'a

  Sample* = object
    ## lo se dunda be le vreji .i le klesi cu vasru lo jufra poi se cuxna ku'o .e lo se jdice ne'i
    ##   le mulno vreji
    sentences*: seq[Sentence]  ## lo jufra pe le mupli ta'i lo porsi be lo namcu
    count_features*: int  ## lo te kancu be lo tcila poi su'o jufra pe le mupli cu jarco ke'a
    counts*: CountTable[string]
      ## lo te kancu be ro se jdice ne'i le mulno vreji .i le se jdice be lo jufra poi se tcidu cu
      ##   kunti
    count_sentences*: int  ## lo te kancu be lo jufra pe le mulno vreji
    digest*: string  ## la'o gy. SHA-256 .gy. pe le vreji poi se tcidu


const
  DIGEST_TATOEBA* = "bf91e751a78a5137ffa741b0971df3c4e7a5444e18b47545be51d0593629bb40"
    ## la'o gy. SHA-256 .gy. pe `jbo_sentences_detailed.tsv` noi se cpacu fi le vreji pe de'i
    ##   `2026-10-31` ta'i lo nu kalri
  URL_TATOEBA* =
    "https://downloads.tatoeba.org/exports/per_language/jbo/jbo_sentences_detailed.tsv.bz2"
    ## lo judri poi le vreji cu se cpacu fi ke'a
  URL_LICENCE* = "https://creativecommons.org/licenses/by/2.0/fr/"  ## le curmi javni pe le jufra
  URL_SENTENCE* = "https://tatoeba.org/en/sentences/show/"
    ## le judri be lo papri be pa jufra .i le namcu pe le jufra cu se jmina fi le fanmo be le judri
  PATH_SENTENCES* = "tests/sample_tatoeba/sentences.nim"
    ## lo datnyvei poi le mupli cu se ciska fi ke'a
  PATH_NOTICE_TATOEBA* = "tests/sample_tatoeba/NOTICE.md"
    ## lo notci be le curmi javni .i le notci cu lamji le samtci datnyvei
  OWNER_NONE = "\\N"  ## lo sinxa poi le vreji cu ciska ke'a va'o lo nu no da ponse le jufra
  WORDS_CONSTRUCT = 3
    ## lo te kancu be lo valsi pe pa gerna stura .i lo tcila cu kancu su'e le te kancu
  INDENT_TEXT = 12
    ## lo stuzi poi lo se ciska pe lo clani jufra cu cfari bu'u ke'a ba `text: ` pe le datni pagbu
  INDENT_CONTINUED = 10
    ## lo stuzi poi ro linji pe le se ciska zi'e poi na pamoi cu cfari bu'u ke'a .i le stuzi cu
    ##   zmadu le cfari stuzi be le linji pe le datni pagbu fo li vo



#[ lo tcila ]#

func addShapes(features: var HashSet[string], node: Node, units: openArray[Unit]) =
  ## jmina lo tarmi be ro javni poi se cmene gi'e cnita `node` .i le tarmi cu du le javni jo'u lo
  ##   tcita be lo panzi be le javni .i va'o lo nu pa tcita cu rapli kei le tcita cu zvati le tarmi
  ##   pa roi
  if node.is_terminal: return
  var labels: seq[string]
  for child in node.children:
    let label = (if child.is_terminal: $units[child.at].terminal else: child.rule)
    if labels.len == 0 or labels[^1] != label: labels.add label
  features.incl "shape " & node.rule & "(" & labels.join(" ") & ")"
  for child in node.children: features.addShapes(child, units)


func reading*(text: string): tuple[verdict: string, features: HashSet[string]] =
  ## tcidu lo jufra sepi'o le genturfa'i gi'e dunda lo se jdice pe le jufra ge'u .e lo tcila poi le
  ##   se tcidu cu jarco ke'a
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



#[ lo nu tcidu ]#

proc readSentences*(path: string): tuple[sentences: seq[Sentence], digest: string] =
  ## tcidu ro jufra pe le vreji poi zvati `path` ku'o sepi'o le genturfa'i gi'e dunda lo sinxa namcu
  ##   be le datnyvei
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
  ## jdice lo du'u xu kau `a` cu lidne `b` va'o lo nu le re jufra cu jmina lo mintu te kancu be lo
  ##   tcila .i lo jufra poi tordu zmadu cu lidne .i va'o lo nu dunli kei lo jufra poi ckini lo
  ##   mleca namcu cu lidne
  (a.text.len, a.id) < (b.text.len, b.id)


func toSample*(sentences: openArray[Sentence], digest: string): Sample =
  ## cuxna lo mupli sepi'o lo nu gacri lo tcila ta'i lo nu ro roi cuxna lo traji .i ji'a kancu ro se
  ##   jdice ne'i ro jufra
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



#[ lo nu ciska ]#

func linesSentence(sentence: Sentence): seq[string] =
  ## ciska pa jufra ta'i lo zbasu fancu .i va'o lo nu mapti kei le jufra cu se ciska fi pa linji .i
  ##   va'o lo drata ro datni pagbu cu se ciska fi pa linji
  let
    id = "id: " & $sentence.id
    owner = "owner: " & sentence.owner.toLiteral
    verdict = "verdict: " & sentence.verdict.toLiteral
    line = "    SentenceTatoeba(" & id & ", text: " & sentence.text.toLiteral & ", " & owner &
        ", " & verdict & "),"
  if line.isFit: return @[line]
  result.add "    SentenceTatoeba("
  result.add "      " & id & ","
  # ro pagbu cu mapti le pamoi linji .i lo se ciska pe le pamoi linji cu cfari bu'u lo stuzi poi
  #   traji lo ka darno
  let text = sentence.text.linesLiteral(INDENT_TEXT, ",")
  result.add "      text: " & text[0].strip(trailing = false)
  for line in text[1 .. ^1]: result.add repeat(' ', INDENT_CONTINUED) & line.strip(trailing = false)
  result.add "      " & owner & ","
  result.add "      " & verdict & ","
  result.add "    ),"


func toModuleSentences*(sample: Sample): string =
  ## ciska le mupli ta'i lo se ciska be fi le datnyvei poi se ralte
  var lines = @[
    "## ralte lo stodi mupli be fi lo lojbo jufra pe la'o gy. Tatoeba .gy. mu'i le cipra .i le",
    "##   mupli cu vasru lo se jdice be le genturfa'i bei ro le jufra",
    "##   .i lo minde po'u `nim r tools/build.nim tatoeba <export>` cu ciska le vi datnyvei ra'i",
    "##   `jbo_sentences_detailed.tsv` pe le vreji pe la'o gy. Tatoeba .gy. zi'e pe de'i",
    "##   `2026-10-31` .i lo sinxa namcu be `jbo_sentences_detailed.tsv` cu du",
    "##   zoi ky. SHA-256 `" & sample.digest[0..31] & "`",
    "##   `" & sample.digest[32 .. ^1] & "` .ky. .i lo nu xance galfi le vi datnyvei cu na drani",
    "##   .i lo nu galfi le vi datnyvei cu nitcu lo nu rapli pilno le minde",
    "##   .i lo jufra pe la'o gy. Tatoeba .gy. cu se javni la'o gy. CC BY 2.0 FR .gy. .i",
    "##     `NOTICE.md` noi lamji le vi datnyvei cu cusku lo du'u le datnyveiste poi vasru le vi",
    "##     datnyvei cu se javni le curmi javni gi'e no roi se javni le curmi javni pe la'o gy.",
    "##     delegations .gy.",
    "##   .i le mupli cu gacri lo tcila pe lo se tcidu ta'i lo nu ro roi cuxna lo traji .i",
    "##     `tools/tatoeba.nim` cu skicu le tcila",
    "",
    "{.experimental: \"strictFuncs\".}",
    "",
    "",
    "type SentenceTatoeba* = object",
    "  ## pa jufra pe le mupli .i le klesi cu vasru lo namcu .e lo se ciska .e lo ponse .e " &
    "lo se jdice",
    "  id* {.requiresInit.}: int",
    "    ## lo namcu poi la'o gy. Tatoeba .gy. cu dunda ke'a le jufra ku'o mu'u `599308`",
    "  text* {.requiresInit.}: string  ## le jufra ta'i lo nu le vreji cu ciska le jufra",
    "  owner* {.requiresInit.}: string",
    "    ## lo cmene be lo ponse be le jufra .i va'o lo nu no da ponse le jufra kei le cmene " &
    "cu kunti",
    "  verdict* {.requiresInit.}: string",
    "    ## lo nu to'e curmi kei jo'u lo javni vu'o poi le genturfa'i pu dunda ke'a .i va'o lo nu",
    "    ##   le jufra cu se tcidu kei le se jdice cu kunti",
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
  ## dunda lo ckiku be lo vlaste porsi .i lo ka barda lerfu kei .e `_` cu na'e vajni .i va'o lo nu
  ##   dunli kei lo lerfu namcu cu jdice to `Article X.10` toi
  (text.toLowerAscii.replace("_", ""), text)


func toNotice*(sample: Sample): string =
  ## ciska lo notci be le curmi javni .i le notci cu cusku ro nu galfi kei gi'e sitna ro ponse be lo
  ##   jufra
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
