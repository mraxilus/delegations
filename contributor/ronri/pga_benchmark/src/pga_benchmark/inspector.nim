## Read counts out of C compiler emits: terms, divisions, zero fills, intermediates, checks.
##   Library's operators are straight-line C, one function each; what that function spends
##   is countable from its text, deterministically, so regression in it is finding rather
##   than timing noise (Article VII.1 asks emitted code be read; this reads it every run).
##   Reference forms are inline functions in same cache, counted same way, so both implementations
##   of gap list come from one reader.
##
##   Names are read back through compiler's own mangling: ASCII operator characters become
##     words (`bar` for `|`, `roof` for `^`), other bytes become `X<hex>`, and any of those
##     appends `_`; then `_u<n>` disambiguates overloads and `__<module>` names module.
##     Reader strips suffix from last `__`, then decodes head only where trailing `_` says
##     it was encoded.
##   Terms inside loop count once per trip where loop's bound is literal (`for b in Basis`,
##     `0 ..< 16`); bound naming variable counts once, since trips are not in text.
##   Counts are own body's, then total with callees found in same reading, recursively,
##     since library chains (norm calls both norms; support calls three products) spend
##     what their callees spend.
##
##   Cost: text reading is by substring, so pattern compiler changes would silently miss;
##     suite `Inspector` holds reader to fixture and to this project's own nimcache.

{.experimental: "strictFuncs".}

import std/[algorithm, os, strutils, tables]


type
  CFunction* = object
    ## Define one function read from emitted C.
    name*: string
      ## Mangled name as emitted.
    symbol*: string
      ## Demangled head, e.g. `∧`, `|∙`, `wedge`, `{}`.
    module*: string
      ## Module suffix after last `__`, e.g. `referenceZrigid3`; empty where name has none.
    overload*: int
      ## Overload index `_u<n>`, `-1` where name carries none.
    params*: seq[string]
      ## Parameter type stems in order, e.g. `Multivector`, `Point`, `float`; `Result` excluded.
    result_stem*: string
      ## Type stem of what call writes: `Result` parameter's, else return type's; `void` if none.
    is_inline*: bool
      ## True for `static N_INLINE`, false for `N_NIMCALL`.
    body*: string
      ## Text between function's braces.
  Counts* = object
    ## Define what one function's text spends.
    multiplies*, adds*, subs*, divides*: int
      ## Floating operations spelled as terms; divisions cost several multiplies each.
    zero_fills*: int
      ## `nimZeroMem` calls, i.e. whole-object zero fills.
    intermediates*: int
      ## Local multivector objects declared.
    copies*: int
      ## Whole-object assignments and memory copies.
    checks*: int
      ## Error-flag branches after calls.
    calls*: int
      ## Call sites of other Nim functions, accessor reads excluded.
    allocations*: int
      ## Heap allocation calls.
    lines*: int
      ## Lines of body.


const
  SPECIALS = [
    ("backslash", "\\"), ("percent", "%"), ("dollar", "$"), ("colon", ":"), ("emark", "!"),
    ("qmark", "?"), ("minus", "-"), ("slash", "/"), ("tilde", "~"), ("roof", "^"),
    ("star", "*"), ("plus", "+"), ("amp", "&"), ("bar", "|"), ("dot", "."), ("at", "@"),
    ("eq", "="), ("lt", "<"), ("gt", ">"),
  ]
    ## Words compiler spells ASCII operator characters with, longest first.
  MULTIVECTOR* = "tyObject_Multivector"
    ## Type stem of library's dense object in emitted C.
  ACCESSOR = "X5BX5D_"
    ## Mangled head of `[]`, whose calls are element reads and not counted as calls.



#[ Names ]#

func stripSuffix(name: string): string =
  ## Drop `_u<n>__module` or `_c<n>__module` suffix, leaving mangled head as encoded.
  let stop = name.rfind("__")
  if stop < 0: return name
  var i = stop - 1
  while i >= 0 and name[i] in Digits: dec i
  if i >= 1 and name[i] in {'u', 'c'} and name[i - 1] == '_': name[0 ..< i - 1]
  else: name[0 ..< stop]


