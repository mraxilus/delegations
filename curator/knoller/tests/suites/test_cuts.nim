## Replicate V.2 on order of words where words decide it alone: property leads its one-letter
##   value, `anti` follows word it qualifies, and axis value goes last; rename writes that order in
##   case of name's kind, and joins case rename of same declaration into one new name.
##   Case held: `m_norm_bulk`, `m_order`, `𝐦_grade`, `antibasis` and `left_name`, lines 371 of
##     `pga/operators.nim`, 499 and 617 of `pga/cayleys.nim`, 392 of `tests/suites.nim` and 45
##     of `pga/emitters.nim` of PGA library at `3d9696e` (rule 8 of #443); `test_regressions.nim`
##     and `test_command.nim` hold renames through semantic pass.

{.experimental: "strictFuncs".}

import std/[sequtils, unittest]
import ../../src/knoller/[cuts, names, rules]


const
  WRAPPERS =
    "type\n" &
    "  Chiral*[T] = object\n" &
    "    left*, right*: T\n" &
    "  Formal*[T] = object\n" &
    "    when IS_CONFORMAL:\n" &
    "      flat*, round*: T\n" &
    "    else:\n" &
    "      round*: T\n" &
    "  Partial*[T] = object\n" &
    "    bulk*, weight*: T\n" &
    "  Spatial*[T] = object\n" &
    "    base*, anti*: T\n"
    ## Wrappers of `pga/cayleys.nim` at `3d9696e`, lines 33 to 44 (V.7).
  AXES = ["left", "right", "flat", "round", "bulk", "weight", "base", "anti"]
    ## Axis values `WRAPPERS` declares.
  WORDS = ["basis", "scalar", "name"]  ## Words names of package take alone.
  ANTI = "Name puts `anti` after word it qualifies, as `scalarAnti`"
    ## Sentence of finding of `anti` glued first.


func stated(name: string; axes: openArray[string] = AXES; words: openArray[string] = WORDS):
    string =
  ## Read message cut check gives local `name` of one routine; empty where it passes.
  let found = checkCuts("a.nim", "proc p() =\n  let " & name & " = 1\n", axes, words)
  if found.len == 0: "" else: found[0].message


func renamed(source: string; axes = AXES; words = WORDS): seq[(string, string, string)] =
  ## Read name, new name and refusal of each rename cut asks in source.
  renamesCut(source, axes, words, []).mapIt((it.name, it.renamed, it.refusal))



