## Enforce staging of compile time, and fix it (`koch fix`): each routine of compile-time family
##   carries `compileTime` alike, and none carries runtime pragma (STYLE.md §2); branch on what
##   build fixes is `when`, never `if` (STYLE.md §3).
##   Member of family is routine compile time alone runs: one `Head.is_compile_time` reads, that
##     is, its pragmas hold `compileTime`, or it nests in macro, `static:` or compile-time routine
##     (`declared.nim`, as `action-verb` reads it); or private routine every use of which lies in
##     member, macro, `static:` block or value of `const`, that is, incidental const evaluation.
##     Rule reads use by name; operator has no name use spells, so rule reads its uses by mentions
##     of type of its first parameter, where mention in `type` section, iterator or template
##     defines that type's interface and is no use. Greatest such set holds, so members calling
##     each other stay.
##   Body of `quote` or `genAst` is code macro emits, which runs where macro puts it: use there
##     is runtime, and routine declared there is no member, though it nests in macro.
##   Family is members of one module, staged where one routine carries its own `compileTime`;
##     module staging none passes. Each member carries its own pragma, nested one too; iterator
##     and template pass, since Nim refuses `compileTime` on both, and macro runs by its keyword.
##   Runtime pragmas, `inline`, `noinit`, `noinline` and `codegenDecl`, act on generated code
##     alone, and compiler generates none for compile-time routine, so each is superstition there.
##   Fix writes on line pragmas stand on, else line closing parameters (`Head.last`): it drops
##     each runtime pragma and puts `compileTime` among bare pragmas in dictionary order (X.10),
##     or opens `{.compileTime.}` before `=` of body. It widens line, so it is widener: off held
##     line it writes freely and wrapping lays line out after; on held line it keeps width guard.
##   Branch on what build fixes is `if` whose condition, and each `elif` of its chain, read only
##     literals, operators, type after `is`, constants, static and typedesc parameters and
##     placeholders of routine around it, calls build answers (`CALLS_BUILD`), and `CALLS_VALUE`
##     of static value. Constant is name `const` binds at module level of file, local `const`
##     above branch in its routine, or name caller passes. Any other name reads as runtime, so
##     its chain passes.
##   `if` in value of `const`, macro, `static:` block or compile-time routine passes: it is no
##     runtime branch, and Nim 2.4.0 cannot read static parameter of macro in `when`.
##   Fix writes `when` for `if`, each `elif` and `else` kept. Branch declaring name stays for
##     hand, since `when` opens no scope (STYLE.md §1), and so does line fix would widen past
##     `LINE_MAX`.
##   Branch reads constants of other modules of its package from caller (`constants`), since rule
##     reads one file; `constantsExported` reads those of one module.
##   Module (`.nim`) alone takes both rules: script and nimble file run in VM alone.
##
##   Cost: rule reads use as word of code on its line, so field or binding of member's name reads
##     as use there, and keeps routine out of family: fewer findings, never false one.
##   Cost: runtime use of operator through field names no type of it, so operator reads as
##     member and fix stages routine runtime calls: false finding, which build refuses.
##   Cost: pair of private routines calling each other, used nowhere else, reads as members.
##   Cost: module staging nothing passes, so routine nesting in its macro keeps runtime pragma.
##   Cost: pragma block spanning lines is unread, so its routine stays for hand.
##   Cost: condition spanning lines is unread, and constant of package run does not read reads as
##     runtime: fewer findings, never false one.
##   Cost: constant counts in each file of its package, imported or not, so runtime name of same
##     spelling from dependency reads as fixed: false finding, which build refuses.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils]
import ./[declared, form, reports, views]


