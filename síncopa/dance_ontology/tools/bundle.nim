## Fold page's script into its markup, as one file that carries whole page.
##   Usage: `bundle <dir> <name>` reads `<dir>/index.html` and `<dir>/<name>.js`, writes
##     `<dir>/artifact.html`.
##   Bundle drops document wrapper as well: it is written to be embedded in page that
##     supplies its own, which is what publishing it expects.
##   Published page is titled for body of work as well as for itself, so gallery holding
##     several sorts them together; page served locally keeps its own plain name.
##   Cost: runs once per build, so no hot path exists (unmeasured).

{.experimental: "strictFuncs".}

import std/[os, strutils]


const TITLE_PREFIX = "Dance Ontology — "
  ## Prefix published page's title carries, so gallery sorts body of work together.


proc bundle(dir, name: string) =
  ## Write `<dir>/artifact.html` from markup and script beside it.
  let
    markup = readFile(dir / "index.html")
    script = readFile(dir / (name & ".js"))
    tag = "<script src=\"" & name & ".js\"></script>"
  var head = markup[markup.find("<title>") .. markup.find("</style>") + 7]
  head = head.replace("<title>", "<title>" & TITLE_PREFIX)
  var body = markup[markup.find("<body>") + 6 ..< markup.find("</body>")]
  doAssert body.contains(tag),
    "Markup should load its script as bundle expects; got `" & dir / "index.html" & "`."
  body = body.replace(tag, "<script>\n" & script & "\n</script>")
  writeFile(dir / "artifact.html", head & body)
  echo "wrote ", dir / "artifact.html"


when isMainModule:
  doAssert paramCount() == 2, "Usage: bundle <dir> <name>; got `" & $paramCount() & "` arguments."
  bundle(paramStr(1), paramStr(2))
