## Splice sim's data and panel program into whole-cloth page, and write it.
##
##   Page's markup lives in `wholecloth_page` (its header says why); its two
##     scripts are built products -- `turns.js` from `design/turns.nim`,
##     `wholecloth_turns.js` from `design/wholecloth_turns.nim` -- so this
##     program folds three files into one self-contained page, as page was
##     hand-written, and `make pages` runs it last:
##       wholecloth <dir>   reads <dir>/turns.js and <dir>/wholecloth_turns.js,
##                          writes <dir>/wholecloth.html
##   Each marker line is replaced by whole `<script>` element, data one keeping
##     `id="turns-sim"` page always had, so anything reading script by id still
##     finds it.
##   Markers are checked at build time, since markup and markers are constants
##     (Article IV.4: invalid configuration fails statically); run-time check
##     stays too, echoing marker, so any future non-constant markup fails loudly
##     rather than writing page without its data.

{.experimental: "strictFuncs".}

import std/[os, strutils, unicode]

import ./wholecloth_page


static:
  for marker in [MARK_DATA, MARK_SCRIPT]:
    doAssert MARKUP.count(marker) == 1,
      "Marker must stand once in markup; got `" & marker & "` " & $MARKUP.count(marker) & " times."


func spliced(markup, marker, element: string): string =
  ## Replace marker with script element; fail naming marker where it is absent.
  doAssert markup.count(marker) == 1,
    "Marker must stand once in markup; got `" & marker & "` " & $markup.count(marker) & " times."
  markup.replace(marker, element)


proc main() =
  ## Read both scripts from directory, splice them in, write page there, and say so.
  doAssert paramCount() == 1, "Usage: wholecloth <dir>; got `" & $paramCount() & "` arguments."
  let
    dir = paramStr(1)
    data = readFile(dir / "turns.js")
    program = readFile(dir / "wholecloth_turns.js")
    page = MARKUP
      .spliced(MARK_DATA, "<script id=\"turns-sim\">\n" & data & "</script>")
      .spliced(MARK_SCRIPT, "<script>\n" & program & "</script>")
    path = dir / "wholecloth.html"
  writeFile(path, page)
  echo "wrote ", path, ": ", page.runeLen, " characters"


main()
