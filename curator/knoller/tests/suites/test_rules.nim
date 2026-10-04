## Replicate naming of rules in `rules.nim` header: id is slug of name, one for each rule.

{.experimental: "strictFuncs".}

import std/[sequtils, unittest]
import ../../src/knoller/rules



suite "Rules":
  test "id is slug of name: lowercase words joined by hyphen":
    check Rule.ExpressionSpacing.id == "expression-spacing"  # space becomes hyphen
    check Rule.TargetSubject.id == "to-target-subject-first"  # bracket run folds into one
    check Rule.StrictFuncs.id == "strictfuncs"  # case folds
    check Rule.Fence.id == "fence"  # one word stays


  test "every rule has id of its own, so output names one rule":
    var ids: seq[string]
    for rule in Rule: ids.add rule.id
    check ids.deduplicate.len == ids.len  # no two rules share id
    check ids.allIt(it.len > 0 and it[0] != '-' and it[^1] != '-')  # hyphen joins, never ends
