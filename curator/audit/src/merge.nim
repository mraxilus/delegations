## Judge branch as merged with base, by koch built from that merge, as runner judges merge ref
##   (#893). Runner checks out merge ref for each job judging tree but `check-drift`, so checker
##   of base judges there; `koch check` judges same merge, so drift names no checker (`base.nim`).
##
##   Clean checkout whose HEAD lacks base is merged with it in second tree, which stays in git dir
##     of checkout, out of view of checkout. Each checkout keeps its own, as worktree of subagent
##     does. Mark of `pre-push` hook, drift, branch name and hooks read checkout itself; static
##     pass and suites alone read second tree.
##   HEAD of second tree is merge commit of its own, base its second parent, so `linesOwned` there
##     reads lines branch owns; no branch holds commit. Rejected: `git merge --no-commit`, which
##     leaves HEAD at tip of branch, so `linesOwned` diffs merged tree from old fork and reads
##     lines base gained as branch's.
##   Merge is read by `merge-tree --write-tree` before second tree moves, so conflict leaves it
##     as it was. Conflict is finding asking for merge of base. Assumed from GitHub
##     documentation: GitHub runs no `pull_request` workflow on conflicting pull request, so
##     runner agrees.
##   Second tree stays, so ignored state suites restore there, as `dependencies/`,
##     `node_modules/` and `build/`, is restored once. Checkout is forced and untracked files
##     are cleaned, ignored ones kept, so tree holds merge exactly. Clean runs only where git
##     names second tree as top of its own worktree.
##   Koch of merge builds beside second tree, with cache of its own, keyed on object ids of its
##     sources in merge, as `.claude/hooks.sh` keys built koch; warm run builds nothing. Its
##     compiler is one pin of `curator/audit` in merge names, as `NIM_VERSION` of merge builds
##     it on runner. Rejected: `nim r` of merge, which turns each exit of koch into 1, so failed
##     build reads as findings.
##   Dirty checkout is judged in place: `readTree` reads uncommitted and untracked files, which
##     merge of commits misses, and no mark is written. Checkout holding base is
##     its own merge, so it is judged in place too. Koch of merge is handed commit of base, which
##     its HEAD holds, so it judges in place and never merges again.
##   Detached HEAD records no mark on either path, since no branch holds its tree; second tree
##     is detached, so its own run records none.
##
##   Cost: conflict blocks each push, since no mark is written.
##   Cost: hooks, `koch fix` and `koch stamp` keep checker of branch until it merges base.
##   Cost: second tree holds one more checkout and what suites restore there; cold build of koch
##     follows each change of checker on base.
##   Cost: two runs of `koch check` at once in one checkout share one second tree.
##   Cost: `merge-tree --write-tree` needs git 2.38 or newer. Assumed from release notes of git
##     2.38.0, which add that mode.
##   Cost: move of main checkout breaks link of its second tree; `git worktree repair <second
##     tree>` in checkout mends it, and bare `repair` does not. Moved linked worktree keeps
##     second tree, since git dir holding it stays.

{.experimental: "strictFuncs".}

import std/[options, os, sequtils, strutils]
from ../../knoller/src/knoller/command import runGit
import ../../knoller/src/knoller
import ./[base, checker, compilers, findings, hooks, layout, plan, projects, toolchain, tree]


const
  DIRECTORY_MERGE* = "koch-merge"
    ## Second tree, in git dir of checkout, where `koch check` judges branch as merged with base.
  DIRECTORY_MERGE_BUILD = "koch-merge-build"
    ## Koch of merge, its key and its cache, beside second tree in git dir.
  NAME_KOCH = "koch"  ## Binary of koch of merge; its key sits beside it, with `.key` added.
  MESSAGE_MERGE = "Merge base, for koch check"  ## Subject of merge commit, which no branch holds.
  IDENTITY_MERGE = ["-c", "user.name=koch", "-c", "user.email=koch@example.invalid"]
    ## Author of merge commit, which never leaves second tree.


type
  Merge* = object  ## Define merge of branch with base, as second tree holds it.
    directory*: string  ## Top of second tree, in git dir of checkout.
    base*: string  ## Commit of base, second parent of merge; koch of merge compares with it.
    tree*: string  ## Tree of branch at HEAD, which mark records once merge passes.
    findings*: seq[Finding]  ## What stops judgement, such as conflict; second tree stays as it was.

  Verdict* = object  ## Define what judgement of checkout as merged with base gives `koch check`.
    is_merged*: bool  ## Whether second tree judged checkout; else checkout is judged in place.
    code*: int  ## Exit code of `koch check`: that of koch of merge, else 1 where findings stop it.
    findings*: seq[Finding]  ## Drift, conflict, compiler or build that stops judgement.


