## Expose reader of prose to JavaScript as one function, `parseLojban(text)`, which gives what
##   `readText` gives as plain object; `nim r tools/build.nim js` compiles it, with whole parser,
##   into `build/lojban_parser.js`.
##   Object mirrors `ReadingText` of `prose.nim`, field for field, each enum as its name:
##     `is_read`; then `occurrences`, `units` and `tree` where text reads, else `refusal`, `start`
##     and `rule`, with `stream`, what `readStream` gives, so caller sees words before refusal, or
##     refusal of stream with its detail.
##   Occurrence holds `start`, `text`, `pause`, `stress` (null where none), `breaks` and
##     `reading`. Reading holds `is_word`, then `kind` and `selmaho` (null where none), else
##     `refusal` and `detail`. Unit holds `words` and `terminal`. Node holds `rule`, `number` and
##     `children`, or `at` alone for terminal.
##   `start` counts bytes of text in UTF-8, as parser reads it; for text of ASCII alone, byte is
##     index of JavaScript string too.
##   Script defines `parseLojban` as global, and puts it on `module.exports` where loader of
##     CommonJS gives one, so browser and node load one file.
##   Rejected: text of JSON, which caller would parse. Plain object is value caller's own runtime
##     holds, so no format of data crosses between programs (CONTRIBUTOR.md, Data).
##   Cost: reading runs on thread of caller, so page waits while it reads; PROVENANCE.md,
##     JavaScript build, gives figures measured against native build.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[jsffi, options]

import ../lojban_parser  # umbrella, for `$` of each type, as `KOhA` of `Selmaho`


let MODULE_NODE {.importc: "module", nodecl.}: JsObject
  ## Read module object node gives each script of CommonJS it loads; browser gives none.
  ##   Boundary of JS target: `typeof` reads it, since bare name of undeclared global throws in
  ##     browser.



proc toObject(reading: Reading): JsObject =
  ## Mirror reading of one word: class and selma'o, or refusal and its detail.
  result = newJsObject()
  result.is_word = reading.is_word
  if reading.is_word:
    result.kind = cstring($reading.kind)
    result.selmaho = (if reading.selmaho.isSome: toJs(cstring($reading.selmaho.get)) else: jsNull)
  else:
    result.refusal = cstring($reading.refusal)
    result.detail = cstring(reading.detail)


proc toObject(occurrence: Occurrence): JsObject =
  ## Mirror one word of stream: place, letters, pause, stress, commas and reading.
  result = newJsObject()
  result.start = occurrence.start
  result.text = cstring(occurrence.text)
  result.pause = cstring($occurrence.pause)
  result.stress = (if occurrence.stress.isSome: toJs(occurrence.stress.get) else: jsNull)
  result.breaks = occurrence.breaks
  result.reading = occurrence.reading.toObject


proc toObject(node: Node): JsObject =
  ## Mirror node of tree: rule, its number and nodes under it, or index of terminal.
  ##   Index reads each child in place; loop over `items` copies whole subtree of each on JS
  ##     backend, so each level would copy all below it again.
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
  ## Mirror each word of stream, in order.
  for occurrence in occurrences: result.add occurrence.toObject


proc toObject(reading: ReadingStream): JsObject =
  ## Mirror reading of stream: its words, or refusal with place and detail.
  result = newJsObject()
  result.is_read = reading.is_read
  if reading.is_read:
    result.occurrences = reading.occurrences.toObjects
    return
  result.refusal = cstring($reading.refusal)
  result.start = reading.start
  result.detail = cstring(reading.detail)


proc parseLojban*(text: cstring): JsObject {.exportc.} =
  ## Read text as prose, and give what `readText` gives, as plain object.
  ##   Boundary of JS target: `exportc` keeps name `parseLojban` in script. Text arrives as string
  ##     of JavaScript, and `$` gives its UTF-8 bytes, which parser reads. Object holds strings,
  ##     numbers, booleans, arrays and null alone, so caller reads it with no Nim runtime.
  let
    source = $text
    reading = source.readText
  result = newJsObject()
  result.is_read = reading.is_read
  if reading.is_read:
    var units: seq[JsObject]
    for index in 0..<reading.units.len:  # index, since `items` copies each unit on JS backend
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



# Export to loader of CommonJS where node gives one; browser keeps global alone.
if MODULE_NODE.jsTypeOf != "undefined": MODULE_NODE.exports.parseLojban = parseLojban
