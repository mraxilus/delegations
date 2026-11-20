## Hold that each value of message stands in backticks, before `got` and with none (Article
##   IV.4), and that value opening its claim stays for hand, as Architect ruled on rule 6 of #443:
##   message need not take form `; got`.
##   Fix adds backticks, and nothing else, and nothing second time.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/knoller/[messages, reports]


const
  FLAGS =
    "  doAssert lut_basis_by_flags[b].isSome, &\"Found invalid basis flags: {int(b):b}\"\n"
    ## Line 243 of `pga/algebra.nim` of PGA library at `3d9696e`.
  DIGIT =
    "      assert ord(d) - ord('0') in digits_valid, &\"Found invalid digit `{d}` in " &
    "{digits=}.\"\n"
    ## Line 252 of `pga/algebra.nim` at `3d9696e`.
  INVALID =
    "    assert digits_invalid == 0, &\"Found invalid flags `{digits_invalid:b}` in " &
    "{flags=:b}\"\n"
    ## Line 262 of `pga/algebra.nim` at `3d9696e`.
  NORM =
    "  assert norm[Basis.scalar] == 0 or norm[Basis.scalarAnti] == 0,\n" &
    "    &\"`{norm=}` must be a bulk xor weight norm, not geometric norm.\"\n"
    ## Lines 104 and 105 of `tests/suites.nim` at `3d9696e`.
  KEPT =
    "  doAssert DIMENSIONS in 2..6,\n" &
    "    &\"Dimensionality should be in the range 2..6; got `{DIMENSIONS}`.\"\n" &
    "  doAssert IS_RIGID or DIMENSIONS >= 3,\n" &
    "    &\"Conformal Geometric Algebras must have dimensionality of 3 or more \" &\n" &
    "    &\"(2 Conformal + 1 Euclidean); got `{DIMENSIONS}`.\"\n" &
    "  assert product.len == 1, &\"Attempt to extract singular product term from " &
    "`{product}`.\"\n" &
    "    assert countSetBits(f.toFlags) == 1,\n" &
    "      &\"Attempt to filter with non-grade 1 basis factor: `{f=}`.\"\n" &
    "    assert terms.len <= 1,\n" &
    "      &\"Attempt to convert 2D cayley to 1D with non-singleton product values;\" &\n" &
    "      &\" got `{terms}` for `{chirality}` `{operand}`.\"\n" &
    "func `==`*(m, n: Multivector): bool {.error:\n" &
    "  \"Use approximate comparison, `=~`, or compare elements directly.\"\n" &
    ".}\n" &
    "  func normCenter*(m: Multivector): MultivectorScalars {.inline, error: \"TODO:  |⊙m\".}\n"
    ## Lines 97 to 101 of `pga/algebra.nim`, 670, 813, 814, 877 and 878 of `pga/cayleys.nim`,
    ##   184 to 186 of `pga/multivectors.nim` and 206 of `pga.nim`, at `3d9696e`: each value in
    ##   backticks, split `; got` among them, and message of no value.


func found(source: string): seq[(int, string)] =
  ## Read line and message of each report of message echo in source.
  checkEchoes("a.nim", source).mapIt((it.line, it.message))


func fixed(source: string): string =
  ## Fix messages of source, as `koch fix` does.
  fixEchoes("a.nim", source).source


func isSettled(source: string): bool =
  ## Decide whether source reports no message echo and fixes to itself again.
  checkEchoes("a.nim", source).len == 0 and source.fixed == source



suite "Echoes":
  test "bare value of library message takes backticks, with no `got`":
    check FLAGS.found == @[
      (1, "Message echoes each value in backticks, so empty value stays visible; got " &
        "`{int(b):b}`."),
    ]  # line 243 of `pga/algebra.nim`
    check FLAGS.fixed == FLAGS.replace(": {int(b):b}\"", ": `{int(b):b}`\"")
    check DIGIT.found.mapIt(it[1]).allIt(it.endsWith("got `{digits=}`."))
    check DIGIT.fixed == DIGIT.replace(" in {digits=}.", " in `{digits=}`.")
    check INVALID.fixed == INVALID.replace(" in {flags=:b}", " in `{flags=:b}`")
    for source in [FLAGS, DIGIT, INVALID]:
      check source.fixed.isSettled


  test "value that opens its claim stays for hand, backticks and all":
    check NORM.found == @[
      (2, "Message states its claim before its value, so hand rewords it; got `{norm=}` " &
        "before `must be a bulk xor weight norm, not geometric norm.`."),
    ]  # line 105 of `tests/suites.nim`
    check NORM.fixed == NORM
    let bare = "doAssert x, &\"{name} is empty.\"\n"
    check bare.found.len == 2  # bare value, and value that opens its claim
    check bare.fixed == "doAssert x, &\"`{name}` is empty.\"\n"
    check bare.fixed.found.len == 1  # claim stays for hand


  test "message of library that echoes each value in backticks takes no report":
    check KEPT.isSettled


  test "message is argument of each call that takes one, or value of pragma":
    for (source, mended) in [
      ("raise newException(ValueError, &\"Bad {x}.\")\n",
        "raise newException(ValueError, &\"Bad `{x}`.\")\n"),
      ("raiseAssert &\"Bad {x}.\"\n", "raiseAssert &\"Bad `{x}`.\"\n"),
      ("quit &\"Bad {x}.\"\n", "quit &\"Bad `{x}`.\"\n"),
      ("error(&\"Bad {x}.\", node)\n", "error(&\"Bad `{x}`.\", node)\n"),
      ("warning(fmt\"Bad {x}.\")\n", "warning(fmt\"Bad `{x}`.\")\n"),
      ("doAssert(x > 0, &\"Bad {x}.\")\n", "doAssert(x > 0, &\"Bad `{x}`.\")\n"),
      ("{.error: &\"Bad {X}.\".}\n", "{.error: &\"Bad `{X}`.\".}\n"),
      ("{.fatal: \"Bad \" & X & \".\".}\n", "{.fatal: \"Bad `\" & X & \"`.\".}\n"),
    ]:
      check source.found.len == 1
      check source.fixed == mended
    for kept in [
      "let m = &\"Count {n}.\"\n",  # no message site
      "let error = &\"Count {n}.\"\n",  # binding named as call
      "quit(1)\n",  # code, no message
      "doAssert x, message\n",  # message held by name, so no literal
    ]:
      check kept.isSettled


  test "operand takes backtick at end of literal before it, and start of one after":
    check "doAssert x, \"Bad \" & name & \" here.\"\n".fixed ==
      "doAssert x, \"Bad `\" & name & \"` here.\"\n"
    check "doAssert x, \"Bad name: \" & name\n".fixed ==
      "doAssert x, \"Bad name: `\" & name & \"`\"\n"  # operand ending message ends it on value
    check "doAssert x, \"Bad `\" & name & \"` here.\"\n".isSettled
    check "doAssert x, &\"Bad {{x}} here.\"\n".isSettled  # `{{` is no value


  test "value after `got` is rule of message value, so echo reports it not again":
    let tail = "doAssert x, &\"Bad {a}; got {b}.\"\n"
    check tail.found == @[
      (1, "Message echoes each value in backticks, so empty value stays visible; got `{a}`."),
    ]  # `{b}` is `checkMessages`'s
    check checkMessages("a.nim", tail).len == 1


  test "backtick that would widen held line stays, with its report":
    let wide = "doAssert x, &\"" & "w".repeat(76) & " {name}.\"\n"  # 99 runes
    check wide.found.len == 1
    check wide.fixed == wide
