## Wrap each page `drive` renders in skeleton publish host serves it in, so charset and viewport
## are what viewer gets.
##   Host's style sheet is left out: its body stack leads with font families of system, which no
##     file here may name (X.8). Nothing is lost: element that inherits no stack from page takes
##     browser's default, also font family of system, so `koch drive` finds it either way.
##   Findings on font faces are `koch drive`'s (CONTRIBUTOR.md, Pages and assets): harness
##     (`tools/drive/`) writes what it reads, and nothing here judges it.

{.experimental: "strictFuncs".}


const SKELETON_HOST* = (
  "<!doctype html><html><head><meta charset=utf8><meta name=viewport " &
      "content=\"width=device-width,initial-scale=1,viewport-fit=cover\"></head><body>\n",
  "\n</body></html>",
)
  ## Document skeleton publish host wraps page in: opening, then closing.
  ##   Read off Reference, version 11, as published on 2026-10-05, with host's style
  ##     sheet left out, as module's head says why. Host's own, so it can change under us.


func hosted*(page: string): string =
  ## Wrap built page in skeleton publish host serves it in, as `drive` renders it.
  SKELETON_HOST[0] & page & SKELETON_HOST[1]
