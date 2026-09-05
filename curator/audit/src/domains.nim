## Define domain registry and branch grammar, i.e. one table every path rule derives from.
##
##   |-------------|--------------|---------------------------------------------|
##   | Folder      | Name         | Theme                                       |
##   |-------------|--------------|---------------------------------------------|
##   | abstand     | abstand      | Music.                                      |
##   | bangu       | bangu        | Language.                                   |
##   | ronri       | ronri        | Computing.                                  |
##   | síncopa     | síncopa      | Dance and movement.                         |
##   | comma_games | comma, games | Game development across every other domain. |
##   |-------------|--------------|---------------------------------------------|
##
##   Folder is slug, name is display form: git refs reject spaces, so `comma, games` needs
##     slug for branch prefix; keeping name preserves owner's spelling.
##   Domain folders live under `contributor/`; curator projects live under `curator/`.
##     Root README.md repeats domain table by hand; layout check verifies copy against data.
##
##   Branch grammar mirrors paths:
##     curator/<name>                         rules and root work, every path allowed
##     curator/<project>/<name>               confined to curator/<project>/
##     contributor/<domain>/<project>/<name>  confined to contributor/<domain>/<project>/
##     <project> ::= [a-z][a-z0-9_]*     <name> ::= [a-z0-9][a-z0-9_-]*
##   Commit scope is `curator` for root work, else <project>.
##
##   Cost of Unicode folder `síncopa`: macOS stores name as NFD; contributors there need
##     `git config core.precomposeunicode true`, else git reports phantom renames.
##   Cost of fixed segment counts: `curator/audit/feature/x` is rejected; flat names only.
##   Cost: grammar never checks project exists; scope check then flags every path.

{.experimental: "strictFuncs".}

import std/[options, strutils]


type
  Domain* = object
    ## Define one life area: folder slug, display name, one-line theme.
    folder*: string  ## Directory name under `contributor/`; also branch segment.
    name*: string    ## Display name, may hold characters git refs reject.
    theme*: string   ## One sentence naming what projects under it are about.

  Role* {.pure.} = enum
    ## Define what branch owns, one member per grammar arm.
    Curator         ## `curator/<name>`: whole tree, rules and root work.
    CuratorProject  ## `curator/<project>/<name>`: one curator project.
    Contributor     ## `contributor/<domain>/<project>/<name>`: one domain project.

  Branch* = object
    ## Define parsed branch name.
    role*: Role
    domain*: string   ## Domain folder; empty unless `Role.Contributor`.
    project*: string  ## Project folder; empty for `Role.Curator`.
    name*: string     ## Free part after prefix.


const
  DOMAINS* = [
    Domain(folder: "abstand", name: "abstand", theme: "Music."),
    Domain(folder: "bangu", name: "bangu", theme: "Language."),
    Domain(folder: "ronri", name: "ronri", theme: "Computing."),
    Domain(folder: "síncopa", name: "síncopa", theme: "Dance and movement."),
    Domain(
      folder: "comma_games",
      name: "comma, games",
      theme: "Game development across every other domain.",
    ),
  ]
  CURATOR* = "curator"          ## Root of curator projects; head of curator branches.
  CONTRIBUTOR* = "contributor"  ## Root of domain folders; head of contributor branches.
  ROOTS* = [CURATOR, CONTRIBUTOR]  ## Project roots; each holds README.md and folders only.
  MAIN* = "main"                ## Protected branch; owner merges into it by hand.


func findDomain*(folder: string): Option[Domain] =
  ## Look up domain by folder slug.
  for d in DOMAINS:
    if d.folder == folder: return some(d)
  none(Domain)


func isProjectName*(s: string): bool =
  ## Decide whether `s` is valid project folder, i.e. `[a-z][a-z0-9_]*`.
  s.len > 0 and s[0] in {'a'..'z'} and s.allCharsInSet({'a'..'z', '0'..'9', '_'})


func isBranchTail*(s: string): bool =
  ## Decide whether `s` is valid free part of branch, i.e. `[a-z0-9][a-z0-9_-]*`.
  s.len > 0 and s[0] in {'a'..'z', '0'..'9'} and
    s.allCharsInSet({'a'..'z', '0'..'9', '_', '-'})


func parseBranch*(branch: string): Option[Branch] =
  ## Parse branch name into role and prefix; `none` when grammar rejects it.
  let parts = branch.split('/')
  if parts.len < 2 or not parts[^1].isBranchTail: return none(Branch)
  let tail = parts[^1]
  if parts.len == 2 and parts[0] == CURATOR:
    return some(Branch(role: Role.Curator, name: tail))
  if parts.len == 3 and parts[0] == CURATOR and parts[1].isProjectName:
    return some(Branch(role: Role.CuratorProject, project: parts[1], name: tail))
  if parts.len == 4 and parts[0] == CONTRIBUTOR and parts[1].findDomain.isSome and
      parts[2].isProjectName:
    return some(Branch(
      role: Role.Contributor,
      domain: parts[1],
      project: parts[2],
      name: tail,
    ))
  none(Branch)


func prefix*(b: Branch): string =
  ## Read directory prefix branch owns, trailing `/`; empty for curator root, i.e. tree.
  case b.role
  of Role.Curator: ""
  of Role.CuratorProject: CURATOR & "/" & b.project & "/"
  of Role.Contributor: CONTRIBUTOR & "/" & b.domain & "/" & b.project & "/"


func scope*(b: Branch): string =
  ## Read commit scope branch's commits must carry.
  case b.role
  of Role.Curator: CURATOR
  of Role.CuratorProject, Role.Contributor: b.project
