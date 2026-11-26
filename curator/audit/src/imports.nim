## Read each module Nim source names; hold each import by path inside its project, and each
##   driver clear of package (D1 of #927).
##   Reader is one: `plan.nim` reads importers of each folder from it (`importersByFolder`), and
##     both checks here read same modules, so plan and checks never disagree on what source names.
##   Statement opens its line, past `when` guard on that line, with `import`, `include` or `from`,
##     and runs on while bracket stays open, line ends in comma, or keyword stands alone. Module
##     is each word between commas, or prefix before bracket joined to each member; quotes,
##     pragma, `as` alias and names after `except` drop, and first word alone names module of
##     `from`. Text after `#` is comment, and line opening inside long string is data.
##   Path resolves against folder of source, as compiler tries it before any search path. Bare
##     name resolves there too, so only path opening `./` or `../` leaves its folder.
##
##   Import by path from one project into other is finding at its line, naming project it reaches:
##     that project is package that `atlas.lock` pins (CONTRIBUTOR.md, Dependencies). Importer
##     by path compiles whatever checkout holds, and move of either folder breaks it. Path into
##     clone under `dependencies/` stays inside its own project, so it passes.
##   Checker is one exception: root `koch.nim`, audit and knoller build as one program from each
##     checkout, and audit imports knoller by path. Import among them stands, and import from
##     them into any other project is finding, as any other.
##
##   Driver compiles before any restore, since `koch list-packages` runs its `system` verb before
##     runner restores `dependencies/` (#934). So each import of driver is followed through modules
##     of its own project, and first package it reaches is finding at line of driver that leads
##     there, naming package and module that names it.
##     Module opening `std/` is standard library, as STYLE.md §5 writes it. Module of project is
##       Nim file tree holds inside project, resolved from folder of module naming it. Rest is
##       package: name folder lacks, which compiler finds on search path of `nim.cfg`; `pkg/`
##       name; or path to file tree lacks, as clone under `dependencies/` or file of `build/`.
##     Module of other project reached by path is read no further: check of paths reports it.
##
##   Rejected: tokens of knoller for reader, which took 1.5 s over each Nim file of tree, built as
##     koch builds, against 0.18 s for check of paths by line, measured 2026-11-15. Line opening
##     with no keyword and no guard leaves before any split, which cut that check from 0.45 s.
##   Cost: block comment, and `"""` inside one-line string, mislead reader; path macro builds
##     names nothing.
##   Cost: standard module written without `std/` reads as package, as knoller ranks it
##     (`rankImport`); each driver of tree writes `std/`, read 2026-11-15.
##   Cost: `--path` of `nim.cfg` into other project is unread; none stands in tree, read
##     2026-11-15. NimScript and nimble files are unread, as plan reads modules alone.

{.experimental: "strictFuncs".}

import std/[algorithm, options, sets, strutils, tables]
import ../../knoller/src/knoller
import ./[findings, layout, projects, toolchain]


type Import* = object  ## Define one module statement of Nim source names, and line naming it.
  line*: int  ## One-based line holding path of module: that of prefix, for member of bracket.
  target*: string  ## Module as written, as `../src/x`, `std/os` or `knoller`; quotes dropped.


const
  KEYWORDS_IMPORT = ["import", "include", "from"]  ## Words opening statement that names modules.
  PREFIX_STANDARD = "std/"  ## Opening of module of standard library, as STYLE.md §5 writes it.
  STRING_LONG = "\"\"\""  ## Delimiter of string spanning lines.
  MARKS_ALONE = {',', '[', ']'}  ## Characters of statement that stand as words of their own.
  LETTERS_OPENING = {'f', 'i', 'w'}  ## First letters of each keyword and of `when` guard.
  PROJECTS_CHECKER* = [DIRECTORY_DRIVER, DIRECTORY_KNOLLER]
    ## Projects building with `koch.nim` as one program from each checkout, so import by path
    ##   among them stands (D1 of #927).


func wordsLine(text: string, line: int): seq[(string, int)] =
  ## Split text of statement on one line into words, each with that line: `,`, `[` and `]` stand
  ##   alone, quoted text is one word without its quotes, and pragma drops.
  var at = 0
  while at < text.len:
    if text[at] in Whitespace: inc at
    elif text[at] in MARKS_ALONE:
      result.add ($text[at], line)
      inc at
    elif text[at] == '"':
      let
        close = text.find('"', at + 1)
        stop = if close < 0: text.len else: close
      result.add (text[at + 1 ..< stop], line)
      at = stop + 1
    elif text.continuesWith("{.", at):
      let close = text.find(".}", at + 2)
      at = if close < 0: text.len else: close + 2
    else:
      var stop = at
      while stop < text.len and text[stop] notin Whitespace + MARKS_ALONE + {'"'} and
          not text.continuesWith("{.", stop):
        inc stop
      result.add (text[at ..< stop], line)
      at = stop


func modules(keyword: string, words: openArray[(string, int)]): seq[Import] =
  ## Read each module statement names from its words: of `from`, first word alone; else each word
  ##   between commas, or prefix before bracket joined to each member, up to `except`.
  if keyword == "from":
    if words.len > 0: result.add Import(line: words[0][1], target: words[0][0])
    return
  var
    prefix = ("", 0)  # Path before bracket open, with its line.
    is_inside = false  # Bracket stands open.
    is_wanted = true  # Next word names module: after keyword, comma or open bracket.
  for k in 0 ..< words.len:
    let (word, line) = words[k]
    case word
    of "[": (is_inside, is_wanted) = (true, true)
    of "]": (is_inside, is_wanted) = (false, false)
    of ",": is_wanted = true
    of "except":
      if not is_inside: return
    else:
      if not is_wanted: continue
      is_wanted = false
      if is_inside: result.add Import(line: prefix[1], target: prefix[0] & word)
      elif k + 1 < words.len and words[k + 1][0] == "[": prefix = (word, line)
      else: result.add Import(line: line, target: word)


