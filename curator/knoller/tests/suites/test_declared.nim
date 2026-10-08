## Replicate declaration scanner of `declared.nim` header: kind and reach of each name read, and
##   which parameter is generic.

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


  test "parameter of type `typedesc` or `type` alone is generic, and its group shares it":
    const signature = "proc f(A, b: typedesc; c: int, D: typedesc[I], e: type, G: type int,\n" &
        "    h: typeDesc = int, k = int) = discard\n"
    let parameters = signature.declarations.filterIt(it.kind == KindName.Parameter)
    check parameters.mapIt((it.name, it.is_generic)) == @[
      ("A", true), ("b", true), ("c", false), ("D", false), ("e", true), ("G", false),
      ("h", true), ("k", false),
    ]  # V.12: `typedesc[I]` and `type int` name their type, and default alone shows none
    check SOURCE.declarations.allIt(not it.is_generic)  # V.12, no other declaration is generic
