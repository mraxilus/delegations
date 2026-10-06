## Ask semantic pass of knoller (`symbols.nim` there) about files of tree, each through
##   `nimsuggest` of toolchain serving its project's pin, for fixers whose rule text cannot
##   settle (`koch fix`, `koch check`).
##   Tree tells what knoller's command line reads from disk: project of path is its directory,
##     whose nimble file names pin, root file takes pin of driver, and includer of file is read
##     among Nim files of tree. Pass runs at root of project, root for root file.
##
##   Cost: file whose pin nothing serves, or whose project pins no compiler, is answered
##     unresolved with reason, and asks nothing.

{.experimental: "strictFuncs".}

import std/[options, os, sequtils, strutils]
import ../../knoller/src/knoller
import ./[layout, plan, toolchain]


func includerOf*(tree: Tree, path: string): string =
  ## Read file whose `include` names path, followed up to file nothing includes; path itself
  ##   where nothing includes it.
  tree.mapIt((it.path, it.content)).includerOf(path)


func directoryOf(path: string): string =
  ## Read project directory of path; empty for file at root, such as `koch.nim`.
  path.split('/').directoryProject


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
      directory = query.path.directoryOf
      pin = tree.pinOf(if directory.len == 0: DIRECTORY_DRIVER else: directory)
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
      includer: tree.includerOf(query.path),
      bin: bin.get,
    )
  result.add resolve(requests)
