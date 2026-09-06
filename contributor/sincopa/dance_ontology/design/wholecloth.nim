## Splice sim's data and panel program into whole-cloth page, and write it.
##
##   Page's markup lives in `mockups/wholecloth.html` (its own comment says why
##     it is mock-up rather than page project stands behind); its two scripts
##     are built products -- `turns.js` from `design/turns.nim`,
##     `wholecloth_turns.js` from `design/wholecloth_turns.nim` -- so this
##     program folds three files into one self-contained page, as page was
##     hand-written, and build driver runs it last:
##       wholecloth <dir>   reads <dir>/turns.js and <dir>/wholecloth_turns.js,
##                          writes <dir>/wholecloth.html
##   Each marker line is replaced by whole `<script>` element, data one keeping
##     `id="turns-sim"` page always had, so anything reading script by id still
##     finds it.
##   Markup was Nim string constant while repository read no markup kind; `Html`
##     is registered now, so mock-up is committed file read at run time.
##     Cost: markers were checked at compile time as well, since markup and
##       markers were both constants (Article IV.4); file read at run time can
##       carry no such check, so only run-time one is left.  It echoes marker
##       and refuses to write page without its data, which is what module's
##       first version kept it for.
##     Cost: path is relative to project directory, so this runs from there, as
##       build driver and testament both do.

{.experimental: "strictFuncs".}

import std/[os, strutils, unicode]


const
  MARKUP_PATH = "mockups" / "wholecloth.html"
    ## Committed mock-up this splices sim's data and panel program into.
  MARK_DATA = "{{turns_data}}"
    ## Marker line standing where sim's data script goes.
  MARK_SCRIPT = "{{turns_script}}"
    ## Marker line standing where panel program goes.


func spliced(markup, marker, element: string): string =
  ## Replace marker with script element; fail naming marker where it is absent.
  doAssert markup.count(marker) == 1,
    "Marker must stand once in markup; got `" & marker & "` " & $markup.count(marker) & " times."
  markup.replace(marker, element)


proc main() =
  ## Read markup and both scripts, splice them in, write page, and say so.
  doAssert paramCount() == 1, "Usage: wholecloth <dir>; got `" & $paramCount() & "` arguments."
  let
    dir = paramStr(1)
    data = readFile(dir / "turns.js")
    program = readFile(dir / "wholecloth_turns.js")
    page = readFile(MARKUP_PATH)
      .spliced(MARK_DATA, "<script id=\"turns-sim\">\n" & data & "</script>")
      .spliced(MARK_SCRIPT, "<script>\n" & program & "</script>")
    path = dir / "wholecloth.html"
  writeFile(path, page)
  echo "wrote ", path, ": ", page.runeLen, " characters"


main()