proc fileMark*(root: string): string =
  ## Read path of check mark, in git dir git names for this checkout.
  pathMark(root, fieldsGit(root, ["rev-parse", "--git-dir"])[0].strip)


proc isDetached(root: string): bool =
  ## Decide whether HEAD of checkout is detached, i.e. no branch holds its tree.
  fieldsGit(root, ["rev-parse", "--abbrev-ref", "HEAD"])[0].strip == "HEAD"


proc isMerging*(root, base: string): bool =
  ## Decide whether `koch check` judges checkout in second tree: working tree clean, and HEAD
  ##   lacking base.
  if fieldsGit(root, ["status", "--porcelain"]).len > 0: return false
  let (_, failure, code) = runGit(root, ["merge-base", "--is-ancestor", base, "HEAD"])
  if code > 1: raise newException(IOError, "git failed; got `" & failure.strip & "`.")
  code == 1


proc isTop(directory: string): bool =
  ## Decide whether git names directory as top of worktree of its own, so clean stays inside it.
  try: sameFile(fieldsGit(directory, ["rev-parse", "--show-toplevel"])[0].strip, directory)
  except IOError, OSError: false


proc writeMerge*(root, base: string): Merge =
  ## Merge HEAD with base into second tree, as merge commit of its own whose second parent is
  ##   base; conflict names each path, and leaves second tree as it was.
  let head = fieldsGit(root, ["rev-parse", "HEAD"])[0].strip
  result = Merge(
    directory: fieldsGit(root, ["rev-parse", "--absolute-git-dir"])[0].strip / DIRECTORY_MERGE,
    base: fieldsGit(root, ["rev-parse", base & "^{commit}"])[0].strip,
    tree: fieldsGit(root, ["rev-parse", "HEAD^{tree}"])[0].strip,
  )

  # Read merge before second tree moves: exit 1 with tree written is conflict, else failure.
  let (output, failure, code) = runGit(
    root,
    ["merge-tree", "--write-tree", "-z", "--name-only", "--no-messages", head, result.base],
  )
  let fields = output.split('\0').filterIt(it.len > 0)
  if code == 1 and fields.len > 0:
    result.findings.add finding(
      "",
      0,
      "Branch conflicts with base, so no merge of them can be judged; merge base, resolve " &
        "each conflict, then check again, as /sync says; got `" & fields[1 .. ^1].join(", ") &
        "`.",
    )
    return
  if code != 0: raise newException(IOError, "git failed; got `" & failure.strip & "`.")

  # Write merge commit, then put second tree at it exactly; directory git names as no top of its
  #   own is left to person, since clean there would reach files of other tree.
  let commit = fieldsGit(
    root,
    @IDENTITY_MERGE &
      @["commit-tree", fields[0].strip, "-p", head, "-p", result.base, "-m", MESSAGE_MERGE],
  )[0].strip
  if not dirExists(result.directory):
    discard fieldsGit(
      root, ["worktree", "add", "-q", "--force", "--detach", result.directory, commit]
    )
  elif result.directory.isTop:
    discard fieldsGit(result.directory, ["checkout", "-q", "--force", "--detach", commit])
    discard fieldsGit(result.directory, ["clean", "-q", "-f", "-d"])
  else:
    result.findings.add finding(
      result.directory,
      0,
      "Second tree is no worktree of its own; remove it, then check again; got `" &
        result.directory & "`.",
    )


proc keyKoch(directory: string): string =
  ## Read object ids of sources koch builds from at HEAD of second tree, on paths
  ##   `.claude/hooks.sh` keys built koch with; empty where HEAD holds none, so build runs.
  ##   `ls-tree` lists each path HEAD holds and skips one it lacks, where `rev-parse` stops at
  ##     first path HEAD lacks, so no path that exists drops out of key.
  let paths =
    @FILES_CHECKER & @[DIRECTORY_DRIVER.pathNimble, DIRECTORY_CHECKER] & @FILES_KNOLLER
  fieldsGit(directory, @["ls-tree", "-z", "HEAD", "--"] & paths).join("\n")


