## Hold checker to rules it holds everything else to (Article IX.8, Article I.4).
##   Checker checks every project and nothing else checks checker, so each fault it would
##   report elsewhere is rule here rather than one-off correction.
##
##   Dead export: routine exported from check module that no other module and no suite names.
##     STYLE.md §5 puts `*` on intentional export alone, and routine only its own module calls
##     is none. Suite counts as caller: test proves routine works, never that anything wants
##     it, yet pure rules here are covered by calling them directly. Mention anywhere counts,
##     comment included, so rule reports only routines nothing outside their module names.
##     Fixer (`koch fix`) drops `*` where module itself calls routine; routine nothing calls
##     keeps its finding, since to delete it is choice.
##     Knoller is held to it as check module is: audit imports it by path, and its suites call.
##   Missing suite: check module without `tests/suites/t<module>.nim`.
##   Verb mismatch: verbs koch dispatches, verbs its usage text lists, and verbs CURATOR.md
##     tables are one set named three times.
##   Option mismatch: options koch parses and options its usage text prints are one set named
##     twice.
##   Stale mention: `koch <verb>` written where verb is not one koch dispatches. Mention is
##     read in forms that run command, i.e. `nim r koch <verb>`, `./koch <verb>` and code span
##     opening `koch <verb>`, so prose naming koch itself passes. Contributor code is not read,
##     since curator cannot write it; its records are, since curator can.
##
##   Rules apply to checker alone, never to contributor project: one suite per module suits
##     library of small checks and suits nothing else, and projects here group tests by
##     subject rather than by file.
##   Rejected: flagging export only tests use, which is how pure rules are covered here and
##     would need exemption list, second place for truth to live; warning rather than
##     finding, since every finding fails and warning nobody must act on is read by nobody;
##     rescanning every source once per export, i.e. exports times sources, which was half of
##     static pass. Identifiers are counted once per source, and every export reads counts.
##   Cost: routine named in prose is not dead, so comment mentioning retired routine hides
##     it; cost is paid to keep rule free of false findings.
##   Cost: exported operator is skipped, since it is spelled at call sites rather than named.
##   Cost: table rows say what each verb reads and enforces, and that prose is checked by
##     nobody. Only verb set is derived.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, strutils, tables]
import ../../knoller/src/knoller
import ./[findings, markdown, toolchain]


const
  PATH_KOCH* = "koch.nim"  ## Driver whose dispatch names every verb.
  PATH_CURATOR* = "CURATOR.md"  ## Document tabling verbs for curator sessions.
  DIRECTORY_CHECK* = "curator/audit/src/"  ## Modules these rules cover.
  DIRECTORY_SUITE* = "curator/audit/tests/suites/"
    ## Where each module's suite lives; `tests/test_suites.nim` runs them as one program.
  DIRECTORY_KNOLLER_SOURCE = DIRECTORY_KNOLLER & "/src/"
    ## Modules of package checker imports by path, held to dead-export rule as checker is.
  DIRECTORY_KNOLLER_SUITE = DIRECTORY_KNOLLER & "/tests/suites/"  ## Where knoller's suites live.
  EXT_NIM* = ".nim"  ## Extension of module and suite alike.
  ROUTINES* = ["converter", "func", "iterator", "macro", "method", "proc", "template"]
    ## Keywords opening routine definition; exported one ends its name with asterisk.
  MARK_USAGE* = "Usage: koch"  ## Opening of driver's usage text.
  MARK_VERBS* = "Verbs:"
    ## Line opening usage text's verb list: one indented line per verb, verb first.
  MARK_DISPATCH* = "of \""  ## Opening of dispatch branch naming one verb.
  CASE_COMMAND* = "case options.command"
    ## Line opening driver's command dispatch. Option parser cases over labels too, so scan
    ## starts here and ends at that dispatch's `else`, as `KEY_VERSION` names one line of
    ## workflow rather than reading whole file.
  CASE_DRIVER* = "case paramStr(1)"
    ## Line opening project driver's own dispatch. Same shape one level down, and koch reads
    ## it to learn which verbs that project carries (`plan.nim`, `directoriesVerb`).
  CASE_END* = "else:"  ## Line closing dispatch, after which branches belong to something else.
  CASE_OPTION* = "case key"
    ## Line opening driver's option parser, whose branches name one option each, one to line.
  USAGE_END* = "\"\"\""
    ## Line closing driver's usage text, after which `--` names prose rather than usage.
  MARK_OPTION* = "--"  ## Opening of option usage text prints.
  MARK_KOCH* = "koch "  ## Command name as mention writes it, followed by verb.
  MARK_RUN* = "nim r "
    ## Compile-and-run form mention may open with, options between it and `koch`.
  CHARS_VERB = {'a' .. 'z', '-'}  ## Characters verb is spelled with.
  HEADING_TABLE* = "## Checks reference"
    ## Heading above table naming verbs; other tables in same document name other things.
  CHARS_IDENT = {'a' .. 'z', 'A' .. 'Z', '0' .. '9', '_'}
    ## Characters Nim identifier is built from.
  CHARS_OPTION = CHARS_IDENT + {'-'}
    ## Characters option name is built from, as `--dry-run` spells it.


