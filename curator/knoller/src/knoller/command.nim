## Run knoller from shell: `knoller [--check] [--nim:path] path...`, fixing each Nim file paths
##   name.
##   Path names file, or directory standing for `.nim`, `.nims` and `.nimble` files `git
##     ls-files` lists under it, sorted. Named file of other extension is passed over; path
##     naming nothing is usage error, and so is directory naming no Nim file, which says why:
##     it lies outside git work tree, or git lists no Nim file under it (`listingOf`). Silent
##     `0 to fix.` would read as clean run over files never read.
##   Nimble file whose copy `atlas.lock` beside it holds is passed over (`lockedNimbles`).
##   Fix writes only file that changes; `--check` writes none, and reports each change due.
##   Output, sorted by path, line, then rule id: `path:line: <rule-id> fixed`, or `to fix`
##     with `--check`; `path:line: <rule-id> left: <message>` for finding left for hand;
##     `path:line: fence-held warning: <message>` for each fence, naming each rule broken
##     inside it with count and first line, so no fenced line goes unseen (`heldOf`); then
##     count, `N fixed.` or `N to fix.`. Line `0` is whole file, so its location is path alone.
##   Every line printed is line of file as given: finding left in fixed text is traced back
##     through fix (`traced`), as each rewrite is. Finding on line fix inserts has no line as
##     given, so it prints at line `0`, path alone, and its message echoes its text.
##   Exit: 0 clean; 1 finding left, or change due under `--check`; 2 usage error. Warning
##     changes no exit code, since fence is escape charter grants (Article X.1).
##   No style option: rules are constants, and fence is only escape (Article X.1).
##   Needless parentheses go where parser of file's compiler proves it (`proofs.nim`). Compiler
##     of file is one `--nim` names; else compiler of pin of nearest nimble file at or above
##     directory of file, `nim == <pin>` or `nim#<commit>`, served from PATH, cache or fetch
##     (`compilers.nim`); else `nim` on `PATH` (`batchesOf`). Files of one compiler form one
##     batch, whose prover answers them once each round.
##   Pin no compiler serves, and directory holding several nimble files, whose pin nothing can
##     trust (nimble refuses such directory), prove nothing: rule removes no group in their
##     files, and run prints one line `needless-parentheses warning: <message>` for each, before
##     count. Warning changes no exit code, and no other compiler stands in silently (`GUIDE.md`,
##     Toolchain).
##   Run fixes every file, asks prover of each batch what its files asked, and fixes again each
##     file that asked, at most `ASKS_MAX` times. Pin resolves where first file of it asks, so
##     pin no file asks about is never fetched.
##   Fixers read each path whole, absolute and with `.` and `..` resolved (`layoutOf`), so test
##     file, stub and umbrella read alike however command line names them; output prints path
##     as named.
##   `outcomeOf` decides what run writes and prints from text alone, so suite drives it with
##     no file; `main` reads files, runs git, writes and prints.
##
##   Cost: rule id is stable name for tool reading output, so caller citing article maps it
##     (`curator/audit` holds `CITATIONS`).
##   Cost: directory is read through git, so file git ignores, or does not list yet, is unread
##     there; named file is read whatever git says.
##   Cost: first run on pin machine lacks fetches release, in seconds, or builds commit, in
##     minutes, once; cache serves it after (`compilers.nim`).
##   Cost: nearest nimble file decides, so nested package pinning nothing takes `nim` on `PATH`,
##     never pin of package around it.

{.experimental: "strictFuncs".}

import std/[algorithm, options, os, osproc, parseopt, sequtils, strutils, tables]
import ./[chain, compilers, fences, parentheses, pins, proofs, reports]


const
  USAGE = """
Usage: knoller [--check] [--nim:path] path...

Fix each Nim file path names; directory stands for Nim files git lists under it.

Options:
  --check     write nothing; report each change due, and exit 1 where any
  --nim:path  compiler whose parser proves each parentheses removal; default:
              compiler of pin of nearest nimble file above each file, else `nim`
"""
    ## Text printed on usage error.
  ASKS_MAX = 8
    ## Rounds of asking parser at most; each answers sources chain asked, and tree settles in
    ##   three (`PROVENANCE.md`, Content fixes).


