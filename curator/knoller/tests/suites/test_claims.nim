## Hold that each claim of comment opens with capital and closes with period, and each path,
##   literal and name of comment stands in backticks (Article VI.10), as Architect ruled on rule 2
##   of #443.
##   Lowercase line two spaces deeper wraps sentence above, line with no closing mark before
##     capitalised line takes no report, citation of charter stands bare, and generated doc is
##     unread.
##   Fix writes each backtick, period and capital it can, and nothing second time.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/knoller/[chain, claims, reports, tokens]


const
  BORROWS =
    "# Borrow necessary functions for using distinct types (i.e. for added type safety).\n" &
    "#   Ideally Nim would have feature to auto borrow everything, but prevent interop.\n" &
    "func `&`(a, b: BasisDigits): BasisDigits {.borrow, compileTime.}\n" &
    "func `and`(a, b: BasisFlags): BasisFlags {.borrow, compileTime, used.}  # Used in " &
    "cayleys.nim.\n" &
    "func `not`(a: BasisFlags): BasisFlags {.borrow, compileTime, used.}  # Used in " &
    "cayleys.nim.\n" &
    "func `xor`(a, b: BasisFlags): BasisFlags {.borrow, compileTime, used.}  # Used in " &
    "cayleys.nim.\n" &
    "func countSetBits(b: BasisFlags): int {.borrow, compileTime.}\n" &
    "func len(b: BasisDigits): int {.borrow, compileTime.}\n" &
    "iterator items(b: BasisDigits): char = (for d in string(b): yield d)\n" &
    "template `[]`(b: BasisDigits, i: int): char {.used.} = string(b)[i]  # Used in " &
    "cayleys.nim.\n" &
    "template `in`(c: char, b: BasisDigits): bool = c in string(b)\n"
    ## Lines 117 to 127 of `pga/algebra.nim` of PGA library at `3d9696e`.
  TO_BASIS =
    "func toBasis(b: BasisDigits): Basis {.compileTime, noinit, used.} =  # Used in " &
    "\"cayleys.nim\".\n" &
    "  ## Convert digit representation of basis to associated basis.\n"
    ## Lines 229 and 230 of `pga/algebra.nim` at `3d9696e`.
  CAYLEY =
    "  Cayley2D* =  ## Define data structure for constructing binary algebra operations.\n" &
    "    array[Basis, array[Basis, seq[BasisSigned]]]  # Support conformal operators with " &
    "`seq`.\n" &
    "    # TODO: Avoid seq as heap allocated, perhaps array with count custom type.\n" &
    "    #   Applies especially for 1D which only uses singular slot.\n"
    ## Lines 23 to 26 of `pga/cayleys.nim` at `3d9696e`.
  SUBTYPES =
    "macro defineMultivectors(): untyped =\n" &
    "  ## Define specialized subtypes for n-dimensional PGA.\n" &
    "  ##   This indirection is necessary as enums must be contiguous (e.g. for " &
    "scalars/even/odd).\n" &
    "  ##     The ideal would be using sub ranges (e.g. E1..E4 for grade 1, E41..E12 for " &
    "grade 2).\n"
    ## Lines 33 to 36 of `pga/multivectors.nim` at `3d9696e`, trailing space of line 33 dropped.
  INDEX =
    "func index[B: static Bases](b: Basis): range[0 .. B.card-1] {.inline, noinit.} =\n" &
    "  ## Convert basis to subset index.\n" &
    "  ##   Note: returns range instead of int, avoiding uncecessary checks in generated output.\n"
    ## Lines 90 to 92 of `pga/multivectors.nim` at `3d9696e`.
  EQUATIONS =
    "  test \"Equation 2.13\":\n" &
    "    var 𝐦 = ELEMENTS[Basis.scalar.succ]  # 1'e1\n" &
    "    for b in Basis:\n" &
    "      if b.grade == Grade(1) and b != Basis.scalar.succ:\n" &
    "        𝐦 = 𝐦 ∧ ELEMENTS[b]  # 1'e1 ∧ 1'e2 ∧ ... ∧ 1'en\n"
    ## Lines 166 to 170 of `tests/suites.nim` at `3d9696e`.
  ORDERING =
    "func constructAlgebra(dimensions: int): Algebra {.compileTime, noinit.} =\n" &
    "  ## Construct algebra for `dimensions`-dimensional PGA.\n" &
    "  ##   Follow Lengyel's basis convention as opposed to lexicographic ordering.\n" &
    "  ##     For pedagogical interop with standard linear algebra and related math.\n" &
    "  ##   Differences from lexicographical ordering:\n" &
    "  ##     Order 3D 2-vectors by which basis does NOT appear (e₂₃, e₃₁, e₁₂).\n" &
    "  ##       Matches with quaternion imaginary units i, j, k.\n" &
    "  ##     Order 3D antiscalar in decending order (e₃₂₁),\n" &
    "  ##       so motors can be sum of sin/cos instead of difference.\n" &
    "  ##     Order 4D 2/3-vectors to align as right complements of basis vectors,\n" &
    "  ##       to consider 4x4 transformation matrix rows as planes, columns as points.\n"
    ## Lines 156 to 166 of `pga/algebra.nim` at `3d9696e`: lines 163 and 165 wrap lowercase.
  OPERATORS =
    "## Source files ordered to be read as reference, with optimized compiled representation.\n" &
    "## This file serves as documentation for underlying operators provided in " &
    "`operators.nim`.\n" &
    "##   Each operator is also documented in case symbols are non-obvious for those " &
    "unfamiliar.\n" &
    "## Each operator has human readable aliases for external use.\n" &
    "##   Operators use symbols as base form to simplify equations at cost of typability.\n" &
    "##   E.g. (∙𝐦 + ∘𝐦) ∨ (∙𝐧 + ∘𝐧) vs (bulk(𝐦) + weight(𝐦)).antiWedge(bulk(𝐧) + weight(𝐧))\n" &
    "##   All operators and aliases should have documentation.\n" &
    "##     Operators' documentation should specify what operator is and is called.\n"
    ## Lines 25 to 32 of `pga.nim` at `3d9696e`: line 30 has no closing mark.
  CARRIER =
    "when IS_CONFORMAL:\n" &
    "  func carrier*(m: Multivector): Multivector {.inline.} = ⊟m\n" &
    "    ## Get carrier of multivector as lowest dimensional flat object containing it, " &
    "i.e. 𝐦 ∧ eₙ.\n" &
    "    ##   Has effect of annihilating flat part of multivector as eₙ ∧ eₙ = 0,\n" &
    "    ##   Also add eₙ to each round component, making it flat geometry.\n" &
    "    ##   Carrrier contains center of original multivector.\n"
    ## Lines 226 to 231 of `pga.nim` at `3d9696e`: line 229 has no closing mark.
  GENERATED =
    "    # Construct UFCS basis element constructor function.\n" &
    "    result.add emitFunc(\n" &
    "      name = toLower($b),\n" &
    "      docs = &\"Initialize multivector as singular {b} basis element via UFCS " &
    "shorthand.\",\n" &
    "    )\n"
    ## Lines 155 to 158 of `pga/multivectors.nim` at `3d9696e`, call closed below them.
  SCALARS =
    "# TODO: Add sqrt, abs, div, exp, etc. to library when homogeneous scalars are in.\n" &
    "func sqrt(m: Multivector): MultivectorScalars =\n" &
    "  ## Find square root of dual number, i.e. √𝐦.\n\n\n" &
    "# TODO: Define to converters for every compatible multivector forms.\n" &
    "#   I.e. for all compatible demotions and promotion to full multivector.\n"
    ## Lines 68 to 70 of `tests/suites.nim`, and lines 240 and 241 of `pga/multivectors.nim`, at
    ##   `3d9696e`.
  COMMENTED =
    "    # var elements = newNimNode(nnkCurly)\n" &
    "    # for b in constructVectorParity(is_odd):\n" &
    "    #   elements.add nnkDotExpr.newTree(ident\"Basis\", ident($b))\n" &
    "    let bases = constructVectorParity(is_odd)\n\n\n" &
    "# func `=~`*(m, n: Multivector): bool =\n" &
    "#   ## Compare approximate equality between multivectors, i.e. 𝐦 ≈ 𝐧.\n" &
    "#   for b in Basis:\n" &
    "#     if not (m[b] =~ n[b]):\n" &
    "#       return false\n" &
    "#   true\n\n" &
    "    # when IS_RIGID: skip()\n" &
    "    # when IS_CONFORMAL:\n" &
    "    #   for 𝐦, 𝐧, 𝐨 in sampleMultivectors():\n"
    ## Lines 69 to 72 and 211 to 216 of `pga/multivectors.nim`, and lines 433 to 435 of
    ##   `tests/suites.nim`, at `3d9696e`: code commented one space past marker.
  LIBRARY = [
    BORROWS, TO_BASIS, CAYLEY, SUBTYPES, INDEX, EQUATIONS, ORDERING, OPERATORS, CARRIER,
    GENERATED, SCALARS, COMMENTED,
  ]
    ## Each excerpt of library above, which laws of fix read.


