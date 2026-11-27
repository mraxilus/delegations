## Collect, inside page, each run of text it draws with font browser used, and each font face it
##   declares; post all to server of `tools/drive.nim` once page has loaded, then post end.
##   `koch drive` judges what this posts against font faces page ships (CONTRIBUTOR.md, Pages and
##     assets); this file judges nothing.
##   Compiled to JavaScript, as rest of page is, so no step of drive runs in Node (D1 on #859).
##   Siblings: `ricysoho/tools/drive/collector.nim`, whose logic this file takes, and
##     `ronri/pga_benchmark/tools/drive/text.ts`, which collects same in TypeScript under
##     Playwright (II.9). Each project drives its own pages, as D1 on #1058 ruled; fix to one is
##     finished only when each is checked.
##
##   Reads every text node outside script, style and their kin, with its computed family, weight
##     and transform; reads placeholder, value of button input, and content of each pseudo.
##   Each codepoint counts once per run, ASCII included, as `koch drive` asks.
##   Opens each `details` and reveals each element first, so text hidden at load counts too.
##     Cost: page is left in state no viewer sees; drive reads nothing after collector.

{.experimental: "strictFuncs".}

import std/[asyncjs, jsffi, sets, strutils, unicode]


const
  SILENT = "script, style, title, desc, metadata, noscript"
    ## Elements whose text is never drawn.
  TYPES_BUTTON = ["button", "reset", "submit"]  ## Types of input whose value is drawn.
  PSEUDOS = ["::before", "::after", "::marker"]  ## Pseudos whose content is drawn.
  SHOW_TEXT = 4  ## Filter of tree walker for text nodes, i.e. `NodeFilter.SHOW_TEXT`.
  RULE_FONT_FACE = 5  ## Type of `@font-face` rule, i.e. `CSSRule.FONT_FACE_RULE`.
  STYLE_SHOWN = "body * { display: revert !important; }"  ## Rule that reveals each element.
  PATH_COLLECTED = "/collected"  ## Path collector posts what it read to.
  PATH_DONE = "/done"  ## Path collector posts its end to.


let
  DOCUMENT {.nodecl, importc: "document".}: JsObject  ## `document` of page.
  SELF {.nodecl, importc: "self".}: JsObject  ## Global scope of page.


proc styleOf(element: JsObject, pseudo: cstring): JsObject {.importjs: "getComputedStyle(@)".}
  ## Read computed style of element, or of its pseudo.
proc stringify(value: JsObject): cstring {.importjs: "JSON.stringify(#)".}
  ## Render value as JSON, which `koch drive` reads.
proc newRequest(): JsObject {.importjs: "new XMLHttpRequest()".}
  ## Make request; synchronous, so end posts after collection.
proc toArray(iterable: JsObject): JsObject {.importjs: "Array.from(#)".}
  ## Copy iterable of browser into array.
proc loaded(font_face: JsObject): Future[JsObject] {.importjs: "#.load()".}
  ## Load font face, so its status is final.



#[ Names ]#

proc named(element: JsObject): string =
  ## Name element as tag, id and classes, as CSS selects it.
  result = ($element.tagName.to(cstring)).toLowerAscii
  let id = $element.id.to(cstring)
  if id.len > 0: result.add "#" & id
  let classes = element.getAttribute(cstring("class"))
  if not classes.isNull:
    for name in strutils.splitWhitespace($classes.to(cstring)): result.add "." & name


proc described(element: JsObject): string =
  ## Name element by up to three ancestors, stopping at first with id, so finding points at it.
  var
    parts = @[element.named]
    at = element.parentElement
  while not at.isNull and at != DOCUMENT.body and parts.len < 3 and
      ($element.id.to(cstring)).len == 0:
    parts.insert(at.named, 0)
    if ($at.id.to(cstring)).len > 0: break
    at = at.parentElement
  parts.join(" > ")


func joinStrings(value: string): string =
  ## Read text of each quoted string of computed `content`, escapes of CSS decoded.
  var
    k = 0
    is_quoted = false
  while k < value.len:
    let c = value[k]

    # Skip text outside quotes, and enter string at its quote.
    if not is_quoted:
      is_quoted = c == '"'
      inc k
      continue
    if c == '"':
      is_quoted = false
      inc k
      continue

    # Keep plain character, and decode escape of up to six hex digits.
    if c != '\\' or k + 1 >= value.len:
      result.add c
      inc k
      continue
    var last = k + 1
    while last < value.len and last - k <= 6 and value[last] in HexDigits: inc last
    if last == k + 1:  # `\` before character that stands for itself.
      result.add value[k + 1]
      k += 2
      continue
    result.add Rune(fromHex[int](value[k + 1 ..< last])).toUTF8
    k = (if last < value.len and value[last] == ' ': last + 1 else: last)