type
  Options* = object  ## Define parsed command line.
    is_check*: bool  ## Report changes due and write none.
    nim*: string  ## Compiler whose parser proves each removal of parentheses; empty: none named.
    paths*: seq[string]  ## Paths named, files or directories, in order given.

  Outcome* = object  ## Define what one run writes and prints, and its exit code.
    written*: seq[(string, string)]  ## Path and new text of each file that changes.
    lines*: seq[string]  ## Lines printed, in order.
    code*: int  ## Exit code: 0 clean, 1 finding left or change due under `--check`.
    asked*: seq[string]  ## Source chain asked parser about and no answer holds yet.

  Batch* = object  ## Define files whose groups one compiler proves, and its prover.
    paths*: seq[string]  ## Path of each file, as named.
    prover*: Prover  ## Parser of compiler these files take.

  Pinning = object  ## Define what nearest nimble file at or above directory says of its pin.
    pin: Option[string]  ## Pin it names; `none` where no nimble file stands above, or names none.
    refusal: string  ## Directory holding several nimble files, so no pin; empty where one.

  Part = object  ## Define what fix of one file gives, before `joined` sorts it into outcome.
    written: seq[(string, string)]  ## Path and new text, where file changes.
    fixed, left, held: seq[Report]  ## Rewrite, finding left and fence warning, unsorted.
    asked: seq[string]  ## Source chain asked parser about and no answer holds yet.


proc parseOptions*(arguments: openArray[string]): Option[Options] =
  ## Parse command line; `none` on unknown option, value where none belongs, `--nim` without
  ##   one, or no path.
  var
    options = Options()
    parser = initOptParser(@arguments)
  for kind, key, value in parser.getopt():
    case kind
    of cmdArgument: options.paths.add key
    of cmdLongOption, cmdShortOption:
      if key == "check" and value.len == 0: options.is_check = true
      elif key == "nim" and value.len > 0: options.nim = value
      else: return none(Options)
    of cmdEnd: break
  if options.paths.len == 0: none(Options) else: some(options)


func dialectOf*(path: string): Option[Dialect] =
  ## Read dialect of file by its extension; `none` for file of no Nim dialect.
  for dialect in Dialect:
    if path.endsWith(EXTENSIONS[dialect]): return some(dialect)
  none(Dialect)


func layoutOf*(path, directory: string): string =
  ## Read path whole, as fixers read it: absolute, from directory it is named from, with `.` and
  ##   `..` resolved.
  if path.isAbsolute: path.normalizedPath else: normalizedPath(directory / path)


func shownAs(reports: openArray[Report], path: string): seq[Report] =
  ## Rename each report of one file to path as named, which output prints.
  for report in reports:
    var shown = report
    shown.path = path
    result.add shown


func located(report: Report): string =
  ## Render location and rule of report: `path:line: <rule-id>`, line `0` left out.
  let location = if report.line == 0: report.path else: report.path & ":" & $report.line
  location & ": " & report.rule.id


func `<`(a, b: Report): bool =
  ## Order reports by path, then line, then rule id, then message, so output is stable.
  if a.path != b.path: return a.path < b.path
  if a.line != b.line: return a.line < b.line
  if a.rule != b.rule: return a.rule.id < b.rule.id
  a.message < b.message


func partOf(path, source: string; is_check: bool; directory: string; proofs: Proofs): Part =
  ## Fix one file of Nim dialect, as `outcomeOf` does: what file writes and reports, and what it
  ##   asks parser.
  let
    dialect = path.dialectOf.get
    layout = path.layoutOf(directory)
  result.held = heldOf(layout, source, dialect, proofs).shownAs(path)
  if source.fenceOf.lines.len > 0: result.asked.add source.questionsOf(proofs)
  let fix = formatted(layout, source, dialect, proofs)
  result.asked.add fix.asked
  var after = checkFormatting(layout, fix.source, dialect, proofs)
  for report in after.mitems: report.line = fix.traced(report.line)  # Line as given.
  result.left = shownAs(fix.left & after, path)
  if fix.source == source: return
  result.fixed = fix.fixed.shownAs(path)
  if not is_check: result.written.add (path, fix.source)


