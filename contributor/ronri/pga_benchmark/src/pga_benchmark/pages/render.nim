## Judge what harness found when it rendered pages, and hold it to control that proves it sees.
##   Harness (`tools/drive/`) renders each page and writes, as data, every character beyond ASCII
##     that font face of system would draw, every font face browser does not load, and every
##     pair of blocks of card that stand closer than 4 px. It judges nothing: wording and
##     verdict are here, where suites reach them (Article II.9).
##   Control page is positive control of render. Its paragraphs and cards come from fixture
##     `tests/fixtures/control_render.json`, built into page through shell, so it ships font
##     faces and styles every page ships. Paragraph marked drawn by system writes character no
##     shipped font face maps under its stack; other paragraph writes one shipped font face
##     does map. Card marked crowded sets inline margin of zero on its second block, which no
##     style of shell outranks; other card keeps margins shell gives, so it holds shell to
##     spacing each block.
##     Control's expected findings are never page's failure. Expected finding absent is finding
##     instead, since render that misses it is blind; finding control does not expect is one too.
##   Fixture lives under `tests/`: static coverage check (`curator/audit/src/coverage.nim`) reads
##     every file of project outside it, and control's characters are ones no font face maps.
##     Rejected: control page under `pages/`, where layout admits HTML, since coverage reads it.
##   Harness names element with id as `<tag>#<id>`, then its classes (`tools/drive/text.ts`,
##     `layout.ts`), so control's paragraph `han` is `p#han` and its card `crowded` is
##     `details#crowded.card`; misnamed one reads as blind, so drive holds naming too.

{.experimental: "strictFuncs".}

import std/[json, os, strutils, unicode]

import ../[guard, markdown]


type
  ParagraphControl* = object  ## Define one paragraph of control page.
    id*: string  ## Id harness names paragraph by, as `p#<id>`.
    stack*: string  ## Font stack paragraph sets inline; empty keeps page's own.
    text*: string  ## Text paragraph writes.
    is_drawn_by_system*: bool  ## Every character of text beyond ASCII must raise finding.

  FindingExpected* = tuple[element: string, codepoint: int]
    ## Define finding control must raise: element, as harness names it, and codepoint.

  CardControl* = object  ## Define one card of control page.
    id*: string  ## Id harness names card by, as `details#<id>.card`.
    is_crowded*: bool  ## Second block of card sits on first, so pair must raise finding.


const
  CONTROL* = "control_render"  ## Name control page renders under, beside every page.
  ASCII_MAX = 0x7F  ## Last codepoint of ASCII, which render never reads.



#[ Control ]#

func codepointText*(codepoint: int): string =
  ## Spell codepoint as Unicode names it, at least four digits, as `U+2603`.
  "U+" & codepoint.toHex.strip(trailing = false, chars = {'0'}).align(4, '0')


func paragraphs*(control: JsonNode): seq[ParagraphControl] =
  ## Read paragraphs of control fixture, in order written.
  for paragraph in control{"paragraphs"}.getElems:
    result.add ParagraphControl(
      id: paragraph{"id"}.getStr,
      stack: paragraph{"stack"}.getStr,
      text: paragraph{"text"}.getStr,
      is_drawn_by_system: paragraph{"is_drawn_by_system"}.getBool,
    )


func cards*(control: JsonNode): seq[CardControl] =
  ## Read cards of control fixture, in order written.
  for card in control{"cards"}.getElems:
    result.add CardControl(id: card{"id"}.getStr, is_crowded: card{"is_crowded"}.getBool)


