## Enforce Article I.6 and STYLE.md §5 on sibling markers: private symbol sibling reaches through
##   `{.all.}`, and its own module never uses, carries `{.used.}` and comment naming sibling;
##   `{.all.}` import reaches private symbol. Check and fixer read uses caller passes (`Uses`), as
##   semantic pass answered them.
##   Rulings of rule 7 (#443) fix three readings:
##   - Q1: sibling is module of package outside its `tests`; suite reaching internal needs no
##     marker, since test reaches internals by design. Its `{.all.}` still reaches something.
##   - Q2: marker stands only where sibling reaches symbol and its own module never uses it, as
##     compiler confirms: each such symbol is hint that it is declared and never used.
##   - Q3: `{.all.}` import of module outside package is not read, and its markers belong to
##     its own package.
##   Private symbol is name module declares at top level, under blocks opening no scope (`when`
##     chain, section keyword), outside entry block, with no `*`: routine, operator among them,
##     type, and single binding (`privatesTop`). Each is asked where every use of it stands
##     (`use`), at last byte of its name, or first of its operator, so implicit `result` that
##     routine at column 5 declares never answers. Answer lines of other symbol at same place,
##     as one `{.borrow.}` calls, are left out by name and type; use inside its own name is none.
##   Use counts where compiler resolves it, implicit call among them: `for d in x` calls `items`,
##     and `x[i]` calls `[]`. Caller asks in entry of each file importing module with `{.all.}`,
##     under each configuration its stubs give, so each `when` branch one takes is read.
##   `from M {.all.} import a, b` names its reach in its text, so it reaches where it names
##     private symbol of `M`.
##   Comment names sibling where it holds file name of each sibling reaching symbol, in any
##     spelling, as `# Used in cayleys.nim.`; comment rule decides backticks.
##   Fixer puts `used` among bare pragmas of block in dictionary order (X.10), or opens
##     `{.used.}` after name and its placeholders and parameters; comment `# Used in `x.nim`.`
##     trails line holding pragma. Doc cannot share line with plain comment, so trailing doc moves
##     to next line, one level in; fix moves that line, and caller traces it (`originApplied`).
##     Line holding plain comment, marker whose comment names no sibling, line marker would widen
##     past `LINE_MAX`, fenced line (X.1), and span edit of other fixer writes keep it for hand.
##   Fixer drops `{.all.}` of import reaching nothing, with space before it.
##
##   Cost: binding line declaring several names is unread, so its symbols take no marker.
##   Cost: use inside template body of module counts as use of module, where compiler may count
##     it only at expansion; fewer reports, never false one.
##   Cost: forward declaration answers its routine's own name as use, so forward-declared
##     symbol takes no marker.

{.experimental: "strictFuncs".}

import std/[algorithm, os, sequtils, sets, strutils, tables]
import ./[edits, form, reports, symbols, tokens, views]


type
  UsePrivate* = object  ## Define where semantic pass finds private symbol used.
    siblings*: seq[string]
      ## File name of each sibling using it, outside `tests` of package, as `cayleys.nim`.
    is_own*: bool  ## Own module uses it, beyond its declaration.

  Uses* = object  ## Define what semantic pass tells marker rule of one file.
    reason*: string  ## Why pass resolved nothing for file; empty where it resolved.
    privates*: Table[(int, int), UsePrivate]
      ## Use of each private symbol file declares at top level, by one-based line and zero-based
      ##   byte column of its name; symbol no module of package imports with `{.all.}` is absent.
    imports*: Table[(int, int), bool]
      ## Whether each `{.all.}` import of module of package reaches private symbol, by line and
      ##   column of module it names; import of module outside package is absent.

  Private* = object  ## Define private symbol module declares at top level.
    name*: string  ## Name as declared, operator in backticks.
    keyword*: string  ## Keyword declaring it: routine's, `type`, `const`, `let` or `var`.
    line*: int  ## One-based line of name.
    column*: int  ## Zero-based byte column of first byte of name.
    index: int  ## Index of name token.

  ImportAll* = object  ## Define item of import that opens it with `{.all.}`.
    module*: string  ## Module as import names it, as `./algebra`.
    item: string  ## Name of item as written, as `algebra`.
    line*: int  ## One-based line of module's name.
    column*: int  ## Zero-based byte column of module's name.
    names*: seq[string]  ## Names `from … import` lists; empty for `import`.
    first: int  ## Byte offset of space before `{.all.}`, span fixer drops.
    after: int  ## Byte offset after `.}`.


