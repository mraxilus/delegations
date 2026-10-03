## Hold faces every page ships to what they claim, and every sheet to faces it names.
##
##   Faces themselves are fetched, so nothing here reaches network or reads one:
##     laws are about which faces are named, and about where they land in page.
##   Two tables name same faces from opposite ends -- one pins bytes, other names
##     family each answers to -- and pair that drifts is fault neither file shows
##     on its own, so it is checked here.
##   Sheets are read as text, rule by rule, and never rendered.  Cost: which face draws
##     each codepoint is beyond them, so coverage is verified by hand and recorded with its
##     tool and date (`PROVENANCE.md`, Faces).

{.experimental: "strictFuncs".}

import std/[os, strutils, unittest]

import ../../design/[faces, page, parts]


const
  DOCUMENT = "<!doctype html>\n<html>\n<head>\n<title>T</title>\n" &
    "<style>p{}</style>\n</head>\n<body>x</body>\n</html>"
    ## Whole page, of shape `pages/app/index.html` carries.
  FRAGMENT = "<title>T</title>\n<style>p{}</style>\n<main>x</main>"
    ## Headless page, of shape review page and mark pages carry.
  STORE = "../../../curator/audit/src/assets.nim"
    ## Repository's declaration of every file fetched at build time, from project directory.
  PATH_APP = "pages" / "app" / "index.html"  ## Shell of Reference, whose sheet sits in its head.
  PATH_REVIEW = "pages" / "review" / "review.html"  ## Shell of review page.
  PATH_WHOLECLOTH = "mockups" / "wholecloth.html"  ## Whole-cloth proposal, drawn by hand.


proc stub(directory: string) =
  ## Write one byte per face, so shape can be checked without fetching any.
  createDir(directory)
  for (file, _, _, _) in faces.FACES:
    writeFile(directory / file, "x")


func stylesOf(markup: string): string =
  ## Join every `<style>` block of markup, comments cut, so no brace of script or comment
  ## reads as rule.
  var at = 0
  while true:
    let opens = markup.find("<style", at)
    if opens < 0: break
    let
      head = markup.find('>', opens)
      shuts = markup.find("</style>", head)
    if head < 0 or shuts < 0: break
    result.add markup[head + 1..<shuts] & "\n"
    at = shuts
  while true:
    let opens = result.find("/*")
    if opens < 0: return
    let shuts = result.find("*/", opens + 2)
    if shuts < 0: return result[0..<opens]
    result = result[0..<opens] & result[shuts + 2 .. ^1]


func declarationsOf(sheet, selector: string): seq[string] =
  ## Read every declaration of every rule whose selector list holds `selector` as written.
  ##   At-rule's block holds braces of its own, so reader steps into it and reads its rules.
  var
    start = 0
    at = 0
  while at < sheet.len:
    if sheet[at] == '}':
      start = at + 1
    elif sheet[at] == '{':
      let
        shuts = sheet.find('}', at + 1)
        nested = sheet.find('{', at + 1)
      if nested >= 0 and nested < shuts:
        start = at + 1
      else:
        for written in sheet[start..<at].split(','):
          if written.strip == selector:
            result.add sheet[at + 1..<shuts].split(';')
        start = shuts + 1
        at = shuts
    inc at


func familiesOf(stack: string): seq[string] =
  ## Split stack into its families, in order, quotes taken off.
  for family in stack.split(','):
    if family.strip.len > 0: result.add family.strip.strip(chars = {'"', '\''})


func stackOf(sheet, selector: string): seq[string] =
  ## Read families, in order, that last face declaration of `selector` names.
  ##   One custom property is resolved, as audit's faces check resolves one; shorthand
  ##     `font` gives its families after size, so stack starts at its first family.
  var value = ""
  for declaration in declarationsOf(sheet, selector):
    let parts = declaration.split(':', maxsplit = 1)
    if parts.len == 2 and parts[0].strip in ["font-family", "font"]:
      value = parts[1].strip
  let resolves = value.find("var(--")
  if resolves >= 0:
    let
      property = value[resolves + 4..<value.find(')', resolves)]
      defined = sheet.find(property & ":")
    value = if defined < 0: "" else: sheet[defined + property.len + 1..<sheet.find(';', defined)]
  elif value.find('"') > 0:
    value = value[value.find('"') .. ^1]
  familiesOf(value)



