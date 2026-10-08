## Run knoller from shell: `knoller [--check] [--nim:path] path...`, fixing each Nim file paths
##   name.
##   Path names file, or directory standing for `.nim`, `.nims` and `.nimble` files `git
##     ls-files` lists under it, sorted. Named file of other extension is passed over; path
##     naming nothing is usage error, and so is directory naming no Nim file, which says why:
##     it lies outside git work tree, or git lists no Nim file under it (`listingOf`). Silent
##     `0 to fix.` would read as clean run over files never read. Git runs as direct process,
##     its stderr read apart from paths, so warning never glues to first of them (`runGit`).
##   Nimble file whose copy `atlas.lock` beside it holds is passed over (`nimblesLocked`).
##   Fix writes only file that changes; `--check` writes none, and reports each change due.
##   Output, sorted by path, line, then rule id: `path:line: <rule-id> fixed`, or `to fix`
##     with `--check`; `path: unsettled: <message>` for file fixers do not settle, which stays
##     as written, with no line and no rule, since fault is tool's (`Fix.unsettled`);
##     `path:line: <rule-id> left: <message>` for finding left for hand, as every check of
##     knoller reads fixed text (`checkSource`), static pass's among them;
##     `path:line: fence-held warning: <message>` for each fence, naming each rule broken
##     inside it with count and first line, so no fenced line goes unseen (`heldOf`); then
##     count, `N fixed.` or `N to fix.`. Line `0` is whole file, so its location is path alone.
##   Every line printed is line of file as given: finding left in fixed text is traced back
##     through fix (`traced`), as each rewrite is. Finding on line fix inserts has no line as
##     given, so it prints at line `0`, path alone, and its message echoes its text.
##   Exit: 0 clean; 1 finding left, file unsettled, or change due under `--check`; 2 usage
##     error. Warning changes no exit code, since fence is escape charter grants (Article X.1).
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
##   Fixers read text as commit stores it. Where checkout wrote CRLF that commit turns back into
##     LF, as `core.autocrlf` does on Windows by default, run reads LF and writes CRLF back
##     (`isConverted`), so no CR reads as trailing whitespace and no fix rewrites line endings.
##     CRLF that commit keeps is read as written, and stays finding.
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

import std/[algorithm, options, os, osproc, parseopt, sequtils, sets, streams, strutils, tables]
import ./[
  chain, compilers, conversions, edits, fences, names, parentheses, pins, proofs, reports, rewrites,
  rules, symbols,
]


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
    code*: int  ## Exit code: 0 clean; 1 finding left, file unsettled, change due on `--check`.
    asked*: seq[string]  ## Source chain asked parser about and no answer holds yet.

  Batch* = object  ## Define files whose groups one compiler proves, and its prover.
    paths*: seq[string]  ## Path of each file, as named.
    prover*: Prover  ## Parser of compiler these files take.

  Pinning = object  ## Define what nearest nimble file at or above directory says of its pin.
    pin: Option[string]  ## Pin it names; `none` where no nimble file stands above, or names none.
    refusal: string  ## Directory holding several nimble files, so no pin; empty where one.

  Part = object  ## Define what fix of one file gives, before `joined` sorts it into outcome.
    path: string  ## Path as named.
    written: seq[(string, string)]  ## Path and new text, where file changes.
    fixed, left, held: seq[Report]  ## Rewrite, finding left and fence warning, unsorted.
    unsettled: string  ## Why fixers leave file as written (`Fix.unsettled`); empty if settled.
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
  ##   `..` resolved, and each separator `/` on every platform (`slashed`), since rules split
  ##   it there to find tests, stubs and drive code.
  slashed(if path.isAbsolute: path.normalizedPath else: normalizedPath(directory / path))


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


