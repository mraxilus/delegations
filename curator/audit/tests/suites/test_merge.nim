## Replicate judgement of `merge.nim` header: real git on throwaway repository, second tree read
##   back, and koch of merge built by stub compiler.

{.experimental: "strictFuncs".}

import std/[options, os, sequtils, strutils, tables, tempfiles, unittest]
from std/posix import close, dup, dup2, STDOUT_FILENO
import ../../../knoller/src/knoller
import ../../src/[findings, merge, tree]
import ./fixtures


const STUB_NIM = "#!/bin/sh\n" &
  "logs=\"$(cd \"$(dirname \"$0\")/../..\" && pwd)\"\n" &
  "if [ \"$1\" = --version ]; then echo 'Nim Compiler Version 0.0.1 [Linux: amd64]'; exit 0; fi\n" &
  "echo \"$*\" >> \"$logs/builds.log\"\n" &
  "[ \"$(cat koch.nim)\" != broken ] || exit 1\n" &
  "for a in \"$@\"; do case \"$a\" in -o:*) out=\"${a#-o:}\" ;; esac; done\n" &
  "[ -n \"${out:-}\" ] || exit 1\n" &
  "printf '#!/bin/sh\\necho \"built from %s; ran $*\" > \"%s/run.log\"\\n" &
  "exit \"$(cat \"%s/exit\" 2>/dev/null || echo 3)\"\\n' " &
  "\"$(cat koch.nim)\" \"$logs\" \"$logs\" > \"$out\"\n" &
  "chmod +x \"$out\"\n"
  ## Compiler of pin `0.0.1` writing koch that logs source it was built from and arguments it
  ##   ran with, then exits with code that file `exit` beside cache holds, else 3; source
  ##   `broken` fails build.


proc repoForked(): string =
  ## Create repository whose branch `curator/older` forked, then `main` changed checker alone,
  ##   with its pin, as #893 names case; branch is checked out.
  result = repoTemp()
  result.writeInto(".gitignore", "build/\n")
  result.writeInto("koch.nim", "checker of fork\n")
  result.writeInto("curator/audit/audit.nimble", "requires \"nim == 0.0.0\"\n")
  result.writeInto("README.md", "Fork.\n")
  discard result.git("add -A")
  discard result.git("commit -q -m 'feat(audit): write checker'")
  discard result.git("checkout -q -b curator/older")
  result.writeInto("README.md", "Branch.\n")
  discard result.git("commit -q -am 'docs(curator): write readme'")
  discard result.git("checkout -q main")
  result.writeInto("koch.nim", "checker of base\n")
  result.writeInto("curator/audit/audit.nimble", "requires \"nim == 0.0.1\"\n")
  discard result.git("commit -q -am 'feat(audit): move checker and its pin'")
  discard result.git("checkout -q curator/older")


proc lines(path: string): seq[string] =
  ## Read lines of file, none where file is absent.
  if fileExists(path): readFile(path).strip.splitLines else: @[]


proc captureOutput(run: proc(): int): tuple[code: int, output: string] =
  ## Run proc with descriptor 1 sent to file; give its exit, and what it printed there, which
  ##   child process inherits too.
  let
    folder = createTempDir("delegations_", "_output")
    copy = dup(STDOUT_FILENO)
  defer: removeDir(folder)
  var file = open(folder / "output", fmWrite)
  flushFile(stdout)
  discard dup2(file.getFileHandle, STDOUT_FILENO)
  try: result.code = run()
  finally:
    flushFile(stdout)
    discard dup2(copy, STDOUT_FILENO)
    discard close(copy)
    file.close
  result.output = readFile(folder / "output")


proc toolchainStub(): string =
  ## Create cache of toolchains that holds stub compiler of pin `0.0.1` alone.
  result = createTempDir("delegations_", "_nim")
  result.writeInto("0.0.1/bin/nim", STUB_NIM)
  inclFilePermissions(result / "0.0.1" / "bin" / "nim", {fpUserExec})


proc moveOnBase(root, path, content: string) =
  ## Write file on `main` and commit it, then check branch `curator/older` out again.
  discard root.git("checkout -q main")
  root.writeInto(path, content)
  discard root.git("add -A")
  discard root.git("commit -q -m 'feat(audit): move " & path & "'")
  discard root.git("checkout -q curator/older")



