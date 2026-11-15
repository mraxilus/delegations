## Hold that this project exports no type, constant or variable whose name `lojban_parser` exports.
##   Suites and tools import umbrella of parser beside modules of this project, and Nim refuses
##     bare name that two of their modules export: #878 found `HEADER` of `index.nim` and of
##     `nif.nim` of parser, refused at line 74 of `test_index.nim`.
##   Names of parser are read from each module that `export` statement of its umbrella lists;
##     lists of parser stay off its surface, so their names never meet these.
##   Names are read from source text, as each section of `const`, `let`, `var` or `type` at top
##     level declares them: one level in, or on line of its keyword; `nim jsondoc` of both
##     projects listed same names on 2026-11-11.
##     Cost: routines, fields and enum members go unread, as do declarations inside `when` and
##       second declaration on one line. Nim tells routines apart by their parameters; bare
##       member that meets type of parser reads as that type (`Hyphen`), so code qualifies it.
##   Nim compares names by first letter as written, then by rest with case and `_` ignored
##     (manual, Identifier equality), so each name is compared in that form.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[os, sequtils, strutils, tables, unittest]


const
  DIRECTORY_PROJECT = currentSourcePath().parentDir.parentDir.parentDir
    ## Folder of this project, two above `tests/suites/`.
  DIRECTORIES_PROJECT =
    [DIRECTORY_PROJECT / "src", DIRECTORY_PROJECT / "app", DIRECTORY_PROJECT / "tools"]
    ## Folders of modules that suites and tools import beside umbrella of parser.
  DIRECTORY_PARSER = DIRECTORY_PROJECT.parentDir / "lojban_parser" / "src"
    ## Folder of umbrella of `lojban_parser`, and of folder of its modules.
  PATH_UMBRELLA_PARSER = DIRECTORY_PARSER / "lojban_parser.nim"  ## Umbrella of parser.
  FLOOR_MODULES_PARSER = 14  ## Least modules umbrella of parser exports: 16 read on 2026-11-11.
  FLOOR_NAMES_PROJECT = 52  ## Least names read in this project: 58 read on 2026-11-11.
  FLOOR_NAMES_PARSER = 60  ## Least names read in parser: 67 read on 2026-11-11.
  KEYWORDS_SECTION = ["const", "let", "var", "type"]
    ## Keywords that open section of declarations at column 0.


func normalized(name: string): string =
  ## Spell name as Nim compares it: first letter as written, rest lowercase, `_` left out.
  name[0] & name[1 .. ^1].toLowerAscii.replace("_", "")


func namesExported(text: string): seq[string] =
  ## Read each exported name that section of `const`, `let`, `var` or `type` at top level of text
  ##   declares, one level in or on line of its keyword: type takes `=`, past any generic
  ##   parameters and pragma, and constant or variable takes `:` or `=`.
  var section = ""
  for line in text.splitLines:
    var body = line
    if line.len > 0 and line[0] notin {' ', '#'}:
      section = ""
      for keyword in KEYWORDS_SECTION:
        if line == keyword or line.startsWith(keyword & " "):
          section = keyword
          body = "  " & line[keyword.len .. ^1].strip
    if section.len == 0 or not body.startsWith("  ") or body.startsWith("   "): continue
    let declaration = body[2 .. ^1]
    if declaration.len == 0 or declaration[0] notin IdentStartChars: continue
    var at = 0
    while at < declaration.len and declaration[at] in IdentChars: inc at
    if at == declaration.len or declaration[at] != '*': continue
    var rest = declaration[at + 1 .. ^1].strip
    if section == "type" and rest.startsWith('['): rest = rest[rest.find(']') + 1 .. ^1].strip
    if rest.startsWith("{."): rest = rest[rest.find(".}") + 2 .. ^1].strip
    let is_assigned = rest.startsWith('=') and not rest.startsWith("==")
    if is_assigned or (section != "type" and rest.startsWith(':')):
      result.add declaration[0 ..< at]


func modulesExported(text: string): seq[string] =
  ## Read each module that `export` statement of umbrella text lists, over indented lines after it.
  var is_listing = false
  for line in text.splitLines:
    if line == "export": is_listing = true
    elif is_listing and line.startsWith("  "):
      for name in line.split(','):
        if name.strip.len > 0: result.add name.strip
    elif is_listing: break


proc pathsUnder(directories: openArray[string]): seq[string] =
  ## List each module under directories, at any depth.
  for directory in directories:
    for path in walkDirRec(directory):
      if path.endsWith(".nim"): result.add path


proc namesIn(paths: openArray[string]): Table[string, string] =
  ## Map each name that modules at paths export, as Nim compares it, to module and name.
  for path in paths:
    for name in readFile(path).namesExported:
      result[name.normalized] = path.relativePath(DIRECTORY_PROJECT.parentDir) & ": " & name



suite "Names apart from lojban_parser":
  test "Reader of names reads type, constant and variable that section declares":
    check namesExported("const\n  HEADER* = \"lojban_tagger index 1\"") == @["HEADER"]  # #878
    check namesExported("const\n  PLACES_SAME*: Places = [1, 2, 3, 4, 5]") ==
        @["PLACES_SAME"]  # typed, as `tanru_units.nim` of parser declares it
    check namesExported("const LIST_GISMU* = [") == @["LIST_GISMU"]  # on line of keyword
    check namesExported("type\n  RefusalTag* {.pure.} = enum\n    Empty") ==
        @["RefusalTag"]  # pragma, and member one level deeper
    check namesExported("type Pair*[T] = object") == @["Pair"]  # generic parameters
    check namesExported("type\n  Tag* = object\n    words*: seq[Word]") ==
        @["Tag"]  # field one level deeper
    check namesExported("func readTag*(text: string): ReadingTag =").len == 0  # routine
    check namesExported("const\n  ## HEADER* = \"\"").len == 0  # doc comment
    check namesExported("when defined(js):\n  const X* = 1").len == 0  # inside `when`, unread


  test "Reader of umbrella reads each module that its export statement lists":
    check modulesExported("import x\n\nexport\n  a, b,\n  c\n\n#[ Rest ]#\n") ==
        @["a", "b", "c"]  # statement over two lines, as umbrella of parser writes it
    check modulesExported("export a").len == 0  # statement on one line goes unread


  test "Names alike past first letter by case or underscore are one name":
    check "LETTERS".normalized == "Letters".normalized  # manual, Identifier equality
    check "HEADER_INDEX".normalized == "HEADERINDEX".normalized  # manual, `_` ignored
    check "HEADER".normalized != "hEADER".normalized  # manual, first letter as written


  test "No name that this project exports is one that lojban_parser exports":
    let
      modules = readFile(PATH_UMBRELLA_PARSER).modulesExported
      names = DIRECTORIES_PROJECT.pathsUnder.namesIn
      parser = modules.mapIt(DIRECTORY_PARSER / "lojban_parser" / it & ".nim").namesIn
    check modules.len >= FLOOR_MODULES_PARSER  # reader still reads umbrella of parser
    check names.len >= FLOOR_NAMES_PROJECT  # reader still reads this project
    check parser.len >= FLOOR_NAMES_PARSER  # reader still reads parser
    var shared: seq[string]
    for name, place in names:
      if name in parser: shared.add place & ", and " & parser[name]
    checkpoint shared.join("\n")
    check shared.len == 0  # #878, `HEADER` of `index.nim` and of `nif.nim`