func partOf(
  path, source: string;
  is_check: bool;
  directory: string;
  proofs: Proofs;
  answer: Answer;
  plans: openArray[Plan],
): Part =
  ## Fix one file of Nim dialect, as `outcomeOf` does: what file writes and reports, and what it
  ##   asks parser. Renames planned whole across files, and conversion semantic pass settles,
  ##   are written first, from source as given; file whose candidate pass could not resolve
  ##   keeps each conversion, and rename refused warns where it is declared, each saying why.
  let
    dialect = path.dialectOf.get
    layout = path.layoutOf(directory)
    fence = source.fenceOf
  result.held = heldOf(layout, source, dialect, proofs).shownAs(path)
  if fence.lines.len > 0: result.asked.add source.questionsOf(proofs)
  var
    renamed: seq[Edit]
    rewritten: seq[Report]
  for plan in plans:
    if plan.refusal.len > 0:
      if plan.rename.path == path:
        result.held.add initReport(
          path,
          plan.rename.line,
          plan.rename.rule,
          "Rename to `" & plan.rename.renamed & "` stays for hand, since it is refused: " &
            plan.refusal & "; got `" & plan.rename.name & "`.",
        )
      continue
    renamed.add plan.edits.getOrDefault(path)
    for (file, line) in plan.lines:
      if file == path: rewritten.add initReport(path, line, plan.rename.rule)
  var base = source.applied(renamed)
  if answer.reason.len > 0:
    result.held.add initReport(
      path,
      0,
      Rule.Conversion,
      "Semantic pass resolved no name, so each type conversion stays as written; got `" &
        answer.reason & "`.",
    )
  elif answer.symbols.len > 0:
    let (edits, reports) = editsConversion(layout, source, answer, fence.lines, renamed)
    base = source.applied(renamed & edits)
    rewritten.add reports.shownAs(path)
  let fix = formatted(layout, base, dialect, proofs)
  result.asked.add fix.asked
  var after = checkSource(layout, fix.source, dialect, proofs)
  for report in after.mitems: report.line = fix.traced(report.line)  # Line as given.
  result.path = path
  result.unsettled = fix.unsettled
  result.left = after.shownAs(path)
  if fix.source == source: return
  result.fixed = rewritten & fix.fixed.shownAs(path)
  if not is_check: result.written.add (path, fix.source)


func joined(parts: openArray[Part], is_check: bool, failures: openArray[string]): Outcome =
  ## Sort reports of each file's part into lines printed, and decide exit code; each failure of
  ##   prover prints as one warning, in order given.
  var
    fixed, left, held: seq[Report]
    unsettled: seq[string]
  for part in parts:
    result.written.add part.written
    result.asked.add part.asked
    fixed.add part.fixed
    left.add part.left
    held.add part.held
    if part.unsettled.len > 0: unsettled.add part.path & ": unsettled: " & part.unsettled
  let outcome = if is_check: " to fix" else: " fixed"
  for report in fixed.sorted: result.lines.add report.located & outcome
  for line in unsettled.sorted: result.lines.add line
  for report in left.sorted: result.lines.add report.located & " left: " & report.message
  for report in held.sorted: result.lines.add report.located & " warning: " & report.message
  for failure in failures:
    if failure.len > 0: result.lines.add Rule.ParenthesesNeedless.id & " warning: " & failure
  result.lines.add $fixed.len & outcome & "."
  result.code = if left.len + unsettled.len > 0 or (is_check and fixed.len > 0): 1 else: 0
  result.asked = result.asked.deduplicate


func outcomeOf*(
  files: openArray[(string, string)];
  locked: openArray[string];
  is_check: bool;
  directory = "/";
  proofs = Proofs();
  failure = "";
  answers = initTable[string, Answer]();
  plans: openArray[Plan] = [],
): Outcome =
  ## Fix each file of Nim dialect, as path and text, and decide what run writes and prints;
  ##   file `locked` names, or of no dialect, is passed over. Fixers read each path whole from
  ##   directory it is named from (`layoutOf`). Parentheses go where `proofs` prove them, and
  ##   each source no answer reaches is in `Outcome.asked`, source as given too where fence
  ##   holds lines, since fence's warning reads it. Failure of prover prints as warning.
  ##   Conversion goes where answer of semantic pass for path settles it (`answersOf`), and
  ##   rename where its plan writes path (`plansOf`).
  var parts: seq[Part]
  for (path, source) in files:
    if path.dialectOf.isNone or path in locked: continue
    parts.add partOf(
      path, source, is_check, directory, proofs, answers.getOrDefault(path), plans
    )
  parts.joined(is_check, [failure])


