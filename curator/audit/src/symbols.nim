## Resolve names of Nim source to symbols through compiler's own semantic pass: `nimsuggest` of
##   toolchain serving project's pin, for fixers whose rule text cannot settle (`koch fix`).
##   Text cannot tell conversion `x.T` from field or module path (`rigid3.Point`), nor find every
##     use of name across modules; semantic pass of pin project runs on can, symbol by symbol.
##   One `nimsuggest --v3 --stdin` serves each entry: file itself, or file including it, since
##     included file compiles inside includer alone. It runs in project directory, so project's
##     `nim.cfg` and `config.nims` apply, with `-d:testing` under `tests/` as stubs compile.
##   Each file is checked first (`chkFile`). File reporting error on C backend is asked again on
##     JavaScript backend, and file failing both stays unresolved with its first error, so
##     fixers leave it and their findings stay for hand.
##   Answer of file: symbol each site resolves to (`def`), and global declarations named exactly
##     as each name asked (`globalSymbols`, read whole and filtered by Nim's own identity).
##   Site of included file asks `dus`, whose answer opens on same definition, then lists uses:
##     `def` there recompiles includer for each site (commit pin's `nimsuggest`, include query),
##     where `dus` recompiles only what is dirty. Measured 2026-10-04 on this container, 20
##     sites of shared suite of `rga_visualiser`: `def` 345 s, `dus` 50 s. Site of entry keeps
##     `def`, since `dus` there would list every use of common symbol such as `float`. Cost:
##     included file pays that list, in output and never in compile.
##   Routine returning value answers its own declared name with its implicit `result`, placed
##     at start of routine's line (both pins served, 2026-10-03); that answer reads as routine
##     declared at site, where every use of it resolves, so rename finds its declaration.
##   Entries run several at once, `PARALLEL` at most: each takes its input whole, so reading
##     their output in turn lets later ones run meanwhile.
##   Run reads commands from file and writes answers to file, through shell's redirection.
##     Pipe holds 64 KiB: run whose answers fill it stops reading commands, so writing every
##     command first, through pipes, waits forever on entry of many sites. Cost: two temporary
##     files per run, removed once read.
##
##   Rejected: compiler as library inside koch, which compiles compiler into every build of koch
##     and binds it to one pin, where ronri projects lex glyphs only their commit pin knows.
##     Rejected: `nim check --def` for each site, one compile of project per site. `nimsuggest`
##     ships with every toolchain koch serves, so it costs no build.
##   Cost: one compile per entry, about 2 s for module of curator and 5 to 9 s for front-end or
##     suite of `rga_visualiser` (measured 2026-10-02 on this container, 2.2.12 and commit pin).
##     Callers ask only files holding candidate, which their prefilter keeps few.
##   Cost: checkout `koch fetch-deps` restores, and native library, are needed to compile; file
##     lacking either stays unresolved.
##   Cost: branch of `when` that entry's defines leave untaken resolves nothing, so fixers leave
##     names there.

{.experimental: "strictFuncs".}

import std/[options, os, osproc, sequtils, strutils, tables, tempfiles]
import ../../knoller/src/knoller
import ./[layout, plan, toolchain]


type
  Symbol* = object  ## Define symbol name resolves to: kind, qualified name, definition.
    kind*: string  ## Symbol kind, as compiler names it, e.g. `skType`; `routine` for routine
                   ##   whose own name pass answers with its result, kind unread.
    name*: string  ## Qualified name, e.g. `system.float`.
    file*: string  ## Absolute path of definition.
    line*: int  ## One-based line of definition.
    column*: int  ## Zero-based byte column of definition.

  Query* = object  ## Define what fixer asks of one file: sites to resolve, names to look up.
    path*: string  ## Repository-relative path.
    sites*: seq[(int, int)]  ## One-based line and zero-based byte column of each name.
    names*: seq[string]  ## Names whose global declarations to list.

  Answer* = object  ## Define what semantic pass answers for one file.
    path*: string  ## Repository-relative path.
    reason*: string  ## Why file stays unresolved; empty where it compiled.
    symbols*: Table[(int, int), Symbol]  ## Symbol each site resolves to; absent where none.
    globals*: Table[string, seq[Symbol]]  ## Global declarations of each name, any module.

  Entry = object  ## Define one `nimsuggest` run: where, on what, for which files.
    root: string  ## Absolute root of repository, which query paths are relative to.
    directory: string  ## Absolute directory it runs in: project's, else root.
    file: string  ## Absolute path of entry it compiles.
    bin: string  ## Directory of toolchain serving pin; empty names PATH.
    defines: seq[string]  ## Options it takes before entry.
    queries: seq[Query]

  Asked = object  ## Define `nimsuggest` run started: process, file of commands, file of answers.
    process: Process
    commands: string  ## Path of file process reads commands from.
    answers: string  ## Path of file process writes answers to.


