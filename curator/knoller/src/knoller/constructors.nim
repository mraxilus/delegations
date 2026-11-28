## Report each constructor package calls both by dot and by prefix call, since subject test of
##   STYLE.md §5 gives one answer for one routine, so calls of one constructor take one form.
##   Constructor is `init…` routine package declares (V.3). Call takes dot on plain receiver, or
##     prefix call on plain first argument, plain as `targets.nim` reads it: name with calls,
##     indexes and fields glued after it. Prefix call whose first argument is compound takes
##     neither form, since dot cannot take it without parentheses, and so do generic call,
##     command call and call of no argument.
##   Text cannot tell whether first argument is subject, so check reports form fewer calls across
##     package take, or both where they tie, and fix writes none (Architect's ruling, #443).
##   Caller counts calls of each constructor across package (`callsConstructor`), and passes
##     them in (`NamesPackage`), since rule reads one file.
##
##   Cost: text reads no symbol, so routine of other module spelled as constructor of package
##     counts as it; field is `snake_case` (V.1), so none reads as routine.
##   Cost: call forms of other routines stay unread (Architect's ruling, #443), so routine other
##     than constructor may take both forms; page of #443 shows reading every routine reads
##     `len`, `countSetBits` and `abs` library borrows or overloads.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, sets, strutils]
import ./[conversions {.all.}, declared, reports, rules, targets {.all.}, tokens]


type  # TODO: Document.
  FormCall {.pure.} = enum  ## Define form of call of constructor on plain first argument.
    Dotted  ## Dot on plain receiver: `b.initElement(1)`.
    Prefixed  ## Prefix call on plain first argument: `initElement(Basis.origin)`.

  Call = object  ## Define one call of constructor, in one of its forms.
    name: string  ## Constructor called.
    line: int  ## Zero-based line of its name.
    form: FormCall
    got: string  ## Call as written, receiver or arguments included.

  Calls* = object  ## Define calls of one constructor across package, by form.
    name*: string  ## Constructor, as `initElement`.
    dotted*: int  ## Calls taking dot on plain receiver.
    prefixed*: int  ## Calls taking prefix call on plain first argument.


const VERB_CONSTRUCTOR = "init"  ## Verb of constructor of value (V.3).


func constructorsDeclared(source: string): seq[string] =
  ## Read name of each constructor source declares: routine opening `init`, then capital (V.3).
  for d in source.declarations:
    if d.kind == KindName.Routine and d.name.len > VERB_CONSTRUCTOR.len and
        d.name.startsWith(VERB_CONSTRUCTOR) and d.name[VERB_CONSTRUCTOR.len] in {'A' .. 'Z'}:
      result.add d.name


func callsNamed(source: string; names: openArray[string]): seq[Call] =
  ## Read each call of constructor `names` gives, by dot on plain receiver or by prefix call on
  ##   plain first argument; declaration and call of neither form are left out.
  let
    tokens = source.tokens
    partners = tokens.partners
    modules = namesImported(tokens, partners, source)
  for k, t in tokens:
    if t.kind != KindToken.Word or t.spelling(source) notin names: continue
    if k > 0 and tokens[k - 1].isKeyword(source): continue
    let o = k + 1
    if o < tokens.len and tokens[o].first == t.after and tokens[o].spelling(source) == "[":
      continue
    let
      is_called = o < tokens.len and tokens.isCallOpen(partners, o, source)
      after = if is_called: tokens[partners[o]].after else: t.after

    # Dot on receiver of name with calls, indexes and fields glued, never module.
    if k > 1 and tokens[k - 1].spelling(source) == "." and tokens[k - 1].after == t.first:
      let first = receiver(tokens, partners, k - 1, source)
      if first < 0 or not tokens.isPlain(partners, first, k - 2, source): continue
      if first == k - 2 and tokens[first].spelling(source) in modules: continue
      result.add Call(
        name: t.spelling(source),
        line: t.line,
        form: FormCall.Dotted,
        got: source[tokens[first].first ..< after],
      )
      continue

    # Prefix call whose first argument, up to its comma, is plain.
    if not is_called or partners[o] == o + 1: continue
    var last = o + 1
    while last < partners[o] and tokens[last].kind != KindToken.Comma:
      if tokens[last].kind == KindToken.Open and partners[last] > last: last = partners[last]
      inc last
    if not tokens.isPlain(partners, o + 1, last - 1, source): continue
    result.add Call(
      name: t.spelling(source),
      line: t.line,
      form: FormCall.Prefixed,
      got: source[t.first ..< after],
    )


func callsConstructor*(sources: openArray[string]): seq[Calls] =
  ## Count calls of each constructor sources declare, by form, across them: modules of package.
  var names: seq[string]
  for source in sources:
    for name in source.constructorsDeclared:
      if name notin names: names.add name
  for name in names.sorted: result.add Calls(name: name)
  for source in sources:
    for call in source.callsNamed(names):
      let at = result.mapIt(it.name).find(call.name)
      if call.form == FormCall.Dotted: inc result[at].dotted
      else: inc result[at].prefixed


func checkConstructors*(path, source: string; calls: openArray[Calls]): seq[Report] =
  ## Report each call of constructor in form fewer calls across package take, or in either form
  ##   where they tie (STYLE.md §5); `calls` counts each across package.
  let names = calls.mapIt(it.name)
  for call in source.callsNamed(names):
    let
      counts = calls[names.find(call.name)]
      own = if call.form == FormCall.Dotted: counts.dotted else: counts.prefixed
      other = if call.form == FormCall.Dotted: counts.prefixed else: counts.dotted
    if own > other: continue
    let taken =
      if own == other: "`" & $other & "` calls take each form"
      elif call.form == FormCall.Dotted: "`" & $other & "` calls take prefix call"
      else: "`" & $other & "` calls take dot"
    result.add initReport(
      path,
      call.line + 1,
      Rule.PrefixConversion,
      "Routine takes one call form on plain first argument across package, where " & taken &
        "; got `" & call.got & "`.",
    )
