## Resolve each character page draws past ASCII down font stack of its element, against font
##   faces page ships, for `koch resolve-font-faces` (CONTRIBUTOR.md, Pages and assets).
##   One resolver serves every project, where three copies had drifted and disagreed (repository
##     issue 671). Each project's browser part writes what browser computed; this writes what
##     font face of system would draw; project's own judge gives verdict, since it holds its
##     control page and its wording.
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


func isHolding(face: FontFace, codepoint: int): bool =
  ## Tell whether rule draws `codepoint`: its range holds it, or it sets none, and its file maps it.
  (face.ranges.len == 0 or face.ranges.anyIt(codepoint in it)) and codepoint in face.codepoints


func isDrawn(faces: seq[FontFace], families: openArray[string], weight, codepoint: int): bool =
  ## Tell whether font faces page ships draw `codepoint` at `weight` down `families`.
  if families.len == 0: return false  # end of stack: font face of system draws
  let own = faces.filterIt(it.family == families[0])
  if own.len == 0: return false  # family page does not ship ends search (Article X.8)
  var sets: OrderedTable[(int, int), seq[FontFace]]
  for face in own: sets.mgetOrPut((face.weights.a, face.weights.b), @[]).add face
  let matched =
    if own.anyIt(weight in it.weights): weight
    else: weightMatched(weight, own.mapIt(@[it.weights.a, it.weights.b]).concat)
  for (bounds, set) in sets.pairs:
    if matched notin bounds[0] .. bounds[1]: continue
    if not set.anyIt(it.isHolding(codepoint)) and
        not faces.isDrawn(families.toOpenArray(1, families.high), weight, codepoint):
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
    let faces = entry{"declared"}.toFontFaces(directory, read)
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
        if (element, codepoint) in reported or faces.isDrawn(families, weight, codepoint):
          continue
        reported.incl (element, codepoint)
        characters.add %*{"element": element, "codepoint": codepoint}
    let refused = if entry{"refused"}.isNil: newJArray() else: entry["refused"]
    result[page] = %*{"characters": characters, "refused": refused}


proc writeFound*(path_written, path_found: string): seq[Finding] =
  ## Resolve `written.json` at `path_written`, and write `found.json` at `path_found`; finding
  ##   where either cannot be read or written, or where file breaks shape header gives.
  try:
    let found = parseFile(path_written).toFound(path_written.parentDir)
    writeFile(path_found, found.pretty & "\n")
  except IOError, OSError, ValueError, KeyError:
    result.add finding(
      path_written, 0,
      "Written file resolves where each page holds runs, rules and refused font faces, and " &
        "each file of rule reads; got `" & getCurrentExceptionMsg() & "`.",
    )