const
  NIMSUGGEST = "nimsuggest"  ## Tool every toolchain ships beside compiler.
  PARALLEL = 4  ## Entries running at once at most.
  HEADER_MARKS = ["usage:", "type '"]  ## Openings of lines `nimsuggest` prints before answers.
  ERROR_SEVERITY = "Error"  ## Severity of `chk` answer that leaves file unresolved.
  BACKEND_JS = "--backend:js"  ## Option asking JavaScript backend, for file C rejects.
  TESTING_DEFINE = "-d:testing"  ## Define stub's own `cmd` passes, read under `tests/`.
  RESULT_KIND = "skResult"  ## Kind of routine's implicit `result`.
  RESULT_SUFFIX = ".result"  ## Last part of qualified name of implicit `result`.
  ROUTINE_KIND = "routine"  ## Kind given routine declared at site whose answer is its result.
  COMMAND_SITE = "def"  ## Command resolving site of entry itself: its definition alone.
  COMMAND_INCLUDED = "dus"
    ## Command resolving site of included file: its definition first, then each use of it.
  TEMP_PREFIX = "koch_suggest_"  ## Opening of name of each temporary file of run.
  TEMP_COMMANDS = ".commands"  ## Extension of file run reads commands from.
  TEMP_ANSWERS = ".answers"  ## Extension of file run writes answers to.


func symbolOf*(line: string): Option[Symbol] =
  ## Read symbol of one answer line: section, kind, name, type, file, line, column, doc, ….
  let fields = line.split('\t')
  if fields.len < 7: return none(Symbol)
  try:
    some(
      Symbol(
        kind: fields[1],
        name: fields[2],
        file: fields[4],
        line: fields[5].parseInt,
        column: fields[6].parseInt,
      ),
    )
  except ValueError: none(Symbol)


func blocksOf*(output: string): seq[seq[string]] =
  ## Split `nimsuggest` output into one block of answer lines per command, header dropped.
  ##   Each command ends its answer with empty line, so empty answer is empty line alone.
  var
    current: seq[string]
    is_header = true
  let text = if output.endsWith("\n"): output[0 ..^ 2] else: output
  for line in text.splitLines:
    if is_header and HEADER_MARKS.anyIt(line.startsWith(it)): continue
    is_header = false
    if line.len == 0:
      result.add current
      current = @[]
    else: current.add line


func declaredAt(symbol: Symbol, path: string, site: (int, int)): Symbol =
  ## Read symbol answered at site of file at repository-relative path: routine declared there
  ##   where answer is its implicit result on that line, else answer itself.
  if symbol.kind != RESULT_KIND or not symbol.file.endsWith("/" & path) or
      symbol.line != site[0] or not symbol.name.endsWith(RESULT_SUFFIX):
    return symbol
  Symbol(
    kind: ROUTINE_KIND,
    name: symbol.name[0 ..< ^RESULT_SUFFIX.len],
    file: symbol.file,
    line: site[0],
    column: site[1],
  )


func isSameName*(a, b: string): bool =
  ## Decide whether two identifiers are one to Nim: first character exact, rest compared
  ##   without case and underscores.
  a.len > 0 and b.len > 0 and a[0] == b[0] and
    a[1 .. ^1].replace("_", "").toLowerAscii == b[1 .. ^1].replace("_", "").toLowerAscii


func includerOf*(tree: Tree, path: string): string =
  ## Read file whose `include` names path, followed up to file nothing includes; path itself
  ##   where nothing includes it.
  result = path
  for _ in 0 .. tree.len:
    var found = ""
    for e in tree:
      if not e.path.endsWith(".nim"): continue
      for line in e.content.splitLines:
        let s = line.strip
        if not s.startsWith("include "): continue
        let
          named = s["include ".len .. ^1].strip(chars = {'"', ' '})
          target = e.path.parentDir / (if named.endsWith(".nim"): named else: named & ".nim")
        if target.normalizedPath == result: found = e.path
      if found.len > 0: break
    if found.len == 0: return
    result = found


func directoryOf(path: string): string =
  ## Read project directory of path; empty for file at root, such as `koch.nim`.
  path.split('/').projectDirectory


