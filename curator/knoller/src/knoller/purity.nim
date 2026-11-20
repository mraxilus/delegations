## Enforce STYLE.md §1 on pure routines: routine with no effect beyond its parameters is `func`,
##   and `proc` stays for effect or randomness; compiler proves each, and fixer writes `func`.
##   Syntax picks candidates (`candidatesPure`), since it cannot prove routine pure: `proc` with
##     body, of no foreign pragma, taking no routine, outside code macro emits (`quote`,
##     `genAst`) and template substitutes, whose body
##   - names no effect of `EFFECTS`: output, input, files, clock, random numbers, environment,
##     process, address, and lock, wait and signal, which another thread sees (ruling of rule 11,
##     #443), though compiler checks routine taking lock in its `var` parameter as `func`;
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
##     keeps every `proc`, with reason. All candidates are asked at once; error inside routine
##     refuses it, and error outside every candidate asks each alone.
##   Included file checks inside text of file including it, which caller passes around it
##     (`prefix`, `suffix`), since included file compiles inside its includer alone.
##   Fixer writes `func` for `proc`, same width, so no line moves or widens; site holding no
##     `proc`, fenced line (X.1), and span edit of other fixer writes keep it for hand.
##
##   Cost: effect is read from names, so name of `EFFECTS` used otherwise, as field `write`,
##     keeps routine `proc`; fewer reports, never false one.
##   Cost: generic body checks where module instantiates it alone, so instantiation in other
##     module that compiler would refuse is unread.
##   Cost: one `nim check` of file for each configuration and round, about 0.6 s for module of
##     PGA library (measured 2026-11-20, 2.4.0).

{.experimental: "strictFuncs".}

import std/[algorithm, os, osproc, sequtils, sets, strutils, tables, tempfiles]
import ./[declared, edits, reports, tokens, views]


type
  Pures* = object  ## Define what compiler tells pure routine rule of one file.
    reason*: string  ## Why compiler proved nothing for file; empty where it proved.
    sites*: seq[(int, int)]
      ## One-based line and zero-based byte column of `proc` of each routine compiler checks as
      ##   `func`.

  Routine = object  ## Define `proc` declaration: site, name, and tokens of its body.
    site: (int, int)  ## One-based line and zero-based byte column of `proc`.
    name: string
    first: int  ## Index of `proc` token.
    body: seq[int]  ## Index of each token of body, comment left out.
    lines: Slice[int]  ## Zero-based lines from `proc` to end of body.
    is_candidate: bool  ## Shape admits it: body, no foreign pragma, no routine taken, own code.

  Error = object  ## Define error compiler reports in text it checks.
    line: int  ## One-based line in text.
    message: string


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
  MARKS_EMITTED = ["quote", "genAst"]  ## Calls whose block holds code macro emits.
  KEYWORD_PROC = "proc"  ## Keyword of routine rule reads.
  KEYWORD_FUNC = "func"  ## Keyword fixer writes for it.
  FILE_STDIN = "stdinfile.nim"  ## File name compiler gives source it reads from stdin.
  CODES_MISSING = [126, 127]  ## Exit codes of shell where compiler did not start.


func ids(names: openArray[string]): HashSet[string] =
  ## Read names as Nim compares them (`identity`).
  for name in names: result.incl name.identity


func indents(source: string): seq[int] =
  ## Read indent of each line of code, `-1` for blank or comment line.
  for line in source.codeOnly.splitLines:
    result.add(if line.strip.len == 0: -1 else: line.indentWidth)


func parents(indents: openArray[int], line: int): seq[int] =
  ## Read each line opening block around zero-based line, nearest first.
  var depth = indents[line]
  if depth < 0: return
  for k in countdown(line - 1, 0):
    if indents[k] >= 0 and indents[k] < depth:
      result.add k
      depth = indents[k]


func lastBody(indents: openArray[int], line, indent: int): int =
  ## Read last zero-based line of block whose head ends at line and stands at indent: each later
  ##   line indented deeper.
  result = line
  for k in line + 1 ..< indents.len:
    if indents[k] < 0: continue
    if indents[k] <= indent: break
    result = k


func routines(source: string): seq[Routine] =
  ## Read each `proc` declaration of source: site, name, body tokens and whether shape admits it.
  let
    tokens = source.tokens
    partners = tokens.partners
    starts = source.lineStarts
    code = source.codeOnly.splitLines
    depths = source.indents
  for k, t in tokens:
    if t.kind != KindToken.Word or t.spelling(source) != KEYWORD_PROC: continue
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
      words_head: seq[string]
    while j < tokens.len and tokens[j].line == tokens[j - 1].line:
      let s = tokens[j].spelling(source)
      if tokens[j].kind == KindToken.Comment: break
      if s == "=" and tokens[j].kind == KindToken.Operator:
        bodied = j
        break
      if tokens[j].kind == KindToken.Open and partners[j] > j:
        for m in j .. partners[j]:
          if tokens[m].kind == KindToken.Word: words_head.add tokens[m].spelling(source)
        j = partners[j] + 1
        continue
      if tokens[j].kind == KindToken.Word: words_head.add s
      inc j

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
        words = routine.body.filterIt(tokens[it].kind == KindToken.Word)
          .mapIt(tokens[it].spelling(source).identity)
        called = callees(source, tokens, routine.body).mapIt(it.identity)
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


