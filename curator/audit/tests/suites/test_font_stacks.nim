## Replicate `font_stacks.nim` header: each character resolved down font stack of its element,
##   against font faces page ships, as CSS Fonts 4 matches family and weight; what `found.json`
##   holds for each page; and verdict `koch drive` gives over it, control page included.
##   Files are built here (`fixtures.nim`) into temporary folder, so suite needs no network.

{.experimental: "strictFuncs".}

import std/[algorithm, json, os, sequtils, strutils, tempfiles, unittest]
import ./fixtures
import ../../src/[assets, font_stacks]


const
  OMEGA = 0x3A9  ## Greek capital omega, which Latin font faces lack.
  ARROW = 0x2192  ## Rightwards arrow, which text font faces often lack.
  E_ACUTE = 0xE9  ## Latin small e with acute, which Latin font faces hold.
  PROJECT = "contributor/test/project"  ## Project checked, relative to temporary root.


proc writeFontFace(directory, name: string, codepoints: openArray[Slice[int]]): string =
  ## Write TrueType file mapping `codepoints` into `directory`, and return its name.
  writeFile(directory / name, fileFontFace(codepoints))
  name


func rule(family, weight, file: string, range = ""): JsonNode =
  ## Render one `@font-face` rule as browser part writes it.
  %*{"family": family, "weight": weight, "range": range, "file": file}


func page(
  stack: string, weight: int, codepoints: openArray[int], declared: openArray[JsonNode],
  element = "p"
): JsonNode =
  ## Render `written.json` of one page `index`, drawing one run.
  %*{"index": {
    "runs": [{"element": element, "stack": stack, "weight": weight, "codepoints": codepoints}],
    "declared": declared,
    "refused": [],
  }}


func charactersFound(found: JsonNode): seq[int] =
  ## Read codepoints `found.json` reports for page `index`, sorted.
  found["index"]["characters"].getElems.mapIt(it["codepoint"].getInt).sorted


func control(skipped: openArray[int] = []): JsonNode =
  ## Render control page as collector writes it, each numeral in run of its own, but `skipped`.
  result = %*{"runs": [], "declared": [], "refused": []}
  for (codepoint, place) in NUMERALS_CONTROL:
    if codepoint in skipped: continue
    result["runs"].add %*{
      "element": place, "stack": "serif", "weight": 400, "codepoints": [codepoint],
    }


func foundControl(skipped: openArray[int] = []): JsonNode =
  ## Render what `found.json` holds for control page, each numeral found but `skipped`.
  var characters = newJArray()
  for (codepoint, place) in NUMERALS_CONTROL:
    if codepoint notin skipped: characters.add %*{"element": place, "codepoint": codepoint}
  %*{"characters": characters, "refused": []}


