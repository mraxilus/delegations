## Hold each case that review of PGA library and delegate reports found, end to end: source as
##   found, comment naming where it came from, run through whole chain as `koch fix` runs it
##   (`formatted`), to exact output; second run writes nothing.
##   Parser of compiler proves needless parentheses. Case 2.2.12 reads rightly asks 2.2.12, which
##     builds this suite; case only commit pin of `ronri` projects reads, since it holds glyph
##     operators, asks stub of `stubs.nim`, which gives verdict that pin gives (checked
##     2026-10-05), since job of knoller runs 2.2.12 alone.
##   Lines quoted are as found; `strictFuncs` and enclosing suite, routine or block around them
##     only give them place to stand. Rulings cited are those of #533, PGA review of knoller.
##   Each case keeps its domain test in suite of its rule; this suite adds end-to-end form.

{.experimental: "strictFuncs".}

import std/[os, strutils, unittest]
import ../../src/knoller/[chain, command, proofs, reports]
import ./stubs


const
  NIM = getCurrentCompilerExe()  ## Compiler building suite, 2.2.12, whose parser answers.
  HEAD = "{.experimental: \"strictFuncs\".}\n\n"  ## Opening of module chain writes nothing to.
  DISTANCES =
    HEAD &
    "suite \"S\":\n" &
    "  test \"Equation 2.97-98\":\n" &
    "    when IS_RIGID:\n" &
    "      for 𝐦, 𝐧, _ in randMultivectors():\n" &
    "        let \n" &
    "          distance_a = (|∙ ⊖(𝐦 ∧ 𝐧)) div (|∙ (⊖𝐦 ∧ ⊖𝐧))\n" &
    "          distance_b = (|∙ ⊖(𝐦 ∧ 𝐧)) + (|∘ (𝐦 ∧ ⊖𝐧))\n" &
    "          distance_b_unitized = (^distance_b){Grade.scalar}\n" &
    "        check distance_a =~ distance_b_unitized\n"
    ## Lines 325 to 332 of `tests/suites.nim` of PGA library at `d9be8ae`, in suite.
  PRODUCT =
    HEAD &
    "func constructAnti(cayley: Cayley2D; complements: Chiral[Cayley1D]): Cayley2D" &
    " {.compileTime.} =\n" &
    "  ## Construct anti version of 2D cayley table by applying right (left) complement" &
    " before (after).\n" &
    "  for m in Basis:\n" &
    "    let m_from = complements.right[m].toSigned\n" &
    "    for n in Basis:\n" &
    "      let n_from = complements.right[n].toSigned\n" &
    "\n" &
    "      for term in cayley[m_from.basis][n_from.basis]:\n" &
    "        let product_to = complements.left[term.basis].toSigned\n" &
    "        result[m][n].add BasisSigned(\n" &
    "          basis: product_to.basis,\n" &
    "          is_negated: (\n" &
    "            m_from.is_negated xor\n" &
    "            n_from.is_negated xor\n" &
    "            term.is_negated xor\n" &
    "            product_to.is_negated\n" &
    "          )\n" &
    "        )\n"
    ## Lines 262 to 279 of `pga/cayleys.nim` at `d9be8ae`: chain of `xor` in call of line 271.
  ASSERTS =
    HEAD &
    "static:\n" &
    "  doAssert DIMENSIONS in 2..6,\n" &
    "    &\"Dimensionality should be in the range 2..6; got `{DIMENSIONS}`.\"\n" &
    "  doAssert IS_RIGID or DIMENSIONS >= 3,\n" &
    "    &\"Conformal Geometric Algebras must have dimensionality of 3 or more \" &\n" &
    "    &\"(2 Conformal + 1 Euclidean); got `{DIMENSIONS}`.\"\n"
    ## Lines 93 to 98 of `pga/algebra.nim` at `d9be8ae`: messages as chains of `&`.
  FILTERS =
    HEAD &
    "proc p() =\n" &
    "  block:\n" &
    "    for f in factors:\n" &
    "      let flags_overlap = f.toFlags and b_flags\n" &
    "      if ((as_exclusions and int(flags_overlap) != 0) or\n" &
    "          (not as_exclusions and int(flags_overlap) == 0)):\n" &
    "        should_filter = true\n"
    ## Lines 727 to 731 of `pga/cayleys.nim` at `d9be8ae`, in routine.
  TABLE =
    "## Property operators:\n" &
    "##   |-----|-------------------|-------------|\n" &
    "##   |Oper.| Name              | Lengyel     |\n" &
    "##   |-----|-------------------|-------------|\n" &
    "##   | ⊖  | attitude          | att(𝐦)      |\n" &
    "##   | ⊟  | carrier         † | car(𝐦)      |\n" &
    "##   | ⊞  | cocarrier       † | ccr(𝐦)      |\n" &
    "##   | ⊙  | center          † | cen(𝐦)      |\n" &
    "##   | ⊡  | container       † | con(𝐦)      |\n" &
    "##   | ⊛  | partner         † | par(𝐦)      |\n" &
    "##   | ∩   | support           | sup(𝐦)      |\n" &
    "##   | ∪   | supportAnti       | asp(𝐦)      |\n" &
    "##   |-----|-------------------|-------------|\n" &
    "\n" &
    "{.experimental: \"strictFuncs\".}\n"
    ## Lines 89 to 101 of `pga.nim` at `d9be8ae`, operator table of module doc (#526).
  DIGITS =
    HEAD &
    "func toDigits(b: Basis): BasisDigits {.compileTime, noinit.} =\n" &
    "  ## Convert basis to ordered digit representation.\n" &
    "  toBasisDigits(($b)[1 .. ^1])\n"
    ## Lines 268 to 270 of `pga/algebra.nim` at `d9be8ae`.
  PARITY =
    HEAD &
    "func isNegatedFromOrderLexicographic(b: Basis): bool {.compileTime.} =\n" &
    "  ## Determine if canonically ordered basis is negated relative to lexicographical" &
    " order.\n" &
    "  const lut_parity_by_basis = block:\n" &
    "    var lut: array[Basis, bool]\n" &
    "    for basis in Basis:\n" &
    "      let digits = basis.toDigits\n" &
    "      var inversions = 0\n" &
    "      for i in 0..<len(digits):\n" &
    "        for j in i + 1 ..< len(digits):\n" &
    "          if digits[i] > digits[j]:\n" &
    "            inversions += 1\n" &
    "      result[basis] = inversions mod 2 == 1\n" &
    "    lut\n" &
    "  lut_parity_by_basis[b]\n"
    ## Lines 800 to 810 of `pga/cayleys.nim` at `d9be8ae`, routine closed after.
  ELEMENTS =
    HEAD &
    "var MULTIVECTORS: array[SAMPLES, Multivector]\n" &
    "for i in 1 .. len(ELEMENTS): MULTIVECTORS[i] = ELEMENTS[Basis(i - 1)]\n"
    ## Lines 29 and 30 of `tests/suites.nim` at `d9be8ae`.
  SCALAR =
    HEAD &
    "template scalar*[I: Basis | Grade | GradeAnti](t: typedesc[I]): I = I.low\n" &
    "  ## Alias scalar's basis and (anti)grade indices (e.g. `Basis.low`).\n"
    ## Lines 312 and 313 of `pga/algebra.nim` at `d9be8ae`.
  BORROWS =
    HEAD &
    "# Borrow functions for performing basic operations on grades.\n" &
    "template borrowGradeOperations(T: typedesc) =\n" &
    "  func `-`*(g, h: T): T {.borrow.}\n" &
    "  func `*`*(g, h: T): T {.borrow.}\n" &
    "  func `+`*(g, h: T): T {.borrow.}\n" &
    "  func `<`*(g, h: T): bool {.borrow.}\n" &
    "  func `<=`*(g, h: T): bool {.borrow.}\n" &
    "  func `==`*(g, h: T): bool {.borrow.}\n" &
    "borrowGradeOperations(Grade)\n" &
    "borrowGradeOperations(GradeAnti)\n"
    ## Lines 125 to 134 of `pga/algebra.nim` at `d9be8ae` (ruling 4 of #533).
  ENUM =
    HEAD &
    "func emitEnumBasis(vectors: seq[BasisDigits]): NimNode {.compileTime, noinit.} =\n" &
    "  ## Emit enum to represent bases for a `dimensions`-dimensional PGA.\n" &
    "  newEnum(\n" &
    "    ident\"Basis\",\n" &
    "    fields = vectors.map(b => ident(b.toBasisName)),\n" &
    "    public = true,\n" &
    "    pure = true,\n" &
    "  )\n"
    ## Lines 209 to 216 of `pga/algebra.nim` at `d9be8ae`: `newEnum(` call of line 211.
  ANTI =
    HEAD &
    "func constructAnti(cayley: Cayley1D; complements: Chiral[Cayley1D]): Cayley1D" &
    " {.compileTime.} =\n" &
    "  ## Construct anti version of 1D cayley table by applying right (left) complement" &
    " before (after).\n" &
    "  for b in Basis:\n" &
    "    let b_from = complements.right[b].toSigned\n" &
    "\n" &
    "    for term in cayley[b_from.basis]:\n" &
    "      let b_to = complements.left[term.basis].toSigned\n" &
    "      result[b].add BasisSigned(\n" &
    "        basis: b_to.basis, is_negated: b_from.is_negated xor term.is_negated xor" &
    " b_to.is_negated\n" &
    "      )\n"
    ## Lines 250 to 259 of `pga/cayleys.nim` at `d9be8ae`: `BasisSigned(` call of line 257.
  INTERIOR =
    HEAD &
    "proc p() =\n" &
    "  block:\n" &
    "    block:\n" &
    "      for term in product:\n" &
    "        result[a][b].add(BasisSigned(\n" &
    "          basis: term.basis,\n" &
    "          is_negated: dual_signed.is_negated xor term.is_negated,\n" &
    "        ))\n"
    ## Lines 389 to 393 of `pga/cayleys.nim` at `d9be8ae`, in routine.
  ALGEBRAS =
    HEAD &
    "proc p() =\n" &
    "  block:\n" &
    "      for i in 1 ..< len(prev):\n" &
    "        curr.add(prev[i] & prev[i-1].map(digits => digits & digit_new))\n"
    ## Lines 179 and 180 of `pga/algebra.nim` at `d9be8ae`, in routine.
  WEDGES =
    HEAD &
    "proc p() =\n" &
    "  block:\n" &
    "        check (∙𝐦 + ∘𝐦 + ■𝐦 + □𝐦) ∧ (∙𝐧 + ∘𝐧 + ■(𝐧) + □(𝐧)) =~ 𝐦 ∧ 𝐧  # 2.68\n"
    ## Line 258 of `tests/suites.nim` at `d9be8ae`, in routine.
  MASK =
    HEAD &
    "proc p() =\n" &
    "    let\n" &
    "      mask = not ((2'u^(DIMENSIONS)) - 1)\n" &
    "      digits_invalid = (flags and mask)\n"
    ## Lines 256 to 258 of `pga/algebra.nim` at `d9be8ae`, in routine.
  FLAGS =
    HEAD &
    "  ## Convert digits to binary flag representation of present 1-vectors.\n" &
    "  var flags = 0'u\n" &
    "  for i in 1 .. DIMENSIONS:\n" &
    "    if char(ord('0')+i) in b:\n" &
    "      flags = flags or (1'u shl (i-1))\n" &
    "  toBasisFlags(flags)\n"
    ## Lines 284 to 289 of `pga/algebra.nim` at `d9be8ae`.
  COMPLEMENTS =
    HEAD &
    "proc p() =\n" &
    "  for b, 𝐮 in enumerateBasis():\n" &
    "      check \\(/𝐮) =~ 𝐮  # 2.22a\n"
    ## Line 194 of `tests/suites.nim` at `d9be8ae`, in its loop.
  NORMALIZED =
    HEAD &
    "proc p() =\n" &
    "  block:\n" &
    "    block:\n" &
    "        if 𝑡 != 0:\n" &
    "          check ^(|𝐦) =~ initElement(Basis.scalar, 𝐬/𝑡) + 𝟙  # 2.94\n"
    ## Lines 319 and 320 of `tests/suites.nim` at `d9be8ae`, in routine.
  LINKS =
    HEAD &
    "proc p() =\n" &
    "  block:\n" &
    "    while true:\n" &
    "      let\n" &
    "        task = SETTLES[i]\n" &
    "        links = @(PAIRS[task.pair][0])\n" &
    "        is_away = PAIRS[task.pair][1]\n"
    ## Lines 77 to 80 of `tests/test_read.nim` of `dance_ontology` (#539), in routine.
  ANTISCALAR =
    HEAD &
    "proc p() =\n" &
    "  block:\n" &
    "      var 𝐮̅ = /𝐮\n" &
    "      for c in Basis:\n" &
    "        𝐮̅[c] = float(-1^(int(b.grade) * int(b.gradeAnti))) * 𝐮̅[c]\n" &
    "      check \\𝐮 =~ 𝐮̅\n"
    ## Lines 186 to 189 of `tests/suites.nim` at `d9be8ae`, in routine.
  BARE = HEAD & "func f(): bool =\n  a or\n      b\n"
    ## Value that ends routine, as Architect answered on ruling 2.
  HEADED =
    HEAD & "proc p() =\n  if check(a_long_name, first_condition or second_condition or\n" &
    "    second_condition and first_condition):\n    echo a_long_name\n"
    ## Block head of ruling 10, whose last line stands at body's indent.
  SIGILS = HEAD & "let\n  s = @(x.items)\n  t = @(f(a))\n  u = @@(x[0])\n  v = @(x)\n"
    ## Cases of #541, test commit `8bb10aea`, under one `let`.
  POWERS = HEAD & "let\n  p = -1 ^ (k)\n  q = -1 ^ (a * b)\n  r = a ^ -b\n"
    ## Examples of ruling 12, as Architect corrected them, under one `let`.
  MESH =HEAD &
    "proc p() =\n" &
    "  block:\n" &
    "    for _ in 0 ..< samples_views:\n" &
    "      # Plane through centre near origin, arms square to its normal at radius one to" &
    " eight.\n" &
    "      let\n" &
    "        normal_unit = unitDrawn(generator)\n" &
    "        along = normalize(cross(normal_unit, unitDrawn(generator))).get\n" &
    "        radius = generator.rand(1.0 .. 8.0)\n" &
    "        arm_first = radius*along\n" &
    "        arm_second = radius*cross(normal_unit, along)\n" &
    "        centre = Position(\n" &
    "          x: generator.rand(-5.0 .. 5.0), y: generator.rand(-5.0 .. 5.0),\n" &
    "          z: generator.rand(-5.0 .. 5.0),\n" &
    "        )\n" &
    "        record = DiscRecord(\n" &
    "          centre_x: float32(centre.x), centre_y: float32(centre.y), centre_z:" &
    " float32(centre.z),\n" &
    "          arm_first_x: float32(arm_first.x), arm_first_y: float32(arm_first.y),\n" &
    "          arm_first_z: float32(arm_first.z), arm_second_x: float32(arm_second.x),\n" &
    "          arm_second_y: float32(arm_second.y), arm_second_z: float32(arm_second.z),\n" &
    "          fill_alpha: 1.0,\n" &
    "        )\n" &
    "      # Eye over or under plane, low in half of views, so vanishing line runs through" &
    " view.\n" &
    "      let\n" &
    "        height = (if generator.rand(1.0) < 0.5: generator.rand(0.001 .. 0.5)\n" &
    "          else: generator.rand(0.5 .. 3.0))*radius*(if generator.rand(1.0) < 0.5: -1.0" &
    " else: 1.0)\n" &
    "        offset_across = generator.rand(-1.5 .. 1.5)*radius\n" &
    "        offset_along = generator.rand(-1.5 .. 1.5)*radius\n"
    ## Lines 516 to 540 of `tests/suites/test_mesh.nim` of `rga_visualiser` at `a440fb8` (#521),
    ##   in routine; line 538 of file is line 27 here.
  STUB =
      "discard \"\"\"\n" &
      "action: run\n" &
      "cmd: \"nim c -r --hints:on -d:testing -d:nimUnittestAbortOnError:on $options $file\"\n" &
      "matrix: \"-d:pga.dimensions=3 -d:pga.is_conformal=false\"\n" &
      "\"\"\"\n" &
      "include \"../suites.nim\""
    ## Whole `tests/rga3d/test_rga3d.nim` of PGA library at `d9be8ae`, no newline after its last
    ##   line (#443).


