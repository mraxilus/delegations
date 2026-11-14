## dunda le tcidu be lo se ciska la'o gy. JavaScript .gy. ta'i re fancu .i
##   `nim r tools/build.nim javascript` cu fanva le re fancu jo'u le mulno genturfa'i fi
##   la'o gy. JavaScript .gy. fu `build/lojban_parser.js` .i `parseLojban(text)` cu jarco lo se
##   jarco be `readText` ta'i lo sampu dacti .i `parseLojbanToNif(text)` cu jarco le tricu ta'i lo
##   se ciska be fi la'o gy. NIF .gy.
##   .i le dacti cu minra `ReadingText` pe `prose.nim` .i le dacti cu vasru ro datni pagbu be
##     `ReadingText` .i ro cmima be lo klesi pe la'o gy. enum .gy. cu se vasru le dacti ta'i lo
##     cmene be le cmima .i le dacti cu vasru `is_read` .i va'o lo nu le se ciska cu se tcidu kei
##     le dacti cu vasru ji'a `occurrences` .e `units` .e `tree` .i va'o lo drata le dacti cu vasru
##     ji'a `refusal` .e `start` .e `rule` .e `stream` noi `readStream` cu jarco ke'a .i se ki'u bo
##     va'o lo nu le gerna cu to'e curmi kei lo pilno cu viska lo valsi poi lidne le nu to'e curmi
##     .i va'o lo nu lo porsi be lo valsi cu se to'e curmi kei lo pilno cu viska le nu to'e curmi
##     kei .e lo tcila be le nu to'e curmi
##   .i lo minra be `Occurrence` cu vasru `start` .e `finish` .e `text` .e `pause` .e `stress` .e
##     `breaks` .e `reading` .i `stress` cu du `null` va'o lo nu le se ciska cu sinxa no nu basna
##     .i lo minra be `Reading` cu vasru `is_word` .i va'o lo nu le se tcidu cu valsi kei le minra
##     cu vasru ji'a `kind` .e `selmaho` .i va'o lo drata le minra cu vasru ji'a `refusal` .e
##     `detail` .i `selmaho` cu du `null` va'o lo nu le valsi cu ponse no selma'o .i lo minra be
##     `Unit` cu vasru `words` .e `terminal` .i lo minra be `Node` cu vasru `rule` .e `number` .e
##     `children` .i va'o lo nu le jgena cu gerna valsi kei le minra cu vasru `at` po'o
##   .i `parseLojbanToNif` cu jarco lo datnyvei poi `toNif` pe `nif.nim` cu ciska ke'a ku'o ta'i
##     pa lerpoi pe la'o gy. JavaScript .gy. .i va'o lo nu le se ciska cu se to'e curmi kei
##     `parseLojbanToNif` cu jarco `null` .i ki'u bo lo nu to'e curmi cu vasru no tricu .i
##     `parseLojban` cu jarco lo krinu be le nu to'e curmi
##   .i `start` .e `finish` cu kancu lo stuzi be le se ciska ne'i la'o gy. UTF-8 .gy. ta'i lo nu le
##     genturfa'i cu tcidu le se ciska .i va'o lo nu le se ciska cu vasru la'o gy. ASCII .gy. po'o
##     kei lo namcu pe pa stuzi cu du ji'a lo stuzi namcu pe lo lerpoi pe la'o gy. JavaScript .gy.
##   .i le samtci cu zbasu ro le re fancu .e `parseLojbanLive` ta'i lo fancu poi ro da pe lo papri
##     poi cpacu le samtci cu ka'e pilno ke'a .i `parseLojbanLive` cu tcidu lo jmive se ciska to
##     `live_text.nim` toi .i la'o gy. node .gy. na cpacu le samtci .i la'o gy. Architect .gy. cu
##     jdice di'u bu'u `#859` .i se ki'u bo le samtci cu punji no da `module.exports` pe
##     la'o gy. CommonJS .gy. zi'e noi no cipra cu ka'e cipra ke'a
##   .i se to'e cuxna fa pa se ciska be fi la'o gy. JSON .gy. be'o noi lo pilno cu rapli tcidu ke'a
##     .i lo sampu dacti cu zvati le samtci poi lo pilno cu zvati ke'a .i se ki'u bo no datni tarmi
##     cu se benji fi pa samtci fo pa drata samtci to `CONTRIBUTOR.md, Data` toi .i lo se ciska be
##     fi la'o gy. NIF .gy. cu se benji ta'i lo se curmi be le javni .i lo flalu pe `test_nif.nim`
##     cu cipra le se ciska
##   .i jdima fa lo nu le nu tcidu cu fasnu ne'i le cilta pe lo pilno .i se ki'u bo le papri cu
##     denpa ca lo nu le genturfa'i cu tcidu .i `PROVENANCE.md` cu jarco lo se merli poi karbi le se
##     zbasu pe la'o gy. JavaScript .gy. le jbena zbasu ku'o ne'i le ckupaupau po'u
##     la'o gy. JavaScript build .gy.