func decode(head: string): string =
  ## Decode encoded head: `X<hex>` bytes and special words become characters.
  var i = 0
  while i < head.len:
    if head[i] == 'X' and i + 2 < head.len and head[i + 1] in HexDigits and
        head[i + 2] in HexDigits:
      result.add char(parseHexInt(head[i + 1 .. i + 2]))
      i += 3
      continue
    var is_special = false
    for (word, c) in SPECIALS:
      if head.continuesWith(word, i):
        result.add c
        i += word.len
        is_special = true
        break
    if not is_special:
      result.add head[i]
      inc i


func demangle*(name: string): string =
  ## Read symbol out of mangled function name.
  ##   Head ending in `_` was encoded and is decoded; plain head is identifier as written.
  let head = name.stripSuffix
  if head.len > 0 and head[^1] == '_': decode(head[0 ..< head.high])
  else: head


func stemOf(param: string): string =
  ## Read type stem of one C parameter or return type, e.g. `Point` from
  ## `tyObject_Point__hash* p_p0`, `float` from `NF`, `Basis` from `tyEnum_Basis__hash`.
  let text = param.strip
  for prefix in ["tyObject_", "tyEnum_", "tyDistinct_", "tyTuple_"]:
    if text.startsWith(prefix):
      let start = prefix.len
      var stop = start
      while stop < text.len and text[stop] notin {'_', '*', ' '}: inc stop
      return text[start ..< stop]
  if text == "NF" or text.startsWith("NF "): return "float"
  if text == "NI" or text.startsWith("NI "): return "int"
  if text == "NIM_BOOL" or text.startsWith("NIM_BOOL "): return "bool"
  text.split(' ')[0]


func moduleOf(name: string): string =
  ## Read module suffix after last `__`; empty where name carries none.
  let at = name.rfind("__")
  if at < 0: "" else: name[at + 2 ..< name.len]


func overloadOf*(name: string): int =
  ## Read overload index `_u<n>` before module suffix; `-1` where name carries none.
  ##   Compiler numbers overloads in declaration order within module, so index is stable
  ##   where emission order is not.
  let stop = name.rfind("__")
  if stop < 0: return -1
  var i = stop - 1
  while i >= 0 and name[i] in Digits: dec i
  if i >= 1 and i < stop - 1 and name[i] == 'u' and name[i - 1] == '_':
    parseInt(name[i + 1 ..< stop])
  else: -1



#[ Functions ]#

func functionsIn*(source: string): seq[CFunction] =
  ## Read every function definition of C source, with its parameter stems and body.
  ##   Definition opens on line `N_NIMCALL(<type>, <name>)(<params>) {` or
  ##   `static N_INLINE(<type>, <name>)(<params>) {`; declarations end in `;` and are
  ##   skipped. Body runs to brace closing that line's.
  var pos = 0
  while pos < source.len:
    let line_end = source.find('\n', pos)
    let stop = if line_end < 0: source.len else: line_end
    let line = source[pos ..< stop]
    pos = stop + 1
    let is_inline = line.startsWith("static N_INLINE(")
    let is_call = line.startsWith("N_NIMCALL(") or line.startsWith("N_LIB_PRIVATE N_NIMCALL(")
    if not (is_inline or is_call) or not line.endsWith("{"): continue
    let open_paren = line.find('(')
    let comma = line.find(',', open_paren)
    let close_name = line.find(')', comma)
    if comma < 0 or close_name < 0: continue
    let name = line[comma + 1 ..< close_name].strip
    let returns = line[open_paren + 1 ..< comma].stemOf
    let params_start = line.find('(', close_name)
    let params_stop = line.rfind(')')
    if params_start < 0 or params_stop <= params_start: continue
    var params: seq[string]
    var result_stem = returns
    for param in line[params_start + 1 ..< params_stop].split(','):
      let stem = param.stemOf
      if stem.len == 0: continue
      if param.strip.endsWith(" Result"): result_stem = stem
      else: params.add stem
    var depth = 1
    var i = pos
    while i < source.len and depth > 0:
      if source[i] == '{': inc depth
      elif source[i] == '}': dec depth
      inc i
    result.add CFunction(
      name: name,
      symbol: name.demangle,
      module: name.moduleOf,
      overload: name.overloadOf,
      params: params,
      result_stem: result_stem,
      is_inline: is_inline,
      body: source[pos ..< i],
    )
    pos = i