proc outcomeProven*(
  files: openArray[(string, string)],
  locked: openArray[string],
  is_check: bool,
  directory: string,
  batches: openArray[Batch],
  answers = initTable[string, Answer](),
  plans: openArray[Plan] = [],
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
    parts.add partOf(
      path, source, is_check, directory, proofs[owner], answers.getOrDefault(path), plans
    )

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
      parts[k] = partOf(
        path, source, is_check, directory, proofs[owners[k]], answers.getOrDefault(path), plans
      )
  parts.joined(is_check, failures)


proc outcomeProven*(
  files: openArray[(string, string)],
  locked: openArray[string],
  is_check: bool,
  directory: string,
  prover: Prover,
): Outcome =
  ## Fix files as batch form does, every file proven by one prover, as `--nim` names it.
  let batch = Batch(paths: files.mapIt(it[0]), prover: prover)
  outcomeProven(files, locked, is_check, directory, [batch])


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
    elif nimbles.len == 1: Pinning(pin: readFile(nimbles[0]).pinNim)
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
  if nim.len > 0: return @[Batch(paths: @paths, prover: proverCompiler(nim))]
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
            proverFailure(
              "Parser proved no removal, since directory holds several nimble files, so no " &
              "pin is trusted; got `" & pinning.refusal & "`.",
            )
          elif pinning.pin.isSome: provers(pinning.pin.get)
          else: proverCompiler(NIM),
      )
      k = keys.high
    result[k].paths.add path


func listingOf*(directory, output: string; code: int): tuple[files: seq[string], refusal: string] =
  ## Read Nim files git lists under directory, sorted, from output and exit code of `git ls-files
  ##   -z` run there; refusal says why directory names none, and is empty where it names some.
  ##   Each path reads with separator `/` (`slashed`), as git lists it, so output of one tree is
  ##   same on every platform.
  if code != 0:
    result.refusal = "Directory lies outside git work tree, so git lists no file under it; got `" &
        directory & "`."
    return
  for name in output.split('\0'):
    if name.len > 0 and name.dialectOf.isSome: result.files.add slashed(directory / name)
  result.files.sort
  if result.files.len == 0:
    result.refusal = "Directory holds no Nim file that git lists; got `" & directory & "`."


func isConverted*(record, autocrlf: string): bool =
  ## Decide from one record of `git ls-files --eol`, and value of `core.autocrlf`, whether
  ##   checkout wrote CRLF that commit turns back into LF: worktree holds CRLF, index holds LF
  ##   or no file yet, and git normalizes file, by `core.autocrlf` or by `text` or `eol`
  ##   attribute, which `-text` overrides.
  let
    info = record.split('\t')[0]
    at = info.find("attr/")
    attribute = if at < 0: "" else: info[at + "attr/".len .. ^1]
    words = attribute.splitWhitespace
  var index, worktree = ""
  for word in info[0 ..< (if at < 0: info.len else: at)].splitWhitespace:
    if word.startsWith("i/"): index = word["i/".len .. ^1]
    elif word.startsWith("w/"): worktree = word["w/".len .. ^1]
  let
    is_binary = "-text" in words
    is_text = words.anyIt(it == "text" or it.startsWith("text=") or it.startsWith("eol="))
    is_normalized = not is_binary and (is_text or autocrlf.strip in ["true", "input"])
  worktree in ["crlf", "mixed"] and index in ["", "lf", "none"] and is_normalized


func judged*(text: string, is_converted: bool): string =
  ## Read text as commit stores it: each CRLF turned LF where checkout converted file.
  if is_converted: text.replace("\r\n", "\n") else: text


func restored*(text: string, is_converted: bool): string =
  ## Read text to write as checkout writes it: each LF turned CRLF where checkout converted file.
  if is_converted: text.replace("\n", "\r\n") else: text


proc runGit*(
  directory: string, arguments: openArray[string]
): tuple[output, failure: string, code: int] =
  ## Run git in directory as direct process with argument list, never through shell, and read
  ##   stdout and stderr apart: output, what git says on stderr, and exit code.
  ##   Git ends warning on stderr in newline rather than NUL, so stream carrying both would glue
  ##     warning to first field of `-z` output.
  ##   Umbrella exports none of command line, so `tree.nim` of `curator/audit` reaches this proc
  ##     here, and reads git through it too.
  ##   Both pipes are drained before exit is waited on, since child blocks where pipe fills.
  let process = startProcess(
    "git",
    args = @["-C", directory] & @arguments,
    options = {poUsePath},
  )
  defer: process.close
  result.output = process.outputStream.readAll
  result.failure = process.errorStream.readAll
  result.code = process.waitForExit


proc listed*(directory: string): tuple[files: seq[string], refusal: string] =
  ## Read Nim files git lists under directory, sorted, or why it names none; what git writes on
  ##   stderr never reaches path (`runGit`).
  let (output, _, code) = runGit(directory, ["ls-files", "-z"])
  listingOf(directory, output, code)


