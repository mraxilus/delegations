## Hold that definitions of one configuration standing next to each other share one block, and
##   that configuration build gets by default comes first (Article X.11), as Architect ruled on
##   rule 14 of #443: fix joins two blocks only where nothing stands between them, and swaps
##   branches of two-way `when` whose default stands last; definition never leaves its family.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, tables, unittest]
import ../../src/knoller/[chain, command, configurations, reports]


const
  ALGEBRA =
    "const\n  DIMENSIONS* {.define: \"pga.dimensions\".} = 4\n" &
    "  IS_CONFORMAL* {.define: \"pga.is_conformal\".} = false\n  IS_RIGID* = not IS_CONFORMAL\n"
    ## Lines 77 to 80 of `pga/algebra.nim` of PGA library at `3d9696e`: configuration constants.
  FORMAL =
    "type\n  Formal*[T] = object\n    when IS_CONFORMAL:\n      flat*, round*: T\n" &
    "    else:\n      round*: T\n"
    ## Lines 33 and 36 to 40 of `pga/cayleys.nim` at `3d9696e`, type section cut to `Formal`.
  SWAPPED =
    "type\n  Formal*[T] = object\n    when IS_RIGID:\n      round*: T\n" &
    "    else:\n      flat*, round*: T\n"
    ## `FORMAL` with its default first, as fix writes it.
  ORDER = "Configuration build gets by default comes first; got `"
    ## Opening of message of branch putting default last.
  JOIN = "Definitions of one configuration standing next to each other share one block; got `"
    ## Opening of message of blocks side by side.


func library(): Configurations =
  ## Read defaults of configurations of library, from its constants.
  readConfigurations([ALGEBRA])


func found(source: string): seq[(int, string)] =
  ## Read line and message of each report of configuration blocks in source.
  checkConfigurations("a.nim", source, library()).mapIt((it.line, it.message))


func fixed(source: string): string =
  ## Join and order configuration blocks of source, as `koch fix` does.
  fixConfigurations("a.nim", source, library()).source



suite "Configurations":
  test "constant read from define gives its default, and constant written `not` the other":
    let read = library()
    check read.defaults == {"IS_CONFORMAL": false, "IS_RIGID": true}.toTable
      # define of number names no configuration
    check read.complements == {"IS_CONFORMAL": "IS_RIGID", "IS_RIGID": "IS_CONFORMAL"}.toTable
    check readConfigurations([
      "const HAS_FORMS_DENSE* {.booldefine: \"pga_benchmark.has_forms_dense\".} = true\n",
    ]).defaults == {"HAS_FORMS_DENSE": true}.toTable  # line 45 of `measurements.nim` of benchmark
    let routine = readConfigurations(["proc p() =\n  ## Do.\n  let IS_X = not IS_CONFORMAL\n"])
    check routine.defaults.len == 0  # binding of routine names no configuration


  test "two-way branch putting default last reports, and fix swaps its branches":
    check FORMAL.found == @[(3, ORDER & "when IS_CONFORMAL:` first.")]
    check FORMAL.fixed == SWAPPED
    check SWAPPED.found.len == 0
    let own = readConfigurations(["const IS_FAST* {.booldefine.} = false\n"])
    check fixConfigurations("a.nim", "when IS_FAST:\n  a()\nelse:\n  b()\n", own).source ==
      "when not IS_FAST:\n  b()\nelse:\n  a()\n"  # no constant names complement
    check fixConfigurations("a.nim", "when not IS_FAST:\n  b()\nelse:\n  a()\n", own).fixed.len == 0


  test "branch whose default no define gives, or that holds no definition, passes":
    for kept in [
      "when defined(js):\n  a()\nelse:\n  b()\n",  # target sets symbol, so no define gives it
      "when IS_CONFORMAL:\n  a()\nelif DIMENSIONS > 3:\n  b()\nelse:\n  c()\n",  # three branches
      "proc p() =\n  ## Do.\n  when IS_CONFORMAL:\n    a()\n  else:\n    b()\n",  # inside routine
      "when IS_CONFORMAL: a()\nelse: b()\n",  # branches on lines of heads
    ]:
      check kept.found.len == 0
      check kept.fixed == kept


  test "blocks of one configuration side by side join, with blank lines between kept":
    let source = "when IS_CONFORMAL:\n  func a*() = discard\n\n\nwhen IS_CONFORMAL:\n" &
      "  func b*() = discard\n"
    check source.found == @[(5, JOIN & "when IS_CONFORMAL:` at lines `1` and `5`.")]
    check source.fixed == "when IS_CONFORMAL:\n  func a*() = discard\n\n\n  func b*() = discard\n"
    check source.fixed.found.len == 0
    check "when IS_CONFORMAL :\n  a()\nwhen IS_CONFORMAL:\n  b()\n".found.len == 1
      # spaces aside, one configuration


  test "blocks of one configuration apart, or not alike, stay":
    for kept in [
      "when IS_CONFORMAL:\n  a()\nb()\nwhen IS_CONFORMAL:\n  c()\n",  # definition between
      "when IS_CONFORMAL:\n  a()\n# Carriers.\nwhen IS_CONFORMAL:\n  c()\n",  # comment between
      "when IS_CONFORMAL:\n  a()\nelse:\n  b()\nwhen IS_CONFORMAL:\n  c()\n",  # other branch
      "when IS_RIGID:\n  a()\nwhen IS_CONFORMAL:\n  c()\n",  # family differing by configuration
      "when isMainModule:\n  a()\nwhen isMainModule:\n  c()\n",  # entry block, no configuration
    ]:
      check kept.found.len == 0
      check kept.fixed == kept


  test "chain and command line read defaults of package across its modules":
    check formatted("a.nim", FORMAL, Dialect.Module, configurations = library()).source.contains(
      "when IS_RIGID:"
    )
    check formatted("a.nim", FORMAL, Dialect.Module).source.contains("when IS_CONFORMAL:")
      # no defaults, no order
    let outcome = outcome(
      [("pga/algebra.nim", ALGEBRA), ("pga/cayleys.nim", FORMAL)], [], is_check = true,
      nimbles = {"pga/algebra.nim": "pga.nimble", "pga/cayleys.nim": "pga.nimble"}.toTable,
    )
    check outcome.lines.anyIt(it == "pga/cayleys.nim:3: configuration-block to fix")
