## Enforce STYLE.md §1 on pure routines: routine with no effect beyond its parameters is `func`,
##   and `proc` stays for effect or randomness; compiler proves each, and fixer writes `func`.
##   Syntax picks candidates (`candidatesPure`), since it cannot prove routine pure: `proc` with
##     body, of no foreign pragma, taking no routine, outside code macro emits (`quote`,
##     `genAst`), code template substitutes, and code `compiles` tests, whose verdict clean
##     check of module never proves, whose body, with default of each parameter, which runs at
##     each call leaving its argument out (ruling `D6 a` of #980),
##   - names no effect of `EFFECTS`: output, input, files, clock, random numbers, environment,
##     process, address, and lock, wait and signal, which another thread sees (STYLE.md §1), so
##     answer of routine taking one depends on order of threads, and is no deterministic
##     transformation of its arguments (ruling of rule 11, #443), though compiler checks routine
##     taking lock in its `var` parameter as `func`;
##   - reads no global `var` of project;
##   - calls no routine project declares nowhere and `TRANSFORMS` holds not, so call syntax cannot
##     read never counts as pure; call is name glued before `(` or `[…](`, name glued after `.`,
##     or name opening statement before operand (command form);
##   - calls no `proc` or `method` of project that stays, read to fixed point, so two candidates
##     calling each other both stay candidates.
##   Compiler proves each candidate (`provenPure`): `nim check` reads source with candidate
##     written `func`, under `strictFuncs` module carries, from stdin in directory of file, so
##     imports and configuration resolve as for file itself, and nothing is written there.
##     Candidate stays where any configuration caller names refuses it; configuration where
##     source as given does not check clean proves nothing, and file no configuration proves
##     keeps every `proc`, with reason. Source C does not check is asked on JavaScript backend,
##     as semantic pass asks it (`symbols.nim`). All candidates are asked at once; error inside
##     routine refuses it, and error outside every candidate asks each alone.
##   Compiler also keeps `proc` of candidate taking parameter whose type points, `ref`, `ptr` or
##     `pointer`, distinct one too, since other holder or thread can change it during call
##     (ruling `D1 a` of #980); `var` alone keeps none, as §1 lets `func` write it. Check of each
##     type stands after source, so no line moves, and its error refuses its routine (`probed`).
##     Type naming generic parameter of its routine takes no check, since no scope at end of
##     module names it, and `nim check` of 2.4.0 crashes with no line on some such checks.
##   Check of source as given asks same of each `func` whose types name more than builtin types
##     and containers of value (`isPointingAsked`); its error leaves that check clean. Check reports
##     each `func` that points as `proc` (ruling `D5 a` of #980), and fixer writes `proc`, same
##     width, unless forward declaration of routine stands, whose kind must match.
##   Included file checks inside text of file including it, which caller passes around it
##     (`prefix`, `suffix`), since included file compiles inside its includer alone.
##   Fixer writes `func` for `proc`, same width, so no line moves or widens; site holding no
##     `proc`, fenced line (X.1), and span edit of other fixer writes keep it for hand.
##
##   Cost: effect is read from names, so name of `EFFECTS` used otherwise, as field `write`,
##     keeps routine `proc`; fewer reports, never false one.
##   Cost: compiler accepts write library routine makes through `ref` in field or container of
##     parameter, as `[]=` of `std/json` makes, and adds false report.
##   Cost: `ref` in field or container of parameter, type naming generic parameter, type no scope
##     at end of module names, and `cstring`, which reads as string, keep no `proc`, though other
##     holder can change what each reaches. Each can add false report.
##   Cost: file holding `func` asked and no candidate takes one check of source as given, where
##     none ran before; its time is unmeasured. Where that check is clean in no configuration, its
##     `func` stays unread and warns nothing, since no `proc` stays there.
##   Cost: generic body checks where module instantiates it alone, so instantiation in other
##     module that compiler would refuse is unread, and can add false report.
##   Cost: one `nim check` of file for each configuration and round, 0.61 to 0.76 s for module of
##     PGA library on 4 cores at 2.10 GHz, where none runs without rule (command of `checked`, with
##     its flags, on stdin and fresh cache, six runs, 2026-11-20, 2.4.0).

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, sets, strutils, tables]
import ./[declared, edits, reports, symbols, tokens, views]


