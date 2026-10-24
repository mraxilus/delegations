## Judge font faces each page of project draws, for `koch drive` (Article X.8; CONTRIBUTOR.md,
##   Pages and assets): each character page draws past ASCII is resolved down font stack of
##   its element, against font faces page ships.
##   Verdict is curator's, never project's: project's collector writes what browser computed,
##     and judge of project's own could let finding through. Three copies of resolver had
##     drifted and disagreed (repository issue 671), so one serves every project.
##
##   For each project `koch drive` drives (`runDriven` of `projects.nim`):
##     Control page is written to `build/font-faces/control.html`, before project's `drive`.
##     Project's `drive` reads each page it builds, and control page as page `control`, with
##       one collector, and writes `build/font-faces/written.json`.
##     Once `drive` passes, that file resolves into `found.json` beside it, which is judged.
##   Project writing no `written.json` is finding: rule asks every project with pages for it,
##     and verdict over no file would pass pages nobody read.
##
##   Control page holds Chinese numerals one to five, each in one kind of place text stands:
##     paragraph, placeholder of field, `::before`, SVG text, and text script writes on load.
##     No font face of store maps any of them, which suite holds to rows of `assets.nim`, so
##     each is found wherever collector reads its place, and numeral missing names place
##     collector skips. Script builds its numeral from codepoint, so no literal stands for
##     reader of source alone.
##   Verdict: finding for each character page other than control draws from font face of
##     system, each font face browser refused, and each numeral control page lacks.
##
##   Input, `written.json`, maps each page to three lists:
##     `runs`: each string page draws past ASCII, as `element`, `stack` (computed `font-family`),
##       `weight` (computed `font-weight`) and `codepoints`;
##     `declared`: each `@font-face` rule, as `family`, `weight` (keyword, number, or range of
##       two), `range` (`unicode-range` as rule writes it) and `file`, which path relative to
##       folder of `written.json` names where it is not absolute;
##     `refused`: each font face browser did not load, as `family`, `weight` and `status`.
##   Output, `found.json`, maps each page to `characters`, each `element` and `codepoint` that font
##     face of system would draw, once for each element, and to `refused`, copied as read.
##
##   Matching follows CSS Fonts 4 for `font-family` and `font-weight`:
##     Family names match without case, quotes stripped.
##     Family page does not ship ends search, and so does end of stack: font face of that name,
##       or of generic family, on machine of viewer would draw character (Article X.8).
##     Within family, rules declaring one weight range form one set. Weight wanted that no set
##       holds moves to bound CSS Fonts 4 picks. Each set holding that weight is one browser may
##       pick, so character counts as drawn only where each such set, or family after it,
##       draws it.
##     Rule of set draws character where its `unicode-range` holds it, or it sets none, and its
##       file maps it (`font_files.nim`).
##   Each file is read once, however many rules and pages name it.
##
##   Cost: weight alone is matched; `font-style` and `font-stretch` are unread, as no copy read
##     them. Italic that page ships is later step.
##   Cost: character is resolved alone, as `cmap` maps it. Browser picks font face per cluster,
##     so combining mark whose base font face lacks it can draw from font face this does not name.
##   Cost: text script writes only once reader acts stands in no place of control page.
##     Collectors differ there; static half (`coverage.nim`) holds such text, where source
##     writes it, against every font face project ships.
##   Cost: collector skipping page of its own project, or reading control page apart, passes.
##     Either stands in diff, and static half still holds each character of every file.

{.experimental: "strictFuncs".}

import std/[algorithm, json, os, sequtils, sets, strutils, tables]
import ./[findings, font_files]


type FontFace = object  ## Define one `@font-face` rule page declares, with codepoints file maps.
  family: string  ## Family name, lowercase.
  weights: Slice[int]  ## Weight range rule declares; one weight is range of one.
  ranges: seq[Slice[int]]  ## `unicode-range` of rule; empty where rule sets none.
  codepoints: HashSet[int]  ## Codepoints its file maps to glyph other than `.notdef`.


const
  WEIGHT_NORMAL = 400  ## Weight keyword `normal` names, and weight of rule setting none.
  WEIGHT_BOLD = 700  ## Weight keyword `bold` names.
  WEIGHTS_UPWARD = 400 .. 500
    ## Weights wanted that look upward to 500 before they look downward (CSS Fonts 4).
  DIRECTORY_FONT_FACES* = "build" / "font-faces"
    ## Folder of project, from its root, holding control page, `written.json` and `found.json`.
  FILE_CONTROL* = "control.html"  ## Control page, written before project's `drive`.
  FILE_WRITTEN* = "written.json"  ## What project's collector writes.
  FILE_FOUND* = "found.json"  ## What resolver writes beside it.
  PAGE_CONTROL* = "control"  ## Page `written.json` names for control page.
  NUMERALS_CONTROL* = [
    (0x4E00, "paragraph"),
    (0x4E8C, "placeholder of field"),
    (0x4E09, "`::before`"),
    (0x56DB, "SVG text"),
    (0x4E94, "text script writes on load"),
  ]
    ## Chinese numerals one to five, each with kind of place control page holds it in.
  TEMPLATE_CONTROL = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Control of font faces</title>
