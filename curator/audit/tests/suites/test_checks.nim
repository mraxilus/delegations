## Replicate naming of checks of koch in `checks.nim` header: id is `koch.` and slug of name,
##   one for each check, apart from every id of knoller (D4 of #1002).

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../../knoller/src/knoller
import ../../src/checks


suite "Checks":
  test "id is `koch.` and slug of name, as example of #1002 names it":
    check Check.WidthSubject.id == "koch.commit-subject-width"  # example of #1002
    check Check.Signoff.id == "koch.sign-off"  # hyphen of name stays one
    check Check.Acronym.id == "koch.acronym"  # one word stays


  test "every check has id of its own, and no id of knoller equals one":
    var ids: seq[string]
    for check in Check: ids.add check.id
    check ids.deduplicate.len == ids.len  # no two checks share id
    check ids.allIt(it.startsWith("koch.") and it.len > "koch.".len and it[^1] != '-')
    for rule in Rule: check rule.id notin ids  # prefix keeps tools apart
