## Ask semantic pass of knoller (`symbols.nim` there) about files of tree, each through
##   `nimsuggest` of toolchain serving its project's pin, for fixers whose rule text cannot
##   settle (`koch fix`, `koch check`).
##   Tree tells what knoller's command line reads from disk: project of path is its directory,
##     whose nimble file names pin, root file takes pin of driver, and includer of file is read
##     among Nim files of tree. Pass runs at root of project, root for root file.
##   File under `tests/` of project compiles with `-d:testing`, as each stub of this repository
##     passes it (STYLE.md §6); define is habit of this repository, so knoller names none, and
##     koch names it for each file (`defines`).
##
##   Cost: file whose pin nothing serves, or whose project pins no compiler, is answered
##     unresolved with reason, and asks nothing.

{.experimental: "strictFuncs".}

import std/[options, os, sequtils, strutils]
import ../../knoller/src/knoller
import ./[layout, plan, toolchain]


const DEFINE_TESTING = "-d:testing"  ## Define each stub of this repository passes (STYLE.md §6).


func includer*(tree: Tree, path: string): string =
  ## Read file whose `include` names path, followed up to file nothing includes; path itself
  ##   where nothing includes it.
  tree.mapIt((it.path, it.content)).includer(path)


func directoryProject(path: string): string =
  ## Read project directory of path; empty for file at root, such as `koch.nim`.
  path.split('/').directoryProject


func defines(path: string): seq[string] =
  ## Read options compile of file takes, as stubs of its project compile it: `-d:testing` under
  ##   `tests/` of project, none elsewhere.
  let directory = path.directoryProject
  if directory.len > 0 and path.startsWith(directory & "/" & DIRECTORY_TESTS & "/"):
    result.add DEFINE_TESTING


proc resolve*(root: string, tree: Tree, queries: openArray[Query]): seq[Answer] =
  ## Answer each query through `nimsuggest` of its project's pin; file whose pin nothing serves,
  ##   or which compiles on no backend, is answered unresolved with reason.
  if queries.len == 0: return
  var
    toolchains = initToolchains()
    requests: seq[Request]
  let absolute = root.absolutePath
  for query in queries:
    let
      directory = query.path.directoryProject
      pin = tree.pin(if directory.len == 0: DIRECTORY_DRIVER else: directory)
    if pin.isNone:
      result.add Answer(path: query.path, reason: "project pins no compiler")
      continue
    let bin = toolchains.binFor(pin.get)
    if bin.isNone:
      result.add Answer(path: query.path, reason: "no compiler serves pin `" & pin.get & "`")
      continue
    requests.add Request(
      query: query,
      root: absolute,
      directory: absolute / directory,
      includer: tree.includer(query.path),
      bin: bin.get,
      defines: query.path.defines,
    )
  result.add resolve(requests)
