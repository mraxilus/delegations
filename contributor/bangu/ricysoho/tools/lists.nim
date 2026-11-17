## galfi le gimste .e le ma'oste vu'o pe `Logical Language Group` lo samtci datnyvei pe `Nim` zi'e
##     poi ponse lo klesi gi'e selra'e le vi selgu'a
##   .i ji'a stosni le jvoste noi lo cipra cu tcidu ke'a ta'i lo datselci'a
##   .i tcidu `gismu.txt` .e `cmavo.txt` ta'i lo nu `lojban-common` noi bakfu ne'i `Debian` punji le
##       re datnyvei
##   .i ciska `src/ricysoho/lists/gismu.nim` .e `cmavo.nim`
##   .i `build.nim` pilno le vi datnyvei
##
## ni'o le galfi samtci pe `rictadni/tools/lists.nim` cpacu `Source` .e `readSource` .e
##     `KEY_LISTS` .e `DIRECTORY_LISTS` .e `DIGEST_GISMU` .e `DIGEST_LUJVO` le vi datnyvei
##   .i se ki'u bo ro le xa selcpa cu selpli su'o samtci poi na pagbu le genturfa'i
##   .i ji'a ro stosni cu selci'a pa roi gi'e selpli le re selgu'a
##   .i le galfi samtci cu ponse pa sivyfancu po'u `field` noi fukpi `field` pe le vi datnyvei to
##       `Article II.9` toi
##   .i lo nu cikre pa le re fancu cu na mulno pu lo nu le datfancu cu se cipra
##
## ni'o lo stuzi pe `gismu.txt` ge'u .e lo stuzi pe `cmavo.txt` stodi
##   .i `entries.nim` ciska le stuzi ne'i lo lijgri liste
##   .i ro kuspe pe le vi datnyvei cu selmre ne'i ro linji pe ro le re datnyvei
##   .i le nu merli cu jarco lo du'u ro linji cu vasru no lerfu poi zvati lo jbini be re datnypau
##
## ni'o le samtci datnyvei cu ralte ro datnypau poi lo javni cu nitcu ke'a ku'o gi'e ralte no drata
##     datni pagbu to `entries.nim` toi
##   .i se ki'u bo ro stecmi cu selci'a fi pa linji poi tceto'u gi'e vasru me'i panono stuzi
##   .i no datnypau cu nitcu lo nu se fendi fi su'o re linji
##
## ni'o le ma'oste cu ralte ro linji poi vasru pa cmavo po'o
##   .i ro linji poi lo selma'o pe ke'a se tcita `*` selvi'u gi'e vasru pa ma'orgunma .a pa jufpau
##   .i le galfi samtci cu tcidu lo cmene be lo selma'o
##   .i le cmene cu lidne lo klesi poi le liste cu ciska ke'a
##   .i va'o lo nu `CLL 20` na dunda le cmene kei le galfi samtci cu fliba gi'e cusku le linji
##
## ni'o no samtci datnyvei cu selzba fi `lujvo.txt`
##   .i ki'u bo le jvoste cu dunda lo smuni gi'e no roi dunda lo ka drani
##   .i se ki'u bo le jvoste cu stali `rictadni`
##
## ni'o lo cipra cu tcidu le datnyvei poi selpu'i ku'o ta'i lo datselci'a
##   .i le vi datnyvei cu stosni le datnyvei sepi'o lo snina'u
##   .i va'o lo nu le datnyvei cu na zvati gi'a cenba kei lo cipra cu na zukte to `Article IX.9` toi
##
## ni'o le vi datnyvei cu stosni ro krasi sepi'o `SHA-256`
##   .i lo nu `Debian` galfi pa liste cu rinka lo nu lo minde po'u `lists` to'e curmi kei .e lo nu
##       lo minde po'u `head` cusku le nu galfi
##   .i le nu galfi cu no roi rinka lo nu smaji ke rapci'a le selra'este kei .a lo nu smatcidu lo
##       datselci'a
##
## ni'o lo nu ciska lo samtci datnyvei cu ro roi dunda lo mitselci'a ra'i lo mitkra
##   .i se ki'u bo lo minde po'u `head` karbi ro stuzi be lo selci'a le mitstu be le selra'e
##
## ni'o jdima fa lo nu le vi datnyvei cu pilno `sha256sum` mu'i lo nu tcidu lo snina'u
##   .i lo minde po'u `system` cusku `sha256sum`
##   .i lo fadni samtci pe `Nim` na vasru `SHA-256`

