## galfi le gismu liste .e le cmavo liste vu'o pe la'o gy. Logical Language Group .gy. lo samtci
##   datnyvei pe la'o gy. Nim .gy. zi'e poi ponse lo klesi gi'e se ralte le vi se gunka
##   .i ji'a stodi sinxa le lujvo liste noi lo cipra cu tcidu ke'a ta'i lo drata se ciska
##   .i tcidu `gismu.txt` .e `cmavo.txt` ta'i lo nu `lojban-common` noi bakfu ne'i la'o gy. Debian
##     .gy. ku'o cu punji le re datnyvei
##   .i ciska `src/lojban_parser/lists/gismu.nim` .e `cmavo.nim`
##   .i `build.nim` cu pilno le vi datnyvei
##
## ni'o le galfi samtci pe `lojban_tagger/tools/lists.nim` cu cpacu `Source` .e `readSource` .e
##   `KEY_LISTS` .e `DIRECTORY_LISTS` .e `DIGEST_GISMU` .e `DIGEST_LUJVO` le vi datnyvei
##   .i se ki'u bo ro le xa se cpacu cu se pilno su'o samtci poi na pagbu le genturfa'i
##   .i ji'a ro stodi sinxa cu se ciska pa roi gi'e se pilno le re se gunka
##   .i le galfi samtci cu ponse pa sivni fancu po'u `field` noi fukpi `field` pe le vi datnyvei to
##     `Article II.9` toi
##   .i lo nu cikre pa le re fancu cu na mulno pu lo nu le drata fancu cu se cipra
##   .i lo stuzi pe `gismu.txt` ge'u .e lo stuzi pe `cmavo.txt` cu stodi
##   .i `entries.nim` cu ciska le stuzi ne'i lo lijgri liste
##   .i ro kuspe pe le vi datnyvei cu se merli ne'i ro linji pe ro le re datnyvei
##   .i le nu merli cu jarco lo du'u ro linji cu vasru no lerfu poi zvati lo jbini be re datni pagbu
##   .i le samtci datnyvei cu ralte ro datni pagbu poi lo javni cu nitcu ke'a ku'o gi'e ralte no
##     drata datni pagbu to `entries.nim` toi
##   .i se ki'u bo ro liste cmima cu se ciska fi pa linji poi mutce tordu gi'e vasru me'i panono
##     stuzi
##   .i no datni pagbu cu nitcu lo nu se fendi fi su'o re linji
##   .i le cmavo liste cu ralte ro linji poi vasru pa cmavo po'o
##   .i ro linji poi lo selma'o pe ke'a cu se tcita `*` cu se vimcu
##   .i ro le linji cu vasru pa cmavo gunma .a pa jufra pagbu
##   .i le galfi samtci cu tcidu lo cmene be lo selma'o
##   .i le cmene cu lidne lo klesi poi le liste cu ciska ke'a
##   .i va'o lo nu `CLL 20` cu na dunda le cmene kei le galfi samtci cu fliba gi'e cusku le linji
##   .i no samtci datnyvei cu se zbasu fi `lujvo.txt`
##   .i ki'u bo le lujvo liste cu dunda lo smuni gi'e no roi dunda lo ka drani
##   .i se ki'u bo le lujvo liste cu stali `lojban_tagger`
##   .i lo cipra cu tcidu le datnyvei poi se punji ku'o ta'i lo drata se ciska
##   .i le vi datnyvei cu stodi sinxa le datnyvei sepi'o lo sinxa namcu
##   .i va'o lo nu le datnyvei cu na zvati gi'a cenba kei lo cipra cu na zukte to `Article IX.9` toi
##   .i le vi datnyvei cu stodi sinxa ro krasi sepi'o la'o gy. SHA-256 .gy.
##   .i lo nu la'o gy. Debian .gy. cu galfi pa liste kei cu rinka lo nu lo minde po'u `lists` cu
##     to'e curmi kei .e lo nu lo minde po'u `head` cu cusku le nu galfi
##   .i le nu galfi cu no roi rinka lo nu smaji ke rapli ciska le se ralte liste kei .a lo nu smaji
##     tcidu lo drata se ciska
##   .i lo nu ciska lo samtci datnyvei cu ro roi dunda lo mintu se ciska ra'i lo mintu krasi
##   .i se ki'u bo lo minde po'u `head` cu karbi ro stuzi be lo se ciska le mintu stuzi be le se
##     ralte
##   .i jdima fa lo nu le vi datnyvei cu pilno `sha256sum` mu'i lo nu tcidu lo sinxa namcu
##   .i lo minde po'u `system` cu cusku `sha256sum`
##   .i lo fadni samtci pe la'o gy. Nim .gy. cu na vasru la'o gy. SHA-256 .gy.

