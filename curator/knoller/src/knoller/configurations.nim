## Enforce that definitions of one configuration standing next to each other share one block, and
##   that configuration build gets by default comes first (Article X.11), and fix both (`koch
##   fix`), as Architect ruled on rule 14 of #443. Fix never moves definition out of its family.
##   Configuration is condition of `when` at module level, in branch of such `when`, in type
##     section or among fields of object: `when` inside routine holds no definition, so it is
##     unread. `isMainModule` and `compileOption(…)` name no configuration. Conditions reading
##     alike, spaces aside, are one configuration.
##   Join: block of one configuration with no other branch, whose next line past blank lines opens
##     block of same configuration at its indent, with no other branch either: fix deletes head of
##     second, so its body follows first, blank lines between as written. Definition or comment
##     between keeps both apart, since what stands there may belong to either family.
##   Order: two-way `when` whose condition is false by default puts default last, so it reports:
##     fix swaps branches and writes complement, by name of constant naming it
##     (`IS_RIGID* = not IS_CONFORMAL`), else with `not`. Default is read from define of package
##     (`readConfigurations`), so condition no define gives, as `defined(js)` target sets, names
##     no order.
##   Pair: block with no other branch whose condition is false by default, whose next line past
##     blank lines opens block of its complement at its indent, with no other branch either, puts
##     default last, so it reports, as two-way `when` does (ruling `D3 a` of #980). Complement
##     reads as fix of two-way `when` writes it, either way, spaces aside. Fix swaps blocks whole,
##     blank lines between as written; definition or comment between keeps both apart, as for
##     join.
##   Head carrying trailing comment, or body whose indent differs from block it joins, stays for
##     hand, so fix writes no comment away; pair moves each head whole, comment with it. Check and
##     fixer share one reading (`sites`), so rule is written once (Article II.1).
##
##   Cost: scanner on lines, never parser: body runs while lines stand deeper than head, so line
##     of string at column 0 ends it. Branch on line of its head (`when C: a`) and `elif` chain
##     are unread.
##   Cost: complement written otherwise, as `not IS_RIGID` beside `not IS_CONFORMAL`, names no
##     pair, so its order is unread.

{.experimental: "strictFuncs".}

import std/[algorithm, sequtils, strutils, tables]
import ./[reports, views]


const  # TODO: Document.
  GUARDS_UNREAD = ["isMainModule", "compileOption"]  ## Words of condition naming no configuration.
  PRAGMAS_DEFINE = ["booldefine", "define"]  ## Pragmas giving value of constant from define.
  MESSAGE_ORDER = "Configuration build gets by default comes first; got `"
  MESSAGE_JOIN =
    "Definitions of one configuration standing next to each other share one block; got `"


type  # TODO: Document.
  KindSite {.pure.} = enum  ## Define how site breaks rule.
    Join  ## Block of configuration standing next to block of same one.
    Order  ## Two-way branch putting default last.
    Pair  ## Block of configuration standing next to block of its complement, default last.

  Site = object  ## Define one place breaking rule, at `when` head.
    kind: KindSite
    head: int  ## Zero-based line of head reported: second head for join.
    first: int  ## Zero-based line of first head, for join.
    other: int  ## Zero-based line of `else:`, for order, or of second head, for pair.
    last: int  ## Zero-based last line of body of `else:`, for order, or of second block, for pair.
    complement: string  ## Condition true where head's is false, for order.
    is_fixable: bool  ## Whether fix may write site; head with trailing comment stays for hand.


func readConfigurations*(sources: openArray[string]): Configurations =
  ## Read default of each configuration constant of package from its modules: module-level
  ##   constant with `define` or `booldefine` pragma and literal `true` or `false`, then each
  ##   constant written `not` of one read, until none is new.
  var negations: seq[(string, string)]
  for source in sources:
    let
      lines = source.split('\n')
      code = source.codeOnly.split('\n')
    var depth = -1  # indent of bindings of `const` section; `-1` outside one
    for k, line in code:
      let s = line.strip
      if s.len == 0: continue
      let indent = lines[k].indentWidth
      if indent == 0:
        depth = if s == "const": 0 else: -1
        if not s.startsWith("const "): continue
      elif depth == 0: depth = indent
      if indent > 0 and indent != depth: continue

      # Read name, pragma and value of binding.
      let
        binding = if indent == 0: s["const ".len .. ^1].strip else: s
        name = binding.identifierAt(0)
      if name.len == 0: continue
      var rest = binding[binding.find(name) + name.len .. ^1].strip(trailing = false)
      if rest.startsWith('*'): rest = rest[1 .. ^1].strip(trailing = false)
      var words: seq[string]
      if rest.startsWith("{."):
        let close = rest.find(".}")
        if close < 0: continue
        words = rest[2 ..< close].split(AllChars - IdentChars).filterIt(it.len > 0)
        rest = rest[close + 2 .. ^1].strip(trailing = false)
      if rest.startsWith(':'): rest = rest[max(rest.find('='), 0) .. ^1]  # type stated, as `: bool`
      if not rest.startsWith('='): continue
      let value = rest[1 .. ^1].strip
      if PRAGMAS_DEFINE.anyIt(it in words) and value in ["true", "false"]:
        result.defaults[name] = value == "true"
      elif words.len == 0 and value.startsWith("not ") and value[4 .. ^1].strip.validIdentifier:
        negations.add (name, value[4 .. ^1].strip)

  # Read each negation of constant read, until none is new.
  var is_new = true
  while is_new:
    is_new = false
    for (name, other) in negations:
      if name in result.defaults or other notin result.defaults: continue
      result.defaults[name] = not result.defaults[other]
      result.complements[name] = other
      result.complements[other] = name
      is_new = true


