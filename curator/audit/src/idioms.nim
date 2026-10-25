## Enforce idioms of source whose rules come from CONTRIBUTOR.md (System, TypeScript), and so
##   belong to this repository; idioms of STYLE.md and Article X.5 are knoller's (`idioms.nim`
##   there, `checkIdioms`), which static pass runs on Nim source.
##   Every kind but Markdown: path of one machine is finding (CONTRIBUTOR.md, System).
##     Prefix names path only where it opens one: character before it is none that word or path
##       ends on (`CHARS_RUNNING`), or flag of one letter stands there, as `-I/home/me`. So word
##       holding prefix, as `nest/home/abode` of word list (#753), names no path.
##   `tsconfig.json` sets three flags TypeScript section names, each to `true`.
##   No fixer: machine path and TypeScript flags, since each needs knowledge text does not hold.
##
##   Cost: path written after letter that opens no flag passes, as `x/home/me`; text reads word.

{.experimental: "strictFuncs".}

import std/strutils
import ./findings



const
  PATHS_MACHINE* = ["/home/", "/Users/", "C:\\"]
    ## Prefixes naming paths of one machine (CONTRIBUTOR.md, System).
  CHARS_RUNNING = {'a'..'z', 'A'..'Z', '0'..'9', '_', '.', '~'}
    ## Characters word or path ends on, so prefix after one runs on, never opens path.
  FLAGS_TYPESCRIPT* = ["exactOptionalPropertyTypes", "noUncheckedIndexedAccess", "strict"]
    ## Compiler options `tsconfig.json` sets to `true` (CONTRIBUTOR.md, TypeScript).


func isOpening(line: string, at: int): bool =
  ## Decide whether prefix at byte `at` of line opens path: no character of `CHARS_RUNNING`
  ##   stands before it, or flag of one letter does, as `-I/home/me`.
  if at == 0 or line[at-1] notin CHARS_RUNNING: return true
  at >= 2 and line[at-1] in Letters and line[at-2] == '-' and
      (at == 2 or line[at-3] notin CHARS_RUNNING + {'-'})


func checkPathsMachine*(path, source: string): seq[Finding] =
  ## Report line naming path of one machine where prefix opens path (CONTRIBUTOR.md, System).
  let lines = source.splitLines
  for i, line in lines:
    for prefix in PATHS_MACHINE:
      var at = line.find(prefix)
      while at >= 0 and not line.isOpening(at): at = line.find(prefix, at + 1)
      if at >= 0:
        result.add finding(
          path,
          i + 1,
          "Source names path of one machine; take location from environment " &
            "(CONTRIBUTOR.md, System); got `" & prefix & "`.",
        )


func isFlagSet(config, flag: string): bool =
  ## Decide whether text of `tsconfig.json` sets `"flag": true`.
  let at = config.find("\"" & flag & "\"")
  if at < 0: return
  var k = at + flag.len + 2
  while k < config.len and config[k] in {' ', '\t', '\n', '\r', ':'}: inc k
  config.continuesWith("true", k)


func checkTsconfig*(path, config: string): seq[Finding] =
  ## Report flag `tsconfig.json` leaves unset (CONTRIBUTOR.md, TypeScript).
  for flag in FLAGS_TYPESCRIPT:
    if not config.isFlagSet(flag):
      result.add finding(
        path,
        0,
        "`tsconfig.json` sets `" & flag & "` to `true` (CONTRIBUTOR.md, TypeScript); got none.",
      )
