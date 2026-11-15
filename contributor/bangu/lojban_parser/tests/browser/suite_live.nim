## cipra lo du'u lo tcidu be lo mivyselci'a be'o pe le samtci to `src/javascript/live_text.nim` toi
##     cu mintu le jbezba ne'i `headless Chromium` noi lo minde po'u `drive` rinka lo nu ke'a cfari
##     to `tools/drive.nim` toi
##   .i le cipra cu fasnu ne'i pa papri poi cpacu le cipra sepi'o lo judri be le cipra ta'i lo nu lo
##       papri pe lo viska cu cpacu le samtci to lo seljdi bu'u `#859` toi
##   .i le cipra cu vasru le cripu ta'i le cipra pe le samtci
##   .i ki'u bo ro samtci poi `Nim` fanva ke'a punji ro fancu pe vo'a lo stuzi poi ro da ka'e pilno
##       ke'a
##   .i se ki'u bo pa remoi samtci ne'i pa papri cu basti ro fancu pe le pamoi ge'u zi'e poi ke'a .e
##       pa fancu pe le remoi cu selcme pa cmene
##   .i se ki'u bo va'o lo nu pa sepcipra cu zvati lo mlana be le samtci kei le cipra cu tcidu lo
##       spofu samtci
##   .i le gunka cu selkra le cipra ta'i lo nu selkra le samtci
##   .i le cipra cu fasnu ne'i lo papri poi vasru `document`
##   .i le cipra cu na fasnu ne'i le gunka
##   .i ro selci'a poi le sabji samtci cu sabji ke'a se tcidu ta'i lo nu ro valsi cu sepli kei ne'i
##       pa gunka .e lo cilta pe le papri
##   .i le cenba cu katna lo lerpoi pe `JavaScript` bu'u `at` gi'e jmina fi le lerpoi
##   .i ca lo fanmo le lerpoi cu mintu le selci'a be fi `NIF` be'o poi le jbezba cu dunda ke'a le se
##       ciska to `readTextParts` toi ro stuzi
##   .i `nif` dunda le ca selci'a be fi `NIF` be'o poi mintu lo jalge be le cenba
##   .i le gunka cu tcidu ro selci'a
##   .i lo cilta pe le papri cu tcidu no pagbu be le selci'a
##   .i se ki'u bo le papri cu denpa no roi le tcidu
##   .i lo cilta pe le papri cu tcidu pa jufra ca ro nu `event loop` carna to `toSentences` toi
##   .i le papri cu gasnu pa selgu'a pe vo'a ca lo jbini be re jufra pe pa pagbu
##   .i ki'u bo ro nu carna cu fasnu sepi'o pa notci pe `MessageChannel`
##   .i `event loop` cpacu le notci ta'i le porsi be lo nu benji
##   .i lo stuzi be lo cenba cu kancu lo pagbu pe `UTF-16`
##   .i lo selci'a poi zo zoi sitna ke'a gi'e vasru pa lerfu poi zmadu `U+FFFF` zi'e noi re pagbu cu
##       ciska ke'a se tcidu fi le selci'a be fi `NIF` be'o poi le jbezba cu dunda ke'a
##   .i se ki'u bo `slice` katna bu'u lo stuzi poi le cenba cu cfari bu'u ke'a
##   .i va'o lo nu lo javni pe lo selvau be le papri cu to'e curmi ro gunka kei lo cilta pe le papri
##       cu basti le gunka poi le tcidu cu cpedu ke'a
##   .i le cilta cu tcidu ro selci'a fi le selci'a be fi `NIF` be'o poi le jbezba cu dunda ke'a
##   .i le cipra pe lo nupre cu cusku ro cipra ta'i lo nu `unittest` ciska to `report.nim` toi
##   .i ki'u bo `unittest` denpa no nupre
##   .i ba bo le cipra cu cusku lo famna'u pe le nu cipra

{.experimental: "strictFuncs".}

import std/[asyncjs, jsffi, strutils, unicode]

import ../../src/javascript/[bridge, live_text]
import ../../src/lojban_parser/[live, nif]
import ./report


const
  PATH_COUNT = "/drive/live/count.text"
    ## lo du'u le sabji samtci cu sabji xo kau selci'a le cipra
  PIECE_MIDDLE = 7
    ## lo pagbu poi le cipra cu cpedu le ca selci'a be fi `NIF` be'o le tcidu ba ke'a ku'o ne'i ro
    ##     selci'a poi vasru le pagbu
  COUNT_TEXTS_LEAST = 5  ## lo du'u le sabji samtci cu sabji su'o xo kau selci'a
  TEXT_TURNS = "mi klama .i do cadzu .i ko sipna "
    ## pa pagbu poi vasru ci jufra
    ##   .i lo cilta pe le papri cu tcidu le pagbu ca ci nu carna
    ##   .i le pagbu cu selfi'i
  COUNT_TURNS = 3
    ## lo du'u `TEXT_TURNS` vasru xo kau jufra
    ##   .i ro jufra cu se tcidu ca pa drata nu carna
  MODE_REFUSED = "refused"
    ## lo tadji be lo papri poi lo javni pe lo selvau be ke'a cu to'e curmi ro gunka
    ##   .i `data-mode` pe `body` jarco le tadji