suite "Font stacks":
  let directory = createTempDir("delegations_", "_font_stacks")
  let
    sans = directory.writeFontFace("sans.ttf", [0x20 .. 0x7E, E_ACUTE .. E_ACUTE])
    math = directory.writeFontFace("math.ttf", [OMEGA .. OMEGA, ARROW .. ARROW])


  test "character first family lacks falls to next family page ships, and is drawn":
    let found = page(
      "\"Noto Sans\", \"Noto Sans Math\", sans-serif", 400, [E_ACUTE, OMEGA, ARROW],
      [rule("Noto Sans", "400", sans), rule("Noto Sans Math", "400", math)],
    ).toFound(directory)
    check found.charactersFound.len == 0


  test "end of stack, generic family included, is font face of system":
    let found = page(
      "\"Noto Sans\", sans-serif", 400, [E_ACUTE, OMEGA], [rule("Noto Sans", "400", sans)],
    ).toFound(directory)
    check found.charactersFound == @[OMEGA]
    check found["index"]["characters"][0]["element"].getStr == "p"


  test "family page does not ship ends search, whatever stands after it (Article X.8)":
    # Viewer whose machine holds `Inter` sees its glyph, though `Noto Sans Math` would draw it.
    let found = page(
      "Inter, \"Noto Sans Math\"", 400, [OMEGA], [rule("Noto Sans Math", "400", math)],
    ).toFound(directory)
    check found.charactersFound == @[OMEGA]


  test "family matches without case and without quotes":
    let found = page(
      "\"noto sans math\"", 400, [OMEGA], [rule("'Noto Sans Math'", "400", math)],
    ).toFound(directory)
    check found.charactersFound.len == 0


  test "weight no rule holds moves to bound CSS Fonts 4 picks":
    # Each rule maps one marker, so marker drawn names weight matching settled on.
    var markers: seq[(int, string)]
    for weight in [300, 400, 500, 600, 700]:
      markers.add (0x4E00 + weight, directory.writeFontFace(
        "weight" & $weight & ".ttf", [0x4E00 + weight .. 0x4E00 + weight]))

    proc matched(wanted: int, declared: openArray[int]): int =
      ## Resolve every marker at `wanted`, and return weight whose marker is drawn.
      let
        rules = markers.filterIt(it[0] - 0x4E00 in declared)
        found = page(
          "Test", wanted, rules.mapIt(it[0]), rules.mapIt(rule("Test", $(it[0] - 0x4E00), it[1])),
        ).toFound(directory)
        drawn = rules.mapIt(it[0]).filterIt(it notin found.charactersFound)
      check drawn.len == 1
      drawn[0] - 0x4E00

    check matched(600, [400, 700]) == 700  # past 500, upward first
    check matched(800, [400, 700]) == 700  # past 500, downward where nothing stands above
    check matched(450, [300, 500]) == 500  # inside 400 to 500, upward to 500 first
    check matched(450, [300, 600]) == 300  # then downward, before past 500
    check matched(450, [600]) == 600  # then upward past 500
    check matched(350, [300, 400]) == 300  # below 400, downward first
    check matched(350, [400, 700]) == 400  # then upward


  test "rule whose weight range holds weight wanted serves it":
    let found = page(
      "Test", 500, [OMEGA], [rule("Test", "400 600", math)],
    ).toFound(directory)
    check found.charactersFound.len == 0
    check page("Test", 700, [OMEGA], [rule("Test", "bold", math)]).toFound(directory)
      .charactersFound.len == 0  # keyword `bold` is `700`


  test "where two sets hold weight wanted, each set or family after it must draw":
    # Browser picks one of two tied sets by its own rule, so neither may be trusted alone.
    let
      tied = [rule("Test", "400", sans), rule("Test", "400 600", math)]
      alone = page("Test", 400, [E_ACUTE, OMEGA], tied).toFound(directory)
      covered = page(
        "Test, Fallback", 400, [E_ACUTE, OMEGA],
        @tied & @[rule("Fallback", "400", sans), rule("Fallback", "400", math)],
      ).toFound(directory)
    check alone.charactersFound == @[E_ACUTE, OMEGA]  # each set lacks what other holds
    check covered.charactersFound.len == 0  # family after them draws both


  test "unicode-range limits its rule, and wildcard spans each hex digit it stands for":
    let
      narrow = page(
        "Test", 400, [OMEGA], [rule("Test", "400", math, "U+0-FF")],
      ).toFound(directory)
      wildcard = page(
        "Test", 400, [OMEGA], [rule("Test", "400", math, "U+3??")],
      ).toFound(directory)
      segmented = page(
        "Test", 400, [E_ACUTE, OMEGA],
        [rule("Test", "400", sans, "U+0-FF"), rule("Test", "400", math, "U+370-3FF, U+2190-21FF")],
      ).toFound(directory)
    check narrow.charactersFound == @[OMEGA]  # file maps it, range leaves it out
    check wildcard.charactersFound.len == 0  # `U+3??` is `300` to `3ff`
    check segmented.charactersFound.len == 0  # rules of one weight form one set


  test "character is found once for each element, and refused font faces are copied":
    var written = page(
      "Test", 400, [OMEGA], [rule("Test", "400", sans)], element = "h1#title",
    )
    written["index"]["runs"].add %*{
      "element": "h1#title", "stack": "Other", "weight": 700, "codepoints": [OMEGA],
    }
    written["index"]["refused"] = %*[{"family": "Test", "weight": "400", "status": "error"}]
    let found = written.toFound(directory)
    check found["index"]["characters"].len == 1
    check found["index"]["refused"][0]["status"].getStr == "error"


  removeDir(directory)


