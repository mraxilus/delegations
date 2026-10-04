## Assemble page from committed shell: title, body and faces filled in, nothing else.
##   Every page this project publishes is one shell and one body. Shell is hand-written HTML in
##     `pages/shell.html`, committed and checked as any file is; body is rendered here from
##     committed files, so page says only what they say, and built page is one long line
##     under ignored `build/` (CONTRIBUTOR.md, "Pages and assets").
##   Shell carries tokens: `@TITLE@`, `@BODY@`, and one `@EMBED:<face>@` per face it draws
##     with. Faces are named here and fetched by `koch fetch-assets`, which checks each digest
##     against repository's store (`curator/audit/src/assets.nim`); bytes are inlined, so page
##     names no face viewer may lack (Article X.8).
##   Interaction is CSS: tabs, filters and toggles are inputs read by `:has()` rules, rows open
##     as `details`. Docket's search box alone runs script, constant text in `docket.nim`, so
##     build stays deterministic and digest of page is digest of what those files say.
##   Bar marks on bold maths letters, as `𝐜̱` and `𝐞̄`, are drawn by markup, as Architect ruled
##     on 2026-10-04: Noto Sans Math gives those letters no anchor for mark above or below, so
##     font leaves mark beside letter (`PROVENANCE.md`, Pages). `htmlMarked` boxes each such letter
##     with its marks; shell draws bar where font draws its own, and clips mark font left beside.
##
##   Cost: whole Noto faces inlined as base64 weigh about 4.4 MB in each page; published page
##     may hold sixteen megabytes.

{.experimental: "strictFuncs".}

import std/[base64, strutils, tables]
from std/unicode import runeAt, runeLenAt

import ../[changes, markdown]


const
  TOKEN_TITLE* = "@TITLE@"  ## Token page's title replaces.
  TOKEN_BODY* = "@BODY@"  ## Token rendered body replaces.
  TOKEN_EMBED* = "@EMBED:"  ## Opening of token one face replaces, closed by `@`.
  MARKS_UNDER = [0x0331, 0x0332]  ## Bar marks font draws under base: macron below, low line.
  MARKS_OVER = [0x0304, 0x0305]  ## Bar marks font draws over base: macron, overline.
  BOLD_FIRST = 0x1D400  ## First mathematical bold Latin letter, `𝐀`.
  BOLD_LAST = 0x1D433  ## Last mathematical bold Latin letter, `𝐳`.
  BOLD_LOWER = 0x1D41A  ## Mathematical bold small `𝐚`; capitals stand before it.
  LETTERS_TALL = "bdfhijklt"  ## Small letters whose ascender or dot rises over x-height.
  ELEMENTS_KEPT = ["svg", "script", "style"]  ## Elements whose content passes unmarked.
  FACES* = [
    "commit-mono-latin-400-normal.woff2",
    "NotoSans-Regular.ttf",
    "NotoSans-SemiBold.ttf",
    "NotoSansMath-Regular.ttf",
    "NotoSansSymbols2-Regular.ttf",
    "NotoSerif-SemiBold.ttf",
  ]
    ## Faces pages draw with: Article X.8's three families, plus maths and symbols.
    ##   Maths and symbols are what notation needs (`𝐆`, `⟑`, `★`).
    ##   Each Noto face ships whole, as TrueType of its own release, never as subset (X.8).
    ##     Commit Mono is no Noto, so its Latin subset stays.
    ##   Same six as `rga_visualiser` page, from same store.



#[ Assembly ]#

func facesAsked*(shell: string): seq[string] =
  ## List faces shell's embed tokens name, in order of first use.
  var at = shell.find(TOKEN_EMBED)
  while at >= 0:
    let close = shell.find('@', at + TOKEN_EMBED.len)
    if close < 0: break
    let face = shell[at + TOKEN_EMBED.len..<close]
    if face notin result: result.add face
    at = shell.find(TOKEN_EMBED, close + 1)


func mediaOf(face: string): string =
  ## Name media type data URL of `face` declares, read off its extension.
  ##   Type stated matches `format()` beside it in shell, so two never disagree about one file.
  if face.endsWith(".ttf"): "font/ttf"
  elif face.endsWith(".woff2"): "font/woff2"
  else: raise newException(ValueError, "Face is TrueType or WOFF2; got `" & face & "`.")