<style>#before::before { content: "\$3"; }</style>
</head>
<body>
<p id="paragraph">&#x$1;</p>
<input id="placeholder" placeholder="&#x$2;">
<p id="before"></p>
<svg width="48" height="48"><text id="svg" x="0" y="32">&#x$4;</text></svg>
<p id="script"></p>
<script>document.getElementById("script").textContent = String.fromCodePoint(0x$5);</script>
</body>
</html>
"""
    ## Control page; `$n` stands for hex digits of numeral `n`. References and escapes keep
    ##   source ASCII, and script builds its numeral, so it stands only once script runs.


func toFamilies(stack: string): seq[string] =
  ## Split font stack into families, unquoted and lowercase, in order browser tries them.
  var
    family = ""
    quote = '\0'
  for character in stack & ",":
    if quote != '\0':
      if character == quote: quote = '\0' else: family.add character
    elif character in {'"', '\''}: quote = character
    elif character == ',':
      if family.strip.len > 0: result.add family.strip.toLowerAscii
      family = ""
    else: family.add character


func toWeights(descriptor: string): Slice[int] =
  ## Read `font-weight` descriptor, keyword, number or range of two, as its bounds.
  var weights: seq[int]
  for word in descriptor.splitWhitespace:
    weights.add(
      case word
      of "normal": WEIGHT_NORMAL
      of "bold": WEIGHT_BOLD
      else: int(word.parseFloat)
    )
  if weights.len == 0: WEIGHT_NORMAL .. WEIGHT_NORMAL else: weights[0] .. weights[^1]


func toRanges(descriptor: string): seq[Slice[int]] =
  ## Read `unicode-range` descriptor as inclusive bounds; `?` spans each hex digit it stands for,
  ##   as `U+4??` spans `400` to `4ff`.
  for part in descriptor.split(','):
    let token = part.strip.toUpperAscii
    if token.len == 0: continue
    if not token.startsWith("U+"):
      raise newException(ValueError, "Range opens with `U+`; got `" & token & "`.")
    let
      bounds = token[2 .. ^1]
      dash = bounds.find('-')
    if dash >= 0: result.add bounds[0 ..< dash].parseHexInt .. bounds[dash + 1 .. ^1].parseHexInt
    else: result.add bounds.replace('?', '0').parseHexInt .. bounds.replace('?', 'F').parseHexInt


func weightMatched(wanted: int, bounds: seq[int]): int =
  ## Pick weight CSS Fonts 4 settles on for `wanted`, among bounds family's rules declare.
  let
    above = bounds.filterIt(it > wanted).sorted
    below = bounds.filterIt(it < wanted).sorted(Descending)
    window = above.filterIt(it <= WEIGHTS_UPWARD.b)
  if wanted in bounds: wanted
  elif wanted in WEIGHTS_UPWARD and window.len > 0: window[0]
  elif wanted <= WEIGHTS_UPWARD.b: (if below.len > 0: below[0] else: above[0])
  else: (if above.len > 0: above[0] else: below[0])


func isHolding(font_face: FontFace, codepoint: int): bool =
  ## Tell whether rule draws `codepoint`: its range holds it, or it sets none, and its file maps it.
  (font_face.ranges.len == 0 or font_face.ranges.anyIt(codepoint in it)) and
    codepoint in font_face.codepoints


func isDrawn(
  font_faces: seq[FontFace], families: openArray[string], weight, codepoint: int
): bool =
  ## Tell whether font faces page ships draw `codepoint` at `weight` down `families`.
  if families.len == 0: return false  # end of stack: font face of system draws
  let own = font_faces.filterIt(it.family == families[0])
  if own.len == 0: return false  # family page does not ship ends search (Article X.8)
  var sets: OrderedTable[(int, int), seq[FontFace]]
  for font_face in own:
    sets.mgetOrPut((font_face.weights.a, font_face.weights.b), @[]).add font_face
  let matched =
    if own.anyIt(weight in it.weights): weight
    else: weightMatched(weight, own.mapIt(@[it.weights.a, it.weights.b]).concat)
  for (bounds, set) in sets.pairs:
    if matched notin bounds[0] .. bounds[1]: continue
    if not set.anyIt(it.isHolding(codepoint)) and
        not font_faces.isDrawn(families.toOpenArray(1, families.high), weight, codepoint):
      return false
  true


proc toFontFaces(
  declared: JsonNode, directory: string, read: var Table[string, HashSet[int]]
): seq[FontFace] =
  ## Read every `@font-face` rule page declares, with codepoints its file maps; each file once.
  for rule in declared.getElems:
    let
      file = rule["file"].getStr
      path = if file.isAbsolute: file else: directory / file
    if path notin read: read[path] = readFile(path).cmap.codepoints.toHashSet
    result.add FontFace(
      family: rule["family"].getStr.toFamilies.join(","),
      weights: rule{"weight"}.getStr.toWeights,
      ranges: rule{"range"}.getStr.toRanges,
      codepoints: read[path],
    )


proc toFound*(written: JsonNode, directory: string): JsonNode =
  ## Resolve each run of each page `written` holds into what `found.json` holds; relative file
  ##   of rule reads from `directory`.
  if written.kind != JObject:
    raise newException(ValueError, "Written file maps each page to its lists; got `" &
      $written.kind & "`.")
  result = newJObject()
  var read: Table[string, HashSet[int]]
  for page, entry in written.pairs:
    let font_faces = entry{"declared"}.toFontFaces(directory, read)
    var
      characters = newJArray()
      reported: HashSet[(string, int)]
    for run in entry{"runs"}.getElems:
      let
        element = run["element"].getStr
        families = run["stack"].getStr.toFamilies
        weight = int(run["weight"].getFloat)
      for node in run["codepoints"].getElems:
        let codepoint = node.getInt
        if (element, codepoint) in reported or font_faces.isDrawn(families, weight, codepoint):
          continue
        reported.incl (element, codepoint)
        characters.add %*{"element": element, "codepoint": codepoint}
    let refused = if entry{"refused"}.isNil: newJArray() else: entry["refused"]
    result[page] = %*{"characters": characters, "refused": refused}


func pageControl*(): string =
  ## Render control page, each numeral of `NUMERALS_CONTROL` in its kind of place.
  TEMPLATE_CONTROL % NUMERALS_CONTROL.mapIt(it[0].toHex(4))


func toText(node: JsonNode): string =
  ## Render scalar as it reads: string unquoted, number as JSON writes it.
  if node.isNil: "" elif node.kind == JString: node.getStr else: $node


func toVerdict*(found: JsonNode, path: string): seq[Finding] =
  ## Judge what `found.json` holds; each finding names `path`, file project's collector wrote.
  for page, entry in found.pairs:
    for refused in entry{"refused"}.getElems:
      result.add finding(
        path, 0,
        "Font face page ships loads, or font face of system draws in its place (Article X.8); " &
          "got `" & page & "`: `" & refused{"family"}.toText & "` at weight `" &
          refused{"weight"}.toText & "`, status `" & refused{"status"}.toText & "`.",
      )
    if page == PAGE_CONTROL: continue
    for character in entry{"characters"}.getElems:
      result.add finding(
        path, 0,
        "Character falls to font face of system, which viewer may lack (Article X.8); got `" &
          page & "`: `" & character{"element"}.toText & "` draws `" &
          character{"codepoint"}.getInt.toNotation & "`.",
      )
  if found{PAGE_CONTROL}.isNil:
    result.add finding(
      path, 0,
      "Collector reads control page `koch drive` writes, as page `" & PAGE_CONTROL & "`; got none.",
    )
    return
  let collected = found[PAGE_CONTROL]{"characters"}.getElems.mapIt(it{"codepoint"}.getInt)
  for (codepoint, place) in NUMERALS_CONTROL:
    if codepoint notin collected:
      result.add finding(
        path, 0,
        "Collector reads text in every kind of place control page holds; got `" &
          codepoint.toNotation & "` in " & place & " uncollected.",
      )


proc writeControl*(root, project: string) =
  ## Write control page into folder of font faces of `project`, where its `drive` reads it.
  let folder = root / project / DIRECTORY_FONT_FACES
  createDir(folder)
  writeFile(folder / FILE_CONTROL, pageControl())


proc checkFontFaces*(root, project: string): seq[Finding] =
  ## Resolve `written.json` of `project`, write `found.json` beside it, and judge it; project
  ##   writing none is finding (header).
  let
    folder = root / project / DIRECTORY_FONT_FACES
    path = project / DIRECTORY_FONT_FACES / FILE_WRITTEN
  if not fileExists(folder / FILE_WRITTEN):
    return @[finding(
      path, 0,
      "Drive of project with pages writes what its collector read, control page included " &
        "(CONTRIBUTOR.md, Pages and assets); got no file.",
    )]
  var found: JsonNode
  try:
    found = parseFile(folder / FILE_WRITTEN).toFound(folder)
    writeFile(folder / FILE_FOUND, found.pretty & "\n")
  except IOError, OSError, ValueError, KeyError:
    return @[finding(
      path, 0,
      "Written file resolves where each page holds runs, rules and refused font faces, and " &
        "each file of rule reads; got `" & getCurrentExceptionMsg() & "`.",
    )]
  found.toVerdict(path)
