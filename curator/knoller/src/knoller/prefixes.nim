## Write `to<Target>` call of compound argument as prefix call, as STYLE.md §5 gives
##   (`toMultivector(a + b)`, never `(a + b).toMultivector`), and fix it (`koch fix`).
##   Compound argument is bracket group holding expression with operator, as `(a + b)` or
##     `(|𝐦)`: group of one plain operand, or of one literal, is none, and tuple is no group.
##     Plain is name with calls, indexes and fields glued after it, as `targets.nim` reads it,
##     and `to<Target>` is `to` and capital, as there, so `($rule).toLowerAscii` becomes
##     `toLowerAscii($rule)`.
##   Fix gives parentheses of group to call, so `(a).toX(c)` becomes `toX(a, c)`, and `.` binding
##     tighter than any prefix operator before it moves no reading. Rewrite is reverse of
##     `to<Target>` subject first, which leaves compound argument prefix call, so neither undoes
##     other.
##   No fixer, check reports still: generic call (`(a + b).toX[T]`), and call spanning lines,
##     whose layout hand chose.
##
##   Cost: text reads no symbol, so field named as routine (`to_x`) would read as call; field is
##     `snake_case` (V.1), so none is.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, strutils]
import ./[conversions {.all.}, reports, rules, targets {.all.}, tokens]


type Prefix = object  ## Define dotted `to<Target>` call of compound argument.
  line: int  ## Zero-based line of `.`.
  first: int  ## Byte offset of group's `(`.
  after: int  ## Byte offset after call: after its `)`, or after name where it takes none.
  shaped: string  ## Call as prefix call; empty where fixer reaches none.
  got: string  ## Call as written.


const PASSES_MAX = 8  ## Passes fixer takes at most; each writes calls whose spans hold none.


func isCompound(
  tokens: openArray[Token]; partners: openArray[int]; a, b: int; source: string
): bool =
  ## Decide whether tokens `a` to `b` hold expression with operator: neither one plain operand nor
  ##   one literal.
  if a > b: return false
  if a == b and tokens[a].kind in {KindToken.Number, KindToken.Text, KindToken.Character}:
    return false
  not tokens.isPlain(partners, a, b, source)


func prefixes(source: string): seq[Prefix] =
  ## Find each `to<Target>` call glued by dot after group holding compound argument, with rewrite
  ##   where fixer reaches it.
  let
    tokens = source.tokens
    partners = tokens.partners
  for k in 1 ..< tokens.len - 1:
    let t = tokens[k]
    if t.kind != KindToken.Operator or t.spelling(source) != ".": continue
    let
      close = k - 1
      name = tokens[k + 1]
    if tokens[close].spelling(source) != ")" or tokens[close].after != t.first: continue
    if name.first != t.after or name.kind != KindToken.Word: continue
    if not name.spelling(source).isNameTarget: continue
    let open = partners[close]
    if open < 0 or tokens.isCallOpen(partners, open, source): continue
    if not isGroup(tokens, partners, open, close, source): continue
    if not tokens.isCompound(partners, open + 1, close - 1, source): continue

    # Shape prefix call: group's text opens arguments, then call's own where it takes some.
    let
      callee = name.spelling(source)
      inner = source[tokens[open].after ..< tokens[close].first]
      o = k + 2
      is_glued = o < tokens.len and tokens[o].first == name.after
      opening = if is_glued: tokens[o].spelling(source) else: ""
    var prefix = Prefix(line: t.line, first: tokens[open].first, after: name.after)
    if opening == "(" and partners[o] > o:
      prefix.after = tokens[partners[o]].after
      let arguments = source[tokens[o].after ..< tokens[partners[o]].first]
      prefix.shaped =
        if arguments.strip.len == 0: callee & "(" & inner & ")"
        else: callee & "(" & inner & ", " & arguments & ")"
    elif opening notin ["(", "["]: prefix.shaped = callee & "(" & inner & ")"
    prefix.got = source[prefix.first ..< prefix.after]
    if '\n' in prefix.got: prefix.shaped = ""
    result.add prefix


func checkPrefixes*(path, source: string): seq[Report] =
  ## Report each `to<Target>` call written by dot after compound argument (STYLE.md §5).
  for prefix in source.prefixes:
    result.add initReport(
      path,
      prefix.line + 1,
      Rule.PrefixConversion,
      "Conversion of compound argument is prefix call, as `toMultivector(a + b)`; got `" &
        prefix.got & "`.",
    )


func fixPrefixes*(path, source: string): Fix =
  ## Write each call check reports as prefix call, where fixer reaches it; call whose span holds
  ##   another waits for next pass, so inner one is written first, and its text carries outward.
  result.source = source
  for pass in 1 .. PASSES_MAX:
    let found = result.source.prefixes.filterIt(it.shaped.len > 0)
    if found.len == 0: break
    var
      shaped = result.source
      step: Fix
    for prefix in found.sortedByIt(-it.first):
      if found.anyIt(it.first >= prefix.first and it.after <= prefix.after and
          it.after - it.first < prefix.after - prefix.first):
        continue
      shaped = shaped[0 ..< prefix.first] & prefix.shaped & shaped[prefix.after .. ^1]
      step.fixed.add initReport(path, prefix.line + 1, Rule.PrefixConversion)
    step.source = shaped
    step.fixed.reverse
    result = result.chain(step)
