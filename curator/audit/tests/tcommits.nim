discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Replicate Article XI.1: Conventional Commits with stable scope.

import std/[options, sequtils, strutils, unittest]
import ../src/commits


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

  test "IX.8 fix needs earlier test of same scope on branch":
    # Subjects arrive newest first, so test commit is later element.
    check checkCommits(
      "curator/work", ["fix(audit): stop it", "test(audit): cover it"]
    ).len == 0  # test landed first
    let found = checkCommits("curator/work", ["fix(audit): stop it"])
    check found.len == 1
    check found[0].message.endsWith("got `fix(audit): stop it`.")
    check checkCommits(
      "curator/work", ["test(audit): cover it", "fix(audit): stop it"]
    ).len == 1  # test after fix does not count
    check checkCommits(
      "curator/work", ["fix(audit): stop it", "test(probe): cover other"]
    ).len == 1  # other project's test does not count
    check checkCommits(
      "curator/work", ["refactor(audit): tidy it"]
    ).len == 0  # change needing no test is not fix
