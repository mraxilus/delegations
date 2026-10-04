## Replicate declaration scanner of `declared.nim` header: kind and reach of each name read.

{.experimental: "strictFuncs".}

import std/[sequtils, unittest]
import ../../src/knoller/declared


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
    ##   Copy of same fixture in `curator/audit/tests/suites/test_names.nim`, which names
    ##     check reads; fix to one is finished only when other is checked.
  OPERATORS = """
func `∧`*(m, n: Multivector): Multivector = m
func `[]`*(m: var Multivector, b: Basis): var float = m.elements[b]
template m: untyped = MULTIVECTORS(i)
type State {.pure.} = enum Code, Str_Raw
"""
    ## Operators, routine without parameters, and enum on one line.
    ##   Copy of same fixture in `curator/audit/tests/suites/test_names.nim`, which names
    ##     check reads; fix to one is finished only when other is checked.


func names(source: string): seq[string] =
  ## Read declared names of source, in order.
  source.declarations.mapIt(it.name)



suite "Declarations":
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


  test "operator is backticked and never read as name":
    let found = OPERATORS.names
    check "∧" notin found and "[]" notin found  # III.5
    check "m" in found and "n" in found and "b" in found  # parameters of operator are read
    check "i" notin found  # call in body of routine without parameters is no parameter
    check "Code" in found and "Str_Raw" in found  # V.11, enum on one line