const
  KEYWORDS_ROUTINE = ["converter", "func", "iterator", "macro", "method", "proc", "template"]
    ## Keywords declaring routine.
  KEYWORDS_SECTION = ["const", "let", "type", "var"]  ## Keywords opening section or single one.
  WORDS_CHAIN = ["elif", "else", "when"]  ## Words opening branch of `when` chain.
  PRAGMA_USED = "used"  ## Pragma marking symbol another module uses.
  PRAGMA_ALL = "all"  ## Pragma of import opening private symbols.
  ENTRY = "isMainModule"  ## Name whose `when` opens entry block, which import never runs.
  FOLDER_TESTS = "tests"  ## Folder of package holding its suites, whose reach makes no sibling.


func firsts(tokens: openArray[Token], lines: int): seq[int] =
  ## Read index of first code token of each zero-based line; `-1` where none opens there.
  result = newSeqWith(lines, -1)
  for k, t in tokens:
    if t.kind != KindToken.Comment and t.line < lines and result[t.line] < 0: result[t.line] = k


func isExported(tokens: openArray[Token], k: int, source: string): bool =
  ## Decide whether name token `k` carries export mark `*` glued after it.
  k + 1 < tokens.len and tokens[k + 1].first == tokens[k].after and
    tokens[k + 1].spelling(source) == "*"


func privatesTop*(source: string): seq[Private] =
  ## Read each private symbol source declares at top level: routine, operator among them, type and
  ##   single binding, under blocks opening no scope, outside entry block, with no `*`.
  let
    tokens = source.tokens
    starts = source.lineStarts
    code = source.codeOnly.splitLines
    depths = source.indents
    opening = tokens.firsts(code.len)
  for line in 0 ..< code.len:
    let k = opening[line]
    if k < 0: continue

    # Top level: every block above is `when` chain outside entry, or one section keyword alone.
    var
      is_top = true
      section = ""
    for n, parent in depths.parents(line):
      let words = code[parent].wordsCode
      if words.len == 0: continue
      if words[0] in WORDS_CHAIN and ENTRY notin words: continue
      if n == 0 and words.len == 1 and words[0] in KEYWORDS_SECTION:
        section = words[0]
        continue
      is_top = false
      break
    if not is_top: continue

    # Name: after routine keyword, after section keyword on its line, or opening section child.
    let word = tokens[k].spelling(source)
    var
      name = -1
      keyword = ""
    if tokens[k].kind == KindToken.Word and (word in KEYWORDS_ROUTINE or word in KEYWORDS_SECTION):
      if k + 1 < tokens.len and tokens[k + 1].line == line: (name, keyword) = (k + 1, word)
    elif section.len > 0: (name, keyword) = (k, section)
    if name < 0 or tokens[name].kind notin {KindToken.Word, KindToken.Quoted}: continue
    if tokens[name].kind == KindToken.Word and tokens[name].isKeyword(source): continue
    if tokens.isExported(name, source): continue
    if keyword in ["const", "let", "var"] and name + 1 < tokens.len and
        tokens[name + 1].kind == KindToken.Comma:
      continue
    result.add Private(
      name: tokens[name].spelling(source),
      keyword: keyword,
      line: line + 1,
      column: tokens[name].first - starts[line],
      index: name,
    )


func site(private: Private): (int, int) =
  ## Read site semantic pass is asked at: first byte of operator past its backtick, else last
  ##   byte of name, so implicit `result` of routine at column 5 never answers there.
  if private.name.startsWith('`'): (private.line, private.column + 1)
  else: (private.line, private.column + private.name.len - 1)


