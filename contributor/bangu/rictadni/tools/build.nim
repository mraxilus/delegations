## Answer every verb of this project: `nim r tools/build.nim <command>`, from project directory.
##
##   |-----------|--------------------------------------------------------------------------|
##   | Command   | Effect                                                                   |
##   |-----------|--------------------------------------------------------------------------|
##   | lists     | read `gismu.txt` and `lujvo.txt` lojban-common installs, check each      |
##   |           | digest against its pin, and write both typed modules under `src/`        |
##   | head      | read both lists again and compare digest and rendered module with what   |
##   |           | is committed; exit 1 where either differs, i.e. Debian moved list        |
##   | tagger    | compile `app/tagger.nim`, in release mode, to `binaries/tagger`          |
##   | suggester | compile `app/suggester.nim`, in release mode with TLS, to                |
##   |           | `binaries/suggester`                                                     |
##   | examples  | write worked examples of `suggester` as exchange files under             |
##   |           | `build/examples/`, and print command replaying each                      |
##   | page      | build tag page into `build/page/tagger.html` (`tools/page.nim`)          |
##   | drive     | build tag page, collect what it draws in Chromium, and write             |
##   |           | `build/font-faces/written.json`, which `koch drive` judges               |
##   | system    | print packages verbs, `suggester` and suites need, one per line:         |
##   |           | `openssl` and `protoc` commands among them, which `test_exchanges` runs  |
##   |-----------|--------------------------------------------------------------------------|
##   Exit: 0 done, 1 command failed or lists differ, 2 usage error.
##
##   `head` is verb CONTRIBUTOR.md gives check against outside reference that moves: package
##     can carry new list with no commit here, and no merge waits on it.
##   Sibling: `lists` and `head` of `ricysoho/tools/build.nim` take same steps over lists of
##     parser, and read same sources by same pins (`tools/lists.nim`). Each driver renders and
##     watches lists of its own project, and no driver exports verb, so steps stand in both,
##     here in `tools/lists.nim` (II.9); fix to one is finished only when other is checked.
##   Rejected: reading lists at compile time from package directory, which would make every
##     build need package; list changes seldom, so committed copy serves every build and `head`
##     watches upstream.
##   `head` holds no check of language model service: CI gives project jobs no secret, and live
##     call would cost money every day.
##   `lists`, `head`, `examples`, `page` and `drive` run as own programs, so driver imports no
##     package:
##     `koch list-packages` compiles and runs driver before Atlas restores any, and CI installs
##     what `system` prints (`suites/test_build.nim`).
##   Cost: driver runs from project directory, since every path here is relative to it.

{.experimental: "strictFuncs".}

when compileOption("profiler"):
  import std/nimprof

import std/[os, osproc]


const
  USAGE = "Usage: nim r tools/build.nim <lists|head|tagger|suggester|examples|page|drive|" &
      "system>\n"
    ## Text printed on usage error.
  PATH_TAGGER = "binaries" / "tagger"  ## Binary `tagger` compiles to; root `.gitignore` covers it.
  PATH_SUGGESTER = "binaries" / "suggester"  ## Binary `suggester` compiles to; git ignores it.
  SYSTEM = [
    ("lojban-common", "word lists of Logical Language Group, which `lists` and `head` read"),
    ("coreutils", "`sha256sum`, which `lists` and `head` check each list's digest with"),
    ("libssl3", "TLS of `std/httpclient` under `-d:ssl`; `suggester` loads it when it starts"),
    ("ca-certificates", "roots `suggester` checks services and pages against"),
    ("openssl", "command `test_exchanges` makes test root and leaves with, at run time"),
    ("protobuf-compiler", "`protoc`, which `test_exchanges` encodes text format file with"),
    ("unzip", "unpacks Chromium of store, which `drive` runs tag page in"),
    ("libbrotli1", "`koch drive` reads `woff2` font face of tag page through it"),
  ]
    ## Packages verbs, `suggester` and suites need, each with reason (Article II.8); `system`
    ##   prints names alone.



#[ Verbs ]#

proc compileTagger(): int =
  ## Compile `tagger` in release mode; exit code of compiler.
  let command = "nim c --hints:off -d:release -o:" & quoteShell(PATH_TAGGER) & " app/tagger.nim"
  result = execCmd(command)
  if result == 0: echo PATH_TAGGER


proc compileSuggester(): int =
  ## Compile `suggester` in release mode with TLS; exit code of compiler. Sibling of compile
  ##   command in `tests/suites/test_suggester.nim`, which builds without release (II.9).
  let command = "nim c --hints:off -d:release -d:ssl -o:" & quoteShell(PATH_SUGGESTER) &
      " app/suggester.nim"
  result = execCmd(command)
  if result == 0: echo PATH_SUGGESTER


proc main(): int =
  ## Dispatch command named as first argument.
  if paramCount() != 1:
    stderr.write USAGE
    return 2
  case paramStr(1)
  of "lists": execCmd("nim r --hints:off tools/lists.nim lists")
  of "head": execCmd("nim r --hints:off tools/lists.nim head")
  of "tagger": compileTagger()
  of "suggester": compileSuggester()
  of "examples": execCmd("nim r --hints:off tools/examples.nim")
  of "page": execCmd("nim r --hints:off tools/page.nim page")
  of "drive": execCmd("nim r --hints:off tools/page.nim drive")
  of "system":
    for (name, _) in SYSTEM: echo name
    0
  else:
    stderr.write USAGE
    2


when isMainModule:
  quit main()
