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
): seq[int] {.compileTime.} = discard

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
  ALIASES* =
    "when IS_CONFORMAL:\n" &
    "  template infinity*(t: typedesc[Basis]): Basis = t.vectorLast\n" &
    "    ## Alias basis representing point at infinity (i.e. eₙ).\n" &
    "\n" &
    "template origin*(t: typedesc[Basis]): Basis =\n" &
    "  ## Alias basis representing origin (i.e. eₙ in RGA; 𝐞ₙ₋₁ in CGA).\n" &
    "  when IS_RIGID: t.vectorLast else: t.vectorLast.pred\n" &
    "\n" &
    "template scalar*[I: Basis | Grade | GradeAnti](t: typedesc[I]): I =\n" &
    "  ## Alias scalar's basis and (anti)grade indices.\n" &
    "  when I is GradeAnti:  I.high else: I.low\n" &
    "\n" &
    "template scalarAnti*[I: Basis | Grade | GradeAnti](t: typedesc[I]): I =\n" &
    "  ## Alias antiscalar's basis and (anti)grade indices.\n" &
    "  when I is GradeAnti:  I.low else: I.high\n" &
    "\n" &
    "template vector*[G: Grade | GradeAnti](t: typedesc[G]): G = \n" &
    "  ## Alias grade of (anti)vectors.\n" &
    "  when G is GradeAnti: G(DIMENSIONS - 1) else: G(1)\n" &
    "\n" &
    "template vectorAnti*[G: Grade | GradeAnti](t: typedesc[G]): G = \n" &
    "  ## Alias antigrade of (anti)vectors. \n" &
    "  when G is GradeAnti: G(1) else: G(DIMENSIONS - 1)\n" &
    "\n" &
    "template vectorLast*(t: typedesc[Basis]): Basis = Basis(DIMENSIONS)\n" &
    "  ## Alias basis representing last vector, i.e. last grade 1 multivector element, eₙ.\n" &
    "\n" &
    "template low*[G: Grade | GradeAnti](t: typedesc[G]): G = G(0)\n" &
    "  ## Alias (anti)scalar's (anti)grade index.\n" &
    "\n" &
    "template high*[G: Grade | GradeAnti](t: typedesc[G]): G = G(DIMENSIONS)\n" &
    "  ## Alias (anti)antiscalar's (anti)grade index (where antiantiscalar is scalar).\n" &
    "\n" &
    "func horizon(t: typedesc[Basis]): BasisSigned {.compileTime.} =\n" &
    "  ## Alias basis representing horizon (i.e. 𝐞̄ₙ in RGA; 𝐞̄ₙ₋₁ in CGA).\n" &
    "  Basis.origin.complement(Chirality.Right)\n"
    ## Aliases of `pga/algebra.nim` at `3d9696e`, lines 300 to 337, and `horizon` of
    ##   `pga/cayleys.nim`, line 929.