{.experimental: "strictFuncs".}

import std/[enumutils, options, os, osproc, strutils]

import ../src/lojban_parser/[entries, selmaho]


type
  Source* = object
    ## pa liste datnyvei poi se tcidu
    ##   .i le klesi cu vasru lo stuzi be le datnyvei be'o .e lo sinxa namcu be le stuzi
    text*: string
      ## lo se vasru be le datnyvei
      ##   .i ro lerfu po'u la'o gy. carriage return .gy. cu se vimcu
    digest*: string
      ## la'o gy. SHA-256 .gy. pe lo stuzi poi se punji
      ##   .i le sinxa namcu cu se ciska ta'i la'o gy. hex .gy. sepi'o lo cmalu lerfu


const
  KEY_LISTS* = "LOJBAN_PARSER_LISTS"
    ## lo cmene be lo vanbi cenba poi basti lo datnyveiste poi le liste cu se tcidu fi ke'a
  DIRECTORY_LISTS* = "/usr/share/lojban"
    ## lo datnyveiste poi `lojban-common` noi bakfu ku'o cu punji le liste ke'a
  DIGEST_GISMU* = "f2fc4cff4f265ad02717d56733b4627ffa78c616db78dcaa44caab694e1dd5b7"
    ## la'o gy. SHA-256 .gy. pe `gismu.txt` pe la'o gy. 1.5+dfsg.1-4 .gy. pe `lojban-common`
    ##   .i lo stedu be le datnyvei cu cusku lo detri po'u zoi gy. 9/26/94 .gy.
  DIGEST_LUJVO* = "23c182f3534f4e33efbb4a3d92cd943427d5a6fdf3b061b07cd6bbc3d0e6b0cc"
    ## la'o gy. SHA-256 .gy. pe `lujvo.txt` pe la'o gy. 1.5+dfsg.1-4 .gy. pe `lojban-common`
    ##   .i lo cipra cu tcidu le datnyvei ta'i lo drata se ciska
  DIGEST_CMAVO* = "544414d61f3ff35dd2cf4e4f79f3c86bf9bb0568eb3403f57288057e16796402"
    ## la'o gy. SHA-256 .gy. pe `cmavo.txt` pe la'o gy. 1.5+dfsg.1-4 .gy. pe `lojban-common`
    ##   .i lo stedu be le datnyvei cu cusku lo detri po'u zoi gy. 26 August 2002 .gy.
    ##   .i lo cipra cu tcidu le datnyvei ta'i lo drata se ciska
  PATH_GISMU* = "src/lojban_parser/lists/gismu.nim"
    ## lo datnyvei poi le gismu liste cu se ciska fi ke'a
  PATH_CMAVO* = "src/lojban_parser/lists/cmavo.nim"
    ## lo datnyvei poi le cmavo liste cu se ciska fi ke'a
  NOTICE_GISMU = [
    ".i le vi datnyvei cu se zbasu fi lo datni poi la'o gy. Logical Language Group .gy. cu rinka " &
    "lo",
    "  nu ke'a zifre fi ro da",
    ".i le girzu cu cpedu lo nu lo se zbasu be fi le datni cu cusku lo tadji be lo nu zbasu",
    ".i le vi pinka cu cusku le tadji",
    ".i le minde cu ralte lo stuzi be lo valsi jo'u lo rafsi pe `entries.nim` gi'e vimcu ro drata",
    "  stuzi",
    ".i le minde cu vimcu ji'a ro lerfu po'u la'o gy. carriage return .gy. ge'u .e ro kunti lerfu",
    "  poi zvati lo fanmo be lo datni pagbu",
    ".i lo zmadu datni be la lojban. cu zvati",
    "  `Logical Language Group, Inc., 2904 Beau Lane, Fairfax VA 22031 USA` .e",
    "  `https://www.lojban.org/`",
  ]
    ## lo linji poi le datnyvei pe le gismu liste cu vasru ke'a ja'i lo se cpedu be le notci be lo
    ##   du'u le datni cu zifre fi ro da
  NOTICE_CMAVO = [
    ".i le vi datnyvei cu se zbasu fi lo datni poi la'o gy. Logical Language Group .gy. cu rinka " &
    "lo",
    "  nu ke'a zifre fi ro da",
    ".i le girzu cu cpedu lo nu lo se zbasu be fi le datni cu cusku lo tadji be lo nu zbasu",
    ".i le vi pinka cu cusku le tadji",
    ".i le minde cu ralte lo linji poi vasru pa cmavo po'o ku'o gi'e ralte lo stuzi be lo valsi " &
    "jo'u",
    "  lo selma'o pe `entries.nim` gi'e vimcu ro drata stuzi",
    ".i le minde cu vimcu ji'a lo lerfu po'u denpa bu ge'u .e lo klesi be lo selma'o be'o .e ro",
    "  lerfu po'u la'o gy. carriage return .gy. ge'u .e ro kunti lerfu poi zvati lo fanmo be lo",
    "  datni pagbu",
    ".i lo zmadu datni be la lojban. cu zvati",
    "  `Logical Language Group, Inc., 2904 Beau Lane, Fairfax VA 22031 USA` .e",
    "  `https://www.lojban.org/`",
  ]
    ## lo linji poi le datnyvei pe le cmavo liste cu vasru ke'a ja'i le mintu se cpedu