func toErrors(output: string): seq[Error] =
  ## Read each error compiler reports in text it read from stdin: `stdinfile.nim(L, C) Error: …`.
  for line in output.splitLines:
    if not line.startsWith(FILE_STDIN & "("): continue
    let
      close = line.find(')')
      marker = line.find(" Error: ")
    if close < 0 or marker < close: continue
    let place = line[FILE_STDIN.len + 1 ..< close].split(',')
    try: result.add Error(line: place[0].strip.parseInt, message: line[marker + 8 .. ^1])
    except ValueError: discard


proc checked(
  text, directory, nim: string; defines: openArray[string]
): tuple[errors: seq[Error], is_clean: bool, reason: string] =
  ## Check text by compiler `nim` under defines, read from stdin in directory, cache in private
  ##   temporary directory removed after; reason says why compiler did not run.
  let cache = createTempDir("knoller_purity_", "")
  defer: removeDir(cache)
  let command = (@[nim, "check", "--hints:off", "--warnings:off", "--nimcache:" & cache] &
    @defines & @["-"]).mapIt(it.quoteShell).join(" ")
  let (output, code) =
    try:
      execCmdEx(
        command, options = {poStdErrToStdOut, poEvalCommand}, workingDir = directory, input = text
      )
    except OSError as e: (e.msg, CODES_MISSING[1])
  let last = if output.strip.len == 0: "no output" else: output.strip.splitLines[^1]
  if code in CODES_MISSING:
    result.reason = "compiler did not run: " & last
    return
  result.errors = output.toErrors
  result.is_clean = code == 0 and result.errors.len == 0
  if not result.is_clean and result.errors.len == 0:
    result.errors.add Error(line: 0, message: last)


func written(source: string; sites: openArray[(int, int)]): string =
  ## Write `func` for `proc` at each site, same width, so every line and column holds.
  let starts = source.lineStarts
  result = source
  for (line, column) in sites:
    let at = starts[line - 1] + column
    result[at ..< at + KEYWORD_FUNC.len] = KEYWORD_FUNC


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
  if sites.len == 0: return
  let
    offset = prefix.count('\n')
    spans = source.routines.filterIt(it.site in sites).mapIt((it.site, it.lines))
  var
    refused: seq[(int, int)]
    proving = 0
    reasons: seq[string]
  for defines in (if configurations.len == 0: @[newSeq[string]()] else: @configurations):
    let before = checked(prefix & source & suffix, directory, nim, defines)
    if before.reason.len > 0: reasons.add before.reason
    if not before.is_clean:
      if before.errors.len > 0: reasons.add before.errors[0].message
      continue
    inc proving

    # Ask open candidates at once; error inside routine refuses it, else ask each alone.
    var open = @sites.filterIt(it notin refused)
    while open.len > 0:
      let after = checked(prefix & source.written(open) & suffix, directory, nim, defines)
      if after.is_clean: break
      var hit: seq[(int, int)]
      for e in after.errors:
        for (site, lines) in spans:
          if site in open and e.line - offset - 1 in lines and site notin hit: hit.add site
      if hit.len == 0:
        for site in open:
          if not checked(prefix & source.written([site]) & suffix, directory, nim, defines)
              .is_clean:
            refused.add site
        break
      refused.add hit
      open = open.filterIt(it notin hit)
  if proving == 0:
    result.reason = "source checks clean in no configuration: " &
      (if reasons.len > 0: reasons[0] else: "no configuration")
    return
  result.sites = @sites.filterIt(it notin refused).sorted


func found(source: string; pures: Pures): seq[Routine] =
  ## Read each routine pures name whose site still holds `proc`.
  if pures.reason.len > 0: return
  source.routines.filterIt(it.site in pures.sites)


func checkPure*(path, source: string; pures: Pures): seq[Report] =
  ## Report each `proc` compiler checks as `func` (STYLE.md §1).
  for routine in source.found(pures):
    result.add initReport(
      path,
      routine.site[0],
      Rule.PureFunc,
      "Routine with no effect beyond its parameters is `func`; got `" & KEYWORD_PROC & " " &
        routine.name & "`.",
    )


func editsPure*(
  path, source: string; pures: Pures; fenced: openArray[int]; held: openArray[Edit] = []
): (seq[Edit], seq[Report]) =
  ## Read edits writing `func` for each `proc` check reports, and one report per routine.
  ##   Fenced line (X.1) keeps `proc` for hand, and so does span edit of other fixer writes.
  let starts = source.lineStarts
  for routine in source.found(pures):
    let
      at = starts[routine.site[0] - 1] + routine.site[1]
      edit = Edit(first: at, after: at + KEYWORD_PROC.len, text: KEYWORD_FUNC)
    if routine.site[0] - 1 in fenced or held.anyIt(it.isTouching(edit)): continue
    result[0].add edit
    result[1].add initReport(path, routine.site[0], Rule.PureFunc)