{.experimental: "strictFuncs".}

import std/[enumutils, options, os, osproc, strutils]

import ../src/ricysoho/[entries, selmaho]


type
  Source* = object
    ## pa liste datnyvei poi se tcidu
    ##   .i le klesi cu vasru lo stuzi be le datnyvei be'o .e lo snina'u be le stuzi
    text*: string
      ## lo selvau be le datnyvei
      ##   .i ro lerfu po'u `carriage return` selvi'u
    digest*: string
      ## `SHA-256` pe lo stuzi poi selpu'i
      ##   .i le snina'u cu selci'a ta'i `hex` sepi'o lo cmale'u


const
  KEY_LISTS* = "RICYSOHO_LISTS"
    ## lo cmene be lo vabycne poi basti lo datnyveiste poi le liste cu se tcidu fi ke'a
  DIRECTORY_LISTS* = "/usr/share/lojban"
    ## lo datnyveiste poi `lojban-common` noi bakfu cu punji le liste ke'a
  DIGEST_GISMU* = "f2fc4cff4f265ad02717d56733b4627ffa78c616db78dcaa44caab694e1dd5b7"
    ## `SHA-256` pe `gismu.txt` pe `1.5+dfsg.1-4` pe `lojban-common`
    ##   .i lo stedu be le datnyvei cu cusku lo detri po'u zoi gy. 9/26/94 .gy.
  DIGEST_LUJVO* = "23c182f3534f4e33efbb4a3d92cd943427d5a6fdf3b061b07cd6bbc3d0e6b0cc"
    ## `SHA-256` pe `lujvo.txt` pe `1.5+dfsg.1-4` pe `lojban-common`
    ##   .i lo cipra cu tcidu le datnyvei ta'i lo datselci'a
  DIGEST_CMAVO* = "544414d61f3ff35dd2cf4e4f79f3c86bf9bb0568eb3403f57288057e16796402"
    ## `SHA-256` pe `cmavo.txt` pe `1.5+dfsg.1-4` pe `lojban-common`
    ##   .i lo stedu be le datnyvei cu cusku lo detri po'u zoi gy. 26 August 2002 .gy.
    ##   .i lo cipra cu tcidu le datnyvei ta'i lo datselci'a
  PATH_GISMU* = "src/ricysoho/lists/gismu.nim"
    ## lo datnyvei poi le gimste cu selci'a fi ke'a
  PATH_CMAVO* = "src/ricysoho/lists/cmavo.nim"
    ## lo datnyvei poi le ma'oste cu selci'a fi ke'a
  NOTICE_GISMU = [
    ".i le vi datnyvei cu selzba fi lo datni poi `Logical Language Group` rinka lo nu ke'a zifre " &
    "fi",
    "    ro da",
    ".i le girzu cu cpedu lo nu lo selzba be fi le datni cu cusku lo tadji be lo nu zbasu",
    ".i le vi pinka cu cusku le tadji",
    ".i le minde cu ralte lo stuzi be lo valsi jo'u lo rafsi pe `entries.nim` gi'e vimcu ro datstu",
    ".i le minde cu vimcu ji'a ro lerfu po'u `carriage return` ge'u .e ro kutle'u poi zvati lo " &
    "fanmo",
    "    be lo datnypau",
    ".i lo zmadatni be la lojban. cu zvati",
    "    `Logical Language Group, Inc., 2904 Beau Lane, Fairfax VA 22031 USA` .e",
    "    `https://www.lojban.org/`",
  ]
    ## lo linji poi le datnyvei pe le gimste cu vasru ke'a ja'i lo selcpe be le notci be lo du'u le
    ##     datni cu zifre fi ro da
  NOTICE_CMAVO = [
    ".i le vi datnyvei cu selzba fi lo datni poi `Logical Language Group` rinka lo nu ke'a zifre " &
    "fi",
    "    ro da",
    ".i le girzu cu cpedu lo nu lo selzba be fi le datni cu cusku lo tadji be lo nu zbasu",
    ".i le vi pinka cu cusku le tadji",
    ".i le minde cu ralte lo linji poi vasru pa cmavo po'o ku'o gi'e ralte lo stuzi be lo valsi " &
    "jo'u",
    "    lo selma'o pe `entries.nim` gi'e vimcu ro datstu",
    ".i le minde cu vimcu ji'a lo lerfu po'u denpa bu ge'u .e lo klesi be lo selma'o be'o .e ro",
    "    lerfu po'u `carriage return` ge'u .e ro kutle'u poi zvati lo fanmo be lo datnypau",
    ".i lo zmadatni be la lojban. cu zvati",
    "    `Logical Language Group, Inc., 2904 Beau Lane, Fairfax VA 22031 USA` .e",
    "    `https://www.lojban.org/`",
  ]
    ## lo linji poi le datnyvei pe le ma'oste cu vasru ke'a ja'i le mitselcpe



