discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Replicate gated-language rule of `justification.nim` header and CONTRIBUTOR.md Language.

import std/unittest
import ../src/[kinds, comments, justification]


const
  REASON = "// Wire WebGL; " & MARKER & " browser host runs JavaScript only.\nexport {};\n"
    ## Gated file arguing for itself on its first line.
  SILENT = "// Wire WebGL and pointer events.\nexport {};\n"
    ## Same file saying nothing about why it is not Nim.


func ts(): KindRule =
  ## Read rule of gated kind tests drive.
  Kind.TypeScript.rule


suite "Justification":
  test "gated kind without marker in header is finding at line one":
    let found = checkJustification("p/src/glue.ts", SILENT, ts())
    check found.len == 1
    check found[0].path == "p/src/glue.ts"
    check found[0].line == 1  # header is where reader looks
    check checkJustification("p/src/glue.ts", REASON, ts()).len == 0  # argued

  test "every gated kind is held to same rule, and ungated kinds to none":
    check Kind.TypeScript.rule.is_gated  # JavaScript forced by browser or node host
    check Kind.Cpp.rule.is_gated  # library no Nim import expresses
    check Kind.C.rule.is_gated
    check not Kind.Nim.rule.is_gated  # default language argues for nothing
    check not Kind.Markdown.rule.is_gated
    let shim = "// Flatten overload set; " & MARKER & " importcpp cannot bind defaults.\n"
    check checkJustification("p/src/shim.cpp", shim, Kind.Cpp.rule).len == 0
    check checkJustification("p/src/shim.cpp", "// Flatten overloads.\n", Kind.Cpp.rule).len == 1
    # Ungated kind carrying no marker passes, since nothing gates it.
    check checkJustification("p/src/main.nim", "## Run program.\n", Kind.Nim.rule).len == 0

  test "header is opening comment run, so guard above it and blank line inside it survive":
    let guarded = "#pragma once\n// Bind panels; " & MARKER & " no import expresses them.\n"
    check checkJustification("p/src/panels.hpp", guarded, Kind.Cpp.rule).len == 0
    let spaced = "/*\n * Bind panels.\n *\n * Kept small; " & MARKER & " C++ owns layout.\n */\n"
    check checkJustification("p/src/panels.hpp", spaced, Kind.Cpp.rule).len == 0

  test "marker below header does not satisfy gate":
    # Argument buried in body is argument reader never meets, so run ends before it.
    let buried = "// Wire WebGL.\nexport {};\n\n\n// Kept here; " & MARKER & " host is node.\n"
    check checkJustification("p/src/glue.ts", buried, ts()).len == 1
    check header(comments(buried, Syntax.Slash)) == "Wire WebGL."  # run stops at code

  test "file without comments at all is finding, never crash":
    check checkJustification("p/src/glue.ts", "export {};\n", ts()).len == 1
    check header(newSeq[Comment]()).len == 0  # empty file names empty header