func plainSites(body: string): seq[string] =
  ## Read mangled name at every call site of Nim function in text holding no loop,
  ## accessor reads excluded. Call is identifier holding `__` followed by `(`; runtime
  ## helpers hold none.
  var i = 0
  while i < body.len:
    if body[i] notin IdentStartChars:
      inc i
      continue
    var stop = i
    while stop < body.len and body[stop] in IdentChars: inc stop
    let name = body[i ..< stop]
    i = stop
    if stop < body.len and body[stop] == '(' and "__" in name and not name.startsWith(ACCESSOR):
      result.add name


func countIntermediates(body: string): int =
  ## Count local multivector declarations, i.e. lines `tyObject_Multivector__<id> T<n>_;`.
  for line in body.splitLines:
    let s = line.strip
    if s.startsWith(MULTIVECTOR) and s.endsWith("_;") and " T" in s and '*' notin s:
      inc result


const
  LOOP_OPEN = "while (1) {"
    ## Text every loop compiler emits opens with; bound is tested inside.
  BOUND_OPEN = "if ((!(("
    ## Text loop's bound test opens with, e.g. `if ((!((i_1 < ((NI) 16))))) {`.
  BOUND_TYPE = "((NI) "
    ## Text before literal bound; bound naming variable instead is unknown.


func startOf(context: string; counter: string): int =
  ## Read value counter was last set to before loop, `<counter> = ((NI) <n>);`; zero else.
  let at = context.rfind(counter & " = ((NI) ")
  if at < 0: return 0
  let from_digits = at + counter.len + " = ((NI) ".len
  var stop = from_digits
  while stop < context.len and context[stop] in Digits: inc stop
  if stop == from_digits: 0 else: parseInt(context[from_digits ..< stop])


func tripsOf(inner, context: string): int =
  ## Read how many times loop body runs from its bound test and counter's start; one
  ## where bound is not literal.
  let at = inner.find(BOUND_OPEN)
  if at < 0: return 1
  let start = at + BOUND_OPEN.len
  var i = start
  while i < inner.len and inner[i] in IdentChars: inc i
  let counter = inner[start ..< i]
  if counter.len == 0: return 1
  let is_inclusive = inner.continuesWith(" <= ", i)
  if not is_inclusive and not inner.continuesWith(" < ", i): return 1
  i += (if is_inclusive: " <= ".len else: " < ".len)
  if not inner.continuesWith(BOUND_TYPE, i): return 1
  i += BOUND_TYPE.len
  var stop = i
  while stop < inner.len and inner[stop] in Digits: inc stop
  if stop == i: return 1
  let bound = parseInt(inner[i ..< stop]) + (if is_inclusive: 1 else: 0)
  max(1, bound - startOf(context, counter))


func plain(body: string): Counts =
  ## Count spent terms of text holding no loop, i.e. once each.
  Counts(
    multiplies: body.count(") * ("),
    adds: body.count(") + ("),
    subs: body.count(") - ("),
    divides: body.count(") / ("),
    zero_fills: body.count("nimZeroMem("),
    copies: body.count("(*Result) = ") + body.count("nimCopyMem(") + body.count("memcpy("),
    checks: body.count("NIM_UNLIKELY((*nimErr_))"),
    calls: body.plainSites.len,
    allocations: body.count("alloc(") + body.count("newSeq") + body.count("rawNewString"),
  )


func `+`*(a, b: Counts): Counts =
  ## Sum counts field by field.
  Counts(
    multiplies: a.multiplies + b.multiplies,
    adds: a.adds + b.adds,
    subs: a.subs + b.subs,
    divides: a.divides + b.divides,
    zero_fills: a.zero_fills + b.zero_fills,
    intermediates: a.intermediates + b.intermediates,
    copies: a.copies + b.copies,
    checks: a.checks + b.checks,
    calls: a.calls + b.calls,
    allocations: a.allocations + b.allocations,
    lines: a.lines + b.lines,
  )


func `*`(c: Counts; trips: int): Counts =
  ## Scale spent terms by trips; declarations and lines are static and stay.
  Counts(
    multiplies: c.multiplies * trips,
    adds: c.adds * trips,
    subs: c.subs * trips,
    divides: c.divides * trips,
    zero_fills: c.zero_fills * trips,
    intermediates: c.intermediates,
    copies: c.copies * trips,
    checks: c.checks * trips,
    calls: c.calls * trips,
    allocations: c.allocations * trips,
    lines: c.lines,
  )


