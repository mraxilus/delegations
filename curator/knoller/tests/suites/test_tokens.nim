## Hold token scanner to compiler's lexer: each byte outside whitespace lies in one token, and
##   each literal, comment, bracket and operator form reads as `compiler/lexer.nim` reads it.

{.experimental: "strictFuncs".}

import std/[sequtils, unittest]
import ../../src/knoller/tokens


const SAMPLE =
  "proc `+`*[T](a: T; b = -1): T {.inline.} =\n" &
  "  ## Doc.\n" &
  "  let s = r\"a\"\"b\" & fmt\"{x}\\n\" & \"c\\\"d\" & '\\'' & '\\x41'\n" &
  "  #[ block #[ nested ]# still ]#\n" &
  "  ##[ doc block ]##\n" &
  "  result = a.b[^1] + 0x1F'u8 + 1.5e-3 + `x`\n" &
  "  let t = \"\"\"\nlong \"\" text\"\"\"\"\n"
  ## Source holding every literal, comment and bracket form scanner tells apart.


func spellings(source: string): seq[string] =
  ## Read spelling of each token of source.
  source.tokens.mapIt(it.spelling(source))


func kinds(source: string): seq[TokenKind] =
  ## Read kind of each token of source.
  source.tokens.mapIt(it.kind)



suite "Tokens":
  test "each byte outside whitespace lies in one token, and tokens keep source order":
    let found = SAMPLE.tokens
    var covered = newSeq[bool](SAMPLE.len)
    for t in found:
      for k in t.first ..< t.after: covered[k] = true
    for k, c in SAMPLE:
      check covered[k] or c in {' ', '\n'}  # whitespace alone lies between tokens
    for k in 1 ..< found.len: check found[k - 1].after <= found[k].first  # no overlap


  test "string, character and comment forms read whole, as lexer reads them":
    check "r\"a\"\"b\"".kinds == @[TokenKind.Word, TokenKind.Text]  # `""` escapes raw quote
    check "fmt\"{x}\\n\"".spellings == @["fmt", "\"{x}\\n\""]  # generalized raw, `\` kept
    check "\"c\\\"d\"".kinds == @[TokenKind.Text]  # escaped quote stays inside
    check "'\\'' '\\x41' 'a'".kinds == TokenKind.Character.repeat(3)  # escapes read whole
    check "#[ a #[ b ]# c ]# x".spellings == @["#[ a #[ b ]# c ]#", "x"]  # block nests
    check "##[ a ]## x".spellings == @["##[ a ]##", "x"]  # doc block closes on `]##`
    check "\"\"\"a\"\"\"\" x".spellings == @["\"\"\"a\"\"\"\"", "x"]  # last quote of run closes


  test "operator characters and glyphs run as one operator":
    check "m ∧☆ n".spellings == @["m", "∧☆", "n"]  # compound glyph operator
    check "a=-1".spellings == @["a", "=-", "1"]  # `=-` is one token, as lexer reads it
    check "0..<n".spellings == @["0", "..<", "n"]  # number stops before range
    check "x*: int".spellings == @["x", "*", ":", "int"]  # `*` before lone `:` stands alone
    check "☆m".spellings == @["☆", "m"]  # glyph of commit pin opens operator


  test "minus before digit opens number after whitespace or opening, never after operand":
    check "f -1".kinds == @[TokenKind.Word, TokenKind.Number]  # command call of literal
    check "(-1, -2)".spellings == @["(", "-1", ",", "-2", ")"]
    check "a-1".spellings == @["a", "-", "1"]  # binary minus
    check "1.5e-3 0x1F'u8".spellings == @["1.5e-3", "0x1F'u8"]  # exponent and suffix


  test "pragma and dotted brackets pair, and every bracket finds its partner":
    let
      source = "f(a[b], {.c.}, {d})"
      found = source.tokens
      partners = found.partners
    check source.spellings == @["f", "(", "a", "[", "b", "]", ",", "{.", "c", ".}", ",", "{",
                                "d", "}", ")"]
    check partners[1] == found.high and partners[found.high] == 1  # outermost pair
    check partners[7] == 9  # `{.` closes on `.}`
    check partners[0] == -1  # no bracket, no partner


  test "operand end tells binary place from prefix place":
    let
      source = "return x.type nil (a)"
      found = source.tokens
    check found[0].isKeyword(source) and not found[1].isKeyword(source)
    check not found.isOperandEnd(0, source)  # keyword ends no operand
    check found.isOperandEnd(1, source)  # name
    check found.isOperandEnd(3, source)  # keyword naming field after `.`
    check found.isOperandEnd(4, source)  # `nil`
    check found.isOperandEnd(7, source)  # closing bracket


  test "parameters of routine, routine type and lambda tell apart from call":
    let
      source = "proc f*[T](a: T) = g(a); let h = proc (b: int) = cast[int](b); k (c)"
      found = source.tokens
      partners = found.partners
    var opens: seq[int]
    for k, t in found:
      if t.spelling(source) == "(": opens.add k
    check found.signatureOf(partners, opens[0], source) == 0  # named, generic, exported
    check found.isCallOpen(partners, opens[1], source)  # `g(`
    check found.signatureOf(partners, opens[2], source) >= 0  # lambda `proc (`
    check not found.isCallOpen(partners, opens[3], source)  # `cast[int](` is no call
    check not found.isCallOpen(partners, opens[4], source)  # space before `(`: tuple argument


  test "token spanning lines reports line it closes on":
    let found = SAMPLE.tokens
    check found.anyIt(it.lastLine(SAMPLE) > it.line)  # long string spans lines
    check found.allIt(it.lastLine(SAMPLE) >= it.line)
    check "a\nbc\n".lineStarts == @[0, 2, 5]  # line after final newline opens empty
