## Replicate names check: declarations read, words split, case and reach of each kind held.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/[findings, names]


const
  SOURCE = """
## Module doc with `ctx` in it, which is comment and unread.

type
  Chiral*[T] = object
    ## Define pair.
    base*: T
    dir_hint: int  # Field coins `dir`.
  Space* {.pure.} = enum
    Base, Anti

const LUT_GRADE_BY_BASIS = block:
  var lut: array[2, int]
  lut

let
  ALGEBRA* = 4
  tmp_count = 2

proc getGrade*(m: int, buf: string): int =
  ## Doc mentions "args" in string, unread.
  let text = "tmp in string stays unread"
  for i, err in ["a", "b"]:
    discard
  m

func toJSON*(x: int; dest: var string) = discard

func constructTable(
  cayley: var int, factors: seq[int], as_exclusions = false
) {.compileTime.} = discard

type Algebra = object
  args*: seq[string]
"""
    ## Declaration of every kind, with words that break V.3, V.6, V.9 and V.10.
  BLOCKS = """
const TOP = 1
when defined(js):
  let JS_ONLY = 2
else:
  let NATIVE = 3
let
  SECTION = 4
  DEPENDENT = block:
    var inner = 5
    inner
  CALL = run(
    first = 1,
  )
  (LEFT, RIGHT) = (left_value, right_value)
static:
  let in_static = 6
proc run() =
  const local_constant = 7
  when true:
    let in_routine_when = 8
for each in [1]:
  let in_loop = 9
"""
    ## Binding under each kind of block; `when` and bare section open no scope.
  ENTRY_BINDS = """
proc main(): int =
  let inside = 1
  inside

when isMainModule:
  let verb = paramStr(1)
  for path in [verb]:
    let shown = path
  try: discard
  except CatchableError as error: echo error.msg
  proc helper() =
    let helper_local = 1
else:
  let SHARED = 1
"""
    ## Entry block binding by `let`, `for` and `except … as`, and routine declared inside it.
  ENTRY_CALLS = """
when isMainModule:
  doAssert paramCount() == 1, "Usage: marks <dir>; got `" & $paramCount() & "` arguments."
  buildPages(paramStr(1))
"""
    ## Entry block of plain calls, which binds nothing.
  CASES = """
type
  BasisDigits = distinct string
  Shape = object
    side_length: int
  Space = enum
    Base, Anti
const ALGEBRA_DEFAULT = 1
proc constructTable(count: int) =
  let metric_exomorphism = 1
"""
    ## Every kind in its own case (V.1, V.11).
  CASES_BROKEN = """
type
  basis_digits = distinct string
  Shape = object
    Width: int
  Space = enum
    base, Anti_Side
const lowerGlobal = 1
proc Construct_table(Count: int) =
  let Local_value = 1
"""
    ## Every kind in case of another kind.
  LETTERS = """
type T = int
const G = 9
let g = 9
proc f[A](m: int, N: int): int =
  let
    n = m
    M = n
  for i in 0 ..< N: discard
  M
"""
    ## One letter of each kind, either case.
  PLACEHOLDERS = """
type
  Chiral*[T] = object
  Pair[Key, V] = object
  Comparable = concept a, var B
proc scalar*[I: Basis | Grade](t: typedesc[I]): I = I.low
template borrow(T: typedesc) = discard
func sized[N: static int, Element](x: array[N, Element]) = discard
"""
    ## Placeholders in brackets and after `concept`, and parameters holding type.
  BOOLEANS = """
const IS_CONFORMAL = true
type Rule = object
  is_prose: bool
  gated: bool = false
proc setup() =
  var
    found_config = false
    done = false
  let
    ready: bool = check()
    inferred = check()
proc fetch(path: string, as_weight = false, quiet: bool): bool = true
func isMixed(m: int): bool = true
func mixed(m: int): bool = true
func advance(state: var int): bool = true
func contains(s: Set, x: int): bool = true
"""
    ## Boolean shown by type or literal, of each kind, and routines returning `bool`.
  NOTATION = """
const 𝟎* = 0
let 𝐦 = 1
var
  𝐧 = 2
  𝐍 = 3
type Plane = object
  𝐀: float
proc wedge(𝐮: int): int =
  let 𝐌 = 𝐮
  𝐌
"""
    ## Source's notation at module scope, mutable and not, and as field, parameter and local.
  OPERATORS = """
func `∧`*(m, n: Multivector): Multivector = m
func `[]`*(m: var Multivector, b: Basis): var float = m.elements[b]
template m: untyped = MULTIVECTORS(i)
type State {.pure.} = enum Code, Str_Raw
"""
    ## Operators, routine without parameters, and enum on one line.


