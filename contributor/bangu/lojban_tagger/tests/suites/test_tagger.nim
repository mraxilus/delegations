## Drive built `tagger` through real index file, environment and streams: suite compiles
##   `app/tagger.nim`, then drives binary it built, so verdict holds for that build (IX.5-6).
##   CLL covers no binary, so suite is `Internal:`, tests named by behaviour (Article IX.10).
##   Binary, index files and compiler cache live in fresh directory under `getTempDir`, named by
##     fixed prefix and process, and removed at end.
##   Environment reaches binary as shell prefix, never through `putEnv`, so process running suite
##     keeps environment it started with; standard error goes to file, so output and report are
##     read apart.
##   Index file written by binary is compared with `toText` of index expected, byte for byte, so
##     writer is checked through file, not through `run`.
##   Cost: compile of `tagger` with fresh cache adds seconds to every run of suite.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[os, osproc, sequtils, strutils, unittest]

import ../../src/lojban_tagger/[commands, index, tags]


type
  Answer = object  ## Define what one run of `tagger` prints and exits with.
    output: string  ## Standard output.
    report: string  ## Standard error.
    code: int  ## Exit code.


const
  PREFIX_DIRECTORY = "lojban_tagger_suite_tagger_"  ## Opening of temporary directory name.
  KEY_INDEX = "LOJBAN_TAGGER_INDEX"  ## Environment name `app/tagger.nim` reads index path from.
  NIM = getCurrentCompilerExe()  ## Compiler building suite, which builds `tagger` too.
  PATH_APP = currentSourcePath().parentDir.parentDir.parentDir / "app" / "tagger.nim"
    ## Source of `tagger`, found from this file.


proc runTagger(binary, path_index: string; arguments: openArray[string]): Answer =
  ## Run `tagger` with `KEY_INDEX` naming `path_index`; output and report read apart.
  let
    path_report = binary.parentDir / "report"
    command = KEY_INDEX & "=" & quoteShell(path_index) & " " &
        (@[binary] & @arguments).map(quoteShell).join(" ") & " 2>" & quoteShell(path_report)
    (output, code) = execCmdEx(command, options = {poUsePath})
  Answer(output: output, report: readFile(path_report), code: code)


func toIndex(rows: openArray[(string, seq[string])]): Index =
  ## Build index tagging each name with each word, read as tag.
  for (name, words) in rows: result.addTags(name, words.mapIt(it.readTag.tag))



