## Replicate kind registry of `kinds.nim` header table, read from header rather than restated.

import std/[options, sequtils, strutils, unittest]
import ../../src/kinds
import ./fixtures


const TABLE = staticRead("../../src/kinds.nim").headerTable
  ## Heading row, then one row per kind, as `kinds.nim` header holds them.


func yesNo(is_set: bool): string =
  ## Render flag as header spells it.
  if is_set: "yes" else: "no"


suite "Article I":
  test "I.4 header table is derived view of registry":
    check TABLE[0] == @["Kind", "Match", "Syntax", "Prose", "Gate"]  # columns read below
    let rows = TABLE[1 .. ^1]
    check rows.mapIt(it[0]) == Kind.toSeq.mapIt($it)  # every kind once, in enum order
    for (row, kind) in zip(rows, Kind.toSeq):
      for match in row[1].splitWhitespace:
        for prefix in ["", "d/"]:  # root and nested
          # Leading dot is extension or dotfile basename; one spelling of two classifies.
          let spellings = if match.startsWith("."): @[match, "x" & match] else: @[match]
          check spellings.anyIt(kindOf(prefix & it) == some(kind))  # VI.5 match classifies
      check row[2] == $kind.rule.syntax  # Syntax column
      check row[3] == kind.rule.is_prose.yesNo  # Prose column
      check row[4] == kind.rule.is_gated.yesNo  # Gate column


suite "Article VI":
  test "VI.5 last extension decides":
    check kindOf("koch.nim.cfg") == some(Kind.Cfg)  # driver flags read as cfg, never Nim

  test "VI.5 unregistered kinds are none":
    for path in ["Makefile", "x.mk", "data.csv", "nimble.paths", "a.txt"]:  # 5 cases
      check kindOf(path).isNone  # retired or never registered
