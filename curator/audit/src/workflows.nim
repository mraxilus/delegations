## Hold each workflow's `permissions` block to scopes its own steps use.
##   Block is whole grant rather than addition to default: scope left out of it is set to
##   `none`, not left alone. So workflow naming one scope silently loses every other, and
##   loss shows as `403` on runner rather than as anything readable here.
##   Written after that happened: `watch.yml` named `contents` and `issues`, and its first
##   firing failed reading run it was pointed at, because naming those two revoked
##   `actions: read` it never mentioned.
##
##   Check is deliberately narrow. It reads what steps call, not what they might, and reports
##   only scope that some step demonstrably uses and block leaves out. Workflow declaring no
##   block at all is left alone: it takes repository default, which is somebody's decision
##   rather than drift.
##   Cost: marks below are text, so step reaching same endpoint by other spelling goes unseen.
##   That is floor, never ceiling -- check catches what it names and claims nothing else.

{.experimental: "strictFuncs".}

import std/[options, strutils]
import ./findings


const
  WORKFLOW_DIR* = ".github/workflows/"
    ## Directory every workflow lives in.
  PERMISSIONS_KEY* = "permissions:"
    ## Line opening grant, at column zero; job-level block is indented and left to its job.
  SCOPE_MARKS* = [
    ("actions", "/actions/"),
    ("actions", "gh run "),
    ("issues", "gh issue "),
    ("pull-requests", "gh pr "),
    ("contents", "actions/checkout"),
  ]
    ## Text step uses scope by, paired with scope it then needs. Endpoint path is what `gh api`
    ## spells; `gh run`, `gh issue` and `gh pr` are same reach through subcommand.
    ## `pull-requests` arrived late: no workflow read pull requests until sweep did, so gap
    ## sat unseen behind check written to stop exactly it.


func permissionScopes*(workflow: string): Option[seq[string]] =
  ## Read scopes workflow's own top-level `permissions` block names; `none` when it has none.
  ##   Absent block and empty block differ: absent takes repository default, empty grants
  ##   nothing, and only first is left alone.
  var scopes: seq[string]
  var is_inside = false
  for line in workflow.splitLines:
    if line.startsWith(PERMISSIONS_KEY):
      is_inside = true
      continue
    if not is_inside: continue
    if line.len > 0 and line[0] notin {' ', '\t'}: break
    let s = line.strip
    if s.len == 0 or s.startsWith("#"): continue
    let named = s.split(':')[0].strip
    if named.len > 0 and named notin scopes: scopes.add named
  if is_inside: some(scopes) else: none(seq[string])


func checkScopes*(path, workflow: string): seq[Finding] =
  ## Report scope workflow's steps use that its own `permissions` block leaves out.
  let granted = workflow.permissionScopes
  if granted.isNone: return
  var reported: seq[string]
  for (scope, mark) in SCOPE_MARKS:
    if mark notin workflow or scope in granted.get or scope in reported: continue
    reported.add scope
    result.add finding(
      path, 0,
      "Steps use `" & mark & "`, so `permissions` must grant `" & scope &
        "`; block is whole grant and scope left out is `none`; got `" &
        granted.get.join(", ") & "`.",
    )
