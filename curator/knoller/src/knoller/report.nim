## Render finding of any tool in one of two forms (STYLE.md §3): terminal form for reader at
##   terminal, and line form for pipe or log.
##   Finding holds only parts its check knows (ruling D3 of #1002, option `a`): location runs
##     path, line and column, each only behind part before it. Terminal form shows source line
##     only where finding holds line and its text, and marker only where it holds column too.
##   Terminal form, block by block where held: location and rule; summary; source line under
##     gutter of its number, then marker under its span; `actual` and `expect` in two columns;
##     `help:` line. Blank line stands between two blocks, and between two findings.
##   Line form: `path:line:column: rule: actual="…" expect="…" message="…" help="…"`, each value
##     quoted and escaped, so finding takes one line and each value parses back by its key. Help
##     stands last, so hook and log keep remedy each finding gives (ruling 7197275206 of #1002).
##   Warning prints in both forms, with `warning` after its rule, as knoller marks it on its
##     command line (ruling D2 of #1002, option `a`); rewrite is no finding, so its caller keeps
##     its one line.
##   Renderer stays pure: caller reads terminal, flag and `NO_COLOR`, and passes what they say
##     (`formOutput`, `isColored`), as color shows in terminal form on terminal alone.
##   Column and span count runes, as width of line counts them (`form.nim`); control character
##     of source line prints as its picture, one rune wide, so marker stays under its rune.
##   Source line past `WIDTH_SOURCE` runes shows window around span, each cut edge marked `…`,
##     since finding of width names line of hundreds of runes, and terminal wraps it.
##   Terminal form quotes value that is empty, or whose edge or control character would hide in
##     column, as line form quotes it, so each value stays visible (Article IV.4).
##
##   Cost: marker counts each rune as one column, so wide glyph, as of East Asian text or emoji,
##     shifts marker right of its span.
##   Cost: path and rule print bare in line form, so path holding `: ` reads ambiguously there.

{.experimental: "strictFuncs".}

import std/[options, sequtils, strutils, unicode]


type  # TODO: Document.
  Form* {.pure.} = enum  ## Define form finding prints in (STYLE.md §3).
    Terminal  ## Blocks over several lines, for reader at terminal; colored where caller asks.
    Line  ## One line, for pipe or log, each value quoted.

  Notice* = object  ## Define finding as renderer reads it, with each part its check holds.
    path*: string  ## Path of file, `/` separated; empty where finding names no file.
    line*: int  ## One-based line; `0` where finding names none.
    column*: int  ## One-based column, in runes; `0` where finding names none.
    span*: int  ## Runes marker underlines from column; one where `0`.
    rule*: string  ## Id of rule broken, as `name-cut`, or `koch.line-width` of check of koch.
    summary*: string  ## Lowercase statement of what breaks rule.
    actual*: Option[string]  ## Value source holds, empty one too; none where finding names none.
    expected*: Option[string]  ## Value rule asks for; none where finding names none.
    help*: string  ## What reader does about finding; empty where it gives none.
    source*: Option[string]  ## Text of line finding names; none where caller read none.
    is_warning*: bool  ## Finding warns rather than breaks rule, so `warning` follows its rule.


const  # TODO: Document.
  COLOR_LOCATION = "\e[36m"  ## Cyan, of location.
  COLOR_RULE = "\e[2m"  ## Dim, of rule.
  COLOR_SUMMARY = "\e[1m"  ## Bold, of summary.
  COLOR_GUTTER = "\e[34m"  ## Blue, of number of source line and its bar.
  COLOR_ACTUAL = "\e[31m"  ## Red, of value source holds and its span in source line.
  COLOR_MARKER = "\e[1;31m"  ## Bold red, of marker and label `actual`.
  COLOR_EXPECTED = "\e[32m"  ## Green, of value rule asks for.
  COLOR_LABEL_EXPECTED = "\e[1;32m"  ## Bold green, of label `expect`.
  COLOR_HELP = "\e[1;36m"  ## Bold cyan, of label `help`.
  COLOR_WARNING = "\e[1;33m"  ## Bold yellow, of mark of warning.
  COLOR_RESET = "\e[0m"  ## Reset of each color.
  WIDTH_GUTTER = 4  ## Runes gutter gives number of source line at least, right-aligned.
  WIDTH_SOURCE = 80  ## Runes of source line terminal form shows at most.
  WIDTH_BEFORE = 20  ## Runes window shows before span, where line runs on past window.
  MARK_CUT = "…"  ## Mark of edge where window cuts source line.
  MARK_WARNING = "warning"  ## Mark after rule of finding that warns.
  PICTURE_DELETE = "␡"  ## Control picture of delete, `\x7F`.



