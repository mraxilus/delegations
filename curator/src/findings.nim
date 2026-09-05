## Define finding record every check emits, plus its order and report form.
##   One record shape keeps umbrella trivial: collect, sort, print, count.
##   Message convention (Article IV.4): end by echoing offending value in backticks.
##
##   Cost: line `0` marks whole-file findings, so `0` never means first line.
##   Cost: empty path marks branch-level findings (scope, commits) with no file to open.

{.experimental: "strictFuncs".}

import std/[algorithm]


type Finding* = object
  ## Define one rule violation located at path and line.
  path*: string     ## Repository-relative path, `/` separated; empty for branch-level.
  line*: int        ## One-based line; `0` when finding concerns whole file.
  message*: string  ## Telegraphic statement, ending with echoed value where one exists.


func finding*(path: string, line: int, message: string): Finding =
  ## Construct finding.
  Finding(path: path, line: line, message: message)


func `<`*(a, b: Finding): bool =
  ## Order findings by path, then line, then message, so reports are stable.
  if a.path != b.path: return a.path < b.path
  if a.line != b.line: return a.line < b.line
  a.message < b.message


func render*(f: Finding): string =
  ## Render finding as `path:line: message`; line omitted when `0`, path when empty.
  if f.path.len == 0: return f.message
  let location = if f.line == 0: f.path else: f.path & ":" & $f.line
  location & ": " & f.message


proc report*(findings: seq[Finding]) =
  ## Print findings sorted, one per line, then count.
  for f in findings.sorted: echo f.render
  echo $findings.len & " finding(s)."