proc ask(entry: Entry, is_js: bool): Asked =
  ## Start `nimsuggest` on entry, reading every command entry's queries make from file and
  ##   writing its answers to file, so neither process waits on pipe other leaves full.
  var arguments = @["--v3", "--stdin"] & entry.defines
  if is_js: arguments.add BACKEND_JS
  arguments.add entry.file
  let tool = if entry.bin.len == 0: findExe(NIMSUGGEST) else: entry.bin / NIMSUGGEST
  var commands = ""
  for query in entry.queries:
    let
      file = entry.root / query.path
      command = if file == entry.file: COMMAND_SITE else: COMMAND_INCLUDED
    commands.add "chkFile " & file & "\n"
    for (line, column) in query.sites:
      commands.add command & " " & file & ":" & $line & ":" & $column & "\n"
    for name in query.names: commands.add "globalSymbols " & name & "\n"
  commands.add "quit\n"

  # Run through shell, which redirects both streams to files.
  let (written, path) = createTempFile(TEMP_PREFIX, TEMP_COMMANDS)
  written.write commands
  written.close
  result.commands = path
  result.answers = path.changeFileExt(TEMP_ANSWERS)
  let line = (@[tool] & arguments).mapIt(it.quoteShell).join(" ") & " < " &
    result.commands.quoteShell & " > " & result.answers.quoteShell
  result.process = startProcess(line, workingDir = entry.directory, options = {poEvalCommand})


proc answersOf(entry: Entry, asked: Asked): seq[Answer] =
  ## Read answers of started run, in order commands went: check, sites, names of each file.
  discard asked.process.waitForExit
  asked.process.close
  let output = if fileExists(asked.answers): readFile(asked.answers) else: ""
  removeFile(asked.commands)
  removeFile(asked.answers)
  let blocks = output.blocksOf
  var at = 0
  for query in entry.queries:
    var answer = Answer(path: query.path)
    if at < blocks.len:
      for line in blocks[at]:
        let fields = line.split('\t')
        if fields.len > 7 and fields[3] == ERROR_SEVERITY and answer.reason.len == 0:
          answer.reason = fields[7].strip(chars = {'"'}) & " at line " & fields[5]
    else: answer.reason = "nimsuggest answered nothing"
    inc at
    for site in query.sites:
      if at < blocks.len and blocks[at].len > 0:
        let symbol = blocks[at][0].symbolOf
        if symbol.isSome: answer.symbols[site] = symbol.get.declaredAt(query.path, site)
      inc at
    for name in query.names:
      var found: seq[Symbol]
      if at < blocks.len:
        for line in blocks[at]:
          let symbol = line.symbolOf
          if symbol.isSome and symbol.get.name.split('.')[^1].isSameName(name):
            found.add symbol.get
      answer.globals[name] = found
      inc at
    result.add answer


proc resolve*(root: string, tree: Tree, queries: openArray[Query]): seq[Answer] =
  ## Answer each query through `nimsuggest` of its project's pin; file whose pin nothing serves,
  ##   or which compiles on no backend, is answered unresolved with reason.
  if queries.len == 0: return
  var
    toolchains = initToolchains()
    entries: seq[Entry]
  for query in queries:
    let
      directory = query.path.directoryOf
      pin = tree.pinOf(if directory.len == 0: DRIVER_DIRECTORY else: directory)
    if pin.isNone:
      result.add Answer(path: query.path, reason: "project pins no compiler")
      continue
    let bin = toolchains.binFor(pin.get)
    if bin.isNone:
      result.add Answer(path: query.path, reason: "no compiler serves pin `" & pin.get & "`")
      continue
    let
      absolute = root.absolutePath
      file = absolute / tree.includerOf(query.path)
    var at = entries.mapIt(it.file).find(file)
    if at < 0:
      entries.add Entry(
        root: absolute,
        directory: absolute / directory,
        file: file,
        bin: bin.get,
      )
      if "/tests/" in "/" & query.path: entries[^1].defines.add TESTING_DEFINE
      at = entries.high
    entries[at].queries.add query

  # Run entries several at once on C backend, then again on JavaScript where C reported error.
  var k = 0
  while k < entries.len:
    let batch = entries[k .. min(k + PARALLEL, entries.len) - 1]
    var started: seq[Asked]
    for entry in batch: started.add entry.ask(is_js = false)
    var retried: seq[(Entry, seq[Answer], Asked)]
    for i, entry in batch:
      let answers = entry.answersOf(started[i])
      if answers.allIt(it.reason.len == 0): result.add answers
      else: retried.add (entry, answers, entry.ask(is_js = true))
    for (entry, answers, asked) in retried:
      let again = entry.answersOf(asked)
      for i, answer in answers:
        result.add(if answer.reason.len == 0 or again[i].reason.len > 0: answer else: again[i])
    k += PARALLEL
