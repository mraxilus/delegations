## Hold checker to rules it holds everything else to (Article IX.8, Article I.4).
##   Checker checks every project and nothing else checks checker, so each fault it would
##   report elsewhere is rule here rather than one-off correction.
##
##   Dead export: routine exported from check module that no other module and no suite names.
##     STYLE.md §5 puts `*` on intentional export alone, and routine only its own module calls
##     is none. Suite counts as caller: test proves routine works, never that anything wants
##     it, yet pure rules here are covered by calling them directly. Mention anywhere counts,
##     comment included, so rule reports only routines nothing outside their module names.
##   Missing suite: check module without `tests/suites/t<module>.nim`.
##   Verb drift: verbs koch dispatches, verbs its usage text prints, and verbs CURATOR.md
##     tables are one set named three times.
##   Option drift: options koch parses and options its usage text prints are one set named
##     twice.
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
import ./[findings, markdown]


const
  KOCH_PATH* = "koch.nim"
    ## Driver whose dispatch names every verb.
  CURATOR_PATH* = "CURATOR.md"
    ## Document tabling verbs for curator sessions.
  CHECK_DIR* = "curator/audit/src/"
    ## Modules these rules cover.
  SUITE_DIR* = "curator/audit/tests/suites/"
    ## Where each module's suite lives; `tests/tsuites.nim` runs them as one program.
  NIM_EXT* = ".nim"
    ## Extension of module and suite alike.
  ROUTINES* = ["func", "proc", "template", "macro", "iterator", "converter"]
    ## Keywords opening routine definition; exported one ends its name with asterisk.
  USAGE_MARK* = "Usage: koch <"
    ## Opening of driver's usage text, whose angle brackets hold verbs.
  DISPATCH_MARK* = "of \""
    ## Opening of dispatch branch naming one verb.
  COMMAND_CASE* = "case options.command"
    ## Line opening driver's command dispatch. Option parser cases over labels too, so scan
    ## starts here and ends at that dispatch's `else`, as `VERSION_KEY` names one line of
    ## workflow rather than reading whole file.
  DRIVER_CASE* = "case paramStr(1)"
    ## Line opening project driver's own dispatch. Same shape one level down, and koch reads
    ## it to learn which verbs that project carries (`plan.nim`, `verbDirs`).
  CASE_END* = "else:"
    ## Line closing dispatch, after which branches belong to something else.
  OPTION_CASE* = "case key"
    ## Line opening driver's option parser, whose branches name one option each, one to line.
  USAGE_END* = "\"\"\""
    ## Line closing driver's usage text, after which `--` names prose rather than usage.
  OPTION_MARK* = "--"
    ## Opening of option usage text prints.
  TABLE_HEADING* = "## Checks reference"
    ## Heading above table naming verbs; other tables in same document name other things.
  IDENT_CHARS = {'a'..'z', 'A'..'Z', '0'..'9', '_'}
    ## Characters Nim identifier is built from.


func exportedRoutines*(source: string): seq[string] =
  ## Collect names routines export, i.e. `func name*` and its keyword siblings.
  ##   Operator, written in backticks, is skipped: it is spelled where used rather than
  ##   named, so counting identifiers can never find its callers. Cost, deliberate.
  for line in source.splitLines:
    let words = line.splitWhitespace
    if words.len < 2 or words[0] notin ROUTINES: continue
    let name = words[1].split({'*', '(', '[', ':', ','})[0]
    if name.len == 0 or not name.allCharsInSet(IDENT_CHARS): continue
    if words[1].len > name.len and words[1][name.len] == '*': result.add name


func identifiers(source: string): CountTable[string] =
  ## Count identifier runs source spells, comments included.
  ##   Runs rather than whitespace words, since call is written `tree.auditTree` as often as
  ##   `auditTree(tree)` and word would hide first form.
  var i = 0
  while i < source.len:
    if source[i] notin IDENT_CHARS:
      inc i
      continue
    var j = i
    while j < source.len and source[j] in IDENT_CHARS: inc j
    result.inc source[i ..< j]
    i = j


func checkDeadExports*(paths, sources, suites: openArray[string]): seq[Finding] =
  ## Report routine exported from checker that no other module and no suite names.
  ##   Exports are read from `sources` alone; suites call, and export nothing checker owns.
  let counts = sources.mapIt(it.identifiers)
  var total = initCountTable[string]()
  for count in counts: total.merge count
  for suite in suites: total.merge suite.identifiers
  for i, source in sources:
    for name in source.exportedRoutines:
      if total[name] > counts[i][name]: continue
      result.add finding(
        paths[i], 0,
        "Routine is exported and named by no other module and no suite; drop its `*`, or " &
          "delete it; got `" & name & "`.",
      )


func moduleOf*(path: string): string =
  ## Read module name of check source; empty when path is not one.
  if not (path.startsWith(CHECK_DIR) and path.endsWith(NIM_EXT)): return ""
  path[CHECK_DIR.len ..< path.len - NIM_EXT.len]