suite "Merge":
  test "branch older than change of checker alone is judged in second tree, by checker of base":
    # Case as #893 names it: runner judges merge ref with checker of base, so `koch check`
    #   judges same merge, in tree that git dir holds.
    let root = repoForked()
    defer: removeDir(root)
    check root.isMerging("main")  # clean, and HEAD lacks base
    let merged = writeMerge(root, "main")
    check merged.findings.len == 0
    check sameFile(merged.directory, root / ".git" / DIRECTORY_MERGE)  # under git dir
    check readFile(merged.directory / "koch.nim") == "checker of base\n"
    check readFile(merged.directory / "README.md") == "Branch.\n"  # with what branch holds
    # HEAD there is merge commit of its own, base its second parent, and no branch holds it.
    check merged.directory.git("rev-parse HEAD^1") == root.git("rev-parse HEAD")
    check merged.directory.git("rev-parse HEAD^2") == root.git("rev-parse main")
    check merged.base == root.git("rev-parse main").strip
    check root.git("branch --contains " & merged.directory.git("rev-parse HEAD").strip).len == 0
    # Lines owned there are branch's alone, and none of those base changed.
    let owned = linesOwned(merged.directory, merged.directory.readTree, merged.base)
    check "README.md" in owned and "koch.nim" notin owned
    # Mark records tree of branch, which push compares, and checkout stays clean.
    check merged.tree == root.git("rev-parse HEAD^{tree}").strip
    check root.git("status --porcelain").len == 0


  test "second tree stays, keeps what git ignores, and holds merge exactly on each run":
    # Suites restore ignored state there, as `dependencies/` and `build/`, so tree that stays
    #   restores it once; file earlier run left, tracked or not, is no part of merge.
    let root = repoForked()
    defer: removeDir(root)
    let first = writeMerge(root, "main")
    first.directory.writeInto("build/restored", "kept\n")
    first.directory.writeInto("stray.md", "gone\n")
    first.directory.writeInto("stray/notes.md", "gone too\n")  # folder git does not track
    first.directory.writeInto("README.md", "Edited by run.\n")
    root.writeInto("README.md", "Branch, again.\n")
    discard root.git("commit -q -am 'docs(curator): write readme again'")
    let again = writeMerge(root, "main")
    check again.findings.len == 0 and again.directory == first.directory
    check readFile(again.directory / "build/restored") == "kept\n"
    check not fileExists(again.directory / "stray.md")
    check not dirExists(again.directory / "stray")
    check readFile(again.directory / "README.md") == "Branch, again.\n"
    check again.directory.git("status --porcelain").len == 0


  test "folder in place of second tree that is no worktree of its own is left to person":
    # Clean there would reach files of tree git names instead, so it gives finding, and touches
    #   nothing.
    let root = repoForked()
    defer: removeDir(root)
    root.writeInto(".git/" & DIRECTORY_MERGE & "/notes.md", "Kept.\n")
    let
      folder = root / ".git" / DIRECTORY_MERGE
      found = writeMerge(root, "main").findings
    check found.len == 1 and sameFile(found[0].path, folder)
    check found.len == 1 and "no worktree of its own" in found[0].brief
    check found.anyIt(it.rule == "koch.second-tree")
    check readFile(folder / "notes.md") == "Kept.\n"
    check root.git("worktree list --porcelain").count("worktree ") == 1  # none added


  test "second tree whose folder was deleted by hand is added again, in place of its entry":
    # Git keeps entry of worktree whose folder is gone, and refuses to add it again unless forced;
    #   forced add replaces that entry, so no second entry is left.
    let root = repoForked()
    defer: removeDir(root)
    let first = writeMerge(root, "main")
    removeDir(first.directory)
    check "prunable" in root.git("worktree list --porcelain")
    let again = writeMerge(root, "main")
    check again.findings.len == 0 and again.directory == first.directory
    check again.directory.git("rev-parse HEAD^2") == root.git("rev-parse main")
    check root.git("worktree list --porcelain").count("worktree ") == 2  # checkout, second tree
    check "prunable" notin root.git("worktree list --porcelain")


  test "dirty checkout, and checkout holding base, are judged in place":
    # `readTree` reads uncommitted and untracked files, which merge of commits misses; checkout
    #   holding base is its own merge. Merge path of `koch check` gives each back unjudged. Koch
    #   of merge passes here, so merge made by mistake would leave second tree and mark.
    let
      root = repoForked()
      toolchain = toolchainStub()
    defer: removeDir(root)
    defer: removeDir(toolchain)
    toolchain.writeInto("exit", "0\n")
    var toolchains = initToolchains(toolchain, some(Compiler(version: "0.0.0")))
    root.writeInto("README.md", "Edit in progress.\n")
    check not root.isMerging("main")
    check not judgeMerged(root, "main", "curator/older", toolchains).is_merged
    discard root.git("checkout -q -- README.md")
    root.writeInto("notes.md", "Untracked.\n")
    check not root.isMerging("main")
    check not judgeMerged(root, "main", "curator/older", toolchains).is_merged
    removeFile(root / "notes.md")
    check root.isMerging("main")
    discard root.git("merge -q --no-edit main")
    check not root.isMerging("main")
    check not judgeMerged(root, "main", "curator/older", toolchains).is_merged
    check not dirExists(root / ".git" / DIRECTORY_MERGE)  # nothing merged, so no second tree
    check not fileExists(root.fileMark)


  test "branch in conflict with base asks for merge of base, and leaves second tree as it was":
    # Runner runs no `pull_request` workflow on conflicting pull request, so local run agrees.
    let root = repoForked()
    defer: removeDir(root)
    let
      clean = writeMerge(root, "main")
      head = clean.directory.git("rev-parse HEAD")
    root.writeInto("koch.nim", "checker of branch\n")
    discard root.git("commit -q -am 'feat(audit): move checker on branch'")
    let found = writeMerge(root, "main").findings
    check found.len == 1 and found[0].path.len == 0 and found[0].line == 0
    check found.len == 1 and "merge base" in found[0].brief and "/sync" in found[0].brief
    check found.anyIt(it.rule == "koch.merge-conflict")
    check found.len == 1 and found[0].brief.endsWith(
      "got `koch.nim`; help: merge base, resolve each conflict, then check again, as /sync says",
    )
    check clean.directory.git("rev-parse HEAD") == head


  test "each checkout keeps second tree of its own, under its own git dir":
    let
      root = repoForked()
      worktree = root & "_worktree"
    defer: removeDir(root)
    defer: removeDir(worktree)
    discard root.git("worktree add -q -b curator/other " & worktree.quoteShell & " curator/older")
    let
      of_root = writeMerge(root, "main")
      of_worktree = writeMerge(worktree, "main")
    check of_root.findings.len == 0 and of_worktree.findings.len == 0
    check of_worktree.directory != of_root.directory
    check sameFile(
      of_worktree.directory.parentDir, worktree.git("rev-parse --absolute-git-dir").strip
    )
    check readFile(of_worktree.directory / "koch.nim") == "checker of base\n"
    check worktree.git("status --porcelain").len == 0 and root.git("status --porcelain").len == 0


  test "koch of merge builds on pin merge names, with cache of its own, where its source moved":
    # Stub compiler logs each build and writes koch that logs its source and arguments, so log
    #   names koch that judged; real git and real `sh` run (Article IX.5). Pin of branch is on
    #   PATH, and pin of base is in cache alone, as after base moved compiler of koch.
    let
      root = repoForked()
      toolchain = createTempDir("delegations_", "_nim")
    defer: removeDir(root)
    defer: removeDir(toolchain)
    toolchain.writeInto("0.0.1/bin/nim", STUB_NIM)
    inclFilePermissions(toolchain / "0.0.1" / "bin" / "nim", {fpUserExec})
    var toolchains = initToolchains(toolchain, some(Compiler(version: "0.0.0")))
    let
      merged = writeMerge(root, "main")
      (code, found) = runMerge(merged, "curator/older", toolchains)
    check found.len == 0 and code == 3  # exit of koch of merge is verdict
    check lines(toolchain / "run.log") == @["built from checker of base; ran check --root:" &
      merged.directory & " --branch:curator/older --base:" & merged.base]
    # Build and its cache sit beside second tree, in git dir, and read `koch.nim` of merge.
    let
      built = lines(toolchain / "builds.log")
      beside = merged.directory.parentDir
    check built.len == 1 and built[0].startsWith("c ") and built[0].endsWith(" koch.nim")
    check built.len == 1 and ("--nimcache:" & beside) in built[0] and ("-o:" & beside) in built[0]
    check merged.directory.git("status --porcelain --ignored").len == 0  # nothing built there

    # Same sources build nothing again, after merge writes and cleans second tree once more;
    #   base moving checker builds again.
    check runMerge(writeMerge(root, "main"), "curator/older", toolchains).code == 3
    check lines(toolchain / "builds.log").len == 1
    check runMerge(writeMerge(root, "main"), "curator/older", toolchains, "line").code == 3
    check lines(toolchain / "run.log")[0].endsWith(" --form:line")  # form named passes on
    discard root.git("checkout -q main")
    root.writeInto("koch.nim", "checker of base, moved\n")
    discard root.git("commit -q -am 'feat(audit): move checker again'")
    discard root.git("checkout -q curator/older")
    let moved = writeMerge(root, "main")
    check runMerge(moved, "curator/older", toolchains).code == 3
    let ran = lines(toolchain / "run.log")
    check lines(toolchain / "builds.log").len == 2
    check ran.len == 1 and ran[0].startsWith("built from checker of base, moved; ran check ")

    # Build that fails is one finding, and nothing runs.
    discard root.git("checkout -q main")
    root.writeInto("koch.nim", "broken\n")
    discard root.git("commit -q -am 'feat(audit): break checker'")
    discard root.git("checkout -q curator/older")
    removeFile(toolchain / "run.log")
    let broken = runMerge(writeMerge(root, "main"), "curator/older", toolchains)
    check broken.code == 1 and broken.found.len == 1
    check broken.found.len == 1 and "failed to build" in broken.found[0].brief
    check not fileExists(toolchain / "run.log")


  test "koch of merge builds again where base moves any source it keys, and nowhere else":
    # Key holds each path `.claude/hooks.sh` keys, so base moving any one of them builds koch
    #   that judges; path koch never compiles builds nothing.
    let
      root = repoForked()
      toolchain = createTempDir("delegations_", "_nim")
    defer: removeDir(root)
    defer: removeDir(toolchain)
    toolchain.writeInto("0.0.1/bin/nim", STUB_NIM)
    inclFilePermissions(toolchain / "0.0.1" / "bin" / "nim", {fpUserExec})
    var toolchains = initToolchains(toolchain, some(Compiler(version: "0.0.0")))
    discard runMerge(writeMerge(root, "main"), "curator/older", toolchains)
    var builds = lines(toolchain / "builds.log").len
    check builds == 1
    const keyed = [
      ("koch.nim", "checker of base, keyed\n"),
      ("koch.nim.cfg", "hints:off\n"),
      ("curator/audit/audit.nimble", "requires \"nim == 0.0.1\"\n# keyed\n"),
      ("curator/audit/src/checks.nim", "discard\n"),
      ("curator/knoller/src/knoller.nim", "discard\n"),
      ("curator/knoller/knoller.nimble", "requires \"nim == 0.0.1\"\n"),
    ]
    for (path, content) in keyed:
      root.moveOnBase(path, content)
      check runMerge(writeMerge(root, "main"), "curator/older", toolchains).code == 3
      builds += 1
      check lines(toolchain / "builds.log").len == builds  # path is keyed
    for path in ["notes.md", "curator/audit/tests/test_checks.nim", "curator/knoller/README.md"]:
      root.moveOnBase(path, "Moved.\n")
      check runMerge(writeMerge(root, "main"), "curator/older", toolchains).code == 3
      check lines(toolchain / "builds.log").len == builds  # path is no source of koch


  test "merge path of koch check reads drift first, and merges nothing where branch drifts":
    # Drift reads checkout, since merge as HEAD gains no governing path over its base; branch
    #   that drifts merges base first, so second tree waits.
    let
      root = repoForked()
      toolchain = toolchainStub()
    defer: removeDir(root)
    defer: removeDir(toolchain)
    root.moveOnBase("GUIDE.md", "# Guide\n\n## Toolchain\n\nPin.\n")
    var toolchains = initToolchains(toolchain, some(Compiler(version: "0.0.0")))
    let verdict = judgeMerged(root, "main", "curator/older", toolchains)
    check verdict.is_merged and verdict.code == 1
    check verdict.findings.len == 1 and verdict.findings[0].path == "GUIDE.md"
    check not dirExists(root / ".git" / DIRECTORY_MERGE) and not fileExists(root.fileMark)
    check lines(toolchain / "builds.log").len == 0


  test "mark of merge path records tree of branch where koch of merge exits 0, and only there":
    # Exit of koch of merge is exit of `koch check`; push sends commits of branch, so mark holds
    #   tree of branch, never tree of merge.
    let
      root = repoForked()
      toolchain = toolchainStub()
    defer: removeDir(root)
    defer: removeDir(toolchain)
    var toolchains = initToolchains(toolchain, some(Compiler(version: "0.0.0")))
    let failed = judgeMerged(root, "main", "curator/older", toolchains)
    check failed.is_merged and failed.code == 3 and failed.findings.len == 0
    check not fileExists(root.fileMark)
    toolchain.writeInto("exit", "0\n")
    let passed = judgeMerged(root, "main", "curator/older", toolchains)
    check passed.is_merged and passed.code == 0 and passed.findings.len == 0
    check readFile(root.fileMark).strip == root.git("rev-parse HEAD^{tree}").strip

    # Conflict gives one finding, and no mark.
    removeFile(root.fileMark)
    root.writeInto("koch.nim", "checker of branch\n")
    discard root.git("commit -q -am 'feat(audit): move checker on branch'")
    let conflicted = judgeMerged(root, "main", "curator/older", toolchains)
    check conflicted.is_merged and conflicted.code == 1 and conflicted.findings.len == 1
    check not fileExists(root.fileMark)


  test "detached checkout lacking base records no mark, even where its merge passes":
    # Case as record review of #893 found it: mark followed exit 0 alone, so clean detached
    #   checkout judged with `--branch` was marked, though no branch holds its tree. In place,
    #   detached HEAD already recorded none.
    let
      root = repoForked()
      toolchain = toolchainStub()
    defer: removeDir(root)
    defer: removeDir(toolchain)
    toolchain.writeInto("exit", "0\n")
    var toolchains = initToolchains(toolchain, some(Compiler(version: "0.0.0")))
    discard root.git("checkout -q --detach")
    let verdict = judgeMerged(root, "main", "curator/older", toolchains)
    check verdict.is_merged and verdict.code == 0 and verdict.findings.len == 0
    check lines(toolchain / "run.log").len == 1  # koch of merge ran, and passed
    check not fileExists(root.fileMark)


  test "build that fails gives finding, exit 1 and no mark":
    # It stops judgement at exit 1, so `koch check` reports it rather than pass.
    let
      root = repoForked()
      toolchain = toolchainStub()
    defer: removeDir(root)
    defer: removeDir(toolchain)
    toolchain.writeInto("exit", "0\n")
    var toolchains = initToolchains(toolchain, some(Compiler(version: "0.0.0")))
    root.moveOnBase("koch.nim", "broken\n")
    let broken = judgeMerged(root, "main", "curator/older", toolchains)
    check broken.is_merged and broken.code == 1 and broken.findings.len == 1
    check broken.findings.len == 1 and "failed to build" in broken.findings[0].brief
    check broken.findings.anyIt(it.rule == "koch.merge-build")
    check not fileExists(root.fileMark) and not fileExists(toolchain / "run.log")


  test "pin of merge that no compiler serves gives finding, exit 1 and no mark":
    # It stops judgement at exit 1, as failed build does. Stub `curl` fails as unreachable network
    #   would, so pin nothing serves fetches nothing, as in `test_compilers.nim` of knoller. Case
    #   stands alone, so its skip hides no other check.
    let
      root = repoForked()
      toolchain = toolchainStub()
      tools = createTempDir("delegations_", "_tools")
    defer: removeDir(root)
    defer: removeDir(toolchain)
    defer: removeDir(tools)
    toolchain.writeInto("exit", "0\n")
    var toolchains = initToolchains(toolchain, some(Compiler(version: "0.0.0")))
    if platform(hostOS, hostCPU).len == 0:
      # Gap: platform with no tarball builds pin from source through real git, so pin nothing
      #   serves is held on platform that has tarball alone.
      skip()
    else:
      tools.writeInto("curl", "#!/bin/sh\nexit 6\n")
      inclFilePermissions(tools / "curl", {fpUserExec})
      let path = getEnv("PATH")
      putEnv("PATH", tools & PathSep & path)
      defer: putEnv("PATH", path)
      root.moveOnBase("curator/audit/audit.nimble", "requires \"nim == 0.0.2\"\n")
      let unserved = judgeMerged(root, "main", "curator/older", toolchains)
      check unserved.is_merged and unserved.code == 1 and unserved.findings.len == 1
      check unserved.findings.len == 1 and "no compiler serves" in unserved.findings[0].brief
      check not fileExists(root.fileMark) and not fileExists(toolchain / "run.log")
      check runMerge(writeMerge(root, "main"), "curator/older", toolchains).code == 1


  test "koch check judges clean checkout lacking base in second tree, and any other in place":
    # Choice between two paths lives in `judgeCheckout`, which suite reaches; koch hands its
    #   path in place over as proc, which counts each call here.
    let
      root = repoForked()
      toolchain = toolchainStub()
    defer: removeDir(root)
    defer: removeDir(toolchain)
    var
      toolchains = initToolchains(toolchain, some(Compiler(version: "0.0.0")))
      runs_in_place = 0
    proc judgeInPlace(): int =
      ## Count judgement in place, and give exit of its own.
      runs_in_place += 1
      7

    root.writeInto("notes.md", "Untracked.\n")
    check judgeCheckout(root, "main", "curator/older", toolchains, judgeInPlace) == 7  # dirty
    check runs_in_place == 1 and not dirExists(root / ".git" / DIRECTORY_MERGE)
    removeFile(root / "notes.md")
    check judgeCheckout(root, "main", "curator/older", toolchains, judgeInPlace) == 3  # merged
    check runs_in_place == 1 and lines(toolchain / "run.log").len == 1
    toolchain.writeInto("exit", "0\n")
    check judgeCheckout(root, "main", "curator/older", toolchains, judgeInPlace) == 0  # green
    check runs_in_place == 1  # merge that passes runs nothing in place

    # Drift stops merge at exit 1, and reports each finding.
    root.moveOnBase("GUIDE.md", "# Guide\n\n## Toolchain\n\nPin.\n")
    let drifted = captureOutput(
      proc(): int = judgeCheckout(root, "main", "curator/older", toolchains, judgeInPlace)
    )
    check drifted.code == 1 and runs_in_place == 1
    check "GUIDE.md: koch.drift: actual=\"`# Guide`, `## Toolchain`\" message=\"base changed " &
      "sections" in drifted.output  # line form, as output is no terminal
    check "1 finding(s)." in drifted.output and "Merge with base not judged" in drifted.output
    discard root.git("merge -q --no-edit main")
    check judgeCheckout(root, "main", "curator/older", toolchains, judgeInPlace) == 7  # holds base
    check runs_in_place == 2


  test "run in place records tree of HEAD where checkout is clean and on branch, and only there":
    # Dirty tree records nothing, since no commit holds exactly what passed; detached HEAD
    #   records nothing, since no branch holds its tree.
    let root = repoForked()
    defer: removeDir(root)
    root.writeInto("notes.md", "Untracked.\n")
    root.recordMark
    check not fileExists(root.fileMark)  # untracked file
    removeFile(root / "notes.md")
    root.writeInto("README.md", "Edit in progress.\n")
    root.recordMark
    check not fileExists(root.fileMark)  # tracked file changed
    discard root.git("checkout -q -- README.md")
    discard root.git("checkout -q --detach")
    root.recordMark
    check not fileExists(root.fileMark)
    discard root.git("checkout -q curator/older")
    root.recordMark
    check readFile(root.fileMark).strip == root.git("rev-parse HEAD^{tree}").strip
