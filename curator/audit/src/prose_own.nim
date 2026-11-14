## Name each project whose prose stays in its own language, and hold each entry to tree (VI.5,
##   VI.8).
##   List is policy of this repository, so it lives here and never in knoller, which runs on any
##     repository: fix passes knoller one mode of articles for each file instead
##     (`should_drop_articles`), as names check passes words glossaries admit.
##   Listed project keeps its three records and its comments in its own language: English check
##     reads none of those records (`english.nim`), article check and fixer read none of its files
##     (`prose.nim`, `fixes.nim`), and planner reads those records as its code, so change to one
##     runs suites that hold them (`plan.nim`). Every other check reads them still.
##   Entry names project, issue where Architect approves it, and suite holding its prose in its
##     own language, which audit demands once entry says so. Static assertion holds project
##     directly under `contributor/bangu/`, since language is subject of that domain alone.
##   Check reports entry whose project tree lacks, at this module, and suite entry demands that
##     tree lacks, at that suite: inside project, so branch of that project clears it (duty 3).
##
##   Rejected: list in knoller, which would put policy of this repository into tool that runs on
##     any.
##   Rejected: list of directories with no suite, which leaves prose of listed project read by
##     nothing.
##   Cost: bare `knoller` command knows no list, so it drops `a` of lojban from comment of listed
##     project; delegate of that project runs `koch fix` instead.
##   Cost: until entry demands its suite, nothing reads prose of listed project, so English it
##     holds on `main` goes unchecked until it moves to lojban, as ruling `D4 a` of #818 accepts.
##   Cost: each rules change re-stamps record of listed project, so it runs suites of that project.

{.experimental: "strictFuncs".}

import std/[options, sequtils, strutils]
import ./[domains, findings, layout]


type ProjectProseOwn* = object
  ## Define one project whose prose stays in its own language, and what holds it there.
  directory* {.requiresInit.}: string  ## Project directory, repository-relative.
  issue* {.requiresInit.}: int  ## Number of issue where Architect approves project.
  suite* {.requiresInit.}: string  ## Suite holding its prose, relative to project directory.
  should_demand_suite* {.requiresInit.}: bool  ## Audit reports suite where tree lacks it.


const
  DOMAIN_PROSE_OWN* = "bangu"
    ## Folder of domain whose project alone may keep its own prose, since its subject is language.
  PROJECTS_PROSE_OWN* = [
    ProjectProseOwn(
      directory: "contributor/bangu/lojban_parser",
      issue: 818,
      suite: "tests/suites/test_prose_own.nim",
      should_demand_suite: false,
    ),
  ]
    ## Projects whose records and comments stay in their own language, each by Architect's ruling.
  PATH_PROSE_OWN* = "curator/audit/src/prose_own.nim"
    ## This module, which finding on project tree lacks names, since entry is what to change.


static:
  # Each entry is project of language domain, at earliest boundary (IV.4): entry outside it
  #   fails build, rather than reading as project tree lacks.
  doAssert DOMAIN_PROSE_OWN.findDomain.isSome,
    "Domain of own prose is registered domain; got `" & DOMAIN_PROSE_OWN & "`."
  for p in PROJECTS_PROSE_OWN:
    let parts = p.directory.split('/')
    doAssert parts.len == 3 and parts[0] == CONTRIBUTOR and parts[1] == DOMAIN_PROSE_OWN and
        parts[2].isNameProject,
      "Project keeping its own prose lies directly under `" & CONTRIBUTOR & "/" &
      DOMAIN_PROSE_OWN & "/`; got `" & p.directory & "`."


func isProseOwn*(path: string): bool =
  ## Decide whether path lies inside project whose prose stays in its own language.
  PROJECTS_PROSE_OWN.anyIt path.startsWith(it.directory & "/")


func checkProjectsProseOwn*(tree: Tree, projects: openArray[ProjectProseOwn]): seq[Finding] =
  ## Report each entry whose project tree lacks, and each suite entry demands that tree lacks.
  let directories = tree.directoriesProject
  for p in projects:
    if p.directory notin directories:
      result.add finding(
        PATH_PROSE_OWN,
        0,
        "Project keeping its own prose (VI.5, VI.8) is one tree holds; remove its entry, or " &
        "name project where it moved; got `" & p.directory & "`.",
      )
      continue
    let suite = p.directory & "/" & p.suite
    if p.should_demand_suite and not tree.anyIt(it.path == suite):
      result.add finding(
        suite,
        0,
        "Suite holding prose of project in its own language (VI.5, VI.8) is missing; restore " &
        "it, or demand it no longer in `" & PATH_PROSE_OWN & "`; got `" & suite & "`.",
      )
