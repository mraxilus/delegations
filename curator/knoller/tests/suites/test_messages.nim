## Replicate Article IV.4: message ends echoing value in backticks, ``"…; got `{value}`."``;
##   tail ending on word echoes none; fix adds backticks, and nothing else, and nothing second
##   time.

{.experimental: "strictFuncs".}

import std/[sequtils, strutils, unittest]
import ../../src/knoller/messages


func fixed(source: string): string =
  ## Fix messages of source, as `koch fix` does.
  fixMessages("a.nim", source).source


func isSettled(source: string): bool =
  ## Decide whether source reports no message finding and fixes to itself again.
  checkMessages("a.nim", source).len == 0 and fixMessages("a.nim", source).fixed.len == 0



suite "Article IV":
  test "IV.4 interpolated value after `got` takes backticks":
    let source = "doAssert x, &\"Turn ended off centre; got {manner}.\"\n"
    check checkMessages("a.nim", source)[0].message.endsWith("got `{manner}`.")
    check source.fixed == "doAssert x, &\"Turn ended off centre; got `{manner}`.\"\n"
    check source.fixed.isSettled
    check "raise f(&\"Bad; got {a} against {b} for {c}.\")\n".fixed ==
      "raise f(&\"Bad; got `{a}` against `{b}` for `{c}`.\")\n"  # every value of tail
    check "let m = fmt\"Bad; got {x=}.\"\n".fixed == "let m = fmt\"Bad; got `{x=}`.\"\n"
    check "let m = &\"Bad {a}; got {{x}} `{b}`.\"\n".isSettled  # `{{` and value before tail


  test "IV.4 operand after `got` takes backtick at end of literal before, and start of one after":
    let source = "let m = \"Prompt over \" & $LIMIT & \" bytes; got \" & $count & \".\"\n"
    check checkMessages("a.nim", source).mapIt(it.message) ==
      @["Message ends echoing value in backticks, as ``…; got `{value}`.`` (IV.4); got " &
        "`$count`."]  # value before tail is no echo
    check source.fixed ==
      "let m = \"Prompt over \" & $LIMIT & \" bytes; got `\" & $count & \"`.\"\n"
    check source.fixed.isSettled
    check "f(\"Empty; got cell in row \" & row[0] & \".\")\n".fixed ==
      "f(\"Empty; got cell in row `\" & row[0] & \"`.\")\n"


  test "IV.4 tail spanning lines takes backticks on each line they land on":
    let source =
      "doAssert x,\n  &\"Holds at most {N} records; got \" &\n    &\"{count} at {at}.\"\n"
    check source.fixed ==
      "doAssert x,\n  &\"Holds at most {N} records; got \" &\n    &\"`{count}` at `{at}`.\"\n"
    let split = "f(\"Short; got \" &\n  $count & \" rows.\")\n"
    check split.fixed == "f(\"Short; got `\" &\n  $count & \"` rows.\")\n"
    check split.fixed.isSettled


  test "IV.4 tail ending on word echoes no value, and is no finding":
    for kept in [
      "f(\"Line ends with CR; got CRLF.\")\n",
      "f(\"Module carries pragma; got none.\")\n",
      "f(\"Checkouts differ; got exit `\" & $code & \"`.\")\n",  # backticks already
      "f(\"Name; got `\" & name & \"`.\")\n",
      "f(&\"Extent; got `{width}x{height}`.\")\n",  # one span holds both values
      "f(\"History; got `git \" & sub & \"`.\")\n",  # span text opens holds operand
      "f(\"Kind; got `\" & base & ext & \"`.\")\n",
      "f(\"Want `\" & a & \"`; got `\" & b & \"`.\")\n",  # span before `got` closed
      "# Comment; got {x}.\n",  # comment, never message
      "let detail = name & \" got \" & $count\n",  # no `; got`
    ]:
      check checkMessages("a.nim", kept).len == 0
      check kept.fixed == kept


  test "IV.4 operand ending message, and backtick widening line, stay with finding":
    let ending = "f(\"Bad; got \" & $count)\n"
    check ending.fixed == ending
    check checkMessages("a.nim", ending).len == 1
    let near = "f(&\"" & "x".repeat(80) & "; got {value}.\")\n"  # 100 runes; backticks 102
    check near.fixed == near
    check checkMessages("a.nim", near).len == 1