proc convertedOf*(paths: openArray[string]): HashSet[string] =
  ## Read each path whose checkout wrote CRLF that commit turns back into LF (`isConverted`),
  ##   asking git once in each directory; path git knows nothing of is read as written.
  var groups: seq[(string, seq[string])]
  for path in paths:
    let directory = path.parentDir
    var at = groups.mapIt(it[0]).find(directory)
    if at < 0:
      groups.add (directory, @[])
      at = groups.high
    groups[at][1].add path
  for (directory, group) in groups:
    let names = group.mapIt(it.extractFilename)
    let (listing, _, code) = runGit(
      directory,
      @["--literal-pathspecs", "ls-files", "--eol", "-z", "--cached", "--others", "--"] & names,
    )
    if code != 0: continue
    let autocrlf = runGit(directory, ["config", "--get", "core.autocrlf"]).output
    for record in listing.split('\0'):
      let fields = record.split('\t')
      if fields.len < 2: continue
      let k = names.find(fields[1])
      if k >= 0 and record.isConverted(autocrlf): result.incl group[k]


proc projectOf(directory: string): string =
  ## Read nearest directory at or above directory holding nimble file, whose configuration
  ##   compile of file there reads; directory itself where none stands above.
  var at = directory
  while true:
    for kind, path in walkDir(at):
      if kind in {pcFile, pcLinkToFile} and path.endsWith(EXTENSIONS[Dialect.Package]) and
          path.extractFilename.len > EXTENSIONS[Dialect.Package].len:
        return at
    let parent = at.parentDir
    if parent.len == 0 or parent == at: return directory
    at = parent


proc binOf(
  absolute, nim: string; seen: var Table[string, Pinning]; toolchains: var Toolchains
): tuple[bin, reason: string] =
  ## Read toolchain semantic pass of file at absolute path takes: one `--nim` names, else that of
  ##   pin of nearest nimble file, as parser's is (`batchesOf`), else `nim` on `PATH`, named by
  ##   empty `bin`; reason says why none serves.
  if nim.len > 0: return (nim.parentDir, "")
  let pinning = pinningOf(absolute.parentDir, seen)
  if pinning.refusal.len > 0:
    return ("", "directory holds several nimble files, so no pin is trusted: " & pinning.refusal)
  if pinning.pin.isNone: return ("", "")
  let served = toolchains.binFor(pinning.pin.get)
  if served.isNone: return ("", "no compiler serves pin " & pinning.pin.get)
  (served.get, "")


proc listingOf(
  project: string; listings: var Table[string, seq[(string, string)]]
): seq[(string, string)] =
  ## Read path, relative to project, and text of each Nim file git lists under project, once.
  if project notin listings:
    let (listed, _) = project.listed
    listings[project] = listed.mapIt((it.relativePath(project, '/'), readFile(it)))
  listings[project]


proc answersOf*(
  files: openArray[(string, string)]; nim, directory: string; toolchains: var Toolchains
): Table[string, Answer] =
  ## Resolve, through semantic pass, each file of Nim dialect holding type conversion candidate
  ##   (`queryConversion`), keyed by path as named; file holding none is asked nothing. Pass
  ##   runs in project of file, nearest directory holding nimble file, and reads includer
  ##   among Nim files git lists there, with toolchain `binOf` gives. Toolchain none serves
  ##   answers file unresolved, with reason.
  var
    requests: seq[Request]
    keys: seq[string]
    seen = initTable[string, Pinning]()
    listings = initTable[string, seq[(string, string)]]()
  for (path, source) in files:
    if path.dialectOf.isNone: continue
    let
      absolute = path.layoutOf(directory)
      project = absolute.parentDir.projectOf
      query = queryConversion(absolute.relativePath(project, '/'), source)
    if query.sites.len == 0: continue
    let (bin, reason) = binOf(absolute, nim, seen, toolchains)
    if reason.len > 0:
      result[path] = Answer(path: query.path, reason: reason)
      continue
    requests.add Request(
      query: query,
      root: project,
      directory: project,
      includer: project.listingOf(listings).includerOf(query.path),
      bin: bin,
    )
    keys.add path

  # Resolve each project apart, since path relative to project names one file within it alone.
  for project in listings.keys:
    let asked = toSeq(0 ..< requests.len).filterIt(requests[it].root == project)
    for answer in resolve(asked.mapIt(requests[it])):
      for k in asked:
        if requests[k].query.path == answer.path: result[keys[k]] = answer


