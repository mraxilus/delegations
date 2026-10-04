## Judge what harness found when it rendered pages, and hold it to control that proves it sees.
##   Harness (`tools/drive/`) renders each page and writes, as data, every character beyond ASCII
##     that face of system would draw, and every face browser does not load. It judges nothing:
##     wording and verdict are here, where suites reach them (Article II.9).
##   Control page is positive control of render. Its paragraphs come from fixture
##     `tests/fixtures/control_faces.json`, built into page through shell, so it ships faces
##     every page ships. Paragraph marked drawn by system writes character no shipped face maps
##     under its stack; other paragraph writes one shipped face does map.
##     Control's expected findings are never page's failure. Expected finding absent is finding
##     instead, since render that misses it is blind; finding control does not expect is one too.
##   Fixture lives under `tests/`: static coverage check (`curator/audit/src/coverage.nim`) reads
##     every file of project outside it, and control's characters are ones no face maps.
##     Rejected: control page under `pages/`, where layout admits HTML, since coverage reads it.
##   Harness names element with id as `<tag>#<id>` (`tools/drive/text.ts`), so control's
##     paragraph `han` is `p#han`; misnamed one reads as blind, so drive holds naming too.

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


const
  CONTROL* = "control_faces"  ## Name control page renders under, beside every page.
  ASCII_MAX = 0x7F  ## Last codepoint of ASCII, which render never reads.



#[ Control ]#

func codepointText*(codepoint: int): string =
  ## Spell codepoint as Unicode names it, at least four digits, as `U+2603`.
  "U+" & codepoint.toHex.strip(trailing = false, chars = {'0'}).align(4, '0')


func paragraphsOf*(control: JsonNode): seq[ParagraphControl] =
  ## Read paragraphs of control fixture, in order written.
  for paragraph in control{"paragraphs"}.getElems:
    result.add ParagraphControl(
      id: paragraph{"id"}.getStr,
      stack: paragraph{"stack"}.getStr,
      text: paragraph{"text"}.getStr,
      is_drawn_by_system: paragraph{"is_drawn_by_system"}.getBool,
    )


func bodyControl*(paragraphs: openArray[ParagraphControl]): string =
  ## Render control's body: one paragraph each, its stack set inline where it names one.
  for paragraph in paragraphs:
    let style =
      if paragraph.stack.len == 0: ""
      else: " style=\"font-family: " & escapeHtml(paragraph.stack) & "\""
    result.add "<p id=\"" & escapeHtml(paragraph.id) & "\"" & style & ">" &
        escapeHtml(paragraph.text) & "</p>"


func expectedOf*(paragraphs: openArray[ParagraphControl]): seq[FindingExpected] =
  ## List findings control must raise: each character beyond ASCII that system draws.
  for paragraph in paragraphs:
    if not paragraph.is_drawn_by_system: continue
    for rune in paragraph.text.runes:
      let expected = (element: "p#" & paragraph.id, codepoint: int(rune))
      if int(rune) > ASCII_MAX and expected notin result: result.add expected



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
    for face in document{"faces"}.getElems:
      result.add Finding(
        path: path,
        message: "@font-face " & face{"family"}.getStr & " " & face{"weight"}.getStr &
            ": Face does not load; got `" & face{"status"}.getStr & "`.",
      )
    for character in document{"characters"}.getElems:
      let pair = (element: character{"element"}.getStr, codepoint: character{"codepoint"}.getInt)
      if page == control and pair in expected:
        seen.add pair
        continue
      result.add Finding(
        path: path,
        message: pair.element & ": Character drawn by face of system; got `" &
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