type
  Pures* = object  ## Define what compiler tells pure routine rule of one file.
    reason*: string  ## Why compiler proved nothing for file; empty where it proved.
    sites*: seq[(int, int)]
      ## One-based line and zero-based byte column of `proc` of each routine compiler checks as
      ##   `func`.
    pointing*: seq[(int, int)]
      ## One-based line and zero-based byte column of `func` of each routine whose parameter type
      ##   points, so it is `proc` (ruling `D5 a` of #980).

  Routine = object  ## Define `proc` declaration: site, name, and tokens of its body.
    site: (int, int)  ## One-based line and zero-based byte column of `proc`.
    name: string
    first: int  ## Index of `proc` token.
    body: seq[int]  ## Index of each token of body, comment left out.
    defaults: seq[int]  ## Index of each token of default of each parameter, comment left out.
    lines: Slice[int]  ## Zero-based lines from `proc` to end of body.
    types: seq[string]
      ## Type of each parameter group as written; group its default alone types reads as `typeof`
      ##   of default. Compiler reads `var` type as type it holds, so `var` of `ref` points too.
      ##   Type naming generic parameter of routine is left out, since no scope at end of module
      ##   names it.
    is_candidate: bool  ## Shape admits it: body, no foreign pragma, no routine taken, own code.


const
  EFFECTS = [
    "echo", "debugEcho", "stdout", "stderr", "stdin", "write", "writeLine", "writeFile",
    "readLine", "readLines", "readAll", "readFile", "readChar", "open", "close", "flushFile",
    "File", "fileExists", "dirExists", "removeFile", "removeDir", "createDir", "copyFile",
    "moveFile",
    "walkDir", "walkFiles", "walkDirRec", "now", "epochTime", "getTime", "cpuTime",
    "getMonoTime", "sleep", "sleepAsync", "rand", "random", "gauss", "sample", "shuffle",
    "randomize", "initRand", "Rand", "urandom", "getEnv", "putEnv", "existsEnv", "delEnv",
    "envPairs", "paramStr", "paramCount", "commandLineParams", "getCurrentDir", "setCurrentDir",
    "getAppDir", "getHomeDir", "getTempDir", "execProcess", "startProcess", "execCmd",
    "execCmdEx", "execShellCmd", "quit", "addr", "unsafeAddr", "asm", "emit", "Lock", "Cond",
    "initLock", "deinitLock", "acquire", "release", "tryAcquire", "withLock", "initCond",
    "deinitCond", "wait", "signal", "broadcast", "Atomic", "atomicInc", "atomicDec",
    "atomicLoad", "atomicStore", "fetchAdd", "fetchSub", "compareExchange", "Channel", "send",
    "recv", "tryRecv", "trySend", "spawn", "createThread", "joinThread", "joinThreads",
  ]
    ## Names of effect beyond parameters: output, input, files, clock, random numbers,
    ##   environment, process, address, and lock, wait and signal (STYLE.md §1).
  TRANSFORMS = [
    "abs", "add", "assert", "card", "chr", "clamp", "cmp", "compiles", "contains", "dec",
    "declared", "default", "defined", "del", "delete", "doAssert", "excl", "find", "high", "inc",
    "incl", "insert", "isNil", "items", "len", "low", "max", "min", "mitems", "move", "mpairs",
    "newException", "newSeq", "newSeqOfCap", "newString", "newStringOfCap", "ord", "pairs",
    "pred", "setLen", "sizeof", "substr", "succ", "swap", "toOpenArray", "typeof", "arccos",
    "arcsin", "arctan", "arctan2", "cbrt", "ceil", "copySign", "cos", "cosh", "degToRad", "exp",
    "floor", "floorDiv", "floorMod", "hypot", "isNaN", "ln", "log", "log10", "log2", "pow",
    "radToDeg", "round", "sgn", "sin", "sinh", "sqrt", "sum", "tan", "tanh", "trunc", "align",
    "alignLeft", "capitalizeAscii", "count", "endsWith", "format", "formatFloat", "indent",
    "intToStr", "isDigit", "isEmptyOrWhitespace", "join", "parseFloat", "parseInt", "repeat",
    "replace", "rfind", "spaces", "split", "splitLines", "splitWhitespace", "startsWith",
    "strip", "toHex", "toLowerAscii", "toUpperAscii", "all", "allIt", "any", "anyIt", "concat",
    "countIt", "deduplicate", "filter", "filterIt", "foldl", "foldr", "map", "mapIt",
    "maxIndex", "minIndex", "newSeqWith", "toSeq", "unzip", "zip", "binarySearch", "fill",
    "reverse", "reversed", "sort", "sorted", "sortedByIt", "getOrDefault", "hasKey",
    "initHashSet", "initTable", "keys", "mgetOrPut", "toHashSet", "toTable", "values", "get",
    "isNone", "isSome", "none", "some", "collect", "fmt", "hash", "countSetBits", "runeLen",
    "toRunes",
  ]
    ## Routines of standard library that transform their arguments alone, which candidate may
    ##   call though project declares none of them.
  TYPES_BUILTIN = [
    "bool", "byte", "char", "cint", "cstring", "float", "float32", "float64", "int", "int16",
    "int32", "int64", "int8", "Natural", "Positive", "string", "uint", "uint16", "uint32",
    "uint64", "uint8",
  ]
    ## Types `system` declares, whose call is conversion rather than routine.
  MARKS_EMITTED = ["compiles", "genAst", "quote"]
    ## Calls whose block holds code macro emits, or code whose compile is itself under test.
  KEYWORD_PROC = "proc"  ## Keyword of routine rule reads.
  KEYWORD_FUNC = "func"  ## Keyword fixer writes for it.
  NAME_POINTING = "knollerPointing"  ## Template of check, under name no source of project takes.
  CHECK_POINTING = "\nfrom std/typetraits import nil\n\ntemplate " & NAME_POINTING &
    "(t: typedesc): bool =\n  typetraits.distinctBase(t) is ref or " &
    "typetraits.distinctBase(t) is ptr or\n    typetraits.distinctBase(t) is pointer\n"
    ## Template written after source: whether type points, distinct one included.
  MESSAGE_POINTING = "parameter of `ref` or `ptr` type keeps routine `proc`"
    ## Error of check whose type points.
  WORDS_PLAIN = [
    "array", "CountTable", "HashSet", "HSlice", "lent", "openArray", "Option", "OrderedSet",
    "OrderedTable", "range", "seq", "set", "sink", "Slice", "static", "Table", "tuple", "type",
    "typedesc", "typeof", "var", "varargs",
  ]
    ## Words of type that point at nothing: container of value and modifier, whose argument
    ##   decides alone; container of `ref` keeps no `proc` (ruling `D1 a` of #980).
  SEPARATORS_TYPE = {' ', '[', ']', ',', '(', ')', ':', '.', '*', '{', '}', '=', '\n', '"', '\''}
    ## Characters between words of type as written.