func routinesExported*(source: string): seq[string] =
  ## Collect names routines export, i.e. `func name*` and its keyword siblings.
  ##   Operator, written in backticks, is skipped: it is spelled where used rather than
  ##   named, so counting identifiers can never find its callers. Cost, deliberate.
  for line in source.splitLines:
    let words = line.splitWhitespace
    if words.len < 2 or words[0] notin ROUTINES: continue
    let name = words[1].split({'*', '(', '[', ':', ','})[0]
    if name.len == 0 or not name.allCharsInSet(CHARS_IDENT): continue
    if words[1].len > name.len and words[1][name.len] == '*': result.add name


func identifiers(source: string): CountTable[string] =
  ## Count identifier runs source spells, comments included.
  ##   Runs rather than whitespace words, since call is written `tree.auditTree` as often as
  ##   `auditTree(tree)` and word would hide first form.
  var i = 0
  while i < source.len:
    if source[i] notin CHARS_IDENT:
      inc i
      continue
    var j = i
    while j < source.len and source[j] in CHARS_IDENT: inc j
    result.inc source[i ..< j]
    i = j


func isExporting*(path: string): bool =
  ## Decide whether dead-export rule reads exports of path: check module, `koch.nim`, or module
  ##   of knoller.
  path.startsWith(DIRECTORY_CHECK) or path.startsWith(DIRECTORY_KNOLLER_SOURCE) or path == PATH_KOCH


func isCalling*(path: string): bool =
  ## Decide whether path is suite whose calls keep export alive: audit's or knoller's.
  path.startsWith(DIRECTORY_SUITE) or path.startsWith(DIRECTORY_KNOLLER_SUITE)


func exportsDead*(paths, sources, suites: openArray[string]): seq[(string, string)] =
  ## Read path and name of each routine exported from checker that no other module and no
  ##   suite names. Exports are read from `sources` alone; suites call, and export nothing
  ##   checker owns.
  let counts = sources.mapIt(it.identifiers)
  var total = initCountTable[string]()
  for count in counts: total.merge count
  for suite in suites: total.merge suite.identifiers
  for i, source in sources:
    for name in source.routinesExported:
      if total[name] > counts[i][name]: continue
      result.add (paths[i], name)


func checkExportsDead*(paths, sources, suites: openArray[string]): seq[Finding] =
  ## Report routine exported from checker that no other module and no suite names.
  for (path, name) in exportsDead(paths, sources, suites):
    result.add finding(
      path,
      0,
      "Routine is exported and named by no other module and no suite; drop its `*`, or " &
        "delete it; got `" & name & "`.",
    )


