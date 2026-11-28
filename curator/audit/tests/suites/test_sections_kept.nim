## Replicate reading of merges of `sections_kept.nim` header: real git on throwaway repository,
##   each merge replayed with resolution test writes, findings read back (D5 of #1086).

{.experimental: "strictFuncs".}

import std/[os, sequtils, strutils, unittest]
import ../../src/[findings, scope, sections_kept]
import ./fixtures


type  # Define where replay writes each record, and what record holds there.
  Revision {.pure.} = enum  ## Define commit of replay at which record is written.
    Base  ## Merge base, on `main`.
    Branch  ## First parent, tip of branch.
    Main  ## Second parent, tip of `main`.
    Merge  ## Merge of `main` into branch.

  Shape {.pure.} = enum  ## Define what record holds at revision.
    Absent  ## No file.
    Bare  ## File without heading law follows.
    Headed  ## File holding heading law follows.


const  # Name records and branch of case as found, and heading law follows.
  PATH_TAGGER = DIRECTORY_TAGGER & "/PROVENANCE.md"  ## Record of `rictadni`, which `5ffcb104` cut.
  PATH_AUDIT = DIRECTORY_AUDIT & "/PROVENANCE.md"  ## Record of audit, which `5ffcb104` cut too.
  HEADING = "## Heading"  ## Heading whose fate law enumerates.
  BRANCH = "curator/block-docs"  ## Branch of case as found.


func textRecord(stamp: string, headings: openArray[string]): string =
  ## Render record of `Rules` row and one `##` section for each heading, in order.
  result = "# Provenance\n\n| Rules | " & stamp & " |\n"
  for heading in headings: result.add "\n" & heading & "\n\nText.\n"


proc commitFiles(
  root: string, files: openArray[(string, string)], removed: openArray[string] = []
) =
  ## Write each file and remove each path named, then commit all.
  for (path, text) in files: root.writeInto(path, text)
  for path in removed:
    if fileExists(root / path): removeFile(root / path)
  discard root.git("add -A")
  discard root.git("commit -q --allow-empty --no-edit -m 'docs(alpha): edit records'")


proc mergeAs(
  root, other: string, files: openArray[(string, string)], removed: openArray[string] = []
) =
  ## Merge `other` into HEAD with tree of HEAD (`-s ours`), then write each file and remove each
  ##   path named, so merge commit holds resolution test gives.
  discard root.git("merge -q --no-commit -s ours " & other)
  root.commitFiles(files, removed)


proc headShort(root: string): string =
  ## Read abbreviated object id of HEAD, as finding names merge.
  root.git("rev-parse --short HEAD").strip


func isNamed(found: openArray[Finding], path: string): bool =
  ## Decide whether some finding names record.
  found.anyIt(("`" & path & "`") in it.message)


func pathCase(shapes: array[Revision, Shape]): string =
  ## Name record of one case by its shape at each revision, as digits.
  result = "cases/"
  for shape in shapes: result.add $ord(shape)
  result.add "/PROVENANCE.md"


func isNamedLaw(shapes: array[Revision, Shape]): bool =
  ## Decide whether merge of case loses heading one parent added: parent holds it, base and merge
  ##   do not, and no parent deleted record that merge lacks.
  let
    is_added = Shape.Headed in [shapes[Revision.Branch], shapes[Revision.Main]] and
      shapes[Revision.Base] != Shape.Headed
    is_deleted = shapes[Revision.Merge] == Shape.Absent and
      shapes[Revision.Base] != Shape.Absent and
      Shape.Absent in [shapes[Revision.Branch], shapes[Revision.Main]]
  is_added and not is_deleted and shapes[Revision.Merge] != Shape.Headed


proc writeShapes(root: string, cases: openArray[array[Revision, Shape]], revision: Revision) =
  ## Write record of each case as revision holds it, then commit, or merge `main` at `Merge`.
  var
    files: seq[(string, string)]
    removed: seq[string]
  for shapes in cases:
    case shapes[revision]
    of Shape.Absent: removed.add shapes.pathCase
    of Shape.Bare: files.add (shapes.pathCase, textRecord("s", []))
    of Shape.Headed: files.add (shapes.pathCase, textRecord("s", [HEADING]))
  if revision == Revision.Merge: root.mergeAs("main", files, removed)
  else: root.commitFiles(files, removed)



