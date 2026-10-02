## Replicate Article XI.1: Conventional Commits with stable scope.

{.experimental: "strictFuncs".}

import std/[options, sequtils, strutils, unittest]
from std/unicode import runeLen
import ../../src/commits


suite "Article XI":
  test "XI.1 every type parses with project or curator scope":
    for kind in TYPES:  # 11 types, exhaustive
      for scope in ["curator", "alpha", "a_2"]:
        let parsed = parseSubject(kind & "(" & scope & "): add thing")
        check parsed.isSome and parsed.get.kind == kind and parsed.get.scope == scope  # XI.1
        check parsed.get.summary == "add thing"  # summary kept
    check parseSubject("feat(alpha)!: drop api").isSome  # breaking marker

  test "XI.1 grammar rejects every deviation":
    for subject in [
      "add thing", "feat: add thing", "feat(alpha): Add thing", "feat(alpha): add thing.",
      "Feat(alpha): add thing", "feat(Alpha): add thing", "feat(alpha):add thing",
      "feat(alpha): ", "wip(alpha): add thing", "feat(a/b): add thing", "(alpha): add thing",
    ]:  # 11 cases
      check parseSubject(subject).isNone  # type(scope): lowercase summary, no period

  test "XI.1 subject at most one source line wide":
    let at_limit = "feat(alpha): " & "a".repeat(SUBJECT_MAX - 13)
    check at_limit.runeLen == SUBJECT_MAX  # fixture sits on limit
    check checkCommits("contributor/ronri/alpha/work", [at_limit]).len == 0  # at limit
    check checkCommits("contributor/ronri/alpha/work", [at_limit & "a"]).mapIt(it.message) ==
      @["Commit subject exceeds 100 characters; got `101`."]  # one over
    let wide = "feat(alpha): a" & "∧".repeat(SUBJECT_MAX - 14)
    check checkCommits("contributor/ronri/alpha/work", [wide]).len == 0  # runes, not bytes
    check checkCommits("claude/setup", ["x".repeat(SUBJECT_MAX + 1)]).len ==
      2  # width checked beside grammar

  test "XI.1 scope must match project on contributor and curator project branches":
    check checkCommits("contributor/ronri/alpha/work", ["feat(alpha): add", "test(alpha): c"])
      .len == 0  # scope equals project
    check checkCommits("contributor/ronri/alpha/work", ["feat(beta): add"]).mapIt(it.message) ==
      @["Commit scope must be `alpha`; got `feat(beta): add`."]  # scope named
    check checkCommits("curator/audit/work", ["feat(audit): add"]).len == 0  # curator project
    check checkCommits("curator/audit/work", ["docs(curator): x"]).mapIt(it.message) ==
      @["Commit scope must be `audit`; got `docs(curator): x`."]  # not curator
    check checkCommits("curator/rules", ["docs(alpha): x", "ci(curator): y"]).len == 0  # any
    check checkCommits("claude/setup", ["docs(alpha): x", "feat(curator): y"]).len ==
      0  # unparsed branch checks format only
    check checkCommits("claude/setup", ["Bad subject"]).len == 1  # format still checked
    check checkCommits("contributor/ronri/alpha/work", []).len == 0  # no commits, no findings

  test "Regression rule: test of same scope sits immediately before each fix":
    # Subjects arrive newest first, so commit before element `i` is element `i + 1`.
    check checkCommits(
      "curator/work", ["fix(audit): stop it", "test(audit): cover it"]
    ).len == 0  # test immediately before
    check checkCommits(
      "curator/work", ["fix(audit): stop it", "test(audit): cover it", "test(audit): cover more"]
    ).len == 0  # tests before test are free
    let found = checkCommits("curator/work", ["fix(audit): stop it"])
    check found.len == 1
    check found[0].message.endsWith("got `fix(audit): stop it`.")
    check "CONTRIBUTOR.md" in found[0].message  # cites rule where it lives; Article IX has none
    check checkCommits(
      "curator/work", ["test(audit): cover it", "fix(audit): stop it"]
    ).len == 1  # test after fix does not count
    check checkCommits(
      "curator/work", ["fix(audit): stop it", "test(probe): cover other"]
    ).len == 1  # other project's test does not count
    check checkCommits(
      "curator/work", ["fix(audit): stop other", "fix(audit): stop it", "test(audit): cover it"]
    ).len == 1  # one test clears one fix
    check checkCommits(
      "curator/work", ["fix(audit): stop it", "docs(audit): say it", "test(audit): cover it"]
    ).len == 1  # commit between them breaks pair
    check checkCommits(
      "curator/work", ["fix(audit): stop it", "revert(audit): undo it", "test(audit): cover it"]
    ).len == 1  # revert between them breaks pair too
    check checkCommits(
      "curator/work", ["refactor(audit): tidy it"]
    ).len == 0  # change needing no test is not fix

  test "XI.4 body is in sentence case, one sentence to line, trailers and code skipped":
    const trailers = "\n\nCo-Authored-By: Name <a@b.c>\nClaude-Session: https://x.y/z\n"
    let listed = "Reason sits here.\nMechanism sits here:\n- First item.\n" & trailers
    check checkBody("s", listed).len == 0
    check "sentence case" in checkBody("s", "reason sits here.")[0].message
    check "runs on" in checkBody("s", "Reason wraps across\nlines.")[0].message
    check "got two" in checkBody("s", "One sentence. Second one.")[0].message
    check checkBody("s", "Call `a. B` once.").len == 0  # code span holds no boundary
    check checkBody("s", "Version 2.2.12 is pinned.").len == 0  # decimal point, no space
    check checkBody("s", "Run this:\n\n```text\nkoch check\n```\n").len == 0  # fenced code
    check checkBody("s", "").len == 0  # subject alone is enough

  test "record travels in commit of its own":
    check checkRecordCommit("docs(a): record", ["c/d/a/PROVENANCE.md", "c/d/a/README.md"]).len == 0
    check checkRecordCommit("feat(a): add", ["c/d/a/src/a.nim"]).len == 0
    let mixed = checkRecordCommit("feat(a): add", ["c/d/a/PROVENANCE.md", "c/d/a/src/a.nim"])
    check mixed.len == 1 and "got `c/d/a/src/a.nim` beside it" in mixed[0].message

  test "history runs subject, ladder, body and paths over every commit":
    let commits = @[
      Commit(subject: "feat(curator): add", body: "reason.", paths: @["CURATOR.md"]),
      Commit(subject: "docs(curator): record", paths: @["c/PROVENANCE.md", "koch.nim"]),
    ]
    let found = checkHistory("curator/x", commits).mapIt(it.message)
    check found.len == 2
    check found.anyIt("sentence case" in it) and found.anyIt("of its own" in it)
