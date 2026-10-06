## Hold every import of knoller to standard library or module inside `src/`.
##   Import leaving `src/` reaches sibling project, which install of package lacks; import of
##   package needs requirement and lock, and `knoller.nimble` requires compiler alone.
##   Cost: statement is read by line, not by token: import opening line at column zero, or
##     after `when …:` there, outside triple-quoted string. Import inside routine is unread.

{.experimental: "strictFuncs".}

import std/[os, sequtils, strutils, unittest]


const
  DIRECTORY_SOURCE = currentSourcePath().parentDir.parentDir.parentDir / "src"
    ## Package sources every import stays inside.
  KEYWORDS_IMPORT = ["import ", "include ", "from "]  ## Words opening import statement.


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


func pathsOf(statement: string): seq[string] =
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
  for line in source.splitLines:
    if line.count("\"\"\"") mod 2 == 1: is_string = not is_string
    if statement.len > 0:
      statement.add " " & line.strip
      depth += line.count('[') - line.count(']')
    else:
      if is_string or line.len == 0 or line[0] == ' ': continue
      var text = line.strip
      if text.startsWith("when ") and ": import " in text: text = text[text.find(": ") + 2 .. ^1]
      if not KEYWORDS_IMPORT.anyIt(text.startsWith(it)): continue
      statement = text
      depth = text.count('[') - text.count(']')
    if depth > 0: continue
    result.add statement.pathsOf
    statement = ""



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


  test "import inside string or block names nothing":
    check pathsImported("const s = \"\"\"\nimport ./a\n\"\"\"\n").len == 0  # string
    check pathsImported("proc f() =\n  import ./a\n").len == 0  # indented, unread


  test "every import is standard library or module inside src":
    var count = 0
    for path in walkDirRec(DIRECTORY_SOURCE):
      if not path.endsWith(".nim"): continue
      for imported in readFile(path).pathsImported:
        inc count
        if imported.startsWith("std/"): continue
        let module = (path.parentDir / imported).normalizedPath
        check module.startsWith(DIRECTORY_SOURCE & "/")  # leaves package otherwise
        check fileExists(if module.endsWith(".nim"): module else: module & ".nim")
    check count > 0  # walk read imports, so check above is not vacuous