const  # TODO: Document.
  PRAGMA_STAGE = "compileTime"  ## Pragma each member of compile-time family carries.
  PRAGMAS_RUNTIME = ["codegenDecl", "inline", "noinit", "noinline"]
    ## Pragmas acting on generated code alone, which compile-time routine has none of.
  KEYWORDS_STAGED = ["proc", "func", "converter"]  ## Keywords of routine Nim lets carry pragma.
  KEYWORDS_EXPANDED = ["iterator", "template"]
    ## Keywords of routine whose body runs where it is used, so mention there defines type.
  MODIFIERS_TYPE = ["var", "sink", "lent", "ptr", "ref"]  ## Words standing before type name.
  WORDS_OPERATOR = [
    "and", "div", "false", "in", "mod", "nil", "not", "notin", "of", "or", "shl", "shr", "true",
    "xor",
  ]
    ## Words of condition that are operator or literal, which build fixes where operands are.
  WORDS_TYPE = ["is", "isnot"]  ## Words whose right operand is type, which build fixes.
  CALLS_BUILD = ["compileOption", "compiles", "declared", "defined", "sizeof"]
    ## Calls build answers whatever their argument.
  CALLS_VALUE = ["card", "high", "len", "low", "ord"]
    ## Calls that stay static where their argument is: length, bounds, ordinal, cardinal.
  KEYWORDS_DECLARING = [
    "const", "converter", "func", "iterator", "let", "macro", "method", "proc", "template", "type",
    "var",
  ]
    ## Keywords declaring name, which `when` lets reach block around branch.


type  # TODO: Document.
  Extent = tuple[first, last: int]  ## Define one-based lines of block, both included.

  Member = object  ## Define routine of compile-time family, as check reads it.
    head: Head
    is_staged: bool  ## Its pragmas hold `compileTime`.


func keyDictionary(name: string): string =
  ## Read key of dictionary order: case and `_` ignored, as `idioms.nim` sorts pragmas.
  name.toLowerAscii.replace("_", "")


func isHolding(extent: Extent, line: int): bool =
  ## Decide whether one-based line lies inside extent.
  line >= extent.first and line <= extent.last


func lastBlock(lines: openArray[string], first, last: int): int =
  ## Find zero-based last line of block opened at line `first` whose head ends at line `last`:
  ##   each line below deeper than its opening, blank lines inside it included.
  let indent = lines[first].indentWidth
  result = last
  for k in last + 1 ..< lines.len:
    if lines[k].strip.len == 0: continue
    if lines[k].indentWidth <= indent: break
    result = k


func regions(lines: openArray[string]): tuple[fixed, typed, quoted: seq[Extent]] =
  ## Read blocks compile time alone runs, `const` and `static:`, `type` sections, and bodies of
  ##   `quote` and `genAst`, which macro emits as code.
  for k, line in lines:
    let
      s = line.strip
      word = s.identifierAt(0)
      words = s.wordsCode
      extent = (k + 1, lines.lastBlock(k, k) + 1)
    if word == "const" or s.startsWith("static:"): result.fixed.add extent
    elif word == "type": result.typed.add extent
    if ("quote" in words and s.endsWith("do:")) or ("genAst" in words and s.endsWith(":")):
      result.quoted.add (k + 2, extent[1])


func mentions(lines: openArray[string], name: string): seq[int] =
  ## Read one-based line of each mention of name as word of code, as Nim compares names.
  let id = name.identity
  for k, line in lines:
    if line.wordsCode.anyIt(it.identity == id): result.add k + 1


func typeFirst(parameters: string): string =
  ## Read name of type first parameter group takes, modifier dropped: `a, b: O` gives `O`.
  let at = parameters.find(':')
  if at < 0: return ""
  var words = parameters[at + 1 .. ^1].wordsCode
  while words.len > 0 and words[0] in MODIFIERS_TYPE: words.delete(0)
  if words.len == 0: "" else: words[0]


func isInside(extents: openArray[Extent], line: int): bool =
  ## Decide whether one-based line lies inside any extent.
  for extent in extents:
    if extent.isHolding(line): return true
  false


