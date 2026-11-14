## crepu lo pixra pe le papri ge'u .e lo lerfu tarmi poi le papri cu cusku ke'a ku'o ta'i lo se
##   kanji be lo tcidu be lo papri gi'e benji lo se crepu le samtci poi sabji le papri ku'o to
##   `tools/drive.nim` toi ba lo nu le papri cu se cpacu .i `koch drive` cu jdice sepi'o le vi
##   crepu to `CONTRIBUTOR.md, Pages and assets` toi .i le crepu cu tcidu ro papri poi lo minde
##   po'u `drive` cu zbasu ke'a ku'o .e le jitro papri poi `koch drive` cu ciska ke'a .i le crepu
##   cu jdice fi no papri .i `font_stacks.nim` pe la'o gy. curator .gy. cu jdice fi lo se tcidu be
##   le crepu
##   .i le vi datnyvei cu fukpi fi la'o gy. Nim .gy. fe
##     `contributor/ronri/pga_benchmark/tools/drive/text.ts` noi tcidu lo papri sepi'o
##     la'o gy. Playwright .gy. .i vi le se ciska cu fasnu ne'i le papri ta'i lo se ciska be fi
##     la'o gy. Nim .gy. poi se fanva fi la'o gy. JavaScript .gy. .i se ki'u bo ro se ciska cu se
##     ciska fi la'o gy. Nim .gy. .i le fanva cu cipra ro le se ciska .i la'o gy. node .gy. na
##     jitro le se ciska .i la'o gy. Architect .gy. cu jdice di'u bu'u `#859` .i le re se ciska cu
##     pilno le mintu tadji .i se ki'u bo va'o lo nu le drata na se cipra kei lo nu cikre pa le re
##     se ciska cu na mulno to `II.9` toi
##   .i le crepu cu tcidu ro lerpoi poi le papri cu pixra ke'a .i le se tcidu cu vasru lo se ciska
##     jgena mu'u lo se ciska jgena pe `text` pe la'o gy. SVG .gy. .i le crepu cu tcidu no se ciska
##     jgena pe lo pagbu be le papri be'o poi pixra no da .i le crepu cu tcidu `placeholder` .e
##     `value` pe lo batke .i le crepu cu tcidu lo lerpoi pe `content` bu'u `::before` .e
##     `::after` .e `::marker` .i le crepu cu tcidu ji'a lo lerpoi pe `list-style-type` .i ro le
##     lerpoi cu se tcidu fi'o kansa `font-family` .e `font-weight` .e `text-transform` vu'o pe lo
##     pagbu poi pixra le lerpoi
##   .i le crepu cu tcidu ro skicu be lo javni pe `@font-face` ta'i lo lerpoi poi
##     la'o gy. CSSOM .gy. cu ciska ke'a .i ro lerfu tarmi poi lo tcidu be lo papri cu to'e curmi
##     ke'a cu se tcidu fi'o kansa lo tcini poi le lerfu tarmi cu klama ke'a
##   .i pu lo nu tcidu le crepu cu kargau ro `details` gi'e jarco ro pagbu .i se ki'u bo ro tcini
##     be le papri cu se tcidu ca pa nu tcidu .i `display` cu galfi no se ckaji be lo lerfu tarmi
##     .i se ki'u bo no se jdice cu cenba
##   .i benji `{runs, rules, refused}` fi `/collected` ta'i pa lerpoi pe la'o gy. JSON .gy. .i
##     `written.json` cu vasru le lerpoi .i le samtci cu ciska le lerpoi fi le datnyvei .i le tarmi
##     be le datnyvei cu du le tarmi poi `koch drive` cu tcidu ke'a to `font_stacks.nim` toi
##   .i jdima fa lo nu le papri cu se tcidu bu'u pa canko po'o .i la'o gy. Chromium .gy. cu zmiku
##     cuxna le canko .i se ki'u bo no da cu tcidu lo lerpoi .a lo porsi be lo lerfu tarmi vu'o poi
##     `@media` cu curmi ke'a va'o lo ni ganra poi drata po'o