suite "faces":
  let directory = getTempDir() / "dance_faces_test"
  removeDir(directory)
  stub(directory)


  test "every face named here is one repository's store declares":
    ## Store holds digest and address, this project holds choice (repository issue 116),
    ## and pair has to meet somewhere.  It is checked here rather than left to build
    ## because this project carries no `drive` verb, so runner never runs its `assets`:
    ## face named that store lacks would otherwise surface only when somebody built pages
    ## by hand.  Read as text rather than imported, so this test depends on declaration
    ## and not on curator's module staying shaped as it is.
    check fileExists(STORE)
    let declared = readFile(STORE)
    for (file, _, _, _) in faces.FACES:
      checkpoint(file)
      check ("\"" & file & "\"") in declared


  test "each face is inlined once, as bytes rather than as link":
    let style = faceStyle(directory)
    check style.count("@font-face") == faces.FACES.len
    check style.count("data:font/woff2;base64,") == faces.FACES.len
    check "http" notin style  # names no host page would have to reach (X.8)


  test "every family is named, and ligatures are kept on":
    let style = faceStyle(directory)
    for family in ["Noto Serif", "Noto Sans", "Commit Mono", "Noto Sans Math"]:
      check ("font-family:\"" & family & "\"") in style
    # Commit Mono carries its ligatures in `calt`, on by default until something
    # sets this property; setting it at root means no later reset can lose them.
    check "font-variant-ligatures:contextual" in style


  test "absent face is refused, never quietly left out":
    expect IOError:
      discard faceStyle(directory / "nowhere")


  test "whole page takes faces inside its head":
    let dressed = withFaces(DOCUMENT, directory)
    check dressed.find("@font-face") < dressed.find("</head>")
    check dressed.count("<title>") == 1


  test "headless page takes faces after its title":
    let dressed = withFaces(FRAGMENT, directory)
    check dressed.find("</title>") < dressed.find("@font-face")
    check dressed.count("<main>") == 1


  test "page with neither head nor title is refused":
    expect ValueError:
      discard withFaces("<p>no head here</p>", directory)


  test "dressing is not doubled where it runs twice":
    ## Build dresses every page under `build/`, and not only pages this run wrote,
    ## so page left there by earlier run is dressed again.  Law is that second
    ## dressing gives same page, and it was claimed here without ever dressing
    ## twice: `build/simulation/artifact.html` grew 223 kB on every `pages` run, from
    ## 10.9 MB toward limit published page has to stay under.
    for page in [DOCUMENT, FRAGMENT]:
      let
        once = withFaces(page, directory)
        twice = withFaces(once, directory)
      check once.count("data:font/woff2;base64,") == faces.FACES.len
      check twice.count("data:font/woff2;base64,") == faces.FACES.len
      check twice == once


  test "every heading takes serif face":
    ## X.8 gives headings and titles to Noto Serif, and record says pages follow it.  Heading
    ## rules of Reference and of shared sheet of workbench named no face, so every heading
    ## took body's Noto Sans (repository issue 391).
    for (sheet, selectors) in [
      (page.STYLE.stylesOf, @["h1", "h2", "h3"]),
      (readFile(PATH_APP).stylesOf, @["h1", "h2", "h3", "h4"]),
      (readFile(PATH_REVIEW).stylesOf, @["h1", "h2", "h3"]),
      (readFile(PATH_WHOLECLOTH).stylesOf, @["h1", "section.plate h2", ".panel h3"]),
    ]:
      for selector in selectors:
        checkpoint(selector)
        let families = stackOf(sheet, selector)
        check families.len > 0 and families[0] == "Noto Serif"


  test "every stack falls back to faces that draw what its own face lacks":
    ## Noto Sans and Noto Serif draw no arrow, and Commit Mono draws no `⇄`, read with
    ##   fontconfig 2.15.0 on 2026-10-02 from files of store's digests.  So pages drew
    ##   five arrows from whatever face their reader's machine had (repository issue 391).
    ##   Noto Sans Math draws all five, and Commit Mono draws `✓`, which other three lack.
    for (sheet, selectors) in [
      (page.STYLE.stylesOf, @["body", "h1", "code"]),
      (readFile(PATH_APP).stylesOf, @["body", "h1"]),
      (readFile(PATH_REVIEW).stylesOf, @["body", "h1", "code"]),
      (readFile(PATH_WHOLECLOTH).stylesOf, @["body", "h1", ".m"]),
    ]:
      for selector in selectors:
        checkpoint(selector)
        let families = stackOf(sheet, selector)
        check families.len >= 3 and families[1] == "Noto Sans Math"
        if families.len >= 3 and families[0] != "Commit Mono":
          check families[2] == "Commit Mono"
    for stack in [faces.SERIF, faces.SANS_SERIF, faces.MONOSPACE]:
      checkpoint(stack)
      let families = familiesOf(stack)
      check families.len >= 3 and families[1] == "Noto Sans Math"


  test "dressed page declares utf-8 ahead of its face block":
    ## Face block is half megabyte of ASCII, and browser that opens page from file guesses
    ## its charset from bytes ahead of first that is not ASCII.  Review page and whole-cloth
    ## page declared none, and Chromium 141 read both as windows-1250 on 2026-10-02 once
    ## block grew (repository issue 391).
    for page in [DOCUMENT, FRAGMENT]:
      checkpoint(page)
      let
        dressed = withFaces(page, directory)
        declared = dressed.find("<meta charset=\"utf-8\">")
      check declared >= 0 and declared < dressed.find("@font-face") and declared < 1024


  test "label of turn glyph names face pages ship":
    ## Its label named `ui-sans-serif` first, which no page ships, so `¼` and `½` came from
    ## reader's machine: Chromium 141 drew `¼` in DejaVu Sans on 2026-10-02 (repository
    ## issue 391).  Audit's faces check reads no stack built through `&`, as this one is.
    let
      glyph = turnGlyph("&#188; turn")
      opens = glyph.find("8px ") + "8px ".len
    check familiesOf(glyph[opens..<glyph.find(';', opens)])[0] == "Noto Sans"