func weighted(body, context: string): Counts =
  ## Count spent terms with every loop's body weighted by its trips, nested loops
  ## multiplying; text outside loops counts once.
  var pos = 0
  var outside = ""
  while true:
    let at = body.find(LOOP_OPEN, pos)
    if at < 0:
      outside.add body[pos ..< body.len]
      break
    outside.add body[pos ..< at]
    var i = at + LOOP_OPEN.len
    var depth = 1
    while i < body.len and depth > 0:
      if body[i] == '{': inc depth
      elif body[i] == '}': dec depth
      inc i
    let inner = body[at + LOOP_OPEN.len ..< max(at + LOOP_OPEN.len, i - 1)]
    let before = context & body[0 ..< at]
    result = result + weighted(inner, before) * tripsOf(inner, before)
    pos = i
  result = result + plain(outside)


func weightedSites(body, context: string): seq[string] =
  ## Read call sites with every loop's body repeated by its trips, so callees fold once
  ## per trip; sites outside loops once.
  var pos = 0
  var outside = ""
  while true:
    let at = body.find(LOOP_OPEN, pos)
    if at < 0:
      outside.add body[pos ..< body.len]
      break
    outside.add body[pos ..< at]
    var i = at + LOOP_OPEN.len
    var depth = 1
    while i < body.len and depth > 0:
      if body[i] == '{': inc depth
      elif body[i] == '}': dec depth
      inc i
    let inner = body[at + LOOP_OPEN.len ..< max(at + LOOP_OPEN.len, i - 1)]
    let before = context & body[0 ..< at]
    let sites = weightedSites(inner, before)
    for _ in 1 .. tripsOf(inner, before): result.add sites
    pos = i
  result.add plainSites(outside)


func callSites*(body: string): seq[string] =
  ## Read mangled name at every call site of Nim function in body, once per loop trip,
  ## accessor reads excluded.
  weightedSites(body, "")


func count*(body: string): Counts =
  ## Count what one function body spends, by text: terms once per loop trip where loop's
  ## bound is literal, declarations and lines once.
  result = weighted(body, "")
  result.intermediates = body.countIntermediates
  result.lines = body.count('\n')



#[ Totals ]#

func key*(f: CFunction): string =
  ## Key function by symbol and parameter stems, e.g. `∧(Multivector,Multivector)`.
  f.symbol & "(" & f.params.join(",") & ")"


func totalOf(
  name: string; own: Table[string, Counts]; sites: Table[string, seq[string]]; depth: int
): Counts =
  ## Count one function with its callees folded in, per call site, recursion bounded.
  ##   Callee absent from reading (runtime, accessors) adds nothing.
  if name notin own or depth > 32: return Counts()
  result = own[name]
  for callee in sites[name]:
    if callee != name: result = result + totalOf(callee, own, sites, depth + 1)


func folded(
  functions: seq[CFunction]
): (Table[string, Counts], Table[string, seq[string]]) =
  ## Read own counts and call sites of each function once, keyed by mangled name.
  for f in functions:
    if f.name in result[0]: continue
    result[0][f.name] = count(f.body)
    result[1][f.name] = callSites(f.body)


func totals*(functions: seq[CFunction]): Table[string, Counts] =
  ## Count each function with its callees folded in, keyed by mangled name.
  let (own, sites) = folded(functions)
  for name in own.keys:
    result[name] = totalOf(name, own, sites, 0)


func totals*(functions: seq[CFunction]; roots: openArray[string]): Table[string, Counts] =
  ## Count named functions only, with their callees folded in; same fold as whole-cache one.
  ##   Folding one root walks its whole call graph, so cost of folding every function of
  ##   cache grows past what suite can spend (Article IX.8). Reader wanting few functions
  ##   asks for those, and gets same counts whole-cache fold would give.
  let (own, sites) = folded(functions)
  for name in roots:
    if name in own: result[name] = totalOf(name, own, sites, 0)



#[ Cache ]#

proc inspectCache*(dir: string): seq[CFunction] =
  ## Read every function of every C file in nimcache directory, first definition kept.
  ##   Inline functions are emitted once per module using them; duplicates share body.
  ##   Files are read in path order, so numbering of colliding keys is same on every
  ##   file system.
  var paths: seq[string]
  for path in walkDirRec(dir):
    if path.endsWith(".c"): paths.add path
  paths.sort
  var seen: Table[string, bool]
  for path in paths:
    for f in functionsIn(readFile(path)):
      if f.name in seen: continue
      seen[f.name] = true
      result.add f
