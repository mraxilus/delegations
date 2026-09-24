discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Replicate face rules of `faces.nim` header, i.e. Article X.8 over sources declaring stacks.

import std/[strutils, unittest]
import ../src/faces


const KEEPING = """
<style>
  :root {
    --serif: "Noto Serif UI", Georgia, serif;
    --sans: "Noto Sans UI", Arial, sans-serif;
    --mono: "Commit Mono UI", "Noto Sans UI", monospace;
  }
  body { font-family: var(--sans); }
  h1, h2 { font-family: var(--serif); }
  code { font-family: var(--mono); font-variant-ligatures: contextual; }
</style>
"""
  ## Page keeping every rule: three families, headings serif, ligatures on, no host.


suite "Faces":
  test "source declaring no stack is no page, and is not reported for lacking one":
    # Most files are not pages. Absence of faces is not violation of how faces are named.
    check checkFaces("koch.nim", "let x = 1\n").len == 0
    check checkFaces("README.md", "# Title\n\nProse about fonts.\n").len == 0

  test "page keeping X.8 reports nothing":
    check checkFaces("pages/shell.html", KEEPING).len == 0

  test "linking font host is failing to ship face":
    const LINKED = """
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fraunces">
<style> body { font-family: "Noto Sans", sans-serif; } </style>
"""
    let found = checkFaces("mockups/wholecloth.html", LINKED)
    check found.len == 1
    check found[0].line == 1  # names line, so page opens at link
    check found[0].message.endsWith("got `fonts.googleapis.com`.")
    for host in HOSTS:  # every host listed is reported, not first alone
      check checkFaces("p.html", "a { font-family: \"Noto Sans\"; }\n@import \"https://" &
        host & "/x\";\n").len == 1

  test "stack leading with family X.8 does not name is reported, by that family":
    const OUTSIDE = """
  body { font-family: "Fraunces", Georgia, serif; }
"""
    let found = checkFaces("p.html", OUTSIDE)
    check found.len >= 1
    check found[0].message.endsWith("got `Fraunces`.")

  test "system stack is reported too, since keyword resolves to whatever viewer has":
    # This is shape three targets actually carried, and reading alone did not catch it.
    check checkFaces("p.html", "  body { font-family: ui-sans-serif, system-ui; }\n").len == 1
    check checkFaces("p.html", "  b { font-family: ui-monospace, Menlo; }\n").len == 1
    check checkFaces("p.html", "  i { font-family: serif; }\n").len == 1

  test "fallbacks after first family are free, since shipped face is what viewer gets":
    # Allow-list of every acceptable fallback is list nobody maintains; first entry decides.
    check checkFaces("p.html",
      "  body { font-family: \"Noto Sans\", Impact, Papyrus, cursive; }\n").len == 0

  test "subset alias is same family named for its subset":
    check isFamily("Noto Sans UI")
    check isFamily("Noto Sans Math")
    check isFamily("Noto Serif")
    check isFamily("Commit Mono UI")
    check not isFamily("Instrument Sans")  # different family, similar words
    check not isFamily("Spline Sans Mono")

  test "first family is read unquoted, whatever quoting stack uses":
    check firstFamily("\"Noto Sans\", Arial") == "Noto Sans"
    check firstFamily("'Noto Sans', Arial") == "Noto Sans"
    check firstFamily("  Noto Sans , Arial") == "Noto Sans"
    check firstFamily("").len == 0

  test "heading taking family other than serif is reported":
    const SANS_HEADING = """
  :root { --sans: "Noto Sans", sans-serif; --serif: "Noto Serif", serif; }
  h1 { font-family: var(--sans); }
"""
    let found = checkFaces("p.html", SANS_HEADING)
    check found.len == 1
    check found[0].message.endsWith("got `Noto Sans`.")
    # Serif heading passes, and so does non-heading element taking sans.
    check checkFaces("p.html",
      "  :root { --serif: \"Noto Serif\", serif; }\n  h3 { font-family: var(--serif); }\n"
    ).len == 0

  test "heading rule reads element, never class or word that merely contains one":
    check isHeading("h1")
    check isHeading("h1, h2, h3")
    check isHeading("article > h2")
    check isHeading("h1.title")  # heading carrying class is still heading
    check isHeading(".sheet h2")  # heading is subject, ancestor merely locates it
    check not isHeading(".h1")  # class named after heading
    check not isHeading("#h1")
    check not isHeading("graph1")  # word ending in tag
    check not isHeading("h7")

  test "selector styling something inside heading is not styling heading":
    # Both of these are real, from `design/page.nim` and `mockups/wholecloth.html`. Reading
    #   whole selector reported each as heading set in mono, where what each sets is small
    #   uppercase label beside heading. Check that accuses page of what it did not do is
    #   worse than no check, since curator hands it to contributor as finding.
    check not isHeading(".plate h3 .tag")
    check not isHeading(".panel h3 .tag")
    check not isHeading("h1 span")
    check not isHeading("h2 > code")
    check not isHeading("h3 .kicker, h4 .kicker")  # every selector in list reads its own
    # Subject decides, so list mixing both still reports where subject is heading.
    check isHeading("h1 .tag, h2")
    let inside = checkFaces("p.html",
      "  :root { --mono: \"Commit Mono\", monospace; --serif: \"Noto Serif\", serif; }\n" &
      "  h3 { font-family: var(--serif); }\n" &
      "  .plate h3 .tag { font: 600 0.62rem/1 var(--mono); }\n" &
      "  code { font-feature-settings: \"calt\"; }\n")
    check inside.len == 0

  test "one level of var() is resolved, and unresolvable var is left alone":
    const PROPS = [("--sans", "\"Noto Sans\", Arial"), ("--x", "var(--y)")]
    check resolved("var(--sans)", PROPS) == "\"Noto Sans\", Arial"
    check resolved("var(--absent)", PROPS) == "var(--absent)"  # named nothing here
    check resolved("\"Noto Sans\"", PROPS) == "\"Noto Sans\""  # literal passes through
    check resolved("var(--x)", PROPS) == "var(--y)"  # one level, never chased

  test "Commit Mono without its ligatures is face half used":
    const NO_LIGATURES = """
  :root { --mono: "Commit Mono", monospace; }
  code { font-family: var(--mono); }
"""
    let found = checkFaces("p.html", NO_LIGATURES)
    check found.len == 1
    check found[0].line == 0  # whole-file finding: property may go anywhere
    check MONO in found[0].message
    # Either property satisfies it, since either can carry `calt`.
    for property in LIGATURES:
      check checkFaces("p.html", NO_LIGATURES & "  code { " & property & ": x; }\n").len == 0
    # Page naming no Commit Mono is never asked for ligatures.
    check checkFaces("p.html", "  body { font-family: \"Noto Sans\", serif; }\n").len == 0

  test "property that is not stack is not read as one, whatever commas it holds":
    # Found by pointing check at real tree: `--ease` and `--surface` were reported as stacks
    #   leading with `cubic-bezier(0.215` and `rgba(22`. Property is checked where `var()`
    #   reaches it from declaration, never on its own.
    const PALETTE = """
  :root {
    --ease: cubic-bezier(0.215, 0.61, 0.355, 1);
    --surface: rgba(22, 27, 34, 0.82);
    --sans: "Noto Sans", Arial;
  }
  body { font-family: var(--sans); }
"""
    check checkFaces("p.html", PALETTE).len == 0

  test "line carrying two properties yields both, not first alone":
    # `:root { --sans: ...; --serif: ...; }` is one line and two stacks. Reading first alone
    #   left second unresolved, so `var(--serif)` read as family nobody names and page was
    #   reported for stack it had declared correctly.
    const ONE_LINE =
      """  :root { --mono: "Commit Mono", monospace; --serif: "Noto Serif", serif; }"""
    let held = ONE_LINE.propertyValues
    check held.len == 2
    check held[0][0] == "--mono"
    check held[1][0] == "--serif"
    check held[1][1] == "\"Noto Serif\", serif"
    check resolved("var(--serif)", held) == "\"Noto Serif\", serif"

  test "value deferring to cascade names no family, so it is not reported":
    # `font-family: inherit` takes whatever parent settled, and parent is checked where set.
    for defers in DEFERS:
      check checkFaces("p.html",
        "  a { font-family: \"Noto Sans\"; }\n  b { font-family: " & defers & "; }\n").len == 0
    # Heading deferring is not reported either, for same reason.
    check checkFaces("p.html",
      "  :root { --serif: \"Noto Serif\", serif; }\n" &
      "  h1 { font-family: var(--serif); }\n  h2 { font-family: inherit; }\n").len == 0

  test "font shorthand names family last, and is read as stack":
    # `design/page.nim` writes every stack this way; check reading `font-family` alone
    #   passed it, which is how whole page stayed unseen.
    check shorthandFamilies("16px/1.6 var(--sans)") == "var(--sans)"
    check shorthandFamilies("500 0.7rem/1 var(--mono)") == "var(--mono)"
    check shorthandFamilies("italic bold 12px/30px Georgia, serif") == "Georgia, serif"
    check shorthandFamilies("0.66rem/1.4 \"Noto Sans\"") == "\"Noto Sans\""
    check shorthandFamilies("caption").len == 0  # names system font, no family list
    let found = checkFaces("page.nim",
      "  body { font: 16px/1.6 ui-sans-serif; }\n  x { font-family: \"Noto Sans\"; }\n")
    check found.len == 1
    check found[0].message.endsWith("got `ui-sans-serif`.")
    # Shorthand naming admitted family passes, and heading rule reaches it too.
    check checkFaces("p.html",
      "  :root { --serif: \"Noto Serif\", serif; }\n  h1 { font: 2rem var(--serif); }\n"
    ).len == 0
    let heading = checkFaces("p.html",
      "  :root { --sans: \"Noto Sans\", serif; }\n  h1 { font: 2rem var(--sans); }\n")
    check heading.len == 1
    check heading[0].message.endsWith("got `Noto Sans`.")

  test "every family X.8 names is data, in role order":
    check FAMILIES == [SERIF, SANS, MONO]
    check SERIF == "Noto Serif"
    check SANS == "Noto Sans"
    check MONO == "Commit Mono"
