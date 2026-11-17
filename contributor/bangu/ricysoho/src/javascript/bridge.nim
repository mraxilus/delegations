## dunda le tcidu be lo selci'a `JavaScript` ta'i re fancu
##   .i `nim r tools/build.nim javascript` fanva le re fancu jo'u le mulno genturfa'i fi
##       `JavaScript` fu `build/ricysoho.js`
##   .i `parseLojban(text)` jarco lo selja'o be `readText` ta'i lo sapydai
##   .i `parseLojbanToNif(text)` jarco le tricu ta'i lo selci'a be fi `NIF`
##
## ni'o le dacti cu minra `ReadingText` pe `prose.nim` gi'e vasru ro datnypau be `ReadingText`
##   .i ro cmima be lo klesi pe `enum` cu selvau le dacti ta'i lo cmene be le cmima
##
## ni'o le dacti cu vasru `is_read`
##   .i va'o lo nu le selci'a cu se tcidu kei le dacti cu vasru `occurrences` .e `units` .e `tree`
##   .i va'o lo drata le dacti cu vasru `refusal` .e `start` .e `rule` .e `stream` noi `readStream`
##       jarco ke'a
##   .i se ki'u bo va'o lo nu le gerna cu to'e curmi kei lo pilno cu viska lo valsi poi lidne le nu
##       to'e curmi
##   .i va'o lo nu lo porsi be lo valsi cu se to'e curmi kei lo pilno cu viska le nu to'e curmi kei
##       .e lo tcila be le nu to'e curmi
##
## ni'o lo minra be `Occurrence` cu vasru `start` .e `finish` .e `text` .e `pause` .e `stress` .e
##     `breaks` .e `reading`
##   .i `stress` du `null` va'o lo nu le selci'a cu sinxa no nu basna
##
## ni'o lo minra be `Reading` cu vasru `is_word`
##   .i va'o lo nu le se tcidu cu valsi kei le minra cu vasru `kind` .e `selmaho`
##   .i va'o lo drata le minra cu vasru `refusal` .e `detail`
##   .i `selmaho` du `null` va'o lo nu le valsi cu ponse no selma'o
##
## ni'o lo minra be `Unit` cu vasru `words` .e `terminal`
##   .i lo minra be `Node` cu vasru `rule` .e `number` .e `children`
##   .i va'o lo nu le jgena cu genvla kei le minra cu vasru `at` po'o
##
## ni'o `parseLojbanToNif` jarco lo datnyvei poi `toNif` pe `nif.nim` ciska ke'a ku'o ta'i pa lerpoi
##     pe `JavaScript`
##   .i va'o lo nu le selci'a cu se to'e curmi kei `parseLojbanToNif` jarco `null`
##   .i ki'u bo lo nu to'e curmi cu vasru no tricu
##   .i `parseLojban` jarco lo krinu be le nu to'e curmi
##
## ni'o `start` .e `finish` kancu lo stuzi be le selci'a ne'i `UTF-8` ta'i lo nu le genturfa'i cu
##     tcidu le selci'a
##   .i va'o lo nu le selci'a cu vasru `ASCII` po'o kei lo namcu pe pa stuzi cu du lo stuna'u pe lo
##       lerpoi pe `JavaScript`
##
## ni'o le samtci cu zbasu ro le re fancu .e `parseLojbanLive` ta'i lo fancu poi ro da pe lo papri
##     poi cpacu le samtci cu ka'e pilno ke'a
##   .i `parseLojbanLive` tcidu lo jmive se ciska to `live_text.nim` toi
##   .i `node` na cpacu le samtci
##   .i `Architect` jdice di'u bu'u `#859`
##   .i se ki'u bo le samtci cu punji no da `module.exports` pe `CommonJS` zi'e noi no cipra cu ka'e
##       cipra ke'a
##
## ni'o se to'e cuxna fa pa selci'a be fi `JSON` be'o noi lo pilno cu raptcidu ke'a
##   .i lo sapydai cu zvati le samtci poi lo pilno cu zvati ke'a
##   .i se ki'u bo no datnytai cu selbe'i fi pa samtci fo pa drata samtci to `CONTRIBUTOR.md, Data`
##       toi
##   .i lo selci'a be fi `NIF` cu selbe'i ta'i lo selcru be le javni
##   .i lo flalu pe `test_nif.nim` cipra le selci'a
##
## ni'o jdima fa lo nu le nu tcidu cu fasnu ne'i le cilta pe lo pilno
##   .i se ki'u bo le papri cu denpa ca lo nu le genturfa'i cu tcidu
##   .i `PROVENANCE.md` jarco lo selmre poi karbi le selzba pe `JavaScript` le jbezba ku'o ne'i le
##       ckupaupau po'u lu le se zbasu pe `JavaScript` li'u

{.experimental: "strictFuncs".}
# lo cipra poi cpacu le cripu tezu'e lo fancu po'o poi le cripu cu zbasu ke'a ne'i le papri cu pilno
#     no fancu pe le cripu ne'i `Nim`
{.used.}

when compileOption("profiler"):
  import std/nimprof

import std/[jsffi, options]