suite "Font faces judged":
  test "control page holds each numeral in its own kind of place, in ASCII source":
    let html = pageControl()
    check "<p id=\"paragraph\">&#x4E00;</p>" in html  # paragraph
    check "placeholder=\"&#x4E8C;\"" in html  # placeholder of field
    check "#before::before { content: \"\\4E09\"; }" in html  # `::before`
    check ">&#x56DB;</text></svg>" in html  # SVG text
    check "String.fromCodePoint(0x4E94)" in html  # script builds numeral five on load
    check html.count("4E94") == 1  # nowhere else, so it stands only once script runs
    check html.allIt(it.ord < 0x80)
    check NUMERALS_CONTROL.mapIt(it[0]) == @[0x4E00, 0x4E8C, 0x4E09, 0x56DB, 0x4E94]


  test "no font face of store maps numeral of control page (Article X.8)":
    # So each numeral collector reads is found, whatever font faces project ships.
    for (file, _, _, ranges) in ASSETS:
      for (codepoint, place) in NUMERALS_CONTROL:
        if ranges.toRanges.anyIt(codepoint in it):
          checkpoint "`" & file & "` maps numeral in " & place & "."
        check not ranges.toRanges.anyIt(codepoint in it)


  test "character page other than control draws from font face of system is finding":
    let found = %*{
      "index": {"characters": [{"element": "p.note", "codepoint": E_ACUTE}], "refused": []},
      "control": foundControl(),
    }
    let verdict = found.toVerdict("written.json")
    check verdict.len == 1
    check "`index`: `p.note` draws `U+00E9`" in verdict[0].message
    check verdict[0].path == "written.json"


  test "font face browser refused is finding, on any page":
    var found = %*{"index": {"characters": [], "refused": [
      {"family": "Noto Sans", "weight": 700, "status": "error"},
    ]}}
    found["control"] = foundControl()
    let verdict = found.toVerdict("written.json")
    check verdict.len == 1
    check "`Noto Sans` at weight `700`, status `error`" in verdict[0].message


  test "control page holding each numeral passes, and its characters are no finding":
    check (%*{"index": {"characters": [], "refused": []}, "control": foundControl()})
      .toVerdict("written.json").len == 0


  test "numeral control page lacks is finding naming place collector skips":
    let verdict = (%*{"control": foundControl(skipped = [0x4E09])}).toVerdict("written.json")
    check verdict.len == 1
    check "`U+4E09` in `::before` uncollected" in verdict[0].message


  test "written file without control page is finding":
    let verdict = (%*{"index": {"characters": [], "refused": []}}).toVerdict("written.json")
    check verdict.len == 1
    check "page `control`" in verdict[0].message


  test "control page is written into folder of font faces of project":
    let root = createTempDir("delegations_", "_font_faces")
    writeControl(root, PROJECT)
    check readFile(root / PROJECT / DIRECTORY_FONT_FACES / FILE_CONTROL) == pageControl()
    removeDir(root)


  test "project writing no written file is not reported yet (CURATOR.md duty 3)":
    # Report would redden every project before any can port; it follows ports.
    let root = createTempDir("delegations_", "_font_faces")
    createDir(root / PROJECT)
    check checkFontFaces(root, PROJECT).len == 0
    check not fileExists(root / PROJECT / DIRECTORY_FONT_FACES / FILE_FOUND)
    removeDir(root)


  test "written file resolves into found file beside it, and is judged":
    # Worked example: page draws é in font face it ships; collector reads every place but one.
    let
      root = createTempDir("delegations_", "_font_faces")
      folder = root / PROJECT / DIRECTORY_FONT_FACES
    createDir(folder)
    let sans = folder.writeFontFace("sans.ttf", [0x20 .. 0x7E, E_ACUTE .. E_ACUTE])
    var written = page("\"Noto Sans\"", 400, [E_ACUTE], [rule("Noto Sans", "400", sans)])
    written["control"] = control()
    writeFile(folder / FILE_WRITTEN, $written)
    check checkFontFaces(root, PROJECT).len == 0
    check readFile(folder / FILE_FOUND).endsWith("\n")
    check parseFile(folder / FILE_FOUND).charactersFound.len == 0  # relative file read

    written["control"] = control(skipped = [0x56DB])
    writeFile(folder / FILE_WRITTEN, $written)
    let verdict = checkFontFaces(root, PROJECT)
    check verdict.len == 1
    check "in SVG text uncollected" in verdict[0].message
    check verdict[0].path == PROJECT / DIRECTORY_FONT_FACES / FILE_WRITTEN
    removeDir(root)


  test "file absent, or page breaking shape, is finding naming what broke":
    let
      root = createTempDir("delegations_", "_font_faces")
      folder = root / PROJECT / DIRECTORY_FONT_FACES
    createDir(folder)
    writeFile(
      folder / FILE_WRITTEN, $page("Test", 400, [OMEGA], [rule("Test", "400", "absent.ttf")]),
    )
    let absent = checkFontFaces(root, PROJECT)
    check absent.len == 1
    check "absent.ttf" in absent[0].message
    writeFile(folder / FILE_WRITTEN, """{"index": {"runs": [{"element": "p"}]}}""")
    check checkFontFaces(root, PROJECT).len == 1  # run without stack
    writeFile(folder / FILE_WRITTEN, "[]")
    check checkFontFaces(root, PROJECT).len == 1  # pages are object, never list
    removeDir(root)
