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
##   Option drift: options koch parses and options its usage text prints are one set named
##     twice. `--driven` was parsed, documented in header and used by `check.yml`, and usage
##     never printed it.
##   Bootstrap drift: umbrella's `->` diagram (Article I.5) is derived view of every module's
##     `import` line, so it is held to them as I.4 holds table to declarations. Each module
##     appears in diagram; each name there is module; each import is reached along chains
##     from module imported to module importing it; chains form no cycle. Copy of graph
##     drifted once and was deleted; checked copy cannot drift in silence.
##     Chain is one line, `a -> [b, c] -> d`, every member of one group before every member
##     of next. Chains may repeat module, so diagram reads by subject rather than by layer.
##     Cost: new module or new import edits diagram in same change; extra edge that no import
##     asks for passes, since it only orders reading more strictly.
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
    ## it to learn which verbs that project carries (`plan.nim`, `verbDirs`).
  CASE_END* = "else:"
    ## Line closing dispatch, after which branches belong to something else.
  OPTION_CASE* = "case key"
    ## Line opening driver's option parser, whose branches name one option each, one to line.
  USAGE_END* = "\"\"\""
    ## Line closing driver's usage text, after which `--` names prose rather than usage.
  OPTION_MARK* = "--"
    ## Opening of option usage text prints.
  UMBRELLA_PATH* = "curator/audit/src/audit.nim"
    ## Umbrella module whose header states bootstrap order.
  BOOTSTRAP_MARK* = "## Order of module bootstrapping:"
    ## Header line opening diagram; chains follow as `##   ` lines until first line that is
    ## not one.
  CHAIN_PREFIX* = "##   "
    ## Opening of each chain line under mark.
  ARROW* = "->"
    ## Separator between groups of one chain.
  IMPORT_MARK* = "import ./"
    ## Opening of local import, bracketed or bare.
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


func bootstrapChains*(umbrella: string): seq[seq[seq[string]]] =
  ## Read chains of bootstrap diagram, each as groups of module names; empty when absent.
  var is_inside = false
  for line in umbrella.splitLines:
    if line.startsWith(BOOTSTRAP_MARK):
      is_inside = true
      continue
    if not is_inside: continue
    if not line.startsWith(CHAIN_PREFIX): break
    var chain: seq[seq[string]]
    for group in line[CHAIN_PREFIX.len .. ^1].split(ARROW):
      chain.add group.strip.strip(chars = {'[', ']'}).split(',').mapIt(it.strip)
    result.add chain


func identifiers(text: string): seq[string] =
  ## Collect identifier runs of text, in order.
  var i = 0
  while i < text.len:
    if text[i] notin IDENT_CHARS:
      inc i
      continue
    var j = i
    while j < text.len and text[j] in IDENT_CHARS: inc j
    result.add text[i ..< j]
    i = j


func localImports*(source: string): seq[string] =
  ## Read modules source imports from its own directory, sorted.
  ##   Bracket may span lines, as umbrella's does, so text is read to its close.
  var at = source.find(IMPORT_MARK)
  while at >= 0:
    let start = at + IMPORT_MARK.len
    let stop =
      if start < source.len and source[start] == '[': source.find(']', start)
      else: source.find('\n', start)
    let text = source[start ..< (if stop < 0: source.len else: stop)]
    for name in text.identifiers:
      if name notin result: result.add name
    at = source.find(IMPORT_MARK, start)
  result.sort


func checkBootstrap*(paths, sources: openArray[string]): seq[Finding] =
  ## Report umbrella's bootstrap diagram disagreeing with modules' own imports.
  ##   Tree without umbrella is left alone: fixtures of other rules carry none.
  var modules: seq[string]
  var umbrella = ""
  var has_umbrella = false
  for i, path in paths:
    let module = path.moduleOf
    if module.len > 0: modules.add module
    if path == UMBRELLA_PATH:
      umbrella = sources[i]
      has_umbrella = true
  if not has_umbrella: return
  let chains = umbrella.bootstrapChains
  if chains.len == 0:
    return @[finding(
      UMBRELLA_PATH, 0,
      "Umbrella must state bootstrap order as `->` diagram under `" & BOOTSTRAP_MARK &
        "` (Article I.5); got nothing.",
    )]

  # Collect names diagram carries and edges its chains draw.
  var named: seq[string]
  var edges: seq[(string, string)]
  for chain in chains:
    for group in chain:
      for name in group:
        if name notin named: named.add name
    for k in 0 ..< chain.len - 1:
      for a in chain[k]:
        for b in chain[k + 1]: edges.add (a, b)

  # Name each module diagram lacks, and each name that is no module.
  for module in modules:
    if module notin named:
      result.add finding(
        UMBRELLA_PATH, 0,
        "Bootstrap diagram must name every module; got `" & module & "` missing.",
      )
  for name in named:
    if name notin modules:
      result.add finding(
        UMBRELLA_PATH, 0, "Bootstrap diagram must name modules alone; got `" & name & "`.",
      )

  # Walk edges from one module, collecting every module reached after it.
  func reached(start: string): seq[string] =
    var frontier = @[start]
    while frontier.len > 0:
      let node = frontier.pop
      for (a, b) in edges:
        if a == node and b notin result:
          result.add b
          frontier.add b

  # Order each import along chains; module absent from diagram was reported above.
  for i, path in paths:
    let module = path.moduleOf
    if module.len == 0 or module notin named: continue
    for imported in sources[i].localImports:
      if imported notin modules or imported notin named: continue
      if module notin imported.reached:
        result.add finding(
          UMBRELLA_PATH, 0,
          "Bootstrap diagram must place imported module before importer; got `" & imported &
            "` unordered before `" & module & "`.",
        )

  # Name cycle once, since module on it orders nothing.
  let cyclic = named.filterIt(it in it.reached).sorted
  if cyclic.len > 0:
    result.add finding(
      UMBRELLA_PATH, 0,
      "Bootstrap diagram must order modules without cycle; got `" & cyclic.join(", ") & "`.",
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
