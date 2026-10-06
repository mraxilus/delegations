## Read Nim source as tokens, as compiler's lexer reads them (`compiler/lexer.nim`), for layout
##   rules no single line shows: separators, wrapping, trailing separators, operator spacing.
##   Token holds kind, byte span and line; whitespace between tokens is what layout rules read.
##   Lexer's own rules, kept so token here is token there:
##   - run of operator characters is one operator (`OpChars`, and glyphs `unicodeOprLen`
##     lists), so `∧☆` is one token and `=-` is one;
##   - `-` before digit opens number where whitespace, `,`, `;` or opening bracket stands before
##     it (`UnaryMinusWhitelist`), so `a -1` holds literal `-1`;
##   - `{.`, `[.`, `(.` open and `.}`, `.]`, `.)` close, unless second dot follows; `[:` opens;
##   - `*` before lone `:` is operator alone, as in `x*: int`;
##   - string after identifier character is raw (`r"…"`, generalized `fmt"…"`), so `\` escapes
##     nothing there; long string ends at last quote of run of three or more.
##   Glyphs are those of pinned compiler admitting most: commit pin of `ronri` projects adds
##     `☆ ⟑ ⟇ ⩓ ⩔ ■ □` to glyphs of 2.2.12, and no project on 2.2.12 spells them in code.
##
##   Cost: scanner, never parser. Token kind is what lexer tells apart, so whether `(` opens call,
##     tuple or parameters is read by each rule from tokens around it.
##   Cost: character literal of several bytes, which compiler refuses, reads up to next quote.

{.experimental: "strictFuncs".}

import std/strutils
import ./views


type
  KindToken* {.pure.} = enum  ## Define what one token is, as layout rules tell tokens apart.
    Word  ## Identifier or keyword, e.g. `proc`, `x`.
    Quoted  ## Name in backticks, e.g. `` `+` ``.
    Number  ## Numeric literal, sign and suffix included, e.g. `-1`, `0xFF'u8`.
    Text  ## String literal of any form, e.g. `"a"`, `r"a"`, `"""a"""`.
    Character  ## Character literal, e.g. `'a'`.
    Comment  ## Line, doc or block comment.
    Operator  ## Run of operator characters, `=`, `:`, `.` and `..` among them.
    Open  ## Opening bracket: `(`, `[`, `{`, `{.`, `[.`, `(.`, `[:`.
    Close  ## Closing bracket: `)`, `]`, `}`, `.}`, `.]`, `.)`.
    Comma  ## Separator `,`.
    Semicolon  ## Separator `;`.

  Token* = object  ## Define one token: kind, byte span in source, line it opens on.
    kind*: KindToken
    first*: int  ## Byte offset of first character.
    after*: int  ## Byte offset after last character.
    line*: int  ## Zero-based line token opens on.


const
  CHARS_OPERATOR = {
    '!', '$', '%', '&', '*', '+', '-', '.', '/', ':', '<', '=', '>', '?', '@', '\\', '^', '|', '~',
  }
    ## Characters operator is built from (`OpChars`).
  GLYPHS_OPERATOR = [
    "±", "×", "∘", "∙", "∧", "∨", "∩", "∪", "⊓", "⊔", "⊕", "⊖", "⊗", "⊘", "⊙", "⊛", "⊞", "⊟", "⊠",
    "⊡", "■", "□", "★", "☆", "⟇", "⟑", "⩓", "⩔",
  ]
    ## Unicode glyphs operator is built from (`unicodeOprLen`), commit pin's set.
  NEGATION_AFTER = {' ', '\t', '\n', '\r', ',', ';', '(', '[', '{'}
    ## Characters before `-` that make `-<digit>` number (`UnaryMinusWhitelist`).
  KEYWORDS = [
    "addr", "and", "as", "asm", "bind", "block", "break", "case", "cast", "concept", "const",
    "continue", "converter", "defer", "discard", "distinct", "div", "do", "elif", "else", "end",
    "enum", "except", "export", "finally", "for", "from", "func", "if", "import", "in", "include",
    "interface", "is", "isnot", "iterator", "let", "macro", "method", "mixin", "mod", "nil", "not",
    "notin", "object", "of", "or", "out", "proc", "ptr", "raise", "ref", "return", "shl", "shr",
    "static", "template", "try", "tuple", "type", "using", "var", "when", "while", "xor", "yield",
  ]
    ## Words lexer reads as keywords (`TokType`), never as identifiers.
  KEYWORDS_ROUTINE = ["converter", "func", "iterator", "macro", "method", "proc", "template"]
    ## Keywords opening routine, its type, or lambda.


func glyphLength(source: string, at: int): int =
  ## Count bytes of operator glyph opening at offset; zero where none opens there.
  for glyph in GLYPHS_OPERATOR:
    if source.continuesWith(glyph, at): return glyph.len