func joined(parts: openArray[Part], is_check: bool, failures: openArray[string]): Outcome =
  ## Sort reports of each file's part into lines printed, and decide exit code; each failure of
  ##   prover prints as one warning, in order given.
  var fixed, left, held: seq[Report]
  for part in parts:
    result.written.add part.written
    result.asked.add part.asked
    fixed.add part.fixed
    left.add part.left
    held.add part.held
  let outcome = if is_check: " to fix" else: " fixed"
  for report in fixed.sorted: result.lines.add report.located & outcome
  for report in left.sorted: result.lines.add report.located & " left: " & report.message
  for report in held.sorted: result.lines.add report.located & " warning: " & report.message
  for failure in failures:
    if failure.len > 0: result.lines.add Rule.NeedlessParentheses.id & " warning: " & failure
  result.lines.add $fixed.len & outcome & "."
  result.code = if left.len > 0 or (is_check and fixed.len > 0): 1 else: 0
  result.asked = result.asked.deduplicate


func outcomeOf*(
  files: openArray[(string, string)];
  locked: openArray[string];
  is_check: bool;
  directory = "/";
  proofs = Proofs();
  failure = "",
): Outcome =
  ## Fix each file of Nim dialect, as path and text, and decide what run writes and prints;
  ##   file `locked` names, or of no dialect, is passed over. Fixers read each path whole from
  ##   directory it is named from (`layoutOf`). Parentheses go where `proofs` prove them, and
  ##   each source no answer reaches is in `Outcome.asked`, source as given too where fence
  ##   holds lines, since fence's warning reads it. Failure of prover prints as warning.
  var parts: seq[Part]
  for (path, source) in files:
    if path.dialectOf.isNone or path in locked: continue
    parts.add partOf(path, source, is_check, directory, proofs)
  parts.joined(is_check, [failure])


proc provenOutcome*(
  files: openArray[(string, string)],
  locked: openArray[string],
  is_check: bool,
  directory: string,
  batches: openArray[Batch],
): Outcome =
  ## Fix files as `outcomeOf` does, ask prover of each batch what its files asked, and fix again
  ##   each file that asked, at most `ASKS_MAX` times; prover that fails is asked no more, and
  ##   its failure prints as warning, one for each batch. Each batch holds answers of its own,
  ##   since two compilers can read one source otherwise. File that asked nothing read only
  ##   sources answered, and answer once held never changes, so fixing it again would give
  ##   same part.
  let read = files.filterIt(it[0].dialectOf.isSome and it[0] notin locked)
  var
    proofs = newSeq[Proofs](batches.len)
    failures = newSeq[string](batches.len)
    owners: seq[int]
    parts: seq[Part]

  # Fix each file once, with answers of batch holding it.
  for (path, source) in read:
    var owner = -1
    for b, batch in batches:
      if path in batch.paths: owner = b
    doAssert owner >= 0, "File reads in no batch; got `" & path & "`."
    owners.add owner
    parts.add partOf(path, source, is_check, directory, proofs[owner])

  # Ask prover of each batch what its files asked, then fix again each file that asked.
  for ask in 1..ASKS_MAX:
    var is_asked = false
    for b, batch in batches:
      var asked: seq[string]
      for k, part in parts:
        if owners[k] == b: asked.add part.asked
      if asked.len == 0: continue
      is_asked = true
      if failures[b].len > 0:
        for source in asked: proofs[b].answers[source] = @[]
      else: failures[b] = proofs[b].answered(asked.deduplicate, batch.prover)
    if not is_asked: break
    for k, (path, source) in read:
      if parts[k].asked.len == 0: continue
      parts[k] = partOf(path, source, is_check, directory, proofs[owners[k]])
  parts.joined(is_check, failures)


proc provenOutcome*(
  files: openArray[(string, string)],
  locked: openArray[string],
  is_check: bool,
  directory: string,
  prover: Prover,
): Outcome =
  ## Fix files as batch form does, every file proven by one prover, as `--nim` names it.
  let batch = Batch(paths: files.mapIt(it[0]), prover: prover)
  provenOutcome(files, locked, is_check, directory, [batch])


proc pinningOf(directory: string, seen: var Table[string, Pinning]): Pinning =
  ## Read pin of nearest nimble file at or above directory, each directory read once.
  if directory in seen: return seen[directory]
  var nimbles: seq[string]
  for kind, path in walkDir(directory):
    let name = path.extractFilename
    if kind in {pcFile, pcLinkToFile} and name.len > EXTENSIONS[Dialect.Package].len and
        name.endsWith(EXTENSIONS[Dialect.Package]):
      nimbles.add path
  let parent = directory.parentDir
  result =
    if nimbles.len > 1: Pinning(refusal: directory)
    elif nimbles.len == 1: Pinning(pin: readFile(nimbles[0]).nimPin)
    elif parent.len == 0 or parent == directory: Pinning()
    else: pinningOf(parent, seen)
  seen[directory] = result


