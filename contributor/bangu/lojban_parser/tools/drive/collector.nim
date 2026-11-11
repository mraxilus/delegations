## Collect what page draws, and font faces it declares, as browser computed them, and post it to
##   backend that serves page (`tools/drive.nim`) once page loads: collector `koch drive` judges
##   through (CONTRIBUTOR.md, Pages and assets). It reads each page `drive` builds, and control
##   page `koch drive` writes, and judges none: `font_stacks.nim` of curator resolves what it reads.
##   Port of `contributor/ronri/pga_benchmark/tools/drive/text.ts`, which reads page through
##     Playwright. Here code runs in page itself, as Nim compiled to JavaScript, so each expression
##     is checked Nim, and no node runs it (ruling on #859). Code is one, so fix to either is
##     finished only when other is checked (II.9).
##   Text read is every string page draws: text nodes, SVG `text` among them, past elements that
##     draw none; `placeholder`, and `value` of button; strings of `content` on `::before`,
##     `::after` and `::marker`, and of `list-style-type`. Each is read with `font-family`,
##     `font-weight` and `text-transform` of element drawing it.
##   Each `@font-face` rule is read as CSSOM serialises its descriptors, and each font face browser
##     refuses is read with status it reached.
##   Every `details` opens first, and every element shows, so every state of page reads in one
##     pass; `display` sets no font property, so no verdict moves.
##   Posts `{runs, rules, refused}` to `/collected`, string of JSON, as `written.json` holds it;
##     backend writes it into that file, which is format `koch drive` reads (`font_stacks.nim`).
##   Cost: page is read at one viewport, default of Chromium; string or stack that `@media` gates
##     on other width is unread.

{.experimental: "strictFuncs".}

import std/[asyncjs, jsffi, sets, strutils, unicode]


const
  SILENT = "script, style, title, desc, metadata, noscript"  ## Elements whose text draws none.
  TYPES_BUTTON = ["button", "reset", "submit"]  ## Types of input whose value draws as text.
  PSEUDOS = ["::before", "::after", "::marker"]  ## Pseudo-elements whose `content` draws.
  SHOW_TEXT = 4  ## Filter of tree walker that shows text nodes alone (`NodeFilter.SHOW_TEXT`).
  RULE_FONT_FACE = 5  ## Type of `@font-face` rule in CSSOM (`CSSRule.FONT_FACE_RULE`).
  STYLE_SHOWN = "body * { display: revert !important; }"  ## Style that shows every element.
  PATH_COLLECTED = "/collected"  ## Path collector posts what it read to.
  PATH_DONE = "/done"  ## Path collector posts end of run to, once it posted what it read.


let
  DOCUMENT {.nodecl, importc: "document".}: JsObject  ## Document of page.
  SELF {.nodecl, importc: "self".}: JsObject  ## Global scope of page.


proc styleOf(element: JsObject, pseudo: cstring): JsObject {.importjs: "getComputedStyle(@)".}
  ## Give style browser computed for element, or for its pseudo-element. Boundary of JS target.
proc stringify(value: JsObject): cstring {.importjs: "JSON.stringify(#)".}
  ## Write value as string of JSON. Boundary of JS target.
proc newRequest(): JsObject {.importjs: "new XMLHttpRequest()".}
  ## Make request to backend. Boundary of JS target: constructor of page.
proc toArray(iterable: JsObject): JsObject {.importjs: "Array.from(#)".}
  ## Give array of each item of collection. Boundary of JS target.
proc loaded(font_face: JsObject): Future[JsObject] {.importjs: "#.load()".}
  ## Give promise of font face loaded. Boundary of JS target: method of `FontFace`.



proc named(element: JsObject): string =
  ## Name element by tag, id and classes.
  result = ($element.tagName.to(cstring)).toLowerAscii
  let id = $element.id.to(cstring)
  if id.len > 0: result.add "#" & id
  let classes = element.getAttribute(cstring("class"))
  if not classes.isNull:
    for name in strutils.splitWhitespace($classes.to(cstring)): result.add "." & name


proc described(element: JsObject): string =
  ## Name element under its ancestors, up to one carrying id, at most two.
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
  ## Join strings of computed `content` or `list-style-type`, each between double quotes, with
  ##   escapes of CSS resolved: hex of one to six digits and space after it, or character itself.
  var
    k = 0
    is_quoted = false
  while k < value.len:
    let c = value[k]
    if not is_quoted:
      is_quoted = c == '"'
      inc k
      continue
    if c == '"':
      is_quoted = false
      inc k
      continue
    if c != '\\' or k + 1 >= value.len:
      result.add c
      inc k
      continue
    var last = k + 1
    while last < value.len and last - k <= 6 and value[last] in HexDigits: inc last
    if last == k + 1:  # escape of character itself
      result.add value[k + 1]
      k += 2
      continue
    result.add Rune(fromHex[int](value[k + 1 ..< last])).toUTF8
    k = (if last < value.len and value[last] == ' ': last + 1 else: last)


proc collect(): Future[JsObject] {.async.} =
  ## Read every run page draws, ASCII included, every `@font-face` rule it declares, and every font
  ##   face browser refused.
  var runs: seq[JsObject]
  proc add(element: JsObject, pseudo, text: string, pseudo_style = "") =
    ## Record text element draws under one pseudo-element, as its style transforms it.
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
    for rune in drawn.runes:  # each codepoint once, ASCII included (D1 b of #751)
      if seen.containsOrIncl(rune.int): continue
      codepoints.add rune.int
    if codepoints.len == 0: return
    let run = newJsObject()
    run.element = cstring(element.described & pseudo)
    run.stack = style.fontFamily
    run.weight = style.fontWeight.to(cstring).`$`.parseFloat
    run.codepoints = codepoints
    runs.add run

  for details in DOCUMENT.querySelectorAll(cstring("details")).toArray.to(seq[JsObject]):
    details.open = true  # every state of page reads in one pass
  let shown = DOCUMENT.createElement(cstring("style"))
  shown.textContent = cstring(STYLE_SHOWN)
  DOCUMENT.head.append(shown)

  let walker = DOCUMENT.createTreeWalker(DOCUMENT.body, SHOW_TEXT)
  var node = walker.nextNode()
  while not node.isNull:
    let parent = node.parentElement
    if not parent.isNull and parent.closest(cstring(SILENT)).isNull:
      parent.add("", $node.textContent.to(cstring))
    node = walker.nextNode()

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

  var refused: seq[JsObject]
  for font_face in DOCUMENT.fonts.toArray.to(seq[JsObject]):
    try: discard await font_face.loaded  # face browser refuses reads as refused, not as unasked
    except CatchableError: discard
    if $font_face.status.to(cstring) == "loaded": continue
    let face = newJsObject()
    face.family = font_face.family
    face.weight = font_face.weight
    face.status = font_face.status
    refused.add face

  let collected = newJsObject()  # `result` of proc of promises is no plain object to set on
  collected.runs = runs
  collected.rules = rules
  collected.refused = refused
  return collected


proc post(path: string, body: cstring) =
  ## Post body to backend at path, and wait for its answer.
  let request = newRequest()
  request.open(cstring("POST"), cstring(path), false)
  request.send(body)


proc collectPosted() {.async.} =
  ## Collect page once it loads, post what collector read, then end run.
  post(PATH_COLLECTED, (await collect()).stringify)
  post(PATH_DONE, "0")


SELF.addEventListener(cstring("load"), proc(event: JsObject) = discard collectPosted())