func imports*(source: string): seq[Import] =
  ## Read each module `import`, `include` or `from` of Nim source names, in order, each with line
  ##   holding its path.
  var
    keyword = ""  # Keyword of statement still open; empty where none is.
    words: seq[(string, int)]  # Words of that statement, each with its line.
    depth = 0  # Brackets that statement holds open.
    is_string = false  # Next line opens inside long string.
    line = 0
  for text in source.splitLines:
    inc line
    let is_data = is_string
    if '"' in text and text.count(STRING_LONG) mod 2 == 1: is_string = not is_string
    if is_data: continue
    if keyword.len == 0:
      # Line opening with no keyword and no guard leaves before any split, as most lines do.
      var lead = 0
      while lead < text.len and text[lead] in Whitespace: inc lead
      if lead == text.len or text[lead] notin LETTERS_OPENING: continue
    var s = text.split('#')[0].strip
    if keyword.len == 0:
      if s.startsWith("when ") and ':' in s: s = s[s.find(':') + 1 .. ^1].strip
      let first = s.split(Whitespace)[0]
      if first notin KEYWORDS_IMPORT: continue
      (keyword, words, depth) = (first, newSeq[(string, int)](), 0)
      s = s[first.len .. ^1].strip
    words.add wordsLine(s, line)
    depth += s.count('[') - s.count(']')
    if depth > 0 or s.endsWith(",") or words.len == 0: continue
    result.add modules(keyword, words)
    keyword = ""


func isRelative*(target: string): bool =
  ## Decide whether module path leaves folder of source by its own text: it opens `./` or `../`.
  target.startsWith("./") or target.startsWith("../")


func resolve*(folder, target: string): string =
  ## Resolve module path against folder holding source, repository-relative, as compiler tries it
  ##   before any search path; empty where path climbs past root.
  var parts = if folder.len == 0: newSeq[string]() else: folder.split('/')
  for part in target.split('/'):
    if part == "..":
      if parts.len == 0: return ""
      parts.setLen(parts.len - 1)
    elif part.len > 0 and part != ".": parts.add part
  parts.join("/")


func folderHolding(path: string): string =
  ## Read folder holding path; empty at root.
  let cut = path.rfind('/')
  if cut < 0: "" else: path[0 ..< cut]


func checkImportsProject*(tree: Tree): seq[Finding] =
  ## Report each line of Nim source of project whose import by path reaches into other project,
  ##   once for each project it reaches; import among projects of checker stands.
  for e in tree:
    if not e.path.endsWith(EXTENSIONS[Dialect.Module]): continue
    let importer = e.path.split('/').directoryProject
    if importer.len == 0: continue
    var named: seq[(int, string)]  # Line and project of each finding of source.
    for one in e.content.imports:
      if not one.target.isRelative: continue
      let path = resolve(e.path.folderHolding, one.target)
      if path.len == 0: continue
      let imported = path.split('/').directoryProject
      if imported.len == 0 or imported == importer or (one.line, imported) in named: continue
      if importer in PROJECTS_CHECKER and imported in PROJECTS_CHECKER: continue
      named.add (one.line, imported)
      result.add finding(
        e.path,
        one.line,
        Check.ImportProject,
        "Import by path reaches into other project (CONTRIBUTOR.md, Dependencies); got `" &
          imported & "`.",
        help = "require it as package that `atlas.lock` pins",
      )


func checkImportsDriver*(tree: Tree): seq[Finding] =
  ## Report each import of driver of project that reaches package, itself or through modules of
  ##   its project, at line of driver that leads there.

  func reached(
    modules: Table[string, string]; directory, driver: string; first: Import
  ): Option[(string, string)] =
    ## Follow import through modules of project, depth first in order source names them; read
    ##   first package reached, and path of module naming it inside project; none where none is.
    var
      stack = @[(driver, first)]
      seen: HashSet[string]
    while stack.len > 0:
      let (path, one) = stack.pop
      if one.target.startsWith(PREFIX_STANDARD): continue
      var module = resolve(path.folderHolding, one.target)
      if not module.endsWith(EXTENSIONS[Dialect.Module]): module.add EXTENSIONS[Dialect.Module]
      if module notin modules: return some((one.target, path[directory.len + 1 .. ^1]))
      if not module.startsWith(directory & "/") or module in seen: continue
      seen.incl module
      for next in modules[module].imports.reversed: stack.add (module, next)

  var modules: Table[string, string]  # Text of each Nim source of tree, by path.
  for e in tree:
    if e.path.endsWith(EXTENSIONS[Dialect.Module]): modules[e.path] = e.content
  for directory in tree.directoriesProject:
    let driver = directory & "/" & FILE_DRIVER
    if driver notin modules: continue
    for one in modules[driver].imports:
      let found = reached(modules, directory, driver, one)
      if found.isNone: continue
      result.add finding(
        driver,
        one.line,
        Check.ImportDriver,
        "Driver imports no package, itself or through module of its project, since `koch " &
          "list-packages` runs it before any restore (CONTRIBUTOR.md, Dependencies); got `" &
          found.get[0] & "` in `" & found.get[1] & "`.",
      )