import ../ricysoho  # le ralju datnyvei tezu'e `$` pe ro klesi mu'u `KOhA` pe `Selmaho`
# le tcidu be lo mivyselci'a be'o po'u `parseLojbanLive` tcidu ne'i lo gunka va'o lo nu le papri cu
#     dunda pa gunka
import ./live_text



proc toObject(reading: Reading): JsObject =
  ## minra lo se tcidu pe pa valsi
  ##   .i le minra cu vasru lo klesi .e bo lo selma'o .a lo nu to'e curmi .e bo lo tcila be le nu
  ##       to'e curmi
  result = newJsObject()
  result.is_word = reading.is_word
  if reading.is_word:
    result.kind = cstring($reading.kind)
    result.selmaho = (if reading.selmaho.isSome: cstring($reading.selmaho.get).toJs else: jsNull)
  else:
    result.refusal = cstring($reading.refusal)
    result.detail = cstring(reading.detail)


proc toObject(occurrence: Occurrence): JsObject =
  ## minra pa valsi pe lo porsi be lo valsi
  ##   .i le minra cu vasru lo stuzi .e lo lerfu .e lo denpa .e lo nu basna .e lo lerfu po'u slaka
  ##       bu ge'u .e lo se tcidu
  result = newJsObject()
  result.start = occurrence.start
  result.finish = occurrence.finish
  result.text = cstring(occurrence.text)
  result.pause = cstring($occurrence.pause)
  result.stress = (if occurrence.stress.isSome: occurrence.stress.get.toJs else: jsNull)
  result.breaks = occurrence.breaks
  result.reading = occurrence.reading.toObject


proc toObject(node: Node): JsObject =
  ## minra pa jgena pe le tricu
  ##   .i le minra cu vasru lo javni .e bo lo namcu pe le javni ge'u .e bo lo pazyjge .a lo stuna'u
  ##       pe lo genvla
  ##
  ## ni'o le fancu cu tcidu ro pazyjge sepi'o lo stuna'u
  ##   .i se ki'u bo le fancu cu zbasu no fukpi be lo pazyjge
  ##   .i ne'i lo fanva be fi `JavaScript` lo nu rapli sepi'o `items` cu zbasu lo fukpi be ro
  ##       pazyjge
  ##   .i lo fukpi be pa jgena cu vasru lo fukpi be le multricu poi le jgena cu genja ke'a
  ##   .i se ki'u bo va'o lo nu rapli sepi'o `items` kei ro jgena cu rapyzba lo fukpi be ro jgena
  ##       poi le jgena cu vasru ke'a
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
  ## minra lo se tcidu pe lo porsi be lo valsi
  ##   .i le minra cu vasru lo valsi pe le porsi ge'u .a lo nu to'e curmi .e bo lo stuzi be le nu
  ##       to'e curmi .e bo lo tcila be le nu to'e curmi
  result = newJsObject()
  result.is_read = reading.is_read
  if reading.is_read:
    result.occurrences = reading.occurrences.toObjects
    return
  result.refusal = cstring($reading.refusal)
  result.start = reading.start
  result.detail = cstring(reading.detail)


proc parseLojban*(text: cstring): JsObject {.exportc.} =
  ## tcidu le selci'a ta'i lo prosa gi'e jarco lo selja'o be `readText` ta'i lo sapydai
  ##
  ## ni'o le fancu cu korbi `Nim` `JavaScript`
  ##   .i `exportc` ralte le cmene po'u `parseLojban` ne'i le samtci
  ##   .i le selci'a cu klama ta'i lo lerpoi pe `JavaScript`
  ##   .i `$` jarco lo stuzi be le selci'a ne'i `UTF-8`
  ##   .i le genturfa'i cu tcidu le stuzi
  ##
  ## ni'o le dacti cu vasru lo lerpoi .e lo namcu .e lo jetnu ja jitfa .e lo porsi .e `null` .e no
  ##     drata
  ##   .i se ki'u bo lo pilno cu tcidu le dacti sepi'o no samtci pe `Nim`
  let
    source = $text
    reading = source.readText
  result = newJsObject()
  result.is_read = reading.is_read
  if reading.is_read:
    var units: seq[JsObject]
    # pilno lo stuna'u ki'u lo nu `items` zbasu lo fukpi be ro pagbu ne'i lo fanva be fi
    #     `JavaScript`
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
  ## tcidu le selci'a ta'i lo prosa gi'e jarco le tricu pe le selci'a ta'i lo datnyvei pe `NIF` ge'u
  ##     zi'e poi `toNif` ciska ke'a
  ##   .i va'o lo nu le selci'a cu se to'e curmi kei le fancu cu jarco `null`
  ##
  ## ni'o le fancu cu korbi `Nim` `JavaScript`
  ##   .i `exportc` ralte le cmene po'u `parseLojbanToNif` ne'i le samtci
  ##   .i le datnyvei cu selpau lo stuzi pe `UTF-8`
  ##   .i `cstring` dunda le stuzi lo pilno ta'i lo lerpoi pe `JavaScript`
  let reading = ($text).readText
  if not reading.is_read: return nil
  cstring(reading.toNif)
