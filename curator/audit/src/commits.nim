## Enforce Conventional Commits (Article XI.1): `type(scope): lowercase imperative summary`.
##   Types are data in `TYPES`; scope must be project name or `curator`. On project branch,
##   contributor or curator, scope must equal project, so log replays by project; curator
##   root branch accepts any valid scope, because rules propagation commits carry each
##   project's scope.
##   Merge commits are excluded upstream (`git log --no-merges`); reverts use type `revert`.
##   Regression rule is enforced here, not hoped for (Article IX.8, CONTRIBUTOR.md): every
##     `fix` carries earlier `test` of same scope on same branch, since mistake earns test
##     that fails before fix and passes after, committed first. Subjects arrive newest
##     first, so earlier means later in sequence.
##   Change needing no new test is not `fix`: it is `refactor`, `chore` or `docs`. That is
##     escape, and it is honest one, since `fix` claims mistake was found.
##
##   Cost: imperative mood unverified; check sees lowercase first letter and no final period.
##   Cost: fix of mistake whose test already sits on `main` still needs test here, or another
##     type; check reads one branch, never whole history.
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
  ## Report subjects outside grammar and, on project branch, scopes not its project.
  let parsed_branch = branch.parseBranch
  let expected =
    if parsed_branch.isSome and parsed_branch.get.role != Role.Curator:
      some(parsed_branch.get.scope)
    else:
      none(string)
  # Regression rule: `test` of same scope lands before `fix` it covers.
  var tested: seq[string]
  for i in countdown(subjects.high, 0):
    let parsed = subjects[i].parseSubject
    if parsed.isNone: continue
    if parsed.get.kind == "test": tested.add parsed.get.scope
    elif parsed.get.kind == "fix" and parsed.get.scope notin tested:
      result.add finding(
        "", 0,
        "Fix needs earlier `test(" & parsed.get.scope & ")` on branch; mistake earns test " &
          "that fails before it (Article IX.8); got `" & subjects[i] & "`.",
      )

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