func ids(names: openArray[string]): HashSet[string] =
  ## Read names as Nim compares them (`identity`).
  for name in names: result.incl name.identity


func lastBody(indents: openArray[int], line, indent: int): int =
  ## Read last zero-based line of block whose head ends at line and stands at indent: each later
  ##   line indented deeper.
  result = line
  for k in line + 1 ..< indents.len:
    if indents[k] < 0: continue
    if indents[k] <= indent: break
    result = k


func parameterTypes(
  source: string; tokens: openArray[Token]; partners: openArray[int]; open: int
): seq[string] =
  ## Read type of each parameter group of list opening at token `open`, as written; group its
  ##   default alone types reads as `typeof` of default.
  var
    first, last = -1  # Tokens of type or default read now; first is -1 while names read.
    is_default, is_done = false  # Default read; group read already, so rest of it skipped.
  template read() =
    if first >= 0 and last >= first and not is_done:
      let text = source[tokens[first].first ..< tokens[last].after]
      result.add (if is_default: "typeof(" & text & ")" else: text)
    is_done = true

  var k = open + 1
  while k < partners[open]:
    let
      t = tokens[k]
      s = t.spelling(source)
    if t.kind in {KindToken.Comma, KindToken.Semicolon}:
      if first >= 0 or is_done:  # Separator after type or default ends group, between names not.
        read()
        (first, last, is_default, is_done) = (-1, -1, false, false)
    elif t.kind == KindToken.Operator and s == ":" and first < 0 and not is_done: first = k + 1
    elif t.kind == KindToken.Operator and s == "=" and not is_done:
      if first >= 0: read()  # Type read, so its default is skipped.
      else: (first, is_default) = (k + 1, true)
    elif t.kind != KindToken.Comment and first >= 0 and not is_done:
      last = if t.kind == KindToken.Open and partners[k] > k: partners[k] else: k
    if t.kind == KindToken.Open and partners[k] > k: k = partners[k]
    inc k
  read()
  result = result.deduplicate