suite "Kept sections":
  test "merge that kept side of branch for whole record is named, as `5ffcb104` was (#1086)":
    # Case found on #1086: merge `5ffcb104` of `curator/block-docs` kept side of branch for two
    #   whole records, where `Rules` row alone conflicted. So `main` lost `## Live replies` and
    #   `## Tag page` of record of `rictadni`, and `## Node packages` of record of audit, and
    #   `koch check` and runner passed it.
    let root = repoTemp()
    defer: removeDir(root)
    root.commitFiles([
      (PATH_TAGGER, textRecord("a", ["## Suggestion", "## Open questions"])),
      (PATH_AUDIT, textRecord("a", ["## Build glue", "## Open questions"])),
    ])
    discard root.git("checkout -q -b " & BRANCH)
    root.commitFiles([
      (PATH_TAGGER, textRecord("b", ["## Suggestion", "## Open questions"])),
      (PATH_AUDIT, textRecord("b", ["## Build glue", "## Open questions"])),
    ])
    discard root.git("checkout -q main")
    root.commitFiles([
      (
        PATH_TAGGER,
        textRecord("c", ["## Suggestion", "## Live replies", "## Tag page", "## Open questions"]),
      ),
      (PATH_AUDIT, textRecord("c", ["## Build glue", "## Node packages", "## Open questions"])),
    ])
    discard root.git("checkout -q " & BRANCH)
    root.mergeAs("main", [])  # each whole record kept as branch holds it
    let
      merge = root.headShort
      found = checkMerges(readMerges(root, "main"))
      lost = [
        (PATH_TAGGER, "## Live replies"), (PATH_TAGGER, "## Tag page"),
        (PATH_AUDIT, "## Node packages"),
      ]
    check found.len == lost.len  # one finding for each section lost (D5 of #1086)
    for (path, heading) in lost:
      check found.countIt(
        ("`" & path & "`") in it.message and ("`" & heading & "`") in it.message and
          ("`" & merge & "`") in it.message
      ) == 1  # names record, heading and merge
    check found.allIt(it.rule == "koch.kept-sections" and it.path.len == 0)
    let (held, own) = splitHeld(BRANCH, found)
    check held.len == 0 and own.len == lost.len  # curator branch holds no loss of contributor


  test "law over one heading at each revision: named where parent added it and merge lost it":
    # Each case is record of its own in one merge, so domain of one heading is read whole.
    let root = repoTemp()
    defer: removeDir(root)
    var cases: seq[array[Revision, Shape]]
    for base in Shape:
      for branch in Shape:
        for main in Shape:
          for merge in Shape: cases.add [base, branch, main, merge]
    root.writeShapes(cases, Revision.Base)
    discard root.git("checkout -q -b curator/law")
    root.writeShapes(cases, Revision.Branch)
    discard root.git("checkout -q main")
    root.writeShapes(cases, Revision.Main)
    discard root.git("checkout -q curator/law")
    root.writeShapes(cases, Revision.Merge)
    let
      found = checkMerges(readMerges(root, "main"))
      expected = cases.filterIt(it.isNamedLaw).mapIt(it.pathCase)
    check expected.len > 0 and expected.len < cases.len  # law both names and passes
    check found.len == expected.len  # heading both parents added is named once
    for path in expected: check found.countIt(("`" & path & "`") in it.message) == 1
    check found.allIt(("`" & HEADING & "`") in it.message)
    # Domain ruling names, as base, branch, main, merge.
    check not found.isNamed([Bare, Headed, Headed, Headed].pathCase)  # both add, merge keeps
    check found.isNamed([Bare, Headed, Headed, Bare].pathCase)  # both add, merge drops
    check not found.isNamed([Headed, Bare, Headed, Bare].pathCase)  # one removes, other keeps
    check not found.isNamed([Headed, Bare, Headed, Headed].pathCase)  # same, merge keeps
    check not found.isNamed([Absent, Absent, Headed, Headed].pathCase)  # added whole, kept
    check found.isNamed([Absent, Absent, Headed, Absent].pathCase)  # added whole, dropped
    check not found.isNamed([Bare, Absent, Headed, Absent].pathCase)  # merge takes deletion
    check found.isNamed([Bare, Bare, Headed, Absent].pathCase)  # merge deletes what both hold


  test "clean merge keeps both sides, and record is read only where both sides changed it":
    let root = repoTemp()
    defer: removeDir(root)
    let (both, base_only, main_only) = ("a/PROVENANCE.md", "b/PROVENANCE.md", "c/PROVENANCE.md")
    root.commitFiles([
      (both, textRecord("s", ["## A"])), (base_only, textRecord("s", ["## A"])),
      (main_only, textRecord("s", ["## A"])),
    ])
    discard root.git("checkout -q -b curator/clean")
    root.commitFiles([(both, textRecord("s", ["## Branch", "## A"]))])
    discard root.git("checkout -q main")
    root.commitFiles([
      (both, textRecord("s", ["## A", "## Main"])), (main_only, textRecord("s", ["## A", "## B"])),
    ])
    discard root.git("checkout -q curator/clean")
    discard root.git("merge -q --no-edit main")
    let merges = readMerges(root, "main")
    check merges.len == 1
    check merges[0].records.mapIt(it.path) == @[both]  # what one side alone changed is not read
    check checkMerges(merges).len == 0  # clean merge keeps each line one side added


  test "branch with no merge reads none":
    let root = repoTemp()
    defer: removeDir(root)
    root.commitFiles([(PATH_AUDIT, textRecord("s", ["## A"]))])
    discard root.git("checkout -q -b curator/plain")
    root.commitFiles([], [PATH_AUDIT])
    check readMerges(root, "main").len == 0
    check checkMerges(readMerges(root, "main")).len == 0


  test "merge of two branches that are not main is read, and merge main holds is not":
    let root = repoTemp()
    defer: removeDir(root)
    root.commitFiles([(PATH_AUDIT, textRecord("s", ["## A"]))])
    # Merge on `main` that lost section stays out, since `origin/main..HEAD` never reaches it.
    discard root.git("checkout -q -b curator/old")
    root.commitFiles([(PATH_AUDIT, textRecord("s", ["## A", "## Old"]))])
    discard root.git("checkout -q main")
    root.commitFiles([(PATH_AUDIT, textRecord("t", ["## A"]))])
    root.mergeAs("curator/old", [])
    # Branch `right` merges `third` and loses its section; branch `left` merges `right` whole.
    discard root.git("checkout -q -b curator/third")
    root.commitFiles([(PATH_AUDIT, textRecord("t", ["## A", "## Third"]))])
    discard root.git("checkout -q main")
    discard root.git("checkout -q -b curator/right")
    root.commitFiles([(PATH_AUDIT, textRecord("u", ["## A", "## Right"]))])
    root.mergeAs("curator/third", [])
    let lost = root.headShort
    discard root.git("checkout -q main")
    discard root.git("checkout -q -b curator/left")
    root.commitFiles([(PATH_TAGGER, textRecord("s", ["## A"]))])
    discard root.git("merge -q --no-edit curator/right")
    let found = checkMerges(readMerges(root, "main"))
    check readMerges(root, "main").len == 2  # merge of `left` and merge it brings from `right`
    check found.len == 1
    check found.allIt(
      ("`## Third`") in it.message and ("`" & lost & "`") in it.message
    )  # loss names merge where it happened, whichever branch made it


  test "heading some merge base holds is never added, as criss-cross merge has two bases":
    let root = repoTemp()
    defer: removeDir(root)
    root.commitFiles([(PATH_AUDIT, textRecord("s", ["## A"]))])
    discard root.git("checkout -q -b curator/a")
    root.commitFiles([(PATH_AUDIT, textRecord("s", ["## A", "## Cross"]))])
    discard root.git("checkout -q main")
    discard root.git("checkout -q -b curator/b")
    root.commitFiles([(PATH_TAGGER, textRecord("s", ["## A"]))])
    let (tip_a, tip_b) =
      (root.git("rev-parse curator/a").strip, root.git("rev-parse curator/b").strip)
    discard root.git("merge -q --no-edit " & tip_a)
    discard root.git("checkout -q curator/a")
    discard root.git("merge -q --no-edit " & tip_b)
    root.commitFiles([(PATH_AUDIT, textRecord("s", ["## A"]))])  # `a` removes `## Cross`
    check root.git("merge-base --all curator/a curator/b").strip.splitLines.len == 2
    root.mergeAs("curator/b", [])  # `b` kept `## Cross`, merge takes removal of `a`
    check checkMerges(readMerges(root, "main")).len == 0  # base `tip_a` held it


  test "text inside section, fenced heading and other Markdown are never read":
    # Ruling reads whole `##` sections alone, so bullet lost inside kept section passes.
    let root = repoTemp()
    defer: removeDir(root)
    root.commitFiles([
      (PATH_AUDIT, textRecord("s", ["## A"]) & "\n- One.\n"), ("README.md", "# Readme\n"),
    ])
    discard root.git("checkout -q -b curator/text")
    root.commitFiles([(PATH_AUDIT, textRecord("t", ["## A"]) & "\n- One.\n")])
    discard root.git("checkout -q main")
    root.commitFiles([
      (PATH_AUDIT, textRecord("u", ["## A"]) & "\n- One.\n- Two.\n\n```md\n## Example\n```\n"),
      ("README.md", "# Readme\n\n## Usage\n\nRun.\n"),
    ])
    discard root.git("checkout -q curator/text")
    root.mergeAs("main", [])
    check checkMerges(readMerges(root, "main")).len == 0


  test "merge of unrelated history reads each heading of its record as added":
    let root = repoTemp()
    defer: removeDir(root)
    discard root.git("checkout -q --orphan curator/other")
    root.commitFiles([(PATH_AUDIT, textRecord("s", ["## Other"]))])
    discard root.git("checkout -q main")
    discard root.git("checkout -q -b curator/unrelated")
    root.commitFiles([(PATH_TAGGER, textRecord("s", ["## A"]))])
    discard root.git("merge -q --no-commit -s ours --allow-unrelated-histories curator/other")
    root.commitFiles([(PATH_AUDIT, textRecord("s", []))])
    let found = checkMerges(readMerges(root, "curator/other"))
    check found.len == 1 and ("`## Other`") in found[0].message  # no merge base holds it
