## Ship faces every page draws with, inlined, so page names none viewer may lack.
##
##   Article X.8 asks presentation target to ship its faces.  Pages here are opened
##     from `build/`, from published artefact and from file, none of which can be
##     relied on to reach font host, so bytes travel inside page as data URI rather
##     than as link to one.
##     Cost of inlining: every page carries same 223 kB of base64, measured, whatever
##       of it that page uses.  Rejected: linking host's copy, which names face
##       viewer may lack and needs network at reading time; rejected: subsetting per
##       page, which trades one shared block for five that drift.
##   Faces themselves are fetched and pinned by `tools/build.nim`, verb `assets`;
##     this module only reads what that wrote, and says so loudly when it is absent,
##     because page drawn without them is page nobody can compare with another.
##   Ligatures are why `contextual` is set at root: Commit Mono carries its
##     ligatures in `calt` rather than in `liga`, and `calt` is on by default only
##     until some rule sets `font-variant-ligatures` otherwise.  Setting it here
##     costs nothing on Noto, whose `liga` is unaffected, and makes ligature
##     survive any later reset.

{.experimental: "strictFuncs".}

import std/[base64, os, strutils]


const
  DIR_FONTS* = "build" / "fonts"
    ## Directory `assets` writes faces into, read from project directory.
  FACES* = [
    ("noto-serif-latin-400-normal.woff2", "Noto Serif", "400", "normal"),
    ("noto-serif-latin-600-normal.woff2", "Noto Serif", "600", "normal"),
    ("noto-serif-latin-400-italic.woff2", "Noto Serif", "400", "italic"),
    ("noto-sans-latin-400-normal.woff2", "Noto Sans", "400", "normal"),
    ("noto-sans-latin-600-normal.woff2", "Noto Sans", "600", "normal"),
    ("commit-mono-latin-400-normal.woff2", "Commit Mono", "400", "normal"),
    ("commit-mono-latin-700-normal.woff2", "Commit Mono", "700", "normal"),
  ]
    ## Each face with family, weight and style it answers to.  Rows match `FACES` in
    ##   `tools/build.nim`, which pins their bytes; that table is what to change to
    ##   add one, and this is what to change to name it.
  SERIF* = "\"Noto Serif\", Georgia, \"Times New Roman\", serif"
    ## Titles.  Fallback is only for face that failed to load, never for one absent.
  SANS* = "\"Noto Sans\", ui-sans-serif, system-ui, sans-serif"
    ## Body text.
  MONO* = "\"Commit Mono\", ui-monospace, SFMono-Regular, Menlo, monospace"
    ## Code, data and figures.


proc faceStyle*(dir = DIR_FONTS): string =
  ## Build `<style>` holding every face inlined, and root that keeps ligatures on.
  ##   Raises where face is missing, rather than writing page that silently falls
  ##     back to whatever machine building it happens to carry.
  var rules: seq[string]
  for (file, family, weight, style) in FACES:
    let path = dir / file
    if not fileExists(path):
      raise newException(IOError,
        "Face is absent, so page would name one reader may lack; run " &
          "`nim r tools/build.nim assets`: got `" & path & "`.")
    rules.add "@font-face{font-family:\"" & family & "\";font-style:" & style &
      ";font-weight:" & weight & ";font-display:block;src:url(data:font/woff2;base64," &
      encode(readFile(path)) & ") format(\"woff2\")}"
  "<style>" & rules.join("\n") & "\n:root{font-variant-ligatures:contextual}</style>"


proc withFaces*(html: string; dir = DIR_FONTS): string =
  ## Put face style sheet last in page's head, so page ships what it draws with.
  ##   Last rather than first for two reasons: root rule keeping ligatures on then
  ##     wins over any page rule that would turn them off, and `bundle` folds head
  ##     from title to final style block, so faces put before title would be
  ##     dropped from published page exactly where they are wanted most.
  ##   Two page shapes reach here.  Whole document takes faces last in its head.
  ##     Fragment takes them after its title, since publishing wraps it in head of
  ##     its own and there is none here to put them in; nothing in these pages sets
  ##     `font-variant-ligatures`, so order costs nothing either way.
  const
    SHUT = "</head>"
    TITLE = "</title>"
  let shuts = html.find(SHUT)
  if shuts >= 0:
    return html[0 ..< shuts] & faceStyle(dir) & "\n" & html[shuts .. ^1]
  let titled = html.find(TITLE)
  if titled < 0:
    raise newException(ValueError,
      "Page carries neither head nor title to put faces by; got first 40 " &
        "characters `" & html[0 ..< min(40, html.len)] & "`.")
  html[0 ..< titled + TITLE.len] & "\n" & faceStyle(dir) & html[titled + TITLE.len .. ^1]