func genericNames(
  source: string; tokens: openArray[Token]; partners: openArray[int]; open: int
): seq[string] =
  ## Read name of each generic parameter of list opening at token `open`: word opening list or
  ##   following its separator, nested brackets skipped.
  var
    k = open + 1
    is_name = true  # Next word names parameter, as after `[`, `,` or `;`.
  while k < partners[open]:
    let t = tokens[k]
    if t.kind in {KindToken.Comma, KindToken.Semicolon}: is_name = true
    elif t.kind == KindToken.Word and is_name:
      result.add t.spelling(source)
      is_name = false
    elif t.kind != KindToken.Comment: is_name = false
    if t.kind == KindToken.Open and partners[k] > k: k = partners[k]
    inc k


func parameterDefaults(
  source: string; tokens: openArray[Token]; partners: openArray[int]; open: int
): seq[int] =
  ## Read index of each token of default of each parameter of list opening at token `open`,
  ##   comment left out; bracket of name or type is skipped whole.
  var
    k = open + 1
    is_default = false
  while k < partners[open]:
    let t = tokens[k]
    if t.kind in {KindToken.Comma, KindToken.Semicolon}: is_default = false
    elif t.kind == KindToken.Operator and t.spelling(source) == "=" and not is_default:
      is_default = true
    elif is_default and t.kind != KindToken.Comment:
      let last = if t.kind == KindToken.Open and partners[k] > k: partners[k] else: k
      for m in k .. last:
        if tokens[m].kind != KindToken.Comment: result.add m
      k = last
    elif t.kind == KindToken.Open and partners[k] > k: k = partners[k]
    inc k


func routines(source: string; keyword = KEYWORD_PROC): seq[Routine] =
  ## Read each declaration of source that `keyword` opens: site, name, body tokens and whether
  ##   shape admits it.
  let
    tokens = source.tokens
    partners = tokens.partners
    starts = source.lineStarts
    code = source.codeOnly.splitLines
    depths = source.indents
  for k, t in tokens:
    if t.kind != KindToken.Word or t.spelling(source) != keyword: continue
    if k + 1 >= tokens.len or tokens[k + 1].kind notin {KindToken.Word, KindToken.Quoted}:
      continue
    var routine = Routine(
      site: (t.line + 1, t.first - starts[t.line]),
      name: tokens[k + 1].spelling(source),
      first: k,
    )

    # Walk head on its line, each bracket whole: name, export mark, placeholders, parameters,
    #   return type, pragmas, then `=`.
    var
      j = k + 2
      bodied = -1
      parameters = -1  # Token opening list of parameters.
      words_head, generics: seq[string]
    while j < tokens.len and tokens[j].line == tokens[j - 1].line:
      let s = tokens[j].spelling(source)
      if tokens[j].kind == KindToken.Comment: break
      if s == "=" and tokens[j].kind == KindToken.Operator:
        bodied = j
        break
      if tokens[j].kind == KindToken.Open and partners[j] > j:
        if s == "(" and parameters < 0: parameters = j
        if s == "[" and parameters < 0 and generics.len == 0:
          generics = genericNames(source, tokens, partners, j)
        for m in j .. partners[j]:
          if tokens[m].kind == KindToken.Word: words_head.add tokens[m].spelling(source)
        j = partners[j] + 1
        continue
      if tokens[j].kind == KindToken.Word: words_head.add s
      inc j

    if parameters >= 0:
      let named = generics.ids
      routine.types = parameterTypes(source, tokens, partners, parameters).filterIt(
        not it.split(SEPARATORS_TYPE).anyIt(it.len > 0 and it.identity in named)
      )
      routine.defaults = parameterDefaults(source, tokens, partners, parameters)

    # Body: rest of `=` line, else lines indented deeper than head.
    let head_line = t.line
    if bodied >= 0:
      let
        line_equals = tokens[bodied].line
        last = depths.lastBody(line_equals, depths[head_line])
      routine.lines = head_line .. last
      for m in bodied + 1 ..< tokens.len:
        if tokens[m].line > last: break
        if tokens[m].kind != KindToken.Comment: routine.body.add m
    else: routine.lines = head_line .. head_line

    # Shape: body, own code, no foreign or emitted context, no routine taken.
    let
      around = depths.parents(head_line).mapIt(code[it].wordsCode)
      is_emitted = around.anyIt(
        (it.len > 0 and it[0] == "template") or it.anyIt(it in MARKS_EMITTED)
      )
      is_foreign = words_head.anyIt(it in MARKS_FOREIGN)
      is_routine_taken = words_head.anyIt(it in ["proc", "iterator", "func"])
    routine.is_candidate = bodied >= 0 and routine.body.len > 0 and not is_emitted and
      not is_foreign and not is_routine_taken
    result.add routine