suite "Internal: Tagger":
  let
    directory = getTempDir() / (PREFIX_DIRECTORY & $getCurrentProcessId())
    binary = directory / "tagger"
  removeDir(directory)
  createDir(directory)
  let (output_compile, code_compile) = execCmdEx(
    quoteShell(NIM) & " c --hints:off --nimcache:" & quoteShell(directory / "cache") & " -o:" &
    quoteShell(binary) & " " & quoteShell(PATH_APP),
  )


  test "binary builds from `app/tagger.nim`":
    checkpoint output_compile
    check code_compile == 0  # one command rebuilds, then drives
    check fileExists(binary)  # binary written where asked


  test "tag writes index file, which find reads back by gismu and by English":
    let
      path = directory / "tagging" / "index"  # directory made by first write
      first = runTagger(binary, path, ["tag", "notes/plan.md", "datni", "vreji"])
    check first.code == 0 and first.report == ""  # done, nothing to report
    check first.output == "notes/plan.md\tdatni vreji\n"  # entity line printed
    check readFile(path) ==
        toIndex([("notes/plan.md", @["datni", "vreji"])]).toText  # written text of index
    let second = runTagger(binary, path, ["tag", "notes/plan.md", "datnyvei"])
    check second.output == "notes/plan.md\tdatni vreji datnyvei\n"  # tag added to file read
    check runTagger(binary, path, ["tag", "photo", "pixra"]).code == 0  # second entity
    check readFile(path) == toIndex([
      ("notes/plan.md", @["datni", "vreji", "datnyvei"]),
      ("photo", @["pixra"]),
    ]).toText  # file holds what each run added, written text of index
    check not fileExists(path & ".writing")  # sibling renamed over index, none left
    let gismu = runTagger(binary, path, ["find", "vreji"])
    check gismu.code == 0 and gismu.output == "notes/plan.md\tdatni vreji datnyvei\n"  # gismu
    check gismu.report == "`vreji` reads as tag `vreji`.\n"  # report on standard error
    let english = runTagger(binary, path, ["find", "file"])
    check english.code == 0 and english.output == gismu.output  # English of gloss finds it
    check english.report.startsWith("`file` reads as English: ")  # term read as English
    let none = runTagger(binary, path, ["find", "gerku"])
    check none.code == 1 and none.output == ""  # nothing found exits 1


  test "untag rewrites index file, and entity left with no tag leaves it":
    let path = directory / "untagging"
    writeFile(path, toIndex([("notes", @["datni", "datnyvei"]), ("photo", @["pixra"])]).toText)
    let first = runTagger(binary, path, ["untag", "notes", "datni"])
    check first.code == 0 and first.output == "notes\tdatnyvei\n"  # tag left printed
    check readFile(path) ==
        toIndex([("notes", @["datnyvei"]), ("photo", @["pixra"])]).toText  # tag gone from file
    let last = runTagger(binary, path, ["untag", "notes", "datnyvreji"])
    check last.code == 0 and last.output == ""  # last tag, by other spelling, takes entity
    check readFile(path) == toIndex([("photo", @["pixra"])]).toText  # entity gone from file
    check runTagger(binary, path, ["show"]).output == "photo\tpixra\n"  # show reads file
    let missing = runTagger(binary, path, ["show", "notes"])
    check missing.code == 1  # entity gone, so show refuses it
    check missing.report == "Entity should be in index; got `notes`.\n"  # report names it


  test "refused verb leaves index file as it was":
    let path = directory / "refusing"
    writeFile(path, toIndex([("notes", @["datni"])]).toText)
    let
      before = readFile(path)
      refused = runTagger(binary, path, ["tag", "notes", "vreji", "bi"])
    check refused.code == 1 and refused.output == ""  # one refused word stops all
    check refused.report == readTag("bi").explain & "\n"  # refusal on standard error
    check readFile(path) == before  # file untouched
    let usage = runTagger(binary, path, [])
    check usage.code == 2 and usage.report == USAGE  # usage error prints usage
    check readFile(path) == before  # file untouched


  test "option `--index` wins over environment":
    let (path_environment, path_option) = (directory / "environment", directory / "option")
    writeFile(path_environment, toIndex([("notes", @["datni"])]).toText)
    let
      before = readFile(path_environment)
      tagged = runTagger(
        binary, path_environment, ["--index:" & path_option, "tag", "photo", "pixra"]
      )
    check tagged.code == 0 and tagged.output == "photo\tpixra\n"  # option consumed, verb ran
    check readFile(path_option) == toIndex([("photo", @["pixra"])]).toText  # option's file
    check readFile(path_environment) == before  # environment's file untouched
    let shown = runTagger(binary, path_environment, ["--index:" & path_option, "show"])
    check shown.output == "photo\tpixra\n"  # option's file read


  test "absent index file reads as empty, and only change makes it":
    let
      path = directory / "absent"
      shown = runTagger(binary, path, ["show"])
    check shown.code == 0 and shown.output == "" and shown.report == ""  # empty index
    check runTagger(binary, path, ["find", "datni"]).code == 1  # empty index finds nothing
    check runTagger(binary, path, ["untag", "notes", "datni"]).code == 0  # nothing to remove
    check not fileExists(path)  # no verb changed index, so none wrote it


  test "malformed index file exits 1, naming path, line and offending text":
    let path = directory / "malformed"
    for (text, line, problem) in [
      ("lojban_tagger index 2\n", 1, "Header should read `" & HEADER &
          "`; got `lojban_tagger index 2`."),
      (HEADER & "\nnotes datni\n", 2, "Line should hold name, tab, then tags; got `notes datni`."),
      (HEADER & "\nnotes\tdatnyvei\n", 2,
          "Tag should be gismu of list joined by `+`; got `datnyvei`."),
    ]:
      writeFile(path, text)
      let shown = runTagger(binary, path, ["tag", "photo", "pixra"])
      check shown.code == 1 and shown.output == ""  # refused before verb
      check shown.report == path & ":" & $line & ": " & problem & "\n"  # path:line: problem
      check readFile(path) == text  # malformed file never overwritten

  removeDir(directory)