func isDigit(source: string, at: int): bool =
  ## Decide whether offset holds decimal digit.
  at < source.len and source[at] in {'0' .. '9'}


func commentAfter(source: string, at: int): int =
  ## Find offset after comment opening at `at`: line comment to line end, block comment nested.
  let is_doc = source.continuesWith("##[", at)
  if not is_doc and not source.continuesWith("#[", at):
    var k = at
    while k < source.len and source[k] != '\n': inc k
    return k
  let (opener, closer) = if is_doc: ("##[", "]##") else: ("#[", "]#")
  var
    depth = 1
    k = at + opener.len
  while k < source.len:
    if source.continuesWith(closer, k):
      dec depth
      k += closer.len
      if depth == 0: return k
    elif source.continuesWith(opener, k):
      inc depth
      k += opener.len
    else: inc k
  source.len


func textAfter(source: string, at: int): int =
  ## Find offset after string literal opening at `at`: long, raw or escaped.
  if source.continuesWith("\"\"\"", at):
    var k = at + 3
    while k < source.len:
      if source.continuesWith("\"\"\"", k):
        while k + 3 < source.len and source[k + 3] == '"': inc k
        return k + 3
      inc k
    return source.len
  let is_raw = at > 0 and source[at - 1] in CHARS_NAME
  var k = at + 1
  while k < source.len and source[k] != '\n':
    if source[k] == '\\' and not is_raw: k += 2
    elif source[k] == '"':
      if is_raw and k + 1 < source.len and source[k + 1] == '"': k += 2
      else: return k + 1
    else: inc k
  k


func characterAfter(source: string, at: int): int =
  ## Find offset after character literal opening at `at`, escape included.
  var k = at + 1
  if k < source.len and source[k] == '\\': k += 2
  else: inc k
  while k < source.len and source[k] != '\'' and source[k] != '\n': inc k
  if k < source.len and source[k] == '\'': k + 1 else: at + 1


func numberAfter(source: string, at: int): int =
  ## Find offset after numeric literal opening at `at`: sign, base, fraction, exponent, suffix.
  var k = at
  if source[k] == '-': inc k
  if source[k] == '0' and k + 1 < source.len and source[k + 1] in {'x', 'X', 'o', 'O', 'b', 'B'}:
    k += 2
    while k < source.len and source[k] in {'0' .. '9', 'a' .. 'f', 'A' .. 'F', '_'}: inc k
  else:
    while k < source.len and source[k] in {'0' .. '9', '_'}: inc k
    if k < source.len and source[k] == '.' and source.isDigit(k + 1):
      inc k
      while k < source.len and source[k] in {'0' .. '9', '_'}: inc k
    if k < source.len and source[k] in {'e', 'E'}:
      if source.isDigit(k + 1): inc k
      elif k + 1 < source.len and source[k + 1] in {'+', '-'} and source.isDigit(k + 2): k += 2
      while k < source.len and source[k] in {'0' .. '9', '_'}: inc k
  if k < source.len and source[k] == '\'': inc k
  while k < source.len and source[k] in {'a' .. 'z', 'A' .. 'Z', '0' .. '9', '_'}: inc k
  k


func wordAfter(source: string, at: int): int =
  ## Find offset after identifier opening at `at`; operator glyph ends it.
  var k = at
  while k < source.len and source[k] in CHARS_NAME:
    if k > at and source.glyphLength(k) > 0: break
    inc k
  k


func operatorAfter(source: string, at: int): int =
  ## Find offset after run of operator characters and glyphs opening at `at`.
  var k = at
  while k < source.len:
    if source[k] in CHARS_OPERATOR: inc k
    else:
      let glyph = source.glyphLength(k)
      if glyph == 0: break
      k += glyph
  k


func tokens*(source: string): seq[Token] =
  ## Read every token of Nim source, in order; whitespace and line breaks lie between them.
  var
    i = 0
    line = 0
  while i < source.len:
    let c = source[i]
    if c == '\n':
      inc line
      inc i
      continue
    if c in {' ', '\t', '\r'}:
      inc i
      continue
    var
      kind = KindToken.Operator
      after = i + 1
    let next = if i + 1 < source.len: source[i + 1] else: '\0'
    case c
    of '#': (kind, after) = (KindToken.Comment, source.commentAfter(i))
    of '"': (kind, after) = (KindToken.Text, source.textAfter(i))
    of '\'': (kind, after) = (KindToken.Character, source.characterAfter(i))
    of '`':
      kind = KindToken.Quoted
      while after < source.len and source[after] notin {'`', '\n'}: inc after
      if after < source.len and source[after] == '`': inc after
    of '0' .. '9': (kind, after) = (KindToken.Number, source.numberAfter(i))
    of '(', '[', '{':
      kind = KindToken.Open
      let is_dotted = next == '.' and (i + 2 >= source.len or source[i + 2] != '.')
      if is_dotted or (c == '[' and next == ':'): after = i + 2
    of ')', ']', '}': kind = KindToken.Close
    of ',': kind = KindToken.Comma
    of ';': kind = KindToken.Semicolon
    of '.':
      if next in {')', ']', '}'}: (kind, after) = (KindToken.Close, i + 2)
      else: after = source.operatorAfter(i)
    of '*':
      let is_lone = next == ':' and (i + 2 >= source.len or source[i + 2] notin CHARS_OPERATOR)
      if not is_lone: after = source.operatorAfter(i)
    of '-':
      let is_negative = source.isDigit(i + 1) and (i == 0 or source[i - 1] in NEGATION_AFTER)
      if is_negative: (kind, after) = (KindToken.Number, source.numberAfter(i))
      else: after = source.operatorAfter(i)
    else:
      if c in CHARS_OPERATOR or source.glyphLength(i) > 0: after = source.operatorAfter(i)
      elif c in CHARS_NAME: (kind, after) = (KindToken.Word, source.wordAfter(i))
    result.add Token(kind: kind, first: i, after: after, line: line)
    for k in i ..< after:
      if source[k] == '\n': inc line
    i = after


