## cipra ro minde pe `README.md` ja'i lo minde samtci poi tcidu le minde .i lo minde poi sitna lo se
##   ciska sepi'o `'` cu vasru no drata lerfu po'u `'` .i se ki'u bo lo minde samtci cu dunda le
##   mulno se ciska la'o gy. Nim .gy. .a `node`
##   .i ro minde cu se krasi pa linji poi se krasi `$ ` ne'i pa girzu be lo linji be'o poi se tcita
##     `text` .i le minde cu se fanmo le pamoi linji poi se fanmo `'` .i le nu sitna cu se fanmo vi
##     .i ne'i le se sitna `\x27` cu basti `'`
##   .i mupli fa lo nu fliba poi se facki de'i `2026-11-11` .i le pamoi minde cu sitna zo la'o ne'i
##     lo vo'a se ciska be fi la'o gy. Nim .gy. .i le lerfu po'u `'` pe zo la'o cu fanmo le nu sitna
##     pe lo minde samtci .i se ki'u bo lo minde samtci cu dunda `dy.` la'o gy. Nim .gy. ta'i lo
##     datnyvei .i lo jalge be le minde cu du li pa
##   .i `README.md` cu se tcidu ta'i lo se ciska ca lo nu fanva .i no minde pe `README.md` cu se
##     pilno vi .i ki'u bo ro minde cu rapli fanva le genturfa'i

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[strutils, unittest]


const
  TEXT_README = staticRead("../../README.md")  ## `README.md` ta'i lo nu se vreji
  OPENING_COMMAND = "$ "
    ## lo krasi be lo pamoi linji be lo minde be'o ne'i lo girzu be lo linji be'o pe `README.md`
  COUNT_COMMANDS_LEAST = 8
    ## lo mleca traji te kancu be lo minde poi sitna lo se ciska gi'e zvati `README.md` .i ca lo nu
    ##   jmina le cipra kei `README.md` cu vasru pano minde poi sitna lo se ciska



func commandsQuoted(text: string): seq[tuple[line: int, command: string]] =
  ## dunda ro minde poi sitna lo se ciska sepi'o `'` ku'o .e lo linji poi le minde cu se krasi ke'a
  ##   .i ro minde cu se krasi pa linji poi se krasi `$ ` .i le minde cu se fanmo le pamoi linji poi
  ##   se fanmo `'`
  let lines = text.splitLines
  var k = 0
  while k < lines.len:
    if not lines[k].startsWith(OPENING_COMMAND) or '\'' notin lines[k]:
      inc k
      continue
    var
      last = k
      command = lines[k]
    while not lines[last].endsWith("'") and last + 1 < lines.len:
      inc last
      command.add "\n" & lines[last]
    result.add (k + 1, command)
    k = last + 1



suite "Internal: README":
  test "Each command that quotes its text holds two quotes of shell alone, which open and close":
    let commands = TEXT_README.commandsQuoted
    for (line, command) in commands:
      checkpoint "README.md line " & $line & ": " & command
      # le nu sitna pe lo minde samtci cu se krasi pa roi gi'e se fanmo pa roi
      check command.count('\'') == 2  # `README.md`
    # lo bandu cu ralte lo minde pe `README.md`
    check commands.len >= COUNT_COMMANDS_LEAST  # ja'i `IX.3`