#[ Values ]#

func painted(text, color: string, is_colored: bool): string =
  ## Wrap text in color and its reset where colored and not empty; text alone elsewhere.
  if is_colored and text.len > 0: color & text & COLOR_RESET else: text


func isControl(c: char): bool =
  ## Decide whether byte is control character of ASCII, delete included.
  c < ' ' or c == '\x7F'


func quoted*(value: string): string =
  ## Quote value as line form quotes it: `"` around it, with `\`, `"` and each control character
  ##   escaped, so value spans one line and parses back; text beyond ASCII stays as written.
  result = "\""
  for c in value:
    case c
    of '\\': result.add "\\\\"
    of '"': result.add "\\\""
    of '\n': result.add "\\n"
    of '\r': result.add "\\r"
    of '\t': result.add "\\t"
    elif c.isControl: result.add "\\x" & c.ord.toHex(2)
    else: result.add c
  result.add '"'


func shown(value: string): string =
  ## Print value as terminal form shows it: bare, or quoted where empty, or where blank edge or
  ##   control character would hide it in its column.
  let is_hidden = value.len == 0 or value[0] in Whitespace or value[^1] in Whitespace or
    value.anyIt(it.isControl)
  if is_hidden: value.quoted else: value


func pictured(text: string): string =
  ## Print each control character of text as its control picture, one rune wide, i.e. tab as
  ##   `␉` and CR as `␍`; other text as written.
  for c in text:
    if c == '\x7F': result.add PICTURE_DELETE
    elif c.isControl: result.add Rune(0x2400 + c.ord).toUTF8
    else: result.add c


func pictured(runes: openArray[Rune]): string =
  ## Print runes as text, each control character as its picture.
  var text = ""
  for r in runes: text.add r
  text.pictured



#[ Forms ]#

func location(notice: Notice): string =
  ## Join parts of location finding holds: path, then line, then column, each only behind part
  ##   before it.
  if notice.path.len == 0: return ""
  result = notice.path
  if notice.line == 0: return
  result.add ":" & $notice.line
  if notice.column > 0: result.add ":" & $notice.column


func window(count, start: int): Slice[int] =
  ## Pick runes of source line terminal form shows: whole line where it fits `WIDTH_SOURCE`, else
  ##   that many, `WIDTH_BEFORE` of them before span where line runs on past window, and up to
  ##   end of line where it does not.
  if count <= WIDTH_SOURCE: return 0 ..< count
  let first = min(max(start - WIDTH_BEFORE, 0), count - WIDTH_SOURCE)
  first ..< first + WIDTH_SOURCE


func blockSource(notice: Notice, is_colored: bool): seq[string] =
  ## Render source line of finding under gutter of its number, its span red, and marker under
  ##   span where finding holds column; none where it holds no line or no text of line.
  if notice.line == 0 or notice.source.isNone: return
  let
    number = $notice.line
    cell = number.align(max(WIDTH_GUTTER, number.len))
    bar = "│".painted(COLOR_GUTTER, is_colored)
    gutter = "  " & cell.painted(COLOR_GUTTER, is_colored) & " " & bar & " "
    runes = notice.source.get.toRunes
    start = if notice.column == 0: 0 else: min(notice.column - 1, runes.len)
    shown = window(runes.len, start)
    cut_left = if shown.a > 0: MARK_CUT.painted(COLOR_RULE, is_colored) else: ""
    cut_right = if shown.b + 1 < runes.len: MARK_CUT.painted(COLOR_RULE, is_colored) else: ""
  if notice.column == 0: return @[gutter & cut_left & runes[shown].pictured & cut_right]

  # Split window at span, so its runes take red and marker stands under them.
  let
    stop = min(start + max(notice.span, 1), shown.b + 1)
    text = runes[shown.a ..< start].pictured &
      runes[start ..< stop].pictured.painted(COLOR_ACTUAL, is_colored) &
      runes[stop .. shown.b].pictured
    offset = start - shown.a + (if shown.a > 0: 1 else: 0)
    marker = "─".repeat(max(stop - start, 1)).painted(COLOR_MARKER, is_colored)
  @[
    gutter & cut_left & text & cut_right,
    "  " & ' '.repeat(cell.len) & " " & bar & " " & ' '.repeat(offset) & marker,
  ]