func found(source: string): seq[(int, string)] =
  ## Read line and message of each report of comment form in source.
  checkClaims("a.nim", source).mapIt((it.line, it.message))


func fixed(source: string): string =
  ## Write each fix of comment form, as `koch fix` does.
  fixClaims("a.nim", source).source


func isSettled(source: string): bool =
  ## Decide whether source reports no comment form and fixes to itself again.
  checkClaims("a.nim", source).len == 0 and source.fixed == source


func spellingsCode(source: string): seq[string] =
  ## Read spelling of each token of source but comments, in order.
  for t in source.tokens:
    if t.kind != KindToken.Comment: result.add t.spelling(source)



suite "Claims":
  test "path, literal and name of library take backticks, and quoted path trades quotes":
    check BORROWS.found == [4, 5, 6, 10].mapIt(
      (it, "Path in comment stands in backticks; got `cayleys.nim`.")
    )  # lines 120, 121, 122 and 126 of `pga/algebra.nim`
    check BORROWS.fixed == BORROWS.replace("# Used in cayleys.nim.", "# Used in `cayleys.nim`.")
    check TO_BASIS.found == @[
      (1, "Path in comment stands in backticks; got `\"cayleys.nim\"`."),
    ]  # line 229 of `pga/algebra.nim`
    check TO_BASIS.fixed == TO_BASIS.replace("\"cayleys.nim\"", "`cayleys.nim`")
    check CAYLEY.found == @[(3, "Name in comment stands in backticks; got `seq`.")]
    check CAYLEY.fixed == CAYLEY.replace("Avoid seq as", "Avoid `seq` as")
    check SUBTYPES.found == @[
      (4, "Literal in comment stands in backticks; got `E1..E4`."),
      (4, "Literal in comment stands in backticks; got `E41..E12`."),
    ]  # line 36 of `pga/multivectors.nim`
    check SUBTYPES.fixed == SUBTYPES.replace(
      "(e.g. E1..E4 for grade 1, E41..E12 for", "(e.g. `E1..E4` for grade 1, `E41..E12` for"
    )
    check INDEX.found == @[(3, "Name in comment stands in backticks; got `int`.")]
    check INDEX.fixed == INDEX.replace("instead of int,", "instead of `int`,")  # range is word
    check EQUATIONS.found == @[
      (2, "Literal in comment stands in backticks; got `1'e1`."),
      (5, "Literal in comment stands in backticks; got `1'e1 ∧ 1'e2 ∧ ... ∧ 1'en`."),
    ]  # lines 167 and 170 of `tests/suites.nim`: literals operators part take one pair
    check EQUATIONS.fixed ==
      "  test \"Equation 2.13\":\n" &
      "    var 𝐦 = ELEMENTS[Basis.scalar.succ]  # `1'e1`\n" &
      "    for b in Basis:\n" &
      "      if b.grade == Grade(1) and b != Basis.scalar.succ:\n" &
      "        𝐦 = 𝐦 ∧ ELEMENTS[b]  # `1'e1 ∧ 1'e2 ∧ ... ∧ 1'en`\n"


  test "lowercase line two spaces deeper wraps sentence above, and is no claim":
    check ORDERING.isSettled  # lines 163 and 165 of `pga/algebra.nim`, as ruling quotes them
    check "## Read file,\n##   then write it.\n".isSettled
    check "# Cost: one fetch,\n#         paid once.\n".isSettled  # two spaces past tag's sentence


  test "line with no closing mark before line of same depth takes no report":
    check OPERATORS.isSettled  # line 30 of `pga.nim`, before capitalised line 31
    check CARRIER.isSettled  # line 229 of `pga.nim`, which ends with comma
    check "## Read file\n## Write it.\n".isSettled


  test "citation of charter stands bare, and path with folder takes backticks":
    for kept in [
      "## Read once, as STYLE.md §5 asks.\n",
      "## Read once, as PROVENANCE.md, Fences, says.\n",
      "## Read once (`curator/audit/PROVENANCE.md`, Fixes).\n",
    ]:
      check kept.isSettled
    let folder = "## Read once, as curator/audit/PROVENANCE.md says.\n"
    check folder.found == @[
      (1, "Path in comment stands in backticks; got `curator/audit/PROVENANCE.md`."),
    ]
    check folder.fixed == "## Read once, as `curator/audit/PROVENANCE.md` says.\n"
    check "## Read cayleys.nim, then lexer.nim.\n".fixed ==
      "## Read `cayleys.nim`, then `lexer.nim`.\n"
    check "## Read draw/ once.\n".fixed == "## Read `draw/` once.\n"  # folder that slash closes
    check "## draw/ chain reads it.\n".fixed == "## `draw/` chain reads it.\n"  # no capital
    check "## Run under Node.js once.\n".isSettled  # product name


  test "generated doc stands in string, so rule reads none":
    check GENERATED.isSettled  # line 158 of `pga/multivectors.nim`, as ruling quotes it
    check "emitFunc(name = \"f\", docs = \"convert seq\")\n".isSettled


  test "claim opens with capital and closes with period, past tag and bullet":
    let doc = "proc f() =\n  ## convert basis to index\n  discard\n"
    check doc.found == @[
      (2, "Claim of comment opens with capital; got `convert`."),
      (2, "Claim of comment closes with period; got `index`."),
    ]
    check doc.fixed == "proc f() =\n  ## Convert basis to index.\n  discard\n"
    let bullets = "# Steps:\n#   - read file,\n#   - write file\n"
    check bullets.found == @[(3, "Claim of comment closes with period; got `file`.")]
    check bullets.fixed == "# Steps:\n#   - read file,\n#   - write file.\n"
      # bullet may open in lowercase, as one that ends sentence of line above
    check "# Steps:\n#   - Read file.\n#   - Write file.\n".isSettled  # as VIII writes them
    check "## e.g. one.\n".fixed == "## E.g. one.\n"  # capitalised where it opens sentence
    check "proc f() =\n  ## Read basis\n  ##   Then index.\n  discard\n".isSettled  # wrap
    check "## Read basis.\n##   Then index\n## Write it.\n".fixed ==
      "## Read basis.\n##   Then index.\n## Write it.\n"  # claim ends before shallower line
    for kept in [
      "# TODO: avoid copy.\n",  # tag opens claim
      "## Order of bootstrapping:\n##   [Algebra, BasisDigits] -> Basis\n",  # colon, diagram
      "## Read (see above.)\n",  # mark inside bracket
      "## Read all…\n",
      "## Is it read?\n",
    ]:
      check kept.isSettled


  test "claim cut short stays for hand, as fix would hide cut":
    check "## Read file of\n".found == @[
      (1, "Claim of comment ends cut short, so hand closes it; got `of`."),
    ]
    check "## Read file,\n".found == @[
      (1, "Claim of comment ends cut short, so hand closes it; got `file,`."),
    ]
    check "## Read all, e.g.\n".found == @[
      (1, "Claim of comment ends cut short, so hand closes it; got `e.g.`."),
    ]
    let lowered = "## Read file.\n## then write it.\n"
    check lowered.found == @[
      (2, "Line of comment opens in lowercase after sentence end, so hand mends it; got " &
        "`then`."),
    ]
    for cut in ["## Read file of\n", "## Read file,\n", "## Read all, e.g.\n", lowered]:
      check cut.fixed == cut


  test "label carries neither capital nor period, and still takes backticks":
    for kept in [
      "let x = 1  # count of items\n",  # trailing comment
      "# count of items\nlet x = 1\n",  # own-line comment of one line in lowercase
      "# E1\n",  # one word
      "## | count | items |\n",  # table cell
      "# STYLE.md §5\n",  # citation
      "let values = [\n  1,\n    # Value alone\n]\n",  # label under code it labels
      "# `- -x` of #521; `--` one token\nlet x = - -y\n",  # label opening with name
    ]:
      check kept.isSettled
    check "let x = 1  # count of seq\n".fixed == "let x = 1  # count of `seq`\n"
    check "# Count of items\nlet x = 1\n".fixed == "# Count of items.\nlet x = 1\n"


  test "name is identifier file declares, in shape no English word takes":
    let declared = "let count_items = 1  ## Count of items.\n" &
      "# Read count_items once, as WebGL and RGB do, and sqrt, Basis and to stay words.\n"
    check declared.found == @[
      (2, "Name in comment stands in backticks; got `count_items`."),
    ]  # WebGL is undeclared, RGB is capitals alone, and one word is word
    check declared.fixed == declared.replace("Read count_items", "Read `count_items`")
    let dotted = "type Syntax = enum  ## Define syntax.\n  TypeScript  ## Define TypeScript.\n\n" &
      "# Read Syntax.TypeScript, as TypeScript alone names language.\n"
    check dotted.found == @[
      (4, "Name in comment stands in backticks; got `Syntax.TypeScript`."),
    ]  # enum member alone stays word
    for kept in [
      "# Read eₙ and grade(𝐦) once.\n",  # formal notation
      "let count_items = 1  ## Count of items.\n# Read `count_items` once.\n",  # in backticks
      "# Read \"Equation 2.13\" once.\n",  # quoted text
      "let count_items = 1  ## Count of items.\n\n# Columns:\n#   count_items   items read\n" &
        "#   size          widest size\n",  # aligned column
      "## Usage: record [rig] [verdicts]   writes file of each\n" &
        "##                                  recording named, or of all four\n",
          # deeper line continues aligned column
      "let count_items = 1  ## Count of items.\n## | count_items | items |\n",  # table row
      "let count_items = 1  ## Count of items.\n## Read count_items -> size\n",  # diagram
      "# RULE 3.  `\"Slots lie off side of`\n# `lead/follow.\"`  Six spots: default, and one\n" &
        "# slightly forward.\n",  # two spaces after sentence end inside quote
      "# Rule 7's measure stops here.\n",  # possessive, no typed literal
      "## Read both sides or\n##   neither (`a  + b`), as lexer does.\n",  # spaces in backticks
      "## Lists:\n##   `runs`: each run, as\n##     page draws it;\n##   `declared`: each face.\n",
        # item of definition list closes with `;` before its sibling
      "let md = 1  ## Count.\n# Read STYLE.md once.\n",  # citation, though file declares part
    ]:
      check kept.isSettled


  test "commented code and fenced code hold no prose":
    for kept in [
      "#func `<=`(a, b: Order): bool {.borrow.}\n",
      "#  let count_items = seq[int]\n#     y\n",
      "## Do.\n##   ```nim\n##   let x = seq[int]\n##   ```\n",
      COMMENTED,
      "# TODO: Fit.\n#   let x = seq[int]\n",  # line of code under prose
    ]:
      check kept.isSettled


  test "comment in its own language reads names alone":
    let own = "## convert seq once\n"
    check checkBackticks("a.nim", own).mapIt((it.line, it.message)) == @[
      (1, "Name in comment stands in backticks; got `seq`."),
    ]
    check fixBackticks("a.nim", own).source == "## convert `seq` once\n"
    let formatted = checkFormatting("a.nim", own, Dialect.Module).filterIt(
      it.rule == Rule.FormComment
    )
    check formatted.len == 3  # capital, name and period, as comments drop articles
    check checkFormatting(
      "a.nim", own, Dialect.Module, should_drop_articles = false
    ).filterIt(it.rule == Rule.FormComment).len == 1


  test "fix that would widen line past `LINE_MAX` stays for hand, report and all":
    let wide = "# Read " & "w".repeat(84) & " as seq.\n"  # 99 runes
    check wide.found == @[(1, "Name in comment stands in backticks; got `seq`.")]
    check wide.fixed == wide
    let full = "# Read " & "w".repeat(93) & "\n"  # 100 runes
    check full.found.len == 1
    check full.fixed == full
    let capital = "## read " & "w".repeat(92) & "\n"  # 100 runes
    check capital.found.len == 2
    check capital.fixed == "## Read " & "w".repeat(92) & "\n"  # capital widens nothing


  test "fix writes comments alone, settles, and keeps each line":
    for source in LIBRARY:
      let once = source.fixed
      check once.spellingsCode == source.spellingsCode
      check once.fixed == once
      check once.count('\n') == source.count('\n')
    check fixClaims("a.nim", BORROWS).fixed.mapIt(it.line) == @[4, 5, 6, 10]
