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
##   Root README.md repeats table by hand; layout check verifies copy against this data.
##
##   Branch grammar:
##     curator/<name>              curator work, every path allowed
##     <domain>/<project>/<name>   project work, confined to <domain>/<project>/
##     <project> ::= [a-z][a-z0-9_]*     <name> ::= [a-z0-9][a-z0-9_-]*
##
##   Cost of Unicode folder `síncopa`: macOS stores name as NFD; contributors there need
##     `git config core.precomposeunicode true`, else git reports phantom renames.
##   Cost of exactly three segments: `ronri/alpha/feature/x` is rejected; flat names only.

{.experimental: "strictFuncs".}

import std/[options, strutils]


type
  Domain* = object
    ## Define one life area: folder slug, display name, one-line theme.
    folder*: string  ## Directory name at repository root; also branch prefix head.
    name*: string    ## Display name, may hold characters git refs reject.
    theme*: string   ## One sentence naming what projects under it are about.

  Role* {.pure.} = enum
    ## Define who owns branch: curator (whole tree) or contributor (one project).
    Curator, Contributor

  Branch* = object
    ## Define parsed branch name.
    role*: Role
    domain*: string   ## Domain folder; empty for curator branches.
    project*: string  ## Project folder; empty for curator branches.
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
  CURATOR* = "curator"  ## Folder and branch head of curator tooling.
  MAIN* = "main"        ## Protected branch; owner merges into it by hand.


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
  if parts.len == 2 and parts[0] == CURATOR and parts[1].isBranchTail:
    return some(Branch(role: Role.Curator, name: parts[1]))
  if parts.len == 3 and parts[0].findDomain.isSome and parts[1].isProjectName and
      parts[2].isBranchTail:
    return some(Branch(
      role: Role.Contributor,
      domain: parts[0],
      project: parts[1],
      name: parts[2],
    ))
  none(Branch)


func prefix*(b: Branch): string =
  ## Read directory prefix branch owns, with trailing `/`.
  case b.role
  of Role.Curator: CURATOR & "/"
  of Role.Contributor: b.domain & "/" & b.project & "/"


func scope*(b: Branch): string =
  ## Read commit scope branch's commits must carry.
  case b.role
  of Role.Curator: CURATOR
  of Role.Contributor: b.project
