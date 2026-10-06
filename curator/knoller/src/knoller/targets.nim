## Write `to<Target>` call with its plain subject first, as STYLE.md §5 gives (`b.toDigits`),
##   and fix it (`koch fix`).
##   `to<Target>` call: one argument, on one line, callee `to` and capital, neither generic
##     (`toX[T](y)`) nor already method call. Argument is plain: name, then any call, index or
##     field glued after it (`a.b(c)[i]`). Compound argument (`toMultivector(a + b)`, `-v`,
##     literal) stays prefix call, so no parentheses hide it (STYLE.md §5). Call followed by
##     bracket glued after it stays too, since `y.toX(z)` and `y.toX[T]` read otherwise.
##   Rewrite moves no reading: `toX(y)` and `y.toX` are one call, and `.` binds tighter than
##     any prefix operator before it.
##   Cost: `to<Target>` text reads no symbol, so field named as routine (`to_x`) would capture
##     method call; tree proof compares symbol each call resolves to, before and after.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, strutils]
import ./[reports, tokens]


type
  Target = object  ## Define one `to<Target>` call to write subject first.
    line: int  ## Zero-based line.
    first: int  ## Byte offset of callee.
    after: int  ## Byte offset after closing parenthesis.
    shaped: string  ## Call as rule writes it: argument, `.`, callee.
    got: string  ## Call as written.


const
  PASSES_MAX = 8  ## Passes target fixer takes at most; each writes calls nesting none.


func isTargetName(text: string): bool =
  ## Decide whether name is `to<Target>`: `to`, then capital.
  text.len > 2 and text.startsWith("to") and text[2] in {'A' .. 'Z'}


func isPlain(tokens: openArray[Token]; partners: openArray[int]; a, b: int; source: string): bool =
  ## Decide whether tokens `a` to `b` are name with call, index or field glued after it.
  if a > b or tokens[a].kind != TokenKind.Word or tokens[a].isKeyword(source): return false
  var k = a + 1
  while k <= b:
    let t = tokens[k]
    if t.first != tokens[k - 1].after: return false
    if t.kind == TokenKind.Open and t.spelling(source) in ["(", "["] and partners[k] in k .. b:
      k = partners[k] + 1
    elif t.spelling(source) == "." and k + 1 <= b and tokens[k + 1].kind == TokenKind.Word and
        tokens[k + 1].first == t.after:
      k += 2
    else: return false
  true


func targets(source: string): seq[Target] =
  ## Find each one-argument `to<Target>` prefix call whose argument is plain.
  let
    tokens = source.tokens
    partners = tokens.partners
  for k in 0 ..< tokens.len - 1:
    let t = tokens[k]
    if t.kind != TokenKind.Word or not t.spelling(source).isTargetName: continue
    if k > 0 and tokens[k - 1].spelling(source) == "." and tokens[k - 1].after == t.first:
      continue
    let o = k + 1
    if not tokens.isCallOpen(partners, o, source) or partners[o] <= o + 1: continue
    let c = partners[o]
    if tokens[c].line != t.line or toSeq(o .. c).anyIt(tokens[it].lastLine(source) != t.line):
      continue
    if not tokens.isPlain(partners, o + 1, c - 1, source): continue
    if c + 1 < tokens.len and tokens[c + 1].first == tokens[c].after and
        tokens[c + 1].kind == TokenKind.Open:
      continue
    let argument = source[tokens[o + 1].first ..< tokens[c - 1].after]
    result.add Target(
      line: t.line,
      first: t.first,
      after: tokens[c].after,
      shaped: argument & "." & t.spelling(source),
      got: source[t.first ..< tokens[c].after],
    )


func checkTargets*(path, source: string): seq[Report] =
  ## Report `to<Target>` prefix call whose plain subject could come first (STYLE.md §5).
  ##   Named by its suite and `fixes.nim` alone until static pass calls it (`fixes.nim`).
  for target in source.targets:
    result.add initReport(
      path,
      target.line + 1,
      Rule.TargetSubject,
      "`to<Target>` takes its plain subject first, as `b.toDigits`; got `" & target.got & "`.",
    )


func fixTargets*(path, source: string): Fix =
  ## Write each call check reports subject first; call holding another such call waits for
  ##   next pass, so inner one is written first, and its text carries into outer one.
  result.source = source
  for pass in 1 .. PASSES_MAX:
    let found = result.source.targets
    if found.len == 0: break
    var
      shaped = result.source
      step: Fix
    for target in found.sortedByIt(-it.first):
      if found.anyIt(it.first > target.first and it.after <= target.after): continue
      shaped = shaped[0 ..< target.first] & target.shaped & shaped[target.after .. ^1]
      step.fixed.add initReport(path, target.line + 1, Rule.TargetSubject)
    step.source = shaped
    step.fixed.reverse
    result = result.chain(step)