func members(source: string): seq[Member] =
  ## Read each member of compile-time family of source that carries pragma, in order of lines;
  ##   none where no routine carries its own `compileTime`.
  let
    lines = source.codeOnly.splitLines
    heads = source.heads
    (fixed, typed, quoted) = lines.regions
  if not heads.anyIt(PRAGMA_STAGE in it.pragmas): return
  var
    extents: seq[Extent]
    staged = fixed
    expanded: seq[Extent]
  for h in heads:
    let extent = (h.line, lines.lastBlock(h.line - 1, h.last - 1) + 1)
    extents.add extent
    if h.keyword == "macro": staged.add extent
    if h.keyword in KEYWORDS_EXPANDED: expanded.add extent

  # Read uses of each routine outside its own block: by name, or operator by type it takes.
  var uses = newSeq[seq[int]](heads.len)
  for k, h in heads:
    if h.is_operator:
      let name = h.parameters.typeFirst
      if name.len == 0: continue
      for line in lines.mentions(name):
        if extents[k].isHolding(line) or typed.isInside(line) or expanded.isInside(line): continue
        uses[k].add line
    else:
      for line in lines.mentions(h.name):
        if not extents[k].isHolding(line): uses[k].add line

  # Hold greatest set: drop private routine one of whose uses compile time does not alone run.
  var
    is_member = heads.mapIt(
      not quoted.isInside(it.line) and
        (it.is_compile_time or (not it.is_exported and it.keyword != "macro"))
    )
    is_changed = true
  while is_changed:
    is_changed = false
    for k, h in heads:
      if not is_member[k] or h.is_compile_time: continue
      var is_staged = uses[k].len > 0
      for line in uses[k]:
        if quoted.isInside(line):
          is_staged = false
          break
        if staged.isInside(line): continue
        var is_held = false
        for j in 0 ..< heads.len:
          if j != k and is_member[j] and extents[j].isHolding(line):
            is_held = true
            break
        if not is_held:
          is_staged = false
          break
      if not is_staged:
        is_member[k] = false
        is_changed = true
  for k, h in heads:
    if is_member[k] and h.keyword in KEYWORDS_STAGED:
      result.add Member(head: h, is_staged: PRAGMA_STAGE in h.pragmas)


func blockPragma(code: string): tuple[open, close: int] =
  ## Find `{.` and `.}` of last pragma block of code line; `(-1, -1)` where none.
  let open = code.rfind("{.")
  if open < 0: return (-1, -1)
  let close = code.find(".}", open + 2)
  if close < 0: (-1, -1) else: (open, close)


func itemsPragma(line, code: string; open, close: int): seq[string] =
  ## Read each item of pragma block of line, as written, split at commas outside brackets of code.
  var
    depth = 0
    start = open + 2
  for k in open + 2 .. close:
    let c = if k < close: code[k] else: ','
    if c in {'(', '[', '{'}: inc depth
    elif c in {')', ']', '}'}: dec depth
    elif c == ',' and depth == 0:
      let item = line[start ..< k].strip
      if item.len > 0: result.add item
      start = k + 1


func isCarryingRuntime(head: Head): bool =
  ## Decide whether routine's pragmas hold runtime pragma.
  head.pragmas.anyIt(it in PRAGMAS_RUNTIME)


func rewritten(line, code: string, depth_before: int): string =
  ## Write line with runtime pragmas dropped from its pragma block and `compileTime` among its
  ##   bare pragmas, or `{.compileTime.}` opened before `=` of body where line holds no block.
  let (open, close) = code.blockPragma
  if open >= 0:
    var items = line.itemsPragma(code, open, close).filterIt(
      it.identifierAt(0) notin PRAGMAS_RUNTIME
    )
    if not items.anyIt(it.identifierAt(0) == PRAGMA_STAGE):
      var at = 0
      while at < items.len and ':' notin items[at] and
          items[at].identifierAt(0).keyDictionary < PRAGMA_STAGE.keyDictionary:
        inc at
      items.insert(PRAGMA_STAGE, at)
    return line[0 ..< open] & "{." & items.join(", ") & ".}" & line[close + 2 .. ^1]

  # Find `=` opening body outside brackets and backticks; else end of code on line.
  var
    depth = depth_before
    k = 0
    at = -1
  while k < code.len:
    let c = code[k]
    if c == '`':
      let close_tick = code.find('`', k + 1)
      k = (if close_tick < 0: code.len else: close_tick + 1)
      continue
    if c in {'(', '[', '{'}: inc depth
    elif c in {')', ']', '}'}: dec depth
    elif c == '=' and depth == 0 and k > 0 and code[k - 1] == ' ' and
        (k + 1 == code.len or code[k + 1] == ' '):
      at = k - 1
      break
    inc k
  if at < 0: at = code.strip(leading = false).len
  line[0 ..< at] & " {." & PRAGMA_STAGE & ".}" & line[at .. ^1]