{.experimental: "strictFuncs".}

import std/[asyncjs, jsffi, sets, strutils, unicode]


const
  SILENT = "script, style, title, desc, metadata, noscript"
    ## lo pagbu poi le papri cu pixra no se ciska pe ke'a
  TYPES_BUTTON = ["button", "reset", "submit"]
    ## lo klesi be lo pagbu po'u `input` be'o poi le papri cu pixra `value` pe le pagbu ta'i lo se
    ##   ciska
  PSEUDOS = ["::before", "::after", "::marker"]
    ## lo jitfa pagbu poi le papri cu pixra `content` pe ke'a
  SHOW_TEXT = 4
    ## lo julne poi lo cadzu be le tricu cu jarco lo se ciska jgena po'o sepi'o ke'a to
    ##   `NodeFilter.SHOW_TEXT` toi
  RULE_FONT_FACE = 5
    ## lo klesi be lo javni pe `@font-face` ne'i la'o gy. CSSOM .gy. to `CSSRule.FONT_FACE_RULE` toi
  STYLE_SHOWN = "body * { display: revert !important; }"  ## lo javni poi jarco ro pagbu
  PATH_COLLECTED = "/collected"  ## le judri poi le crepu cu benji lo se tcidu be vo'a fi ke'a
  PATH_DONE = "/done"
    ## le judri poi le crepu cu benji lo fanmo be le nu cipra fi ke'a ba lo nu le crepu cu benji lo
    ##   se tcidu be vo'a


let
  DOCUMENT {.nodecl, importc: "document".}: JsObject  ## `document` pe le papri
  SELF {.nodecl, importc: "self".}: JsObject  ## le mulno vanbi pe le papri


proc styleOf(element: JsObject, pseudo: cstring): JsObject {.importjs: "getComputedStyle(@)".}
  ## jarco lo tarmi be le pagbu .a lo tarmi be lo jitfa pagbu pe le pagbu .i lo tcidu be lo
  ##   papri cu kanji le tarmi .i le fancu cu korbi la'o gy. Nim .gy. la'o gy. JavaScript .gy.
proc stringify(value: JsObject): cstring {.importjs: "JSON.stringify(#)".}
  ## ciska le datni ta'i pa lerpoi pe la'o gy. JSON .gy. .i le fancu cu korbi la'o gy. Nim .gy.
  ##   la'o gy. JavaScript .gy.
proc newRequest(): JsObject {.importjs: "new XMLHttpRequest()".}
  ## zbasu pa nu cpedu fi le samtci .i le fancu cu korbi la'o gy. Nim .gy.
  ##   la'o gy. JavaScript .gy. .i le fancu cu pilno pa zbasu fancu pe le papri
proc toArray(iterable: JsObject): JsObject {.importjs: "Array.from(#)".}
  ## jarco lo porsi be ro cmima be le girzu .i le fancu cu korbi la'o gy. Nim .gy.
  ##   la'o gy. JavaScript .gy.
proc loaded(font_face: JsObject): Future[JsObject] {.importjs: "#.load()".}
  ## jarco lo nupre be lo nu le lerfu tarmi cu se cpacu .i le fancu cu korbi la'o gy. Nim .gy.
  ##   la'o gy. JavaScript .gy. .i le fancu cu pilno pa fancu pe `FontFace`



proc named(element: JsObject): string =
  ## jarco lo cmene be le pagbu sepi'o le tcita .e `id` .e lo klesi vu'o pe le pagbu
  result = ($element.tagName.to(cstring)).toLowerAscii
  let id = $element.id.to(cstring)
  if id.len > 0: result.add "#" & id
  let classes = element.getAttribute(cstring("class"))
  if not classes.isNull:
    for name in strutils.splitWhitespace($classes.to(cstring)): result.add "." & name


