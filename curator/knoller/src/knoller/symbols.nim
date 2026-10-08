## Resolve names of Nim source to symbols through compiler's own semantic pass: `nimsuggest` of
##   toolchain serving project's pin, for fixers whose rule text cannot settle
##   (`conversions.nim`).
##   Caller names, for each file asked, directory run starts in, file including it, and
##     toolchain: `koch` from tree it reads, command line from nearest nimble file
##     (`command.nim`).
##   Text cannot tell conversion `x.T` from field or module path (`rigid3.Point`), nor find every
##     use of name across modules; semantic pass of pin project runs on can, symbol by symbol.
##   One `nimsuggest --v3 --tester` serves each entry: file itself, or file including it, since
##     included file compiles inside includer alone. It runs in project directory, so project's
##     `nim.cfg` and `config.nims` apply, with `-d:testing` under `tests/` as stubs compile
##     (STYLE.md §6).
##   Tester mode reads commands as `--stdin` does, and prints `!EOF!` once ready and after each
##     answer, with no help and no prompt. `--stdin` prompts `> ` before each command on
##     Windows, which glues prompt to first line of every answer there.
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
##   Shell is `sh` on POSIX, where `poEvalCommand` runs line through it, and `cmd` on Windows,
##     where `poEvalCommand` hands line to `CreateProcess` with no shell between, so nothing
##     there would read redirection (`lineRedirected`). Cost: `%` in path expands in `cmd`
##     where it names variable, so such path reaches run changed.
##
##   Rejected: compiler as library inside knoller, which compiles compiler into every build of it
##     and binds it to one pin, where ronri projects lex glyphs only their commit pin knows.
##     Rejected: `nim check --def` for each site, one compile of project per site. `nimsuggest`
##     ships with every toolchain knoller serves, so it costs no build.
##   Cost: one compile per entry, about 2 s for module of curator and 5 to 9 s for front-end or
##     suite of `rga_visualiser` (measured 2026-10-02 on this container, 2.2.12 and commit pin).
##     Callers ask only files holding candidate, which their prefilter keeps few.
##   Cost: checkout project's lock restores, and native library, are needed to compile; file
##     lacking either stays unresolved.
##   Cost: branch of `when` that entry's defines leave untaken resolves nothing, so fixers leave
##     names there.

{.experimental: "strictFuncs".}

import std/[options, os, osproc, sequtils, strutils, tables, tempfiles]
import ./views


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

  Request* = object  ## Define query of one file, and where and with what toolchain it runs.
    query*: Query
    root*: string  ## Absolute directory query's path is relative to.
    directory*: string  ## Absolute directory run starts in, so project's configuration applies.
    includer*: string  ## Path, relative to root, of file whose compile holds query's file.
    bin*: string  ## Directory of toolchain serving pin; empty names PATH.

  Answer* = object  ## Define what semantic pass answers for one file.
    path*: string  ## Repository-relative path.
    reason*: string  ## Why file stays unresolved; empty where it compiled.
    symbols*: Table[(int, int), Symbol]  ## Symbol each site resolves to; absent where none.
    globals*: Table[string, seq[Symbol]]  ## Global declarations of each name, any module.

  Entry = object  ## Define one `nimsuggest` run: where, on what, for which files.
    root: string  ## Absolute directory query paths are relative to.
    directory: string  ## Absolute directory it runs in.
    file: string  ## Absolute path of entry it compiles.
    bin: string  ## Directory of toolchain serving pin; empty names PATH.
    defines: seq[string]  ## Options it takes before entry.
    queries: seq[Query]

  Asked = object  ## Define `nimsuggest` run started: process, file of commands, file of answers.
    process: Process  ## Run itself; nil where `missing` says why none started.
    commands: string  ## Path of file process reads commands from.
    answers: string  ## Path of file process writes answers to.
    missing: string  ## Why no run started, since toolchain holds no `nimsuggest`; empty if one did.


const
  NIMSUGGEST = "nimsuggest"  ## Tool every toolchain ships beside compiler.
  PARALLEL = 4  ## Entries running at once at most.
  MARK_END = "!EOF!"  ## Line tester mode prints once ready and after each answer.
  SEVERITY_ERROR = "Error"  ## Severity of `chk` answer that leaves file unresolved.
  BACKEND_JS = "--backend:js"  ## Option asking JavaScript backend, for file C rejects.
  DEFINE_TESTING = "-d:testing"  ## Define stub's own `cmd` passes, read under `tests/`.
  KIND_RESULT = "skResult"  ## Kind of routine's implicit `result`.
  SUFFIX_RESULT = ".result"  ## Last part of qualified name of implicit `result`.
  KIND_ROUTINE = "routine"  ## Kind given routine declared at site whose answer is its result.
  COMMAND_SITE = "def"  ## Command resolving site of entry itself: its definition alone.
  COMMAND_INCLUDED = "dus"
    ## Command resolving site of included file: its definition first, then each use of it.
  TEMP_PREFIX = "knoller_suggest_"  ## Opening of name of each temporary file of run.
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
  ## Split output of tester mode into one block of answer lines per command. Mark printed once
  ##   ready opens first answer, and each answer ends at mark, so text before first mark is no
  ##   answer, output with no mark holds none, and answer no mark closes was cut short and
  ##   reads as none.
  var
    current: seq[string]
    is_ready = false
  for line in output.splitLines:
    if line == MARK_END:
      if is_ready: result.add current
      current = @[]
      is_ready = true
    elif is_ready and line.len > 0: current.add line


