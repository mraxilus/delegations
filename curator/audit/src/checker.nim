## Hold checker to rules it holds everything else to (Article IX.8, Article I.4).
##   Checker checks every project and nothing checked checker, so three faults it would
##   report elsewhere lived in it until curator pass of 2026-09-06 found them by reading.
##   Each is now rule rather than one-off correction.
##
##   Dead export: routine exported from check module and called from nowhere in checker.
##     `checkRunning` outlived its callers by one change, and its own test kept it compiling,
##     so coverage looked like use. Test proves routine works, never that anything wants it.
##     Mention anywhere in checker counts, comment included, so rule reports only routines
##     nothing names at all.
##   Missing suite: check module without `tests/t<module>.nim`. `findings.nim` carried render
##     and order every finding passes through, and `markdown.nim` parsed every governed
##     table, with no suite between them.
##   Verb drift: verbs koch dispatches, verbs its usage text prints, and verbs CURATOR.md
##     tables are one set named three times. `koch audit` was retired and its row stayed.
##
##   Rules apply to checker alone, never to contributor project: one suite per module suits
##     library of small checks and suits nothing else, and projects here group tests by
##     subject rather than by file.
##   Rejected: flagging export only tests use, which is how pure rules are covered here and
##     would need exemption list, second place for truth to live; warning rather than
##     finding, since every finding fails and warning nobody must act on is read by nobody.
##   Cost: routine named in prose is not dead, so comment mentioning retired routine hides
##     it; cost is paid to keep rule free of false findings.
##   Cost: exported operator is skipped, since it is spelled at call sites rather than named.
##   Cost: table rows say what each verb reads and enforces, and that prose is checked by
##     nobody. Only verb set is derived.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, strutils]
import ./[findings, markdown]


const
  KOCH_PATH* = "koch.nim"
    ## Driver whose dispatch names every verb.
  CURATOR_PATH* = "CURATOR.md"
    ## Document tabling verbs for curator sessions.
  CHECK_DIR* = "curator/audit/src/"
    ## Modules these rules cover.
  SUITE_DIR* = "curator/audit/tests/"
    ## Where each module's suite lives.
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
    ## it to learn which verbs that project carries (`plan.nim`, `drivenDirs`).
  CASE_END* = "else:"
    ## Line closing dispatch, after which branches belong to something else.
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


func mentions*(sources: openArray[string], name: string): int =
  ## Count times checker names routine, its own definition included.
  ##   Identifier runs are counted rather than whitespace words, since call is written
  ##   `tree.auditTree` as often as `auditTree(tree)` and word would hide first form.
  for source in sources:
    var i = 0
    while i < source.len:
      if source[i] notin IDENT_CHARS:
        inc i
        continue
      var j = i
      while j < source.len and source[j] in IDENT_CHARS: inc j
      if source[i ..< j] == name: inc result
      i = j


func checkDeadExports*(paths, sources: openArray[string]): seq[Finding] =
  ## Report routine exported from checker that nothing in checker names.
  ##   One mention is its own definition, so anything above one has caller or reader.
  for i, source in sources:
    for name in source.exportedRoutines:
      if sources.mentions(name) > 1: continue
      result.add finding(
        paths[i], 0,
        "Routine is exported and called nowhere in checker; delete it, or call it; got `" &
          name & "`.",
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


func usageVerbs*(koch: string): seq[string] =
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
  ##   by reading it (`plan.nim`, `drivenDirs`).
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
