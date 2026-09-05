discard """
action: run
cmd: "nim c --hints:off -d:testing -d:nimUnittestAbortOnError:on $options $file"
batchable: true
joinable: true
"""
## Replicate branch grammar of `domains.nim` header and CONTRIBUTOR.md.

import std/[options, unittest]
import ../src/domains


suite "Branch grammar":
  test "every domain and curator prefix round-trips":
    for d in DOMAINS:  # 5 domains, exhaustive
      for project in ["alpha", "a1", "two_words"]:
        for tail in ["init", "0-fix", "add_parser"]:
          let branch = d.folder & "/" & project & "/" & tail
          let parsed = branch.parseBranch
          check parsed.isSome  # <domain>/<project>/<name>
          check parsed.get.role == Role.Contributor  # <domain>/<project>/<name>
          check parsed.get.prefix == d.folder & "/" & project & "/"  # prefix owns folder
          check parsed.get.scope == project  # scope is project
    for tail in ["setup", "rules-2"]:
      let parsed = ("curator/" & tail).parseBranch
      check parsed.isSome and parsed.get.role == Role.Curator  # curator/<name>
      check parsed.get.prefix == "curator/" and parsed.get.scope == "curator"  # curator scope

  test "grammar rejects every deviation":
    for branch in [
      "main", "claude/setup", "ronri/alpha", "ronri/alpha/x/y", "ronri/Alpha/x", "ronri/1a/x",
      "ronri/alpha/", "curator", "curator/x/y", "curator/Upper", "nowhere/alpha/x",
      "ronri/alpha/-lead", "",
    ]:  # 13 cases
      check branch.parseBranch.isNone  # exactly three segments, lowercase, known domain

  test "project names are lowercase snake_case":
    for name in ["a", "alpha", "alpha_2", "a1b2"]: check name.isProjectName  # [a-z][a-z0-9_]*
    for name in ["", "1a", "Alpha", "a-b", "a b", "_a", "síncopa"]:
      check not name.isProjectName  # [a-z][a-z0-9_]*

  test "domain lookup is exact":
    check "síncopa".findDomain.isSome  # Unicode folder kept
    check "comma_games".findDomain.get.name == "comma, games"  # slug maps to display name
    check "Abstand".findDomain.isNone  # case-sensitive
