## Enumerate repository through git and read registered files into `Tree`.
##   Git decides what exists: tracked plus untracked-unignored files, so build products
##   never reach checks and every file that would commit does. Paths arrive NUL-separated
##   (`-z`), so no path is quoted, whatever it holds. Patch that `linesOwned` reads is one
##   exception: there git quotes path holding quote, backslash or control character, and such
##   path owns no line.
##   Same door serves branch context: checkout holding directory, changed paths, paths base
##   gained, file as revision holds it, commit subjects since base, and oldest commit outside
##   `--recent` window.
##
##   Git runs as direct process with argument list, never through shell, through knoller's
##     `runGit`, which command line of knoller lists directory with too: no quoting, and
##     `execCmdEx` is rejected because it reads by line, appends newline to NUL output, and
##     joins stderr to stdout.
##
##   Cost: needs git on PATH and repository root; tests build throwaway repositories.

{.experimental: "strictFuncs".}

import std/[algorithm, options, os, sequtils, sets, strutils, tables]
from ../../knoller/src/knoller/chain import FILE_LOCK
from ../../knoller/src/knoller/command import runGit
import ./[commits, english, kinds, layout, scope]

export layout.Entry, layout.Tree


proc fieldsGit*(root: string, arguments: openArray[string]): seq[string] =
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


proc checkoutAt*(root, directory: string): Option[string] =
  ## Read top of checkout of this repository holding directory; none where git places directory
  ##   in other repository, which keeps its own branch, since hook holds this repository alone.
  ##   Worktree shares root's git store, so both name one common directory. Directory in no
  ##     repository, or git failing, reads as root, so failure still holds root's rule. Path not
  ##     yet written is read from nearest directory that exists.
  ##   Root reads by its real path there too, as git names each other top, so file whose links
  ##     `pathReal` resolved compares with it whichever way root is spelt (#883).
  var at = directory
  while at.len > 1 and not dirExists(at): at = at.parentDir
  const common = ["rev-parse", "--path-format=absolute", "--git-common-dir"]
  try:
    if fieldsGit(at, common)[0].strip != fieldsGit(root, common)[0].strip: return none(string)
    return some(fieldsGit(at, ["rev-parse", "--show-toplevel"])[0].strip)
  except IOError: discard
  try: some(expandFilename(root))
  except OSError: some(root)


proc listPaths*(root: string): seq[string] =
  ## List files git sees, i.e. cached plus others minus ignored, existing on disk, sorted.
  fieldsGit(root, ["ls-files", "-z", "--cached", "--others", "--exclude-standard"])
    .filterIt(fileExists(root / it))
    .deduplicate
    .sorted


proc readTree*(root: string): Tree =
  ## Read every listed file whose kind is registered; unregistered entries carry no content.
  for path in root.listPaths:
    let
      kind = path.classify
      content = if kind.isSome: readFile(root / path) else: ""
    result.add Entry(path: path, kind: kind, content: content)


proc pathsChanged*(root, base: string): seq[string] =
  ## List paths differing between merge base of `base` and HEAD; renames show as two paths.
  fieldsGit(root, ["diff", "-z", "--name-only", "--no-renames", base & "...HEAD"])


func linesHunks*(diff: string): Table[string, HashSet[int]] =
  ## Read lines each hunk of `git diff -U0 --no-prefix` adds, by path after change; deleted file
  ##   adds none, and hunk that only deletes owns line on each side of it, which may now join.
  ##   Header of file runs from `diff --git` to its first hunk, so body line opening `+++` is
  ##     content, never path. Git ends path holding space with tab, which is cut.
  var
    path = ""
    is_header = false
  for line in diff.splitLines:
    if line.startsWith("diff --git "): (path, is_header) = ("", true)
    elif is_header and line.startsWith("+++ "):
      let named = line["+++ ".len .. ^1].strip(leading = false, chars = {'\t'})
      path = if named == "/dev/null": "" else: named
    elif line.startsWith("@@ "):
      is_header = false
      if path.len == 0: continue
      let
        span = line.split(' ')[2][1 .. ^1].split(',')  # `+start[,count]` of new side
        start = span[0].parseInt
        count = if span.len > 1: span[1].parseInt else: 1
        lines =
          if count == 0: toSeq(max(start, 1) .. start + 1)  # deletion: line on each side
          else: toSeq(start ..< start + count)
      for n in lines: result.mgetOrPut(path, initHashSet[int]()).incl n


