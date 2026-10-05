## Hold judge of `drive` to what harness found: each page to faces it ships, control to findings
## it expects, and host's skeleton to one place for page.
##
##   Harness itself needs node and browser, so `drive` runs it, and these laws read its output
##     as data written here. Every law fails where judge says other than what found holds.

{.experimental: "strictFuncs".}

import std/[json, os, strutils, unittest]

import ../../design/[faces, render]


const
  DIRECTORY = "build" / "hosted"  ## Directory pages are judged in, as `drive` names it.
  PATH_CONTROL = "tests" / "drive" / "control_faces.json"  ## Fixture control is built from.



suite "Internal: Judge of faces":
  test "codepoint is spelt as Unicode spells it, at least four digits":
    check codepointText(0x41) == "U+0041"
    check codepointText(0x2192) == "U+2192"
    check codepointText(0x1D400) == "U+1D400"


  test "control expects each character beyond ASCII that system draws, once":
    let paragraphs = paragraphsOf(parseFile(PATH_CONTROL))
    check paragraphs.len == 3
    check expectedOf(paragraphs) == @[
      (element: "p#han", codepoint: 0x4E2D), (element: "p#open", codepoint: 0x1D400)
    ]
    let twice = @[ParagraphControl(id: "x", text: "aé é", is_drawn_by_system: true)]
    check expectedOf(twice) == @[(element: "p#x", codepoint: 0xE9)]


  test "control is whole document in body stack, each paragraph with its own stack":
    let page = pageControl(paragraphsOf(parseFile(PATH_CONTROL)))
    check page.startsWith("<!doctype html>")
    check ("body { font-family: " & SANS_SERIF & "; }") in page
    check "<p id=\"han\">中</p>" in page
    check "<p id=\"open\" style=\"font-family: &quot;Noto Sans&quot;, sans-serif\">" in page


  test "character page draws with face of system fails, naming page, element and codepoint":
    let
      found = parseJson("""{"design-frames": {"characters": [
        {"element": "svg > text.name", "codepoint": 8644}], "faces": []},
        "control_faces": {"characters": [{"element": "p#han", "codepoint": 20013}],
        "faces": []}}""")
      expected = @[(element: "p#han", codepoint: 0x4E2D)]
      findings = checkRendered(found, expected, CONTROL, DIRECTORY)
    check findings.len == 1
    check findings[0].path == DIRECTORY / "design-frames.html"
    check findings[0].message ==
        "svg > text.name: Character drawn by face of system; got `U+21C4`."
    check findings[0].render.startsWith(DIRECTORY / "design-frames.html:0: ")


  test "control that raises every finding it expects, and no other, passes":
    let found = parseJson("""{"control_faces": {"characters": [
      {"element": "p#han", "codepoint": 20013}, {"element": "p#open", "codepoint": 119808}],
      "faces": []}}""")
    let expected = expectedOf(paragraphsOf(parseFile(PATH_CONTROL)))
    check checkRendered(found, expected, CONTROL, DIRECTORY).len == 0


  test "control that misses finding it expects reads as blind":
    let
      found = parseJson("""{"control_faces": {"characters": [
        {"element": "p#han", "codepoint": 20013}], "faces": []}}""")
      expected = expectedOf(paragraphsOf(parseFile(PATH_CONTROL)))
      findings = checkRendered(found, expected, CONTROL, DIRECTORY)
    check findings.len == 1
    check findings[0].path == DIRECTORY / CONTROL & ".html"
    check "p#open: Check is blind" in findings[0].message
    check "`U+1D400`" in findings[0].message


  test "control finding it does not expect fails, as on any page":
    let
      found = parseJson("""{"control_faces": {"characters": [
        {"element": "p#closed", "codepoint": 119808}], "faces": []}}""")
      findings = checkRendered(found, @[], CONTROL, DIRECTORY)
    check findings.len == 2
    check findings[0].message ==
        "p#closed: Character drawn by face of system; got `U+1D400`."
    check "render proves nothing" in findings[1].message


  test "face browser does not load fails, naming family and weight":
    let
      found = parseJson("""{"design-rig": {"characters": [], "faces": [
        {"family": "Noto Serif", "weight": "600", "status": "error"}]}}""")
      findings = checkRendered(found, @[], CONTROL, DIRECTORY)
    check findings[0].path == DIRECTORY / "design-rig.html"
    check findings[0].message == "@font-face Noto Serif 600: Face does not load; got `error`."


  test "page sits inside host's skeleton, which names no face":
    let page = hosted("<p>x</p>")
    check page.startsWith("<!doctype html>")
    check page.find("<body>") < page.find("<p>x</p>")
    check page.find("<p>x</p>") < page.find("</body>")
    check "font" notin SKELETON_HOST[0] & SKELETON_HOST[1]
