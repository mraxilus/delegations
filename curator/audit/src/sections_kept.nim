## Enforce that each merge of branch keeps each `##` section of record that one parent added since
##   merge base (D5 of #1086).
##   Merge is each commit of two parents or more in `base..HEAD`, so merge of `main` into branch
##     and merge of two other branches read alike, and merge `main` holds is never read. Record is
##     each `PROVENANCE.md`; section is part `sections` of `markdown.nim` cuts at `## ` line
##     outside fence, as stamp and drift cut it.
##   Heading that parent holds and no merge base holds is one parent added. Each merge base counts,
##     so criss-cross merge, which has two, adds no heading that some common ancestor held.
##   Check reads whole sections alone, as ruling has it: bullet lost inside kept section passes.
##   Heading both parents added is named once. Heading one parent removed and other kept passes,
##     since merge base holds it. Record one parent added whole adds each heading it holds.
##   Record merge lacks passes where other parent deleted it since merge base: merge takes that
##     deletion. Deletion is commit of that parent, which shows whole record go. Move of project
##     deletes record at old path while merge carries sections to new one, which check by path
##     cannot follow, so finding there would refuse each move `main` touched.
##     Cost: section other parent added to such record goes with it, and nothing names it.
##   Finding names record, heading and merge in message, and no path of tree: merge is act of
##     branch, whichever project record lies in, so duty 3 holds none of it. Path of record would
##     let curator branch pass loss in contributor record, which is case ruling answers.
##   Record is read only where parent changed it since first merge base and merge differs from
##     that parent, since heading parent added needs both. So merge costs one `merge-base`, two
##     `diff` for each parent, and one `cat-file` for each revision of record both sides changed.
##
##   Cost: merge that lost section stays finding after later commit restores it, since check reads
##     merge and never HEAD; remedy is merge made again before push, by amend while it is head.
##   Cost: merge ref of runner and second tree of `koch check` are merges too, so check reads each.
##     Assumed clean: clean three-way merge keeps each line one side added.

{.experimental: "strictFuncs".}

import std/[options, sequtils, sets, strutils]
from ../../knoller/src/knoller/command import runGit
import ./[commits, findings, markdown, tree]


type  # Define each merge of branch as check reads it, with each record at each side.
  RecordSides* = object  ## Define record as merge, each parent and each merge base hold it.
    path*: string  ## Path of record from root.
    merge*: Option[string]  ## Text merge holds; none where merge lacks record.
    parents*: seq[Option[string]]  ## Text each parent holds, in order of parents.
    bases*: seq[Option[string]]  ## Text each merge base holds.

  CommitMerge* = object  ## Define one merge of branch, with each record check reads.
    commit*: string  ## Abbreviated object id of merge, as `%h` of git gives it.
    parents*: seq[string]  ## Abbreviated object id of each parent, in order.
    records*: seq[RecordSides]
      ## Each record one parent changed since merge base and merge changed from that parent.


func isRecord(path: string): bool =
  ## Decide whether path names record, i.e. `FILE_RECORD` at any depth.
  path == FILE_RECORD or path.endsWith("/" & FILE_RECORD)


func headingsSection(text: Option[string]): seq[string] =
  ## Read heading line of each `##` section of record, in order; none where record is absent.
  if text.isNone: return
  for part in text.get.sections:
    if part.heading.len > 0: result.add part.heading


func checkMerges*(merges: openArray[CommitMerge]): seq[Finding] =
  ## Report each `##` section of record that one parent added since merge base and merge lacks.
  for merge in merges:
    for record in merge.records:
      # Pass record merge lacks where other parent deleted it since merge base.
      let is_deleted = record.merge.isNone and record.bases.anyIt(it.isSome) and
        record.parents.anyIt(it.isNone)
      if is_deleted: continue

      # Name each heading parent holds that no merge base and not merge holds, once.
      var held = record.merge.headingsSection.toHashSet
      for text in record.bases: held.incl text.headingsSection.toHashSet
      for i, text in record.parents:
        for heading in text.headingsSection:
          if heading in held: continue
          held.incl heading
          result.add finding(
            "",
            0,
            Check.SectionsKept,
            "Merge keeps each `##` section of record that one parent added since merge base " &
              "(D5 of #1086); got `" & heading & "` of `" & record.path & "` lost in merge `" &
              merge.commit & "`, added by parent `" & merge.parents[i] & "`.",
            help = "make merge again before push, keeping each change of both sides, as step 2 " &
              "of /sync says",
          )


proc textRecord(root, revision, path: string): Option[string] =
  ## Read record as revision holds it, bytes exact; none where revision lacks it.
  let (output, _, code) = runGit(root, ["cat-file", "blob", revision & ":" & path])
  if code == 0: some(output) else: none(string)


proc recordsChanged(root, a, b: string): seq[string] =
  ## List each record that differs between two commits; renamed one stands at both of its paths.
  fieldsGit(root, ["diff", "-z", "--name-only", "--no-renames", a, b, "--", "*" & FILE_RECORD])
    .filterIt(it.isRecord)


proc readMerges*(root, base: string): seq[CommitMerge] =
  ## Read each merge reachable from HEAD but not `base`, newest first, with each record one parent
  ##   changed since first merge base and merge changed from that parent.
  ##   Merge of unrelated history has no merge base, so each record parent holds reads as changed.
  let logged = fieldsGit(root, ["log", "-z", "--merges", "--format=%H %P%n%h %p", base & "..HEAD"])
  for entry in logged:
    let
      lines = entry.strip.splitLines
      ids = lines[0].splitWhitespace
      (commit, parents) = (ids[0], ids[1 .. ^1])
      (output, failure, code) = runGit(root, @["merge-base", "--all", "--octopus"] & parents)
    if code != 0 and failure.strip.len > 0:
      raise newException(IOError, "git failed; got `" & failure.strip & "`.")
    let bases = output.splitWhitespace

    # Gather each record one parent changed since merge base and merge changed from that parent.
    var paths: seq[string]
    for parent in parents:
      let changed_merge = recordsChanged(root, parent, commit)
      if changed_merge.len == 0: continue
      let changed_parent =
        if bases.len > 0: recordsChanged(root, bases[0], parent).toHashSet
        else: changed_merge.toHashSet
      for path in changed_merge:
        if path in changed_parent and path notin paths: paths.add path

    # Read each such record at merge, at each parent and at each merge base.
    let shorts = lines[1].splitWhitespace
    var merge = CommitMerge(commit: shorts[0], parents: shorts[1 .. ^1])
    for path in paths:
      var record = RecordSides(path: path, merge: textRecord(root, commit, path))
      for parent in parents: record.parents.add textRecord(root, parent, path)
      for fork in bases: record.bases.add textRecord(root, fork, path)
      merge.records.add record
    result.add merge