proc batchesOf*(paths: openArray[string]; nim, directory: string; provers: ProverOf): seq[Batch] =
  ## Group files by compiler proving their groups: one `nim` names, for every file; else
  ##   compiler of pin of nearest nimble file at or above directory of file, one batch for each
  ##   pin, `provers` giving its prover; else `nim` on `PATH`. Directory holding several nimble
  ##   files trusts no pin, so its files take prover answering none, with warning naming it.
  ##   Paths read from directory they are named from (`layoutOf`); batch keeps order of first
  ##   path.
  if nim.len > 0: return @[Batch(paths: @paths, prover: compilerProver(nim))]
  var
    keys: seq[string]
    seen = initTable[string, Pinning]()
  for path in paths:
    let
      pinning = pinningOf(path.layoutOf(directory).parentDir, seen)
      key =
        if pinning.refusal.len > 0: "refusal " & pinning.refusal
        elif pinning.pin.isSome: "pin " & pinning.pin.get
        else: "path"
    var k = keys.find(key)
    if k < 0:
      keys.add key
      result.add Batch(
        prover:
          if pinning.refusal.len > 0:
            failureProver(
              "Parser proved no removal, since directory holds several nimble files, so no " &
              "pin is trusted; got `" & pinning.refusal & "`.",
            )
          elif pinning.pin.isSome: provers(pinning.pin.get)
          else: compilerProver(NIM),
      )
      k = keys.high
    result[k].paths.add path


func listingOf*(directory, output: string; code: int): tuple[files: seq[string], refusal: string] =
  ## Read Nim files git lists under directory, sorted, from output and exit code of `git ls-files
  ##   -z` run there; refusal says why directory names none, and is empty where it names some.
  if code != 0:
    result.refusal = "Directory lies outside git work tree, so git lists no file under it; got `" &
        directory & "`."
    return
  for name in output.split('\0'):
    if name.len > 0 and name.dialectOf.isSome: result.files.add directory / name
  result.files.sort
  if result.files.len == 0:
    result.refusal = "Directory holds no Nim file that git lists; got `" & directory & "`."


proc listed(directory: string): tuple[files: seq[string], refusal: string] =
  ## Read Nim files git lists under directory, sorted, or why it names none.
  let (output, code) = execCmdEx("git -C " & directory.quoteShell & " ls-files -z")
  listingOf(directory, output, code)


proc lockedOf(paths: openArray[string]): seq[string] =
  ## Read each nimble file of paths whose copy `atlas.lock` beside it holds.
  var locks: seq[(string, string)]
  for path in paths:
    if path.dialectOf != some(Dialect.Package): continue
    let
      directory = path.parentDir
      lock = if directory.len == 0: LOCK_FILE else: directory & "/" & LOCK_FILE
    if fileExists(lock): locks.add (lock, readFile(lock))
  lockedNimbles(locks)


proc main*(): int =
  ## Fix files command line names; print outcome; return exit code.
  let options = parseOptions(commandLineParams())
  if options.isNone:
    stderr.write USAGE
    return 2
  var paths: seq[string]
  for path in options.get.paths:
    if dirExists(path):
      let (files, refusal) = path.listed
      if refusal.len > 0:
        stderr.write refusal & "\n"
        stderr.write USAGE
        return 2
      paths.add files
    elif fileExists(path): paths.add path
    else:
      stderr.write "Path names no file or directory; got `" & path & "`.\n"
      stderr.write USAGE
      return 2
  paths = paths.deduplicate

  # Group files by compiler proving their groups, then fix them, each batch asking its own.
  let
    directory = getCurrentDir()
    batches = paths.batchesOf(options.get.nim, directory, pinProvers(initToolchains()))
    outcome = provenOutcome(
      paths.mapIt((it, readFile(it))),
      paths.lockedOf,
      options.get.is_check,
      directory,
      batches,
    )
  for (path, text) in outcome.written: writeFile(path, text)
  for line in outcome.lines: echo line
  outcome.code