#[ ni'o ni'o ni'o lo nu tcidu ]#

proc readSource*(name: string): Source =
  ## tcidu lo liste datnyvei poi se cmene `name` ku'o fi lo datnyveiste poi lo vanbi cu cusku lo
  ##   cmene be ke'a
  ##   .i va'o lo drata tcidu le liste datnyvei fi lo datnyveiste pe le bakfu
  let
    directory = getEnv(KEY_LISTS, DIRECTORY_LISTS)
    path = directory / name
  if not fileExists(path):
    quit "List is missing; install `lojban-common` or set `" & KEY_LISTS & "`; got `" & path &
        "`.", 1
  let (output, code) = execCmdEx("sha256sum " & quoteShell(path))
  if code != 0: quit "Digest could not be read; got `" & output.strip & "`.", 1
  Source(text: readFile(path).replace("\r", ""), digest: output.splitWhitespace[0])


func field(line: string, first, last: int): string =
  ## tcidu lo stuzi po'u `first` bi'o `last`
  ##   .i lo namcu pe le pamoi stuzi cu du li pa ja'i `entries.nim`
  ##   .i lo kunti lerfu poi zvati lo fanmo be le se tcidu cu se vimcu
  if line.len < first: return ""
  line[first - 1 .. min(last, line.len) - 1].strip


func toEntriesGismu*(text: string): seq[EntryGismu] =
  ## tcidu ro liste cmima pe `gismu.txt`
  ##   .i le stedu linji cu na se tcidu
  for line in text.splitLines[1 .. ^1]:
    if line.strip.len == 0: continue
    var rafsi: seq[string]
    for (first, last) in [(8, 10), (12, 14), (16, 19)]:
      let one = line.field(first, last)
      if one.len > 0: rafsi.add one
    result.add EntryGismu(word: line.field(2, 6), rafsi: rafsi)


func nameSelmaho*(text: string): string =
  ## tcidu lo cmene be lo selma'o
  ##   .i le cmene cu lidne ro sinxa .e ro klesi vu'o poi le liste cu ciska ke'a ba le cmene
  ##   .i mupli fa `UI` pe `UI3a`
  for letter in text:
    if letter notin {'A' .. 'Z', 'h'}: break
    result.add letter


func toEntriesCmavo*(text: string): seq[EntryCmavo] =
  ## tcidu ro linji pe `cmavo.txt` zi'e poi vasru pa cmavo po'o
  ##   .i le stedu linji cu na se tcidu
  for line in text.splitLines[1 .. ^1]:
    if line.strip.len == 0: continue
    let column = line.field(12, 20)
    # lo cmavo gunma .a lo jufra pagbu
    #   .i ro cmavo pe le gunma cu ponse lo linji pe vo'a
    if '*' in column: continue
    let
      word = line.field(1, 11).replace(".", "")
      found = column.nameSelmaho.toSelmaho
    doAssert found.isSome,
      "Selma'o should be one chapter 20 names; got `" & column & "` for `" & word & "`."
    result.add EntryCmavo(word: word, selmaho: found.get)



#[ ni'o ni'o ni'o lo nu ciska ]#