func declaredAt(symbol: Symbol, path: string, site: (int, int)): Symbol =
  ## Read symbol answered at site of file at repository-relative path: routine declared there
  ##   where answer is its implicit result on that line, else answer itself.
  if symbol.kind != KIND_RESULT or not symbol.file.endsWith("/" & path) or
      symbol.line != site[0] or not symbol.name.endsWith(SUFFIX_RESULT):
    return symbol
  Symbol(
    kind: KIND_ROUTINE,
    name: symbol.name[0 ..< ^SUFFIX_RESULT.len],
    file: symbol.file,
    line: site[0],
    column: site[1],
  )


func includerOf*(files: openArray[(string, string)], path: string): string =
  ## Read file whose `include` names path, followed up to file nothing includes; path itself
  ##   where nothing includes it. Files are path and text, paths relative to one directory.
  result = path
  for _ in 0 .. files.len:
    var found = ""
    for (file, text) in files:
      if not file.endsWith(".nim"): continue
      for line in text.splitLines:
        let s = line.strip
        if not s.startsWith("include "): continue
        let
          named = s["include ".len .. ^1].strip(chars = {'"', ' '})
          target = file.parentDir / (if named.endsWith(".nim"): named else: named & ".nim")
        if target.normalizedPath == result: found = file
      if found.len > 0: break
    if found.len == 0: return
    result = found


func lineRedirected*(
  tool: string; arguments: openArray[string]; commands, answers: string; cmd = ""
): string =
  ## Render line running tool with arguments, reading commands from file and writing answers to
  ##   file: through `sh` where `cmd` is empty, else through `cmd` at that path, as Windows
  ##   needs. Every word is quoted there, since no path holds `"` on Windows; `/d` skips
  ##   AutoRun commands, `/v:off` reads `!` as itself, and `/s` strips outer quotes alone.
  if cmd.len == 0:
    return (@[tool] & @arguments).mapIt(it.quoteShellPosix).join(" ") & " < " &
      commands.quoteShellPosix & " > " & answers.quoteShellPosix
  let inner = (@[tool] & @arguments).mapIt('"' & it & '"').join(" ") & " < \"" & commands &
    "\" > \"" & answers & '"'
  '"' & cmd & "\" /d /v:off /s /c \"" & inner & '"'


proc ask(entry: Entry, is_js: bool): Asked =
  ## Start `nimsuggest` on entry, reading every command entry's queries make from file and
  ##   writing its answers to file, so neither process waits on pipe other leaves full.
  ##   Toolchain holding no `nimsuggest` starts none, and says so, so each file stays unresolved
  ##   with that reason rather than reading empty output as answer.
  var arguments = @["--v3", "--tester"] & entry.defines
  if is_js: arguments.add BACKEND_JS
  arguments.add entry.file
  let tool =
    if entry.bin.len == 0: findExe(NIMSUGGEST) else: entry.bin / NIMSUGGEST.addFileExt(ExeExt)
  if tool.len == 0 or not fileExists(tool):
    result.missing =
      if entry.bin.len == 0: "no nimsuggest on PATH" else: "no nimsuggest in " & entry.bin
    return
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
  let
    cmd = when defined(windows): getEnv("ComSpec", "cmd.exe") else: ""
    line = lineRedirected(tool, arguments, result.commands, result.answers, cmd)
  result.process = startProcess(line, workingDir = entry.directory, options = {poEvalCommand})


proc answersOf(entry: Entry, asked: Asked): seq[Answer] =
  ## Read answers of started run, in order commands went: check, sites, names of each file.
  ##   Run that never started answers each file unresolved, with reason it gives.
  var output = ""
  if asked.missing.len == 0:
    discard asked.process.waitForExit
    asked.process.close
    if fileExists(asked.answers): output = readFile(asked.answers)
    removeFile(asked.commands)
    removeFile(asked.answers)
  let blocks = output.blocksOf
  var at = 0
  for query in entry.queries:
    var answer = Answer(path: query.path)
    if at < blocks.len:
      for line in blocks[at]:
        let fields = line.split('\t')
        if fields.len > 7 and fields[3] == SEVERITY_ERROR and answer.reason.len == 0:
          answer.reason = fields[7].strip(chars = {'"'}) & " at line " & fields[5]
    elif asked.missing.len > 0: answer.reason = asked.missing
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
          if symbol.isSome and symbol.get.name.split('.')[^1].identity == name.identity:
            found.add symbol.get
      answer.globals[name] = found
      inc at
    result.add answer


proc resolve*(requests: openArray[Request]): seq[Answer] =
  ## Answer each request through `nimsuggest` of its toolchain; file that compiles on no
  ##   backend is answered unresolved with reason. Requests whose includer is one file share
  ##   one run.
  var entries: seq[Entry]
  for request in requests:
    let file = request.root / request.includer
    var at = entries.mapIt(it.file).find(file)
    if at < 0:
      entries.add Entry(
        root: request.root,
        directory: request.directory,
        file: file,
        bin: request.bin,
      )
      if "/tests/" in "/" & request.query.path: entries[^1].defines.add DEFINE_TESTING
      at = entries.high
    entries[at].queries.add request.query

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
