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

  test "XI.1 scope must match branch when branch parses":
    check checkCommits("ronri/alpha/work", ["feat(alpha): add", "test(alpha): cover"]).len ==
      0  # scope equals project
    let found = checkCommits("ronri/alpha/work", ["feat(beta): add"])
    check found.mapIt(it.message) ==
      @["Commit scope must be `alpha`; got `feat(beta): add`."]  # scope named
    check checkCommits("curator/rules", ["docs(alpha): x", "ci(curator): y"]).len == 0  # any scope
    check checkCommits("claude/setup", ["docs(alpha): x", "feat(curator): y"]).len ==
      0  # unparsed branch checks format only
    check checkCommits("claude/setup", ["Bad subject"]).len == 1  # format still checked
    check checkCommits("ronri/alpha/work", []).len == 0  # no commits, no findings