func partners*(tokens: openArray[Token]): seq[int] =
  ## Pair each bracket with index of its partner; `-1` for every other token and unpaired one.
  result = newSeq[int](tokens.len)
  var opened: seq[int]
  for k, t in tokens:
    result[k] = -1
    case t.kind
    of KindToken.Open: opened.add k
    of KindToken.Close:
      if opened.len == 0: continue
      let o = opened.pop
      result[k] = o
      result[o] = k
    else: discard


func lineLast*(t: Token, source: string): int =
  ## Read zero-based line token closes on; long string and block comment span several.
  result = t.line
  for k in t.first ..< t.after:
    if source[k] == '\n': inc result


func spelling*(t: Token, source: string): string =
  ## Read text of token.
  source[t.first ..< t.after]


func isKeyword*(t: Token, source: string): bool =
  ## Decide whether token is keyword, never identifier.
  t.kind == KindToken.Word and t.spelling(source) in KEYWORDS


func isKeyword*(name: string): bool =
  ## Decide whether name reads as keyword: Nim compares rest of it without case and underscores.
  name.len > 0 and name[0] & name[1 .. ^1].replace("_", "").toLowerAscii in KEYWORDS


func isOperandEnd*(tokens: openArray[Token], k: int, source: string): bool =
  ## Decide whether token `k` ends operand, so operator after it stands in binary place.
  ##   Keyword ends none but `nil`, or one after `.` that names field, as `x.type`.
  let t = tokens[k]
  case t.kind
  of KindToken.Quoted, KindToken.Number, KindToken.Text, KindToken.Character: true
  of KindToken.Close: t.spelling(source) in [")", "]", "}"]
  of KindToken.Word:
    let is_field = k > 0 and tokens[k - 1].spelling(source) == "." and
      tokens[k - 1].after == t.first
    not t.isKeyword(source) or t.spelling(source) == "nil" or is_field
  else: false


func signatureOf*(tokens: openArray[Token], partners: openArray[int], k: int, source: string): int =
  ## Read index of routine keyword whose parameters `(` at `k` opens; `-1` where it opens none.
  ##   Named routine reads `proc name*[T](`, generic and export marker optional; `proc (` and
  ##   `proc(` open parameters of routine type or lambda.
  if tokens[k].spelling(source) != "(" or k == 0: return -1
  var j = k - 1
  if tokens[j].spelling(source) in KEYWORDS_ROUTINE: return j
  if tokens[j].spelling(source) == "]" and partners[j] > 0: j = partners[j] - 1
  if j >= 0 and tokens[j].spelling(source) == "*": dec j
  if j < 1 or tokens[j].kind notin {KindToken.Word, KindToken.Quoted}: return -1
  if tokens[j - 1].spelling(source) in KEYWORDS_ROUTINE: j - 1 else: -1


func isCallOpen*(tokens: openArray[Token], partners: openArray[int], k: int, source: string): bool =
  ## Decide whether `(` at `k` opens arguments of call: callee glued before it, never keyword.
  ##   Callee is name, quoted name, or closing bracket of generic or of earlier call; `cast[T]`
  ##   and parameters of routine are no call.
  if tokens[k].spelling(source) != "(" or k == 0 or tokens[k - 1].after != tokens[k].first:
    return false
  let callee = tokens[k - 1]
  if callee.kind notin {KindToken.Word, KindToken.Quoted, KindToken.Close}: return false
  if not tokens.isOperandEnd(k - 1, source): return false
  if callee.spelling(source) == "]" and partners[k - 1] > 0 and
      tokens[partners[k - 1] - 1].isKeyword(source):
    return false
  tokens.signatureOf(partners, k, source) < 0



func lineStarts*(source: string): seq[int] =
  ## Read byte offset each line opens at.
  result.add 0
  for k, c in source:
    if c == '\n': result.add k + 1
