## Enforce faces presentation target ships (Article X.8), over sources declaring them.
##   X.8 names three families by role and forbids naming one viewer may lack. Nothing held it
##   before this: every target had drifted, one to Google Fonts and three to system stacks,
##   and drift was found by reading rather than by check. Rule that holds by reading is rule
##   that holds until nobody reads.
##
##   Four rules, and what each rests on:
##     Host. Page linking font host makes viewer fetch face, which is opposite of shipping it.
##       Substring of known hosts, which is robust: address cannot hide from itself.
##     First family. Every stack's *first* family must be one X.8 names. Fallbacks after it are
##       unreachable once face ships, so they cost nothing and stay free -- and "names one
##       viewer may lack" is violation only where primary is one viewer may lack. Rule is
##       crisp where allow-list of every acceptable fallback would be list nobody maintains.
##     Heading. Selector naming `h1`..`h6` must set serif family, one `var()` deep: stacks live
##       in custom properties here, so resolver substitutes property's own value once.
##     Ligature. Source naming Commit Mono must enable `calt`, since its ligatures are
##       functional (`!=` reads `≠`) and live in that feature alone.
##
##   Weaker half, stated rather than implied: heading rule reads selector text and one level of
##     `var()`, so heading styled through class alone, or property defined twice, is not seen.
##     It catches page that sets headings in sans outright, which is drift that happened; it is
##     not proof every heading renders serif.
##   Desktop atlas is exempt from ligature rule by X.8 itself: Dear ImGui does no text shaping,
##     so `calt` never runs there. Exemption belongs in rule rather than in this file, and
##     nothing here reads desktop source, which declares no CSS.
##
##   Cost: source is scanned only where it declares `font-family`, so registry of kinds is not
##     consulted; page emitted from Nim is read exactly as `.html` is, which is what
##     `design/page.nim` needed.
##   Cost: checker's own sources name these families as data and would report themselves, so
##     they are exempt -- same exemption `checkDeadExports` needs and for same reason.
##   Cost: declarations are read, expressions are not. Source assembling font string through
##     `&` is skipped rather than reported through its operators, so stack spelled only that
##     way is unseen. Measured: two such lines in `dance_ontology` read as `&` before this.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils]
import ./findings


const
  SERIF* = "Noto Serif"
    ## Family X.8 gives headings and titles.
  SANS* = "Noto Sans"
    ## Family X.8 gives body and interface text.
  MONO* = "Commit Mono"
    ## Family X.8 gives code, data and figures.
  FAMILIES* = [SERIF, SANS, MONO]
    ## Every family X.8 admits, in role order. Match is by prefix, so target's own
    ## `@font-face` alias -- `Noto Sans UI`, `Noto Sans Math` -- is same family named for
    ## its subset rather than second family smuggled in.
  HOSTS* = [
    "fonts.googleapis.com",
    "fonts.gstatic.com",
    "use.typekit.net",
    "fonts.bunny.net",
    "cdnjs.cloudflare.com/ajax/libs/font",
  ]
    ## Font hosts page must not link. Build fetching face and embedding it is not here: that
    ## is build's own business and viewer never reaches it (`rga_visualiser`, `assets`).
  LIGATURES* = ["font-variant-ligatures", "font-feature-settings"]
    ## Properties that can enable `calt`; either satisfies ligature rule.
  MARK = "font-family"
    ## Declaration naming family list outright.
  SHORTHAND = "font"
    ## Declaration naming family list last, after size and line height. `design/page.nim`
    ## writes every stack this way, and check reading `font-family` alone passed it.
  SHAPES = [
    "normal", "italic", "oblique", "bold", "bolder", "lighter", "small-caps", "caption",
    "icon", "menu", "message-box", "small-caption", "status-bar",
  ]
    ## Shorthand tokens standing before family list; token carrying digit is size or weight
    ## and is dropped by same rule.
  DEFERS* = ["inherit", "initial", "unset", "revert"]
    ## Values naming no family at all: each defers to what cascade already settled, which
    ## this check has read where it was set. Reporting them would be reporting twice.
  GENERICS = [
    "serif", "sans-serif", "monospace", "cursive", "fantasy", "system-ui",
    "ui-serif", "ui-sans-serif", "ui-monospace", "ui-rounded",
  ]
    ## CSS keywords naming no family. First-family rule rejects these too: keyword resolves to
    ## whatever viewer has, which is precisely what X.8 forbids.


func isFamily*(name: string): bool =
  ## Decide whether family name is one X.8 admits, by prefix so subset aliases pass.
  for family in FAMILIES:
    if name.startsWith(family): return true
  false


func shorthandFamilies*(value: string): string =
  ## Read family list out of `font` shorthand, i.e. what stands after size and line height.
  ##   Tokens are dropped while each is shape word or carries digit; remainder is list.
  ##   Value naming no family leaves nothing, which reads as no stack rather than as bad one.
  ##   Shorthand without size is not one: CSS requires size, so `font: cfloat` is object
  ##   field in Nim source rather than declaration, and reading it as stack reported field
  ##   type as family (measured on `src/desktop/gui.nim`).
  if not value.anyIt(it.isDigit) and "var(" notin value: return ""
  var rest: seq[string]
  var dropping = true
  for token in value.splitWhitespace:
    if dropping and (token.toLowerAscii in SHAPES or token.anyIt(it.isDigit)):
      continue
    dropping = false
    rest.add token
  rest.join(" ")