func queryUses*(path, source: string): Query =
  ## Build what marker rule asks semantic pass of module: every use of each private symbol.
  result.path = path
  for private in source.privatesTop: result.usages.add private.site


func itemAll(
  tokens: openArray[Token]; indexes: openArray[int]; prefix, source: string; names: seq[string]
): seq[ImportAll] =
  ## Read item of import whose tokens `indexes` hold, where `{.all.}` follows its module.
  let starts = source.lineStarts
  let at = toSeq(0 ..< indexes.len).filterIt(
    tokens[indexes[it]].spelling(source) == "{." and it + 2 < indexes.len and
      tokens[indexes[it + 1]].spelling(source) == PRAGMA_ALL and
      tokens[indexes[it + 2]].spelling(source) == ".}"
  )
  if at.len == 0 or at[0] == 0: return
  let
    path = indexes[0 ..< at[0]]
    named = path[^1]
    text = path.mapIt(tokens[it].spelling(source)).join
  result.add ImportAll(
    module: prefix & text,
    item: text,
    line: tokens[named].line + 1,
    column: tokens[named].first - starts[tokens[named].line],
    names: names,
    first: tokens[named].after,
    after: tokens[indexes[at[0] + 2]].after,
  )


func importsAll*(source: string): seq[ImportAll] =
  ## Read each item of `import` or `from` statement that `{.all.}` opens: module it names, its
  ##   place, and span of `{.all.}`; bracket imports name each module apart.
  let
    tokens = source.tokens
    partners = tokens.partners
  var k = 0
  while k < tokens.len:
    let
      t = tokens[k]
      word = if t.kind == KindToken.Word: t.spelling(source) else: ""
    if word notin ["import", "from"] or (k > 0 and tokens[k - 1].line == t.line and
        tokens[k - 1].kind != KindToken.Comment):
      inc k
      continue

    # Statement runs on its line, and on through each bracket it opens.
    var
      last = k
      j = k + 1
    while j < tokens.len and tokens[j].line == tokens[last].line:
      if tokens[j].kind == KindToken.Open and partners[j] > j: j = partners[j]
      last = j
      inc j
    let body = toSeq(k + 1 .. last).filterIt(tokens[it].kind != KindToken.Comment)
    k = last + 1

    # Split into items at commas outside brackets; `from` holds one, before `import`.
    if word == "from":
      let to = body.filterIt(tokens[it].spelling(source) == "import")
      if to.len == 0: continue
      let
        at = body.find(to[0])
        names = body[at + 1 .. ^1].filterIt(tokens[it].kind in {KindToken.Word, KindToken.Quoted})
          .mapIt(tokens[it].spelling(source))
      result.add tokens.itemAll(body[0 ..< at], "", source, names)
      continue
    var
      pieces: seq[seq[int]] = @[@[]]
      depth = 0
    for m in body:
      if tokens[m].kind == KindToken.Open: inc depth
      if tokens[m].kind == KindToken.Close: dec depth
      if tokens[m].kind == KindToken.Comma and depth == 0: pieces.add @[]
      else: pieces[^1].add m
    for piece in pieces:
      let open = piece.filterIt(tokens[it].spelling(source) == "[")
      if open.len == 0:
        result.add tokens.itemAll(piece, "", source, @[])
        continue
      let
        at = piece.find(open[0])
        prefix = piece[0 ..< at].mapIt(tokens[it].spelling(source)).join
      var inner: seq[seq[int]] = @[@[]]
      for m in piece[at + 1 ..< piece.high]:
        if tokens[m].kind == KindToken.Comma: inner.add @[]
        else: inner[^1].add m
      for each in inner: result.add tokens.itemAll(each, prefix, source, @[])


func pathImported(importer, module: string; paths: openArray[string]): string =
  ## Read path, relative to package, of file of package import in `importer` names; empty where
  ##   it names none, as module of standard library or of other package.
  let path = slashed(normalizedPath(importer.parentDir / module & ".nim"), DirSep)
  if path in paths: path else: ""


