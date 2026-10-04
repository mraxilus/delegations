## Hold each character beyond ASCII that page sources of project use to faces project ships
##   (Article X.8): static half of coverage that article asks for.
##   X.8 merges faces by codepoint range where none covers everything, then renders each
##     codepoint against `.notdef`. Render needs built page and browser, and static pass has
##     neither; this half reads what sources write against what each face's `cmap` maps, which
##     store row carries (`assets.nim`). Character no face of project maps falls to face viewer
##     may lack, which X.8 forbids.
##
##   Faces of project: every store face its page sources name by file. Store refuses file no
##     row declares, so naming file is only way project reaches face.
##     Union over project, never per page or per stack: question is whether any face project
##     ships covers character, and which face cascade picks is render's business.
##     Cost: character no stack of its element reaches passes, where face covering it serves
##     other stack or desktop atlas alone.
##   Page source: every file of project outside `tests/`, records aside. Pages are built from
##     Nim, TypeScript, Markdown and JSON as well as from `pages/` and `mockups/`, and static
##     pass cannot trace which file build reads. Tests are left out, since fixture holds
##     character to prove its absence; records describe pages and are none.
##     Cost: character in file no page reads, e.g. message tool prints, is reported too.
##   Comments are set aside, line by line: character comment alone holds never reaches page.
##     Comments are read through `comments.nim`, so its blind spots are this check's too:
##     comment inside `<script>` or `<style>` reads as source.
##   References: `&name;` for names HTML 4.01 defined, `&#n;` and `&#xh;`. Name outside table
##     is unread rather than reported, since `&` opens no reference in most code here.
##     C and C++ read none: `&name;` there takes address, and their text reaches screen
##     through Dear ImGui, which decodes no reference.
##
##   Cost: project naming face through computed name, e.g. `"NotoSans-" & weight`, ships face
##     check does not see, so characters only that face covers read as uncovered.
##   Cost: page shipping no face at all is unseen: project naming no store face is skipped,
##     since nothing tells its page apart from tool printing non-ASCII text.
##   Cost: default-ignorable codepoint, e.g. `U+FE0F`, draws nothing, yet is reported where no
##     face maps it. None stands in tree; first one adds exemption with its test.

{.experimental: "strictFuncs".}

import std/[options, os, sequtils, sets, strutils, tables, unicode]
import ./[assets, comments, findings, kinds, layout]


type Character* = object  ## Define one character page source uses: where, which, as written.
  path*: string  ## Repository-relative path of source.
  line*: int  ## One-based line.
  codepoint*: int  ## Codepoint beyond ASCII.
  spelling*: string  ## As source writes it: character itself, or reference such as `&uarr;`.


