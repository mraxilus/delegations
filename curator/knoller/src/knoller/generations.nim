## Write call of `define…` or `emit…` routine as prefix call, as STYLE.md §5 gives
##   (`emitFunc(name, docs)`, never `name.emitFunc(docs)`), and fix it (`koch fix`).
##   Call: name opening `define` or `emit`, then capital, after `.` glued to it (V.3).
##     Receiver module file imports qualifies name (`tessellate.emitObject`), so it stays.
##     Receiver is name with calls, indexes and fields glued after it, or bracket group, as
##     conversion reads it (`conversions.nim`); bracket group gives its parentheses to call,
##     tuple aside (`(a + b).emitF(c)` becomes `emitF(a + b, c)`).
##   `construct…` call takes subject test of STYLE.md §5, as every other call does.
##   Rewrite moves no reading: `x.emitF(y)` and `emitF(x, y)` are one call, and `.` binds
##     tighter than any prefix operator before it.
##   No fixer, check reports still: receiver on line above `.`, generic call or index after name
##     (`x.emitF[T](y)`), command call (`x.emitF y`), and call whose arguments open on line
##     after `(`. Each keeps layout hand chose, so hand writes it.
##   Cost: text reads no symbol, so field spelled as routine (`emitF`) would read as call; field
##     is `snake_case` (V.1), so none is.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, sets, strutils]
import ./[conversions {.all.}, reports, rules, spacing, tokens]


type Generation = object  ## Define one dotted call of `define…` or `emit…` routine.
  line: int  ## Zero-based line of `.`.
  first: int  ## Byte offset where rewrite starts: receiver, or `.` where none stands on line.
  after: int  ## Byte offset where rewrite stops: after `(` of call, or after name alone.
  shaped: string  ## Text rewrite writes over span; empty where no fixer reaches call.
  got: string  ## Call as written, receiver to name.


const
  VERBS_PREFIX = ["define", "emit"]
    ## Verbs of generation whose call is prefix call (STYLE.md §5); `construct` is free.
  PASSES_MAX = 8  ## Passes fixer takes at most; each writes calls whose receivers hold none.
  KINDS_ARGUMENT = {
    KindToken.Word, KindToken.Quoted, KindToken.Number, KindToken.Text, KindToken.Character,
    KindToken.Open,
  }
    ## Kinds of token that open argument of command call, one space after name.


func isNameGeneration(text: string): bool =
  ## Decide whether name opens verb `VERBS_PREFIX` lists, then capital.
  VERBS_PREFIX.anyIt(text.len > it.len and text.startsWith(it) and text[it.len] in {'A' .. 'Z'})


func generations(source: string): seq[Generation] =
  ## Find each dotted call of `define…` or `emit…` routine, with rewrite where fixer reaches it.
  let
    tokens = source.tokens
    partners = tokens.partners
    skipped = tokens.tokensPath(partners, source)
    modules = namesImported(tokens, partners, source)
  for k in 0 ..< tokens.len - 1:
    let t = tokens[k]
    if t.kind != KindToken.Operator or t.spelling(source) != "." or k in skipped: continue
    let name = tokens[k + 1]
    if name.first != t.after or name.kind != KindToken.Word: continue
    let callee = name.spelling(source)
    if not callee.isNameGeneration: continue
    let first =
      if k > 0 and tokens[k - 1].after == t.first: receiver(tokens, partners, k, source)
      else: -1

    # Module path qualifies name, and calls nothing by dot.
    if first == k - 1 and tokens[first].kind == KindToken.Word and
        tokens[first].spelling(source) in modules:
      continue
    var generation = Generation(
      line: t.line,
      first: (if first >= 0: tokens[first].first else: t.first),
      after: name.after,
    )
    generation.got = source[generation.first ..< name.after]
    if first < 0 or tokens[first].line != t.line:
      result.add generation
      continue

    # Shape rewrite: receiver opens arguments, or stands alone where call takes none.
    let
      receiver =
        if isGroup(tokens, partners, first, k - 1, source):
          source[tokens[first].after ..< tokens[k - 1].first].strip
        else: generation.got[0 ..< t.first - generation.first]
      o = k + 2
      is_glued = o < tokens.len and tokens[o].first == name.after
      opening = if is_glued: tokens[o].spelling(source) else: ""
      is_command = not is_glued and o < tokens.len and tokens[o].line == name.line and
        tokens[o].kind in KINDS_ARGUMENT and not tokens[o].isKeyword(source)
    if opening == "(" and partners[o] == o + 1:
      generation.shaped = callee & "(" & receiver
      generation.after = tokens[o].after
    elif opening == "(" and tokens[o + 1].line == tokens[o].line:
      generation.shaped = callee & "(" & receiver & ", "
      generation.after = tokens[o].after
    elif opening notin ["(", "["] and not is_command:
      generation.shaped = callee & "(" & receiver & ")"
    result.add generation


func checkGenerations*(path, source: string): seq[Report] =
  ## Report call of `define…` or `emit…` routine written by dot (STYLE.md §5).
  for generation in source.generations:
    result.add initReport(
      path,
      generation.line + 1,
      Rule.CallGeneration,
      "Call of `define…` or `emit…` is prefix call, as `emitFunc(name, docs)`; got `" &
        generation.got & "`.",
    )


func fixGenerations*(path, source: string): Fix =
  ## Write each call check reports as prefix call, where fixer reaches it; call whose span holds
  ##   another waits for next pass, so inner one is written first, and its text carries outward.
  result.source = source
  for pass in 1 .. PASSES_MAX:
    let found = result.source.generations.filterIt(it.shaped.len > 0)
    if found.len == 0: break
    var
      shaped = result.source
      step: Fix
    for generation in found.sortedByIt(-it.first):
      if found.anyIt(it.first >= generation.first and it.after <= generation.after and
          it.after - it.first < generation.after - generation.first):
        continue
      shaped = shaped[0 ..< generation.first] & generation.shaped & shaped[generation.after .. ^1]
      step.fixed.add initReport(path, generation.line + 1, Rule.CallGeneration)
    step.source = shaped
    step.fixed.reverse
    result = result.chain(step)
