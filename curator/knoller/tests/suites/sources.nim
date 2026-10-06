## Hold Nim sources several suites read, so each suite reads one copy: declarations of every
##   kind, operators, and entry blocks.

{.experimental: "strictFuncs".}


const
  SOURCE* = """
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
  OPERATORS* = """
func `∧`*(m, n: Multivector): Multivector = m
func `[]`*(m: var Multivector, b: Basis): var float = m.elements[b]
template m: untyped = MULTIVECTORS(i)
type State {.pure.} = enum Code, Str_Raw
"""
    ## Operators, routine without parameters, and enum on one line.
  ENTRY_BINDS* = """
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
  ENTRY_CALLS* = """
when isMainModule:
  doAssert paramCount() == 1, "Usage: marks <dir>; got `" & $paramCount() & "` arguments."
  buildPages(paramStr(1))
"""
    ## Entry block of plain calls, which binds nothing.