const
  ASCII_MAX = 0x7F  ## Last codepoint of ASCII, which check never reads.
  CODEPOINT_MAX = 0x10FFFF  ## Last codepoint Unicode defines; reference past it names none.
  REFERENCE_MAX = 10  ## Bytes `&` to `;` span at most, as in `&#x10FFFF;` and `&thetasym;`.
  KINDS_ADDRESSING = {Kind.C, Kind.Cpp}
    ## Kinds where `&name;` takes address rather than naming character, so none is read.
  ENTITIES* = [
    # Latin-1, HTML 4.01 `HTMLlat1.ent`.
    ("nbsp", 160), ("iexcl", 161), ("cent", 162), ("pound", 163), ("curren", 164), ("yen", 165),
    ("brvbar", 166), ("sect", 167), ("uml", 168), ("copy", 169), ("ordf", 170), ("laquo", 171),
    ("not", 172), ("shy", 173), ("reg", 174), ("macr", 175), ("deg", 176), ("plusmn", 177),
    ("sup2", 178), ("sup3", 179), ("acute", 180), ("micro", 181), ("para", 182), ("middot", 183),
    ("cedil", 184), ("sup1", 185), ("ordm", 186), ("raquo", 187), ("frac14", 188), ("frac12", 189),
    ("frac34", 190), ("iquest", 191), ("Agrave", 192), ("Aacute", 193), ("Acirc", 194),
    ("Atilde", 195), ("Auml", 196), ("Aring", 197), ("AElig", 198), ("Ccedil", 199),
    ("Egrave", 200), ("Eacute", 201), ("Ecirc", 202), ("Euml", 203), ("Igrave", 204),
    ("Iacute", 205), ("Icirc", 206), ("Iuml", 207), ("ETH", 208), ("Ntilde", 209), ("Ograve", 210),
    ("Oacute", 211), ("Ocirc", 212), ("Otilde", 213), ("Ouml", 214), ("times", 215),
    ("Oslash", 216), ("Ugrave", 217), ("Uacute", 218), ("Ucirc", 219), ("Uuml", 220),
    ("Yacute", 221), ("THORN", 222), ("szlig", 223), ("agrave", 224), ("aacute", 225),
    ("acirc", 226), ("atilde", 227), ("auml", 228), ("aring", 229), ("aelig", 230), ("ccedil", 231),
    ("egrave", 232), ("eacute", 233), ("ecirc", 234), ("euml", 235), ("igrave", 236),
    ("iacute", 237), ("icirc", 238), ("iuml", 239), ("eth", 240), ("ntilde", 241), ("ograve", 242),
    ("oacute", 243), ("ocirc", 244), ("otilde", 245), ("ouml", 246), ("divide", 247),
    ("oslash", 248), ("ugrave", 249), ("uacute", 250), ("ucirc", 251), ("uuml", 252),
    ("yacute", 253), ("thorn", 254), ("yuml", 255),
    # Symbols, mathematical and Greek, HTML 4.01 `HTMLsymbol.ent`.
    ("fnof", 402), ("Alpha", 913), ("Beta", 914), ("Gamma", 915), ("Delta", 916), ("Epsilon", 917),
    ("Zeta", 918), ("Eta", 919), ("Theta", 920), ("Iota", 921), ("Kappa", 922), ("Lambda", 923),
    ("Mu", 924), ("Nu", 925), ("Xi", 926), ("Omicron", 927), ("Pi", 928), ("Rho", 929),
    ("Sigma", 931), ("Tau", 932), ("Upsilon", 933), ("Phi", 934), ("Chi", 935), ("Psi", 936),
    ("Omega", 937), ("alpha", 945), ("beta", 946), ("gamma", 947), ("delta", 948), ("epsilon", 949),
    ("zeta", 950), ("eta", 951), ("theta", 952), ("iota", 953), ("kappa", 954), ("lambda", 955),
    ("mu", 956), ("nu", 957), ("xi", 958), ("omicron", 959), ("pi", 960), ("rho", 961),
    ("sigmaf", 962), ("sigma", 963), ("tau", 964), ("upsilon", 965), ("phi", 966), ("chi", 967),
    ("psi", 968), ("omega", 969), ("thetasym", 977), ("upsih", 978), ("piv", 982), ("bull", 8226),
    ("hellip", 8230), ("prime", 8242), ("Prime", 8243), ("oline", 8254), ("frasl", 8260),
    ("weierp", 8472), ("image", 8465), ("real", 8476), ("trade", 8482), ("alefsym", 8501),
    ("larr", 8592), ("uarr", 8593), ("rarr", 8594), ("darr", 8595), ("harr", 8596), ("crarr", 8629),
    ("lArr", 8656), ("uArr", 8657), ("rArr", 8658), ("dArr", 8659), ("hArr", 8660),
    ("forall", 8704), ("part", 8706), ("exist", 8707), ("empty", 8709), ("nabla", 8711),
    ("isin", 8712), ("notin", 8713), ("ni", 8715), ("prod", 8719), ("sum", 8721), ("minus", 8722),
    ("lowast", 8727), ("radic", 8730), ("prop", 8733), ("infin", 8734), ("ang", 8736),
    ("and", 8743), ("or", 8744), ("cap", 8745), ("cup", 8746), ("int", 8747), ("there4", 8756),
    ("sim", 8764), ("cong", 8773), ("asymp", 8776), ("ne", 8800), ("equiv", 8801), ("le", 8804),
    ("ge", 8805), ("sub", 8834), ("sup", 8835), ("nsub", 8836), ("sube", 8838), ("supe", 8839),
    ("oplus", 8853), ("otimes", 8855), ("perp", 8869), ("sdot", 8901), ("lceil", 8968),
    ("rceil", 8969), ("lfloor", 8970), ("rfloor", 8971), ("lang", 10216), ("rang", 10217),
    ("loz", 9674), ("spades", 9824), ("clubs", 9827), ("hearts", 9829), ("diams", 9830),
    # Markup and internationalisation, HTML 4.01 `HTMLspecial.ent`.
    ("quot", 34), ("amp", 38), ("lt", 60), ("gt", 62), ("OElig", 338), ("oelig", 339),
    ("Scaron", 352), ("scaron", 353), ("Yuml", 376), ("circ", 710), ("tilde", 732), ("ensp", 8194),
    ("emsp", 8195), ("thinsp", 8201), ("zwnj", 8204), ("zwj", 8205), ("lrm", 8206), ("rlm", 8207),
    ("ndash", 8211), ("mdash", 8212), ("lsquo", 8216), ("rsquo", 8217), ("sbquo", 8218),
    ("ldquo", 8220), ("rdquo", 8221), ("bdquo", 8222), ("dagger", 8224), ("Dagger", 8225),
    ("permil", 8240), ("lsaquo", 8249), ("rsaquo", 8250), ("euro", 8364),
  ]
    ## Named character references HTML 4.01 defined (section 24), each with codepoint WHATWG
    ## HTML maps it to (section 13.5), which is what browser draws.
    ##   Two differ from HTML 4.01: `lang` and `rang`, which WHATWG moved off `2329` and `232a`.
    ##   Names WHATWG added since are unread, so `&check;` passes whatever faces ship.
  FACES = ASSETS.mapIt((file: it[0], ranges: it[3].toRanges))
    ## Every face store declares, with ranges its row spells read at compile time (Article II.2).