func fixExportsDead*(
  path, source: string; dead: openArray[string]
): tuple[source: string, fixed: seq[Finding]] =
  ## Drop `*` of each routine `dead` names that its own module calls; leave one nothing calls.
  ##   Call is name read as code token beyond its declarations, so comment and string count
  ##   none; to delete routine nothing calls is choice, and its finding stays for hand.
  result.source = source
  var lines = source.split('\n')
  for name in dead:
    var declared: seq[int]
    for i, line in lines:
      let words = line.splitWhitespace
      if words.len >= 2 and words[0] in ROUTINES and words[1].startsWith(name & "*"): declared.add i
    let named = source.tokens.countIt(it.kind == KindToken.Word and it.spelling(source) == name)
    if declared.len == 0 or named <= declared.len: continue
    for i in declared:
      let at = lines[i].find(name & "*")
      lines[i] = lines[i][0 ..< at + name.len] & lines[i][at + name.len + 1 .. ^1]
      result.fixed.add finding(path, i + 1, "dead export (CURATOR.md, Checks reference)")
  result.source = lines.join("\n")


func moduleOf*(path: string): string =
  ## Read module name of check source; empty when path is not one.
  if not (path.startsWith(DIRECTORY_CHECK) and path.endsWith(EXT_NIM)): return ""
  path[DIRECTORY_CHECK.len ..< path.len - EXT_NIM.len]


func checkSuites*(paths: openArray[string]): seq[Finding] =
  ## Report check module carrying no suite of its own.
  let present = paths.toSeq
  for path in paths:
    let module = path.moduleOf
    if module.len == 0: continue
    let suite = DIRECTORY_SUITE & "test_" & module & EXT_NIM
    if suite notin present:
      result.add finding(path, 0, "Check module needs suite; write `" & suite & "`; got nothing.")


func between(line, opening, closing: string): string =
  ## Read text between first opening and next closing mark; empty when either is absent.
  let start = line.find(opening)
  if start < 0: return ""
  let
    rest = line[start + opening.len .. ^1]
    stop = rest.find(closing)
  if stop < 0: "" else: rest[0 ..< stop]


func verbsUsage*(koch: string): seq[string] =
  ## Read verbs driver's usage text lists: first word of each indented line under verb mark,
  ##   up to first line that is not indented.
  var is_inside = false
  for line in koch.splitLines:
    if line.strip == MARK_VERBS:
      is_inside = true
      continue
    if not is_inside: continue
    if not line.startsWith("  ") or line.strip.len == 0: break
    result.add line.splitWhitespace[0]
  result.sort


func verbsDispatch*(source: string, opening = CASE_COMMAND): seq[string] =
  ## Read verbs driver dispatches, i.e. quoted labels of its command branches.
  ##   Line opening dispatch is given rather than fixed, since koch and project driver hold
  ##   same shape under different case: koch cases over parsed options, project driver over
  ##   its first argument. One parser reads both, so koch learns what verbs project carries
  ##   by reading it (`plan.nim`, `directoriesVerb`).
  var is_inside = false
  for line in source.splitLines:
    let s = line.strip
    if s.startsWith(opening):
      is_inside = true
      continue
    if not is_inside: continue
    if s == CASE_END: break
    if not s.startsWith(MARK_DISPATCH): continue
    let verb = s.between("\"", "\"")
    if verb.len > 0 and verb notin result: result.add verb
  result.sort


func labelsOption*(koch: string): seq[string] =
  ## Read options driver parses, i.e. quoted labels of option parser's one-line branches.
  ##   Read stops at first line not opening branch, since parser's `else` returns early and
  ##   command dispatch below it names verbs rather than options.
  var is_inside = false
  for line in koch.splitLines:
    let s = line.strip
    if s.startsWith(CASE_OPTION):
      is_inside = true
      continue
    if not is_inside: continue
    if not s.startsWith(MARK_DISPATCH): break
    let option = s.between("\"", "\"")
    if option.len > 0 and option notin result: result.add option
  result.sort


