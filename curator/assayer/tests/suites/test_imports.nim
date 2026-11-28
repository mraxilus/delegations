## Hold every import of assayer to standard library, module of project, or package that
##   `assayer.nimble` requires, which Atlas restores from `atlas.lock` (PROVENANCE.md, Package).
##   Import leaving project by path reaches sibling project, which install of package lacks, so
##   assayer would build from checkout of this repository alone.
##   Copy of `curator/knoller/tests/suites/test_imports.nim`, with packages of nimble file and
##     files under `tests/` added; fix to one is finished only when other is checked
##     (Article II.9).
##   Cost: statement is read by line, not by token: import opening line at column zero, after
##     `when …:` there, or two spaces deep in block of such `when`, outside triple-quoted string.
##     Import inside routine is unread.

{.experimental: "strictFuncs".}

import std/[os, sequtils, strutils, unittest]


const  # TODO: Document.
  DIRECTORY_PROJECT = currentSourcePath().parentDir.parentDir.parentDir
    ## Project whose nimble file names each package it requires.
  DIRECTORY_SOURCE = DIRECTORY_PROJECT / "src"  ## Package sources each import of `src/` stays in.
  BOUNDS = [(DIRECTORY_SOURCE, DIRECTORY_SOURCE), (DIRECTORY_PROJECT / "tests", DIRECTORY_PROJECT)]
    ## Each folder read, and folder its imports by path stay inside: tests reach `src/` too.
  PREFIX_PATH_DEPENDENCY = "--path:\"dependencies/"
    ## Opening of each search path of `nim.cfg`, which reads clone that Atlas restores from lock.
  KEYWORDS_IMPORT = ["import ", "include ", "from "]  ## Words opening import statement.
  PREFIX_REQUIRES = "requires \""  ## Opening of requirement line of nimble file.
  CHARS_NAME = {'a' .. 'z', 'A' .. 'Z', '0' .. '9', '_'}  ## Characters of name of package.


func splitTop(text: string): seq[string] =
  ## Split text at each comma outside brackets.
  var
    depth = 0
    start = 0
  for i, c in text:
    if c == '[': inc depth
    elif c == ']': dec depth
    elif c == ',' and depth == 0:
      result.add text[start ..< i]
      start = i + 1
  result.add text[start .. ^1]


func paths(statement: string): seq[string] =
  ## Read each module path one import statement names, bracket group expanded, pragma dropped.
  var text = statement
  while "{." in text:
    let open = text.find("{.")
    text = text[0 ..< open] & text[text.find(".}", open) + 2 .. ^1]
  if text.startsWith("from "):
    return @[text["from ".len ..< text.find(" import ")].strip]
  text = text[text.find(' ') + 1 .. ^1]
  for piece in text.splitTop:
    var item = piece.strip
    for word in [" except ", " as "]:
      if word in item: item = item[0 ..< item.find(word)]
    if item.len == 0: continue
    if '[' notin item:
      result.add item.strip(chars = {'"'})
      continue
    let prefix = item[0 ..< item.find('[')]
    for inner in item[item.find('[') + 1 ..< item.rfind(']')].splitTop:
      if inner.strip.len > 0: result.add prefix & inner.strip


func pathsImported(source: string): seq[string] =
  ## Read each module path source imports or includes, in order.
  var
    statement = ""
    depth = 0
    is_string = false
    is_when = false  # inside block of `when` at column zero, whose imports are module's
  for line in source.splitLines:
    if line.count("\"\"\"") mod 2 == 1: is_string = not is_string
    if statement.len > 0:
      statement.add " " & line.strip
      depth += line.count('[') - line.count(']')
    else:
      if is_string or line.len == 0: continue
      let indent = line.len - line.strip(trailing = false).len
      if indent == 0: is_when = line.startsWith("when ") and line.endsWith(":")
      elif not is_when or indent != 2: continue
      var text = line.strip
      if text.startsWith("when ") and ": import " in text: text = text[text.find(": ") + 2 .. ^1]
      if not KEYWORDS_IMPORT.anyIt(text.startsWith(it)): continue
      statement = text
      depth = text.count('[') - text.count(']')
    if depth > 0: continue
    result.add statement.paths
    statement = ""