proc described(element: JsObject): string =
  ## jarco lo cmene be le pagbu be'o poi lo cmene be su'e re lo pagbu poi vasru le pagbu cu lidne
  ##   ke'a .i le fancu cu sisti ca lo nu jmina lo cmene be pa pagbu poi ponse `id`
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
  ## jarco pa lerpoi poi se pagbu ro lerpoi pe le se kanji pe `content` .a `list-style-type`
  ##   .i ro le lerpoi cu zvati lo jbini be re lerfu po'u `"` .i ro lerpoi poi se krasi lo lerfu
  ##   po'u `\` cu se basti lo lerfu poi le lerpoi cu sinxa ke'a .i le lerpoi cu vasru su'o pa
  ##   lerfu pe la'o gy. hex .gy. gi'e vasru su'e xa le lerfu gi'e vasru lo kunti lerfu poi se
  ##   lidne le lerfu .i ja le lerpoi cu sinxa le lerfu poi se lidne lo lerfu po'u `\`
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
    if last == k + 1:  # `\` cu lidne le lerfu poi le lerpoi cu sinxa ke'a
      result.add value[k + 1]
      k += 2
      continue
    result.add Rune(fromHex[int](value[k + 1 ..< last])).toUTF8
    k = (if last < value.len and value[last] == ' ': last + 1 else: last)


proc collect(): Future[JsObject] {.async.} =
  ## tcidu ro porsi be lo lerfu poi le papri cu pixra ke'a .i le se tcidu cu vasru ji'a lo lerfu
  ##   pe la'o gy. ASCII .gy. .i tcidu ji'a ro javni pe `@font-face` ge'u zi'e poi le papri cu
  ##   cusku ke'a ku'o .e ro lerfu tarmi poi lo tcidu be lo papri pu to'e curmi ke'a
  var runs: seq[JsObject]
  proc add(element: JsObject, pseudo, text: string, pseudo_style = "") =
    ## ralte lo se ciska poi le pagbu cu pixra ke'a bu'u pa jitfa pagbu ku'o ta'i lo nu le tarmi
    ##   pe le pagbu cu galfi le se ciska
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
    # ro lerfu namcu cu se ralte pa roi .i lo lerfu pe la'o gy. ASCII .gy. cu se ralte ji'a to
    # `D1 b` pe `#751` toi
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

  for details in DOCUMENT.querySelectorAll(cstring("details")).toArray.to(seq[JsObject]):
    details.open = true  # ro tcini be le papri cu se tcidu ca pa nu tcidu
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
    # lo lerfu tarmi poi lo tcidu be lo papri cu to'e curmi ke'a cu se tcidu ta'i lo se to'e
    # curmi .enai lo na'e se cpedu
    try: discard await font_face.loaded
    except CatchableError: discard
    if $font_face.status.to(cstring) == "loaded": continue
    let face = newJsObject()
    face.family = font_face.family
    face.weight = font_face.weight
    face.status = font_face.status
    refused.add face

  # `result` pe lo fancu pe lo nupre cu na du lo sampu dacti poi ka'e punji lo datni pagbu ke'a
  let collected = newJsObject()
  collected.runs = runs
  collected.rules = rules
  collected.refused = refused
  return collected


proc post(path: string, body: cstring) =
  ## benji `body` le samtci bu'u `path` gi'e denpa lo nu le samtci cu spuda
  let request = newRequest()
  request.open(cstring("POST"), cstring(path), false)
  request.send(body)


proc collectPosted() {.async.} =
  ## crepu le papri ba lo nu le papri cu se cpacu .i benji lo se tcidu be le crepu .i sisti le
  ##   nu cipra ba lo nu benji
  post(PATH_COLLECTED, (await collect()).stringify)
  post(PATH_DONE, "0")


SELF.addEventListener(cstring("load"), proc(event: JsObject) = discard collectPosted())