#[ Collection ]#

proc collect(): Future[JsObject] {.async.} =
  ## Read each run of text page draws, each font face it declares, and each it failed to load.
  var runs: seq[JsObject]

  proc add(element: JsObject, pseudo, text: string, pseudo_style = "") =
    ## Add run of text of element, as transform of its style draws it.
    if text.len == 0: return
    let
      style = element.styleOf(cstring(pseudo_style))
      transform = $style.textTransform.to(cstring)
      shown = cstring(text).toJs
      drawn =
        case transform
        of "uppercase": $shown.toUpperCase().to(cstring)
        of "lowercase": $shown.toLowerCase().to(cstring)
        of "capitalize": text & $shown.toUpperCase().to(cstring)
        else: text
    var
      codepoints: seq[int]
      seen: HashSet[int]
    for rune in drawn.runes:
      if seen.containsOrIncl(int(rune)): continue
      codepoints.add int(rune)
    if codepoints.len == 0: return
    let run = newJsObject()
    run.element = cstring(element.described & pseudo)
    run.stack = style.fontFamily
    run.weight = style.fontWeight.to(cstring).`$`.parseFloat
    run.codepoints = codepoints
    runs.add run

  # Reveal each part of page, so text hidden at load is read too.
  for details in DOCUMENT.querySelectorAll(cstring("details")).toArray.to(seq[JsObject]):
    details.open = true
  let shown = DOCUMENT.createElement(cstring("style"))
  shown.textContent = cstring(STYLE_SHOWN)
  DOCUMENT.head.append(shown)

  # Read each text node outside silent elements.
  let walker = DOCUMENT.createTreeWalker(DOCUMENT.body, SHOW_TEXT)
  var node = walker.nextNode()
  while not node.isNull:
    let parent = node.parentElement
    if not parent.isNull and parent.closest(cstring(SILENT)).isNull:
      parent.add("", $node.textContent.to(cstring))
    node = walker.nextNode()

  # Read placeholders, values of buttons, content of pseudos and list markers.
  let elements = DOCUMENT.body.querySelectorAll(cstring("*")).toArray.to(seq[JsObject])
  for element in elements:
    if not element.closest(cstring(SILENT)).isNull: continue
    let placeholder = element.getAttribute(cstring("placeholder"))
    if not placeholder.isNull: element.add("::placeholder", $placeholder.to(cstring))
    let is_button = $element.tagName.to(cstring) == "INPUT" and
      ($element["type"].to(cstring)).toLowerAscii in TYPES_BUTTON
    if is_button: element.add("", $element.value.to(cstring))
    for pseudo in PSEUDOS:
      let content = $element.styleOf(cstring(pseudo)).content.to(cstring)
      element.add(pseudo, content.joinStrings, pseudo)
    let marker = $element.styleOf(cstring("")).listStyleType.to(cstring)
    element.add("::marker", marker.joinStrings)

  # Read each font face page declares, with its source.
  var rules: seq[JsObject]
  for sheet in DOCUMENT.styleSheets.toArray.to(seq[JsObject]):
    for rule in sheet.cssRules.toArray.to(seq[JsObject]):
      if rule["type"].to(int) != RULE_FONT_FACE: continue
      let declared = newJsObject()
      declared.family = rule.style.getPropertyValue(cstring("font-family"))
      declared.weight = rule.style.getPropertyValue(cstring("font-weight"))
      declared.range = rule.style.getPropertyValue(cstring("unicode-range"))
      declared.source = rule.style.getPropertyValue(cstring("src"))
      rules.add declared

  # Read each font face that failed to load, whether refused or never asked for.
  var refused: seq[JsObject]
  for font_face in DOCUMENT.fonts.toArray.to(seq[JsObject]):
    try: discard await font_face.loaded
    except CatchableError: discard
    if $font_face.status.to(cstring) == "loaded": continue
    let face = newJsObject()
    face.family = font_face.family
    face.weight = font_face.weight
    face.status = font_face.status
    refused.add face

  # Gather into one object; `result` of async routine holds no field set before return.
  let collected = newJsObject()
  collected.runs = runs
  collected.rules = rules
  collected.refused = refused
  return collected


proc post(path: string, body: cstring) =
  ## Post body to server synchronously, so next post follows it.
  let request = newRequest()
  request.open(cstring("POST"), cstring(path), false)
  request.send(body)


proc collectPosted() {.async.} =
  ## Collect page, post what was read, then post end of run.
  post(PATH_COLLECTED, (await collect()).stringify)
  post(PATH_DONE, "0")


SELF.addEventListener(cstring("load"), proc(event: JsObject) = discard collectPosted())
