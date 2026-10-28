## Run `tagger`: read index file, answer one verb, write index back where verb changed it.
##   `nim r tools/build.nim tagger` compiles it to `binaries/tagger`; verbs are in
##   `commands.nim`, which this file only wires to files, environment and streams.
##
##   Index path is `--index:<path>` where first argument names it, else environment's
##     `LOJBAN_TAGGER_INDEX`, else `lojban_tagger/index` under data directory of XDG, which
##     `getDataDir` resolves; nothing names path of one machine (CONTRIBUTOR.md, System).
##   Absent file reads as empty index, so first `tag` makes it.
##   Write goes to sibling file, then renames over index, so interrupted write never leaves
##     half index; rename within one directory is atomic on POSIX.
##   Cost: concurrent `tagger` runs race; last rename wins and other change is lost.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[os, strutils]

import ../src/lojban_tagger


const
  KEY_INDEX = "LOJBAN_TAGGER_INDEX"  ## Environment name overriding where index is read.
  FLAG_INDEX = "--index:"  ## Prefix of first argument naming index path.



#[ Files ]#

proc pathIndex(arguments: var seq[string]): string =
  ## Resolve index path, consuming `--index:<path>` where first argument names it.
  if arguments.len > 0 and arguments[0].startsWith(FLAG_INDEX):
    result = arguments[0][FLAG_INDEX.len .. ^1]
    arguments.delete(0)
    return
  getEnv(KEY_INDEX, getDataDir() / "lojban_tagger" / "index")


proc main(): int =
  ## Read index, answer verb, write index where changed, print output and report.
  var arguments = commandLineParams()
  let path = pathIndex(arguments)
  var before: Index
  if fileExists(path):
    let loaded = readFile(path).readIndex
    if not loaded.is_loaded:
      stderr.writeLine path & ":" & $loaded.line & ": " & loaded.problem
      return 1
    before = loaded.index
  let outcome = run(arguments, before)
  if outcome.is_changed:
    createDir(path.parentDir)
    writeFile(path & ".writing", outcome.index.toText)
    moveFile(path & ".writing", path)
  stdout.write outcome.output
  stderr.write outcome.report
  outcome.code


when isMainModule:
  quit main()
