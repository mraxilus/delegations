## Enforce idioms of source whose rules come from CONTRIBUTOR.md (System, TypeScript), and so
##   belong to this repository; idioms of STYLE.md and Article X.5 are knoller's (`idioms.nim`
##   there, `checkIdioms`), which static pass runs on Nim source.
##   Every kind but Markdown: path of one machine is finding (CONTRIBUTOR.md, System).
##   `tsconfig.json` sets three flags TypeScript section names, each to `true`.
##   No fixer: machine path and TypeScript flags, since each needs knowledge text does not hold.

{.experimental: "strictFuncs".}

import std/strutils
import ./findings



const
  MACHINE_PATHS* = ["/home/", "/Users/", "C:\\"]
    ## Prefixes naming paths of one machine (CONTRIBUTOR.md, System).
  TYPESCRIPT_FLAGS* = ["exactOptionalPropertyTypes", "noUncheckedIndexedAccess", "strict"]
    ## Compiler options `tsconfig.json` sets to `true` (CONTRIBUTOR.md, TypeScript).


func checkMachinePaths*(path, source: string): seq[Finding] =
  ## Report line naming path of one machine (CONTRIBUTOR.md, System).
  let lines = source.splitLines
  for i, line in lines:
    for prefix in MACHINE_PATHS:
      if prefix in line:
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
  for flag in TYPESCRIPT_FLAGS:
    if not config.isFlagSet(flag):
      result.add finding(
        path,
        0,
        "`tsconfig.json` sets `" & flag & "` to `true` (CONTRIBUTOR.md, TypeScript); got none.",
      )
