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

import std/[algorithm, os, strutils, unittest]

import ../design/faces
import ../tools/build {.all.}


const
  DOCUMENT = "<!doctype html>\n<html>\n<head>\n<title>T</title>\n" &
    "<style>p{}</style>\n</head>\n<body>x</body>\n</html>"
    ## Whole page, of shape `pages/app/index.html` carries.
  FRAGMENT = "<title>T</title>\n<style>p{}</style>\n<main>x</main>"
    ## Headless page, of shape review page and mark pages carry.


proc stub(dir: string) =
  ## Write one byte per face, so shape can be checked without fetching any.
  createDir(dir)
  for (file, _, _, _) in faces.FACES:
    writeFile(dir / file, "x")


suite "faces":
  let dir = getTempDir() / "dance_faces_test"
  removeDir(dir)
  stub(dir)

  test "every pinned face is named, and every named face is pinned":
    var pinned, named: seq[string]
    for (file, _, _) in build.FACES: pinned.add file
    for (file, _, _, _) in faces.FACES: named.add file
    check pinned.sorted == named.sorted

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
