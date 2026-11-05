## Answer every verb of this project: `nim r tools/build.nim <command>`, from project directory.
##
##   |-----------|--------------------------------------------------------------------------|
##   | Command   | Effect                                                                   |
##   |-----------|--------------------------------------------------------------------------|
##   | lists     | read `gismu.txt` lojban-common installs, check its digest against its    |
##   |           | pin, and write typed module under `src/`                                 |
##   | head      | read `gismu.txt`, `lujvo.txt` and `cmavo.txt` again, compare each digest |
##   |           | with its pin, and rendered gismu module with what is committed; exit 1   |
##   |           | where any differs, i.e. Debian moved list                                |
##   | system    | print packages `lists`, `head` and suites need, one per line             |
##   |-----------|--------------------------------------------------------------------------|
##   Exit: 0 done, 1 command failed or lists differ, 2 usage error.
##
##   Sibling `lojban_tagger/tools/build.nim` holds earlier copy of `lists` and `head`, which
##     render lujvo list too, until #809 (II.9).
##   `head` is verb CONTRIBUTOR.md gives check against outside reference that moves: package
##     can carry new list with no commit here, and no merge waits on it. It reads `lujvo.txt`
##     and `cmavo.txt` for digest alone, since suites read them as outside texts and render
##     nothing of them.
##   Rejected: reading lists at compile time from package directory, which would make every
##     build need package; committed gismu list serves every build, and `head` watches upstream.
##   Cost: driver runs from project directory, since every path here is relative to it.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/os

import ./lists


const
  USAGE = "Usage: nim r tools/build.nim <lists|head|system>\n"  ## Text printed on usage error.
  SYSTEM = [
    ("lojban-common", "word lists of Logical Language Group, read by `lists`, `head` and suites"),
    ("coreutils", "`sha256sum`, which `lists` and `head` check each list's digest with"),
  ]
    ## Packages verbs need, each with reason (Article II.8); `system` prints names alone.



#[ Verbs ]#

proc refuseDigests(sources: openArray[(string, string, string)]): int =
  ## Report each list whose digest left its pin, given as name, digest and pin; count reports.
  for (name, digest, pin) in sources:
    if digest == pin: continue
    stderr.writeLine "List moved from its pin in `tools/lists.nim`; read diff, then move pin; " &
        "got `" & digest & "` for `" & name & "`."
    inc result


proc writeLists(): int =
  ## Write gismu module where its digest matches its pin.
  let gismu = readSource("gismu.txt")
  if refuseDigests([("gismu.txt", gismu.digest, DIGEST_GISMU)]) > 0: return 1
  createDir(PATH_GISMU.parentDir)
  writeFile(PATH_GISMU, toModuleGismu(gismu.text.toEntriesGismu, gismu.digest))
  echo PATH_GISMU


proc compareLists(): int =
  ## Compare each digest, and rendered gismu module with committed one; 1 where any differs.
  let
    gismu = readSource("gismu.txt")
    lujvo = readSource("lujvo.txt")
    cmavo = readSource("cmavo.txt")
    rendered = toModuleGismu(gismu.text.toEntriesGismu, gismu.digest)
  var count_differing = refuseDigests([
    ("gismu.txt", gismu.digest, DIGEST_GISMU),
    ("lujvo.txt", lujvo.digest, DIGEST_LUJVO),
    ("cmavo.txt", cmavo.digest, DIGEST_CMAVO),
  ])
  if not fileExists(PATH_GISMU) or readFile(PATH_GISMU) != rendered:
    stderr.writeLine "Committed list differs from list rendered again; run `lists`; got `" &
        PATH_GISMU & "`."
    inc count_differing
  if count_differing > 0: 1 else: 0


proc main(): int =
  ## Dispatch command named as first argument.
  if paramCount() != 1:
    stderr.write USAGE
    return 2
  case paramStr(1)
  of "lists": writeLists()
  of "head": compareLists()
  of "system":
    for (name, _) in SYSTEM: echo name
    0
  else:
    stderr.write USAGE
    2


when isMainModule:
  quit main()
