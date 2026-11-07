## Fetch translations into lojban that suites read where present, pinned by digest and kept out
##   of repository, and read their paragraphs; `build.nim` runs it.
##   Ruling `D3 a` of #819: each translation is pinned and kept out of repository, since no
##     translator stated release. Ruling `D5 c`: suites read Alice and Oz where pinned page is
##     present, and runner, which has none, skips them.
##   Verb fetches each page with `curl` into `DIRECTORY_TRANSLATIONS`, which ignore file keeps out
##     of every commit, and checks digest against pin; page that differs is named, never read.
##     Digest is of page with each `script` element cut, as `cll.nim` cuts it: server of Alice
##       writes script that differs at each request, which text never holds.
##   Paragraph is text of one `p` element: tags dropped, entities decoded, white space collapsed.
##   Reading drops marks CLL does not define: guillemets, dashes, parentheses, colon, asterisk,
##     marks of question and exclamation, quote, and accent or breve over vowel. Capitals stay,
##     since CLL 3.9 defines them as stress.
##     Cost: accent of Oz marks stress, which reading drops, so brivla reads as stressed where
##       its form puts stress; CLL 3.9 calls more stress than that secondary, and gives it no
##       written mark.
##   Page of Oz holds Windows-1252, though its header declares UTF-8; reader converts it.
##   Cost: few named entities are decoded, those pages use; other one stays, and stream refuses
##     its `&`, naming it.

{.experimental: "strictFuncs".}

import std/[encodings, options, os, osproc, strutils]
from std/unicode import `$`, Rune

import ./cll


type Translation* = object  ## Define one translation suites read where its pinned page is present.
  name*: string  ## Name of page under `DIRECTORY_TRANSLATIONS`, without extension.
  title*: string  ## Title of work, and its translator.
  url*: string  ## Address page is fetched from.
  digest*: string  ## SHA-256 of page fetched 2026-11-06, each `script` element cut.
  encoding*: string  ## Encoding of bytes of page.


const
  DIRECTORY_TRANSLATIONS* = "build/translations"  ## Directory, under project, pages stand in.
  TRANSLATIONS* = [
    Translation(
      name: "alis",
      title: "Alice's Adventures in Wonderland, by xorxes",
      url: "https://alis.lojban.org/",
      digest: "7403e92551f5de7d96b5f8d2e5ebae34cafa8535bdf7cb9cdf9da2e6c2078687",
      encoding: "UTF-8",
    ),
    Translation(
      name: "oz",
      title: "The Wonderful Wizard of Oz, by selpa'i",
      url: "https://selpahi.de/oz.html",
      digest: "adfde23a848147ed1f7d56e7b33a3b3b65e3d88e00b1ab41759963c443847ea6",
      encoding: "CP1252",
    ),
  ]
    ## Translations of Alice and Oz, as `D5 c` names them.
  MARKS_DROPPED = [
    "«", "»", "—", "–", "\u0096", "\u0097", "-", "(", ")", ":", "*", "!", "?",
    "\"", "¬",
  ]
    ## Marks CLL does not define, which reading drops: guillemets, dashes, and other punctuation.
  VOWELS_MARKED = [
    ("à", "a"), ("á", "a"), ("è", "e"), ("é", "e"), ("ì", "i"),
    ("í", "i"), ("ò", "o"), ("ó", "o"), ("ù", "u"), ("ú", "u"),
    ("ŭ", "u"), ("ĭ", "i"), ("À", "A"), ("Á", "A"), ("È", "E"),
    ("É", "E"), ("Ì", "I"), ("Í", "I"), ("Ò", "O"), ("Ó", "O"),
    ("Ù", "U"), ("Ú", "U"), ("Ŭ", "U"), ("Ĭ", "I"),
  ]
    ## Vowel with accent or breve, with vowel reading keeps; case stays.
  ENTITIES_NAMED = [
    ("nbsp", " "), ("amp", "&"), ("lt", "<"), ("gt", ">"), ("quot", "\""), ("apos", "'"),
    ("agrave", "à"),
  ]
    ## Named entities pages use, each with text it stands for.



#[ Reading ]#

func toEntitiesDecoded(text: string): string =
  ## Decode each named entity `ENTITIES_NAMED` holds, and each numeric one.
  var at = 0
  while at < text.len:
    let closing = (if text[at] == '&': text.find(';', at) else: -1)
    if closing < 0 or closing - at > 10:
      result.add text[at]
      inc at
      continue
    let name = text[at+1..<closing]
    var decoded = none(string)
    if name.startsWith("#x"): decoded = some($Rune(parseHexInt(name[2 .. ^1])))
    elif name.startsWith("#"): decoded = some($Rune(parseInt(name[1 .. ^1])))
    else:
      for (entity, text_entity) in ENTITIES_NAMED:
        if entity == name: decoded = some(text_entity)
    if decoded.isNone:
      result.add text[at]
      inc at
      continue
    result.add decoded.get
    at = closing + 1


func toReading(text: string): string =
  ## Drop marks CLL does not define, keep each vowel under its accent or breve, collapse space.
  var kept = text
  for mark in MARKS_DROPPED: kept = kept.replace(mark, " ")
  for (marked, vowel) in VOWELS_MARKED: kept = kept.replace(marked, vowel)
  kept.splitWhitespace.join(" ")


func paragraphs*(page: string): seq[string] =
  ## Read text of each `p` element of page, as reading keeps it; empty paragraph left out.
  let lower = page.toLowerAscii
  var at = 0
  while true:
    let opening = lower.find("<p", at)
    if opening < 0: break
    let after = opening + 2
    if after < lower.len and lower[after] notin {'>', ' ', '\t', '\n', '\r'}:
      at = after
      continue
    let
      start = lower.find('>', after) + 1
      closing = lower.find("</p>", start)
    if start <= 0 or closing < 0: break
    var
      text: string
      depth = 0
    for letter in page[start..<closing]:
      if letter == '<': inc depth
      elif letter == '>': depth = max(0, depth - 1)
      elif depth == 0: text.add letter
      if letter == '>': text.add ' '
    let reading = text.toEntitiesDecoded.toReading
    if reading.len > 0: result.add reading
    at = closing + 4


proc readDigest(path: string): string =
  ## Hash page at `path`, each `script` element cut, by `sha256sum`.
  let (output, code) = execCmdEx("sha256sum", input = readFile(path).toPageXml)
  if code != 0: quit "Digest could not be read; got `" & output.strip & "`.", 1
  output.splitWhitespace[0]


proc readTranslation*(translation: Translation, root: string): Option[seq[string]] =
  ## Read paragraphs of translation under `root`; none where page is absent or moved from pin.
  let path = root / DIRECTORY_TRANSLATIONS / translation.name & ".html"
  if not fileExists(path) or path.readDigest != translation.digest: return none(seq[string])
  let page =
    if translation.encoding == "UTF-8": readFile(path)
    else: convert(readFile(path), "UTF-8", translation.encoding)
  some(page.paragraphs)


proc fetchTranslation*(translation: Translation, root: string): string =
  ## Fetch page of translation into `DIRECTORY_TRANSLATIONS` under `root`, and give its digest.
  let path = root / DIRECTORY_TRANSLATIONS / translation.name & ".html"
  createDir(path.parentDir)
  let (output, code) = execCmdEx(
    "curl -sS -L --max-time 120 -o " & quoteShell(path) & " " & quoteShell(translation.url),
  )
  if code != 0: quit "Page could not be fetched; got `" & output.strip & "` for `" &
      translation.url & "`.", 1
  path.readDigest