func valueDefault(condition: string; configurations: Configurations): tuple[is_known, value: bool] =
  ## Read value condition takes in build with no define: name of constant, or `not` of it.
  var
    words = condition.splitWhitespace
    is_negated = false
  while words.len > 1 and words[0] == "not":
    is_negated = not is_negated
    words = words[1 .. ^1]
  if words.len == 1 and words[0] in configurations.defaults:
    result = (true, configurations.defaults[words[0]] != is_negated)


func complement(condition: string; configurations: Configurations): string =
  ## Write condition true where given one is false: constant naming complement, else `not`.
  let words = condition.splitWhitespace
  if words.len == 1 and words[0] in configurations.complements:
    configurations.complements[words[0]]
  elif words.len == 2 and words[0] == "not": words[1]
  else: "not " & condition.strip


func isComplement(a, b: string; configurations: Configurations): bool =
  ## Decide whether condition is complement of other, either way, as fix of two-way branch
  ##   writes it, spaces aside.
  a.complement(configurations).replace(" ", "") == b.replace(" ", "") or
    b.complement(configurations).replace(" ", "") == a.replace(" ", "")


func isOpen(lines, code: seq[string]; at: int): bool =
  ## Decide whether line stands where configuration holds definitions: at module level, in branch
  ##   of `when`, in type section or among fields of object; never in routine.
  var depth = lines[at].indentWidth
  for j in countdown(at - 1, 0):
    if depth == 0: break
    let s = code[j].strip
    if s.len == 0 or lines[j].indentWidth >= depth: continue
    depth = lines[j].indentWidth
    let is_open = s.startsWith("when ") or s.startsWith("elif ") or s == "else:" or
      s == "type" or s.endsWith("object") or " object of " in s
    if not is_open: return false
  true


func ending(lines: seq[string]; at: int): int =
  ## Read last line, blank lines aside, of body under head at line: lines deeper than head.
  result = at
  for k in at + 1 ..< lines.len:
    if lines[k].strip.len == 0: continue
    if lines[k].indentWidth <= lines[at].indentWidth: break
    result = k


func extent(lines, code: seq[string]; at: int): tuple[last: int, branches: seq[int]] =
  ## Read last line of last branch of `when` at line, and line of each `elif` or `else` head.
  result.last = lines.ending(at)
  while true:
    var next = result.last + 1
    while next < lines.len and lines[next].strip.len == 0: inc next
    if next >= lines.len or lines[next].indentWidth != lines[at].indentWidth: break
    let s = code[next].strip
    if not (s.startsWith("elif ") or s.startsWith("else:")): break
    result.branches.add next
    result.last = lines.ending(next)


func condition(code: string): string =
  ## Read condition of `when` head in code view; empty where line opens no block of `when`.
  let s = code.strip
  if s.startsWith("when ") and s.endsWith(":") and s.len > "when :".len:
    s["when ".len ..< s.len - 1].strip
  else: ""


func bodyIndent(lines: seq[string]; at: int): int =
  ## Read indent of first line, blank lines aside, of body under head at line; `-1` where none.
  result = -1
  for k in at + 1 ..< lines.len:
    if lines[k].strip.len > 0: return lines[k].indentWidth


