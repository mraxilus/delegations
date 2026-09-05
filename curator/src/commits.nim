## Enforce Conventional Commits (Article XI.1): `type(scope): lowercase imperative summary`.
##   Types are data in `TYPES`; scope must be project name or `curator`. On contributor
##   branch scope must equal project, so log replays by project; curator branch accepts any
##   valid scope, because rules propagation commits carry each project's scope.
##   Merge commits are excluded upstream (`git log --no-merges`); reverts use type `revert`.
##
##   Cost: imperative mood unverified; check sees lowercase first letter and no final period.
##   Cost: `!` breaking marker accepted after scope; body and footers pass unchecked.

{.experimental: "strictFuncs".}

import std/[options, strutils]
import ./[findings, domains]


type Subject* = object
  ## Define parsed commit subject.
  kind*: string     ## Commit type, member of `TYPES`.
  scope*: string    ## Project name or `curator`.
  summary*: string  ## Lowercase imperative summary without final period.


const TYPES* = [
  "build", "chore", "ci", "docs", "feat", "fix", "perf", "refactor", "revert", "style", "test",
]
  ## Commit types accepted, alphabetical.


func parseSubject*(subject: string): Option[Subject] =
  ## Parse `type(scope)!?: summary`; `none` when any part breaks grammar.
  let open = subject.find('(')
  let close = subject.find(')')
  if open <= 0 or close < open: return none(Subject)
  let kind = subject[0 ..< open]
  let scope = subject[open + 1 ..< close]
  var rest = subject[close + 1 .. ^1]
  if rest.startsWith("!"): rest = rest[1 .. ^1]
  if not rest.startsWith(": "): return none(Subject)
  let summary = rest[2 .. ^1]
  let is_summary = summary.len > 0 and summary[0] in {'a'..'z', '0'..'9'} and
    not summary.endsWith(".")
  if kind notin TYPES or not (scope == CURATOR or scope.isProjectName) or not is_summary:
    return none(Subject)
  some(Subject(kind: kind, scope: scope, summary: summary))


func checkCommits*(branch: string, subjects: openArray[string]): seq[Finding] =
  ## Report subjects outside grammar and, on contributor branch, scopes not its project.
  let parsed_branch = branch.parseBranch
  let expected =
    if parsed_branch.isSome and parsed_branch.get.role == Role.Contributor:
      some(parsed_branch.get.scope)
    else:
      none(string)
  for s in subjects:
    let parsed = s.parseSubject
    if parsed.isNone:
      result.add finding(
        "", 0,
        "Commit subject must match `type(scope): lowercase summary` without final period; got `" &
          s & "`.",
      )
    elif expected.isSome and parsed.get.scope != expected.get:
      result.add finding(
        "", 0, "Commit scope must be `" & expected.get & "`; got `" & s & "`."
      )
