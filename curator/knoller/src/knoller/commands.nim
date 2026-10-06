## Write dotted call statement in command form where its one argument is call or parenthesised
##   expression, as STYLE.md §5 gives (`result.add BasisSigned(…)`), and fix it (`koch fix`).
##   Dotted call: method call syntax, `x.f(…)`, receiver chain glued from start of statement
##     (`result[a][b].add(`). One argument, no comma after it, glued inside both brackets: call
##     (`Y(…)`, constructor, generic call `Y[T](…)`) or parenthesised expression (`(a, b)`).
##     So `x.f(Y(…))` becomes `x.f Y(…)`, and `x.f((a, b))` becomes `x.f (a, b)`; double
##     bracket goes. Call spanning lines keeps its inner layout, and its `))` becomes `)`.
##   Whole statement only: chain opens line where statement starts, after statement ending line,
##     block `:` or `=` of routine head, and its `)` ends its line. Inside expression, command
##     form can parse otherwise (`x.f g(a) + 1` reads `x.f(g(a) + 1)`), so `let y = x.f(g(a))`,
##     `discard …` and assignment stay.
##   Rewrite moves no reading but node kind: parser reads `nkCommand` where it read `nkCall`
##     around same callee and argument. Rewrite never widens line: `(` becomes space, `)` goes.
##   Left as written: plain call `f(g(x))`, call of two or more arguments or with comma after
##     last, argument of other shape (`g(a) + 1`, `g(a).h`, `@[a]`), `cast[T](…)`.
##
##   Cost: scanner, never parser (`tokens.nim`); statement whose start it cannot read stays.

{.experimental: "strictFuncs".}

import std/algorithm
import ./[precedence, reports, tokens]


type Command = object  ## Define one dotted call statement to write in command form.
  line: int  ## Zero-based line statement opens on.
  open: int  ## Byte offset of `(` of dotted call.
  close: int  ## Byte offset of `)` of dotted call.
  got: string  ## Statement through head of its argument, as written.


const
  KEYWORDS_ROUTINE = ["converter", "func", "iterator", "macro", "method", "proc", "template"]
    ## Keywords whose head line, ending on `=`, opens body of statements.
  KEYWORDS_CONTINUING = [
    "and", "as", "div", "in", "is", "isnot", "mod", "notin", "of", "or", "shl", "shr", "xor",
  ]
    ## Keyword operators line may end on, continuing expression on next line.


func isLast(tokens: openArray[Token], k: int, source: string): bool =
  ## Decide whether token `k` ends its line, comment after it aside.
  let line = tokens[k].lineLast(source)
  k == tokens.high or tokens[k + 1].line > line or
    (tokens[k + 1].kind == KindToken.Comment and tokens[k + 1].lineLast(source) == line and
      (k + 1 == tokens.high or tokens[k + 2].line > line))


func isStatementStart(tokens: openArray[Token], k: int, source: string): bool =
  ## Decide whether line-first token `k` opens statement: code before it ends statement, ends
  ##   line on block `:`, or ends routine head on `=`.
  var j = k - 1
  while j >= 0 and tokens[j].kind == KindToken.Comment: dec j
  if j < 0: return true
  let text = tokens[j].spelling(source)
  case tokens[j].kind
  of KindToken.Comma, KindToken.Open, KindToken.Semicolon: false
  of KindToken.Operator:
    if text == ":": return true
    if text != "=": return false

    # `=` opens body where its line opens routine head, or closes wrapped signature.
    var first = j
    while first > 0 and tokens[first - 1].line == tokens[j].line: dec first
    let head = tokens[first].spelling(source)
    head in KEYWORDS_ROUTINE or head == ")"
  of KindToken.Word: text notin KEYWORDS_CONTINUING
  else: true


func commands(source: string): seq[Command] =
  ## Find each dotted call statement whose one argument is call or parenthesised expression.
  let
    tokens = source.tokens
    partners = tokens.partners
  for k, t in tokens:
    let is_first = k == 0 or tokens[k - 1].lineLast(source) < t.line
    if not is_first or t.kind != KindToken.Word or t.isKeyword(source): continue
    if not tokens.isStatementStart(k, source): continue

    # Walk receiver chain while its tokens stay glued; last bracket group ends statement.
    var e = k
    while true:
      if tokens[e].kind == KindToken.Open:
        if partners[e] < e: break
        e = partners[e]
      if e == tokens.high or tokens[e + 1].first != tokens[e].after: break
      if tokens[e + 1].kind notin {KindToken.Word, KindToken.Open, KindToken.Operator}: break
      if tokens[e + 1].kind == KindToken.Operator and tokens[e + 1].spelling(source) != ".": break
      inc e
    let o = partners[e]
    if tokens[e].spelling(source) != ")" or o < k + 3 or not tokens.isLast(e, source): continue
    let is_dotted = tokens[o-1].kind == KindToken.Word and tokens[o-2].spelling(source) == "." and
      tokens[o-2].after == tokens[o-1].first and tokens[o-1].after == tokens[o].first
    if not is_dotted or not tokens.isCallOpen(partners, o, source): continue

    # One argument glued inside both brackets: call, or parenthesised expression.
    let (first, last) = (o + 1, e - 1)
    if first > last or tokens[first].first != tokens[o].after: continue
    if tokens[last].after != tokens[e].first or tokens[last].spelling(source) != ")": continue
    let inner = partners[last]
    if inner < first: continue
    let is_group = inner == first
    if not is_group:
      let elements = elementsOf(tokens, partners, first, last, source)
      if elements.len != 1 or elements[0].kind != KindElement.Operand: continue
      if not tokens.isCallOpen(partners, inner, source): continue
    result.add Command(
      line: t.line,
      open: tokens[o].first,
      close: tokens[e].first,
      got: source[t.first ..< tokens[first].after],
    )


func checkCommands*(path, source: string): seq[Report] =
  ## Report dotted call statement whose one argument is call or parenthesised expression,
  ##   written in call form (STYLE.md §5).
  ##   Named by its suite and `fixes.nim` alone until static pass calls it (`fixes.nim`).
  for command in source.commands:
    result.add initReport(
      path,
      command.line + 1,
      Rule.CommandDotted,
      "Dotted call statement takes command form where its one argument is call or " &
        "parenthesised expression; got `" & command.got & "`.",
    )


func fixCommands*(path, source: string): Fix =
  ## Write each statement check reports in command form: `(` becomes space, its `)` goes; last
  ##   first, so earlier offsets hold.
  result.source = source
  let found = source.commands
  for command in found.sortedByIt(-it.open):
    result.source = result.source[0 ..< command.open] & " " &
      result.source[command.open + 1 ..< command.close] & result.source[command.close + 1 .. ^1]
  for command in found: result.fixed.add initReport(path, command.line + 1, Rule.CommandDotted)