proc pushed(reader: JsObject, piece: cstring): Future[JsObject] {.importjs: "#.push(#)".}
  ## dunda pa nupre be lo cenba poi le pagbu cu rinka ke'a
  ##   .i korbi `JS` sepi'o lo fancu pe lo tcidu pe le samtci
proc finished(reader: JsObject): Future[JsObject] {.importjs: "#.finish()".}
  ## dunda pa nupre be lo cenba poi le fanmo cu rinka ke'a
  ##   .i korbi `JS` sepi'o lo fancu pe lo tcidu pe le samtci
proc asked(reader: JsObject): Future[cstring] {.importjs: "#.nif()".}
  ## dunda pa nupre be le ca selci'a be fi `NIF`
  ##   .i korbi `JS` sepi'o lo fancu pe lo tcidu pe le samtci
proc applied(held: cstring, at: int, text: cstring): cstring {.importjs: "(#.slice(0, #) + #)".}
  ## katna lo selci'a be fi `NIF` be'o poi selra'e bu'u lo stuzi poi kancu lo pagbu pe `UTF-16`
  ##   .i ba bo jmina `text` ta'i lo papri pe lo viska
proc typeOfGlobal(name: cstring): cstring {.importjs: "(typeof globalThis[#])".}
  ## dunda lo du'u lo selcme be `name` cu cmima ma kau klesi ne'i lo stuzi pe le papri ge'u zi'e poi
  ##     ro da ka'e pilno ke'a
  ##   .i korbi `JS`
proc newChannel(): JsObject {.importjs: "new MessageChannel()".}
  ## zbasu pa tavlu'a poi ponse re vorme
  ##   .i lo notci pe le pluta cu du pa selgu'a pe le papri
  ##   .i korbi `JS`


let DOCUMENT {.nodecl, importc: "document".}: JsObject
  ## `document` pe le papri
  ##   .i no da ne'i lo gunka


type ReadingLive = object  ## lo jalge be lo nu tcidu ta'i lo mivyselci'a ne'i le samtci
  nif: string
    ## lo selci'a be fi `NIF` be'o poi jalge le cenba ca le fanmo
    ##   .i le selci'a cu selka'a gi'e se jmina ta'i pa lerpoi pe `JavaScript`
  is_asked: bool
    ## le ca selci'a be fi `NIF` be'o poi le tcidu cu dunda ke'a ca lo midju be le selci'a cu du lo
    ##     selra'e poi le rebla pe le cenba cu se jmina fi ke'a
  turns: int
    ## lo du'u lo cilta pe le papri cu pilno xo kau nu carna lo nu tcidu le selci'a ta'i lo nu
    ##     `toSentences` katna ro pagbu



proc piecesWords(text: string): seq[string] =
  ## katna le selci'a pu ro valsi
  ##   .i ro pagbu cu vasru pa selci'avla .e lo calyle'u poi se lidne le valsi
  var first = 0
  for k in 0 ..< text.len:
    if text[k] == ' ':
      result.add text[first .. k]
      first = k + 1
  if first < text.len: result.add text[first .. ^1]


proc readTexts(): seq[tuple[text, nif: string]] =
  ## tcidu ro selci'a poi le sabji samtci cu sabji ke'a
  ##   .i tcidu ji'a lo selci'a be fi `NIF` be'o poi le jbezba cu dunda ke'a le selci'a
  for k in 0 ..< readServed(PATH_COUNT).strip.parseInt:
    let path = "/drive/live/" & $k
    result.add (readServed(path & ".text"), readServed(path & ".nif"))


proc readLive(reader: JsObject, text: string): Future[ReadingLive] {.async.} =
  ## tcidu le selci'a ta'i lo nu ro valsi cu sepli kei sepi'o lo tcidu pe le samtci gi'e ralte le
  ##     selci'a be fi `NIF` be'o poi jalge le cenba pe le tcidu
  var
    held = cstring(HEADER)
    reading = ReadingLive(is_asked: true)
  let pieces = text.piecesWords
  for k in 0 ..< pieces.len:
    let change = await reader.pushed(cstring(pieces[k]))
    held = held.applied(change.at.to(int), change.text.to(cstring))
    reading.turns += pieces[k].toSentences.len
    if k == PIECE_MIDDLE:
      let asked = $(await reader.asked)
      reading.is_asked = asked == $held & $change.tail.to(cstring)
      inc reading.turns  # lo nu cpedu le ca selci'a cu pilno pa drata nu carna
  let change = await reader.finished
  held = held.applied(change.at.to(int), change.text.to(cstring))
  reading.nif = $held
  inc reading.turns  # lo nu sisti cu pilno pa drata nu carna
  reading.is_asked = reading.is_asked and $(await reader.asked) == reading.nif
  inc reading.turns
  result = reading