func sites(source: string; configurations: Configurations): seq[Site] =
  ## Read each site breaking rule in source, sorted by head.
  let
    lines = source.split('\n')
    code = source.codeOnly.split('\n')
    views = source.codeAndComments.split('\n')
  for h in 0 ..< lines.len:
    let configuration = code[h].condition
    if configuration.len == 0 or GUARDS_UNREAD.anyIt(it in configuration) or
        not isOpen(lines, code, h):
      continue
    let (last, branches) = extent(lines, code, h)

    # Two-way branch reads order: condition false by default stands first.
    if branches.len > 0:
      let (is_known, value) = configuration.valueDefault(configurations)
      if branches.len == 1 and code[branches[0]].strip == "else:" and is_known and not value:
        result.add Site(
          kind: KindSite.Order,
          head: h,
          other: branches[0],
          last: last,
          complement: configuration.complement(configurations),
          is_fixable: '#' notin views[h] and '#' notin views[branches[0]],
        )
      continue

    # Block with no other branch joins next block of same configuration, blank lines between,
    #   and stands after next block of its complement where it puts default last, as two-way
    #   branch reads it (ruling `D3 a` of #980). Fix writes no head there, so none stays for hand.
    var next = last + 1
    while next < lines.len and lines[next].strip.len == 0: inc next
    if next >= lines.len or lines[next].indentWidth != lines[h].indentWidth: continue
    let configuration_next = code[next].condition
    if configuration_next.len == 0: continue
    let (last_next, branches_next) = extent(lines, code, next)
    if branches_next.len > 0: continue
    if configuration_next.replace(" ", "") == configuration.replace(" ", ""):
      result.add Site(
        kind: KindSite.Join,
        head: next,
        first: h,
        is_fixable: '#' notin views[next] and lines.bodyIndent(h) == lines.bodyIndent(next),
      )
    elif configuration.isComplement(configuration_next, configurations):
      let (is_known, value) = configuration.valueDefault(configurations)
      if is_known and not value:
        result.add Site(
          kind: KindSite.Pair, head: h, other: next, last: last_next, is_fixable: true
        )
  result.sort(proc (a, b: Site): int = cmp(a.head, b.head))


func written(line, view: string): string =
  ## Read code of line as written, comment left out.
  let at = view.find('#')
  (if at < 0: line else: line[0 ..< at]).strip


func checkConfigurations*(path, source: string; configurations: Configurations): seq[Report] =
  ## Report blocks of one configuration side by side, and two-way branch or pair of complementary
  ##   blocks putting default last.
  let
    lines = source.split('\n')
    views = source.codeAndComments.split('\n')
  for site in sites(source, configurations):
    let head = lines[site.head].written(views[site.head])
    case site.kind
    of KindSite.Join:
      result.add initReport(
        path,
        site.head + 1,
        Rule.BlockConfiguration,
        MESSAGE_JOIN & head & "` at lines `" & $(site.first + 1) & "` and `" & $(site.head + 1) &
          "`.",
      )
    of KindSite.Order, KindSite.Pair:
      result.add initReport(
        path, site.head + 1, Rule.BlockConfiguration, MESSAGE_ORDER & head & "` first."
      )


func fixConfigurations*(path, source: string; configurations: Configurations): Fix =
  ## Join blocks of one configuration side by side, and swap two-way branch or pair of
  ##   complementary blocks putting default last, last site first, reading source again after
  ##   each, so lines above keep their numbers.
  var
    lines = source.split('\n')
    origin = toSeq(1 .. lines.len)
  for _ in 0 .. lines.len:
    let fixable = sites(lines.join("\n"), configurations).filterIt(it.is_fixable)
    if fixable.len == 0: break
    let site = fixable[^1]
    result.fixed.add initReport(path, origin[site.head], Rule.BlockConfiguration)
    case site.kind
    of KindSite.Join:
      lines.delete(site.head)
      origin.delete(site.head)
    of KindSite.Order:
      # Swap bodies; blank lines before `else:` stay before it, and head names complement.
      var close = site.other - 1
      while close > site.head and lines[close].strip.len == 0: dec close
      let
        order = @[site.head] & toSeq(site.other + 1 .. site.last) &
          toSeq(close + 1 ..< site.other) & @[site.other] & toSeq(site.head + 1 .. close)
        before = lines
        head = lines[site.head][0 ..< lines[site.head].indentWidth] & "when " & site.complement &
          ":"
      lines = before[0 ..< site.head] & order.mapIt(before[it]) & before[site.last + 1 .. ^1]
      lines[site.head] = head
      origin = origin[0 ..< site.head] & order.mapIt(origin[it]) & origin[site.last + 1 .. ^1]
    of KindSite.Pair:
      # Swap blocks whole, heads with them; blank lines between stay between.
      var close = site.other - 1
      while close > site.head and lines[close].strip.len == 0: dec close
      let
        order = toSeq(site.other .. site.last) & toSeq(close + 1 ..< site.other) &
          toSeq(site.head .. close)
        before = lines
      lines = before[0 ..< site.head] & order.mapIt(before[it]) & before[site.last + 1 .. ^1]
      origin = origin[0 ..< site.head] & order.mapIt(origin[it]) & origin[site.last + 1 .. ^1]
  result.source = lines.join("\n")
  if result.fixed.len > 0: result.origin = origin