suite "Article V.2":
  test "axis value is field of wrapper package declares, and word is word of its names":
    check axesDeclared(WRAPPERS) == @AXES
    for none in [
      "type Pair*[T] = object\n  first, second: T\n",  # adjective closes with no `-al`
      "type Ringal*[T] = object\n  counts: array[4, T]\n  seconds: int\n",  # field of other type
      "type Dual*[A, B] = object\n  left: A\n  right: B\n",  # two placeholders
      "type Mutual*[T] = object\n  only: T\n",  # one field
      "type Chiral* = object\n  left, right: int\n",  # no placeholder
    ]:
      check axesDeclared(none).len == 0
    let declaring = "type BasisSigned = object\n  basis: Basis\nfunc scalarAnti() = discard\n"
    check declaring.wordsDeclared == @["basis", "signed", "scalar", "anti"]


  test "property after its one-letter value, `anti` glued first and axis value first report":
    for (name, message) in [
      ("m_norm_bulk", "Property leads name, value it belongs to last; got `m_norm_bulk`."),
      ("m_order", "Property leads name, value it belongs to last; got `m_order`."),
      ("𝐦_grade", "Property leads name, value it belongs to last; got `𝐦_grade`."),
      ("c_parity", "Property leads name, value it belongs to last; got `c_parity`."),
      ("p_centroid", "Property leads name, value it belongs to last; got `p_centroid`."),
      ("antibasis", ANTI & "; got `antibasis`."),
      ("antiscalar", ANTI & "; got `antiscalar`."),
      ("left_name", "Name opens with head, axis value `left` last; got `left_name`."),
      ("weight_norm", "Name opens with head, axis value `weight` last; got `weight_norm`."),
    ]:
      check name.stated == message
    let
      signature = "func emitTerm*(\n  left_name: string,\n): int = 1\n"
      found = checkCuts("a.nim", signature, AXES, WORDS)
    check found.mapIt((it.line, it.rule)) == @[(1, Rule.CutName)]  # line of signature


  test "order of reading, type word, axis values alone and word of no name pass":
    for passing in [
      "a_flags", "b_flags", "b_flags_remaining",  # value names its flags (V.2)
      "parity_a", "norm_bulk_m", "grade_𝐦", "basis_anti", "name_left",  # head first already
      "c_complement", "c_dual", "product_complement",  # meaning decides: reading holds it
      "FLOAT_WIDTH", "STRING_LONG",  # type word first is no shape (#443)
      "bulkFlat", "weight_round",  # axis values alone: first names thing
      "antique", "antic",  # glued word names no word of package, or holds three letters too few
      "m_flags", "mx_grade",  # value of one letter before no property, or value of two letters
    ]:
      check passing.stated == ""
    check "left_name".stated(axes = []) == ""  # wrapper of library is no axis value
    check "antibasis".stated(words = []) == ""


  test "rename writes order of cut in case of name's kind, abbreviation spelled out":
    check renamed("proc p() =\n  let\n    m_norm_bulk = 1\n    𝐦_grade = 2\n    antibasis = 3\n") ==
      @[("m_norm_bulk", "norm_bulk_m", ""), ("𝐦_grade", "grade_𝐦", ""),
        ("antibasis", "basis_anti", "")]
    check renamed("func emitTerm*(left_name: string, right_basis: Basis): int = 1\n") ==
      @[("left_name", "name_left", ""), ("right_basis", "basis_right", "")]
    check renamed("proc leftRotate*() = discard\n") == @[("leftRotate", "rotateLeft", "")]
    check renamed("type LeftName* = int\n") == @[("LeftName", "NameLeft", "")]
    check renamed("const M_NORM* = 1\n") == @[("M_NORM", "NORM_M", "")]
    check renamed("proc p() =\n  let leftCtx = 1\n") == @[("leftCtx", "context_left", "")]
    let rename = renamesCut("proc p() =\n  let m_order = 1\n", AXES, WORDS, [])[0]
    check (rename.line, rename.column, rename.rule, rename.is_local) == (2, 6, Rule.CutName, true)


  test "rename foreign code, define, `$` or second declaration reads stays for hand":
    let refused = [
      ("const M_ORDER* {.intdefine: \"pga.order\".} = 1\n",
       "`intdefine` gives `M_ORDER`, which caller passes"),  # fix renames no define (#443)
      ("var LEFT_NAME* {.importc: \"left\".}: cint\n", "foreign code reads name through `importc`"),
      ("type Side = enum\n  LeftName, RightName\n", "`$` of member reads its name"),
      ("proc p() =\n  let (m_grade, m_grade) = (1, 2)\n", "line declares `m_grade` twice"),
    ]
    for (source, refusal) in refused:
      check renamed(source).allIt(it[2] == refusal)
      check renamed(source).len > 0
    check renamed("type Side = enum\n  LeftName = \"left\"\n").mapIt(it[2]) == @[""]  # own string


  test "case rename and cut rename of one declaration join into one rename, of case's rule":
    let
      source = "proc p() =\n  let leftName = 1\n  let left_ctx = 2\n  let m_grade = 3\n"
      joined = renamesCase(source, []).composed(renamesCut(source, AXES, WORDS, []))
    check joined.mapIt((it.name, it.renamed, it.rule)) == @[
      ("leftName", "name_left", Rule.CaseName),  # case and cut: one new name
      ("left_ctx", "context_left", Rule.CutName),  # cut spells abbreviation out too
      ("m_grade", "grade_m", Rule.CutName),
    ]
    let defined = "const mOrder* {.intdefine.} = 1\n"
    check renamesCase(defined, []).composed(renamesCut(defined, AXES, WORDS, [])).mapIt(
      (it.renamed, it.rule, it.refusal.len > 0),
    ) == @[("M_ORDER", Rule.CaseName, false), ("ORDER_M", Rule.CutName, true)]  # refusal warns
    check renamesCut("proc leftName*() {.exportc.} = discard\n", AXES, WORDS, []).len == 0
      # foreign routine declares no name of ours