#[ ni'o ni'o ni'o lo nu tcidu ]#

proc readSource*(name: string): Source =
  ## tcidu lo liste datnyvei poi selcme `name` ku'o fi lo datnyveiste poi lo vanbi cu cusku lo cmene
  ##     be ke'a
  ##   .i va'o lo drata ku tcidu le liste datnyvei fi lo datnyveiste pe le bakfu
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
  ##   .i lo kutle'u poi zvati lo fanmo be le se tcidu cu selvi'u
  if line.len < first: return ""
  line[first - 1 .. min(last, line.len) - 1].strip


func toEntriesGismu*(text: string): seq[EntryGismu] =
  ## tcidu ro stecmi pe `gismu.txt`
  ##   .i le sedli'i cu na se tcidu
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
  ##   .i le sedli'i cu na se tcidu
  for line in text.splitLines[1 .. ^1]:
    if line.strip.len == 0: continue
    let column = line.field(12, 20)
    # lo ma'orgunma .a lo jufpau
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
  ## ciska lo selci'a ta'i pa se sitna lerpoi pe `Nim`
  ##   .i lo valsi .e lo rafsi cu vasru lo jbole'u jo'u lo lerfu po'u zoi gy. ' .gy. gi'e vasru no
  ##       datle'u
  "\"" & text & "\""


func toModuleGismu*(entries: openArray[EntryGismu], digest: string): string =
  ## ciska lo stecmi pe le gimste ta'i lo selci'a be fi le datnyvei poi selra'e
  ##   .i ro stecmi cu zvati pa linji
  var lines = @[
    "## ralte le gimste pe `Logical Language Group` ta'i lo stecmi poi ponse lo klesi",
    "##   .i ro linji pe le liste cu selsni pa stecmi",
    "##   .i lo minde po'u `nim r tools/build.nim lists` ciska le vi datnyvei ra'i `gismu.txt` pe",
    "##       `lojban-common` noi bakfu ne'i `Debian`",
    "##   .i lo snina'u be `gismu.txt` cu du zoi ky. SHA-256 `" & digest[0 .. 31] & "`",
    "##       `" & digest[32 .. ^1] & "`; .ky.",
    "##   .i lo nu xanga'i le vi datnyvei cu na drani",
    "##   .i lo nu galfi le vi datnyvei cu nitcu lo nu rapypli le minde",
    "##   .i le stecmi cu ralte le porsi pe le liste",
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
  lines.add "  ## ro stecmi pe le gimste ta'i le stepoi"
  lines.join("\n") & "\n"


func toModuleCmavo*(entries: openArray[EntryCmavo], digest: string): string =
  ## ciska lo stecmi pe le ma'oste ta'i lo selci'a be fi le datnyvei poi selra'e
  ##   .i ro stecmi cu zvati pa linji
  var lines = @[
    "## ralte le ma'oste pe `Logical Language Group` ta'i lo stecmi poi ponse lo klesi",
    "##   .i ro cmavo pe le liste cu selsni pa stecmi",
    "##   .i lo minde po'u `nim r tools/build.nim lists` ciska le vi datnyvei ra'i `cmavo.txt` pe",
    "##       `lojban-common` noi bakfu ne'i `Debian`",
    "##   .i lo snina'u be `cmavo.txt` cu du zoi ky. SHA-256 `" & digest[0 .. 31] & "`",
    "##       `" & digest[32 .. ^1] & "`; .ky.",
    "##   .i lo nu xanga'i le vi datnyvei cu na drani",
    "##   .i lo nu galfi le vi datnyvei cu nitcu lo nu rapypli le minde",
    "##   .i le stecmi cu ralte le porsi pe le liste",
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
  lines.add "  ## ro cmavo poi lo linji pe le liste cu vasru ke'a po'o ku'o ta'i le stepoi"
  lines.join("\n") & "\n"
