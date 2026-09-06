## Enumerate repository through git and read registered files into `Tree`.
##   Git decides what exists: tracked plus untracked-unignored files, so build products
##   never reach checks and every file that would commit does. Paths arrive NUL-separated
##   (`-z`), so no path is ever quoted, whatever it holds.
##   Same door serves branch context: changed paths, paths base gained, commit subjects since
##   base, and oldest commit outside sweep window.
##
##   Git runs as direct process with argument list, never through shell: no quoting, and
##     `execCmdEx` is rejected because it reads by line and appends newline to NUL output.
##
##   Cost: needs git on PATH and repository root; tests build throwaway repositories.

{.experimental: "strictFuncs".}

import std/[algorithm, options, os, osproc, sequtils, streams, strutils]
import ./[kinds, layout]

export layout.Entry, layout.Tree


proc gitFields*(root: string, args: openArray[string]): seq[string] =
  ## Run git in root, return NUL-separated stdout fields; raise on non-zero exit.
  let process = startProcess(
    "git", args = @["-C", root] & @args, options = {poUsePath, poStdErrToStdOut}
  )
  defer: process.close
  let output = process.outputStream.readAll
  if process.waitForExit != 0:
    raise newException(IOError, "git failed; got `" & output.strip & "`.")
  output.split('\0').filterIt(it.len > 0)


proc listPaths*(root: string): seq[string] =
  ## List files git sees, i.e. cached plus others minus ignored, existing on disk, sorted.
  gitFields(root, ["ls-files", "-z", "--cached", "--others", "--exclude-standard"])
    .filterIt(fileExists(root / it))
    .deduplicate
    .sorted


proc readTree*(root: string): Tree =
  ## Read every listed file whose kind is registered; unregistered entries carry no content.
  for path in root.listPaths:
    let kind = path.kindOf
    let content = if kind.isSome: readFile(root / path) else: ""
    result.add Entry(path: path, kind: kind, content: content)


proc changedPaths*(root, base: string): seq[string] =
  ## List paths differing between merge base of `base` and HEAD; renames show as two paths.
  gitFields(root, ["diff", "-z", "--name-only", "--no-renames", base & "...HEAD"])


proc revBefore*(root: string, days: int): string =
  ## Read newest commit older than window; empty when no commit is that old.
  ##   Output is newline-terminated rather than NUL-separated, so field is stripped.
  let fields = gitFields(root, ["rev-list", "-1", "--before=" & $days & " days ago", "HEAD"])
  if fields.len == 0: "" else: fields[0].strip


proc movedPaths*(root, base: string): seq[string] =
  ## List paths on both sides of content-preserving rename, i.e. file moved and not edited.
  ##   `--name-status -M100%` reports `R100`, old path, new path; only exact renames count,
  ##   so edited file is never mistaken for moved one.
  let fields = gitFields(
    root, ["diff", "-z", "--name-status", "--find-renames=100%", base & "...HEAD"]
  )
  var i = 0
  while i + 2 < fields.len:
    if fields[i].startsWith("R"):
      result.add fields[i + 1]
      result.add fields[i + 2]
      i += 3
    else:
      i += 2


proc gainedPaths*(root, base: string): seq[string] =
  ## List paths base holds that branch does not, i.e. what base gained since branch forked.
  ##   Mirror of `changedPaths`: same three-dot range, other way round.
  gitFields(root, ["diff", "-z", "--name-only", "--no-renames", "HEAD..." & base])


proc subjects*(root, base: string): seq[string] =
  ## List commit subjects reachable from HEAD but not `base`, merges excluded.
  gitFields(root, ["log", "-z", "--format=%s", "--no-merges", base & "..HEAD"])
