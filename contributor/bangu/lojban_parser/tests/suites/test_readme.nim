## Hold each command of `README.md` to shell that runs it: command that quotes its text with `'`
##   holds no `'` of its own, so shell passes that text whole to Nim or to node.
##   Command is each line from one that opens with `$ ` in block of text, till first line that ends
##     with `'`, where quote closes; text inside writes `'` as `\x27`.
##   Case as found, 2026-11-11: first command quoted `la'o` in its text of Nim, whose `'` closed
##     quote, so shell gave Nim `dy.` as module, and command exited 1.
##   README is read as text it is, at compile time; no command of it runs here, since each would
##     compile parser again.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[strutils, unittest]


const
  TEXT_README = staticRead("../../README.md")  ## README, as committed.
  OPENING_COMMAND = "$ "  ## Opening of first line of command in block of README.
  COUNT_COMMANDS_LEAST = 8  ## Commands of README that quote text, at least; 10 on adding suite.



func commandsQuoted(text: string): seq[tuple[line: int, command: string]] =
  ## Give each command that quotes text with `'`, with line it opens on: lines from one opening
  ##   with `$ ` till first that ends with `'`.
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
      check command.count('\'') == 2  # shell quote opens once and closes once (README.md)
    check commands.len >= COUNT_COMMANDS_LEAST  # IX.3, guard keeps commands of README
