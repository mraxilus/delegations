## Replicate `font_stacks.nim` header: each character resolved down font stack of its element,
##   against font faces page ships, as CSS Fonts 4 matches family and weight; and what
##   `found.json` holds for each page.
##   Files are built here (`fixtures.nim`) into temporary folder, so suite needs no network.

{.experimental: "strictFuncs".}

import std/[algorithm, json, os, sequtils, strutils, tempfiles, unittest]
import ./fixtures
import ../../src/font_stacks


const
  OMEGA = 0x3A9  ## Greek capital omega, which Latin font faces lack.
  ARROW = 0x2192  ## Rightwards arrow, which text font faces often lack.


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


suite "Font stacks":
  let directory = createTempDir("delegations_", "_font_stacks")
  let
    sans = directory.writeFontFace("sans.ttf", [0x20 .. 0x7E, 0xE9 .. 0xE9])
    math = directory.writeFontFace("math.ttf", [OMEGA .. OMEGA, ARROW .. ARROW])


  test "character first family lacks falls to next family page ships, and is drawn":
    let found = page(
      "\"Noto Sans\", \"Noto Sans Math\", sans-serif", 400, [0xE9, OMEGA, ARROW],
      [rule("Noto Sans", "400", sans), rule("Noto Sans Math", "400", math)],
    ).toFound(directory)
    check found.charactersFound.len == 0


  test "end of stack, generic family included, is font face of system":
    let found = page(
      "\"Noto Sans\", sans-serif", 400, [0xE9, OMEGA], [rule("Noto Sans", "400", sans)],
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
      alone = page("Test", 400, [0xE9, OMEGA], tied).toFound(directory)
      covered = page(
        "Test, Fallback", 400, [0xE9, OMEGA],
        @tied & @[rule("Fallback", "400", sans), rule("Fallback", "400", math)],
      ).toFound(directory)
    check alone.charactersFound == @[0xE9, OMEGA]  # each set lacks what other holds
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
        "Test", 400, [0xE9, OMEGA],
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


  test "file reads from folder of written file where its path is relative":
    let
      path_written = directory / "written.json"
      path_found = directory / "found.json"
    writeFile(path_written, $page("Test", 400, [OMEGA], [rule("Test", "400", math)]))
    check writeFound(path_written, path_found).len == 0
    check parseFile(path_found).charactersFound.len == 0
    check readFile(path_found).endsWith("\n")


  test "file absent, or page breaking shape, is finding naming what broke":
    let
      path_written = directory / "written.json"
      path_found = directory / "found.json"
    writeFile(path_written, $page("Test", 400, [OMEGA], [rule("Test", "400", "absent.ttf")]))
    let absent = writeFound(path_written, path_found)
    check absent.len == 1
    check "absent.ttf" in absent[0].message
    writeFile(path_written, """{"index": {"runs": [{"element": "p"}]}}""")
    check writeFound(path_written, path_found).len == 1  # run without stack
    writeFile(path_written, "[]")
    check writeFound(path_written, path_found).len == 1  # pages are object, never list


  removeDir(directory)