var KNOWN = Proofs()  ## Answers of parser by source, held across cases, as one run holds them.


proc fixedBy(source: string; prover: Prover): Fix =
  ## Fix module source by whole chain, as `koch fix` does: ask parser what chain asks, and fix
  ##   again, until chain asks nothing.
  for ask in 0 .. 8:
    result = formatted("a.nim", source, Dialect.Module, KNOWN)
    if result.asked.len == 0: return
    discard KNOWN.answered(result.asked, prover)


template holds(found, mended: string; prover: Prover = proverCompiler(NIM)) =
  ## Check that found fixes to mended, and that mended fixes to itself, reporting nothing.
  block:
    check fixedBy(found, prover).source == mended
    let again = fixedBy(mended, prover)
    check again.source == mended and again.fixed.len == 0  # second run writes nothing



suite "Regressions":
  test "1. prefix operators never merge (#521)":
    holds DISTANCES, DISTANCES.replace("let \n", "let\n").replace(
      "(|∙ ⊖(𝐦 ∧ 𝐧)) div (|∙ (⊖𝐦 ∧ ⊖𝐧))", "|∙ ⊖(𝐦 ∧ 𝐧) div |∙(⊖𝐦 ∧ ⊖𝐧)",
    ).replace(
      "(|∙ ⊖(𝐦 ∧ 𝐧)) + (|∘ (𝐦 ∧ ⊖𝐧))", "|∙ ⊖(𝐦 ∧ 𝐧) + |∘(𝐦 ∧ ⊖𝐧)",
    ), proverStub  # `|∙⊖` would lex one operator, so space stays; stub as commit pin
    holds HEAD & "let x = - -y\n", HEAD & "let x = - -y\n"  # `- -x` of #521; `--` one token
    holds HEAD & "let y = - 1\n", HEAD & "let y = - 1\n"  # `-1` would lex one literal (#521)


  test "2. comment table with glyphs stays as written (#526)":
    holds TABLE, TABLE  # rows `| ⊖  |` and `| ∩   |`, padded as hand's font shows them


  test "3. chains stay flat at their first piece, and block head keeps four spaces":
    holds ASSERTS, ASSERTS  # message chain of `doAssert IS_RIGID or DIMENSIONS >= 3,` (ruling 2)
    holds PRODUCT, PRODUCT.replace("Cayley2D; complements", "Cayley2D, complements").replace(
      "          )\n        )\n", "          ),\n        )\n",
    )  # chain of `xor` after `is_negated: (` stays flat (ruling 2)
    holds FILTERS, FILTERS  # `if (...) or` keeps four spaces (ruling 10)
    holds BARE, BARE  # bare value opening its statement line keeps four spaces
    holds HEADED, HEADED.replace(
      "    second_condition and first_condition):",
      "      (second_condition and first_condition)):",
    )  # gap moves to four spaces, and `and` beside `or` takes parentheses (X.4)


  test "4. range takes no space, but beside binary piece or before prefix (ruling 3)":
    holds HEAD & "let r = 2 .. 6\n", HEAD & "let r = 2..6\n"
    holds HEAD & "let b = x in 2 .. 6\n", HEAD & "let b = x in 2..6\n"
    holds DIGITS, DIGITS  # `[1 .. ^1]`: `..^` would lex one operator
    holds PARITY, PARITY  # `for j in i + 1 ..< len(digits)`: piece holds binary `+`


  test "5. symbol operator in bracket glued to operand takes no space (ruling 5)":
    holds HEAD & "let a = prev[i - 1]\n", HEAD & "let a = prev[i-1]\n"
    holds ELEMENTS, ELEMENTS.replace("1 .. len", "1..len").replace("(i - 1)", "(i-1)")
    holds SCALAR, SCALAR  # generic list of routine is declaration, so `|` keeps its spaces


  test "6. one-line routines stay stacked, with no blank line (ruling 4)":
    holds BORROWS, BORROWS  # template `borrowGradeOperations` of `algebra.nim`


  test "7. call keeps hand's breaks, and group one item to line takes trailing comma":
    holds ENUM, ENUM.replace(" for a `", " for `")  # split by its trailing comma; X.9 articles
    holds ANTI, ANTI.replace("Cayley1D; complements", "Cayley1D, complements")  # breaks kept
    holds PRODUCT, PRODUCT.replace("Cayley2D; complements", "Cayley2D, complements").replace(
      "          )\n        )\n", "          ),\n        )\n",
    )  # block of line 271 keeps its flat chain and gains `),`


  test "8. dotted call statement takes command form, where its argument is one call":
    holds INTERIOR, INTERIOR.replace(".add(BasisSigned(", ".add BasisSigned(").replace(
      "        ))\n", "        )\n",
    )
    holds ALGEBRAS, ALGEBRAS.replace("1 ..< len", "1..<len")  # `curr.add(a & b)` stays


  test "9. parentheses go where parser proves it, three kinds, and stay where it does not":
    holds WEDGES, WEDGES.replace("■(𝐧) + □(𝐧)", "■𝐧 + □𝐧"), proverStub  # after prefix
    holds MASK, MASK.replace("2'u^(DIMENSIONS)", "2'u^DIMENSIONS")  # beside binary operator
    holds LINKS, LINKS  # `@PAIRS[task.pair][0]` reads `(@PAIRS)[task.pair][0]` (#539)
    holds SIGILS, SIGILS.replace("@(x)\n", "@x\n")  # bare operand alone goes
    holds FLAGS, FLAGS.replace("1 .. DIM", "1..DIM").replace("'0')+i", "'0') + i").replace(
      "(i-1)", "(i - 1)",
    ).replace("toBasisFlags(flags)", "flags.toBasisFlags")  # `1'u shl (i-1)` group stays
    holds HEAD & "let x = b + -(1)\n", HEAD & "let x = b + -(1)\n"  # literal `-1` (ruling 11)
    holds COMPLEMENTS, COMPLEMENTS, proverStub  # `\/` would lex one operator
    holds NORMALIZED, NORMALIZED.replace("𝐬/𝑡", "𝐬 / 𝑡"), proverStub  # `^(|𝐦)` stays
    holds HEAD & "let z = a - (-b) -1\n", HEAD & "let z = a - (-b) -1\n"  # callee of command


  test "10. power operator is tight, and exponent that would merge takes parentheses (ruling 12)":
    holds POWERS, HEAD & "let\n  p = -1^k\n  q = -1^(a * b)\n  r = a^(-b)\n"
    holds ANTISCALAR, ANTISCALAR, proverStub  # `float(-1^(int(b.grade) * int(b.gradeAnti)))`


  test "11. each report prints at its line in file as given (#521)":
    let outcome = outcomeOf([("tests/suites/test_mesh.nim", MESH)], [], is_check = true)
    check outcome.lines == @[
      "tests/suites/test_mesh.nim:5: expression-spacing to fix",
      "tests/suites/test_mesh.nim:10: expression-spacing to fix",
      "tests/suites/test_mesh.nim:11: expression-spacing to fix",
      "tests/suites/test_mesh.nim:12: expression-spacing to fix",
      "tests/suites/test_mesh.nim:13: call-wrapping to fix",
      "tests/suites/test_mesh.nim:14: expression-spacing to fix",
      "tests/suites/test_mesh.nim:14: expression-spacing to fix",
      "tests/suites/test_mesh.nim:15: expression-spacing to fix",
      "tests/suites/test_mesh.nim:17: call-wrapping to fix",
      "tests/suites/test_mesh.nim:26: expression-spacing to fix",
      "tests/suites/test_mesh.nim:27: expression-spacing to fix",
      "tests/suites/test_mesh.nim:27: expression-spacing to fix",
      "tests/suites/test_mesh.nim:27: expression-spacing to fix",
      "tests/suites/test_mesh.nim:28: expression-spacing to fix",
      "tests/suites/test_mesh.nim:28: expression-spacing to fix",
      "tests/suites/test_mesh.nim:29: expression-spacing to fix",
      "tests/suites/test_mesh.nim:29: expression-spacing to fix",
      "17 to fix.",
    ]  # line 538 prints as 27, where fixed text holds it at 33, after six lines calls insert
    let written = outcomeOf([("tests/suites/test_mesh.nim", MESH)], [], is_check = false).written
    check written[0][1].splitLines[32].startsWith("          else: generator.rand(0.5..3.0)) * ")
    check outcomeOf(written, [], is_check = false).lines == @["0 fixed."]  # second run


  test "12. stub inside category of `tests` takes stub rules, as testament reads it (#443)":
    let mended = STUB.replace(" -r ", " ").replace(
      "\"\"\"\ninclude",
      "\"\"\"\n\n" & HEAD & "when compileOption(\"profiler\"): import std/nimprof\n\ninclude",
    ) & "\n"
    for path in ["tests/rga3d/test_rga3d.nim", "tests/test_rga3d.nim"]:
      check outcomeOf([(path, STUB)], [], is_check = true).lines == @[
        path & ": file-ending to fix",
        path & ": profiler-import to fix",
        path & ": strictfuncs to fix",
        path & ":3: stub-keys to fix",
        "4 to fix.",
      ]  # stub of category reports as stub directly under `tests` does
      let written = outcomeOf([(path, STUB)], [], is_check = false).written
      check written == @[(path, mended)]
      check outcomeOf(written, [], is_check = false).lines == @["0 fixed."]  # second run