proc plansOf*(
  files: openArray[(string, string)];
  locked: openArray[string];
  nim, directory: string;
  toolchains: var Toolchains,
): seq[Plan] =
  ## Plan each rename case of name's kind (V.1, V.11) or coined abbreviation (V.6) asks in files
  ##   of Nim dialect, as `names.nim` reads it with jargon alone exempt, since knoller reads no
  ##   glossary. Rename reads every Nim file git lists in project of declaring file, nearest
  ##   directory holding nimble file, and is refused where it would write file not named
  ##   (D2 of #558); local binding reads its own file alone. Plan's paths are paths as named.
  ##   Rename refused before semantic pass, as `renamesCase` refuses it, is plan with reason.
  var
    seen = initTable[string, Pinning]()
    listings = initTable[string, seq[(string, string)]]()
  let named = files.mapIt(it[0].layoutOf(directory))
  for (path, source) in files:
    if path.dialectOf.isNone or path in locked: continue
    let
      absolute = path.layoutOf(directory)
      project = absolute.parentDir.projectOf
      relative = absolute.relativePath(project, '/')
      recased = renamesCase(source, JARGON)
    var renames: seq[Rename]
    for r in recased:
      let rename = Rename(
        path: relative,
        line: r.line,
        column: r.column,
        name: r.name,
        renamed: r.renamed,
        rule: r.rule,
        is_local: r.is_local,
      )
      if r.refusal.len > 0: result.add Plan(rename: rename, refusal: r.refusal)
      else: renames.add rename
    for (line, column, name, full) in renamesAbbreviation(source, JARGON):
      if recased.anyIt(it.line == line and it.column == column): continue
      renames.add Rename(
        path: relative,
        line: line,
        column: column,
        name: name,
        renamed: full,
        rule: Rule.Abbreviation,
      )
    if renames.len == 0: continue

    # Read scope, ask semantic pass every site of it, then plan each rename whole.
    let (bin, reason) = binOf(absolute, nim, seen, toolchains)
    var scope = if relative in project.listingOf(listings).mapIt(it[0]): @[]
                else: @[(relative, source)]
    for (file, text) in project.listingOf(listings):
      scope.add (file, if file == relative: source else: text)
    for rename in renames:
      var plan = Plan(rename: rename)
      let reach = if rename.is_local: scope.filterIt(it[0] == relative) else: scope
      if reason.len > 0: plan.refusal = reason
      else:
        let requests = rename.queriesOf(reach).mapIt(Request(
          query: it,
          root: project,
          directory: project,
          includer: reach.includerOf(it.path),
          bin: bin,
        ))
        var
          answers = initTable[string, Answer]()
          fenced = initTable[string, seq[int]]()
        for answer in resolve(requests): answers[answer.path] = answer
        for (file, text) in reach: fenced[file] = text.fenceOf.lines
        plan = planRename(rename, reach, answers, fenced)
        let outside = toSeq(plan.edits.keys).filterIt(slashed(project / it) notin named)
        if plan.refusal.len == 0 and outside.len > 0:
          plan.refusal = "it would write `" & outside[0] & "`, which this run leaves alone"
          plan.edits.clear
          plan.lines.setLen(0)

      # Name each path as command line names it.
      plan.rename.path = path
      var edits = initTable[string, seq[Edit]]()
      for file, list in plan.edits: edits[files[named.find(slashed(project / file))][0]] = list
      plan.edits = edits
      plan.lines = plan.lines.mapIt((files[named.find(slashed(project / it[0]))][0], it[1]))
      result.add plan


proc lockedOf(paths: openArray[string]): seq[string] =
  ## Read each nimble file of paths whose copy `atlas.lock` beside it holds.
  var locks: seq[(string, string)]
  for path in paths:
    if path.dialectOf != some(Dialect.Package): continue
    let
      directory = path.parentDir
      lock = if directory.len == 0: FILE_LOCK else: directory & "/" & FILE_LOCK
    if fileExists(lock): locks.add (lock, readFile(lock))
  nimblesLocked(locks)


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

  # Resolve conversion candidates, plan renames, group files by compiler proving their groups,
  #   then fix them, each batch asking its own.
  var toolchains = initToolchains()
  let
    directory = getCurrentDir()
    converted = paths.convertedOf
    files = paths.mapIt((it, readFile(it).judged(it in converted)))
    answers = files.answersOf(options.get.nim, directory, toolchains)
    plans = files.plansOf(paths.lockedOf, options.get.nim, directory, toolchains)
    batches = paths.batchesOf(options.get.nim, directory, proversPin(toolchains))
    outcome = outcomeProven(
      files,
      paths.lockedOf,
      options.get.is_check,
      directory,
      batches,
      answers,
      plans,
    )
  for (path, text) in outcome.written: writeFile(path, text.restored(path in converted))
  for line in outcome.lines: echo line
  outcome.code