func toLiteral(text: string): string =
  ## ciska lo se ciska ta'i pa se sitna lerpoi pe la'o gy. Nim .gy.
  ##   .i lo valsi .e lo rafsi cu vasru lo lojbo lerfu jo'u lo lerfu po'u zoi gy. ' .gy. gi'e vasru
  ##     no drata lerfu
  "\"" & text & "\""


func toModuleGismu*(entries: openArray[EntryGismu], digest: string): string =
  ## ciska lo liste cmima pe le gismu liste ta'i lo se ciska be fi le datnyvei poi se ralte
  ##   .i ro liste cmima cu zvati pa linji
  var lines = @[
    "## ralte le gismu liste pe la'o gy. Logical Language Group .gy. ta'i lo liste cmima poi " &
    "ponse lo",
    "##   klesi",
    "##   .i ro linji pe le liste cu se sinxa pa liste cmima",
    "##   .i lo minde po'u `nim r tools/build.nim lists` cu ciska le vi datnyvei ra'i " &
    "`gismu.txt` pe",
    "##     `lojban-common` noi bakfu ne'i la'o gy. Debian .gy.",
    "##   .i lo sinxa namcu be `gismu.txt` cu du zoi ky. SHA-256 `" & digest[0 .. 31] & "`",
    "##     `" & digest[32 .. ^1] & "`; .ky.",
    "##   .i lo nu xance galfi le vi datnyvei cu na drani",
    "##   .i lo nu galfi le vi datnyvei cu nitcu lo nu rapli pilno le minde",
    "##   .i le liste cmima cu ralte le porsi pe le liste",
    "##   .i le liste cu porsi lo gismu jo'u lo cmavo poi ponse lo rafsi ku'o fi lo porsi be lo " &
    "lerfu",
  ]
  for line in NOTICE_GISMU: lines.add "##   " & line
  lines.add [
    "",
    "{.experimental: \"strictFuncs\".}",
    "",
    "import ../entries",
    "",
    "",
    "const LIST_GISMU* = [",
  ]
  for entry in entries:
    var rafsi: seq[string]
    for one in entry.rafsi: rafsi.add toLiteral(one)
    lines.add "  EntryGismu(word: " & toLiteral(entry.word) & ", rafsi: @[" & rafsi.join(", ") &
        "]),"
  lines.add "]"
  lines.add "  ## ro liste cmima pe le gismu liste ta'i le liste porsi"
  lines.join("\n") & "\n"


func toModuleCmavo*(entries: openArray[EntryCmavo], digest: string): string =
  ## ciska lo liste cmima pe le cmavo liste ta'i lo se ciska be fi le datnyvei poi se ralte
  ##   .i ro liste cmima cu zvati pa linji
  var lines = @[
    "## ralte le cmavo liste pe la'o gy. Logical Language Group .gy. ta'i lo liste cmima poi " &
    "ponse lo",
    "##   klesi",
    "##   .i ro cmavo pe le liste cu se sinxa pa liste cmima",
    "##   .i lo minde po'u `nim r tools/build.nim lists` cu ciska le vi datnyvei ra'i " &
    "`cmavo.txt` pe",
    "##     `lojban-common` noi bakfu ne'i la'o gy. Debian .gy.",
    "##   .i lo sinxa namcu be `cmavo.txt` cu du zoi ky. SHA-256 `" & digest[0 .. 31] & "`",
    "##     `" & digest[32 .. ^1] & "`; .ky.",
    "##   .i lo nu xance galfi le vi datnyvei cu na drani",
    "##   .i lo nu galfi le vi datnyvei cu nitcu lo nu rapli pilno le minde",
    "##   .i le liste cmima cu ralte le porsi pe le liste",
    "##   .i le liste cu porsi lo cmavo fi lo porsi be lo lerfu poi na du denpa bu",
  ]
  for line in NOTICE_CMAVO: lines.add "##   " & line
  lines.add [
    "",
    "{.experimental: \"strictFuncs\".}",
    "",
    "import ../[entries, selmaho]",
    "",
    "",
    "const LIST_CMAVO* = [",
  ]
  for entry in entries:
    lines.add "  EntryCmavo(word: " & toLiteral(entry.word) & ", selmaho: Selmaho." &
        symbolName(entry.selmaho) & "),"
  lines.add "]"
  lines.add "  ## ro cmavo poi lo linji pe le liste cu vasru ke'a po'o ku'o ta'i le liste porsi"
  lines.join("\n") & "\n"