func optionsUsage*(koch: string): seq[string] =
  ## Read options driver's usage text prints, i.e. `--name` from usage mark to its close.
  var is_inside = false
  for line in koch.splitLines:
    if MARK_USAGE in line: is_inside = true
    if not is_inside: continue
    if line.strip == USAGE_END: break
    var i = line.find(MARK_OPTION)
    while i >= 0:
      var j = i + MARK_OPTION.len
      while j < line.len and line[j] in CHARS_OPTION: inc j
      let option = line[i + MARK_OPTION.len ..< j]
      if option.len > 0 and option notin result: result.add option
      i = line.find(MARK_OPTION, j)
  result.sort


func checkOptions*(koch: string): seq[Finding] =
  ## Report driver's option parser and its usage text disagreeing.
  let parsed = koch.labelsOption
  if parsed.len == 0: return
  let printed = koch.optionsUsage
  if printed != parsed:
    result.add finding(
      PATH_KOCH,
      0,
      "Usage text must print every option parser takes, and no other; expected `" &
        parsed.join(", ") & "`; got `" & printed.join(", ") & "`.",
    )


func section*(markdown, heading: string): string =
  ## Read text under heading, up to next heading of same depth or deeper; empty when absent.
  var
    lines: seq[string]
    is_inside = false
  for line in markdown.splitLines:
    if line.startsWith(heading):
      is_inside = true
      continue
    if is_inside and line.startsWith("## "): break
    if is_inside: lines.add line
  lines.join("\n")


func verbsTable*(curator: string): seq[string] =
  ## Read verbs checks-reference table rows, i.e. its first cell in backticks.
  for row in curator.section(HEADING_TABLE).rowsTable:
    if row.len < 2: continue
    let verb = row[0].strip(chars = {'`'})
    if row[0].startsWith("`") and verb.len > 0 and verb notin result: result.add verb
  result.sort


func checkVerbs*(koch, curator: string): seq[Finding] =
  ## Report driver's verbs, its usage text and CURATOR.md's table disagreeing.
  ##   Three statements of one set, so any two differing means one drifted.
  let dispatched = koch.verbsDispatch
  if dispatched.len == 0: return
  if koch.verbsUsage != dispatched:
    result.add finding(
      PATH_KOCH,
      0,
      "Usage text must print every verb dispatch names; got `" & koch.verbsUsage.join(", ") & "`.",
    )
  if curator.verbsTable != dispatched:
    result.add finding(
      PATH_CURATOR,
      0,
      "Checks table must row every verb koch dispatches, and no other; expected `" &
        dispatched.join(", ") & "`; got `" & curator.verbsTable.join(", ") & "`.",
    )


func isCommandAt(text: string, at: int): bool =
  ## Decide whether `koch` at index is run as command: after `./`, after code span's opening
  ##   backtick, or after `nim r` and options only.
  if at >= 2 and text[at - 2 .. at - 1] == "./": return true
  if at >= 1 and text[at - 1] == '`': return true
  let run = text.rfind(MARK_RUN, last = at - 1)
  if run < 0: return false
  text[run + MARK_RUN.len ..< at].splitWhitespace.allIt(it.startsWith(MARK_OPTION))


func verbsMentioned*(source: string): seq[(int, string)] =
  ## Collect line and verb of every `koch <verb>` source writes as command, in order.
  var number = 0
  for line in source.splitLines:
    inc number
    var at = line.find(MARK_KOCH)
    while at >= 0:
      var j = at + MARK_KOCH.len
      while j < line.len and line[j] in CHARS_VERB: inc j
      let verb = line[at + MARK_KOCH.len ..< j]
      if verb.len > 0 and verb[0] in {'a' .. 'z'} and line.isCommandAt(at):
        result.add (number, verb)
      at = line.find(MARK_KOCH, j)


func checkMentions*(path, source: string; verbs: openArray[string]): seq[Finding] =
  ## Report `koch <verb>` whose verb koch does not dispatch.
  for (line, verb) in source.verbsMentioned:
    if verb in verbs: continue
    result.add finding(
      path,
      line,
      "Mention names verb koch does not dispatch; write one `./koch` lists; got `" & verb & "`.",
    )