func bodyControl*(
  paragraphs: openArray[ParagraphControl]; cards: openArray[CardControl]
): string =
  ## Render control's body: one paragraph each, its stack set inline where it names one; then
  ##   one open card each, of two blocks, second set on first where card is crowded.
  for paragraph in paragraphs:
    let style =
      if paragraph.stack.len == 0: ""
      else: " style=\"font-family: " & escapeHtml(paragraph.stack) & "\""
    result.add "<p id=\"" & escapeHtml(paragraph.id) & "\"" & style & ">" &
        escapeHtml(paragraph.text) & "</p>"
  for card in cards:
    let style = if card.is_crowded: " style=\"margin-top: 0 !important\"" else: ""
    result.add "<details class=\"card\" id=\"" & escapeHtml(card.id) & "\" open>" &
        "<summary><h3>Card</h3></summary><p>First block.</p><p" & style &
        ">Second block.</p></details>"


func findingsExpected*(paragraphs: openArray[ParagraphControl]): seq[FindingExpected] =
  ## List findings control must raise: each character beyond ASCII that system draws.
  for paragraph in paragraphs:
    if not paragraph.is_drawn_by_system: continue
    for rune in paragraph.text.runes:
      let expected = (element: "p#" & paragraph.id, codepoint: int(rune))
      if int(rune) > ASCII_MAX and expected notin result: result.add expected


func crowdedExpected*(cards: openArray[CardControl]): seq[string] =
  ## List cards control must raise as crowded, each as harness names it.
  for card in cards:
    if card.is_crowded: result.add "details#" & card.id & ".card"



#[ Verdict ]#

func checkRendered*(
  found: JsonNode; expected: openArray[FindingExpected]; control, directory: string
): seq[Finding] =
  ## Turn what harness found into findings, each at page it was found on; hold control to
  ##   exactly findings it expects.
  ##   Document maps page name to its `characters` (element, codepoint) and its `faces` (family,
  ##   weight, status); control absent from it raised nothing, so each expected is blind.
  var seen: seq[FindingExpected]
  for page, document in found.pairs:
    let path = directory / page & ".html"
    for font_face in document{"faces"}.getElems:
      result.add Finding(
        path: path,
        message: "@font-face " & font_face{"family"}.getStr & " " &
            font_face{"weight"}.getStr & ": Font face does not load; got `" &
            font_face{"status"}.getStr & "`.",
      )
    for character in document{"characters"}.getElems:
      let pair = (element: character{"element"}.getStr, codepoint: character{"codepoint"}.getInt)
      if page == control and pair in expected:
        seen.add pair
        continue
      result.add Finding(
        path: path,
        message: pair.element & ": Character drawn by font face of system; got `" &
            codepointText(pair.codepoint) & "`.",
      )
  let path_control = directory / control & ".html"
  if expected.len == 0:
    result.add Finding(
      path: path_control,
      message: "Control expects no finding, so render proves nothing; got `0` expected.",
    )
  for pair in expected:
    if pair in seen: continue
    result.add Finding(
      path: path_control,
      message: pair.element & ": Check is blind, since control raised no finding here; got " &
          "none for `" & codepointText(pair.codepoint) & "`.",
    )


func checkCrowded*(
  found: JsonNode; expected: openArray[string]; control, directory: string
): seq[Finding] =
  ## Turn each pair of blocks of card that harness found too close into finding at its page;
  ##   hold control to exactly cards it expects crowded.
  ##   Document maps page name to its `crowded` (element, between, gap); control absent from it
  ##     raised nothing, so each expected is blind.
  var seen: seq[string]
  for page, document in found.pairs:
    let path = directory / page & ".html"
    for pair in document{"crowded"}.getElems:
      let element = pair{"element"}.getStr
      if page == control and element in expected:
        if element notin seen: seen.add element
        continue
      result.add Finding(
        path: path,
        message: element & ": Blocks of card touch; got `" & pair{"between"}.getStr & "` at `" &
            $pair{"gap"}.getInt & " px`.",
      )
  let path_control = directory / control & ".html"
  if expected.len == 0:
    result.add Finding(
      path: path_control,
      message: "Control expects no crowded card, so layout check proves nothing; got `0` " &
          "expected.",
    )
  for element in expected:
    if element in seen: continue
    result.add Finding(
      path: path_control,
      message: element & ": Check is blind, since control raised no crowded pair here; got none.",
    )