func depthAt(lines: openArray[string], first, line: int): int =
  ## Count brackets lines from `first` up to `line`, both zero-based, leave open.
  for k in first ..< line:
    for c in lines[k]:
      if c in {'(', '[', '{'}: inc result
      elif c in {')', ']', '}'}: dec result


func checkFamilies*(path, source: string): seq[Report] =
  ## Report member of compile-time family lacking `compileTime`, and member of staged family
  ##   carrying runtime pragma (STYLE.md §2), at line its pragmas stand on.
  let lines = source.splitLines
  for member in source.members:
    let h = member.head
    if not member.is_staged:
      result.add initReport(
        path,
        h.last,
        Rule.FamilyCompileTime,
        "Routine compile time alone runs carries `compileTime`, as its family does; got `" &
          h.keyword & " " & h.name & "`.",
      )
    elif h.isCarryingRuntime:
      let
        line = lines[h.last - 1]
        (open, close) = line.codeOnly.blockPragma
        shown = if open < 0: h.pragmas.join(", ") else: line[open .. close + 1]
      result.add initReport(
        path,
        h.last,
        Rule.FamilyCompileTime,
        "Compile-time routine carries no runtime pragma; got `" & shown & "`.",
      )


func fixFamilies*(path, source: string; held: Held): Fix =
  ## Add `compileTime` to each member check reports, and drop each runtime pragma, where held line
  ##   stays narrow.
  result.source = source
  let reports = checkFamilies(path, source)
  if reports.len == 0: return
  var
    lines = source.split('\n')
    code = source.codeOnly.split('\n')
  for member in source.members:
    let h = member.head
    if member.is_staged and not h.isCarryingRuntime: continue
    let k = h.last - 1
    if code[k].rfind("{.") >= 0 and code[k].blockPragma.open < 0: continue  # block spans lines
    let written = lines[k].rewritten(code[k], code.depthAt(h.line - 1, k))
    if held.isHeld(h.last) and written.isWide and not lines[k].isWide: continue
    lines[k] = written
    code[k] = written.codeOnly
    result.fixed.add initReport(path, h.last, Rule.FamilyCompileTime)
  result.source = lines.join("\n")


func fixFamilies*(path, source: string): Fix =
  ## Add `compileTime` to each member check reports, and drop each runtime pragma, unless line
  ##   would then be wide.
  fixFamilies(path, source, EVERY)


func isStaticCondition(code: string, fixed: openArray[string]): bool =
  ## Decide whether condition reads only what build fixes: literals, operators, names `fixed`
  ##   holds, calls build answers, length, bounds, ordinal and cardinal of static value, and
  ##   type after `is`.
  var
    k = 0
    is_read = false
  while k < code.len:
    let c = code[k]
    if c in {'0' .. '9'}:
      # Literal runs on through its fraction and suffix: `1.5`, `0x1F`, `2'u8`.
      while k < code.len and (code[k] in CHARS_NAME + {'\''} or
          (code[k] == '.' and k + 1 < code.len and code[k + 1] in {'0' .. '9'})):
        inc k
      is_read = true
      continue
    if c == '.':
      if k + 1 < code.len and code[k + 1] == '.':
        k += 2
        continue
      let word = code.identifierAt(k + 1)
      if word.len > 0 and word notin CALLS_VALUE: return false
      k += 1 + word.len
      continue
    if c notin CHARS_NAME:
      inc k
      continue
    let
      word = code.identifierAt(k)
      after = k + word.len
    var next = after
    while next < code.len and code[next] == ' ': inc next
    is_read = true
    if word in WORDS_TYPE:
      # Type follows `is`, with its brackets: `T is seq[int]`.
      let name = code.identifierAt(next)
      k = next + name.len
      if k < code.len and code[k] == '[' and code.closing(k) > k: k = code.closing(k) + 1
      continue
    if word in CALLS_BUILD:
      if next >= code.len or code[next] != '(' or code.closing(next) < 0: return false
      k = code.closing(next) + 1
      continue
    if word notin WORDS_OPERATOR and word notin fixed and
        not (word in CALLS_VALUE and next < code.len and code[next] == '('):
      return false
    k = after
  is_read