func packagesRequired(nimble: string): seq[string] =
  ## Read name of each package nimble file requires, compiler left out.
  for line in nimble.splitLines:
    if not line.startsWith(PREFIX_REQUIRES): continue
    var name = ""
    for c in line[PREFIX_REQUIRES.len .. ^1]:
      if c notin CHARS_NAME: break
      name.add c
    if name.len > 0 and name != "nim": result.add name


func isPackage(imported: string; packages: openArray[string]): bool =
  ## Decide whether import names module of standard library or of package nimble file requires.
  imported.startsWith("std/") or packages.anyIt(imported == it or imported.startsWith(it & "/"))


func isInside(path, imported, bound: string): bool =
  ## Decide whether import by path that file at path makes stays inside bound.
  (path.parentDir / imported).normalizedPath.startsWith(bound & DirSep)



suite "Imports":
  test "import paths read from statement, bracket group expanded":
    check pathsImported("import std/[os, strutils]\n") == @["std/os", "std/strutils"]
    check pathsImported("import ./[a {.all.}, b]\n") == @["./a", "./b"]  # pragma dropped
    check pathsImported("import ./[\n  a,\n  b,\n]\n") == @["./a", "./b"]  # spread group
    check pathsImported("from ./a import b, c\n") == @["./a"]
    check pathsImported("import std/os except getEnv\n") == @["std/os"]
    check pathsImported("include \"suites.nim\"\n") == @["suites.nim"]
    check pathsImported("when compileOption(\"profiler\"): import std/nimprof\n") ==
      @["std/nimprof"]
    check pathsImported("when compileOption(\"profiler\"):\n  import std/nimprof\n") ==
      @["std/nimprof"]  # block of `when` at module level


  test "import inside string or block names nothing":
    check pathsImported("const s = \"\"\"\nimport ./a\n\"\"\"\n").len == 0  # string
    check pathsImported("proc f() =\n  import ./a\n").len == 0  # indented, unread
    check pathsImported("when x:\n  proc f() =\n    import ./a\n").len == 0  # routine in block


  test "requirement names package, compiler and comment left out":
    check packagesRequired("requires \"nim == 2.4.0\"\nrequires \"knoller#1a2b3c4\"\n") ==
      @["knoller"]  # name ends at `#` of its commit
    check packagesRequired("#   requires \"knoller\"\n").len == 0  # comment requires nothing
    check packagesRequired("requires \"Pga_lib2 >= 1.0\"\n") == @["Pga_lib2"]  # each name char
    check "knoller/compilers".isPackage(["knoller"])  # module of package
    check "knoller".isPackage(["knoller"])  # package itself
    check not "knollerx/a".isPackage(["knoller"])  # other package that shares opening
    check not "yaml/x".isPackage(["knoller"])  # package nimble file does not require
    check not "../../../knoller/src/knoller/compilers".isPackage(["knoller"])  # path, as before


  test "import by path of tests may reach src, and never leave project":
    check BOUNDS[^1] == (DIRECTORY_PROJECT / "tests", DIRECTORY_PROJECT)  # tests bound by project
    let suite = DIRECTORY_PROJECT / "tests" / "suites" / "test_command.nim"
    check suite.isInside("../../src/assayer/command", BOUNDS[^1][1])  # module of project
    check not suite.isInside("../../../knoller/src/knoller/compilers", BOUNDS[^1][1])  # as found


  test "every import is standard library, module of project, or package it requires":
    let packages = readFile(DIRECTORY_PROJECT / "assayer.nimble").packagesRequired
    check packages == @["knoller"]  # PROVENANCE.md, Package
    var count = 0
    for (directory, bound) in BOUNDS:
      for path in walkDirRec(directory):
        if not path.endsWith(".nim"): continue
        for imported in readFile(path).pathsImported:
          inc count
          if imported.isPackage(packages): continue
          check path.isInside(imported, bound)  # leaves package otherwise
          let module = (path.parentDir / imported).normalizedPath
          check fileExists(if module.endsWith(".nim"): module else: module & ".nim")
    check count > 0  # walk read imports, so check above is not vacuous


  test "each search path of `nim.cfg` reads clone that Atlas restores":
    var count = 0
    for line in readFile(DIRECTORY_PROJECT / "nim.cfg").splitLines:
      if not line.startsWith("--path:"): continue
      inc count
      check line.startsWith(PREFIX_PATH_DEPENDENCY)  # path into checkout would build from it
    check count > 0  # file names its paths, so check above is not vacuous
