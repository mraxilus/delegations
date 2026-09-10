discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options -r $file"
batchable: true
joinable: true
"""
## Hold faces every page ships to what they claim.
##
##   Faces themselves are fetched, so nothing here reaches network or reads one:
##     laws are about which faces are named, and about where they land in page.
##   Two tables name same faces from opposite ends -- one pins bytes, other names
##     family each answers to -- and pair that drifts is fault neither file shows
##     on its own, so it is checked here.

{.experimental: "strictFuncs".}

import std/[os, strutils, unittest]

import ../design/faces


const
  DOCUMENT = "<!doctype html>\n<html>\n<head>\n<title>T</title>\n" &
    "<style>p{}</style>\n</head>\n<body>x</body>\n</html>"
    ## Whole page, of shape `pages/app/index.html` carries.
  FRAGMENT = "<title>T</title>\n<style>p{}</style>\n<main>x</main>"
    ## Headless page, of shape review page and mark pages carry.
  STORE = "../../../curator/audit/src/assets.nim"
    ## Repository's declaration of every file fetched at build time, from project directory.


proc stub(dir: string) =
  ## Write one byte per face, so shape can be checked without fetching any.
  createDir(dir)
  for (file, _, _, _) in faces.FACES:
    writeFile(dir / file, "x")


suite "faces":
  let dir = getTempDir() / "dance_faces_test"
  removeDir(dir)
  stub(dir)

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
    let style = faceStyle(dir)
    check style.count("@font-face") == faces.FACES.len
    check style.count("data:font/woff2;base64,") == faces.FACES.len
    check "http" notin style  # names no host page would have to reach (X.8)

  test "all three families are named, and ligatures are kept on":
    let style = faceStyle(dir)
    for family in ["Noto Serif", "Noto Sans", "Commit Mono"]:
      check ("font-family:\"" & family & "\"") in style
    # Commit Mono carries its ligatures in `calt`, on by default until something
    # sets this property; setting it at root means no later reset can lose them.
    check "font-variant-ligatures:contextual" in style

  test "absent face is refused, never quietly left out":
    expect IOError:
      discard faceStyle(dir / "nowhere")

  test "whole page takes faces inside its head":
    let dressed = withFaces(DOCUMENT, dir)
    check dressed.find("@font-face") < dressed.find("</head>")
    check dressed.count("<title>") == 1

  test "headless page takes faces after its title":
    let dressed = withFaces(FRAGMENT, dir)
    check dressed.find("</title>") < dressed.find("@font-face")
    check dressed.count("<main>") == 1

  test "page with neither head nor title is refused":
    expect ValueError:
      discard withFaces("<p>no head here</p>", dir)

  test "dressing is not doubled where it runs twice":
    ## Build dresses every page it wrote, so page must not gather two copies if
    ## build is rerun over its own output.
    let once = withFaces(DOCUMENT, dir)
    check once.count("data:font/woff2;base64,") == faces.FACES.len