func firstFamily*(stack: string): string =
  ## Read first family of stack, unquoted and stripped; empty when stack names none.
  ##   Stack is comma-separated and first entry is what viewer gets when face ships, so it
  ##   is only entry this rule reads.
  let head = stack.split(',')[0].strip
  head.strip(chars = {'"', '\'', ' ', '\t'})


func declarations*(content: string, property: string): seq[(int, string)] =
  ## Read every `property: value` in source, as one-based line and value.
  ##   Value ends at `;` or line end, so declaration spanning lines is read to line end,
  ##   which is enough for first family and never splits family name.
  let lines: seq[string] = content.splitLines
  for i, line in lines:
    var rest = line
    while true:
      let at = rest.find(property & ":")
      if at < 0: break
      var value = rest[at + property.len + 1 .. ^1]
      let stop = value.find(';')
      if stop >= 0: value = value[0 ..< stop]
      result.add (i + 1, value.strip)
      rest = rest[at + property.len + 1 .. ^1]


func propertyValues*(content: string): seq[(string, string)] =
  ## Read every custom property `--name: value` as name and value, for one-deep resolution.
  let lines: seq[string] = content.splitLines
  for line in lines:
    let at = line.find("--")
    if at < 0: continue
    let colon = line.find(':', at)
    if colon < 0: continue
    let name = line[at ..< colon].strip
    if name.len <= 2 or ' ' in name: continue
    var value = line[colon + 1 .. ^1]
    let stop = value.find(';')
    if stop >= 0: value = value[0 ..< stop]
    result.add (name, value.strip)


func resolved*(value: string, properties: openArray[(string, string)]): string =
  ## Substitute `var(--name)` with that property's own value, one level deep.
  ##   One level, never recursive: stacks here are written literally in property, and
  ##   resolver that chased chains would need cycle guard for depth nothing uses.
  let at = value.find("var(")
  if at < 0: return value
  let close = value.find(')', at)
  if close < 0: return value
  let name = value[at + 4 ..< close].strip
  for (property, held) in properties:
    if property == name: return held
  value


func isHeading*(selector: string): bool =
  ## Decide whether selector names any heading element.
  for level in 1 .. 6:
    let tag = "h" & $level
    let at = selector.find(tag)
    if at < 0: continue
    # Heading tag, never `.h1` class or `graph1`: character before must not continue name.
    let before = if at == 0: ' ' else: selector[at - 1]
    let after = if at + tag.len >= selector.len: ' ' else: selector[at + tag.len]
    if before notin {'.', '#', '-', '_'} and not before.isAlphaNumeric and
       not after.isAlphaNumeric and after notin {'-', '_'}:
      return true
  false


func checkFaces*(path, content: string): seq[Finding] =
  ## Report every way source departs from faces X.8 names.
  ##   Source declaring neither form declares no faces and is not page; whole check is
  ##   skipped rather than reporting absence, since most files are not pages.
  ##   Both forms are asked for: page writing every stack as shorthand carries no
  ##   `font-family` at all, and guard reading that alone skipped whole page.
  if MARK & ":" notin content and SHORTHAND & ":" notin content: return

  let lines: seq[string] = content.splitLines
  for i, line in lines:
    for host in HOSTS:
      if host in line:
        result.add finding(
          path, i + 1,
          "Page links font host rather than shipping face (Article X.8); got `" & host & "`.",
        )

  # Only stacks declaration names are read. Property is reached through `var()` from one
  #   of those, so it is checked where it is used; property scanned on its own would take
  #   `--ease: cubic-bezier(0.2, ...)` for stack, which it did.
  let properties = content.propertyValues
  var stacks: seq[(int, string)]
  for (line, value) in content.declarations(MARK): stacks.add (line, value)
  for (line, value) in content.declarations(SHORTHAND):
    let families = value.shorthandFamilies
    if families.len > 0: stacks.add (line, families)

  for (line, value) in stacks:
    let stack = value.resolved(properties)
    let first = stack.firstFamily
    if first.len == 0 or first.toLowerAscii in DEFERS: continue
    # Source building font string by concatenation leaves operators in what reads as family.
    #   Check reads declarations, never expressions, and says so rather than reporting `&`
    #   as family nobody named. Cost: violation spelled only through concatenation is unseen.
    if first.anyIt(it in {'&', '$', '(', ')', '{', '}'}): continue
    if first in GENERICS or not first.isFamily:
      result.add finding(
        path, line,
        "Stack leads with family X.8 does not name, so viewer may lack it; got `" &
          first & "`.",
      )

  # Headings take serif, which is what X.8's role split says and what page drifts from
  #   first: every other stack reads same whichever family it names.
  for (line, value) in stacks:
    if line == 0: continue
    let before = lines[line - 1]
    let selector = before[0 ..< before.find(SHORTHAND)]
    if not selector.isHeading: continue
    let first = value.resolved(properties).firstFamily
    if first.len > 0 and first.toLowerAscii notin DEFERS and not first.startsWith(SERIF):
      result.add finding(
        path, line,
        "Heading takes family other than `" & SERIF & "` (Article X.8); got `" & first & "`.",
      )

  # Commit Mono's ligatures are functional and live in `calt` alone, so naming face without
  #   enabling feature ships face half used.
  var names_mono = false
  for (_, value) in stacks:
    if MONO in value.resolved(properties): names_mono = true
  if names_mono:
    var enables = false
    for property in LIGATURES:
      if property in content: enables = true
    if not enables:
      result.add finding(
        path, 0,
        "Source sets `" & MONO & "` without enabling its ligatures (Article X.8); got `" &
          LIGATURES[0] & "` absent.",
      )