func callees(source: string; tokens: openArray[Token]; body: openArray[int]): seq[string] =
  ## Read name of each call of body: name glued before `(` or `[…](`, name glued after `.`, or
  ##   name opening statement before operand, as command form calls it.
  let partners = tokens.partners
  for k in body:
    let t = tokens[k]
    if t.kind != KindToken.Word or t.isKeyword(source): continue
    let
      next = k + 1
      is_glued_next = next < tokens.len and tokens[next].first == t.after
      is_call = is_glued_next and tokens[next].spelling(source) == "(" or
        is_glued_next and tokens[next].spelling(source) == "[" and partners[next] > next and
          partners[next] + 1 < tokens.len and
          tokens[partners[next] + 1].spelling(source) == "(" and
          tokens[partners[next] + 1].first == tokens[partners[next]].after
      is_dotted = k > 0 and tokens[k - 1].spelling(source) == "." and
        tokens[k - 1].after == t.first
      is_opening = k == 0 or tokens[k - 1].line < t.line
      is_command = is_opening and next < tokens.len and tokens[next].line == t.line and
        not is_glued_next and tokens[next].kind in {
          KindToken.Word, KindToken.Quoted, KindToken.Number, KindToken.Text, KindToken.Character,
        } and not tokens[next].isKeyword(source)
    if is_call or is_dotted or is_command: result.add t.spelling(source)


func candidatesPure*(files: openArray[(string, string)]): Table[string, seq[(int, int)]] =
  ## Read site of `proc` of each routine of files whose body shows no effect, by path: shape
  ##   admits it, its body names no effect, reads no global `var`, calls no routine project
  ##   declares nowhere and `TRANSFORMS` holds not, and calls no `proc` or `method` of project that
  ##   stays, read to fixed point. Files are path and text of every Nim file of project.
  let
    effects = EFFECTS.ids
    transforms = TRANSFORMS.ids
    builtins = TYPES_BUILTIN.ids
  var
    declared, globals, routines_staying: HashSet[string]
    found: seq[(string, Routine, seq[string])]  # Path, routine, names its body calls.
  for (path, source) in files:
    for d in source.declarations:
      declared.incl d.name.identity
      if d.kind == KindName.Binding and d.reach == Reach.Global and d.is_mutable:
        globals.incl d.name.identity
      if d.kind == KindName.Routine and d.keyword == "method":
        routines_staying.incl d.name.identity
  for (path, source) in files:
    let tokens = source.tokens
    for routine in source.routines:
      let
        read = routine.body & routine.defaults  # Default runs at each call leaving it out.
        words = read.filterIt(tokens[it].kind == KindToken.Word)
          .mapIt(tokens[it].spelling(source).identity)
        called = callees(source, tokens, read).mapIt(it.identity)
        is_effect = words.anyIt(it in effects or it in globals)
        is_unknown = called.anyIt(
          it notin declared and it notin transforms and it notin builtins and not it.isKeyword
        )
      if routine.is_candidate and not is_effect and not is_unknown:
        found.add (path, routine, called)
      else: routines_staying.incl routine.name.identity

  # Drop candidate calling `proc` that stays, until none does.
  var is_changed = true
  while is_changed:
    is_changed = false
    for k in countdown(found.high, 0):
      if found[k][2].anyIt(it in routines_staying):
        routines_staying.incl found[k][1].name.identity
        found.delete k
        is_changed = true
  for (path, routine, _) in found: result.mgetOrPut(path, @[]).add routine.site