proc linesOwned*(root: string, tree: Tree, base: string): Table[string, HashSet[int]] =
  ## Read lines branch changed since merge base of `base`, working tree included, each widened
  ##   to opening of its prose block (`linesOpening`); exact rename changes no line.
  ##   Working tree is read, as `readTree` reads it, so line of finding and of change agree.
  ##   Cost: file git does not track yet owns no line, until it is added.
  let
    fork = fieldsGit(root, ["merge-base", base, "HEAD"])[0].strip
    (output, failure, code) = runGit(root, [
      "-c", "core.quotePath=false", "diff", "-U0", "--no-color", "--no-prefix",
      "--find-renames", fork,
    ])
  if code != 0: raise newException(IOError, "git failed; got `" & failure.strip & "`.")
  result = output.linesHunks
  for entry in tree:
    if entry.kind == some(Kind.Markdown) and entry.path in result:
      result[entry.path] = linesOpening(entry.content, result[entry.path])


proc revBefore*(root: string, days: int): string =
  ## Read newest commit older than window; empty when no commit is that old.
  ##   Output is newline-terminated rather than NUL-separated, so field is stripped.
  let fields = fieldsGit(root, ["rev-list", "-1", "--before=" & $days & " days ago", "HEAD"])
  if fields.len == 0: "" else: fields[0].strip


proc pathsMoved*(root, base: string): seq[string] =
  ## List paths on both sides of rename that scope exempts, old path then new one.
  ##   `--name-status` reports score, old path, new path. Exact rename (`R100`) is file moved and
  ##     not edited, and git pairs exact renames before any other, so edited file is never
  ##     mistaken for moved one.
  ##   Lock renamed at lower score is read at merge base and at HEAD, and passes only where its
  ##     one edit is name of its nimble copy (`isLockMoved`, #631).
  ##   Cost: merge base and two reads of git for each such lock; branch moving none pays nothing.
  let fields = fieldsGit(root, ["diff", "-z", "--name-status", "--find-renames", base & "...HEAD"])
  var
    fork = ""  # Merge base, read on first lock that needs it.
    i = 0
  while i + 2 < fields.len:
    if not fields[i].startsWith("R"):
      i += 2
      continue
    let (score, path_from, path_to) = (fields[i], fields[i+1], fields[i+2])
    i += 3
    if score != "R100":
      if not path_from.endsWith("/" & FILE_LOCK): continue
      if fork.len == 0: fork = fieldsGit(root, ["merge-base", base, "HEAD"])[0].strip
      let
        lock_from = fieldsGit(root, ["show", fork & ":" & path_from]).join
        lock_to = fieldsGit(root, ["show", "HEAD:" & path_to]).join
      if not isLockMoved(path_from, path_to, lock_from, lock_to): continue
    result.add path_from
    result.add path_to


proc pathsGained*(root, base: string): seq[string] =
  ## List paths base holds that branch does not, i.e. what base gained since branch forked.
  ##   Mirror of `pathsChanged`: same three-dot range, other way round.
  fieldsGit(root, ["diff", "-z", "--name-only", "--no-renames", "HEAD..." & base])


proc textAt*(root, revision, path: string): string =
  ## Read file as revision holds it; empty where revision holds none.
  ##   Output is bytes of file rather than NUL-separated fields, so text file joins back whole.
  try: fieldsGit(root, ["show", revision & ":" & path]).join
  except IOError: ""


proc subjects*(root, base: string): seq[string] =
  ## List commit subjects reachable from HEAD but not `base`, merges excluded.
  fieldsGit(root, ["log", "-z", "--format=%s", "--no-merges", base & "..HEAD"])


proc commitsBranch*(root, base: string): seq[Commit] =
  ## Read commits reachable from HEAD but not `base`, newest first, merges excluded.
  ##   Paths come from `diff-tree` of each commit, so rename reads as both of its paths.
  for hash in fieldsGit(root, ["log", "-z", "--format=%H", "--no-merges", base & "..HEAD"]):
    let
      name = hash.strip
      message = fieldsGit(root, ["log", "-1", "-z", "--format=%s%x1f%b", name])[0]
      parts = message.split('\x1f', 1)
    result.add Commit(
      subject: parts[0],
      body: (if parts.len > 1: parts[1] else: ""),
      paths: fieldsGit(root, ["diff-tree", "-z", "--no-commit-id", "--name-only", "-r", name]),
    )