func referenced(body: string): Option[int] =
  ## Read codepoint reference names from its body, i.e. text between `&` and `;`.
  ##   None for name outside `ENTITIES`, for malformed number, and for number past Unicode.
  if body.len > 1 and body[0] == '#':
    let
      is_hex = body[1] in {'x', 'X'}
      digits = body[(if is_hex: 2 else: 1) .. ^1]
    if digits.len == 0 or not digits.allCharsInSet(if is_hex: HexDigits else: Digits):
      return none(int)
    let codepoint = if is_hex: digits.parseHexInt else: digits.parseInt
    if codepoint > CODEPOINT_MAX: return none(int)
    return some(codepoint)
  for (name, codepoint) in ENTITIES:
    if name == body: return some(codepoint)
  none(int)


func charactersIn(text: string, has_references: bool): seq[(int, string)] =
  ## Read each character beyond ASCII that text holds, as codepoint and spelling.
  ##   Rune reads as itself; reference reads as character it names, where kind reads them.
  ##   Reference naming ASCII, e.g. `&amp;`, is passed over as ASCII is.
  var i = 0
  while i < text.len:
    if text[i].ord > ASCII_MAX:
      let size = text.runeLenAt(i)
      result.add (int(text.runeAt(i)), text[i..<i + size])
      i += size
      continue
    if has_references and text[i] == '&':
      let stop = text.find(';', i + 1, last = min(i + REFERENCE_MAX - 1, text.high))
      if stop > i + 1:
        let codepoint = text[i + 1..<stop].referenced
        if codepoint.isSome and codepoint.get > ASCII_MAX:
          result.add (codepoint.get, text[i..stop])
          i = stop + 1
          continue
    inc i


func isPageSource(path, directory: string): bool =
  ## Decide whether file of project may reach page: anything outside `tests/`, records aside.
  if not path.startsWith(directory & "/"): return false
  let inside = path[directory.len + 1 .. ^1]
  not inside.startsWith(TESTS_DIRECTORY & "/") and inside.extractFilename notin PROJECT_FILES


func charactersOutside(e: Entry): seq[Character] =
  ## Read each character beyond ASCII that source uses outside its comments, by line.
  let has_references = e.kind.get notin KINDS_ADDRESSING
  var commented: Table[int, string]
  for comment in e.content.comments(e.kind.get.rule.syntax):
    commented[comment.line] = comment.text

  # Set aside each character comment of line holds; what remains stands outside comment.
  let lines: seq[string] = e.content.splitLines
  for i, line in lines:
    var aside = commented.getOrDefault(i + 1).charactersIn(has_references)
    for (codepoint, spelling) in line.charactersIn(has_references):
      let at = aside.find((codepoint, spelling))
      if at >= 0:
        aside.delete(at)
        continue
      result.add Character(path: e.path, line: i + 1, codepoint: codepoint, spelling: spelling)


func charactersOf*(tree: Tree, directory: string): seq[Character] =
  ## Read each character beyond ASCII that page sources of project use, comments set aside.
  for e in tree:
    if e.kind.isSome and e.path.isPageSource(directory): result.add e.charactersOutside


func facesOf*(tree: Tree, directory: string): seq[string] =
  ## Read store faces that page sources of project name by file, in store order.
  for (file, _) in FACES:
    for e in tree:
      if e.kind.isSome and e.path.isPageSource(directory) and file in e.content:
        result.add file
        break


func toNotation(codepoint: int): string =
  ## Render codepoint as Unicode writes it, i.e. `U+` and at least four hex digits.
  var digits = codepoint.toHex(6)
  while digits.len > 4 and digits[0] == '0': digits = digits[1 .. ^1]
  "U+" & digits


func checkCoverage*(tree: Tree, directory: string): seq[Finding] =
  ## Report each character page source of project uses that no face project ships covers.
  ##   Project naming no store face is skipped; header gives cost.
  ##   One finding for each codepoint on line, however often line spells it.
  ##   Source whose every character faces cover is passed before its comments are scanned:
  ##     faces cover nearly everything, and scan is most of check's cost (PROVENANCE.md).
  let faces = tree.facesOf(directory)
  if faces.len == 0: return
  var ranges: seq[Slice[int]]
  for (file, held) in FACES:
    if file in faces: ranges.add held

  var
    is_held: Table[int, bool]  # Codepoint decided once, since project spells few many times.
    reported: HashSet[(string, int, int)]
  for e in tree:
    if e.kind.isNone or not e.path.isPageSource(directory): continue

    # Decide every character of source, comments included; nothing uncovered ends it here.
    var is_covered = true
    for (codepoint, _) in e.content.charactersIn(e.kind.get notin KINDS_ADDRESSING):
      if codepoint notin is_held: is_held[codepoint] = ranges.anyIt(codepoint in it)
      if not is_held[codepoint]: is_covered = false
    if is_covered: continue

    # Report what stands outside comments; every codepoint of it was decided above.
    for character in e.charactersOutside:
      if is_held.getOrDefault(character.codepoint): continue
      if reported.containsOrIncl((character.path, character.line, character.codepoint)): continue
      result.add finding(
        character.path,
        character.line,
        "Character no face project ships covers, so face viewer may lack draws it (Article " &
          "X.8); got `" & character.codepoint.toNotation & "` for `" & character.spelling & "`.",
      )