func checkSuites*(paths: openArray[string]): seq[Finding] =
  ## Report check module carrying no suite of its own.
  let present = paths.toSeq
  for path in paths:
    let module = path.moduleOf
    if module.len == 0: continue
    let suite = SUITE_DIR & "t" & module & NIM_EXT
    if suite notin present:
      result.add finding(
        path, 0,
        "Check module needs suite; write `" & suite & "`; got nothing.",
      )


func between(line, opening, closing: string): string =
  ## Read text between first opening and next closing mark; empty when either is absent.
  let start = line.find(opening)
  if start < 0: return ""
  let rest = line[start + opening.len .. ^1]
  let stop = rest.find(closing)
  if stop < 0: "" else: rest[0 ..< stop]


func usageVerbs(koch: string): seq[string] =
  ## Read verbs driver's usage text prints, in its angle brackets.
  for line in koch.splitLines:
    if USAGE_MARK notin line: continue
    return line.between("<", ">").split('|').mapIt(it.strip).sorted
  @[]


func dispatchVerbs*(source: string, opening = COMMAND_CASE): seq[string] =
  ## Read verbs driver dispatches, i.e. quoted labels of its command branches.
  ##   Line opening dispatch is given rather than fixed, since koch and project driver hold
  ##   same shape under different case: koch cases over parsed options, project driver over
  ##   its first argument. One parser reads both, so koch learns what verbs project carries
  ##   by reading it (`plan.nim`, `verbDirs`).
  var is_inside = false
  for line in source.splitLines:
    let s = line.strip
    if s.startsWith(opening):
      is_inside = true
      continue
    if not is_inside: continue
    if s == CASE_END: break
    if not s.startsWith(DISPATCH_MARK): continue
    let verb = s.between("\"", "\"")
    if verb.len > 0 and verb notin result: result.add verb
  result.sort


func optionLabels*(koch: string): seq[string] =
  ## Read options driver parses, i.e. quoted labels of option parser's one-line branches.
  ##   Read stops at first line not opening branch, since parser's `else` returns early and
  ##   command dispatch below it names verbs rather than options.
  var is_inside = false
  for line in koch.splitLines:
    let s = line.strip
    if s.startsWith(OPTION_CASE):
      is_inside = true
      continue
    if not is_inside: continue
    if not s.startsWith(DISPATCH_MARK): break
    let option = s.between("\"", "\"")
    if option.len > 0 and option notin result: result.add option
  result.sort


func usageOptions*(koch: string): seq[string] =
  ## Read options driver's usage text prints, i.e. `--name` from usage mark to its close.
  var is_inside = false
  for line in koch.splitLines:
    if USAGE_MARK in line: is_inside = true
    if not is_inside: continue
    if line.strip == USAGE_END: break
    var i = line.find(OPTION_MARK)
    while i >= 0:
      var j = i + OPTION_MARK.len
      while j < line.len and line[j] in IDENT_CHARS: inc j
      let option = line[i + OPTION_MARK.len ..< j]
      if option.len > 0 and option notin result: result.add option
      i = line.find(OPTION_MARK, j)
  result.sort


func checkOptions*(koch: string): seq[Finding] =
  ## Report driver's option parser and its usage text disagreeing.
  let parsed = koch.optionLabels
  if parsed.len == 0: return
  let printed = koch.usageOptions
  if printed != parsed:
    result.add finding(
      KOCH_PATH, 0,
      "Usage text must print every option parser takes, and no other; expected `" &
        parsed.join(", ") & "`; got `" & printed.join(", ") & "`.",
    )


func section*(markdown, heading: string): string =
  ## Read text under heading, up to next heading of same depth or deeper; empty when absent.
  var lines: seq[string]
  var is_inside = false
  for line in markdown.splitLines:
    if line.startsWith(heading):
      is_inside = true
      continue
    if is_inside and line.startsWith("## "): break
    if is_inside: lines.add line
  lines.join("\n")


func tableVerbs*(curator: string): seq[string] =
  ## Read verbs checks-reference table rows, i.e. its first cell in backticks.
  for row in curator.section(TABLE_HEADING).tableRows:
    if row.len < 2: continue
    let verb = row[0].strip(chars = {'`'})
    if row[0].startsWith("`") and verb.len > 0 and verb notin result: result.add verb
  result.sort


func checkVerbs*(koch, curator: string): seq[Finding] =
  ## Report driver's verbs, its usage text and CURATOR.md's table disagreeing.
  ##   Three statements of one set, so any two differing means one drifted.
  let dispatched = koch.dispatchVerbs
  if dispatched.len == 0: return
  if koch.usageVerbs != dispatched:
    result.add finding(
      KOCH_PATH, 0,
      "Usage text must print every verb dispatch names; got `" &
        koch.usageVerbs.join(", ") & "`.",
    )
  if curator.tableVerbs != dispatched:
    result.add finding(
      CURATOR_PATH, 0,
      "Checks table must row every verb koch dispatches, and no other; expected `" &
        dispatched.join(", ") & "`; got `" & curator.tableVerbs.join(", ") & "`.",
    )