func names(source: string): seq[string] =
  ## Read declared names of source, in order.
  source.declarations.mapIt(it.name)


func messages(found: seq[Finding]): seq[string] =
  ## Read messages of findings.
  found.mapIt(it.message)


func breaches(source: string): seq[string] =
  ## Read messages names check reports on source, with no exemption.
  checkNames("x.nim", source, []).messages


func reachIn(source, name: string): Reach =
  ## Read reach of first declaration of name in source.
  source.declarations.filterIt(it.name == name)[0].reach


suite "Names":
  test "comments and strings are blanked, newlines kept":
    let code = ("let a = \"# not comment\" # comment\nlet b = r\"raw \"\" quote\" #[ block\n" &
      "]# c").codeOnly
    check code.splitLines.len == 3
    check "comment" notin code and "quote" notin code and "block" notin code
    check "let a =" in code and "let b =" in code and code.splitLines[2].strip == "c"

  test "declarations of every kind are read":
    let found = SOURCE.names
    for name in ["Chiral", "T", "base", "dir_hint", "Space", "Base", "Anti", "LUT_GRADE_BY_BASIS",
                 "lut", "ALGEBRA", "tmp_count", "getGrade", "m", "buf", "text", "i", "err",
                 "toJSON", "x", "dest", "constructTable", "cayley", "factors", "as_exclusions",
                 "Algebra", "args"]:
      check name in found
    check "ctx" notin found  # comment word
    let kinds = SOURCE.declarations
    check kinds.filterIt(it.name == "ALGEBRA")[0].reach == Reach.Global
    check kinds.filterIt(it.name == "text")[0].reach == Reach.Local
    check kinds.filterIt(it.name == "buf")[0].kind == NameKind.Parameter
    check kinds.filterIt(it.name == "args")[0].kind == NameKind.Field
    check kinds.filterIt(it.name == "Anti")[0].kind == NameKind.Member  # V.11
    check kinds.filterIt(it.name == "T")[0].kind == NameKind.Placeholder  # V.12

  test "words split at underscore and case change":
    check "lut_grade_by_basis".words == @["lut", "grade", "by", "basis"]
    check "wedgeAnti".words == @["wedge", "Anti"]
    check "JSONData".words == @["JSON", "Data"]
    check "toJSON".words == @["to", "JSON"]
    check "rga4d".words == @["rga4d"]
    check "DIRECTORY_SDL3".words == @["DIRECTORY", "SDL3"]

  test "acronyms are capital runs inside camel or Pascal names":
    check "toJSON".acronyms == @["JSON"]
    check "SDL3Window".acronyms == @["SDL3"]
    check "Chiral".acronyms.len == 0 and "isMixed".acronyms.len == 0
    check "DIRECTORY_SDL3".acronyms.len == 0  # screaming holds by reading
    check "rga_visualiser".acronyms.len == 0

  test "glossary gives exemptions from standards spans and terms":
    const glossary = "# d\n\n## Standards\n\n- **SI**, BIPM, 9th: `s` and `m` (Table 2), so " &
      "`ms`.\n- **Acronyms**, Architect: `3D`, `JSON` and `fps`.\n\n## Language\n\n" &
      "**Measurand**:\nOne.\n"
    let exempt = glossary.glossaryExemptions
    for w in ["s", "m", "ms", "3D", "JSON", "fps", "Measurand"]: check w in exempt
    check "BIPM" notin exempt  # owner, not symbol

  test "abbreviation, acronym, verb, lookup and global findings":
    let found = checkNames("x.nim", SOURCE, ["JSON"]).messages
    check found.anyIt("write `directory` (V.6); got `dir_hint`" in it)
    check found.anyIt("write `temporary` (V.6); got `tmp_count`" in it)
    check found.anyIt("got `buf`" in it) and found.anyIt("got `err`" in it)
    check found.anyIt("got `dest`" in it) and found.anyIt("got `args`" in it)
    check found.anyIt("(V.3); got `getGrade`" in it)
    check found.anyIt("(V.10); got `ALGEBRA`" in it)  # shares word with type Algebra
    check not found.anyIt("JSON" in it)  # exempt
    check not found.anyIt("`lut`" in it)  # jargon
    check not found.anyIt("constructTable" in it)
    check checkNames("x.nim", SOURCE, []).messages.anyIt("got `JSON` in `toJSON`" in it)
    check "const LUT_GRADE = 1\n".breaches == @[
      "Lookup table reads `lut_<value>_by_<key>` (V.5); got `LUT_GRADE`."]
    check "const LUT_GRADE_BY_BASIS = 1\n".breaches.len == 0
    check "proc get*(x: int) = x\n".breaches.len == 0  # one word is noun

  test "foreign binding keeps library's name, and its parameters are read":
    const foreign = "proc getError*(): cstring {.importc: \"SDL_GetError\".}\n" &
      "proc glGetString*(name: GLenum, buf: pointer) {.importc, dynlib: \"GL\".}\n" &
      "proc getShaderiv*(shader: Uint)\n  {.importc: \"glGetShaderiv\", header: H.}\n"
    let found = foreign.breaches
    check not found.anyIt("getError" in it) and not found.anyIt("glGetString" in it)
    check not found.anyIt("getShaderiv" in it)  # pragma on its own line
    check found.anyIt("got `buf`" in it)  # parameter is ours
    check "getError" notin foreign.names and "buf" in foreign.names

  test "reach is global under blocks opening no scope, and local under any other":
    for name in ["TOP", "JS_ONLY", "NATIVE", "SECTION", "DEPENDENT", "CALL", "LEFT", "RIGHT"]:
      check BLOCKS.reachIn(name) == Reach.Global  # V.1
    for name in ["inner", "in_static", "local_constant", "in_routine_when", "each", "in_loop"]:
      check BLOCKS.reachIn(name) == Reach.Local  # V.1
    check "first" notin BLOCKS.names  # argument continuing value is no binding
    check "right_value" notin BLOCKS.names  # value side is never name
    check BLOCKS.breaches.len == 0  # V.1

  test "entry block holds no binding, and block of calls passes":
    let found = ENTRY_BINDS.breaches
    for name in ["verb", "path", "shown", "error"]:
      check ENTRY_BINDS.reachIn(name) == Reach.Entry  # V.10
      check found.filterIt(it.endsWith("got `" & name & "`.")) == @[
        "Entry block holds no binding; move code that binds into `proc main` (V.10); got `" &
          name & "`."]  # V.10, one finding and no case finding
    check ENTRY_BINDS.reachIn("inside") == Reach.Local  # V.10, routine is local
    check ENTRY_BINDS.reachIn("helper_local") == Reach.Local  # V.10, routine inside block
    check ENTRY_BINDS.reachIn("SHARED") == Reach.Global  # V.10, other branch of `when`
    check found.len == 4  # V.10
    check ENTRY_CALLS.breaches.len == 0  # V.10
    check "when isMainModule:\n  quit main()\n".breaches.len == 0  # V.10

  test "case follows kind of name":
    check CASES.breaches.len == 0  # V.1, V.11
    let found = CASES_BROKEN.breaches
    check "Type is `PascalCase` (V.1); got `basis_digits`." in found
    check "Field is `snake_case` (V.1); got `Width`." in found
    check "Member is `PascalCase` (V.11); got `base`." in found
    check "Member is `PascalCase` (V.11); got `Anti_Side`." in found
    check "Global is `SCREAMING_SNAKE_CASE` (V.1); got `lowerGlobal`." in found
    check "Routine is `lowerCamelCase` (V.1); got `Construct_table`." in found
    check "Parameter is `snake_case` (V.1); got `Count`." in found
    check "Local is `snake_case` (V.1); got `Local_value`." in found
    check found.len == 8  # V.1, V.11
    check "Member is `PascalCase` (V.11); got `Str_Raw`." in OPERATORS.breaches

  test "one letter fits by its own case, and capital local is finding":
    # Architect's ruling: plain ASCII is no notation, so `N` and `M` take local case.
    check LETTERS.breaches == @[
      "Global is `SCREAMING_SNAKE_CASE` (V.1); got `g`.",
      "Parameter is `snake_case` (V.1); got `N`.",
      "Local is `snake_case` (V.1); got `M`.",
    ]  # V.1, V.6

  test "placeholder is one capital letter, and parameter holding type is snake":
    # Architect's ruling: `typedesc` parameter is parameter (V.1), never placeholder (V.12).
    check PLACEHOLDERS.breaches == @[
      "Placeholder is one capital letter (V.12); got `Key`.",
      "Placeholder is one capital letter (V.12); got `a`.",
      "Parameter is `snake_case` (V.1); got `T`.",
      "Placeholder is one capital letter (V.12); got `Element`.",
    ]  # V.1, V.12
    check PLACEHOLDERS.declarations.filterIt(it.name == "t")[0].kind == NameKind.Parameter

  test "boolean is proposition or mode, and predicate func is `is…`":
    let found = BOOLEANS.breaches
    for name in ["gated", "done", "ready", "quiet"]:
      check "Boolean opens `is_`, `as_`, `should_`, `found_` or `has_` (V.4); got `" & name &
        "`." in found  # V.4
    check "Predicate `func` is `is…` in camel case (V.4); got `mixed`." in found
    check found.len == 5  # V.4: `proc`, `func` writing `var`, and `contains` are unread
    check "inferred" in BOOLEANS.names and not found.anyIt("inferred" in it)  # value unread
    check BOOLEAN_PREFIXES.allIt(("proc run() =\n  let " & it & "_set = true\n").breaches.len == 0)

  test "notation holds over case at any scope, but at module scope only for immutable global":
    # Variable takes source's notation (`𝐀`, `𝐮`, `𝐌` pass); mutable global never does.
    check NOTATION.breaches == @[
      "Notation holds over case only for immutable global (III.5); got `𝐧`.",
      "Notation holds over case only for immutable global (III.5); got `𝐍`.",
    ]  # III.5
    check "𝐦".isNotation and not "m".isNotation  # III.5
    check "𝐌".isCased(Casing.Screaming) and not "𝐌".isCased(Casing.Snake)  # III.5
    check "𝐮".isCased(Casing.Snake) and "𝟎".isCased(Casing.Screaming)  # III.5
    check "Δt".isCased(Casing.Pascal) and not "δt".isCased(Casing.Pascal)  # III.5

  test "operator is backticked and never read as name":
    let found = OPERATORS.names
    check "∧" notin found and "[]" notin found  # III.5
    check "m" in found and "n" in found and "b" in found  # parameters of operator are read
    check "i" notin found  # call in body of routine without parameters is no parameter
    check "Code" in found and "Str_Raw" in found  # V.11, enum on one line

  test "casing follows kind and reach":
    check Declared(kind: NameKind.Binding, reach: Reach.Global).casingOf == Casing.Screaming
    check Declared(kind: NameKind.Binding, reach: Reach.Local).casingOf == Casing.Snake
    check Declared(kind: NameKind.Member).casingOf == Casing.Pascal  # V.11
    check Declared(kind: NameKind.Placeholder).casingOf == Casing.Letter  # V.12
    check "isMixed".isCased(Casing.Camel) and not "is_mixed".isCased(Casing.Camel)  # V.1
    check "E1".isCased(Casing.Pascal) and "x2".isCased(Casing.Snake)  # V.1, digits carry none
