## Replicate names check of `names.nim` header: words split, case and reach of each kind held,
##   and each finding named by its rule.
##   Text koch prints, article included, is held in `curator/audit/tests/suites/test_names.nim`.
##   Renames each case and abbreviation asks, and acronyms of name, are held here too.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/knoller/[declared, entry, names, reports, rules]
import ./sources


const
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
    ##   Copy of same fixture in `curator/audit/tests/suites/test_names.nim`, whose renames read
    ##     it; fix to one is finished only when other is checked.
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


func names(source: string): seq[string] =
  ## Read declared names of source, in order.
  source.declarations.mapIt(it.name)


func breaches(source: string): seq[(Rule, string)] =
  ## Read rule and message of each finding names check reports on source, with no exemption.
  checkNames("x.nim", source, []).mapIt (it.rule, it.message)


func messages(source: string): seq[string] =
  ## Read message of each finding names check reports on source, with no exemption.
  checkNames("x.nim", source, []).mapIt(it.message)


func reachIn(source, name: string): Reach =
  ## Read reach of first declaration of name in source.
  source.declarations.filterIt(it.name == name)[0].reach



suite "Names":
  test "words split at underscore and case change":
    check "lut_grade_by_basis".words == @["lut", "grade", "by", "basis"]
    check "wedgeAnti".words == @["wedge", "Anti"]
    check "JSONData".words == @["JSON", "Data"]
    check "toJSON".words == @["to", "JSON"]
    check "rga4d".words == @["rga4d"]
    check "DIRECTORY_SDL3".words == @["DIRECTORY", "SDL3"]


  test "V.6 V.3 V.5 V.10 abbreviation, verb, lookup and global findings, and no acronym":
    let found = checkNames("x.nim", SOURCE, []).mapIt((it.rule, it.message))
    check (Rule.Abbreviation, "Name coins abbreviation; write `directory`; got `dir_hint`.") in
        found  # V.6
    check (Rule.Abbreviation, "Name coins abbreviation; write `temporary`; got `tmp_count`.") in
        found  # V.6
    for (full, name) in [("buffer", "buf"), ("error", "err"), ("destination", "dest"),
                         ("arguments", "args")]:
      check (Rule.Abbreviation, "Name coins abbreviation; write `" & full & "`; got `" & name &
        "`.") in found  # V.6
    check (Rule.VerbAction, "Action is imperative verb and property is bare noun; got " &
      "`getGrade`.") in found  # V.3
    check (Rule.WordGlobal, "Global never shares its word with type; got `ALGEBRA`.") in
        found  # V.10, shares word with type `Algebra`
    check not found.anyIt("JSON" in it[1])  # V.9 needs glossary, so it is caller's
    check not found.anyIt("`lut`" in it[1])  # jargon
    check not found.anyIt("constructTable" in it[1])
    check (Rule.CaseName, "Global is `SCREAMING_SNAKE_CASE`; got `tmp_count`.") in found  # V.1
    check found.len == 9  # V.1, V.3, V.6, V.10: each break once
    check "func toJSON() = discard\nfunc parseJson() = discard\n".breaches.len == 0  # V.9 caller's
    check "const LUT_GRADE = 1\n".breaches ==
        @[(Rule.TableLookup, "Lookup table reads `lut_<value>_by_<key>`; got `LUT_GRADE`.")]
    check "const LUT_GRADE_BY_BASIS = 1\n".breaches.len == 0  # V.5
    check "proc get*(x: int) = x\n".breaches.len == 0  # one word is noun
    check "proc f(ctx: int) = discard\n".breaches.len == 1  # V.6, exempt word aside
    check checkNames("x.nim", "proc f(ctx: int) = discard\n", ["ctx"]).len == 0  # glossary admits


  test "foreign binding keeps library's name, and its parameters are read":
    const foreign = "proc getError*(): cstring {.importc: \"SDL_GetError\".}\n" &
        "proc glGetString*(name: GLenum, buf: pointer) {.importc, dynlib: \"GL\".}\n" &
        "proc getShaderiv*(shader: Uint)\n  {.importc: \"glGetShaderiv\", header: H.}\n"
    let found = foreign.messages
    check not found.anyIt("getError" in it) and not found.anyIt("glGetString" in it)
    check not found.anyIt("getShaderiv" in it)  # pragma on its own line
    check found.anyIt("got `buf`" in it)  # parameter is ours
    check "getError" notin foreign.names and "buf" in foreign.names


  test "routine carrying any foreign mark among its pragmas keeps its name, and no other does":
    # Case held: marks stood three times, apart (`MARKS_FOREIGN` of `curator/audit` names, and
    #   `FOREIGN_PRAGMAS` here, matched as substrings of signature): `{.importobjc.}` was read as
    #   ours, and parameter `dynlib_path` made routine foreign (#557). Domain is each pragma of
    #   one list, among pragmas of routine, and each name beside them that holds one.
    for mark in ["dynlib", "exportc", "exportcpp", "extern", "header", "importc", "importcpp",
                 "importjs", "importobjc"]:
      check ("proc getView*() {." & mark & ": \"view\".}\n").breaches.len == 0  # library's name
      check "getView" notin ("proc getView*() {.inline, " & mark & ".}\n").names
    check "proc getValue(dynlib_path: string) = discard\n".breaches.mapIt(it[0]) ==
        @[Rule.VerbAction]  # parameter named like mark marks nothing
    check "proc getHeader*(header: string) = discard\n".breaches.mapIt(it[0]) == @[Rule.VerbAction]


  test "reach is global under blocks opening no scope, and local under any other":
    for name in ["TOP", "JS_ONLY", "NATIVE", "SECTION", "DEPENDENT", "CALL", "LEFT", "RIGHT"]:
      check BLOCKS.reachIn(name) == Reach.Global  # V.1
    for name in ["inner", "in_static", "local_constant", "in_routine_when", "each", "in_loop"]:
      check BLOCKS.reachIn(name) == Reach.Local  # V.1
    check "first" notin BLOCKS.names  # argument continuing value is no binding
    check "right_value" notin BLOCKS.names  # value side is never name
    check BLOCKS.breaches.len == 0  # V.1


  test "V.10 binding of entry block takes no names finding, case unjudged":
    for name in ["verb", "path", "shown", "error"]:
      check ENTRY_BINDS.reachIn(name) == Reach.Entry  # V.10
    check ENTRY_BINDS.reachIn("inside") == Reach.Local  # V.10, routine is local
    check ENTRY_BINDS.reachIn("helper_local") == Reach.Local  # V.10, routine inside block
    check ENTRY_BINDS.reachIn("SHARED") == Reach.Global  # V.10, other branch of `when`
    check ENTRY_BINDS.breaches.len == 0  # V.10, entry block's own rule reports them
    check checkBlockEntry("x.nim", ENTRY_BINDS).len == 4  # V.10, one rule, one finding each
    check "when isMainModule:\n  let VERB = paramStr(1)\n".breaches.len == 0  # case unjudged
    check "when isMainModule:\n  let tmp = 1\n".breaches.mapIt(it[0]) == @[Rule.Abbreviation]


  test "V.1 V.11 case follows kind of name":
    check CASES.breaches.len == 0  # V.1, V.11
    let found = CASES_BROKEN.breaches
    check found.len == 8  # V.1, V.11
    for finding in [
      (Rule.CaseName, "Type is `PascalCase`; got `basis_digits`."),
      (Rule.CaseName, "Field is `snake_case`; got `Width`."),
      (Rule.CaseMember, "Member is `PascalCase`; got `base`."),
      (Rule.CaseMember, "Member is `PascalCase`; got `Anti_Side`."),
      (Rule.CaseName, "Global is `SCREAMING_SNAKE_CASE`; got `lowerGlobal`."),
      (Rule.CaseName, "Routine is `lowerCamelCase`; got `Construct_table`."),
      (Rule.CaseName, "Parameter is `snake_case`; got `Count`."),
      (Rule.CaseName, "Local is `snake_case`; got `Local_value`."),
    ]:
      check finding in found
    check (Rule.CaseMember, "Member is `PascalCase`; got `Str_Raw`.") in OPERATORS.breaches


  test "V.1 one letter fits by its own case, and capital local is finding":
    # Architect's ruling: plain ASCII is no notation, so `N` and `M` take local case.
    check LETTERS.breaches == @[
      (Rule.CaseName, "Global is `SCREAMING_SNAKE_CASE`; got `g`."),
      (Rule.CaseName, "Parameter is `snake_case`; got `N`."),
      (Rule.CaseName, "Local is `snake_case`; got `M`."),
    ]  # V.1, V.6


  test "V.12 placeholder is one capital letter, and parameter holding type is snake":
    # Architect's ruling: `typedesc` parameter is parameter (V.1), never placeholder (V.12).
    check PLACEHOLDERS.breaches == @[
      (Rule.LetterPlaceholder, "Placeholder is one capital letter; got `Key`."),
      (Rule.LetterPlaceholder, "Placeholder is one capital letter; got `a`."),
      (Rule.CaseName, "Parameter is `snake_case`; got `T`."),
      (Rule.LetterPlaceholder, "Placeholder is one capital letter; got `Element`."),
    ]  # V.1, V.12
    check PLACEHOLDERS.declarations.filterIt(it.name == "t")[0].kind == KindName.Parameter


  test "V.4 boolean is proposition or mode, and predicate func is `is…`":
    let found = BOOLEANS.breaches
    for name in ["gated", "done", "ready", "quiet"]:
      check (Rule.NameBoolean, "Boolean opens `is_`, `as_`, `should_`, `found_` or `has_`; got `" &
        name & "`.") in found  # V.4
    check (Rule.NameBoolean, "Predicate `func` is `is…` in camel case; got `mixed`.") in found
    check found.len == 5  # V.4: `proc`, `func` writing `var`, and `contains` are unread
    check "inferred" in BOOLEANS.names and not found.anyIt("inferred" in it[1])  # value unread
    check PREFIXES_BOOLEAN.allIt(("proc run() =\n  let " & it & "_set = true\n").breaches.len == 0)


  test "III.5 notation holds over case at any scope, but at module scope only for immutable global":
    # Variable takes source's notation (`𝐀`, `𝐮`, `𝐌` pass); mutable global never does.
    check NOTATION.breaches == @[
      (Rule.Notation, "Notation holds over case only for immutable global; got `𝐧`."),
      (Rule.Notation, "Notation holds over case only for immutable global; got `𝐍`."),
    ]  # III.5
    check "𝐦".isNotation and not "m".isNotation  # III.5
    check "𝐌".isCased(Casing.Screaming) and not "𝐌".isCased(Casing.Snake)  # III.5
    check "𝐮".isCased(Casing.Snake) and "𝟎".isCased(Casing.Screaming)  # III.5
    check "Δt".isCased(Casing.Pascal) and not "δt".isCased(Casing.Pascal)  # III.5


  test "casing follows kind and reach":
    check Declared(kind: KindName.Binding, reach: Reach.Global).casingOf == Casing.Screaming
    check Declared(kind: KindName.Binding, reach: Reach.Local).casingOf == Casing.Snake
    check Declared(kind: KindName.Member).casingOf == Casing.Pascal  # V.11
    check Declared(kind: KindName.Placeholder).casingOf == Casing.Letter  # V.12
    check "isMixed".isCased(Casing.Camel) and not "is_mixed".isCased(Casing.Camel)  # V.1
    check "E1".isCased(Casing.Pascal) and "x2".isCased(Casing.Snake)  # V.1, digits carry none
    check Declared(name: "Width", kind: KindName.Field).isMiscased  # V.1
    check not Declared(name: "VERB", kind: KindName.Binding, reach: Reach.Entry).isMiscased
    check not Declared(name: "𝐌", kind: KindName.Binding, reach: Reach.Local).isMiscased


  test "name that template substitutes declares nothing of that name":
    # `type name = object` inside `template defineKind(name: untyped)` declares parameter's
    #   argument at expansion, never type `name` (P05 of `pga_benchmark`).
    const substituted =
        "template defineKind(name: untyped; count: static int) =\n" &
        "  type name = object\n" &
        "    elements: array[count, float]\n" &
        "  let name_value = count\n"
    check substituted.breaches.len == 0  # V.1
    check substituted.declarations.filterIt(it.name == "name").mapIt(it.kind) ==
        @[KindName.Parameter]  # template parameter alone, no type
    check "elements" in substituted.names and "name_value" in substituted.names


  test "V.6 abbreviation is spelled out word by word, case kept, exempt words aside":
    check "ctx".respelled([]) == "context"
    check "tmpDir".respelled([]) == "temporaryDirectory"
    check "Cfg".respelled([]) == "Configuration"
    check "CFG_PATH".respelled([]) == "CONFIGURATION_PATH"
    check "dir_hint".respelled([]) == "directory_hint"
    check "dirs".respelled([]) == "dirs"  # plural is other word, outside table
    check "ctx".respelled(["ctx"]) == "ctx"  # glossary admits it
    check "src_dir".respelled([]) == "src_directory"  # jargon of V.6 stays


  test "V.1 and V.11 case is spelled word by word, and spelling it again changes nothing":
    check "localValue".cased(Casing.Snake) == "local_value"  # V.1
    check "LOCAL_VALUE".cased(Casing.Snake) == "local_value"  # V.1
    check "N".cased(Casing.Snake) == "n"  # V.1
    check "Construct_table".cased(Casing.Camel) == "constructTable"  # V.1
    check "DO_THING".cased(Casing.Camel) == "doThing"  # V.1
    check "basis_digits".cased(Casing.Pascal) == "BasisDigits"  # V.1
    check "base".cased(Casing.Pascal) == "Base"  # V.11
    check "lastX".cased(Casing.Screaming) == "LAST_X"  # V.1
    check "parse_JSON".cased(Casing.Camel) == "parseJSON"  # V.9, acronym kept
    check "Key".cased(Casing.Letter) == "Key"  # V.12, initial is choice
    for name in ["localValue", "LOCAL_VALUE", "Construct_table", "basis_digits", "lastX", "E1",
                 "vec3Norm", "N", "anti_Side", "toJSON"]:
      for casing in [Casing.Pascal, Casing.Camel, Casing.Snake, Casing.Screaming]:
        let spelled = name.cased(casing)
        check spelled.isCased(casing)  # V.1
        check spelled.cased(casing) == spelled  # V.1, idempotent


  test "line of each finding is line of its declaration":
    check checkNames("x.nim", "const A = 1\nproc getX() = discard\n", []).mapIt(it.line) == @[2]
    check checkNames("x.nim", CASES_BROKEN, []).mapIt(it.line) == @[2, 4, 6, 6, 7, 8, 8, 9]


  test "acronyms are capital runs inside camel or Pascal names":
    check "toJSON".acronyms == @["JSON"]
    check "SDL3Window".acronyms == @["SDL3"]
    check "Chiral".acronyms.len == 0 and "isMixed".acronyms.len == 0
    check "DIRECTORY_SDL3".acronyms.len == 0  # screaming holds by reading
    check "rga_visualiser".acronyms.len == 0


  test "V.6 rename target is each declaration check reports, at its name's column":
    let
      source = "proc f(ctx: int, b: int) =\n  let tmp = ctx\n  echo tmp\n"
      renames = renamesAbbreviation(source, [])
    check renames == @[(1, 7, "ctx", "context"), (2, 6, "tmp", "temporary")]
    check checkNames("a.nim", source, JARGON).len == renames.len  # check reads same set


  test "tuple binding declares names before `=` alone, never global its value names":
    const binding = "let (source, destination) = (paths[i], DIR_FONTS / face)\n"
    check binding.declarations.mapIt(it.name) == @["source", "destination"]  # V.6
    check renamesAbbreviation(binding, []).len == 0  # V.6, `DIR_FONTS` is use, never declaration


  test "V.1 and V.11 rename target is each case finding, and refusal names what fix cannot prove":
    let renames = renamesCase(CASES_BROKEN, [])
    check renames.len == checkNames("x.nim", CASES_BROKEN, []).len  # V.1, V.11: same set
    check renames.mapIt((it.name, it.renamed, it.rule)) == @[
      ("basis_digits", "BasisDigits", Rule.CaseName),
      ("Width", "width", Rule.CaseName),
      ("base", "Base", Rule.CaseMember),
      ("Anti_Side", "AntiSide", Rule.CaseMember),
      ("lowerGlobal", "LOWER_GLOBAL", Rule.CaseName),
      ("Count", "count", Rule.CaseName),
      ("Construct_table", "constructTable", Rule.CaseName),
      ("Local_value", "local_value", Rule.CaseName),
    ]  # V.1, V.11
    check renames.filterIt(it.refusal.len > 0).mapIt(it.refusal) == @[
      "`$` of member reads its name", "`$` of member reads its name"]  # V.11
    check renames[5].line == 8 and renames[5].column == 21  # parameter's own token
    const local = "proc run() =\n  const WIDE = 2\n  let TMP_DIR = \"a\"\n" &
        "when isMainModule:\n  let VERB = paramStr(1)\n"
    check renamesCase(local, []).mapIt((it.renamed, it.is_local)) == @[
      ("wide", true), ("temporary_directory", true), ("verb", true)
    ]  # V.1, V.6; entry binding takes case of local, where fix moves it (V.10)
    const foreign = "type Def {.importc: \"b3Def\".} = object\n  enableSleep {.importc.}: bool\n" &
        "var counter {.exportc.}: cint\nproc pushAt(Body_id: cint) {.importc: \"b3Push\".}\n" &
        "type Side = enum\n  left = \"left\", Right\nproc Count(Count: int) = discard\n" &
        "proc do_x_y() = discard\nproc f[Key](k: Key) = discard\n"
    check renamesCase(foreign, []).mapIt((it.name, it.refusal)) == @[
      ("enableSleep", "foreign code reads name through `importc`"),
      ("counter", "foreign code reads name through `exportc`"),
      ("Body_id", ""),  # parameter crosses by place
      ("left", ""),  # member carries own string
      ("Count", "line declares `Count` twice"),
      ("Count", "line declares `Count` twice"),
      ("do_x_y", "`doXY` reads `XY` as acronym"),
    ]  # V.1, V.11; placeholder `Key` (V.12) has no rename
    check renamesCase("when isMainModule:\n  var COUNT {.global.} = 0\n", []).len == 0  # V.10
    const node = "type Node = ref object of JsRoot\n  Child_count: int\n"
    check renamesCase(node, []).mapIt((it.name, it.refusal)) ==
      @[("Child_count", "foreign code reads name through `JsRoot`")]  # root of JavaScript object