{.experimental: "strictFuncs".}
# lo cipra poi cpacu le cripu tezu'e lo fancu po'o poi le cripu cu zbasu ke'a ne'i le papri cu
# pilno no fancu pe le cripu ne'i la'o gy. Nim .gy.
{.used.}

when compileOption("profiler"):
  import std/nimprof

import std/[jsffi, options]

import ../lojban_parser  # le ralju datnyvei tezu'e `$` pe ro klesi mu'u `KOhA` pe `Selmaho`
# le tcidu be lo jmive se ciska be'o po'u `parseLojbanLive` cu tcidu ne'i lo gunka va'o lo nu le
# papri cu dunda pa gunka
import ./live_text



proc toObject(reading: Reading): JsObject =
  ## minra lo se tcidu pe pa valsi .i le minra cu vasru lo klesi .e bo lo selma'o .a lo nu to'e
  ##   curmi .e bo lo tcila be le nu to'e curmi
  result = newJsObject()
  result.is_word = reading.is_word
  if reading.is_word:
    result.kind = cstring($reading.kind)
    result.selmaho = (if reading.selmaho.isSome: cstring($reading.selmaho.get).toJs else: jsNull)
  else:
    result.refusal = cstring($reading.refusal)
    result.detail = cstring(reading.detail)


proc toObject(occurrence: Occurrence): JsObject =
  ## minra pa valsi pe lo porsi be lo valsi .i le minra cu vasru lo stuzi .e lo lerfu .e lo denpa
  ##   .e lo nu basna .e lo lerfu po'u slaka bu ge'u .e lo se tcidu
  result = newJsObject()
  result.start = occurrence.start
  result.finish = occurrence.finish
  result.text = cstring(occurrence.text)
  result.pause = cstring($occurrence.pause)
  result.stress = (if occurrence.stress.isSome: occurrence.stress.get.toJs else: jsNull)
  result.breaks = occurrence.breaks
  result.reading = occurrence.reading.toObject


proc toObject(node: Node): JsObject =
  ## minra pa jgena pe le tricu .i le minra cu vasru lo javni .e bo lo namcu pe le javni ge'u .e bo
  ##   lo panzi jgena .a lo stuzi namcu pe lo gerna valsi
  ##   .i le fancu cu tcidu ro panzi jgena sepi'o lo stuzi namcu .i se ki'u bo le fancu cu zbasu no
  ##     fukpi be lo panzi jgena .i ne'i lo fanva be fi la'o gy. JavaScript .gy. lo nu rapli sepi'o
  ##     `items` cu zbasu lo fukpi be ro panzi jgena .i lo fukpi be pa jgena cu vasru lo fukpi be le
  ##     mulno tricu poi le jgena cu genja ke'a .i se ki'u bo va'o lo nu rapli sepi'o `items` kei ro
  ##     jgena cu rapli zbasu lo fukpi be ro jgena poi le jgena cu vasru ke'a
  result = newJsObject()
  if node.is_terminal:
    result.at = node.at
    return
  var children: seq[JsObject]
  for index in 0..<node.children.len: children.add node.children[index].toObject
  result.rule = cstring(node.rule)
  result.number = node.number
  result.children = children