func isTest(path: string): bool =
  ## Decide whether path, relative to package, lies under `tests` of package.
  path.split('/')[0] == FOLDER_TESTS


func comment(tokens: openArray[Token]; line: int; source: string): int =
  ## Read index of comment token trailing zero-based line after code; `-1` where none does.
  result = -1
  for k, t in tokens:
    if t.line > line: break
    if t.line == line and t.kind == KindToken.Comment and k > 0 and tokens[k - 1].line == line:
      return k


func pragmaHead(
  tokens: openArray[Token]; partners: openArray[int]; name: int; keyword, source: string
): tuple[open, insert, line: int] =
  ## Read index of `{.` opening pragma block of declaration whose name token is `name`, or byte
  ##   offset `{.used.}` opens at where none, with zero-based line of either: after name and its
  ##   placeholders, and for routine after parameters and return type too, before `=`, `:` of
  ##   binding, or line end.
  var k = name + 1
  result = (-1, tokens[name].after, tokens[name].line)
  while k < tokens.len:
    let s = tokens[k].spelling(source)
    if tokens[k].kind == KindToken.Comment or tokens[k].line > tokens[k - 1].line: break
    if s == "{.": return (k, -1, tokens[partners[k].max(k)].line)
    if s == "=" or (s == ":" and keyword notin KEYWORDS_ROUTINE): break
    if tokens[k].kind == KindToken.Open and partners[k] > k:
      if s == "(" and keyword notin KEYWORDS_ROUTINE: break
      k = partners[k]
    elif keyword notin KEYWORDS_ROUTINE: break
    (result.insert, result.line) = (tokens[k].after, tokens[k].line)
    inc k


func isMarked(
  tokens: openArray[Token]; partners: openArray[int]; private: Private; source: string
): bool =
  ## Decide whether pragma block of private symbol holds `used`.
  let head = pragmaHead(tokens, partners, private.index, private.keyword, source)
  if head.open < 0: return false
  for m in head.open .. partners[head.open]:
    if tokens[m].spelling(source) == PRAGMA_USED: return true


func named(siblings: openArray[string]): string =
  ## Render siblings for comment: `` `a.nim` ``, or `` `a.nim` and `b.nim` ``.
  let quoted = siblings.mapIt("`" & it & "`")
  if quoted.len < 2: quoted.join else: quoted[0 ..< ^1].join(", ") & " and " & quoted[^1]


func itemsOpened(files: openArray[(string, string)]): seq[(string, ImportAll, string)] =
  ## Read each item `{.all.}` opens in files of package, as importer, item, and module of package
  ##   it names; module that file of package includes is none, since it is no module.
  let paths = files.mapIt(it[0])
  for (path, text) in files:
    for item in text.importsAll:
      let module = path.pathImported(item.module, paths)
      if module.len > 0 and files.includer(module) == module: result.add (path, item, module)


func modulesOpened*(files: openArray[(string, string)]): seq[(string, string)] =
  ## Read each module of package that file of package imports with `{.all.}`, as importer and
  ##   module, each pair once: semantic pass asks each module in entry of its importer.
  ##   Files are path and text of every Nim file of package, paths relative to its root.
  for (importer, _, module) in files.itemsOpened:
    if (importer, module) notin result: result.add (importer, module)


