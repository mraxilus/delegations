## Ship faces every page draws with, inlined, so page names none viewer may lack.
##
##   Article X.8 asks presentation target to ship its faces.  Pages here are opened
##     from `build/`, from published artefact and from file, none of which can be
##     relied on to reach font host, so bytes travel inside page as data URI rather
##     than as link to one.
##     Cost of inlining: every page carries same 536 kB face block, whatever of it that
##       page uses, measured in `build/` on 2026-10-02; Noto Sans Math is 311 kB of it.
##       Rejected: linking host's copy, which names face viewer may lack and needs
##       network at reading time; rejected: subsetting per page, which trades one
##       shared block for five that drift.
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
  DIRECTORY_FONTS* = "build" / "fonts"
    ## Directory `assets` writes faces into, read from project directory.
  FACES* = [
    ("noto-serif-latin-400-normal.woff2", "Noto Serif", "400", "normal"),
    ("noto-serif-latin-600-normal.woff2", "Noto Serif", "600", "normal"),
    ("noto-serif-latin-400-italic.woff2", "Noto Serif", "400", "italic"),
    ("noto-sans-latin-400-normal.woff2", "Noto Sans", "400", "normal"),
    ("noto-sans-latin-600-normal.woff2", "Noto Sans", "600", "normal"),
    ("commit-mono-latin-400-normal.woff2", "Commit Mono", "400", "normal"),
    ("commit-mono-latin-700-normal.woff2", "Commit Mono", "700", "normal"),
    ("noto-sans-math-math-400-normal.woff2", "Noto Sans Math", "400", "normal"),
  ]
    ## Each face with family, weight and style it answers to.  Repository's store pins
    ##   bytes of each file by digest (`curator/audit/src/assets.nim`), and verb `assets`
    ##   of `tools/build.nim` fetches every row: row here is what to add to ship face.
    ##   Noto Sans Math draws arrows, which neither text face holds, and every stack names
    ##     it after its own face: merge by codepoint range (X.8).
    ##     Cost: its 311 kB is most of face block on every page, for five arrows.
    ##     Rejected: Commit Mono alone, which draws no `⇄`; another mark for `place`, which
    ##       would change design.
  FACES_MARK* = "<style data-faces>"
    ## Opening tag of face block, which names block so later run can find it.
    ##   Build dresses every page under `build/`, and not only pages it wrote, so
    ##     page earlier run left there arrives already dressed.  Marked block is
    ##     what lets dressing take old one out before it puts new one in.
  SERIF* = "\"Noto Serif\", \"Noto Sans Math\", \"Commit Mono\", Georgia, " &
    "\"Times New Roman\", serif"
    ## Titles.  Fallback is only for face that failed to load, never for one absent.
    ##   Noto Sans Math draws arrows, and Commit Mono marks such as `✓` that both lack.
  SANS_SERIF* = "\"Noto Sans\", \"Noto Sans Math\", \"Commit Mono\", ui-sans-serif, " &
    "system-ui, sans-serif"
    ## Body text, with same two faces after it as titles.
  MONOSPACE* = "\"Commit Mono\", \"Noto Sans Math\", ui-monospace, SFMono-Regular, " &
    "Menlo, monospace"
    ## Code, data and figures, with Noto Sans Math for `⇄`, which Commit Mono lacks.


proc faceStyle*(directory = DIRECTORY_FONTS): string =
  ## Build `<style>` holding every face inlined, and root that keeps ligatures on.
  ##   Raises where face is missing, rather than writing page that silently falls
  ##     back to whatever machine building it happens to carry.
  var rules: seq[string]
  for (file, family, weight, style) in FACES:
    let path = directory / file
    if not fileExists(path):
      raise newException(IOError,
        "Face is absent, so page would name one reader may lack; run " &
          "`nim r tools/build.nim assets`: got `" & path & "`.")
    rules.add "@font-face{font-family:\"" & family & "\";font-style:" & style &
      ";font-weight:" & weight & ";font-display:block;src:url(data:font/woff2;base64," &
      encode(readFile(path)) & ") format(\"woff2\")}"
  FACES_MARK & rules.join("\n") & "\n:root{font-variant-ligatures:contextual}</style>"


func withoutFaces*(html: string): string =
  ## Take every face block earlier dressing put in back out again.
  ##   Replaces rather than skips, so page dressed before face changed takes new
  ##     bytes rather than keeping old ones.
  result = html
  const shut = "</style>"
  while true:
    let opens = result.find(FACES_MARK)
    if opens < 0:
      break
    let shuts = result.find(shut, opens)
    if shuts < 0:
      break
    var cut_to = shuts + shut.len
    if cut_to < result.len and result[cut_to] == '\n':
      cut_to += 1
    result = result[0 ..< opens] & result[cut_to .. ^1]


proc withFaces*(raw: string; directory = DIRECTORY_FONTS): string =
  ## Put face style sheet last in page's head, so page ships what it draws with.
  ##   Last rather than first for two reasons: root rule keeping ligatures on then
  ##     wins over any page rule that would turn them off, and `bundle` folds head
  ##     from title to final style block, so faces put before title would be
  ##     dropped from published page exactly where they are wanted most.
  ##   Two page shapes reach here.  Whole document takes faces last in its head.
  ##     Fragment takes them after its title, since publishing wraps it in head of
  ##     its own and there is none here to put them in; nothing in these pages sets
  ##     `font-variant-ligatures`, so order costs nothing either way.
  ##   Block earlier run left is taken out first, so dressing twice gives
  ##     one page and not one that grows by every face on every build.
  const
    shut = "</head>"
    title = "</title>"
  let
    html = withoutFaces(raw)
    shuts = html.find(shut)
  if shuts >= 0:
    return html[0 ..< shuts] & faceStyle(directory) & "\n" & html[shuts .. ^1]
  let titled = html.find(title)
  if titled < 0:
    raise newException(ValueError,
      "Page carries neither head nor title to put faces by; got first 40 " &
        "characters `" & html[0 ..< min(40, html.len)] & "`.")
  html[0 ..< titled + title.len] & "\n" & faceStyle(directory) & html[titled + title.len .. ^1]
