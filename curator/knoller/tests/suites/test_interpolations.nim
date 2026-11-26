## Hold that interpolated string takes each value in braces, and joins none to it by `&`
##   (STYLE.md §3), as Architect ruled on rule 21 of #443: fix joins concatenation into one
##   interpolated literal, and leaves what one literal cannot read alike, and what project's own
##   `formatValue` would print otherwise.
##   Wrap whose text does not fit on one line stays, since STYLE.md §3 lets it break.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/knoller/[chain, messages, reports]


const
  WRAPS =
    "  doAssert IS_RIGID or DIMENSIONS >= 3,\n" &
    "    &\"Conformal Geometric Algebras must have dimensionality of 3 or more \" &\n" &
    "    &\"(2 Conformal + 1 Euclidean); got `{DIMENSIONS}`.\"\n" &
    "    assert terms.len <= 1,\n" &
    "      &\"Attempt to convert 2D cayley to 1D with non-singleton product values;\" &\n" &
    "      &\" got `{terms}` for `{chirality}` `{operand}`.\"\n"
    ## Lines 99 to 101 of `pga/algebra.nim` and 877 and 878 of `pga/cayleys.nim` of PGA library
    ##   at `3d9696e`: joined, lines would hold 122 and 123 runes.
  RIG =
    "      result.text = &\"{{\\\"key\\\":\\\"{ask.key}\\\"," &
    "\\n\\\"hold\\\":\\\"{ask.key}\\\",\\n\" &\n" &
    "          &\"\\\"band\\\":\\\"{BANDS[ord(Band.Crown)]}\\\"," &
    "\\n\\\"mirror\\\":\\\"{keeper}\\\"}}\"\n"
    ## Lines 244 and 245 of `design/rig.nim` of `dance_ontology` at `441fc785`, which fix joined
    ##   while width check read joined line as fit.
  NAME =
    "func toBasisName(b: BasisDigits): string {.compileTime, noinit.} =\n" &
    "  ## Convert basis' digits to string (with S/E prefix).\n" &
    "  if len(b) == 0: \"S\" else: \"E\" & $b\n"
    ## Lines 266 to 268 of `pga/algebra.nim` at `3d9696e`: join with no interpolated literal.


func found(source: string): seq[(int, string)] =
  ## Read line and message of each report of interpolation braces in source.
  checkInterpolations("a.nim", source).mapIt((it.line, it.brief))


func fixed(source: string): string =
  ## Join concatenations of source, as `koch fix` does.
  fixInterpolations("a.nim", source).source


func isSettled(source: string): bool =
  ## Decide whether source reports no interpolation and fixes to itself again.
  checkInterpolations("a.nim", source).len == 0 and source.fixed == source


func isLeft(source: string): bool =
  ## Decide whether source reports interpolation that fix leaves for hand.
  checkInterpolations("a.nim", source).len == 1 and source.fixed == source



suite "Interpolations":
  test "value or literal joined to interpolated literal joins it, each value in braces":
    let ruled = "let m = &\"y is {y}, from \" & $x\n"
    check ruled.found == @[
      (1, "interpolated string takes each value in braces, never by `&`; got `$x`"),
    ]  # ruling D3
    check ruled.fixed == "let m = &\"y is {y}, from {x}\"\n"
    check ruled.fixed.isSettled
    for (source, mended) in [
      ("let m = &\"a {x}\" & \" and b.\"\n", "let m = &\"a {x} and b.\"\n"),
      ("let m = &\"a {x}\" & \" {b}.\"\n", "let m = &\"a {x} {{b}}.\"\n"),  # brace doubled
      ("let m = fmt\"a {x}\" & $y\n", "let m = fmt\"a {x}{y}\"\n"),  # prefix kept
      ("let m = $x & &\" is {y}.\"\n", "let m = &\"{x} is {y}.\"\n"),  # read back
      ("let m = &\"got `\" & $x & \"`.\"\n", "let m = &\"got `{x}`.\"\n"),  # backticks stay
      ("let m = &\"at {x} \" & dir / name\n", "let m = &\"at {x} {dir / name}\"\n"),
      ("let m = &\"a {x} \" & $(b + c)\n", "let m = &\"a {x} {b + c}\"\n"),  # group under `$`
        # operator binding tighter than `&` holds its operand
    ]:
      check source.found.len == 1
      check source.fixed == mended
      check mended.isSettled


  test "wrap joins where joined line fits, and stays where it does not":
    let wrap = "let m = &\"a {x} \" &\n  &\"b {y}.\"\n"
    check wrap.found.len == 1
    check wrap.fixed == "let m = &\"a {x} b {y}.\"\n"
    check WRAPS.isSettled  # lines 99 and 877 of library, as found
    check RIG.isSettled  # joined, line would hold one long token, which width check lets stand
    check ("let m = &\"" & "x".repeat(60) & "{a}\" &\n  &\"" & "y".repeat(40) & "\"\n").isSettled
      # same shape at 114 runes


  test "concatenation with no interpolated literal stays `&`":
    check NAME.isSettled  # line 268 of `pga/algebra.nim`
    check "let p = directory / \"x\" & name\n".isSettled
    check "let m = \"a\" & \"b\"\n".isSettled


  test "value or literal that one literal cannot read alike stays for hand":
    for left in [
      "let m = &\"x {y} \" & (if b: \"t\" else: \"f\")\n",  # quote
      "let m = &\"x {y} \" & $(a: 1)\n",  # colon outside parentheses of value
      "let m = &\"x {y} \" & $[{1}]\n",  # brace
      "let m = &\"x {y} \" & `name`\n",  # backtick, as splice of `quote do:`
      "let m = &\"x {y} \" & r\"\\d\"\n",  # raw literal
      "let m = &\"\"\"x {y} \"\"\" & $z\n",  # long literal
      "let m = &\"x {y} \" & # count\n  $z\n",  # comment between pieces
      "let m = &\"x {y} \" & $'\\n'\n",  # backslash of escape in value
      "let m = &\"x {y} \" & f(a,\n  b)\n",  # line break in value
      "let m = fmt\"x {y}\" & \"\\t\"\n",  # escape that raw `fmt` reads as two characters
      "let m = &\"x {y}\" & fmt\"\\d\"\n",  # raw backslash that `&` reads as escape
      "let m = &\"x {y}\" & \"\\x7B\"\n",  # escape by number, which spells brace
    ]:
      check left.isLeft


  test "project that declares `formatValue` keeps each join for hand":
    let source = "{.experimental: \"strictFuncs\".}\n\n" &
      "let m = &\"y is {y}, from \" & $x  ## Text.\n"
      # pragma and doc, so other fixers of chain leave source as it is
    check formatted("a.nim", source, Dialect.Module).source ==
      source.replace("from \" & $x", "from {x}\"")
    check formatted("a.nim", source, Dialect.Module, has_format_value = true).source == source
      # `formatValue` of project could print value other than `$`


  test "routine `formatValue` of any spelling marks its source, and binding of that name none":
    let signature = "(result: var string; value: Thing; specifier: string) = discard\n"
    check ("proc formatValue*" & signature).isDeclaringFormatValue
    check ("func format_value" & signature).isDeclaringFormatValue  # Nim reads one name
    check not "let formatValue = 1\n".isDeclaringFormatValue
    check not "proc format(x: int): string = $x\n".isDeclaringFormatValue
