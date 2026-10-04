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
##
##   Cost: whole Noto faces inlined as base64 weigh about 4.4 MB in each page; published page
##     may hold sixteen megabytes.

{.experimental: "strictFuncs".}

import std/[base64, strutils, tables]

import ../[changes, markdown]


const
  TOKEN_TITLE* = "@TITLE@"  ## Token page's title replaces.
  TOKEN_BODY* = "@BODY@"  ## Token rendered body replaces.
  TOKEN_EMBED* = "@EMBED:"  ## Opening of token one face replaces, closed by `@`.
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


func assemble*(shell, title, body: string; faces: Table[string, string]): string =
  ## Fill shell: title escaped, body as rendered, each face as base64 data of its bytes.
  result = shell.replace(TOKEN_TITLE, escapeHtml(title)).replace(TOKEN_BODY, body)
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
