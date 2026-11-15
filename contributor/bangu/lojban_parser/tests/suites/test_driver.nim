## cipra lo du'u le jitro samtci be lo minde be'o po'u `tools/build.nim` cu mapti le tarmi poi la'o
##   gy. koch .gy. cu tcidu lo minde ne'i ke'a
##   .i le pagbu poi cuxna lo minde cu se krasi le linji po'u `case paramStr(1)` gi'e vasru ro minde
##     poi la'o gy. koch .gy. cu pilno ke'a ku'o ta'i lo jimca po'u `of "<verb>":` noi lidne `else:`
##     to `CASE_DRIVER` .e `verbsDispatch` pe `checker.nim` pe la'o gy. curator .gy. toi
##   .i la'o gy. koch .gy. cu cpacu lo du'u xu kau le vi se gunka cu ponse `drive` .a `head` .a
##     `system` kei le pagbu po'o to `CONTRIBUTOR.md` toi
##   .i se ki'u bo la'o gy. runner .gy. cu smaji cliva ro minde poi la'o gy. koch .gy. na ka'e tcidu
##     ke'a
##   .i lo mupli cu te facki de'i `2026-11-11` bu'u lo jimca be la'o gy. git .gy. be'o pe le samtci
##     pe lo jmive se ciska
##   .i le pagbu poi cuxna lo minde cu pu se krasi `case arguments[0]`
##   .i se ki'u bo la'o gy. koch .gy. pu tcidu no minde pe le jitro samtci
##   .i `koch drive` pu jitro no da
##   .i `koch list-packages` pu cusku no bakfu pe le vi se gunka
##   .i `readVerbs` cu fukpi `verbsDispatch`
##   .i ki'u bo le vi se gunka cu cpacu no datnyvei pe la'o gy. curator .gy.
##   .i le jitro samtci cu se tcidu ta'i lo se ciska ca lo nu fanva
##   .i no linji pe le jitro samtci cu se pilno vi

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[strutils, unittest]


const
  TEXT_DRIVER = staticRead("../../tools/build.nim")  ## le jitro samtci poi se punji
  OPENING_DISPATCH = "case paramStr(1)"
    ## le linji poi le pagbu poi cuxna lo minde cu se krasi ke'a to `CASE_DRIVER` pe la'o gy.
    ##   curator .gy. toi
  MARK_BRANCH = "of \""
    ## lo krasi be lo jimca poi cusku pa minde to `MARK_DISPATCH` pe la'o gy. curator .gy. toi
  CLOSING_DISPATCH = "else:"
    ## le linji poi le pagbu poi cuxna lo minde cu se fanmo ke'a to `CASE_END` pe la'o gy. curator
    ##   .gy. toi
  VERBS_KOCH = ["drive", "head", "system"]
    ## lo minde pe le jitro samtci ge'u zi'e poi la'o gy. koch .gy. cu pilno ke'a
    ##   .i le vi se gunka cu ponse ro le minde



func readVerbs(text: string): seq[string] =
  ## tcidu lo minde poi le jitro samtci cu cuxna ke'a ku'o ta'i lo nu la'o gy. koch .gy. cu tcidu le
  ##   minde
  ##   .i tcidu lo cmene poi se sitna ne'i ro jimca poi se lidne le linji poi le pagbu poi cuxna lo
  ##     minde cu se krasi ke'a ku'o gi'e lidne le linji poi le pagbu cu se fanmo ke'a
  var is_inside = false
  for line in text.splitLines:
    let stripped = line.strip
    if stripped.startsWith(OPENING_DISPATCH):
      is_inside = true
      continue
    if not is_inside: continue
    if stripped == CLOSING_DISPATCH: break
    if not stripped.startsWith(MARK_BRANCH): continue
    let verb = stripped[MARK_BRANCH.len .. ^1].split('"')[0]
    if verb.len > 0 and verb notin result: result.add verb



suite "Internal: Driver":
  test "Driver dispatches each verb koch reaches, where koch reads dispatch":
    let verbs = TEXT_DRIVER.readVerbs
    checkpoint "verbs read: " & $verbs
    for verb in VERBS_KOCH:
      # ja'i `CASE_DRIVER` pe la'o gy. curator .gy. la'o gy. koch .gy. cu cpacu lo minde le pagbu
      #   po'o
      check verb in verbs  # `CASE_DRIVER` pe la'o gy. curator .gy.