proc runSuite() {.async.} =
  ## pilno ro cipra pe le cipra ta'i le porsi gi'e cusku ro le cipra
  ##   .i ba bo cusku lo famna'u pe le nu cipra
  ##   .i lo papri poi lo javni pe lo selvau be ke'a cu to'e curmi ro gunka cu pilno le cipra pe le
  ##       papri po'o
  report "[Suite] Internal: Live text of script" &
    (if DOCUMENT.body.dataset.mode.to(cstring) == MODE_REFUSED: ", worker refused" else: "")
  let texts = readTexts()
  var failures = countFailures()

  template ended(name: string) =
    ## cusku le cipra ta'i lo nu `unittest` ciska
    ##   .i le cipra cu fliba va'o lo nu pa xusra cu fliba ba le romoi cipra
    report "  [" & (if countFailures() > failures: "FAILED" else: "OK") & "] " & name
    failures = countFailures()

  if DOCUMENT.body.dataset.mode.to(cstring) == MODE_REFUSED:
    for (text, native) in texts:
      let
        # le papri cu to'e curmi le gunka
        reader = parseLojbanLive(jsUndefined)  # cpedu pa gunka
        live = await reader.readLive(text)
      expectThat not reader.isWorker().to(bool), "thread of page reads: " & text  # basti le gunka
      expectThat live.nif == native, "NIF native build gives: " & text  # `live.nim` to lo flalu toi
      expectThat live.is_asked, "NIF so far is NIF held and tail: " & text  # `D1 c` pe `#859`
    ended "Worker page refuses gives way to thread of page, which reads each text to native NIF"
    reportEnd(if countFailures() > 0: 1 else: 0)
    return

  for name in ["parseLojban", "parseLojbanToNif", "parseLojbanLive"]:
    expectThat typeOfGlobal(cstring(name)) == "function", name & " is global of page"  # le cripu
  ended "Script defines its three functions as globals of page that loads it"

  expectThat texts.len >= COUNT_TEXTS_LEAST, "backend serves " & $COUNT_TEXTS_LEAST & " texts"
  # su'o selci'a cu vasru pa lerfu poi zmadu `U+FFFF` zi'e noi re pagbu pe `UTF-16` ciska ke'a
  var is_wide = false
  for (text, native) in texts:
    for rune in text.runes: is_wide = is_wide or int32(rune) > 0xFFFF
    let
      reader = parseLojbanLive(jsUndefined)
      live = await reader.readLive(text)
    expectThat reader.isWorker().to(bool), "worker reads: " & text  # seljdi bu'u `#859`
    expectThat live.nif == native, "NIF native build gives: " & text  # `live.nim` to lo flalu toi
    expectThat live.is_asked, "NIF so far is NIF held and tail: " & text  # `D1 c` pe `#859`
    expectThat reader.countRead().to(int) == 0, "page reads none: " & text  # seljdi bu'u `#859`
  ended "Worker reads each text to NIF native build gives, and thread of page reads none"

  for (text, native) in texts:
    let options = newJsObject()
    options.worker = false
    let
      reader = parseLojbanLive(options)
      live = await reader.readLive(text)
    expectThat not reader.isWorker().to(bool), "thread of page reads: " & text
    expectThat live.nif == native, "NIF native build gives: " & text  # `live.nim` to lo flalu toi
    expectThat live.is_asked, "NIF so far is NIF held and tail: " & text  # `D1 c` pe `#859`
    # seljdi bu'u `#859`
    expectThat reader.countTurns().to(int) == live.turns,  # `toSentences`
      "turn for each sentence, end and ask: " & text
  ended "Thread of page reads each text, one sentence at each turn, to NIF native build gives"

  block:
    let options = newJsObject()
    options.worker = false
    let
      reader = parseLojbanLive(options)
      reading = reader.pushed(cstring(TEXT_TURNS))
      channel = newChannel()
    var is_run = false
    channel.port1.onmessage = proc(event: JsObject) = is_run = true
    # pa selgu'a pe le papri
    #   .i le selgu'a cu selbe'i ba le pamoi nu carna pe le tcidu
    channel.port2.postMessage(0)
    discard await reading
    expectThat is_run, "task of page runs before piece of three sentences is read"  # lo seljdi
    expectThat reader.countTurns().to(int) == COUNT_TURNS, "turn for each sentence"
  ended "Page runs task of its own between two sentences that thread of page reads"

  # lo bandu cu ralte lo selci'a poi vasru lo ganle'u
  expectThat is_wide, "some text holds rune past U+FFFF"  # `IX.3`
  ended "Offset of change counts units of UTF-16, so slice cuts NIF where change opens"

  reportEnd(if countFailures() > 0: 1 else: 0)


# le cipra cu fasnu ne'i le papri
#   .i le gunka noi selkra le vi samtci cu spuda le papri po'o to `live_text.nim` toi
if DOCUMENT.jsTypeOf != "undefined":
  initReporter()
  discard runSuite()