func usesPackage*(
  files: openArray[(string, string)];
  answers: openArray[(string, Answer)];
  root: string;
  unused = initTable[string, seq[(int, string)]](),
): Table[string, Uses] =
  ## Read uses of each file of package from answers of semantic pass, by path relative to root.
  ##   Files are path and text of every Nim file of package; each answer is importer's, as path
  ##   of file whose entry it ran in, and its module's uses, every configuration counting. File
  ##   whose answer holds reason resolves nothing, and says why.
  ##   Own use reads from hints compiler gives of each module too (`unused`), by path, as line
  ##   and name of each symbol it hints is declared and never used: unmarked symbol of module
  ##   it holds that it hints none of is used there, as use pass cannot read, inside braces
  ##   strformat parses, counts. Module it lacks reads uses of pass alone.
  let
    paths = files.mapIt(it[0])
    opened = files.itemsOpened
  var texts = initTable[string, string]()
  for (path, text) in files: texts[path] = text

  # Files using each private symbol of each module opened, from every answer of module.
  var users = initTable[(string, (int, int)), HashSet[string]]()
  for module in opened.mapIt(it[2]).deduplicate:
    for private in texts[module].privatesTop:
      for (importer, answer) in answers:
        if answer.path != module: continue
        let
          lines = answer.usages.getOrDefault(private.site)
          defs = lines.filterIt(
            it.section == "def" and it.file.endsWith("/" & module) and it.line == private.line
          )
        if defs.len == 0: continue
        let key = (module, (private.line, private.column))
        discard users.hasKeyOrPut(key, initHashSet[string]())
        for line in lines:
          if line.section != "use" or line.name != defs[0].name or
              line.signature != defs[0].signature:
            continue
          let
            base = root.strip(leading = false, chars = {'/'}) & "/"
            file = if line.file.startsWith(base): line.file[base.len .. ^1] else: ""
          if file notin paths: continue
          let is_name = file == module and line.line == private.line and
            line.column >= private.column and line.column < private.column + private.name.len
          if not is_name: users[key].incl file

  # Facts of each module, and of each importer's items.
  for (importer, answer) in answers:
    if answer.reason.len > 0:
      result.mgetOrPut(importer, Uses()).reason = answer.reason
      result.mgetOrPut(answer.path, Uses()).reason = answer.reason
  for key, files_using in users.pairs:
    let (module, at) = key
    var use = UsePrivate(is_own: module in files_using)
    if module in unused:
      let
        source = texts[module]
        tokens = source.tokens
        partners = tokens.partners
      for private in source.privatesTop:
        if (private.line, private.column) != at: continue
        let name = private.name.strip(chars = {'`'})
        if not isMarked(tokens, partners, private, source) and
            (private.line, name) notin unused[module]:
          use.is_own = true
    for file in files_using:
      if file != module and not file.isTest: use.siblings.add file.extractFilename
    use.siblings = use.siblings.deduplicate.sorted
    result.mgetOrPut(module, Uses()).privates[at] = use
  for (importer, item, module) in opened:
    let privates = texts[module].privatesTop
    var is_reaching = false
    if item.names.len > 0:
      is_reaching = item.names.anyIt((let n = it; privates.anyIt(it.name == n)))
    else:
      for private in privates:
        let key = (module, (private.line, private.column))
        if key in users and importer in users[key]: is_reaching = true
    result.mgetOrPut(importer, Uses()).imports[(item.line, item.column)] = is_reaching


func marking(source: string; uses: Uses): seq[(Private, UsePrivate, bool, bool)] =
  ## Read each private symbol sibling reaches and its own module never uses, with whether it
  ##   carries `{.used.}`, and whether comment on line of its pragma names each sibling.
  if uses.reason.len > 0: return
  let
    tokens = source.tokens
    partners = tokens.partners
  for private in source.privatesTop:
    let at = (private.line, private.column)
    if at notin uses.privates: continue
    let use = uses.privates[at]
    if use.siblings.len == 0 or use.is_own: continue
    let
      head = pragmaHead(tokens, partners, private.index, private.keyword, source)
      is_marked = isMarked(tokens, partners, private, source)
      remark = tokens.comment(head.line, source)
      text = if remark < 0: "" else: tokens[remark].spelling(source)
    result.add (private, use, is_marked, use.siblings.allIt(it in text))


func checkMarkers*(path, source: string; uses: Uses): seq[Report] =
  ## Report each private symbol sibling reaches without its marker, and each `{.all.}` that
  ##   reaches none (STYLE.md §5).
  for (private, use, is_marked, is_named) in source.marking(uses):
    if is_marked and is_named: continue
    result.add initReport(
      path,
      private.line,
      Rule.UsedMarker,
      "Private symbol sibling " & use.siblings.named & " reaches carries `{.used.}` and " &
        "comment naming sibling; got `" & private.keyword & " " & private.name & "`.",
    )
  if uses.reason.len > 0: return
  for item in source.importsAll:
    if uses.imports.getOrDefault((item.line, item.column), true): continue
    result.add initReport(
      path,
      item.line,
      Rule.UsedMarker,
      "Import takes `{.all.}` only where it reaches private symbol; got `" & item.item &
        " {.all.}`.",
    )