func conditionAt(code: string, at: int): tuple[first, last: int] =
  ## Find condition of `if` or `elif` whose keyword ends at index: from it to `:` closing it
  ##   outside brackets, both exclusive; `(-1, -1)` where line holds no such `:`.
  var depth = 0
  for k in at ..< code.len:
    let c = code[k]
    if c in {'(', '[', '{'}: inc depth
    elif c in {')', ']', '}'}:
      dec depth
      if depth < 0: return (-1, -1)
    elif c == ':' and depth == 0: return (at, k)
  (-1, -1)


func wordsAt(code, word: string): seq[int] =
  ## Find index of each `word` of code standing alone, so `elif` never reads as `if`.
  var at = code.find(word)
  while at >= 0:
    let
      before = at == 0 or code[at - 1] notin CHARS_NAME
      after = at + word.len >= code.len or code[at + word.len] notin CHARS_NAME
    if before and after: result.add at
    at = code.find(word, at + word.len)


func isDeclaring(lines: openArray[string], k: int, tail: string): bool =
  ## Decide whether branch opening at zero-based line `k` declares name in its body, at its own
  ##   level: text after its `:`, or lines below deeper than it.
  if tail.strip.identifierAt(0) in KEYWORDS_DECLARING: return true
  let indent = lines[k].indentWidth
  var level = -1
  for j in k + 1 ..< lines.len:
    let s = lines[j].strip
    if s.len == 0: continue
    let width = lines[j].indentWidth
    if width <= indent: break
    if level < 0: level = width
    if width == level and s.identifierAt(0) in KEYWORDS_DECLARING: return true
  false


type  # TODO: Document.
  Branch = object  ## Define `if` on what build fixes, as fix reads it.
    line: int  ## One-based line of `if`.
    at: int  ## Index of `if` in its line.
    condition: string  ## Condition, as written.
    is_declaring: bool  ## One branch declares name, which `when` would reach block around.