func written(source: string; sites: openArray[(int, int)]): string =
  ## Write `func` for `proc` at each site, same width, so every line and column holds.
  let starts = source.lineStarts
  result = source
  for (line, column) in sites:
    let at = starts[line - 1] + column
    result[at ..< at + KEYWORD_FUNC.len] = KEYWORD_FUNC


func pointed(
  text: string; found: openArray[Routine]; sites: openArray[(int, int)]
): (string, Table[int, (int, int)]) =
  ## Write text, then check of each type of parameter of each routine at sites, whose error says
  ##   type points; table maps zero-based line of each error to site. Type no scope at end of
  ##   module names reads unread (`compiles`). Text with no type to check stays as it is.
  result[0] = text
  if not found.anyIt(it.site in sites and it.types.len > 0): return
  if not result[0].endsWith('\n'): result[0].add '\n'
  result[0].add CHECK_POINTING
  for routine in found:
    if routine.site notin sites: continue
    for t in routine.types:
      let call = NAME_POINTING & "(" & t & ")"
      result[0].add "when compiles(" & call & "):\n"
      result[1][result[0].count('\n')] = routine.site
      result[0].add "  when " & call & ": {.error: \"" & MESSAGE_POINTING & "\".}\n"


func probed(
  source: string; found: openArray[Routine]; sites: openArray[(int, int)]; prefix, suffix: string
): (string, Table[int, (int, int)]) =
  ## Write source with `func` at each site, inside prefix and suffix, then check of each type of
  ##   parameter of each routine at sites, whose error refuses it (`pointed`).
  pointed(prefix & source.written(sites) & suffix, found, sites)


func isAskedPointing(routine: Routine): bool =
  ## Whether shape admits routine and one of its parameter types names more than builtin type,
  ##   number and plain word, so compiler answers whether it points.
  let builtins = TYPES_BUILTIN.ids
  routine.is_candidate and routine.types.anyIt(
    it.split(SEPARATORS_TYPE).anyIt(
      it.len > 0 and it[0] notin {'0' .. '9'} and it.identity notin builtins and
        it notin WORDS_PLAIN
    )
  )


func isPointingAsked*(source: string): bool =
  ## Whether compiler answers for some `func` of source whether its parameter type points.
  source.routines(KEYWORD_FUNC).anyIt(it.isAskedPointing)


proc provenPure*(
  source: string;
  sites: openArray[(int, int)];
  directory, nim: string;
  configurations: openArray[seq[string]];
  prefix = "";
  suffix = "",
): Pures =
  ## Ask compiler `nim` to check source in directory with each candidate at `sites` as `func`,
  ##   under each configuration of defines: candidate stays where any configuration whose source
  ##   checks clean refuses it, and source checking clean in none proves nothing, with reason.
  ##   Included file reads inside `prefix` and `suffix` of its includer.
  let
    offset = prefix.count('\n')
    found = source.routines.filterIt(it.site in sites)
    spans = found.mapIt((it.site, it.lines))
    funcs = source.routines(KEYWORD_FUNC).filterIt(it.isAskedPointing)
    (given, asked) = pointed(prefix & source & suffix, funcs, funcs.mapIt(it.site))
  if sites.len == 0 and asked.len == 0: return
  var
    refused, pointing: seq[(int, int)]
    proving = 0
    reasons: seq[string]
  for configuration in (if configurations.len == 0: @[newSeq[string]()] else: @configurations):
    # Backend whose source as given checks clean: C, else JavaScript, as semantic pass asks. Error
    #   of check of `func` asked leaves it clean, and says `func` points.
    let (before, defines) =
      checkedBackend(given, directory, nim, configuration, ignored = asked.keys.toSeq)
    if before.reason.len > 0: reasons.add before.reason
    if not before.is_clean:
      let own = before.errors.filterIt(it[0] - 1 notin asked)
      if own.len > 0: reasons.add own[0][1]
      continue
    inc proving
    for (line, _) in before.errors:
      let site = asked.getOrDefault(line - 1, (0, 0))
      if site in asked.values.toSeq and site notin pointing: pointing.add site

    # Ask open candidates at once; error inside routine, or of check of its parameter, refuses
    #   it, else ask each alone.
    var open = @sites.filterIt(it notin refused)
    while open.len > 0:
      let
        (text, checks) = probed(source, found, open, prefix, suffix)
        after = checked(text, directory, nim, defines)
      if after.is_clean: break
      var hit: seq[(int, int)]
      for (line, _) in after.errors:
        let pointing = checks.getOrDefault(line - 1, (0, 0))
        if pointing in open and pointing notin hit: hit.add pointing
        for (site, lines) in spans:
          if site in open and line - offset - 1 in lines and site notin hit: hit.add site
      if hit.len == 0:
        for site in open:
          if not checked(probed(source, found, [site], prefix, suffix)[0], directory, nim, defines)
              .is_clean:
            refused.add site
        break
      refused.add hit
      open = open.filterIt(it notin hit)
  if proving == 0:
    if sites.len == 0: return  # `func` asked alone: no `proc` stays, so nothing warns
    result.reason = "source checks clean in no configuration: " &
      (if reasons.len > 0: reasons[0] else: "no configuration")
    return
  result.sites = @sites.filterIt(it notin refused).sorted
  result.pointing = pointing.sorted