proc runMerge*(
  merge: Merge, branch: string, toolchains: var Toolchains, form = ""
): tuple[code: int, found: seq[Finding]] =
  ## Run `check` of koch of merge in second tree for branch, against base merge holds, building
  ##   that koch first where its sources moved, on compiler pin of merge names. Exit code of that
  ##   run, else finding where no compiler serves pin or build fails. Form `--form` named passes
  ##   on, so both kochs print alike; none named leaves that koch to read its own terminal.
  let
    nimble = merge.directory / DIRECTORY_DRIVER.pathNimble
    pin = if fileExists(nimble): readFile(nimble).pinNim else: none(string)
    bin = if pin.isSome: toolchains.binFor(pin.get) else: some("")
  if bin.isNone:
    return (1, missing(DIRECTORY_DRIVER, pin.get, binCached(toolchains.root, pin.get)))

  # Build beside binary, then rename, so no run takes half-written file; failed build keeps one
  #   it had, under its own key, so next run builds again.
  let
    built = merge.directory.parentDir / DIRECTORY_MERGE_BUILD
    binary = built / NAME_KOCH
    key = merge.directory.keyKoch
    is_current =
      key.len > 0 and fileExists(binary) and fileExists(binary & ".key") and
        readFile(binary & ".key") == key
  if not is_current:
    createDir(built)
    let
      building = binary & "." & $getCurrentProcessId()
      code = runIn(
        merge.directory,
        bin.get.pathNim,
        ["c", "--hints:off", "--nimcache:" & built / "nimcache", "-o:" & building, PATH_KOCH],
        bin.get,
      )
    if code != 0:
      removeFile(building)
      return (1, @[finding(
        PATH_KOCH,
        0,
        "Koch of merge with base failed to build, as compiler says above; merge base, then " &
          "fix what breaks it; got exit `" & $code & "`.",
      )])
    moveFile(building, binary)
    writeFile(binary & ".key", key)
  var arguments = @[
    "check", "--root:" & merge.directory, "--branch:" & branch, "--base:" & merge.base,
  ]
  if form.len > 0: arguments.add "--form:" & form
  (runIn(merge.directory, binary, arguments, bin.get), @[])


proc judgeMerged*(
  root, base, branch: string, toolchains: var Toolchains, form = ""
): Verdict =
  ## Judge clean checkout lacking base as merged with it, as `koch check` does: drift of checkout
  ##   first, then merge in second tree, then `check` of koch of that merge for branch. Mark of
  ##   `pre-push` hook records tree of branch where that run exits 0 on branch checked out, and
  ##   never else; checkout judged in place gives verdict not merged.
  ##   Detached HEAD records no mark, as in place: no branch holds its tree.
  if not root.isMerging(base): return
  result = Verdict(is_merged: true, code: 1, findings: checkBase(readDrift(root, base)))
  if result.findings.len > 0: return
  let merged = writeMerge(root, base)
  result.findings = merged.findings
  if result.findings.len > 0: return
  echo "Koch of merge with base judges branch, in `" & merged.directory & "`."
  let (code, found) = runMerge(merged, branch, toolchains, form)
  (result.code, result.findings) = (code, found)
  if code != 0 or found.len > 0: return
  if root.isDetached:
    echo "Detached HEAD holds no branch; nothing recorded for pre-push hook."
    return
  writeFile(root.fileMark, merged.tree & "\n")
  echo "Tree hash of branch recorded for pre-push hook, as its merge passed."


proc judgeCheckout*(
  root, base, branch: string,
  toolchains: var Toolchains,
  judge_in_place: proc(): int,
  form_named = "",
  form = Form.Line,
  is_colored = false,
): int =
  ## Judge checkout as `koch check` does, and give its exit code: as merged with base where clean
  ##   HEAD lacks base (`judgeMerged`), else in place through `judge_in_place`, which koch holds.
  ##   Finding that stops merge is reported here, at exit 1, in form koch reads; form `--form`
  ##   named passes on to koch of merge.
  let verdict = judgeMerged(root, base, branch, toolchains, form_named)
  if not verdict.is_merged: return judge_in_place()
  if verdict.findings.len > 0:
    verdict.findings.report(form, is_colored)
    echo "Merge with base not judged; fix findings above, then run again."
  verdict.code


proc recordMark*(root: string) =
  ## Record tree of HEAD for `pre-push` hook after green run in place, where checkout is clean
  ##   and on branch, then say what was recorded or why nothing was.
  ##   Dirty tree records nothing, since no commit holds exactly what passed; detached HEAD
  ##     records nothing, since no branch holds its tree, and second tree is one.
  if fieldsGit(root, ["status", "--porcelain"]).len > 0:
    echo "Working tree not clean; nothing recorded for pre-push hook."
  elif root.isDetached:
    echo "Detached HEAD holds no branch; nothing recorded for pre-push hook here."
  else:
    writeFile(root.fileMark, fieldsGit(root, ["rev-parse", "HEAD^{tree}"])[0])
    echo "Tree hash recorded for pre-push hook."