func branchesStatic(source: string; constants: openArray[string]): seq[Branch] =
  ## Read each `if` whose condition, and each `elif` of its chain, reads only what build fixes,
  ##   outside value of `const`, macro, `static:` block and compile-time routine.
  let
    lines = source.split('\n')
    code = source.codeOnly.split('\n')
    heads = source.heads
    (fixed, _, _) = code.regions
    declared = source.declarations
  var
    passed = fixed
    extents: seq[Extent]
  for h in heads:
    let extent = (h.line, code.lastBlock(h.line - 1, h.last - 1) + 1)
    extents.add extent
    if h.keyword == "macro" or h.is_compile_time: passed.add extent
  var global, runtime: seq[string]
  global.add constants
  for d in declared:
    if d.kind != KindName.Binding or d.reach != Reach.Global: continue
    if d.is_constant: global.add d.name else: runtime.add d.name
  global = global.filterIt(it notin runtime)  # global `let` or `var` shadows constant of package

  for i, line in code:
    let one = i + 1
    if passed.isInside(one): continue
    for at in line.wordsAt("if"):
      let (first, last) = line.conditionAt(at + 2)
      if first < 0: continue

      # Names build fixes here: constants, local constants above, and static parameters and
      #   placeholders of each routine around line. Runtime parameter, binding or loop variable
      #   of one name shadows constant, so its name reads as runtime.
      var names, shadowed = newSeq[string]()
      names.add global
      for k, h in heads:
        if not extents[k].isHolding(one) or h.line == one: continue
        names.add h.placeholders
        var group: seq[string]  # names sharing type of next piece: `a, b: static int`
        for piece in h.parameters.split({',', ';'}):
          let
            name = piece.strip.identifierAt(0)
            colon = piece.find(':')
          if colon < 0 and '=' in piece:  # default whose literal fixes type at runtime
            shadowed.add name
            continue
          if name.len > 0: group.add name
          if colon < 0: continue
          let kind = piece[colon + 1 .. ^1].strip.identifierAt(0)
          if kind in ["static", "typedesc", "type"]: names.add group else: shadowed.add group
          group = @[]
        for d in declared:
          if d.kind != KindName.Binding or d.reach != Reach.Local or d.line >= one or
              not extents[k].isHolding(d.line):
            continue
          if d.is_constant: names.add d.name else: shadowed.add d.name
      for j in 0 ..< i:
        let s = code[j].strip
        if not s.startsWith("for ") or " in " notin s or code.lastBlock(j, j) < i: continue
        for variable in s["for ".len ..< s.find(" in ")].split(','):
          shadowed.add variable.strip(chars = {' ', '(', ')'}).identifierAt(0)
      names = names.filterIt(it notin shadowed)
      if not line[first ..< last].isStaticCondition(names): continue

      # Chain: `elif` on same line after condition, or lines below at its indent.
      var
        is_static = true
        is_declaring = false
      let is_statement = line[0 ..< at].strip.len == 0
      for e in line.wordsAt("elif"):
        if e < last: continue
        let (f, l) = line.conditionAt(e + 4)
        if f < 0 or not line[f ..< l].isStaticCondition(names): is_static = false
      if not is_statement:
        # Expression continues on lines deeper than its own; each `elif` there joins chain.
        for j in i + 1 .. code.lastBlock(i, i):
          let s = code[j].strip
          if s.identifierAt(0) != "elif": continue
          let (f, l) = code[j].conditionAt(code[j].indentWidth + 4)
          if f < 0 or not code[j][f ..< l].isStaticCondition(names): is_static = false
      if is_statement:
        is_declaring = code.isDeclaring(i, line[last + 1 .. ^1])
        let indent = line.indentWidth
        for j in i + 1 ..< code.len:
          let s = code[j].strip
          if s.len == 0: continue
          if code[j].indentWidth < indent: break
          if code[j].indentWidth > indent: continue
          let word = s.identifierAt(0)
          if word notin ["elif", "else"]: break
          let (f, l) = code[j].conditionAt(code[j].indentWidth + word.len)
          if word == "elif" and (f < 0 or not code[j][f ..< l].isStaticCondition(names)):
            is_static = false
          let colon = if word == "else": code[j].find(':') else: l
          if colon >= 0 and code.isDeclaring(j, code[j][colon + 1 .. ^1]): is_declaring = true
      if not is_static: continue
      result.add Branch(
        line: one,
        at: at,
        condition: lines[i][first ..< last].strip,
        is_declaring: is_declaring,
      )


func checkBranches*(path, source: string; constants: seq[string] = @[]): seq[Report] =
  ## Report `if` whose condition reads only what build fixes, outside code compile time alone runs
  ##   (STYLE.md §3); `constants` names constants other modules of package export.
  for branch in source.branchesStatic(constants):
    result.add initReport(
      path,
      branch.line,
      Rule.StaticWhen,
      "Branch on static distinction is `when`; got `if " & branch.condition & "`.",
    )


func fixBranches*(path, source: string; constants: seq[string]): Fix =
  ## Write `when` for each `if` check reports, where branch declares no name and line fits.
  result.source = source
  var lines = source.split('\n')
  let branches = source.branchesStatic(constants)
  for k in countdown(branches.high, 0):
    let branch = branches[k]
    if branch.is_declaring: continue
    let
      line = lines[branch.line - 1]
      written = line[0 ..< branch.at] & "when" & line[branch.at + 2 .. ^1]
    if written.isWide and not line.isWide: continue
    lines[branch.line - 1] = written
    result.fixed.insert(initReport(path, branch.line, Rule.StaticWhen), 0)
  result.source = lines.join("\n")


func constantsExported*(source: string): seq[string] =
  ## Read name of each constant module exports at its level, which branch of other module of its
  ##   package reads as fixed by build.
  let code = source.codeOnly.split('\n')
  for d in source.declarations:
    if d.kind != KindName.Binding or not d.is_constant or d.reach != Reach.Global: continue
    let line = code[d.line - 1]
    for at in line.wordsAt(d.name):
      let k = at + d.name.len
      if k < line.len and line[k] == '*':
        result.add d.name
        break
