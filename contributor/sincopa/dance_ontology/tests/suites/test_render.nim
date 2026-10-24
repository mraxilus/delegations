## Hold page `drive` renders to skeleton publish host serves it in: one place for page, and no
## font family named.

{.experimental: "strictFuncs".}

import std/[strutils, unittest]

import ../../design/render



suite "Internal: Page as host serves it":
  test "page sits inside host's skeleton, which names no font family":
    let page = hosted("<p>x</p>")
    check page.startsWith("<!doctype html>")
    check page.find("<body>") < page.find("<p>x</p>")
    check page.find("<p>x</p>") < page.find("</body>")
    check "font" notin SKELETON_HOST[0] & SKELETON_HOST[1]
