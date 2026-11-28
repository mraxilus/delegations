## cipra ro minde pe `README.md` ja'i lo minde samtci poi tcidu le minde
##   .i lo minde poi sitna lo selci'a sepi'o `'` vasru no datle'u po'u `'`
##   .i se ki'u bo lo minde samtci cu dunda le mulselci'a `Nim` .a `node`
##
## ni'o ro minde cu selkra pa linji poi selkra `$ ` ne'i pa girzu be lo linji be'o poi se tcita
##     `text`
##   .i le minde .e le nu sitna cu selfa'o le pamoi linji poi selfa'o `'`
##   .i ne'i le se sitna `\x27` basti `'`
##
## ni'o mupli fa lo nu fliba poi selfa'i de'i `2026-11-11`
##   .i le pamoi minde cu sitna zo la'o ne'i lo vo'a selci'a be fi `Nim`
##   .i le lerfu po'u `'` pe zo la'o fanmo le nu sitna pe lo minde samtci
##   .i se ki'u bo lo minde samtci cu dunda `dy.` `Nim` ta'i lo datnyvei
##   .i lo jalge be le minde cu du li 1
##
## ni'o `README.md` se tcidu ta'i lo selci'a ca lo nu fanva
##   .i no minde pe `README.md` selpli vi
##   .i ki'u bo ro minde cu rapfanva le genturfa'i

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[strutils, unittest]


const  # lo stodi pe le cipra pe `README.md`
  TEXT_README = staticRead("../../README.md")  ## `README.md` ta'i lo nu selvei
  OPENING_COMMAND = "$ "
    ## lo krasi be lo pamoi linji be lo minde be'o ne'i lo girzu be lo linji be'o pe `README.md`
  COUNT_COMMANDS_LEAST = 8
    ## lo mecraiterkancu be lo minde poi sitna lo selci'a gi'e zvati `README.md`
    ##   .i ca lo nu jmina le cipra kei `README.md` vasru 10 minde poi sitna lo selci'a



func commandsQuoted(text: string): seq[tuple[line: int, command: string]] =
  ## dunda ro minde poi sitna lo selci'a sepi'o `'` ku'o .e lo linji poi le minde cu selkra ke'a
  ##   .i ro minde cu selkra pa linji poi selkra `$ ` ku'o gi'e selfa'o le pamoi linji poi selfa'o
  ##       `'`
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
      # le nu sitna pe lo minde samtci cu selkra pa roi gi'e selfa'o pa roi
      check command.count('\'') == 2  # `README.md`
    # lo bandu cu ralte lo minde pe `README.md`
    check commands.len >= COUNT_COMMANDS_LEAST  # ja'i `IX.3`