func htmlMarked*(html: string): string =
  ## Box each bold maths letter that carries bar marks, so shell draws bars where font cannot.
  ##   Letter and its marks go in one `mark` box, classed `under`, `over` and `tall`; mark stays
  ##     in text, so copy and search read what source says.
  ##   Word holding such letter goes in one `word` box, so no line breaks inside it.
  ##   Tags, attributes, and content of `svg`, `script` and `style` pass as they are.

  func isMark(code: int): bool =
    ## Tell whether code point is bar mark shell draws.
    code in MARKS_UNDER or code in MARKS_OVER

  func wordMarked(word: string): string =
    ## Box each marked bold letter of one word, and word itself where any is boxed.
    var
      at = 0
      is_boxed = false
    while at < word.len:
      let
        base = word.runeAt(at).int
        base_end = at + word.runeLenAt(at)
      var marks_end = base_end
      while marks_end < word.len and word.runeAt(marks_end).int.isMark:
        marks_end += word.runeLenAt(marks_end)
      if base in BOLD_FIRST..BOLD_LAST and marks_end > base_end:
        var
          classes = "mark"
          scan = base_end
          is_under, is_over = false
        while scan < marks_end:
          let mark = word.runeAt(scan).int
          if mark in MARKS_UNDER: is_under = true else: is_over = true
          scan += word.runeLenAt(scan)
        if is_under: classes.add " under"
        if is_over: classes.add " over"
        if base < BOLD_LOWER or char(ord('a') + base - BOLD_LOWER) in LETTERS_TALL:
          classes.add " tall"
        result.add "<span class=\"" & classes & "\">" & word[at ..< marks_end] & "</span>"
        is_boxed = true
      else:
        result.add word[at ..< marks_end]
      at = marks_end
    if is_boxed: result = "<span class=\"word\">" & result & "</span>"

  func textMarked(text: string): string =
    ## Mark each word of text between tags; whitespace passes as it is.
    var at = 0
    while at < text.len:
      if text[at] in Whitespace:
        result.add text[at]
        inc at
        continue
      var word_end = at
      while word_end < text.len and text[word_end] notin Whitespace: inc word_end
      result.add wordMarked(text[at ..< word_end])
      at = word_end

  var at = 0
  while at < html.len:
    let open = html.find('<', at)
    if open < 0:
      result.add textMarked(html[at .. ^1])
      break
    result.add textMarked(html[at ..< open])
    let close = html.find('>', open)
    if close < 0:
      result.add html[open .. ^1]
      break
    result.add html[open .. close]
    at = close + 1
    for element in ELEMENTS_KEPT:
      if html.continuesWith("<" & element, open) and
          html[open + element.len + 1] in Whitespace + {'>'}:
        let ending = html.find("</" & element, at)
        if ending >= 0:
          result.add html[at ..< ending]
          at = ending
        break


func assemble*(shell, title, body: string; faces: Table[string, string]): string =
  ## Fill shell: title escaped, body as rendered with marks boxed, each face as base64 data.
  result = shell.replace(TOKEN_TITLE, escapeHtml(title)).replace(TOKEN_BODY, htmlMarked(body))
  for face, bytes in faces.pairs:
    result = result.replace(
      TOKEN_EMBED & face & "@",
      "data:" & mediaOf(face) & ";base64," & encode(bytes),
    )


func digestPage*(page: string): string =
  ## Digest built page, as publications hold it once page is published.
  digestOf(page)



#[ Formatting ]#

func grouped*(number: int): string =
  ## Format integer with thin groups of three digits, as `2 125`.
  let digits = $abs(number)
  for index, digit in digits:
    if index > 0 and (digits.len - index) mod 3 == 0: result.add ' '
    result.add digit
  if number < 0: result = "−" & result


func fixed*(value: float, places = 2): string =
  ## Format float to fixed places.
  formatFloat(value, ffDecimal, places)


func textRatio*(ratio: float): string =
  ## Format ratio of times as `×0.72`.
  "×" & ratio.fixed


func code*(text: string): string =
  ## Render text as inline code.
  "<code>" & escapeHtml(text) & "</code>"


func chip*(text, kind: string): string =
  ## Render short verdict as chip of kind: `pass`, `fail` or `status`.
  "<span class=\"chip " & kind & "\">" & escapeHtml(text) & "</span>"
