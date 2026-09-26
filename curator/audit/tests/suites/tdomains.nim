## Replicate domain table and branch grammar of `domains.nim` header, and CONTRIBUTOR.md.

import std/[options, sequtils, unittest]
import ../../src/domains
import ./fixtures


const TABLE = staticRead("../../src/domains.nim").headerTable
  ## Heading row, then one row per domain, as `domains.nim` header holds them.


suite "Article I":
  test "I.4 header table is derived view of registry":
    check TABLE[0] == @["Folder", "Name", "Theme"]  # columns read below
    check TABLE[1 .. ^1] == DOMAINS.mapIt(@[it.folder, it.name, it.theme])  # row per domain


suite "Branch grammar":
  test "contributor branches round-trip for every domain":
    for d in DOMAINS:  # 5 domains, exhaustive
      for project in ["alpha", "a1", "two_words"]:
        for tail in ["init", "0-fix", "add_parser"]:
          let branch = "contributor/" & d.folder & "/" & project & "/" & tail
          let parsed = branch.parseBranch
          check parsed.isSome and parsed.get.role == Role.Contributor  # four segments
          check parsed.get.prefix == "contributor/" & d.folder & "/" & project & "/"  # prefix
          check parsed.get.scope == project  # scope is project
          check parsed.get.roleName == "contributor/" & d.folder & "/" & project  # role

  test "curator project branches are confined, curator root owns tree":
    for project in ["audit", "probe", "a_2"]:
      for tail in ["init", "probe-koch"]:
        let parsed = ("curator/" & project & "/" & tail).parseBranch
        check parsed.isSome and parsed.get.role == Role.CuratorProject  # three segments
        check parsed.get.prefix == "curator/" & project & "/"  # prefix is project
        check parsed.get.scope == project  # scope is project
        check parsed.get.roleName == "curator/" & project  # role is prefix without slash
    for tail in ["setup", "rules-2"]:
      let parsed = ("curator/" & tail).parseBranch
      check parsed.isSome and parsed.get.role == Role.Curator  # two segments
      check parsed.get.prefix == "" and parsed.get.scope == "curator"  # whole tree
      check parsed.get.roleName == "curator"  # role is named where prefix is empty

  test "grammar rejects every deviation":
    for branch in [
      "main", "claude/setup", "ronri/alpha/x", "contributor/ronri/alpha",
      "contributor/ronri/alpha/x/y", "contributor/alpha/x", "contributor/nowhere/alpha/x",
      "contributor/ronri/Alpha/x", "contributor/ronri/1a/x", "contributor/ronri/alpha/",
      "contributor/ronri/alpha/-lead", "contributor/x", "contributor", "curator",
      "curator/Upper", "curator/a-b/x", "curator/x/y/z", "",
    ]:  # 18 cases
      check branch.parseBranch.isNone  # mirrors paths, fixed segment counts

  test "project names are lowercase snake_case":
    for name in ["a", "alpha", "alpha_2", "a1b2"]: check name.isProjectName  # [a-z][a-z0-9_]*
    for name in ["", "1a", "Alpha", "a-b", "a b", "_a", "síncopa"]:
      check not name.isProjectName  # [a-z][a-z0-9_]*

  test "domain lookup is exact":
    check "sincopa".findDomain.isSome  # slug is ASCII; accent lives in display name
    check "síncopa".findDomain.isNone  # folder that git would quote is gone
    check "comma_games".findDomain.get.name == "comma, games"  # slug maps to display name
    check "Abstand".findDomain.isNone  # case-sensitive
