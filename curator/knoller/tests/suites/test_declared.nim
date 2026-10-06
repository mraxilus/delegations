## Replicate declaration scanner of `declared.nim` header: kind and reach of each name read.

{.experimental: "strictFuncs".}

import std/[sequtils, unittest]
import ../../src/knoller/declared
import ./sources


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
    check kinds.filterIt(it.name == "buf")[0].kind == KindName.Parameter
    check kinds.filterIt(it.name == "args")[0].kind == KindName.Field
    check kinds.filterIt(it.name == "Anti")[0].kind == KindName.Member  # V.11
    check kinds.filterIt(it.name == "T")[0].kind == KindName.Placeholder  # V.12


  test "operator is backticked and never read as name":
    let found = OPERATORS.names
    check "∧" notin found and "[]" notin found  # III.5
    check "m" in found and "n" in found and "b" in found  # parameters of operator are read
    check "i" notin found  # call in body of routine without parameters is no parameter
    check "Code" in found and "Str_Raw" in found  # V.11, enum on one line
