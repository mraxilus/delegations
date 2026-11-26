## Run `tagger`: read index file, answer one verb, write index back where verb changed it.
##   `nim r tools/build.nim tagger` compiles it to `binaries/tagger`; verbs are in
##   `commands.nim`, which this file only wires to files, environment and streams.
##
##   Index path is `--index:<path>` where first argument names it, else environment's
##     `RICTADNI_INDEX`, else `rictadni/index` under data directory of XDG, which `getDataDir`
##     resolves; nothing names path of one machine (CONTRIBUTOR.md, System). Empty variable
##     reads as unset.
##   Names before project took name `rictadni` still read, as D1 on #946 ruled:
##     `LOJBAN_TAGGER_INDEX` where `RICTADNI_INDEX` is unset, and `lojban_tagger/index` where
##     new folder holds no index. Change writes new folder, and old file stays as it was.
##   Absent file reads as empty index, so first `tag` makes it.
##   Write goes to sibling file, then renames over index, so interrupted write never leaves
##     half index; rename within one directory is atomic on POSIX.
##   Cost: concurrent `tagger` runs race; last rename wins and other change is lost.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[os, strutils]

import ../src/rictadni


type
  Paths = object  ## Define where index is read from, and where change to it is written.
    read: string  ## Path index is read from.
    written: string  ## Path change is written to.


const
  KEYS_INDEX = ["RICTADNI_INDEX", "LOJBAN_TAGGER_INDEX"]
    ## Environment names overriding where index is read, first nonempty winning; second is name
    ##   before rename (#946).
  FOLDERS_INDEX = ["rictadni", "lojban_tagger"]
    ## Folders of data directory holding index: first written, second read where first holds
    ##   none, as folder before rename (#946).
  FILE_INDEX = "index"  ## Name of index file in its folder.
  FLAG_INDEX = "--index:"  ## Prefix of first argument naming index path.



#[ Files ]#

proc pathsIndex(arguments: var seq[string]): Paths =
  ## Resolve index paths, consuming `--index:<path>` where first argument names it; path named
  ##   is both read and written.
  if arguments.len > 0 and arguments[0].startsWith(FLAG_INDEX):
    let path = arguments[0][FLAG_INDEX.len .. ^1]
    arguments.delete(0)
    return Paths(read: path, written: path)
  for key in KEYS_INDEX:
    let path = getEnv(key)
    if path.len > 0: return Paths(read: path, written: path)
  let
    written = getDataDir() / FOLDERS_INDEX[0] / FILE_INDEX
    old = getDataDir() / FOLDERS_INDEX[1] / FILE_INDEX
  Paths(read: (if not fileExists(written) and fileExists(old): old else: written),
      written: written)


proc main(): int =
  ## Read index, answer verb, write index where changed, print output and report.
  var arguments = commandLineParams()
  let paths = pathsIndex(arguments)
  var before: Index
  if fileExists(paths.read):
    let loaded = readFile(paths.read).readIndex
    if not loaded.is_loaded:
      stderr.writeLine paths.read & ":" & $loaded.line & ": " & loaded.problem
      return 1
    before = loaded.index
  let outcome = run(arguments, before)
  if outcome.is_changed:
    createDir(paths.written.parentDir)
    writeFile(paths.written & ".writing", outcome.index.toText)
    moveFile(paths.written & ".writing", paths.written)
  stdout.write outcome.output
  stderr.write outcome.report
  outcome.code


when isMainModule:
  quit main()
