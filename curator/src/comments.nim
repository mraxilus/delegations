## Extract comment text from source by syntax, one record per physical line.
##   Hand-written scanners, not language parsers: each tracks only what hides `#` or `//`
##   (string, char, template literals), which is enough to find comments and nothing more.
##   Every scanner feeds one accumulator: text gathers per line, newline flushes.
##
##   Cost: TypeScript regex literals are unscanned, so `//` inside one opens false comment
##     for rest of line. Accepted until real project hits it; fixture then lands.
##   Cost: Nim generalized raw strings (`r"..."`, `fmt"..."`) detected by identifier
##     character before quote; `"` after operator is plain string, matching lexer.
##   Cost: unterminated plain string ends at newline, as lexer would reject it anyway.

{.experimental: "strictFuncs".}

import std/strutils
import ./kinds


type
  Comment* = object
    ## Define comment text found on one line, markers stripped.
    line*: int     ## One-based line of text.
    text*: string  ## Comment text, markers removed, whitespace collapsed to single spaces.

  Scan = object
    ## Define scanner accumulator: current line, pending text, emitted comments.
    line: int
    text: string
    comments: seq[Comment]


const IDENT_CHARS = {'a'..'z', 'A'..'Z', '0'..'9', '_'}
  ## Characters that may precede quote in Nim generalized raw string literal.


func flush(scan: var Scan) =
  ## Emit pending line text when non-blank, whitespace runs collapsed, then advance line.
  let text = scan.text.splitWhitespace.join(" ")
  if text.len > 0: scan.comments.add Comment(line: scan.line, text: text)
  scan.text = ""
  inc scan.line


func addText(scan: var Scan, text: string) =
  ## Append text to pending line, space-separated from earlier comment on same line.
  if scan.text.len > 0 and text.len > 0: scan.text.add ' '
  scan.text.add text



#[ Nim ]#

func scanNim(source: string): seq[Comment] =
  ## Scan Nim: line comments, nesting block comments, string and char literals.
  type State {.pure.} = enum Code, Str, StrTriple, StrRaw, Line, Block
  var scan = Scan(line: 1)
  var state = State.Code
  var depth = 0
  var i = 0
  let n = source.len
  template at(k: int): char = (if k < n: source[k] else: '\0')
  while i < n:
    let c = source[i]

    # Newline ends line comment and plain strings; block and triple forms survive it.
    if c == '\n':
      if state in {State.Line, State.Str, State.StrRaw}: state = State.Code
      scan.flush
      inc i
      continue

    case state
    of State.Code:
      if c == '#':
        if at(i + 1) == '[' or (at(i + 1) == '#' and at(i + 2) == '['):
          state = State.Block
          depth = 1
          i += (if at(i + 1) == '[': 2 else: 3)
        else:
          state = State.Line
          while i < n and source[i] == '#': inc i
        continue
      if c == '"':
        if at(i + 1) == '"' and at(i + 2) == '"':
          state = State.StrTriple
          i += 3
          continue
        state = if i > 0 and source[i - 1] in IDENT_CHARS: State.StrRaw else: State.Str
      elif c == '\'' and not (i > 0 and source[i - 1] in IDENT_CHARS):
        # Skip char literal when closing quote sits within short window; else treat as code.
        var j = i + 1
        if at(j) == '\\': inc j
        var k = j + 1
        while k < n and k <= i + 8 and source[k] != '\'' and source[k] != '\n': inc k
        if at(k) == '\'':
          i = k + 1
          continue
      inc i
    of State.Str:
      if c == '\\': i += 2
      else:
        if c == '"': state = State.Code
        inc i
    of State.StrTriple:
      if c == '"' and at(i + 1) == '"' and at(i + 2) == '"':
        # Extra quotes after closing triple belong to string, per lexer.
        var k = i + 3
        while at(k) == '"': inc k
        i = k
        state = State.Code
      else: inc i
    of State.StrRaw:
      if c == '"':
        if at(i + 1) == '"': i += 2
        else:
          state = State.Code
          inc i
      else: inc i
    of State.Line:
      scan.text.add c
      inc i
    of State.Block:
      if c == '#' and at(i + 1) == '[':
        inc depth
        i += 2
      elif c == ']' and at(i + 1) == '#':
        dec depth
        i += 2
        while at(i) == '#': inc i
        if depth == 0:
          state = State.Code
          scan.text.add ' '
      else:
        scan.text.add c
        inc i
  scan.flush
  scan.comments



