## Name palette, and one stroke width connection is drawn at.
##
##   Colours come through custom properties **with fallbacks**: inside page
##     that defines them, picture follows page, light and dark themes
##     included, and on its own it still draws in ink somebody chose.
##     Fallback used to be left off, on grounds that these pictures
##       only ever appeared on workbench's own pages.  They do not:
##       app writes each frame out as standalone file for `doc/frames/`, to
##       be shown on grounds this module cannot see, and `tests/treview`
##       holds every colour to naming property *and* fallback.
##     Cost of fallback: on its own picture is tuned to neither ground,
##       only readable on either.  Accepted -- standalone file cannot know
##       ground it will be shown on.
##   Values are ones workbench settled on and are repeated in
##     two places that define properties, `design/page.nim` and
##     `app/index.html`.  Repeated on purpose: fallback is what reader
##     gets when nothing defines them, so it cannot itself be reference.
##   Each side has two shades of one hue -- plain for follow, deep
##     for lead -- so connection says whose end is whose along its own
##     length without second mark (rule 9).

{.experimental: "strictFuncs".}

import ./terms


const
  QUIET* = "var(--rule-strong, #c2bbb0)"
    ## Neutral stroke: rims, chevrons, rings.
  FAINT* = "var(--faint, #948d85)"
    ## Caption text.

const
  INK*: array[Arm, string] = [
    "var(--left, #3d7fd0)", "var(--right, #d0763d)"]
    ## Plain shade of each side's hue: follow's.
  DEEP*: array[Arm, string] = [
    "var(--left-deep, #133a72)", "var(--right-deep, #723a13)"]
    ## Deep shade of each side's hue: lead's.

const
  LINK_W* = 3.4          ## Connection's stroke width.
  CAP* = LINK_W / 2      ## How far round cap reaches past endpoint.
