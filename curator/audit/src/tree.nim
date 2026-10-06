## Enumerate repository through git and read registered files into `Tree`.
##   Git decides what exists: tracked plus untracked-unignored files, so build products
##   never reach checks and every file that would commit does. Paths arrive NUL-separated
##   (`-z`), so no path is ever quoted, whatever it holds.
##   Same door serves branch context: changed paths, paths base gained, commit subjects since
##   base, and oldest commit outside `--recent` window.
##
##   Git runs as direct process with argument list, never through shell, through knoller's
##     `runGit`, which command line of knoller lists directory with too: no quoting, and
##     `execCmdEx` is rejected because it reads by line, appends newline to NUL output, and
##     joins stderr to stdout.
##
##   Cost: needs git on PATH and repository root; tests build throwaway repositories.

{.experimental: "strictFuncs".}

import std/[algorithm, options, os, sequtils, strutils]
from ../../knoller/src/knoller/command import runGit
import ./[commits, kinds, layout]

export layout.Entry, layout.Tree


proc gitFields*(root: string, arguments: openArray[string]): seq[string] =
  ## Run git in root, return NUL-separated stdout fields; raise on non-zero exit.
  ##   Streams are read apart (`runGit`). Git writes warning to stderr, ending it in newline
  ##     rather than in NUL, so stream carrying both would leave warning glued to first field.
  ##     `diff base...HEAD` warns whenever branch and base share two merge bases, which is
  ##     ordinary, and glued field then starts with `warning:` rather than with path.
  ##   Stderr is kept rather than dropped: it is where git says why it failed, and `IOError`
  ##     carries it.
  let (output, failure, code) = runGit(root, arguments)
  if code != 0: raise newException(IOError, "git failed; got `" & failure.strip & "`.")
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
    let
      kind = path.kindOf
      content = if kind.isSome: readFile(root / path) else: ""
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
    root,
    ["diff", "-z", "--name-status", "--find-renames=100%", base & "...HEAD"],
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


proc branchCommits*(root, base: string): seq[Commit] =
  ## Read commits reachable from HEAD but not `base`, newest first, merges excluded.
  ##   Paths come from `diff-tree` of each commit, so rename reads as both of its paths.
  for hash in gitFields(root, ["log", "-z", "--format=%H", "--no-merges", base & "..HEAD"]):
    let
      name = hash.strip
      message = gitFields(root, ["log", "-1", "-z", "--format=%s%x1f%b", name])[0]
      parts = message.split('\x1f', 1)
    result.add Commit(
      subject: parts[0],
      body: (if parts.len > 1: parts[1] else: ""),
      paths: gitFields(root, ["diff-tree", "-z", "--no-commit-id", "--name-only", "-r", name]),
    )