proc toObjects(occurrences: seq[Occurrence]): seq[JsObject] =
  ## minra ro valsi pe lo porsi be lo valsi ta'i le porsi
  for occurrence in occurrences: result.add occurrence.toObject


proc toObject(reading: ReadingStream): JsObject =
  ## minra lo se tcidu pe lo porsi be lo valsi .i le minra cu vasru lo valsi pe le porsi ge'u .a lo
  ##   nu to'e curmi .e bo lo stuzi be le nu to'e curmi .e bo lo tcila be le nu to'e curmi
  result = newJsObject()
  result.is_read = reading.is_read
  if reading.is_read:
    result.occurrences = reading.occurrences.toObjects
    return
  result.refusal = cstring($reading.refusal)
  result.start = reading.start
  result.detail = cstring(reading.detail)


proc parseLojban*(text: cstring): JsObject {.exportc.} =
  ## tcidu le se ciska ta'i lo prosa gi'e jarco lo se jarco be `readText` ta'i lo sampu dacti
  ##   .i le fancu cu korbi la'o gy. Nim .gy. la'o gy. JavaScript .gy. .i `exportc` cu ralte le
  ##     cmene po'u `parseLojban` ne'i le samtci .i le se ciska cu klama ta'i lo lerpoi pe
  ##     la'o gy. JavaScript .gy. .i `$` cu jarco lo stuzi be le se ciska ne'i la'o gy. UTF-8 .gy.
  ##     .i le genturfa'i cu tcidu le stuzi .i le dacti cu vasru lo lerpoi .e lo namcu .e lo jetnu
  ##     ja jitfa .e lo porsi .e `null` .i le dacti cu vasru no drata .i se ki'u bo lo pilno cu
  ##     tcidu le dacti sepi'o no samtci pe la'o gy. Nim .gy.
  let
    source = $text
    reading = source.readText
  result = newJsObject()
  result.is_read = reading.is_read
  if reading.is_read:
    var units: seq[JsObject]
    # pilno lo stuzi namcu ki'u lo nu `items` cu zbasu lo fukpi be ro pagbu ne'i lo fanva be fi
    # la'o gy. JavaScript .gy.
    for index in 0..<reading.units.len:
      let mirrored = newJsObject()
      mirrored.words = reading.units[index].words
      mirrored.terminal = cstring($reading.units[index].terminal)
      units.add mirrored
    result.occurrences = reading.occurrences.toObjects
    result.units = units
    result.tree = reading.tree.toObject
    return
  result.refusal = cstring($reading.refusal)
  result.start = reading.start
  result.rule = cstring(reading.rule)
  result.stream = source.readStream.toObject


proc parseLojbanToNif*(text: cstring): cstring {.exportc.} =
  ## tcidu le se ciska ta'i lo prosa gi'e jarco le tricu pe le se ciska ta'i lo datnyvei pe
  ##   la'o gy. NIF .gy. ge'u zi'e poi `toNif` cu ciska ke'a .i va'o lo nu le se ciska cu se to'e
  ##   curmi kei le fancu cu jarco `null`
  ##   .i le fancu cu korbi la'o gy. Nim .gy. la'o gy. JavaScript .gy. .i `exportc` cu ralte le
  ##     cmene po'u `parseLojbanToNif` ne'i le samtci .i le datnyvei cu se pagbu lo stuzi pe
  ##     la'o gy. UTF-8 .gy. .i `cstring` cu dunda le stuzi lo pilno ta'i lo lerpoi pe
  ##     la'o gy. JavaScript .gy.
  let reading = ($text).readText
  if not reading.is_read: return nil
  cstring(reading.toNif)