func editsMarkers*(
  path, source: string; uses: Uses; fenced: openArray[int]; held: openArray[Edit] = []
): (seq[Edit], seq[Report]) =
  ## Read edits writing each marker and dropping each `{.all.}` check reports, and one report
  ##   per symbol or import. Fenced line (X.1), line holding plain comment, marker whose comment
  ##   names no sibling, line marker would widen past `LINE_MAX`, and span edit of other fixer
  ##   writes keep it for hand.
  let
    tokens = source.tokens
    partners = tokens.partners
    starts = source.lineStarts
    lines = source.split('\n')
  for (private, use, is_marked, is_named) in source.marking(uses):
    if is_marked or is_named: continue
    let
      head = pragmaHead(tokens, partners, private.index, private.keyword, source)
      line = head.line
    var edits: seq[Edit]
    if head.open < 0:
      edits.add Edit(first: head.insert, after: head.insert, text: " {." & PRAGMA_USED & ".}")
    else:
      # Put `used` among bare pragmas in dictionary order, before any taking argument.
      let close = partners[head.open]
      var
        items: seq[(int, int, string)]  # First and after byte, and name, of each item.
        m = head.open + 1
      while m < close:
        let t = tokens[m]
        if t.kind == KindToken.Comma:
          inc m
          continue
        if items.len == 0 or tokens[m - 1].kind == KindToken.Comma:
          items.add (t.first, t.after, t.spelling(source))
        let to = if t.kind == KindToken.Open and partners[m] > m: partners[m] else: m
        items[^1][1] = tokens[to].after
        m = to + 1
      let bare = toSeq(0 ..< items.len).filterIt(
        not source[items[it][0] ..< items[it][1]].contains({':', '('})
      )
      var at = items.len
      for i in 0 ..< items.len:
        if i notin bare or cmpIgnoreStyle(items[i][2], PRAGMA_USED) > 0:
          at = i
          break
      if at == items.len:
        let after = if items.len == 0: tokens[head.open].after else: items[^1][1]
        edits.add Edit(
          first: after, after: after, text: (if items.len == 0: "" else: ", ") & PRAGMA_USED
        )
      else: edits.add Edit(first: items[at][0], after: items[at][0], text: PRAGMA_USED & ", ")

    # Comment trails line; trailing doc moves to next line, one level in.
    let
      remark = tokens.comment(line, source)
      ending = toSeq(0 ..< tokens.len).filterIt(
        tokens[it].line == line and tokens[it].kind != KindToken.Comment
      ).mapIt(tokens[it].after).max
      text = "  # Used in " & use.siblings.named & "."
    if remark < 0: edits.add Edit(first: ending, after: ending, text: text)
    elif tokens[remark].spelling(source).startsWith("##"):
      edits.add Edit(
        first: ending,
        after: tokens[remark].after,
        text: text & "\n" & ' '.repeat(lines[line].indentWidth + 2) &
          tokens[remark].spelling(source),
      )
    else: continue
    let
      is_moved = remark >= 0
      written = source.applied(edits & @held).split('\n')
    if line in fenced or held.anyIt((let e = it; edits.anyIt(it.isTouching(e)))) or
        written[line].isWide or (is_moved and written[line + 1].isWide):
      continue
    result[0].add edits
    result[1].add initReport(path, private.line, Rule.UsedMarker)
  if uses.reason.len > 0: return
  for item in source.importsAll:
    if uses.imports.getOrDefault((item.line, item.column), true): continue
    let edit = Edit(first: item.first, after: item.after, text: "")
    if item.line - 1 in fenced or held.anyIt(it.isTouching(edit)): continue
    result[0].add edit
    result[1].add initReport(path, item.line, Rule.UsedMarker)
