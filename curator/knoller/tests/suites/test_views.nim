## Replicate views of `views.nim` header: code alone and code with comments, every length kept.

{.experimental: "strictFuncs".}

import std/[strutils, unittest]
import ../../src/knoller/views



suite "Views":
  test "comments and strings are blanked, newlines kept":
    let code = ("let a = \"# not comment\" # comment\nlet b = r\"raw \"\" quote\" #[ block\n" &
      "]# c").codeOnly
    check code.splitLines.len == 3
    check "comment" notin code and "quote" notin code and "block" notin code
    check "let a =" in code and "let b =" in code and code.splitLines[2].strip == "c"


  test "code-and-comments view blanks strings alone, keeping every length":
    let
      source = "let a = \"# not comment\" # comment\nlet b = '#' #[ block\n]# c"
      kept = source.codeAndComments
    check kept.len == source.len and kept.splitLines.len == 3
    check "not" notin kept and "'#'" notin kept  # string and char blanked
    check "# comment" in kept and "#[ block" in kept and kept.splitLines[2] == "]# c"
    check kept.find('#') == source.find("# comment")  # first `#` left opens comment


  test "identifier opens at index after spaces, and compares as Nim compares it":
    check "  name_1 = 0".identifierAt(0) == "name_1"  # spaces skipped
    check "x = 𝐦".identifierAt(3) == "𝐦"  # Unicode letter is name character
    check "(a)".identifierAt(0).len == 0  # none opens there
    check "is_Wide".identity == "iswide" and "isWide".identity == "iswide"  # case and `_` fold
    check "Wide".identity != "wide".identity  # first character exact
    check "ctxFoo".identity == "ctx_foo".identity and "ctx".identity == "cTX".identity
    check "Ctx".identity != "ctx".identity  # rename planner of `curator/audit` compares so
    check "    x".indentOf == 4 and "x".indentOf == 0