func ruled(notice: Notice, is_colored: bool): string =
  ## Render rule of finding, with `warning` after it where finding warns.
  let mark = if notice.is_warning: MARK_WARNING.painted(COLOR_WARNING, is_colored) else: ""
  [notice.rule.painted(COLOR_RULE, is_colored), mark].filterIt(it.len > 0).join(" ")


func blockValues(notice: Notice, is_colored: bool): seq[string] =
  ## Render `actual` and `expect` finding holds, in two columns; none where it holds neither.
  if notice.actual.isSome:
    result.add "  " & "actual".painted(COLOR_MARKER, is_colored) & "  " &
      notice.actual.get.shown.painted(COLOR_ACTUAL, is_colored)
  if notice.expected.isSome:
    result.add "  " & "expect".painted(COLOR_LABEL_EXPECTED, is_colored) & "  " &
      notice.expected.get.shown.painted(COLOR_EXPECTED, is_colored)


func renderTerminal(notice: Notice, is_colored: bool): string =
  ## Render finding in terminal form: each block it holds, blank line between two.
  var blocks: seq[seq[string]]
  let head = [notice.location.painted(COLOR_LOCATION, is_colored), notice.ruled(is_colored)]
  blocks.add @[head.filterIt(it.len > 0).join("  ")]
  blocks.add @["  " & notice.summary.painted(COLOR_SUMMARY, is_colored)]
  for lines in [notice.blockSource(is_colored), notice.blockValues(is_colored)]:
    if lines.len > 0: blocks.add lines
  if notice.help.len > 0:
    blocks.add @["  " & "help".painted(COLOR_HELP, is_colored) & ": " & notice.help]
  blocks.mapIt(it.join("\n")).join("\n\n")


func renderLine(notice: Notice): string =
  ## Render finding in line form: location parts held, rule, then each value held, quoted, help
  ##   last.
  var
    parts: seq[string]
    values: seq[string]
  for part in [notice.location, notice.ruled(is_colored = false)]:
    if part.len > 0: parts.add part
  if notice.actual.isSome: values.add "actual=" & notice.actual.get.quoted
  if notice.expected.isSome: values.add "expect=" & notice.expected.get.quoted
  values.add "message=" & notice.summary.quoted
  if notice.help.len > 0: values.add "help=" & notice.help.quoted
  parts.add values.join(" ")
  parts.join(": ")



#[ Output ]#

func render*(notice: Notice, form: Form, is_colored = false): string =
  ## Render finding in form: terminal form colored where `is_colored`, and line form never.
  case form
  of Form.Terminal: notice.renderTerminal(is_colored)
  of Form.Line: notice.renderLine


func render*(notices: openArray[Notice], form: Form, is_colored = false): string =
  ## Render findings in form, in order given: blank line between two in terminal form, and line
  ##   break alone in line form.
  let gap = if form == Form.Terminal: "\n\n" else: "\n"
  notices.mapIt(it.render(form, is_colored)).join(gap)


func spanned(value: string): string =
  ## Wrap value in backticks as code span, so empty value shows; value holding code span of its
  ##   own prints bare, as text around code.
  if '`' in value: value else: "`" & value & "`"


func brief*(notice: Notice): string =
  ## Read short text of each part finding holds, as test of each check compares it (ruling D3 of
  ##   #1002, option `c`): summary, then actual after `; got`, value after `; expect` and text
  ##   after `; help:`, each where held. Rule and location stand apart, so text reads as message.
  result = notice.summary
  if notice.actual.isSome: result.add "; got " & notice.actual.get.spanned
  if notice.expected.isSome: result.add "; expect " & notice.expected.get.spanned
  if notice.help.len > 0: result.add "; help: " & notice.help


func formOutput*(is_terminal: bool, forced = none(Form)): Form =
  ## Pick form of output: one flag forces where given, else terminal form at terminal, and line
  ##   form in pipe or log.
  if forced.isSome: forced.get
  elif is_terminal: Form.Terminal
  else: Form.Line


func isColored*(is_terminal: bool, no_color: string): bool =
  ## Decide whether terminal form shows color: on terminal alone, and only where `NO_COLOR` is
  ##   unset or empty, as no-color.org reads it.
  is_terminal and no_color.len == 0