func found(source: string; pures: Pures): seq[Routine] =
  ## Read each routine pures name whose site still holds `proc`.
  if pures.reason.len > 0: return
  source.routines.filterIt(it.site in pures.sites)


func foundPointing(source: string; pures: Pures): seq[Routine] =
  ## Read each routine pures name as pointing whose site still holds `func`.
  if pures.reason.len > 0: return
  source.routines(KEYWORD_FUNC).filterIt(it.site in pures.pointing)


func checkPure*(path, source: string; pures: Pures): seq[Report] =
  ## Report each `proc` compiler checks as `func`, and each `func` whose parameter type points
  ##   (STYLE.md §1), in order of lines.
  for routine in source.found(pures):
    result.add initReport(
      path,
      routine.site[0],
      Rule.PureFunc,
      "Routine with no effect beyond its parameters is `func`; got `" & KEYWORD_PROC & " " &
        routine.name & "`.",
    )
  for routine in source.foundPointing(pures):
    result.add initReport(
      path,
      routine.site[0],
      Rule.PureFunc,
      "Routine with parameter of `ref` or `ptr` type is `proc`; got `" & KEYWORD_FUNC & " " &
        routine.name & "`.",
    )
  result = result.sortedByIt(it.line)


func editsPure*(
  path, source: string; pures: Pures; fenced: openArray[int]; held: openArray[Edit] = []
): (seq[Edit], seq[Report]) =
  ## Read edits writing `func` for each `proc` check reports, and `proc` for each `func`, and one
  ##   report per routine. Fenced line (X.1) keeps its keyword for hand, and so does span edit of
  ##   other fixer writes, and `func` whose forward declaration stands, as kinds must match.
  let
    starts = source.lineStarts
    funcs = source.routines(KEYWORD_FUNC)
  for routine in source.found(pures):
    let
      at = starts[routine.site[0] - 1] + routine.site[1]
      edit = Edit(first: at, after: at + KEYWORD_PROC.len, text: KEYWORD_FUNC)
    if routine.site[0] - 1 in fenced or held.anyIt(it.isTouching(edit)): continue
    result[0].add edit
    result[1].add initReport(path, routine.site[0], Rule.PureFunc)
  for routine in source.foundPointing(pures):
    let
      at = starts[routine.site[0] - 1] + routine.site[1]
      edit = Edit(first: at, after: at + KEYWORD_FUNC.len, text: KEYWORD_PROC)
      is_forwarded = funcs.anyIt(
        it.site != routine.site and it.body.len == 0 and it.name.identity == routine.name.identity
      )
    if routine.site[0] - 1 in fenced or is_forwarded or held.anyIt(it.isTouching(edit)): continue
    result[0].add edit
    result[1].add initReport(path, routine.site[0], Rule.PureFunc)