#[ Hash Families ]#

func scanHash(source: string): seq[Comment] =
  ## Scan Makefile: `#` opens comment anywhere unless escaped as `\#`.
  var scan = Scan(line: 1)
  for line in source.splitLines:
    var i = 0
    while i < line.len:
      if line[i] == '#' and not (i > 0 and line[i - 1] == '\\'):
        scan.addText line[i + 1 .. ^1]
        break
      inc i
    scan.flush
  scan.comments


func scanHashSpaced(source: string): seq[Comment] =
  ## Scan YAML: `#` opens comment at line start or after whitespace, outside quotes.
  var scan = Scan(line: 1)
  for line in source.splitLines:
    var is_single = false
    var is_double = false
    for i, c in line:
      if c == '"' and not is_single: is_double = not is_double
      elif c == '\'' and not is_double: is_single = not is_single
      elif c == '#' and not is_single and not is_double and
          (i == 0 or line[i - 1] in {' ', '\t'}):
        scan.addText line[i + 1 .. ^1]
        break
    scan.flush
  scan.comments


func scanHashLeading(source: string): seq[Comment] =
  ## Scan gitignore-like files: `#` as first non-blank character opens comment.
  var scan = Scan(line: 1)
  for line in source.splitLines:
    let s = line.strip(trailing = false)
    if s.startsWith("#"): scan.addText s[1 .. ^1]
    scan.flush
  scan.comments



#[ Slash ]#

func scanSlash(source: string): seq[Comment] =
  ## Scan TypeScript: `//` line, `/* */` block, string and template literals.
  type State {.pure.} = enum Code, StrDouble, StrSingle, StrTemplate, Line, Block
  var scan = Scan(line: 1)
  var state = State.Code
  var is_line_start = false
  var i = 0
  let n = source.len
  template at(k: int): char = (if k < n: source[k] else: '\0')
  while i < n:
    let c = source[i]

    # Newline ends line comment and quoted strings; block comment and template survive it.
    if c == '\n':
      if state in {State.Line, State.StrDouble, State.StrSingle}: state = State.Code
      is_line_start = state == State.Block
      scan.flush
      inc i
      continue

    case state
    of State.Code:
      if c == '/' and at(i + 1) == '/':
        state = State.Line
        i += 2
        continue
      if c == '/' and at(i + 1) == '*':
        # Opener counts as line start so documentation `/**` sheds its second star.
        state = State.Block
        is_line_start = true
        i += 2
        continue
      case c
      of '"': state = State.StrDouble
      of '\'': state = State.StrSingle
      of '`': state = State.StrTemplate
      else: discard
      inc i
    of State.StrDouble, State.StrSingle, State.StrTemplate:
      if c == '\\': i += 2
      else:
        let closer = case state
          of State.StrDouble: '"'
          of State.StrSingle: '\''
          else: '`'
        if c == closer: state = State.Code
        inc i
    of State.Line:
      scan.text.add c
      inc i
    of State.Block:
      # Drop leading `*` of continuation lines, as documentation comments indent them.
      if is_line_start and c in {' ', '\t'}:
        inc i
        continue
      if is_line_start and c == '*' and at(i + 1) != '/':
        is_line_start = false
        inc i
        continue
      is_line_start = false
      if c == '*' and at(i + 1) == '/':
        state = State.Code
        scan.text.add ' '
        i += 2
      else:
        scan.text.add c
        inc i
  scan.flush
  scan.comments



#[ Dispatch ]#

func comments*(source: string, syntax: Syntax): seq[Comment] =
  ## Extract comments of source under syntax; none for `Syntax.None`.
  case syntax
  of Syntax.None: @[]
  of Syntax.Nim: source.scanNim
  of Syntax.Hash: source.scanHash
  of Syntax.HashSpaced: source.scanHashSpaced
  of Syntax.HashLeading: source.scanHashLeading
  of Syntax.Slash: source.scanSlash
