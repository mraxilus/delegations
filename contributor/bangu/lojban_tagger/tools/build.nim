## Answer every verb of this project: `nim r tools/build.nim <command>`, from project directory.
##
##   |---------|----------------------------------------------------------------------------|
##   | Command | Effect                                                                     |
##   |---------|----------------------------------------------------------------------------|
##   | lists   | read `gismu.txt` and `lujvo.txt` lojban-common installs, check each digest |
##   |         | against its pin, and write both typed modules under `src/lojban_tagger/`   |
##   | head    | read both lists again and compare digest and rendered module with what is  |
##   |         | committed; exit 1 where either differs, i.e. Debian moved list             |
##   | tagger  | compile `app/tagger.nim`, in release mode, to `binaries/tagger`            |
##   | system  | print packages `lists` and `head` need, one per line                       |
##   |---------|----------------------------------------------------------------------------|
##   Exit: 0 done, 1 command failed or lists differ, 2 usage error.
##
##   `head` is verb CONTRIBUTOR.md gives check against outside reference that moves: package
##     can carry new list with no commit here, and no merge waits on it.
##   Rejected: reading lists at compile time from package directory, which would make every
##     build need package; CI `test` job installs none, and list changes seldom, so committed
##     copy serves every build and `head` watches upstream.
##   Cost: driver runs from project directory, since every path here is relative to it.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[os, osproc]

import ./lists


const
  USAGE = "Usage: nim r tools/build.nim <lists|head|tagger|system>\n"
    ## Text printed on usage error.
  PATH_TAGGER = "binaries" / "tagger"  ## Binary `tagger` compiles to; root `.gitignore` covers it.
  SYSTEM = [
    ("lojban-common", "word lists of Logical Language Group, which `lists` and `head` read"),
    ("coreutils", "`sha256sum`, which `lists` and `head` check each list's digest with"),
  ]
    ## Packages verbs need, each with reason (Article II.8); `system` prints names alone.



#[ Verbs ]#

proc readLists(): tuple[gismu, lujvo: string, digests: array[2, string]] =
  ## Read both lists and render both modules, with digest each source carries.
  let
    gismu = readSource("gismu.txt")
    lujvo = readSource("lujvo.txt")
    (entries, count_left) = lujvo.text.toEntriesLujvo
  (
    toModuleGismu(gismu.text.toEntriesGismu, gismu.digest),
    toModuleLujvo(entries, count_left, lujvo.digest),
    [gismu.digest, lujvo.digest],
  )


proc refuseDigests(digests: array[2, string]): int =
  ## Report each list whose digest left its pin; count reports.
  for (name, digest, pin) in [
    ("gismu.txt", digests[0], DIGEST_GISMU),
    ("lujvo.txt", digests[1], DIGEST_LUJVO),
  ]:
    if digest == pin: continue
    stderr.writeLine "List moved from its pin in `tools/lists.nim`; read diff, then move pin; " &
        "got `" & digest & "` for `" & name & "`."
    inc result


proc writeLists(): int =
  ## Write both modules where both digests match their pins.
  let (gismu, lujvo, digests) = readLists()
  if refuseDigests(digests) > 0: return 1
  createDir(PATH_GISMU.parentDir)
  writeFile(PATH_GISMU, gismu)
  writeFile(PATH_LUJVO, lujvo)
  echo PATH_GISMU
  echo PATH_LUJVO


proc compareLists(): int =
  ## Compare digests and rendered modules with committed modules; 1 where any differs.
  let (gismu, lujvo, digests) = readLists()
  var count_differing = refuseDigests(digests)
  for (path, rendered) in [(PATH_GISMU, gismu), (PATH_LUJVO, lujvo)]:
    if fileExists(path) and readFile(path) == rendered: continue
    stderr.writeLine "Committed list differs from list rendered again; run `lists`; got `" &
        path & "`."
    inc count_differing
  if count_differing > 0: 1 else: 0


proc compileTagger(): int =
  ## Compile `tagger` in release mode; exit code of compiler.
  let command = "nim c --hints:off -d:release -o:" & quoteShell(PATH_TAGGER) & " app/tagger.nim"
  result = execCmd(command)
  if result == 0: echo PATH_TAGGER


proc main(): int =
  ## Dispatch command named as first argument.
  if paramCount() != 1:
    stderr.write USAGE
    return 2
  case paramStr(1)
  of "lists": writeLists()
  of "head": compareLists()
  of "tagger": compileTagger()
  of "system":
    for (name, _) in SYSTEM: echo name
    0
  else:
    stderr.write USAGE
    2


when isMainModule:
  quit main()
